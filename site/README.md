# Marketplace Pages Site

Eleventy 3.x source for the bilingual (EN/DE) GitHub Pages site at
https://netresearch.github.io/claude-code-marketplace/ — the canonical
discovery and storytelling layer for this marketplace.

All skill data is read from [`../.claude-plugin/marketplace.json`](../.claude-plugin/marketplace.json)
(single source of truth) and enriched at build time with sections fetched
from each skill repo's README. Procedural skill content is never duplicated
here; the only per-skill data maintained in this directory is curated
presentation data in `src/_data/` (display names, German descriptions,
overrides). Design rationale lives in [`../docs/decisions/`](../docs/decisions/).

## Quick start

```bash
cd site
npm install

# Full build as in CI: README fetch → compliance checks → Eleventy → hreflang check
GITHUB_TOKEN=$(gh auth token) npm run build:all

# Local development with live reload (http://localhost:8080)
npm run dev
```

## Commands

| Command | Description |
|---------|-------------|
| `npm run build:all` | Full CI-equivalent build: fetch READMEs, checks, Eleventy, hreflang |
| `npm run build` | Eleventy build against the existing cache (`prebuild` runs `check:categories` + `og:generate`) |
| `npm run build:once` | Build without prebuild hooks (IDE integrations) |
| `npm run dev` | Dev server with live reload |
| `npm run preview` | Static preview of `_site/` after a build |
| `npm run fetch:readmes` | Fetch skill-repo READMEs (ETag-cached; needs `GITHUB_TOKEN`) |
| `npm run og:generate` | Regenerate OG images (Sharp + SVG template, `landing.png` + one PNG per skill) |
| `npm run check` | All compliance checks: categories, orphans, SEO copy |
| `npm run check:categories` | Blocking — category enum from AGENTS.md |
| `npm run check:orphans` | Blocking — required fields per skill (AGENTS.md §No orphan skills) |
| `npm run check:seo` | Advisory — banned phrases, weak openings, description length |
| `npm run check:hreflang` | Blocking (post-build) — EN↔DE pairs resolve on disk |
| `npm run test:visual` | Playwright visual regression (`test:visual:update` to refresh baselines) |
| `npm run clean` | Remove build artifacts |

Lighthouse runs only in CI against the staged `.lhci-site/` structure
(see [`../.github/workflows/pages.yml`](../.github/workflows/pages.yml) and
[`../lighthouserc.json`](../lighthouserc.json)).

## Structure

```
site/
├── .eleventy.js          Eleventy config: data sources, filters, pathPrefix, i18n
├── scripts/
│   ├── fetch-readmes.js      Octokit fetch of all skill-repo READMEs (ETag cache)
│   ├── parse-readme.js       Markdown → JSON: use cases, related skills, outputs, requirements
│   ├── generate-og-images.js Sharp + SVG template → OG PNGs
│   ├── check-orphans.js      Required-fields validator (blocking)
│   ├── check-categories.js   Category enum enforcement (blocking)
│   ├── check-seo-copy.js     SEO copy lint (advisory)
│   └── check-hreflang.js     EN↔DE pair consistency (blocking)
├── src/
│   ├── _data/                marketplace.js, skills.js (merge + related-skill derivation),
│   │                         displayNames.json, descriptions_de.json, i18n/, categories.js,
│   │                         groups.js, overrides.json, searchIndex.js, site.json
│   ├── _includes/            layouts/ (base, landing, skill) + partials/
│   ├── assets/               css/ (tokens + main), fonts/ (self-hosted WOFF2), img/, js/
│   ├── en/, de/              Landing, per-skill detail pages (pagination), about, 404
│   ├── index.njk             Root locale redirect (meta refresh + JS enhancement)
│   ├── sitemap.xml.njk
│   └── robots.txt
└── tests/visual/             Playwright snapshots (landings + detail-page sample)
```

## Quality gates (CI, blocking unless noted)

- Compliance checks: categories, orphans, hreflang (SEO copy is advisory)
- Lighthouse CI: Performance/Best Practices ≥ 0.95, Accessibility = 1.0, SEO = 1.0
- Visual regression (Playwright, chromium desktop)
- Existing marketplace validation (`../scripts/validate.sh`) is untouched by the site build

## Boundaries

- Never move or rename `.claude-plugin/marketplace.json` — it would break
  `/plugin marketplace add netresearch/claude-code-marketplace`.
- Never hardcode skill data in templates; everything flows from
  `marketplace.json` + fetched READMEs.
- No third-party scripts, no analytics, no external fonts, no cookies
  (see [ADR-0003](../docs/decisions/0003-no-client-side-analytics.md)).
- German copy is written independently in German technical register — never
  machine-echo translations of the English text
  (see [ADR-0002](../docs/decisions/0002-bilingual-en-de-with-independent-german-copy.md)).
- Commits: Conventional Commits with `(site)`/`(pages)` scope, DCO sign-off, signed.
