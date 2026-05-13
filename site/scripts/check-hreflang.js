#!/usr/bin/env node
/**
 * Verifies, against _site/ after `npm run build`:
 *   1. every EN indexable page has a matching DE counterpart (and vice versa)
 *   2. every indexable page declares the full hreflang set (en + de + x-default)
 *   3. each hreflang href resolves to an index.html that actually exists on disk
 *
 * Exit 0 = all paired and resolved, 1 = mismatch.
 */
import { readdir, readFile } from "node:fs/promises";
import { dirname, resolve, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SITE = resolve(__dirname, "../_site");

async function walk(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const out = [];
  for (const entry of entries) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...(await walk(full)));
    } else if (entry.name === "index.html") {
      out.push(full);
    }
  }
  return out;
}

const pages = await walk(SITE);
const rel = (p) => p.replace(SITE, "").replace(/\/index\.html$/, "/");
const langOf = (p) => {
  const m = rel(p).match(/^\/(en|de)\//);
  return m ? m[1] : null;
};

const enPages = new Set(pages.filter((p) => langOf(p) === "en").map(rel));
const dePages = new Set(pages.filter((p) => langOf(p) === "de").map(rel));

const missing = [];

for (const enPath of enPages) {
  const expectedDe = enPath.replace(/^\/en\//, "/de/");
  if (!dePages.has(expectedDe)) {
    missing.push({ have: enPath, missing: expectedDe });
  }
}
for (const dePath of dePages) {
  const expectedEn = dePath.replace(/^\/de\//, "/en/");
  if (!enPages.has(expectedEn)) {
    missing.push({ have: dePath, missing: expectedEn });
  }
}

const linkMismatches = [];
const SITE_BASE = "https://netresearch.github.io/claude-code-marketplace";

function hrefToDiskPath(href) {
  let path = href.startsWith(SITE_BASE) ? href.slice(SITE_BASE.length) : href;
  if (!path.endsWith("/")) path += "/";
  return join(SITE, path.slice(1), "index.html");
}

async function exists(p) {
  try {
    await readFile(p, "utf8");
    return true;
  } catch {
    return false;
  }
}

for (const file of pages) {
  const lang = langOf(file);
  if (!lang) continue;
  const html = await readFile(file, "utf8");

  const hreflangMatches = [...html.matchAll(/hreflang="([^"]+)"\s+href="([^"]+)"/g)];
  const seenHreflangs = new Map();
  for (const [, hl, href] of hreflangMatches) {
    if (!seenHreflangs.has(hl)) seenHreflangs.set(hl, href);
  }
  const required = ["en", "de", "x-default"];
  const missingTags = required.filter((x) => !seenHreflangs.has(x));
  if (missingTags.length > 0) {
    linkMismatches.push({
      file: rel(file),
      reason: `missing hreflang(s): ${missingTags.join(", ")}`,
    });
  }

  for (const [hl, href] of seenHreflangs) {
    const disk = hrefToDiskPath(href);
    if (!(await exists(disk))) {
      linkMismatches.push({
        file: rel(file),
        reason: `hreflang="${hl}" href="${href}" does not resolve to a built page (${disk.replace(SITE, "_site")})`,
      });
    }
  }
}

const ok = missing.length === 0 && linkMismatches.length === 0;
console.log(
  `Hreflang check: ${pages.length} pages scanned, ${missing.length} pair gaps, ${linkMismatches.length} link issues`
);

if (!ok) {
  if (missing.length > 0) {
    console.error("\nMissing translation pairs:");
    for (const m of missing) console.error(`  ✗ ${m.have} → expected ${m.missing}`);
  }
  if (linkMismatches.length > 0) {
    console.error("\nIncomplete hreflang sets:");
    for (const m of linkMismatches) console.error(`  ✗ ${m.file}: ${m.reason}`);
  }
  process.exit(1);
}
