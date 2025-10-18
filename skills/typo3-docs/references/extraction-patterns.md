# Documentation Extraction Patterns

Comprehensive guide for automated extraction of documentation content from TYPO3 extension source code, configuration files, and repository metadata.

## Overview

The TYPO3 documentation skill supports assisted documentation generation through:

1. **Multi-Source Extraction**: Extract from code, configs, repository metadata
2. **Gap Analysis**: Identify missing or outdated documentation
3. **Template Generation**: Create RST scaffolds with extracted data
4. **Non-Destructive Updates**: Suggest changes, never auto-modify existing docs

## Extraction Architecture

```
Source Files → Extraction Scripts → Structured JSON → RST Templates → Human Review → Documentation/
```

### Data Flow

```
1. Extract Phase
   ├─ PHP code → data/php_apis.json
   ├─ Extension configs → data/extension_meta.json, data/config_options.json
   ├─ TYPO3 configs → data/tca_tables.json, data/typoscript.json
   ├─ Build configs → data/ci_matrix.json, data/testing.json
   └─ Repository → data/repo_metadata.json (optional)

2. Analysis Phase
   ├─ Parse existing Documentation/**/*.rst → data/existing_docs.json
   └─ Compare extracted vs existing → Documentation/ANALYSIS.md

3. Generation Phase (Optional)
   └─ Create RST templates → Documentation/GENERATED/
```

## PHP Code Extraction

### Source: Classes/**/*.php

**What to Extract:**

```php
<?php
/**
 * Controller for the image select wizard.
 *
 * @author  Christian Opitz
 * @license https://www.gnu.org/licenses/agpl-3.0.de.html
 */
class SelectImageController extends ElementBrowserController
{
    /**
     * Maximum allowed image dimension in pixels.
     *
     * Prevents resource exhaustion: 10000x10000px ≈ 400MB memory worst case.
     */
    private const IMAGE_MAX_DIMENSION = 10000;

    /**
     * Retrieves image information and processed file details.
     *
     * @param ServerRequestInterface $request PSR-7 server request
     * @return ResponseInterface JSON response with image data
     */
    public function infoAction(ServerRequestInterface $request): ResponseInterface
    {
        // ...
    }
}
```

**Extracted Data Structure:**

```json
{
  "classes": [
    {
      "name": "SelectImageController",
      "namespace": "Netresearch\\RteCKEditorImage\\Controller",
      "file": "Classes/Controller/SelectImageController.php",
      "description": "Controller for the image select wizard.",
      "author": "Christian Opitz",
      "license": "https://www.gnu.org/licenses/agpl-3.0.de.html",
      "extends": "TYPO3\\CMS\\Backend\\Controller\\ElementBrowserController",
      "constants": [
        {
          "name": "IMAGE_MAX_DIMENSION",
          "value": 10000,
          "visibility": "private",
          "description": "Maximum allowed image dimension in pixels.",
          "notes": "Prevents resource exhaustion: 10000x10000px ≈ 400MB memory worst case."
        }
      ],
      "methods": [
        {
          "name": "infoAction",
          "visibility": "public",
          "description": "Retrieves image information and processed file details.",
          "parameters": [
            {
              "name": "request",
              "type": "Psr\\Http\\Message\\ServerRequestInterface",
              "description": "PSR-7 server request"
            }
          ],
          "return": {
            "type": "Psr\\Http\\Message\\ResponseInterface",
            "description": "JSON response with image data"
          }
        }
      ]
    }
  ]
}
```

**RST Mapping:**

```rst
API/SelectImageController.rst:

.. php:namespace:: Netresearch\RteCKEditorImage\Controller

.. php:class:: SelectImageController

   Controller for the image select wizard.

   **Author:** Christian Opitz

   **License:** https://www.gnu.org/licenses/agpl-3.0.de.html

   Extends: :php:`TYPO3\CMS\Backend\Controller\ElementBrowserController`

   .. important::
      Maximum allowed image dimension: 10000 pixels

      Prevents resource exhaustion: 10000x10000px ≈ 400MB memory worst case.

   .. php:method:: infoAction(ServerRequestInterface $request): ResponseInterface

      Retrieves image information and processed file details.

      :param \\Psr\\Http\\Message\\ServerRequestInterface $request: PSR-7 server request
      :returns: JSON response with image data
      :returntype: \\Psr\\Http\\Message\\ResponseInterface
```

## Extension Configuration Extraction

### Source: ext_emconf.php

**What to Extract:**

```php
$EM_CONF[$_EXTKEY] = [
    'title' => 'CKEditor Rich Text Editor Image Support',
    'description' => 'Adds FAL image support to CKEditor for TYPO3',
    'category' => 'be',
    'author' => 'Christian Opitz, Rico Sonntag',
    'author_email' => 'christian.opitz@netresearch.de',
    'state' => 'stable',
    'version' => '13.1.0',
    'constraints' => [
        'depends' => [
            'typo3' => '12.4.0-13.5.99',
            'php' => '8.1.0-8.3.99',
        ],
    ],
];
```

**RST Mapping:**

```rst
Introduction/Index.rst:

=================================
CKEditor Rich Text Editor Image Support
=================================

:Extension Key: rte_ckeditor_image
:Version: 13.1.0
:Author: Christian Opitz, Rico Sonntag
:Email: christian.opitz@netresearch.de
:Status: stable

Adds FAL image support to CKEditor for TYPO3.

Requirements
------------

- TYPO3 12.4.0 - 13.5.99
- PHP 8.1.0 - 8.3.99
```

### Source: ext_conf_template.txt

**What to Extract:**

```
# cat=basic/enable; type=boolean; label=Fetch External Images: Controls whether external image URLs are automatically fetched and uploaded to the current backend user's upload folder. When enabled, pasting image URLs will trigger automatic download and FAL integration. WARNING: Enabling this setting fetches arbitrary URLs from the internet.
fetchExternalImages = 1

# cat=advanced; type=int+; label=Maximum Image Size (px): Maximum allowed dimension for images in pixels
maxImageSize = 5000
```

**Extracted Data:**

```json
{
  "configOptions": [
    {
      "key": "fetchExternalImages",
      "category": "basic",
      "subcategory": "enable",
      "type": "boolean",
      "label": "Fetch External Images",
      "description": "Controls whether external image URLs are automatically fetched and uploaded to the current backend user's upload folder. When enabled, pasting image URLs will trigger automatic download and FAL integration.",
      "default": true,
      "security_warning": "Enabling this setting fetches arbitrary URLs from the internet."
    },
    {
      "key": "maxImageSize",
      "category": "advanced",
      "type": "int+",
      "label": "Maximum Image Size (px)",
      "description": "Maximum allowed dimension for images in pixels",
      "default": 5000
    }
  ]
}
```

**RST Mapping:**

```rst
Integration/Configuration.rst:

.. confval:: fetchExternalImages

   :type: boolean
   :Default: true
   :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['rte_ckeditor_image']['fetchExternalImages']

   Controls whether external image URLs are automatically fetched and uploaded
   to the current backend user's upload folder. When enabled, pasting image
   URLs will trigger automatic download and FAL integration.

   .. warning::
      Enabling this setting fetches arbitrary URLs from the internet.

.. confval:: maxImageSize

   :type: integer
   :Default: 5000
   :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['rte_ckeditor_image']['maxImageSize']

   Maximum allowed dimension for images in pixels.
```

## Composer Dependencies Extraction

### Source: composer.json

**What to Extract:**

```json
{
  "require": {
    "typo3/cms-core": "^12.4 || ^13.0",
    "typo3/cms-backend": "^12.4 || ^13.0"
  },
  "require-dev": {
    "typo3/testing-framework": "^8.0"
  }
}
```

**RST Mapping:**

```rst
Installation/Index.rst:

Installation
============

Composer Installation
---------------------

.. code-block:: bash

   composer require netresearch/rte-ckeditor-image

Dependencies
------------

**Required:**

- typo3/cms-core: ^12.4 || ^13.0
- typo3/cms-backend: ^12.4 || ^13.0

**Development:**

- typo3/testing-framework: ^8.0
```

## TYPO3 Configuration Extraction

### Source: Configuration/TCA/*.php

**What to Extract:**

```php
return [
    'ctrl' => [
        'title' => 'LLL:EXT:my_ext/Resources/Private/Language/locallang_db.xlf:tx_myext_domain_model_product',
        'label' => 'name',
    ],
    'columns' => [
        'name' => [
            'label' => 'LLL:EXT:my_ext/Resources/Private/Language/locallang_db.xlf:tx_myext_domain_model_product.name',
            'config' => [
                'type' => 'input',
                'size' => 30,
                'eval' => 'trim,required',
            ],
        ],
    ],
];
```

**RST Mapping:**

```rst
Developer/DataModel.rst:

Database Tables
===============

tx_myext_domain_model_product
------------------------------

Product table with the following fields:

**name**
   - Type: input
   - Size: 30
   - Validation: trim, required
```

### Source: Configuration/TypoScript/*.typoscript

**What to Extract:**

```typoscript
plugin.tx_myext {
    settings {
        itemsPerPage = 20
        enableCache = 1
    }
}
```

**RST Mapping:**

```rst
Configuration/TypoScript.rst:

.. code-block:: typoscript

   plugin.tx_myext {
       settings {
           # Number of items to display per page
           itemsPerPage = 20

           # Enable frontend caching
           enableCache = 1
       }
   }
```

## Repository Metadata Extraction

### Source: GitHub API (Optional)

**Commands:**

```bash
gh api repos/netresearch/t3x-rte_ckeditor_image
gh api repos/netresearch/t3x-rte_ckeditor_image/releases
gh api repos/netresearch/t3x-rte_ckeditor_image/contributors
```

**Extracted Data:**

```json
{
  "repository": {
    "description": "Image support for CKEditor in TYPO3",
    "topics": ["typo3", "ckeditor", "fal"],
    "created_at": "2017-03-15",
    "stars": 45,
    "issues_open": 3
  },
  "releases": [
    {
      "tag": "13.1.0",
      "date": "2024-12-01",
      "notes": "Added TYPO3 v13 compatibility"
    }
  ],
  "contributors": [
    {"name": "Christian Opitz", "commits": 120},
    {"name": "Rico Sonntag", "commits": 45}
  ]
}
```

**RST Mapping:**

```rst
Introduction/Index.rst:

Repository
----------

- GitHub: https://github.com/netresearch/t3x-rte_ckeditor_image
- Issues: 3 open issues
- Stars: 45

Contributors
------------

- Christian Opitz (120 commits)
- Rico Sonntag (45 commits)
```

## Build Configuration Extraction

### Source: .github/workflows/*.yml

**What to Extract:**

```yaml
strategy:
  matrix:
    php: ['8.1', '8.2', '8.3']
    typo3: ['12.4', '13.0']
    database: ['mysqli', 'pdo_mysql']
```

**RST Mapping:**

```rst
Developer/Testing.rst:

Tested Configurations
---------------------

The extension is continuously tested against:

- PHP: 8.1, 8.2, 8.3
- TYPO3: 12.4, 13.0
- Database: MySQL (mysqli), MySQL (PDO)
```

## Project Files Extraction

### Source: README.md

**What to Extract:**

- Project description → Introduction overview
- Installation instructions → Installation section
- Usage examples → User guide sections
- Troubleshooting → Troubleshooting section

**Strategy:**

Parse markdown structure, map headings to RST sections, convert markdown code blocks to RST code-block directives.

### Source: CHANGELOG.md

**What to Extract:**

```markdown
## [13.1.0] - 2024-12-01
### Added
- TYPO3 v13 compatibility
- New image processing options

### Fixed
- Image upload validation
```

**RST Mapping:**

```rst
Throughout documentation:

.. versionadded:: 13.1.0
   TYPO3 v13 compatibility support added.

.. versionadded:: 13.1.0
   New image processing options available.
```

## Gap Analysis Workflow

### 1. Extract All Data

Run extraction scripts to populate `.claude/docs-extraction/data/*.json`

### 2. Parse Existing Documentation

Scan `Documentation/**/*.rst` files:

- Identify existing `.. php:class::` directives → List documented classes
- Identify existing `.. confval::` directives → List documented config options
- Identify existing API sections → List documented methods
- Collect version markers → Track documented version changes

### 3. Compare

**Missing Documentation:**

```
Classes in php_apis.json NOT in existing_docs.json
→ Undocumented classes

Config options in config_options.json NOT in existing_docs.json
→ Undocumented configuration

Methods in php_apis.json NOT in existing_docs.json
→ Undocumented API methods
```

**Outdated Documentation:**

```
confval default value != config_options.json default
→ Outdated configuration documentation

Method signature mismatch
→ Outdated API documentation

ext_emconf.php version > documented version markers
→ Missing version change documentation
```

### 4. Generate ANALYSIS.md Report

```markdown
# Documentation Analysis Report

Generated: 2024-12-15 10:30:00

## Summary

- Total Classes: 15
- Documented Classes: 12
- **Missing: 3**

- Total Config Options: 8
- Documented Options: 6
- **Missing: 2**

- Total Public Methods: 45
- Documented Methods: 38
- **Missing: 7**

## Missing Documentation

### Undocumented Classes

1. **Classes/Service/ImageProcessor.php**
   - `ImageProcessor` class - Image processing service
   - Suggested location: `API/ImageProcessor.rst`

2. **Classes/Utility/SecurityUtility.php**
   - `SecurityUtility` class - Security validation utilities
   - Suggested location: `API/SecurityUtility.rst`

### Undocumented Configuration

1. **fetchExternalImages** (ext_conf_template.txt)
   - Type: boolean
   - Default: true
   - Suggested location: `Integration/Configuration.rst`
   - Template: See `Documentation/GENERATED/Configuration/fetchExternalImages.rst`

2. **maxImageSize** (ext_conf_template.txt)
   - Type: int+
   - Default: 5000
   - Suggested location: `Integration/Configuration.rst`

### Undocumented Methods

1. **SelectImageController::processImage()**
   - Parameters: File $file, array $options
   - Return: ProcessedFile
   - Suggested location: Add to `API/SelectImageController.rst`

## Outdated Documentation

### Configuration Mismatches

1. **uploadFolder** - Default value mismatch
   - Code: `user_upload/rte_images/`
   - Docs: `user_upload/`
   - File: `Integration/Configuration.rst:45`
   - Action: Update default value

### API Changes

1. **SelectImageController::infoAction()** - Parameter added
   - Code signature: `infoAction(ServerRequestInterface $request, ?array $context = null)`
   - Docs signature: `infoAction(ServerRequestInterface $request)`
   - File: `API/SelectImageController.rst:78`
   - Action: Add `$context` parameter documentation

## Recommendations

1. Generate missing RST templates: `scripts/generate-templates.sh`
2. Review generated templates in `Documentation/GENERATED/`
3. Complete [TODO] sections with usage examples
4. Move completed files to appropriate Documentation/ folders
5. Update outdated sections based on mismatches above
6. Re-run analysis: `scripts/analyze-docs.sh`
7. Validate: `scripts/validate_docs.sh`
8. Render: `scripts/render_docs.sh`

## Next Steps

**Priority 1 (Required for completeness):**
- Document ImageProcessor class
- Document SecurityUtility class
- Add fetchExternalImages configuration
- Add maxImageSize configuration

**Priority 2 (Outdated content):**
- Fix uploadFolder default value
- Update infoAction signature

**Priority 3 (Enhancement):**
- Add usage examples for all config options
- Add code examples for all API methods
```

## Template Generation

### Hybrid Template Approach

Generated RST files include:

1. **Extracted Data**: Automatically populated from source
2. **[TODO] Markers**: Placeholders for human completion
3. **Example Sections**: Pre-structured but empty
4. **Guidance Comments**: Help text for completion

### Example Generated Template

```rst
Documentation/GENERATED/Configuration/fetchExternalImages.rst:

.. confval:: fetchExternalImages

   :type: boolean
   :Default: true
   :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['rte_ckeditor_image']['fetchExternalImages']

   Controls whether external image URLs are automatically fetched and uploaded
   to the current backend user's upload folder. When enabled, pasting image
   URLs will trigger automatic download and FAL integration.

   .. warning::
      Enabling this setting fetches arbitrary URLs from the internet.

   **[TODO: Add usage example]**

   Example
   -------

   .. code-block:: typoscript
      :caption: EXT:my_site/Configuration/TsConfig/Page/RTE.tsconfig

      # [TODO: Add TypoScript configuration example]

   **[TODO: Add use cases]**

   Use Cases
   ---------

   - [TODO: When to enable this setting]
   - [TODO: When to disable this setting]
   - [TODO: Security considerations]

   **[TODO: Add troubleshooting]**

   Troubleshooting
   ---------------

   - [TODO: Common issues and solutions]

<!--
EXTRACTION METADATA:
Source: ext_conf_template.txt:15
Generated: 2024-12-15 10:30:00
Review Status: PENDING
-->
```

## Extraction Scripts Reference

### scripts/extract-all.sh

Main orchestration script:

```bash
#!/usr/bin/env bash
# Extract all documentation data from project sources

scripts/extract-php.sh
scripts/extract-extension-config.sh
scripts/extract-typo3-config.sh
scripts/extract-composer.sh
scripts/extract-project-files.sh
scripts/extract-build-configs.sh  # Optional
scripts/extract-repo-metadata.sh  # Optional, requires network
```

### scripts/extract-php.sh

Extract PHP class information:

```bash
#!/usr/bin/env bash
# Parse PHP files in Classes/ directory
# Output: .claude/docs-extraction/data/php_apis.json
```

### scripts/analyze-docs.sh

Compare extracted data with existing documentation:

```bash
#!/usr/bin/env bash
# Compare data/*.json with Documentation/**/*.rst
# Output: Documentation/ANALYSIS.md
```

### scripts/generate-templates.sh

Generate RST templates from extracted data:

```bash
#!/usr/bin/env bash
# Read data/*.json
# Generate RST templates
# Output: Documentation/GENERATED/**/*.rst
```

## Quality Standards

### Extraction Quality

- ✅ 95%+ accuracy in data extraction
- ✅ All public APIs captured
- ✅ All configuration options captured
- ✅ Docblock formatting preserved
- ✅ Security warnings identified

### Template Quality

- ✅ Valid RST syntax
- ✅ Proper TYPO3 directive usage
- ✅ Clear [TODO] markers
- ✅ Helpful completion guidance
- ✅ Extraction metadata included

### Analysis Quality

- ✅ All gaps identified
- ✅ Clear action items
- ✅ Specific file locations
- ✅ Priority recommendations
- ✅ Actionable next steps

## Integration with AI Assistants

### AGENTS.md Documentation

When AI assistants work with Documentation/:

1. Read ANALYSIS.md for current gaps
2. Check GENERATED/ for pending templates
3. Complete [TODO] sections with context
4. Move completed RST to Documentation/
5. Re-run analyze-docs.sh to verify

### Workflow Integration

```
User: "Document the ImageProcessor class"
→ AI reads: .claude/docs-extraction/data/php_apis.json
→ AI checks: Documentation/ANALYSIS.md (confirms missing)
→ AI generates: Documentation/API/ImageProcessor.rst
→ AI completes [TODO] sections with usage examples
→ AI runs: scripts/validate_docs.sh
→ AI runs: scripts/render_docs.sh
→ User reviews rendered output
```

## Best Practices

**DO:**
- Run extraction scripts before manual documentation
- Review ANALYSIS.md regularly to track coverage
- Use generated templates as starting points
- Complete [TODO] sections with real examples
- Re-run analysis after updates

**DON'T:**
- Auto-commit generated templates without review
- Skip [TODO] completion (templates are incomplete without it)
- Ignore ANALYSIS.md warnings
- Modify extraction data JSON manually
- Delete extraction metadata comments

## Troubleshooting

**Empty extraction data:**
- Check file paths and permissions
- Verify PHP syntax is valid
- Check ext_conf_template.txt format

**Inaccurate gap analysis:**
- Ensure existing RST uses proper directive syntax
- Check cross-references are using :ref: not hardcoded paths
- Verify confval names match exactly

**Template generation failures:**
- Validate extraction JSON syntax
- Check RST template syntax
- Verify output directory exists and is writable

## Future Enhancements

**Planned Features:**

1. **Incremental Extraction**: Only extract changed files
2. **Smart Merging**: Suggest specific line changes in existing RST
3. **Example Generation**: AI-generated usage examples for APIs
4. **Auto-Screenshots**: Generate UI screenshots for editor documentation
5. **Translation Support**: Multi-language documentation extraction
6. **CI Integration**: Fail builds if documentation coverage < threshold

## Resources

- **PHP Parser**: nikic/php-parser for accurate PHP analysis
- **RST Parser**: docutils for existing documentation parsing
- **TYPO3 Docs**: https://docs.typo3.org/m/typo3/docs-how-to-document/
- **GitHub API**: https://docs.github.com/en/rest
- **GitLab API**: https://docs.gitlab.com/ee/api/
