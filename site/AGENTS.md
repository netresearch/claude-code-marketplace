<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: 2026-06-10 -->

# AGENTS.md — site/ (Eleventy Pages site)

## Overview

Bilingual (EN/DE) Eleventy 3.x source for the GitHub Pages discovery site.
Root [AGENTS.md](../AGENTS.md) policy (categories, SEO copy rules, no-orphan
rule, mirroring rule) applies on top. Operational details: [README.md](README.md).
Design rationale: [../docs/decisions/](../docs/decisions/).

Data flow (do not bypass): `../.claude-plugin/marketplace.json` →
`src/_data/marketplace.js` → merged with fetched skill-repo READMEs
(`scripts/fetch-readmes.js` + `parse-readme.js`, ETag-cached) →
`src/_data/skills.js` → templates.

## Setup

```bash
cd site && npm install
export GITHUB_TOKEN=$(gh auth token)   # optional for fetch:readmes; avoids the 60-req/h anonymous rate limit
```

## Commands (run from `site/`)

| Task | Command |
|------|---------|
| Full CI-equivalent build | `npm run build:all` |
| Fast build vs. cache | `npm run build` |
| Dev server | `npm run dev` |
| Compliance checks | `npm run check` (categories, orphans, SEO) |
| Hreflang pairs (post-build) | `npm run check:hreflang` |
| Visual regression | `npm run test:visual` |
| Refresh visual baselines | `npm run test:visual:update` |

## Conventions

- Templates: Nunjucks, semantic HTML5, one `<h1>` per page, BEM-light classes.
- CSS: tokens in `assets/css/tokens.css`, layout in `main.css`, no `!important`.
- JS: vanilla ES2022 progressive enhancement only (~5 KB budget, `defer`);
  every page must work without JavaScript.
- German copy is authored independently in German technical register — never
  a translation echo of the English text (`descriptions_de.json`, `i18n/de.json`).
- Every EN page needs its DE counterpart and vice versa — `check:hreflang`
  breaks the build on missing pairs.
- Commits: `feat(pages):` / `fix(site):` style scopes, DCO sign-off, signed.

## Security

- No third-party scripts, analytics, external fonts, or cookies
  ([ADR-0003](../docs/decisions/0003-no-client-side-analytics.md)).
- Never commit tokens; `GITHUB_TOKEN` is read from the environment only.
- README-derived content is parsed, not executed; keep the parser's URL
  handling restrictive (allowlist) when extending it.

## Examples

- Good: skill card data read from `skills.js` collection in the template.
- Bad: hardcoding a skill name, description, or URL in a `.njk` template —
  data must flow from `marketplace.json` + fetched READMEs.
- Good: new UI string added to both `i18n/en.json` and `i18n/de.json`.
- Bad: English fallback text inline in a template.

## Checklist (before PR)

1. `npm run check` green (categories, orphans; SEO warnings reviewed).
2. `npm run build` + `npm run check:hreflang` green.
3. `npm run test:visual` green — for intended UI changes, refresh baselines
   after inspecting the render (see [Visual baselines](#visual-baselines)).
4. `src/assets/og/` not staged (generated, gitignored).
5. Quality gates stay blocking — never weaken Lighthouse thresholds
   (Perf/BP ≥ 0.95, A11y = 1.0, SEO = 1.0).

## Visual baselines

Baselines in `tests/visual/landings.spec.js-snapshots/` are rendered on CI. A PNG generated on a workstation differs in font rendering and fails the gate, so never commit one.

Adding or removing a catalog entry changes the landing by one card plus the hero count, which shifts every following row and invalidates both `landing-en` and `landing-de`. The `deploy` job needs `visual-regression`, so a stale baseline does not merely fail a check — it stops the site from publishing.

Two ways to obtain the new PNGs:

- `refresh-visual-snapshots.yml` (`workflow_dispatch`) — dispatch on the branch carrying the content change. It always opens its own PR against `main`, so lift the snapshot commit onto your branch and close that PR. It can hang on the install step ([#99](https://github.com/netresearch/claude-code-marketplace/issues/99)).
- The failing gate's own artefact — `pages.yml` uploads `playwright-report` when `visual-regression` fails. Its *actual* screenshots for the run on your head are the PNGs `--update-snapshots` would write. Tell actual from diff by opening them (the diff carries a red/yellow overlay), not by comparing file sizes.

Inspect the render before committing a baseline. A refresh freezes whatever is on screen, a bug included: a card title falling back to a title-cased slug (`Php Structured Edit`) was caught exactly here, and would otherwise have become the reference image.

## Per-slug data

A new catalog slug needs a row in every per-slug source under `src/_data/`, not only in `marketplace.json`:

- `displayNames.json` — curated name; without it `_helpers/display-name.js` title-cases the slug
- `descriptions_de.json` — German landing copy
- `groups.js` — group membership; a slug in no group renders under "uncategorized"

## When stuck

- Build/commands: [README.md](README.md); CI behavior:
  [../.github/workflows/pages.yml](../.github/workflows/pages.yml).
- Why it is built this way: [../docs/decisions/](../docs/decisions/).
- Marketplace policy (categories, SEO rules): [../AGENTS.md](../AGENTS.md).
