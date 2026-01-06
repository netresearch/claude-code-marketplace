---
name: typo3-docs
description: "Create and maintain TYPO3 extension documentation following official docs.typo3.org standards. Use when creating/editing Documentation/*.rst files or README.md, using TYPO3 directives (confval, versionadded, card-grid, accordion, tabs, admonitions), creating/adding screenshots, rendering/testing/viewing docs locally, or deploying to docs.typo3.org. By Netresearch."
---

# TYPO3 Documentation

## When to Use

- **Creating documentation from scratch** (no `Documentation/` exists) → Use `init` command
- Creating new `Documentation/` directory structure
- Editing `Documentation/**/*.rst` files
- Creating `Documentation/guides.xml` or updating `Settings.cfg`
- Using TYPO3 directives: `confval`, `versionadded`, `card-grid`, `accordion`, `tabs`
- Using text roles: `:php:`, `:file:`, `:guilabel:`, `:ref:`
- **Creating/adding screenshots**: Docker container, image guidelines
- **Rendering documentation**: `scripts/render_docs.sh`, Docker container
- **Live-viewing documentation**: Watch mode with auto-rebuild (`--watch`)
- **Testing/validating documentation**: `scripts/validate_docs.sh`
- **Viewing/showing documentation**: Render and open in browser
- Deploying to docs.typo3.org

## Core Workflow

1. Read reference files for the task at hand (see table below)
2. Use TYPO3 directives, not plain text equivalents
3. Validate: `scripts/validate_docs.sh`
4. Render: `scripts/render_docs.sh`
5. **Verify rendered output visually** (open in browser)
6. Keep README.md and Documentation/ synchronized
7. Commit together atomically

> **Critical**: When user asks to "show docs", render and display the HTML output, not raw RST.

## Creating Documentation from Scratch

When asked to create documentation and no `Documentation/` directory exists, **always use the `init` command first**:

```bash
docker run --rm --pull always -v $(pwd):/project -it \
  ghcr.io/typo3-documentation/render-guides:latest init
```

**Interactive prompts:**
1. **Format**: Choose `rst` (ReStructuredText) for full TYPO3 theme features
2. **Site Set**: Enter name/path if extension defines a Site set (auto-generates config docs)

**After init, enhance the generated files:**
1. **Create `.editorconfig`** in `Documentation/` folder (see Critical Rules)
2. Update `guides.xml` with GitHub integration (see guides.xml section)
3. Expand `Index.rst` with proper toctree
4. Create section directories with `Index.rst` files
5. Add content based on extension features

**Prerequisites:**
- `composer.json` must exist in project root
- Docker must be running

See `references/rendering.md` for complete init documentation.

## Quick Reference Table

| Task | Reference File |
|------|----------------|
| File structure and naming conventions | `references/file-structure.md` |
| guides.xml configuration | `references/guides-xml.md` |
| Coding guidelines and .editorconfig | `references/coding-guidelines.md` |
| **Code blocks, confval, PHP domain** | `references/code-structure-elements.md` |
| **Content directives (accordion, tabs, cards)** | `references/content-directives.md` |
| Rendering, testing, viewing documentation | `references/rendering.md` |
| Screenshots and images | `references/screenshots.md` |
| Text roles (`:php:`, `:file:`, `:guilabel:`) | `references/text-roles-inline-code.md` |
| RST syntax (headings, lists, code blocks) | `references/rst-syntax.md` |
| TYPO3 directives (confval, card-grid, PlantUML) | `references/typo3-directives.md` |
| Documentation extraction and analysis | `references/extraction-patterns.md` |
| Coverage methodology | `references/documentation-coverage-analysis.md` |
| Webhook setup and deployment | `references/intercept-deployment.md` |
| Extension architecture context | `references/typo3-extension-architecture.md` |
| Architecture Decision Records (ADRs) | `references/architecture-decision-records.md` |

## Critical Rules (Always Apply)

- **`.editorconfig`** required in `Documentation/` folder (see template below)
- **UTF-8** encoding, **4-space** indentation, no tabs
- **80 characters** max line length
- **LF** line endings (Unix-style), no trailing whitespace
- **Sentence case** headings (not Title Case)
- **CamelCase** file/directory names
- **Index.rst** required in every subdirectory
- **American English** spelling (color, behavior, optimize)
- **PNG format** for screenshots, always include `:alt:` text

### Required .editorconfig

Create `Documentation/.editorconfig`:

```editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 4
insert_final_newline = true
trim_trailing_whitespace = true
max_line_length = 80
```

See `references/coding-guidelines.md` for complete formatting rules.

## Text Roles (Must Use)

| Content | Role |
|---------|------|
| PHP code | `:php:\`ClassName\`` |
| TypoScript | `:typoscript:\`lib.parseFunc\`` |
| YAML | `:yaml:\`imports\`` |
| Files | `:file:\`ext_localconf.php\`` |
| Directories | `:path:\`Configuration/\`` |
| UI elements | `:guilabel:\`Save\`` |
| Keyboard shortcuts | `:kbd:\`Ctrl+S\`` |

See `references/text-roles-inline-code.md` for complete list.

## Code Blocks and Structure Elements

### Use the Right Element

| Content Type | Element |
|--------------|---------|
| **Complete code examples (5+ lines)** | **`..  literalinclude::` (preferred)** |
| Short inline snippets (< 5 lines) | `..  code-block:: <language>` |
| Configuration options | `..  confval::` |
| PHP API documentation | `..  php:class::`, `..  php:method::` |
| Site settings | `..  typo3:site-set-settings::` |

### literalinclude (Preferred for Code)

Store code as source files with underscore prefix, include via `literalinclude`:

```rst
..  literalinclude:: _TranslationService.php
    :language: php
    :caption: EXT:my_ext/Classes/Service/TranslationService.php
```

**File naming:** `_ClassName.php`, `_config.yaml`, `_tca-table.php`

**Benefits:** IDE support, syntax validation, reusability, maintainability.

### code-block (Short Snippets Only)

Use only for very short examples (< 5 lines):

```rst
..  code-block:: php
    :caption: Quick example

    $vault->http()->withAuthentication($key, SecretPlacement::Bearer);
```

**Always include:**
- `:caption:` with file path or description
- Correct language identifier
- Syntactically valid code (highlighting fails on errors)

### confval for Configuration

Use `confval` for extension settings, TCA fields, TypoScript properties:

```rst
..  confval:: encryptionMethod
    :name: ext-vault-encryptionMethod
    :type: string
    :default: 'aes-256-gcm'

    Description of the configuration option.
```

See `references/code-structure-elements.md` for complete guide.

## Content Directives

Use the right directive for structured content:

| Content Type | Directive | When to Use |
|--------------|-----------|-------------|
| Collapsible content | `accordion` | FAQ, optional details |
| Important notices | `note`, `tip`, `warning` | Callouts, caveats |
| Feature grids | `card-grid` | Overview pages, navigation |
| Alternative examples | `tabs` | Multi-language code, variants |
| Version changes | `versionadded`, `deprecated` | API changes |

### Admonitions (Use Appropriately)

```rst
..  note::
    Background information users should know.

..  tip::
    Helpful suggestion for better results.

..  warning::
    Potential issue or data loss risk.
```

### Tabs (Synchronized)

```rst
..  tabs::

    ..  group-tab:: Composer

        Run :bash:`composer require vendor/package`

    ..  group-tab:: Classic

        Download and install manually.
```

Tabs with the same name synchronize across the page.

See `references/content-directives.md` for complete guide.

## Required File Structure

Full documentation requires this structure (per [TYPO3 File Structure](https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/FileStructure.html)):

```
project-root/
├── composer.json         # Required for rendering
├── README.md             # Project overview (synced with Documentation/)
└── Documentation/
    ├── guides.xml        # Metadata and rendering config (required)
    ├── Index.rst         # Entry point with toctree (required)
    ├── Sitemap.rst       # Auto-populated site structure (optional)
    ├── Includes.rst.txt  # Global includes for all pages (optional)
    └── SectionName/      # CamelCase directories
        └── Index.rst     # Required in every subdirectory
```

**Naming Conventions:**
- **CamelCase** for directories and files: `Configuration/Index.rst`, `Developer/TcaIntegration.rst`
- **Index.rst** required in every directory (fallback during version switching)
- Included RST files use `.rst.txt` extension: `Includes.rst.txt`
- Code snippet files start with underscore: `_Services.yaml`, `_Example.php`

**Minimum Prerequisites:**
- Valid `composer.json` in project root
- Entry point: `Documentation/Index.rst` (or `README.md` for single-file docs)

## guides.xml Configuration

Extract project metadata from `composer.json` and GitHub to create a comprehensive `guides.xml`:

```xml
<guides theme="typo3docs">
    <project title="Extension Name" copyright="since 2024 by Vendor"/>
    <extension
        class="\T3Docs\Typo3DocsTheme\DependencyInjection\Typo3DocsThemeExtension"
        edit-on-github="owner/repo"
        edit-on-github-branch="main"
        project-repository="https://github.com/owner/repo"
        project-issues="https://github.com/owner/repo/issues"
        interlink-shortcode="vendor/package-name"
    />
    <inventory id="t3coreapi" url="https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/"/>
</guides>
```

**Extract from sources:**
- `composer.json`: `name` → interlink-shortcode, `authors` → copyright, `support` → project-issues
- GitHub: `owner/repo` → edit-on-github, default branch → edit-on-github-branch
- Git remote: `git remote get-url origin` to determine owner/repo

See `references/guides-xml.md` for complete configuration options.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/validate_docs.sh` | Validate RST syntax |
| `scripts/render_docs.sh` | Render locally with Docker |
| `scripts/watch_docs.sh` | Live-view with auto-rebuild (watch mode) |
| `scripts/extract-all.sh` | Extract documentation data |
| `scripts/analyze-docs.sh` | Generate coverage analysis |

## Screenshots

When writing or reviewing documentation, **proactively suggest screenshots** where they would help users:

### Suggest Screenshots For

- **Backend module interfaces** - Show where to find features
- **Configuration screens** - Extension settings, site configuration
- **Complex UI workflows** - Multi-step processes
- **Visual results** - Frontend output demonstrating features

### Do NOT Add Screenshots For

- Simple button clicks (use `:guilabel:` role instead)
- Information easily conveyed in text
- Standard TYPO3 interfaces that rarely change

### Creating Screenshots

Use the official Docker container for consistent screenshots:
```bash
docker run -d --name typo3-screenshots -p 8080:80 linawolf/typo3-screenshots
```

**Requirements:** PNG format, 1400x1050 or cropped, light mode, `j.doe` username.

See `references/screenshots.md` for complete guidelines.

## Pre-Commit Checklist

1. **`.editorconfig`**: Exists in `Documentation/` with correct settings
2. **File structure**: Every directory has `Index.rst`, CamelCase naming
3. **Formatting**: 4-space indentation, no tabs, max 80 chars, LF line endings
4. **Code blocks**: Have `:caption:`, correct language, valid syntax
5. **Configuration**: Uses `confval` directive with `:type:`, `:default:`
6. **Text roles**: Inline code uses proper roles (`:php:`, `:file:`, etc.)
7. **Content directives**: Correct admonition type, synchronized tab names
8. **Version directives**: Include version number, deprecations mention replacement
9. **guides.xml**: Valid config with edit-on-github, project links, inventories
10. **Screenshots**: PNG format, proper alt text, stored in `Documentation/Images/`
11. `scripts/validate_docs.sh` passes
12. `scripts/render_docs.sh` shows no warnings
13. **Visual verification**: Open rendered HTML and confirm formatting
14. README.md and Documentation/ are in sync (no contradictions)
15. `Documentation-GENERATED-temp/` is in `.gitignore`

## README.md Synchronization

"In sync" means **content parity** and **consistency**, not duplication:

- **Parity**: Topics in README.md should be covered in Documentation/.
- **Consistency**: Shared topics must not contradict (CLI commands, code examples, configs).
- **Source of truth**: Documentation/ is authoritative; update README.md to match.

See `references/rst-syntax.md` for detailed examples.

For detailed guidelines, read the appropriate reference file before starting work.

---

> **Contributing:** Improvements to this skill should be submitted to the source repository:
> https://github.com/netresearch/typo3-docs-skill
