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
    if (existing?.etag) headers["if-none-match"] = existing.etag;

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
      cached++;
      process.stdout.write(`  · ${plugin.name} (not modified)\n`);
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
