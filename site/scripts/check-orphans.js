#!/usr/bin/env node
/**
 * AGENTS.md §No orphan skills: every listed skill MUST be connected to:
 *   1. at least one category
 *   2. at least one use case
 *   3. Related Skills (or documented "none (justified)")
 *   4. Repository link
 *   5. Install path
 *   6. Canonical landing page URL
 *
 * Plus AGENTS.md §Required fields per skill entry: all 13 fields per skill
 * (or marked N/A with justification in overrides).
 *
 * Exit non-zero on any violation. Run in CI before deploy.
 */
import { readFileSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OVERRIDES_PATH = resolve(__dirname, "../src/_data/overrides.json");

const overrides = existsSync(OVERRIDES_PATH)
  ? JSON.parse(readFileSync(OVERRIDES_PATH, "utf8"))
  : { entries: [] };

const overrideMap = new Map();
for (const entry of overrides.entries || []) {
  if (!overrideMap.has(entry.slug)) overrideMap.set(entry.slug, new Set());
  overrideMap.get(entry.slug).add(entry.field);
}

function isOverridden(slug, field) {
  return overrideMap.get(slug)?.has(field) === true;
}

const skillsModule = await import("../src/_data/skills.js");
const skills = skillsModule.default();

const failures = [];

// AGENTS.md §Required fields per skill entry: all 13 fields must be possible
// to populate. Blocking = field must be present (or documented override).
// Optional = field is rendered when present, empty is acceptable.
//
// AGENTS.md §No orphan skills: every listed skill must be connected to at
// least one category + use case + Related Skills (or "none justified") +
// repo + install path + canonical landing page URL — those are blocking.
const RULES = [
  // Blocking, always-required marketplace-source fields:
  { field: "slug", kind: "scalar", blocking: true },
  { field: "displayName", kind: "scalar", blocking: true },
  { field: "category", kind: "scalar", blocking: true },
  { field: "repo", kind: "scalar", blocking: true },
  { field: "installCommand", kind: "scalar", blocking: true },
  { field: "descriptionEn", kind: "scalar", blocking: true },
  { field: "canonicalUrlEn", kind: "scalar", blocking: true },
  { field: "canonicalUrlDe", kind: "scalar", blocking: true },
  // Blocking, with override path (DE description has a fallback, but a missing
  // override should still flag because the page would render English):
  { field: "descriptionDe", kind: "scalar", blocking: true, override: true },
  { field: "useCases", kind: "list", blocking: true, override: true },
  { field: "relatedSkills", kind: "list", blocking: true, override: true },
  // Optional — rendered when present, empty is acceptable per AGENTS.md
  // "must be POSSIBLE to populate" (the data shape supports it, see _data/skills.js).
  { field: "tags", kind: "list", blocking: false },
  { field: "expectedOutputs", kind: "list", blocking: false },
  { field: "contextRequirements", kind: "list", blocking: false },
];

const advisories = [];

for (const skill of skills) {
  const missing = [];
  const optional = [];
  for (const rule of RULES) {
    const value = skill[rule.field];
    const present = rule.kind === "list"
      ? Array.isArray(value) && value.length > 0
      : Boolean(value);
    if (present) continue;
    if (rule.override && isOverridden(skill.slug, rule.field)) continue;
    if (rule.blocking) {
      missing.push(rule.field);
    } else {
      optional.push(rule.field);
    }
  }

  if (missing.length > 0) failures.push({ slug: skill.slug, missing });
  if (optional.length > 0) advisories.push({ slug: skill.slug, optional });
}

const total = skills.length;
const ok = total - failures.length;

console.log(`No-orphan check: ${ok}/${total} skills pass blocking rules`);

if (advisories.length > 0) {
  const fieldCounts = {};
  for (const a of advisories) for (const f of a.optional) fieldCounts[f] = (fieldCounts[f] || 0) + 1;
  console.log(
    `Optional fields not populated (non-blocking — pages render fine without):  ${Object.entries(fieldCounts).map(([f, n]) => `${f}=${n}`).join(", ")}`
  );
}

if (failures.length > 0) {
  console.error(
    "\nOrphans detected (run npm run fetch:readmes to source missing fields, or add an entry to site/src/_data/overrides.json):\n"
  );
  for (const f of failures) {
    console.error(`  ✗ ${f.slug}: missing ${f.missing.join(", ")}`);
  }
  process.exit(1);
}
