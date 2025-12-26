---
name: typo3-docs
description: "Create and maintain TYPO3 extension documentation following official TYPO3 13.x standards. Use when creating/editing Documentation/*.rst files or README.md, using TYPO3 directives (confval, versionadded, card-grid), rendering docs locally, or deploying to docs.typo3.org. By Netresearch."
---

# TYPO3 Documentation

## When to Use

- Editing `Documentation/**/*.rst` files
- Creating `Documentation/guides.xml` or updating `Settings.cfg`
- Using TYPO3 directives: `confval`, `versionadded`, `card-grid`, `php:class`
- Using text roles: `:php:`, `:file:`, `:guilabel:`, `:ref:`
- Running: `scripts/validate_docs.sh`, `scripts/render_docs.sh`
- Deploying to docs.typo3.org

## Core Workflow

1. Read reference files for the task at hand (see table below)
2. Use TYPO3 directives, not plain text equivalents
3. Validate: `scripts/validate_docs.sh`
4. Render: `scripts/render_docs.sh`
5. Keep README.md and Documentation/ synchronized
6. Commit together atomically

## Quick Reference Table

| Task | Reference File |
|------|----------------|
| Text roles (`:php:`, `:file:`, `:guilabel:`) | `references/text-roles-inline-code.md` |
| RST syntax (headings, lists, code blocks) | `references/rst-syntax.md` |
| TYPO3 directives (confval, card-grid, PlantUML) | `references/typo3-directives.md` |
| Documentation extraction and analysis | `references/extraction-patterns.md` |
| Coverage methodology | `references/documentation-coverage-analysis.md` |
| Webhook setup and deployment | `references/intercept-deployment.md` |
| Extension architecture context | `references/typo3-extension-architecture.md` |

## Critical Rules (Always Apply)

- **UTF-8** encoding, **4-space** indentation, no tabs
- **Sentence case** headings (not Title Case)
- **CamelCase** file/directory names
- **Index.rst** required in every subdirectory
- **American English** spelling (color, behavior, optimize)
- **PNG format** for screenshots, always include `:alt:` text

## Text Roles (Must Use)

| Content | Role |
|---------|------|
| PHP code | `:php:\`ClassName\`` |
| Files | `:file:\`ext_localconf.php\`` |
| Directories | `:path:\`Configuration/\`` |
| UI elements | `:guilabel:\`Save\`` |
| TypoScript | `:typoscript:\`lib.parseFunc\`` |

See `references/text-roles-inline-code.md` for complete list.

## Required Structure

```
Documentation/
├── guides.xml        # Config (modern)
├── Index.rst         # Entry point
├── Includes.rst.txt  # Global includes
└── */Index.rst       # Each subdirectory
```

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/validate_docs.sh` | Validate RST syntax |
| `scripts/render_docs.sh` | Render locally with Docker |
| `scripts/extract-all.sh` | Extract documentation data |
| `scripts/analyze-docs.sh` | Generate coverage analysis |

## Pre-Commit Checklist

1. `scripts/validate_docs.sh` passes
2. `scripts/render_docs.sh` shows no warnings
3. README.md and Documentation/ are in sync
4. `Documentation-GENERATED-temp/` is in `.gitignore`

For detailed guidelines, read the appropriate reference file before starting work.

---

> **Contributing:** Improvements to this skill should be submitted to the source repository:
> https://github.com/netresearch/typo3-docs-skill
