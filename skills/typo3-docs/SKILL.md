---
name: typo3-docs
description: Create and maintain TYPO3 extension documentation following official TYPO3 13.x standards. This skill should be used when creating/editing Documentation/*.rst files or README.md, using TYPO3 directives (confval, versionadded, card-grid), rendering docs locally, extracting documentation data, or deploying to docs.typo3.org. Covers RST syntax, TYPO3-specific directives, documentation extraction/analysis, local Docker rendering, validation, webhook setup, and Intercept deployment.
---

# TYPO3 Documentation

## When to Use This Skill

Invoke this skill when working with TYPO3 extension documentation:

**File Patterns:**
- Editing `Documentation/**/*.rst` files
- Creating new RST files in Documentation/ directory
- Updating `Documentation/guides.xml` (modern PHP-based rendering)
- Updating `Documentation/Settings.cfg` (legacy Sphinx - migrate to guides.xml)
- Editing `README.md` (requires syncing with Documentation/)

**Keywords/Commands:**
- Creating: "create Documentation/", "generate documentation", "new docs"
- Using TYPO3 directives: `confval`, `versionadded`, `versionchanged`, `php:method`, `card-grid`
- Running: `ddev docs`, `scripts/validate_docs.sh`, `scripts/render_docs.sh`
- Extraction: `scripts/extract-all.sh`, `scripts/analyze-docs.sh`
- Deployment: "setup webhook", "deploy docs", "publish to docs.typo3.org"

## Core Workflow

**Before editing Documentation/*.rst files or README.md:**

1. Invoke this skill if not already active
2. Optional: Run extraction and analysis for gap identification (see "Extraction Workflow")
3. Use the workflow decision tree below
4. Use appropriate TYPO3 directives (not plain text equivalents)
5. Validate: `scripts/validate_docs.sh` or `ddev docs`
6. Check rendered output for warnings
7. **Verify synchronization:** README.md ↔ Documentation/ must stay in sync
8. Commit both README.md and Documentation/ together in atomic commits

## Workflow Decision Tree

| Task | Action | Reference |
|------|--------|-----------|
| New documentation | Create Index.rst with card-grid | `references/typo3-directives.md` |
| Configuration | Use `confval` directive | `references/typo3-directives.md` |
| Version-specific feature | Use `versionadded`/`versionchanged` | `references/typo3-directives.md` |
| PHP API documentation | Use `php:method` directive | `references/typo3-directives.md` |
| Visual navigation | Use card-grid with `stretched-link` | `references/typo3-directives.md` |
| Cross-references | Use `:ref:` labels | `references/rst-syntax.md` |
| Basic RST syntax | Headings, lists, code blocks | `references/rst-syntax.md` |
| Deploy to docs.typo3.org | Setup webhook | `references/intercept-deployment.md` |

**Always: Validate and render before committing**

## Common Mistakes to Avoid

- ❌ Writing "Since v13.0.0" instead of `.. versionadded:: 13.0.0`
- ❌ Using card-grid without `stretched-link` class
- ❌ Skipping local rendering before committing
- ❌ Creating markdown files in Documentation/ (RST only)
- ❌ Missing `:type:`, `:Default:`, or `:Path:` in confval directives
- ❌ Using external links for internal documentation (use `:ref:` instead)
- ❌ **Updating README.md without updating Documentation/** (or vice versa)
- ❌ Using Title Case headlines instead of sentence case
- ❌ Missing permalink anchors (`.. _section-label:`) before section headings
- ❌ List items without ending punctuation (periods)
- ❌ PHP code examples failing CGL checks (run `make fix-cgl`)

## Documentation Synchronization

**Critical Rule:** README.md and Documentation/ must stay synchronized.

**Synchronization checklist:**
1. ✅ Installation steps match between README.md and Documentation/Introduction/
2. ✅ Feature descriptions consistent between README.md and Documentation/Index.rst
3. ✅ Code examples identical (button names, configuration, TypoScript)
4. ✅ Version numbers consistent
5. ✅ Links to external resources point to same destinations

**Fix approach:** Find source of truth (usually code) → Update README.md → Update Documentation/ → Commit together

## Extraction Workflow

Use extraction when starting documentation, auditing coverage, or updating after code changes.

**Quick Start:**
```bash
scripts/extract-all.sh           # Extract documentation data
scripts/analyze-docs.sh          # Generate ANALYSIS.md with gaps
```

**Outputs:**
- `.claude/docs-extraction/data/*.json` - Extracted data
- `Documentation/ANALYSIS.md` - Coverage report with priorities

**Next steps after analysis:**
1. Review Priority 1 items (missing core documentation)
2. Create missing documentation using extracted data
3. Re-run `scripts/analyze-docs.sh` to verify progress

For complete extraction patterns and templates, see: `references/extraction-patterns.md`

For feature-based coverage methodology, see: `references/documentation-coverage-analysis.md`

## Modern TYPO3 13.x Standards

### Default Patterns

**1. Card-Grid Navigation (DEFAULT for Index.rst)**

Always use card-grid instead of plain toctree lists:

```rst
.. card-grid::
   :columns: 1
   :columns-md: 2
   :gap: 4
   :card-height: 100

   .. card:: 📘 Introduction

      Learn what the extension does and key features.

      .. card-footer:: :ref:`introduction`
         :button-style: btn btn-primary stretched-link
```

**2. confval Directive (MANDATORY for Configuration)**

```rst
.. confval:: settingName
   :type: boolean
   :Default: true
   :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['ext_key']['setting']

   Description of the configuration value.
```

**3. guides.xml (PREFERRED over Settings.cfg)**

- guides.xml = modern PHP-based rendering (preferred)
- Settings.cfg = legacy Sphinx-based (migrate to guides.xml)

For guides.xml structure and migration, see: `references/typo3-directives.md`

**4. literalinclude for Code Examples**

Prefer `literalinclude` over inline code blocks for scripts longer than 20 lines:

```rst
..  literalinclude:: _codesnippets/example.php
    :caption: example.php
    :language: php
```

**Benefits:** DRY, testable, GitHub edit links, maintainable

## Validation and Rendering

### Validate Documentation

```bash
scripts/validate_docs.sh /path/to/project
```

Checks: RST syntax, Settings.cfg/guides.xml presence, Index.rst, UTF-8 encoding, trailing whitespace

### Render Locally

```bash
scripts/render_docs.sh /path/to/project
```

Output: `Documentation-GENERATED-temp/Index.html`

**Always render locally before committing to verify:**
- No rendering warnings
- No broken cross-references
- Card grids display correctly

## Pre-Commit Checklist

Before committing documentation changes:

1. Run `scripts/validate_docs.sh` - check RST syntax
2. Run `scripts/render_docs.sh` - verify no warnings
3. Check cross-references resolve correctly
4. Verify confval directives have `:type:`, `:Default:`, `:Path:`
5. Verify card-footer buttons include `stretched-link`
6. Verify sentence case headings (not Title Case)
7. Verify permalink anchors (`.. _label:`) before sections
8. Run `make fix-cgl` for PHP code in `_codesnippets/`

## TYPO3 Intercept Deployment

TYPO3 Intercept automatically builds and publishes documentation to docs.typo3.org.

**Prerequisites:**
1. Extension registered in TER with same key as `composer.json`
2. Repository URL listed on TER detail page
3. Documentation includes `Index.rst` and `guides.xml` (or Settings.cfg)

**Quick Setup (GitHub CLI):**
```bash
gh api repos/{owner}/{repo}/hooks \
  --method POST \
  --field name=web \
  --field "config[url]=https://docs-hook.typo3.org" \
  --field "config[content_type]=json" \
  --field "config[insecure_ssl]=0" \
  --raw-field "events[]=push" \
  --field active=true
```

**First-time builds require TYPO3 Documentation Team approval (1-3 business days).**

For complete webhook setup, manual configuration, and troubleshooting, see: `references/intercept-deployment.md`

## Reference Material

Consult these bundled references for detailed information:

| Challenge | Reference File |
|-----------|----------------|
| Basic RST syntax (headings, lists, code blocks) | `references/rst-syntax.md` |
| TYPO3 directives (confval, card-grid, php:method) | `references/typo3-directives.md` |
| Documentation coverage methodology | `references/documentation-coverage-analysis.md` |
| Extraction patterns and templates | `references/extraction-patterns.md` |
| Webhook setup and deployment | `references/intercept-deployment.md` |
| Extension file structure priorities | `references/typo3-extension-architecture.md` |

**External Resources:**
- TYPO3 Documentation Guide: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/
- RST Specification: https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html
- Best Practice Extension: https://github.com/TYPO3BestPractices/tea

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `scripts/extract-all.sh` | Extract documentation data from all sources |
| `scripts/analyze-docs.sh` | Generate ANALYSIS.md with coverage gaps |
| `scripts/validate_docs.sh` | Validate RST syntax and structure |
| `scripts/render_docs.sh` | Render documentation locally with Docker |
| `scripts/add-agents-md.sh` | Add AGENTS.md for AI assistant context |
