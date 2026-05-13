#!/usr/bin/env node
/**
 * AGENTS.md §Canonical categories: plugins[].category MUST be one of
 * `development | devops | security | design | workflow | productivity | document`.
 * scripts/validate.sh already enforces this on marketplace.json; this re-check
 * runs against the merged skills data layer so a typo in categories.js or
 * groups.js can't slip past CI either.
 */
import { default as categories } from "../src/_data/categories.js";

const skillsModule = await import("../src/_data/skills.js");
const skills = skillsModule.default();

const allowed = new Set(categories.enum);
const offenders = skills.filter((s) => !allowed.has(s.category));

console.log(
  `Category check: ${skills.length - offenders.length}/${skills.length} skills use canonical categories`
);

if (offenders.length > 0) {
  console.error("\nNon-canonical categories detected:\n");
  for (const skill of offenders) {
    console.error(`  ✗ ${skill.slug}: "${skill.category}"`);
  }
  console.error(`\nAllowed: ${[...allowed].join(", ")}`);
  process.exit(1);
}
