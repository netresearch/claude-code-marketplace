# ADR-0006: Root locale redirect via meta refresh + JS enhancement

## Status

Accepted

## Date

2026-05-13 (recorded retroactively 2026-06-10 from SPEC.md/PLAN.md)

## Context

The site root `/` must route visitors to `/en/` or `/de/`. GitHub Pages is
static hosting: the `Accept-Language` header cannot be evaluated
server-side, and HTTP 302 redirects with content negotiation are not
available.

## Decision

The root page ships a static
`<meta http-equiv="refresh" content="0; url=…/en/">` (EN as `x-default`)
plus visible fallback links to both locales. A small JS enhancement checks
`navigator.language.startsWith("de")` and re-routes to `/de/` immediately.
Without JavaScript the page degrades cleanly to English.

## Alternatives considered

- **Server-side content negotiation** — not available on static hosting.
- **JS-only redirect** — rejected: no-JS visitors would strand on an empty
  root page; meta refresh keeps the no-JS path working.
- **Root = English landing page (no redirect)** — rejected: would create a
  third canonical variant of the landing and complicate hreflang pairs.

## Consequences

- German-locale users with JS disabled land on `/en/` and switch manually
  via the language switcher.
- The meta-refresh page stays out of the sitemap; hreflang `x-default`
  points to `/en/`.
