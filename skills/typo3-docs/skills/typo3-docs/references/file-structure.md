# TYPO3 Documentation File Structure

Complete reference for TYPO3 extension documentation file structure.

Based on: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/FileStructure.html

## Minimum Prerequisites

To render documentation, a project must have:

1. A valid `composer.json` in the project root
2. One of these entry points:
   - `Documentation/Index.rst` (full reST documentation)
   - `Documentation/Index.md` (full Markdown documentation)
   - `README.rst` or `README.md` (single-file documentation)

## Full Documentation Structure

```
project-root/
├── composer.json              # Required for rendering
├── README.md                  # Project overview (synced with Documentation/)
└── Documentation/
    ├── guides.xml             # Metadata and rendering configuration
    ├── Index.rst              # Entry point with general info and toctree
    ├── Sitemap.rst            # Auto-populated site structure (optional)
    ├── Includes.rst.txt       # Central includes for all pages (optional)
    ├── Introduction/
    │   └── Index.rst          # Required in every subdirectory
    ├── Installation/
    │   └── Index.rst
    ├── Configuration/
    │   └── Index.rst
    ├── Usage/
    │   └── Index.rst
    ├── Developer/
    │   ├── Index.rst
    │   ├── Api.rst            # Additional pages in CamelCase
    │   ├── Commands.rst
    │   └── _codesnippets/     # Code examples (underscore prefix)
    │       ├── _Example.php
    │       └── _Services.yaml
    └── Images/                # Screenshots and diagrams
        └── screenshot.png
```

## Required Files

| File | Purpose | Required |
|------|---------|----------|
| `composer.json` | Package metadata, required for rendering | Yes |
| `Documentation/guides.xml` | Rendering configuration and metadata | Yes |
| `Documentation/Index.rst` | Entry point with toctree menu | Yes |
| `*/Index.rst` | Fallback file in each subdirectory | Yes |

## Optional Files

| File | Purpose |
|------|---------|
| `README.md` | Project overview, synced with Documentation/ |
| `Documentation/Sitemap.rst` | Auto-populated site structure |
| `Documentation/Includes.rst.txt` | Global includes for all pages |
| `Documentation/Images/` | Screenshots and diagrams |

## Naming Conventions

### Directories and Files

- **CamelCase** for all directory and file names
- ✅ Correct: `Configuration/Index.rst`, `Developer/TcaIntegration.rst`
- ❌ Wrong: `configuration/index.rst`, `developer/tca-integration.rst`

### Special File Extensions

| Extension | Usage |
|-----------|-------|
| `.rst` | Standard reStructuredText files |
| `.rst.txt` | Included RST files (not standalone) |
| `.md` | Markdown files (if using Markdown documentation) |

### Code Snippet Files

Files containing code examples should start with an underscore:

- `_Example.php` - PHP code example
- `_Services.yaml` - YAML configuration example
- `_setup.typoscript` - TypoScript example

This convention indicates the files are documentation assets, not production code.

## Directory Structure Rules

### Index.rst in Every Directory

Every directory **must** have an `Index.rst` file. This serves as:

1. The default page for the directory
2. A fallback when switching between documentation versions
3. The container for the directory's toctree

**Example:**
```rst
.. include:: /Includes.rst.txt

.. _configuration:

=============
Configuration
=============

.. toctree::
   :maxdepth: 2

   Extension
   SiteConfiguration
   TypoScript
```

### Standard Directory Names

Common directory names for TYPO3 extension documentation:

| Directory | Content |
|-----------|---------|
| `Introduction/` | What the extension does, features, requirements |
| `Installation/` | Composer installation, setup steps |
| `Configuration/` | Extension settings, TypoScript, TSconfig |
| `Usage/` | How to use the extension, examples |
| `Developer/` | API reference, extending, events |
| `Security/` | Security considerations (if applicable) |
| `Changelog/` | Version history (if applicable) |
| `Images/` | Screenshots and diagrams |

## guides.xml Configuration

The `guides.xml` file configures documentation rendering:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<guides
    xmlns="https://www.phpdoc.org/guides"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="https://www.phpdoc.org/guides vendor/phpdocumentor/guides-cli/resources/schema/guides.xsd"
    theme="typo3docs"
>
    <project
        title="Extension Name"
        version="1.0"
        release="1.0.0"
        copyright="Vendor Name"
    />

    <extension
        class="\T3Docs\Typo3DocsTheme\DependencyInjection\Typo3DocsThemeExtension"
        project-home="https://github.com/vendor/extension"
        project-contact="https://github.com/vendor/extension/issues"
        project-repository="https://github.com/vendor/extension"
        edit-on-github="vendor/extension"
        edit-on-github-branch="main"
    />

    <inventory id="t3coreapi" url="https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/"/>
</guides>
```

**Key Points:**
- `theme` must be an **attribute** on `<guides>`, not a child element
- `edit-on-github` enables "Edit on GitHub" button in rendered docs
- `<inventory>` elements enable intersphinx cross-references

## Includes.rst.txt

Central file for substitutions and includes used across all pages:

```rst
.. This file contains global includes for all documentation files.

.. |extension_key| replace:: my_extension
.. |extension_name| replace:: My Extension
.. |vendor| replace:: My Company

.. _vendor-website: https://example.com/
.. _github-repo: https://github.com/vendor/extension
```

Include at the top of every RST file:
```rst
.. include:: /Includes.rst.txt
```

## Sitemap.rst

Optional file that displays the complete site structure:

```rst
.. include:: /Includes.rst.txt

.. _sitemap:

=======
Sitemap
=======

See the :doc:`table of contents </Index>` for a complete overview.
```

The sitemap is auto-populated during rendering.

## Single-File Documentation

For simple extensions, use `README.rst` or `README.md` in the project root instead of a full `Documentation/` directory:

```
project-root/
├── composer.json
└── README.rst    # or README.md
```

## Validation Checklist

Before committing documentation:

1. ✅ `composer.json` exists in project root
2. ✅ `Documentation/guides.xml` exists with valid configuration
3. ✅ `Documentation/Index.rst` exists as entry point
4. ✅ Every subdirectory has an `Index.rst` file
5. ✅ All directories and files use CamelCase naming
6. ✅ Included files use `.rst.txt` extension
7. ✅ Code snippet files start with underscore
8. ✅ `.. include:: /Includes.rst.txt` at top of every RST file

## Common Mistakes

### Missing Index.rst

❌ **Wrong:**
```
Documentation/
├── Configuration/
│   └── Settings.rst    # No Index.rst!
```

✅ **Correct:**
```
Documentation/
├── Configuration/
│   ├── Index.rst       # Required!
│   └── Settings.rst
```

### Wrong File Naming

❌ **Wrong:**
```
Documentation/
├── configuration/      # lowercase
│   └── index.rst       # lowercase
```

✅ **Correct:**
```
Documentation/
├── Configuration/      # CamelCase
│   └── Index.rst       # CamelCase
```

### Theme as Element

❌ **Wrong:**
```xml
<guides>
    <theme name="typo3docs"/>   <!-- Wrong! -->
</guides>
```

✅ **Correct:**
```xml
<guides theme="typo3docs">      <!-- Attribute, not element -->
</guides>
```

## References

- **TYPO3 File Structure:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/FileStructure.html
- **guides.xml Reference:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/GuidesXml/Index.html
