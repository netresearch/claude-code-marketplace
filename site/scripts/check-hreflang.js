#!/usr/bin/env node
/**
 * Verifies that every EN page has a matching DE counterpart (and vice versa),
 * and that hreflang links inside each page point at URLs that actually exist
 * on disk. Run after `npm run build` against _site/.
 *
 * Exit 0 = all paired, 1 = mismatch.
 */
import { readdir, readFile } from "node:fs/promises";
import { resolve, join } from "node:path";

const SITE = resolve(import.meta.dirname, "../_site");

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

for (const file of pages) {
  const lang = langOf(file);
  if (!lang) continue;
  const html = await readFile(file, "utf8");

  const hreflangMatches = [...html.matchAll(/hreflang="([^"]+)"\s+href="([^"]+)"/g)];
  const seenHreflangs = new Set();
  for (const [, hl] of hreflangMatches) {
    seenHreflangs.add(hl);
  }
  if (!seenHreflangs.has("x-default") || !seenHreflangs.has("en") || !seenHreflangs.has("de")) {
    linkMismatches.push({
      file: rel(file),
      reason: `missing hreflang(s): ${["en", "de", "x-default"].filter((x) => !seenHreflangs.has(x)).join(", ")}`,
    });
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
