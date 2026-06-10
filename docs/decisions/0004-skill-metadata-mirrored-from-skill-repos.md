# ADR-0004: Skill metadata mirrored from skill repos at build time

## Status

Accepted

## Date

2026-05-13 (recorded retroactively 2026-06-10 from SPEC.md/PLAN.md)

## Context

AGENTS.md's mirroring rule: the marketplace aggregates, it is not the
primary source of truth. Per-skill content (use cases, expected outputs,
context requirements, related skills) belongs to the skill repos.
Duplicating it in this repo would guarantee drift across 40+ repos.

## Decision

Fetch each skill repo's README at build time via Octokit
(`site/scripts/fetch-readmes.js`) and parse the relevant sections to JSON
(`site/scripts/parse-readme.js`, tolerant of heading variations). Caching
is ETag-based (`If-None-Match`) and persisted in the GitHub Actions cache;
a weekly cron (`0 3 * * 0`) plus `workflow_dispatch` rebuilds the site so
upstream README changes propagate without a push to this repo. Where a
README lacks a section, related skills are derived from category and theme
group (in `site/src/_data/skills.js`); intentional gaps are documented as
overrides (AGENTS.md §Known marketplace overrides).

## Alternatives considered

- **Maintaining per-skill content in this repo** — rejected: violates the
  mirroring rule and guarantees drift.
- **A separate `discovery.yaml` per skill repo** — rejected: SKILL.md
  already carries frontmatter and the Agent Skills spec tolerates unknown
  keys; a second artifact would split the source of truth.
- **(Planned successor) SKILL.md frontmatter fields** (`useCases:`,
  `relatedSkills:`, `expectedOutputs:`, `contextRequirements:`) — accepted
  as the mid-term direction; replaces README parsing once the fields are
  rolled out across skill repos. Requires an AGENTS.md/skill-repo-skill
  update and a multi-repo PR campaign. Until then, README parsing stands.

## Consequences

- Builds need `GITHUB_TOKEN`; rate limits are mitigated by the ETag cache.
- README structure inconsistencies across skill repos surface as parser
  fallbacks or overrides — fixing them upstream improves the page.
- Site content can lag upstream README changes by up to a week unless a
  rebuild is dispatched manually.
