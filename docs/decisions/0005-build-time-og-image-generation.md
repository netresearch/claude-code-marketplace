# ADR-0005: Build-time OG image generation

## Status

Accepted

## Date

2026-05-13 (recorded retroactively 2026-06-10 from SPEC.md/PLAN.md)

## Context

The landing page and every skill detail page need a 1200×630 OG image for
social sharing; one image per skill is shared across both locales. With
40+ skills that is far too many images to author or maintain by hand, and
committed PNGs would bloat the repo with binary diffs on every content
change.

## Decision

Generate all OG images at build time (`site/scripts/generate-og-images.js`)
from an SVG template rendered with Sharp — `landing.png` plus one PNG per
skill slug (skill title and category badge composed per skill, shared
across locales). Images are build artifacts, never committed
(`site/src/assets/og/` is gitignored).

## Alternatives considered

- **Hand-authored images committed to the repo** — rejected: unmaintainable
  at this count, binary diffs, guaranteed drift from content.
- **External OG-image service** — rejected: third-party dependency at
  request time conflicts with ADR-0003 and adds an availability risk.

## Consequences

- Adding a skill to `marketplace.json` automatically yields its OG image.
- The OG template is code; visual changes to it are reviewed like code.
- `og:generate` runs as a `prebuild` hook, adding a few seconds per build.
