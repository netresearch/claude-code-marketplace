<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: 2026-06-10 -->

# AGENTS.md — Netresearch Claude Code Marketplace

Rules for coding agents editing **`netresearch/claude-code-marketplace`**.  
They apply to marketplace maintenance only: catalog, landing pages, SEO presentation, cross-linking, and aggregation.

**Precedence:** rules are additive — scoped files extend this root policy, and on conflict the **closest `AGENTS.md`** to the files you're changing wins. See the [scope index](#index-of-scoped-agentsmd) below.

**Do not copy skill-repository quality rules here.** Those live in [`netresearch/skill-repo-skill`](https://github.com/netresearch/skill-repo-skill) (skill-repo skill). **Do not duplicate runtime instructions from individual `SKILL.md` files** — the marketplace describes *how skills are found and presented*, not how they execute.

---

## Commands

| Task | Command |
|------|---------|
| Validate marketplace.json + README catalog | `./scripts/validate.sh` |
| Advisory catalog overlap report (non-blocking) | `python3 scripts/overlap-report.py` |

---

## Scope separation (mandatory)

| Layer | Responsibility |
| --- | --- |
| **This marketplace repository** | Public discovery hub: catalog, categories, landing/install URLs, related skills, SEO-facing copy, internal linking structure. |
| **Each skill repository** | Source for skill-specific docs: `README.md`, `SKILL.md` (runtime behavior), `agents/openai.yaml`, examples, expected outputs, context requirements, GitHub topics/description. |
| **`SKILL.md` in a skill repo** | Runtime behavior for the agent when the skill is loaded. **Not** the home for marketplace SEO metadata or extended discovery fields in YAML frontmatter. |

---

## Marketplace as canonical discovery hub

- The Netresearch Claude Code Marketplace is the **canonical public discovery hub** for Netresearch Agent Skills distributed through this plugin.
- Every listed skill **must** have a **stable, publicly understandable** presentation (what problem it solves, for whom, how to install).
- The marketplace **owns**: catalog structure, **categories**, **landing pages**, **installation paths**, **cross-links**, **Related Skills**, and **SEO-oriented listing copy** (titles, summaries, indexable detail pages).
- The marketplace **does not** define runtime behavior of skills. Execution semantics, triggers, and procedural detail stay in each skill repo’s **`SKILL.md`** and referenced files.

---

## Required fields per marketplace skill entry

Each skill entry in the marketplace (whether represented as JSON, YAML, tables in `README.md`, or generated metadata) **must** be possible to populate with at least the following **equivalent data**:

1. **Skill slug** — stable identifier (matches plugin/skill name where applicable).
2. **Display name** — human-readable title.
3. **Repository URL** — canonical GitHub (or source) URL for the skill repo.
4. **Marketplace / installation URL** — where users install or add the skill via marketplace/plugin flow.
5. **Short description (English)** — one short paragraph or sentence group for listings.
6. **Short description (German)** — **required when** the skill targets DACH agencies, TYPO3, OroCommerce, or German-speaking operators (otherwise omit with explicit “N/A” in internal tracking if your format requires a field).
7. **Category** — at least one taxonomy bucket controlled by the marketplace.
8. **Tags** — discrete labels for filtering/search.
9. **Use cases** — concrete scenarios (bullets or linked use-case docs).
10. **Expected outputs** — what the user gets (artifacts, decisions, files), at summary level.
11. **Context requirements** — what project/repo/external context must exist.
12. **Related Skills** — links or slugs to adjacent skills **when relationships exist** (see orphan rule below).
13. **Canonical landing page URL** — single stable URL for the skill’s public detail view (GitHub README section anchor, marketplace doc path, or dedicated page — pick one canonical pattern per skill and reuse it).

---

## Canonical categories

Use **exactly one** of these values in `plugins[].category` — do not invent new categories without updating this file, the README catalog grouping, and any future landing-page/sitemap generator:

`development` · `devops` · `security` · `design` · `workflow` · `productivity` · `document`

`scripts/validate.sh` enforces this enum. Skill repositories should keep their `discovery.yaml` `category` field in sync. When a new category is genuinely required, propose it in a PR that updates this list, the validator's allowed set, and the README catalog grouping.

---

## Value type (optional)

`plugins[].value_type` is an **optional** classifier mapping a skill to the six-category value rubric from the skill value-gate program ([skill-repo-skill#143](https://github.com/netresearch/skill-repo-skill/issues/143)). Allowed values:

`automation-script` · `org-convention` · `version-facts` · `failure-patterns` · `guardrail`

`guardrail` covers two rubric categories (inference suppression and anti-rationalization guards). Absence of the field is valid — `scripts/validate.sh` only checks the enum when the field is present. Populate it as skills are audited against the rubric; do not backfill guesses.

---

## SEO and discovery rules (marketplace copy)

Marketplace-facing text **must**:

- **First sentence states the concrete problem** the skill solves (not “helps with development”).
- **Avoid generic AI/agent boilerplate** (e.g. “ultimate assistant”, “supercharge your workflow”).
- **Include relevant keywords naturally** (product names, stacks, tasks).
- **Name technologies explicitly** where applicable, e.g. TYPO3, PHP, OroCommerce, Jira, GitHub, Docker, Concourse, SEO, Security, Accessibility, Vite.
- **Expose one indexable detail surface per skill** (unique heading + stable path; no duplicate canonical URLs for the same skill).
- **Support internal linking** via Related Skills and use-case hubs (markdown links or generated link graph — implementation-specific).
- **Stay snippet-friendly:** `plugins[].description` targets ≤ **300 characters** and is **hard-capped at 500**. `scripts/validate.sh` warns on the target and fails on the hard cap. Long-form content belongs on the dedicated landing or the source README — never copied into the marketplace description.

---

## No orphan skills

A skill **must not** appear isolated in the marketplace. Every listed skill **must** be connected to:

- **At least one category**
- **At least one use case** (statement or link)
- **Related Skills**, **if** there are real adjacencies; if none exist, document **“Related Skills: none (justified)”** in the entry’s maintenance notes or equivalent — **do not invent** relationships for SEO
- **Repository link**
- **Installation path** (command or documented flow)
- **Canonical landing page URL**

---

## Marketplace as aggregator, not primary source of truth

- **Authoritative skill-specific metadata** is created and maintained in **each skill repository** (`README.md`, optional discovery YAML/sections, `agents/openai.yaml`, GitHub settings).
- The marketplace **aggregates, normalizes, and displays** that information for discovery and installation.
- **Avoid duplicate truths**: do not restate long procedural docs from `SKILL.md` in the marketplace; summarize and link.
- **On conflict** between marketplace copy and the skill repo: **fix the skill repo** OR **document an intentional marketplace override** (where, why, effective date). Silent divergence is not allowed.

---

## GitHub Pages policy

The **marketplace repository SHOULD publish a GitHub Pages site** as the canonical public discovery and storytelling layer for Netresearch Agent Skills — hub pages, per-slug landings, related-skills crosslinks, sitemaps, OpenGraph metadata.

Individual **skill repositories MUST NOT enable GitHub Pages by default**. A skill repo may enable Pages only when the criteria in [`skill-repo-skill`/`references/repository-quality-rules.md`](https://github.com/netresearch/skill-repo-skill/blob/main/skills/skill-repo/references/repository-quality-rules.md) are satisfied (multi-page docs, gallery, generated reference, versioned docs, public reference implementation, methodology/assessment model, or a distinct SEO target the marketplace landing cannot cover).

Mirroring rule: skill-specific metadata originates in the skill repository (`discovery.yaml` or README sections). The marketplace consumes it. Do not duplicate the same metadata across README, a skill-repo Pages site and the marketplace landing — pick one canonical surface per fact and link from the others.

---

## Known marketplace overrides

Record intentional deviations from a source skill repo. Empty by default.

| Slug | Field | Marketplace value | Reason | Decided |
|---|---|---|---|---|

---

## Agent workflow checklist (marketplace changes)

Before completing a marketplace PR:

1. Confirm every new or updated skill entry has **all required fields** above (or documented equivalent).
2. If the skill falls under **DACH / TYPO3 / Oro / German-speaking operators**, confirm **short description (German)** is present or explicitly **N/A** where the listing schema forces a value.
3. Confirm **no orphan** listing (category, use case, repo, install path, canonical URL).
4. Confirm **SEO first sentence** matches a real problem statement.
5. Confirm **Related Skills** are real or explicitly absent with justification.
6. Confirm **links** resolve (repo, installation, canonical landing).
7. If `.claude-plugin/marketplace.json`, `scripts/validate.sh`, or `.github/workflows/` validation changed, run `./scripts/validate.sh` locally when available and ensure CI still matches the repo’s actual validation steps.

---

## Related references (outside this repo)

- Skill repository structure and validation: **`netresearch/skill-repo-skill`**
- Do **not** move runtime behavior documentation into this marketplace; link to source repos instead.

## Index of scoped AGENTS.md

| Directory | Read first when touching |
|---|---|
| [site/AGENTS.md](./site/AGENTS.md) | Eleventy Pages site: templates, data pipeline, checks |
| [.github/workflows/AGENTS.md](./.github/workflows/AGENTS.md) | CI workflows: pages, validate, security |
