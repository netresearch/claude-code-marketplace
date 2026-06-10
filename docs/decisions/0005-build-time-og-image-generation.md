# ADR-0005: Build-time OG image generation

## Status

Accepted

## Date

2026-05-13 (recorded retroactively 2026-06-10 from SPEC.md/PLAN.md)

## Context

Every page (landing plus one per skill and locale) needs a 1200×630 OG
image for social sharing. With 40+ skills that is far too many images to
author or maintain by hand, and committed PNGs would bloat the repo with
binary diffs on every content change.

## Decision

Generate all OG images at build time (`site/scripts/generate-og-images.js`)
from an SVG template rendered with Sharp — skill title and category badge
composed per skill. Images are build artifacts, never committed.

## Alternatives considered

- **Hand-authored images committed to the repo** — rejected: unmaintainable
  at this count, binary diffs, guaranteed drift from content.
- **External OG-image service** — rejected: third-party dependency at
  request time conflicts with ADR-0003 and adds an availability risk.

## Consequences

- Adding a skill to `marketplace.json` automatically yields its OG image.
- The OG template is code; visual changes to it are reviewed like code.
- `og:generate` runs as a `prebuild` hook, adding a few seconds per build.
