#!/usr/bin/env node
/**
 * AGENTS.md §SEO and discovery rules — non-blocking warning checks against
 * the merged skill descriptions:
 *   - first sentence should state a concrete problem (heuristic: starts with
 *     a verb, not "A skill that..." or "Helps with..." boilerplate)
 *   - avoid generic AI/agent boilerplate phrases
 *   - description length within target (≤300) / hard cap (≤500, already
 *     enforced by scripts/validate.sh)
 *
 * Exits 0 even on warnings — this surfaces drift early but doesn't block
 * deploy, because copy improvements are humans-in-the-loop.
 */

const BANNED_PHRASES = [
  "ultimate assistant",
  "supercharge",
  "next-level",
  "ai-powered",
  "powered by ai",
  "revolutionize",
  "game-changing",
  "harness the power",
  "unlock the potential",
];

const WEAK_OPENINGS = [
  /^a skill that/i,
  /^this skill/i,
  /^helps (with|you|users)/i,
  /^helps to/i,
  /^used (for|to)/i,
  /^provides/i,
];

const skillsModule = await import("../src/_data/skills.js");
const skills = skillsModule.default();

const warnings = [];

for (const skill of skills) {
  const desc = (skill.description || "").trim();
  if (!desc) continue;

  const lower = desc.toLowerCase();
  for (const banned of BANNED_PHRASES) {
    if (lower.includes(banned)) {
      warnings.push({
        slug: skill.slug,
        rule: "banned-phrase",
        detail: `"${banned}"`,
      });
    }
  }

  const firstSentence = desc.split(/[.!?](\s|$)/)[0] || desc;
  for (const re of WEAK_OPENINGS) {
    if (re.test(firstSentence)) {
      warnings.push({
        slug: skill.slug,
        rule: "weak-opening",
        detail: `"${firstSentence.slice(0, 80)}…"`,
      });
      break;
    }
  }

  if (desc.length > 300 && desc.length <= 500) {
    warnings.push({
      slug: skill.slug,
      rule: "over-target",
      detail: `${desc.length} chars (target ≤300, hard cap 500)`,
    });
  }
}

console.log(
  `SEO copy check: ${skills.length - new Set(warnings.map((w) => w.slug)).size}/${skills.length} skills pass cleanly`
);

if (warnings.length > 0) {
  console.warn(`\n${warnings.length} advisory warning(s):\n`);
  for (const w of warnings) {
    console.warn(`  ⚠ ${w.slug} [${w.rule}]: ${w.detail}`);
  }
}
