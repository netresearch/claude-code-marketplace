# Architecture Decision Records

Decisions behind the GitHub Pages site (`site/`) and its data pipeline.

These ADRs were distilled from the original German project documents
(`SPEC.md` / `PLAN.md`, shipped 2026-05-13 via PRs
[#44](https://github.com/netresearch/claude-code-marketplace/pull/44),
[#45](https://github.com/netresearch/claude-code-marketplace/pull/45),
[#46](https://github.com/netresearch/claude-code-marketplace/pull/46),
Phase 2 via [#48](https://github.com/netresearch/claude-code-marketplace/pull/48)),
preserved in git history at
[`SPEC.md@95f20f5`](https://github.com/netresearch/claude-code-marketplace/blob/95f20f5aab4ed1efddef6986e30016804af71e08/SPEC.md) and
[`PLAN.md@95f20f5`](https://github.com/netresearch/claude-code-marketplace/blob/95f20f5aab4ed1efddef6986e30016804af71e08/PLAN.md).

| ADR | Title |
|-----|-------|
| [0001](0001-static-eleventy-site-on-github-pages.md) | Static Eleventy site on GitHub Pages |
| [0002](0002-bilingual-en-de-with-independent-german-copy.md) | Bilingual EN/DE with independently authored German copy |
| [0003](0003-no-client-side-analytics.md) | No client-side analytics or third-party scripts |
| [0004](0004-skill-metadata-mirrored-from-skill-repos.md) | Skill metadata mirrored from skill repos at build time |
| [0005](0005-build-time-og-image-generation.md) | Build-time OG image generation |
| [0006](0006-root-locale-redirect-via-meta-refresh.md) | Root locale redirect via meta refresh + JS enhancement |

New ADRs: copy the structure of an existing one, number sequentially,
never delete a superseded ADR — mark it `Superseded by ADR-XXXX` instead.
