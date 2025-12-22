---
name: typo3-docs
description: "Create and maintain TYPO3 extension documentation following official TYPO3 13.x standards. Use when creating/editing Documentation/*.rst files or README.md, using TYPO3 directives (confval, versionadded, card-grid), rendering docs locally, extracting documentation data, or deploying to docs.typo3.org. Covers RST syntax, TYPO3-specific directives, documentation extraction/analysis, local Docker rendering, validation, webhook setup, and Intercept deployment. By Netresearch."
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
- Using TYPO3 directives: `confval`, `versionadded`, `versionchanged`, `card-grid`, `uml`
- Using PHP domain: `php:class`, `php:method`, `php:interface`, `php:trait`, `php:attr`, `php:const`
- Using text roles: `:php:`, `:typoscript:`, `:file:`, `:path:`, `:guilabel:`, `:confval:`, `:ref:`
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
| PHP API documentation | Use `php:class`, `php:method` directives | `references/typo3-directives.md` |
| Visual navigation | Use card-grid with `stretched-link` | `references/typo3-directives.md` |
| Architecture diagrams | Use PlantUML `uml::` directive | `references/typo3-directives.md` |
| Inline PHP code | Use `:php:` text role | `references/text-roles-inline-code.md` |
| File/path references | Use `:file:` or `:path:` roles | `references/text-roles-inline-code.md` |
| GUI elements | Use `:guilabel:` text role | `references/text-roles-inline-code.md` |
| Code blocks | Use `code-block::` with `:caption:` | `references/rst-syntax.md` |
| Cross-references | Use `:ref:` labels | `references/rst-syntax.md` |
| Basic RST syntax | Headings, lists, tables | `references/rst-syntax.md` |
| Adding screenshots | PNG format, alt text, light mode | See "Image Guidelines" section |
| File/folder naming | CamelCase, Index.rst per directory | See "File Structure Rules" section |
| Check spelling | American English, Merriam-Webster | See "Spelling and Style" section |
| Deploy to docs.typo3.org | Setup webhook | `references/intercept-deployment.md` |

**Always: Validate and render before committing**

## Formatting Rules (MANDATORY)

### Encoding and Whitespace

- **Encoding**: UTF-8 for all files
- **Indentation**: 4 spaces (no tabs)
- **Trailing whitespace**: Remove all trailing spaces/tabs
- **Line length**: Keep lines under 80 characters

### EditorConfig

Add `.editorconfig` to enforce standards:

```ini
[*.{rst,rst.txt}]
charset = utf-8
indent_style = space
indent_size = 4
end_of_line = lf
trim_trailing_whitespace = true
insert_final_newline = true
max_line_length = 80
```

### Heading Hierarchy

Use consistent underline characters per level:

| Level | Character | Usage |
|-------|-----------|-------|
| 1 (Title) | `=` above and below | Page title only |
| 2 | `=` below | Major sections |
| 3 | `-` below | Subsections |
| 4 | `~` below | Sub-subsections |
| 5 | `"` below | Paragraphs |
| 6 | `'` below | Deep nesting |

**Rules:**
- Underline must match title length exactly
- Use **sentence case** for all headings (not Title Case)
- Every section MUST have a permalink anchor (`.. _label:`)

## File Structure Rules (MANDATORY)

### Naming Conventions

- **CamelCase** for directories and files: `GeneralConventions/FileStructure.rst`
- **Index.rst** required in every directory (fallback for version switching)
- **Included files**: Use `.rst.txt` extension (e.g., `Includes.rst.txt`)
- **Code snippets**: Start with underscore (e.g., `_codesnippets/example.php`)

### Required Structure

```
Documentation/
├── guides.xml              # Configuration (REQUIRED)
├── Index.rst               # Entry point (REQUIRED)
├── Includes.rst.txt        # Global includes (REQUIRED)
├── Introduction/
│   └── Index.rst           # REQUIRED in each directory
├── Configuration/
│   └── Index.rst
└── Images/                 # Screenshots and graphics
```

### Navigation Title

Use `:navigation-title:` for custom menu labels:

```rst
:navigation-title: Quick Start

===============
Getting Started
===============
```

## Image Guidelines (MANDATORY)

### Screenshot Standards

| Requirement | Value |
|-------------|-------|
| **Format** | PNG (`.png`) |
| **Full page dimensions** | 1400 × 1050 pixels |
| **Alt text** | Always required for accessibility |
| **Backend mode** | Light mode, modern look |
| **Username** | "j.doe" (standardized) |
| **TYPO3 version** | Latest LTS, Composer-based |

### Figure Syntax

```rst
..  figure:: /Images/screenshot.png
    :alt: Description for accessibility
    :class: with-shadow

    Caption text describing the screenshot
```

### Best Practices

- ✅ Prefer partial screenshots over full-page captures
- ✅ Use sufficient contrast for annotations (boxes, arrows)
- ✅ Avoid third-party extensions in screenshots
- ✅ Keep screenshots minimal and focused
- ❌ Don't use JPG/JPEG for screenshots
- ❌ Don't include sensitive data

## Spelling and Style (MANDATORY)

### American English

Use American English spelling (reference: Merriam-Webster):
- ✅ "color", "optimize", "behavior"
- ❌ "colour", "optimise", "behaviour"

### Compound Words (TYPO3-Specific)

| Correct | Incorrect |
|---------|-----------|
| backend | back-end, back end |
| frontend | front-end, front end |
| sitepackage | site package, site-package |

### Brand Names vs Commands

| Brand Name | Command |
|------------|---------|
| Git | `git` |
| Docker | `docker` |
| Composer | `composer` |

Use capitalized form in prose, backtick form for commands:
- "Use Git for version control" (brand)
- "Run :bash:`git status`" (command)

### Special Spellings (Preserve Exactly)

- TypoScript, TSconfig, ViewHelper
- Backend, Frontend (when referring to TYPO3 areas)
- HTML, PHP, CMS, LTS, FAL (acronyms uppercase)

### GUI Elements

Match exact interface capitalization:
- :guilabel:`File > Open` (matches menu)
- :guilabel:`ADMIN TOOLS > Extensions` (matches UI)

## Conformance Rules

### Text Roles (MANDATORY)

Always use semantic text roles instead of plain backticks:

| Content Type | Role | Example |
|--------------|------|---------|
| PHP code/classes | `:php:` | `:php:\`GeneralUtility\`` |
| TypoScript | `:typoscript:` | `:typoscript:\`lib.parseFunc_RTE\`` |
| File names | `:file:` | `:file:\`ext_localconf.php\`` |
| Directory paths | `:path:` | `:path:\`Configuration/TypoScript/\`` |
| GUI elements | `:guilabel:` | `:guilabel:\`Save\`` |
| Menu paths | `:menuselection:` | `:menuselection:\`File --> Save\`` |
| Keyboard shortcuts | `:kbd:` | `:kbd:\`Ctrl+S\`` |
| HTML elements | `:html:` | `:html:\`<img>\`` |
| YAML config | `:yaml:` | `:yaml:\`key: value\`` |
| SQL queries | `:sql:` | `:sql:\`SELECT * FROM\`` |
| Shell commands | `:bash:` | `:bash:\`composer install\`` |
| Config references | `:confval:` | `:confval:\`fetchExternalImages\`` |
| Cross-references | `:ref:` | `:ref:\`section-label\`` |

**Decision Tree:**
- Is it a file? → `:file:`
- Is it a directory? → `:path:`
- Is it PHP? → `:php:`
- Is it TypoScript? → `:typoscript:`
- Is it a button/UI element? → `:guilabel:`
- Is it a menu navigation? → `:menuselection:`
- Is it a config value? → `:confval:`

For complete text role reference, see: `references/text-roles-inline-code.md`

### Code Blocks (MANDATORY)

Always include `:caption:` for code blocks:

```rst
..  code-block:: php
    :caption: Classes/Service/MyService.php

    <?php
    $code = 'example';
```

**Required Options:**
- `:caption:` - Always include (typically file path)
- `:language:` - Specify explicitly (php, typoscript, yaml, bash, html, etc.)

**Optional Options:**
- `:linenos:` - Show line numbers
- `:emphasize-lines:` - Highlight specific lines (e.g., `3,5-7`)
- `:lineno-start:` - Start line numbers at N
- `:name:` - Unique reference label

For code blocks reference, see: `references/rst-syntax.md`

### confval Directive (MANDATORY for Configuration)

All configuration values MUST use the `confval` directive:

```rst
..  confval:: settingName
    :name: confval-settingname
    :type: boolean
    :Default: true
    :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['ext_key']['setting']

    Description of the configuration value.
```

**Required Fields:**
- `:type:` - Data type (boolean, string, integer, array)
- `:Default:` - Default value
- `:Path:` - Full configuration path

**Optional Fields:**
- `:name:` - For cross-referencing with `:confval:`
- `:Required:` - If value is mandatory

### PHP Domain (for API Documentation)

Use PHP domain directives for class/method documentation:

```rst
..  php:class:: MyClass

    Class description.

    ..  php:method:: myMethod($param)

        :param string $param: Parameter description.
        :returns: Return value description.
        :returntype: string
```

For complete PHP domain reference, see: `references/typo3-directives.md`

### PlantUML Diagrams (Optional)

For architectural diagrams, use the `uml` directive:

```rst
..  uml::
    :caption: Component diagram

    @startuml
    component Frontend
    component Backend
    Frontend --> Backend
    @enduml
```

For PlantUML reference, see: `references/typo3-directives.md`

## Common Mistakes to Avoid

### Text Role Errors
- ❌ Using backticks `\`\`code\`\`` instead of `:php:\`code\``
- ❌ Using `:file:` for directories (use `:path:` instead)
- ❌ Plain text for UI elements (use `:guilabel:` instead)

### Code Block Errors
- ❌ Missing `:caption:` on code blocks
- ❌ Using `::` shorthand instead of `..  code-block::`
- ❌ Wrong language identifier (e.g., `javascript` for TypoScript)

### Directive Errors
- ❌ Writing "Since v13.0.0" instead of `.. versionadded:: 13.0.0`
- ❌ Using card-grid without `stretched-link` class
- ❌ Missing `:type:`, `:Default:`, or `:Path:` in confval directives

### Formatting Errors
- ❌ Using tabs instead of 4 spaces for indentation
- ❌ Lines exceeding 80 characters
- ❌ Trailing whitespace at end of lines
- ❌ Non-UTF-8 file encoding
- ❌ Underline length not matching heading text

### File Structure Errors
- ❌ Using lowercase or kebab-case file names (use CamelCase: `FeatureOverview.rst`)
- ❌ Missing `Index.rst` in subdirectories
- ❌ Using `.rst` for included files (use `.rst.txt`)
- ❌ Code snippets not prefixed with underscore (`_codesnippets/`)

### Image Errors
- ❌ Using JPG/JPEG format (use PNG)
- ❌ Missing `:alt:` text on figures
- ❌ Full-page screenshots when partial would suffice
- ❌ Screenshots in dark mode (use light mode)
- ❌ Non-standard username in screenshots (use "j.doe")

### Spelling/Style Errors
- ❌ British spelling ("colour", "behaviour")
- ❌ Hyphenated compounds ("back-end" instead of "backend")
- ❌ Lowercase brand names in prose ("use git" instead of "use Git")
- ❌ Wrong case for special terms ("Typoscript" instead of "TypoScript")

### Structure Errors
- ❌ Skipping local rendering before committing
- ❌ Creating markdown files in Documentation/ (RST only)
- ❌ Using external links for internal documentation (use `:ref:` instead)
- ❌ **Updating README.md without updating Documentation/** (or vice versa)
- ❌ Using Title Case headlines instead of sentence case
- ❌ Missing permalink anchors (`.. _section-label:`) before section headings
- ❌ List items without ending punctuation (periods)
- ❌ PHP code examples failing CGL checks (run `make fix-cgl`)
- ❌ **Committing `Documentation-GENERATED-temp/`** (add to `.gitignore`)

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

**Important:** Add `Documentation-GENERATED-temp/` to `.gitignore` - this is a build artifact that should not be committed.

**Always render locally before committing to verify:**
- No rendering warnings
- No broken cross-references
- Card grids display correctly

## Pre-Commit Checklist

Before committing documentation changes:

**Validation:**
1. Run `scripts/validate_docs.sh` - check RST syntax.
2. Run `scripts/render_docs.sh` - verify no warnings.

**Formatting:**
3. UTF-8 encoding, 4-space indentation, no tabs.
4. Lines under 80 characters (where practical).
5. No trailing whitespace.
6. Underlines match heading text length exactly.

**Text Roles:**
7. `:php:` for PHP code, not backticks.
8. `:file:` for files, `:path:` for directories.
9. `:guilabel:` for GUI elements.
10. `:typoscript:` for TypoScript code.

**Directives:**
11. Code blocks have `:caption:` option.
12. confval directives have `:type:`, `:Default:`, `:Path:`.
13. card-footer buttons include `stretched-link`.

**Structure:**
14. CamelCase file/directory names.
15. Index.rst in every subdirectory.
16. Permalink anchors (`.. _label:`) before sections.
17. Sentence case headings (not Title Case).
18. List items end with periods.

**Images:**
19. PNG format (not JPG/JPEG).
20. All figures have `:alt:` text.
21. Screenshots use light mode, "j.doe" username.

**Spelling:**
22. American English (color, optimize, behavior).
23. Correct compound words (backend, sitepackage).
24. Brand names capitalized in prose (Git, Docker).

**Code:**
25. Run `make fix-cgl` for PHP code in `_codesnippets/`.
26. Cross-references resolve correctly.

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
| Text roles and inline code (`:php:`, `:file:`, `:guilabel:`) | `references/text-roles-inline-code.md` |
| Basic RST syntax (headings, lists, code blocks) | `references/rst-syntax.md` |
| TYPO3 directives (confval, card-grid, php domain, PlantUML) | `references/typo3-directives.md` |
| Documentation coverage methodology | `references/documentation-coverage-analysis.md` |
| Extraction patterns and templates | `references/extraction-patterns.md` |
| Webhook setup and deployment | `references/intercept-deployment.md` |
| Extension file structure priorities | `references/typo3-extension-architecture.md` |

**External Resources (Official TYPO3 Guidelines):**
- TYPO3 Documentation Guide: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/
- Coding Guidelines: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/CodingGuidelines/Index.html
- Advanced Coding Guidelines: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Advanced/CodingGuidelines.html
- Image Guidelines: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Advanced/GuidelinesForImages.html
- Content Style Guide: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Advanced/ContentStyleGuide.html
- guides.xml Reference: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/GuidesXml.html
- File Structure: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/FileStructure.html
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
