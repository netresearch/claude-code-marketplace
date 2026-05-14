#!/usr/bin/env node
/**
 * Fetch all skill-repo READMEs referenced from .claude-plugin/marketplace.json.
 *
 * Honors ETag-based conditional requests for cheap repeat runs; persists per-slug
 * cache in site/cache/skills-readme/ as JSON containing both the raw README and
 * the parsed sections so the Eleventy data layer can read it synchronously.
 *
 * GITHUB_TOKEN is optional (public READMEs work without one) but strongly
 * recommended in CI to avoid the 60-req/h anonymous rate limit.
 */
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { Octokit } from "@octokit/rest";
import { parseReadme } from "./parse-readme.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const MARKETPLACE = resolve(__dirname, "../../.claude-plugin/marketplace.json");
const CACHE_DIR = resolve(__dirname, "../cache/skills-readme");

const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN || undefined,
  userAgent: "netresearch-marketplace-pages-build",
});

async function fetchLatestRelease(owner, repo) {
  try {
    const res = await octokit.repos.getLatestRelease({ owner, repo });
    return {
      tag: res.data.tag_name,
      publishedAt: res.data.published_at,
      htmlUrl: res.data.html_url,
    };
  } catch (err) {
    // 404 = no releases yet — common for newer skill repos. Anything else is unexpected.
    if (err.status === 404) return null;
    console.warn(`  · ${owner}/${repo} release lookup failed (${err.status}): ${err.message}`);
    return null;
  }
}

mkdirSync(CACHE_DIR, { recursive: true });

const marketplace = JSON.parse(readFileSync(MARKETPLACE, "utf8"));

let fetched = 0;
let cached = 0;
let failed = 0;

for (const plugin of marketplace.plugins) {
  const cachePath = resolve(CACHE_DIR, `${plugin.name}.json`);
  const existing = existsSync(cachePath)
    ? JSON.parse(readFileSync(cachePath, "utf8"))
    : null;

  if (!plugin.source?.repo) {
    console.warn(`  skip ${plugin.name} (no source.repo)`);
    continue;
  }

  const [owner, repo] = plugin.source.repo.split("/");

  try {
    const headers = {};
    // Only use the cached ETag when the cache entry actually has the raw
    // markdown stashed (post-v6 schema). Older caches would force a 304
    // and we'd be stuck with whatever parsed shape they captured.
    if (existing?.etag && typeof existing.raw === "string") {
      headers["if-none-match"] = existing.etag;
    }

    const res = await octokit.repos.getReadme({ owner, repo, headers });

    const raw = Buffer.from(res.data.content, res.data.encoding || "base64").toString(
      "utf8"
    );

    const parsed = parseReadme(raw);
    const latestRelease = await fetchLatestRelease(owner, repo);

    writeFileSync(
      cachePath,
      JSON.stringify(
        {
          slug: plugin.name,
          owner,
          repo,
          etag: res.headers.etag || null,
          fetchedAt: new Date().toISOString(),
          raw,
          parsed,
          latestRelease,
        },
        null,
        2
      )
    );
    fetched++;
    process.stdout.write(`  ✓ ${plugin.name}${latestRelease ? ` (${latestRelease.tag})` : ""}\n`);
  } catch (err) {
    if (err.status === 304 && existing) {
      // README content is unchanged upstream, but two things drift
      // independently of the README's ETag:
      //
      //   1. The latest-release pointer (separate API).
      //   2. The parser logic in `parse-readme.js`. A cache from an older
      //      parser version would otherwise survive forever because the
      //      ETag still matches; we'd ship stale parsed sections (this
      //      bit the live deploy of #44/#46 — `### Marketplace
      //      (Recommended)` leaked into context-requirements for skills
      //      whose README had not changed since the parser fix).
      //
      // Mitigation: store the raw markdown in the cache and re-run
      // `parseReadme` against it on every 304 so the latest parser
      // logic always wins. Old caches (no `raw` field) fall back to
      // the already-parsed sections.
      const latestRelease = await fetchLatestRelease(owner, repo);
      let dirty = false;
      if (typeof existing.raw === "string") {
        const reparsed = parseReadme(existing.raw);
        if (JSON.stringify(reparsed) !== JSON.stringify(existing.parsed)) {
          existing.parsed = reparsed;
          dirty = true;
        }
      }
      // Compare on the canonical-null form so deletions / unpublished releases
      // also write back (`null` !== `{tag: …}`). Also covers the legacy case
      // where the cache predates `latestRelease` and has no key at all.
      const existingRelease =
        "latestRelease" in existing ? existing.latestRelease : undefined;
      if (JSON.stringify(latestRelease) !== JSON.stringify(existingRelease ?? null)) {
        existing.latestRelease = latestRelease;
        dirty = true;
      }
      if (dirty) writeFileSync(cachePath, JSON.stringify(existing, null, 2));
      cached++;
      process.stdout.write(
        `  · ${plugin.name} (not modified${latestRelease ? `, ${latestRelease.tag}` : ""})\n`
      );
      continue;
    }
    if (err.status === 404) {
      console.warn(`  ✗ ${plugin.name}: README not found (${owner}/${repo})`);
    } else {
      console.warn(`  ✗ ${plugin.name}: ${err.message || err}`);
    }
    failed++;
  }
}

const summary = `\nFetch summary: ${fetched} fetched, ${cached} cached, ${failed} failed (of ${marketplace.plugins.length} total)`;
console.log(summary);

if (failed > 0 && process.env.STRICT_FETCH === "1") {
  process.exit(1);
}
