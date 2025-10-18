# Documentation Context for AI Assistants

This is the official TYPO3 extension documentation directory in reStructuredText (RST) format.

## Documentation Type

**TYPO3 Extension Documentation** - Published at docs.typo3.org

## Documentation Strategy

<!-- Describe what this documentation covers and its target audience -->
<!-- Example: "End-user guide for content editors using the extension features" -->
<!-- Example: "Technical integration guide for developers implementing custom configurations" -->
<!-- Example: "Complete extension documentation including user guide, configuration reference, and API docs" -->

**Target Audience:**

**Main Topics:**

**Not Covered:** <!-- What is intentionally documented elsewhere -->

## Documentation Framework

- **Format**: reStructuredText (RST)
- **Build System**: TYPO3 Documentation rendering tools
- **Published At**: https://docs.typo3.org/p/[vendor]/[extension]/main/en-us/
- **Automated Build**: TYPO3 Intercept webhook deployment

## File Structure

### Required Files

- `Index.rst` - Main documentation entry point
- `Settings.cfg` - Documentation metadata and configuration

### Common Sections

- `Introduction/` - Getting started, features overview
- `Installation/` - Installation and upgrade guides
- `Configuration/` - TypoScript, extension configuration
- `Integration/` - Integration with other systems
- `Editor/` - User guide for content editors
- `Developer/` - Developer documentation
- `API/` - PHP API reference documentation
- `Troubleshooting/` - Common issues and solutions

## TYPO3-Specific Directives

### Configuration Documentation

Use `confval` for configuration options:

```rst
.. confval:: myOption
   :name: ext-myext-myoption
   :type: string
   :Default: 'default value'

   Description of the configuration option.
```

### Version Documentation

Document version-specific features:

```rst
.. versionadded:: 2.0
   Support for feature X was added.

.. versionchanged:: 2.1
   Behavior changed to improve performance.

.. deprecated:: 2.2
   This feature will be removed in version 3.0.
```

### PHP API Documentation

Document PHP methods and classes:

```rst
.. php:method:: processData(array $data): array

   Process the provided data array.

   :param array $data: The input data
   :returns: Processed data array
```

### Card Grid Navigation

Create visual navigation with card grids:

```rst
.. card-grid::
   :columns: 2
   :gap: 4

   .. card:: :ref:`Installation <installation>`

      How to install and configure the extension.

   .. card:: :ref:`Configuration <configuration>`

      TypoScript and extension configuration reference.
```

## Cross-References

### Internal References

```rst
.. _my-section-label:

Section Title
=============

Reference it with :ref:`my-section-label` or :ref:`custom text <my-section-label>`
```

### External TYPO3 Docs

```rst
:ref:`t3coreapi:caching` - Reference to TYPO3 Core API docs
:ref:`t3tsref:stdwrap` - Reference to TypoScript Reference
```

### Code References

```rst
:php:`ClassName` - PHP class
:ts:`config.tx_myext` - TypoScript
:file:`Configuration/TCA/` - File path
:bash:`composer require` - Shell command
```

## RST Syntax Patterns

### Headings

```rst
=============
Document Title (Level 1 - only once per file)
=============

Section (Level 2)
=================

Subsection (Level 3)
--------------------

Subsubsection (Level 4)
^^^^^^^^^^^^^^^^^^^^^^^
```

### Lists

```rst
Bullet list:

*  Item 1
*  Item 2

Numbered list:

#. First
#. Second

Definition list:

Term
   Definition of the term.
```

### Code Blocks

```rst
.. code-block:: php

   <?php
   $variable = 'value';

.. code-block:: typoscript

   plugin.tx_myext {
      setting = value
   }
```

### Admonitions

```rst
.. note::
   Important information for users.

.. warning::
   Critical warning about potential issues.

.. tip::
   Helpful suggestion or best practice.
```

## Local Rendering

### Render Documentation

```bash
# Using Docker (recommended)
cd Documentation
docker run --rm --pull always \
  -v $(pwd):/project \
  ghcr.io/typo3-documentation/render-guides:latest \
  --config=Documentation

# View output
open Documentation-GENERATED-temp/Result/project/0.0.0/Index.html
```

### Validate Documentation

```bash
# Check for syntax errors and warnings
scripts/validate_docs.sh

# Common issues to check:
# - Broken cross-references
# - Invalid directive syntax
# - Heading level inconsistencies
# - Missing required files
```

## Deployment

### TYPO3 Intercept Webhook

Documentation is automatically built and deployed when:

1. Changes pushed to `main` branch
2. Webhook configured in Settings.cfg
3. TYPO3 Intercept receives notification
4. Documentation rebuilt and published

### Settings.cfg Configuration

```ini
[general]
project = Extension Name
version = 1.0
release = 1.0.0
copyright = 2024

[html_theme_options]
project_repository = https://github.com/vendor/extension
```

## Documentation Extraction and Analysis

### Using Extraction Tools

Before creating or updating documentation, use extraction tools to:

1. **Identify gaps** - Find undocumented classes, methods, and configuration options
2. **Ensure accuracy** - Verify documented defaults match actual code
3. **Speed up documentation** - Use extracted data as templates

### Extraction Workflow

**Step 1: Extract Project Data**

```bash
# From project root directory
cd /path/to/extension
scripts/extract-all.sh              # Core extraction (PHP, configs, composer)
scripts/extract-all.sh --all        # Include build configs and repo metadata
```

Extraction data saved to `.claude/docs-extraction/data/`:
- `php_apis.json` - Classes, methods, docblocks
- `extension_meta.json` - ext_emconf.php data
- `config_options.json` - ext_conf_template.txt options
- `dependencies.json` - composer.json requirements
- `project_files.json` - README, CHANGELOG content

**Step 2: Analyze Coverage**

```bash
scripts/analyze-docs.sh
```

Generates `Documentation/ANALYSIS.md` with:
- Missing documentation items
- Outdated configuration defaults
- Inconsistencies between code and docs
- Prioritized recommendations

**Step 3: Review Analysis**

Open `Documentation/ANALYSIS.md` and identify:
- **Priority 1**: Missing core documentation (undocumented classes, essential configs)
- **Priority 2**: Outdated content (wrong defaults, old signatures)
- **Priority 3**: Enhancement opportunities (missing examples, incomplete descriptions)

**Step 4: Use Extracted Data**

When documenting items from ANALYSIS.md:

1. **Open corresponding JSON file** in `.claude/docs-extraction/data/`
2. **Copy relevant information** (descriptions, defaults, types)
3. **Create RST documentation** using proper directives
4. **Add examples and context** beyond extracted data

### Example: Using Extracted Config Data

**ANALYSIS.md identifies missing option:**
```
### fetchExternalImages
- Type: boolean
- Default: true
- Security Warning: Enabling this setting fetches arbitrary URLs
```

**Check extracted data:**
```bash
cat .claude/docs-extraction/data/config_options.json | jq '.config_options[] | select(.key=="fetchExternalImages")'
```

**Create documentation:**
```rst
.. confval:: fetchExternalImages

   :type: boolean
   :Default: true
   :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['ext_key']['fetchExternalImages']

   [Paste extracted description]

   .. warning::
      [Paste extracted security warning]

   [TODO: Add usage examples]
   [TODO: Add troubleshooting tips]
```

### Extraction Best Practices

**DO:**
- Run `scripts/analyze-docs.sh` before starting documentation work
- Use extracted data as starting templates, not final documentation
- Add usage examples and context beyond extracted descriptions
- Re-run analysis after updates to track progress
- Keep extraction data gitignored (already in `.claude/`)

**DON'T:**
- Skip extraction for existing extensions (saves time finding gaps)
- Commit `.claude/docs-extraction/` to version control
- Blindly copy extracted data without adding examples
- Ignore security warnings in config option extractions
- Forget to validate after using extracted data

### Extraction Data Structure

**php_apis.json:**
```json
{
  "classes": [
    {
      "name": "ClassName",
      "namespace": "Vendor\\Extension\\Path",
      "file": "Classes/Path/ClassName.php",
      "description": "Class description from docblock",
      "author": "Author Name",
      "methods": [...]
    }
  ]
}
```

**config_options.json:**
```json
{
  "config_options": [
    {
      "key": "settingName",
      "type": "boolean",
      "default": "1",
      "description": "Description from ext_conf_template.txt",
      "security_warning": "Warning text if present"
    }
  ]
}
```

See `references/extraction-patterns.md` for complete extraction documentation.

## Best Practices

1. **Clear Structure**: Organize docs by audience (users vs developers)
2. **Card Grids**: Use card-grid for main navigation pages
3. **Cross-References**: Use :ref: labels instead of hardcoded paths
4. **Code Examples**: Always include working code examples
5. **Version Markers**: Document version-specific features
6. **Screenshots**: Place in `Images/` directory, reference with `.. image::`
7. **Validation**: Always validate before committing
8. **Local Preview**: Render locally to verify appearance

## Common Issues

**Broken cross-references:**
- Verify label exists: `.. _label-name:`
- Check reference syntax: `:ref:`label-name``
- Ensure label is unique

**Rendering warnings:**
- Check heading level consistency (no skipped levels)
- Verify directive syntax (proper indentation)
- Validate code block languages are supported

**Webhook not triggering:**
- Check Settings.cfg has correct repository URL
- Verify webhook configured in repository settings
- Check TYPO3 Intercept logs for errors

## Resources

- [TYPO3 Documentation Guide](https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/)
- [RST Syntax Reference](~/.claude/skills/typo3-docs/references/rst-syntax.md)
- [TYPO3 Directives](~/.claude/skills/typo3-docs/references/typo3-directives.md)
- [Card Grids](~/.claude/skills/typo3-docs/references/card-grids.md)
- [Cross-References](~/.claude/skills/typo3-docs/references/cross-references.md)
- [Local Rendering](~/.claude/skills/typo3-docs/references/local-rendering.md)
