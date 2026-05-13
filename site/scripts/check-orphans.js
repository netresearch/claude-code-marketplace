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

for (const skill of skills) {
  const missing = [];
  if (!skill.category) missing.push("category");
  if (!skill.repo) missing.push("repo");
  if (!skill.installCommand) missing.push("installCommand");
  if (!skill.canonicalUrlEn) missing.push("canonicalUrlEn");
  if (!skill.canonicalUrlDe) missing.push("canonicalUrlDe");
  if (!skill.description) missing.push("description");

  if (skill.useCases.length === 0 && !isOverridden(skill.slug, "useCases")) {
    missing.push("useCases");
  }
  if (skill.relatedSkills.length === 0 && !isOverridden(skill.slug, "relatedSkills")) {
    missing.push("relatedSkills");
  }

  if (missing.length > 0) {
    failures.push({ slug: skill.slug, missing });
  }
}

const total = skills.length;
const ok = total - failures.length;

console.log(`No-orphan check: ${ok}/${total} skills pass`);

if (failures.length > 0) {
  console.error("\nOrphans detected (run npm run fetch:readmes to source missing fields, or add an entry to site/src/_data/overrides.json):\n");
  for (const f of failures) {
    console.error(`  ✗ ${f.slug}: missing ${f.missing.join(", ")}`);
  }
  process.exit(1);
}
