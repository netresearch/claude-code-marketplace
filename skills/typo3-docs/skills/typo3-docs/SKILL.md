---
name: typo3-docs
description: "Create and maintain TYPO3 extension documentation following official docs.typo3.org standards. Use when creating/editing Documentation/*.rst files or README.md, using TYPO3 directives (confval, versionadded, card-grid, accordion, tabs, admonitions), creating/adding screenshots, rendering/testing/viewing docs locally, or deploying to docs.typo3.org. By Netresearch."
---

# TYPO3 Documentation

## When to Use

- Creating documentation from scratch → Use `docker run ... init` (see `references/rendering.md`)
- Editing `Documentation/**/*.rst` files
- Using TYPO3 directives: `confval`, `versionadded`, `card-grid`, `accordion`, `tabs`
- Using text roles: `:php:`, `:file:`, `:guilabel:`, `:ref:`
- Creating/adding screenshots
- Rendering/testing/viewing documentation
- Deploying to docs.typo3.org

## Core Workflow

1. Read reference files for the task (see table below)
2. Use TYPO3 directives, not plain text
3. Validate: `scripts/validate_docs.sh`
4. Render: `scripts/render_docs.sh`
5. **Verify visually** in browser
6. Keep README.md and Documentation/ synchronized

> **Critical**: When user asks to "show docs", render and display HTML output, not raw RST.

## Reference Files

| Task | Reference |
|------|-----------|
| File structure, naming | `references/file-structure.md` |
| guides.xml config | `references/guides-xml.md` |
| Coding guidelines, .editorconfig | `references/coding-guidelines.md` |
| Code blocks, confval, PHP domain | `references/code-structure-elements.md` |
| Content directives (accordion, tabs, cards) | `references/content-directives.md` |
| Rendering, testing, viewing | `references/rendering.md` |
| Screenshots and images | `references/screenshots.md` |
| Text roles (`:php:`, `:file:`, etc.) | `references/text-roles-inline-code.md` |
| RST syntax (headings, lists) | `references/rst-syntax.md` |
| TYPO3 directives (confval, card-grid) | `references/typo3-directives.md` |
| Webhook/deployment | `references/intercept-deployment.md` |

## Critical Rules

- **UTF-8**, **4-space** indent, **80 char** max, **LF** endings
- **CamelCase** file/directory names, **sentence case** headings
- **Index.rst** required in every subdirectory
- **PNG** screenshots with `:alt:` text
- `.editorconfig` required in `Documentation/` (see `references/coding-guidelines.md`)

## Element Selection

| Content Type | Use |
|--------------|-----|
| Code (5+ lines) | `literalinclude` (preferred) |
| Short snippets | `code-block` with `:caption:` |
| Config options | `confval` with `:type:`, `:default:` |
| PHP API | `php:class::`, `php:method::` |
| Notices | `note`, `tip`, `warning` |
| Grids | `card-grid` |
| Alternatives | `tabs` (synchronized) |
| Collapsible | `accordion` |

See `references/code-structure-elements.md` and `references/content-directives.md` for syntax.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/validate_docs.sh` | Validate RST syntax |
| `scripts/render_docs.sh` | Render with Docker |
| `scripts/watch_docs.sh` | Live-view (watch mode) |

## Pre-Commit Checklist

1. `.editorconfig` exists in `Documentation/`
2. Every directory has `Index.rst`, CamelCase naming
3. 4-space indent, no tabs, max 80 chars
4. Code blocks have `:caption:`, valid syntax
5. Inline code uses roles (`:php:`, `:file:`)
6. `scripts/validate_docs.sh` passes
7. Visual verification of rendered HTML
8. README.md and Documentation/ consistent

---

> **Contributing:** https://github.com/netresearch/typo3-docs-skill
