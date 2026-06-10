# ADR-0003: No client-side analytics or third-party scripts

## Status

Accepted

## Date

2026-05-13 (recorded retroactively 2026-06-10 from SPEC.md/PLAN.md)

## Context

The site needs basic reach insight, but any client-side tracking creates
GDPR obligations (consent banner), adds third-party payload against the
Lighthouse budget, and conflicts with the privacy posture expected of a
developer-tooling vendor page.

## Decision

Ship **zero third-party scripts**: no analytics, no tag manager, no
tracking pixels, no Google Fonts, no cookies, no LocalStorage beyond
necessity. Usage insight comes from GitHub repo insights (traffic, stars,
clones) only.

## Alternatives considered

- **Plausible/Matomo (cookieless)** — deferred: even cookieless analytics
  adds a third-party request and a privacy-policy surface; may be
  revisited as an explicit user decision (listed under "ask first").
- **GA4** — rejected outright: consent banner required, heavy payload.

## Consequences

- No page-level conversion data; reach is inferred from repo traffic.
- Lighthouse Best Practices and Performance budgets are easier to hold.
- No cookie banner, no privacy-policy maintenance for the site itself.
