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
export GITHUB_TOKEN=$(gh auth token)   # needed for fetch:readmes
```

## Commands (run from `site/`)

| Task | Command |
|------|---------|
| Full CI-equivalent build | `npm run build:all` |
| Fast build vs. cache | `npm run build` |
| Dev server | `npm run dev` |
| Compliance checks | `npm run check` (categories, orphans, SEO) |
| Hreflang pairs (post-build) | `npm run check:hreflang` |
| Visual regression | `npm run test:visual` (`:update` to refresh baselines) |

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
3. `npm run test:visual` — update baselines only for intended UI changes,
   inspect the diff first.
4. `src/assets/og/` not staged (generated, gitignored).
5. Quality gates stay blocking — never weaken Lighthouse thresholds
   (Perf/BP ≥ 0.95, A11y = 1.0, SEO = 1.0).

## When stuck

- Build/commands: [README.md](README.md); CI behavior:
  [../.github/workflows/pages.yml](../.github/workflows/pages.yml).
- Why it is built this way: [../docs/decisions/](../docs/decisions/).
- Marketplace policy (categories, SEO rules): [../AGENTS.md](../AGENTS.md).
