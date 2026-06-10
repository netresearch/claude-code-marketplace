# ADR-0001: Static Eleventy site on GitHub Pages

## Status

Accepted

## Date

2026-05-13 (recorded retroactively 2026-06-10 from SPEC.md/PLAN.md)

## Context

AGENTS.md mandates a GitHub Pages site as the canonical discovery and
storytelling layer for the marketplace, with indexable per-skill detail
pages. Requirements: read all skill data from `.claude-plugin/marketplace.json`
without duplicated maintenance, Lighthouse scores ≥ 0.95 (a11y 1.0), full
functionality without JavaScript, and no server-side logic (GitHub Pages is
static hosting).

## Decision

Build a static site with **Eleventy 3.x** (Nunjucks templates), vanilla CSS,
and at most ~5 KB of vanilla progressive-enhancement JavaScript. Deploy via
GitHub Actions (`actions/configure-pages` + `actions/deploy-pages`, build
type `workflow`, no `gh-pages` branch) to
`https://netresearch.github.io/claude-code-marketplace/`. No custom domain.
Fonts (Raleway + Open Sans) are self-hosted WOFF2 subsets.

## Alternatives considered

- **JS-framework SSG (Next.js, Astro, …)** — rejected: runtime JS budget and
  Lighthouse targets favor a zero-runtime generator; no interactive
  requirements beyond copy-to-clipboard and search.
- **Custom domain (`skills.netresearch.de`)** — rejected by explicit user
  decision 2026-05-13; would add DNS + CNAME maintenance with no discovery
  benefit while the GitHub org URL carries trust.
- **`gh-pages` branch deploy** — rejected in favor of the native
  Actions-based Pages deployment (no build artifacts in git).

## Consequences

- Search, locale negotiation, and any future interactivity must work
  client-side or at build time (see ADR-0006).
- All quality gates (Lighthouse, axe/Pa11y, html-validate, hreflang,
  visual regression) run in CI on the built `_site/` output.
- `lighthouserc.json` lives at the repo root; Lighthouse runs against a
  staged `.lhci-site/` path mirroring the Pages path prefix.
