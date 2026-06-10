# ADR-0002: Bilingual EN/DE with independently authored German copy

## Status

Accepted

## Date

2026-05-13 (recorded retroactively 2026-06-10 from SPEC.md/PLAN.md)

## Context

The marketplace targets the DACH market; AGENTS.md requires a German
description per skill entry. The initial plan was an English-only page,
which was revised after reconciling with the AGENTS.md rule canon.

## Decision

Every page exists in both locales: `/en/...` and `/de/...`, with
bidirectional `hreflang` pairs (`x-default` → EN) enforced by a blocking
post-build check. German copy is **authored independently in German
technical register** — never a machine echo of the English text. Per-skill
German descriptions live in `site/src/_data/descriptions_de.json`; UI
strings in `site/src/_data/i18n/{en,de}.json`. Permalink format is
`/<lang>/skills/<slug>/`.

## Alternatives considered

- **EN only** — original assumption; rejected after AGENTS.md
  reconciliation (German descriptions are mandatory fields).
- **Machine-translated German** — rejected: translated-English register
  reads poorly to the German-speaking target audience and violates the
  spirit of the AGENTS.md German-description rule.

## Consequences

- Every new page or skill requires an EN and a DE variant; the hreflang
  check breaks the build when a pair is missing.
- German copy changes are content work, not translation work — reviewers
  read the German corpus on its own.
- Sitemap carries `xhtml:link rel="alternate" hreflang` per URL.
