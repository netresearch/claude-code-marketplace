# TYPO3-Specific Directives

Comprehensive reference for TYPO3-specific RST directives and extensions.

## Configuration Values (confval)

Document configuration options with structured metadata.

**Basic Syntax:**
```rst
.. confval:: settingName

   :type: boolean
   :Default: true
   :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['ext_key']['setting']

   Description of the configuration value.
```

**Field Types:**
- `:type:` - boolean, string, integer, array, object
- `:Default:` - Default value (capitalize 'Default')
- `:Path:` - Full path to the setting in TYPO3 configuration
- `:Scope:` - Where setting applies (frontend, backend, global)

**Example:**
```rst
.. confval:: fetchExternalImages

   :type: boolean
   :Default: true
   :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['rte_ckeditor_image']['fetchExternalImages']

   Controls whether external image URLs are automatically fetched and uploaded
   to the current backend user's upload folder. When enabled, pasting image
   URLs will trigger automatic download and FAL integration.
```

**TSConfig Example:**
```rst
.. confval:: RTE.default.buttons.image.options.magic.maxWidth

   :type: integer
   :Default: 300

   Maximum width in pixels for images inserted through the RTE.
   Images exceeding this width will be automatically scaled down.
```

**YAML Configuration Example:**
```rst
.. confval:: editor.externalPlugins.typo3image.allowedExtensions

   :type: string
   :Default: Value from ``$GLOBALS['TYPO3_CONF_VARS']['GFX']['imagefile_ext']``

   Comma-separated list of allowed image file extensions for the CKEditor
   image plugin. Overrides global TYPO3 image extension settings.
```

### Two-Level Configuration Pattern

**Pattern:** Site-wide configuration with per-item override capability

Many TYPO3 features support two-level configuration:
1. **Site-wide default** via TypoScript
2. **Per-item override** via attributes or UI

**When to use:**
- Features where editors need item-specific control
- Mixed content pages (some items use site-wide, others override)
- Configuration that varies by context or workflow

**Documentation Structure:**

```rst
## Configuration

The noScale feature can be configured at two levels:

1. **Site-wide (TypoScript)** - Default behavior for all images
2. **Per-image (Editor)** - Override for specific images

### Site-Wide Configuration

.. confval:: noScale

   :type: boolean
   :Default: false (auto-optimization enabled)
   :Path: lib.parseFunc_RTE.tags.img.noScale

   Controls whether images are automatically optimized or used as original files.
   When enabled, all images skip TYPO3's image processing.

   **Configuration Priority:**

   - **Per-image setting** (data-noscale attribute) takes precedence
   - **Site-wide setting** (TypoScript) is the fallback
   - **Default behavior** when neither is set

   **Enable for all images:**

   .. code-block:: typoscript
      :caption: setup.typoscript

      lib.parseFunc_RTE {
          tags.img {
              noScale = 1  # All images use original files
          }
      }

### Per-Image Override

.. versionadded:: 13.0.0
   Editors can now enable noScale for individual images using the CKEditor
   image dialog, overriding the site-wide TypoScript setting.

**How to Use:**

1. Insert or edit an image in CKEditor
2. Open the image dialog (double-click or select + click insert image button)
3. Check "Use original file (noScale)" checkbox
4. Save the image

**Configuration Priority:**

- **Per-image setting** (data-noscale attribute) overrides site-wide configuration
- If unchecked: Falls back to site-wide TypoScript setting
- If no site-wide setting: Default behavior (auto-optimization)

**Workflow Benefits:**

- **Mixed Content**: Some images original, others optimized on same page
- **Editorial Control**: Editors decide per-image without developer intervention
- **Flexibility**: Override site-wide settings for specific images
- **Newsletter Integration**: Mark high-quality images for email

**Technical Implementation:**

.. code-block:: html

   <!-- Per-image override via data attribute -->
   <img src="image.jpg" data-noscale="true" />
```

**Example from t3x-rte_ckeditor_image:**

The noScale feature uses this pattern:
- **Site-wide**: `lib.parseFunc_RTE.tags.img.noScale = 1` in TypoScript
- **Per-image**: Checkbox in CKEditor dialog sets `data-noscale` attribute
- **Priority**: Per-image attribute overrides TypoScript setting

**Documentation Benefits:**

✅ Clear separation of site-wide vs per-item configuration
✅ Explicit priority/precedence rules documented
✅ Workflow guidance for editors
✅ Technical implementation details for developers
✅ Use case explanations (mixed content, newsletters)

## Version Information

Document version-specific changes with proper directives.

**Version Added:**
```rst
.. versionadded:: 13.0.0
   The CKEditor plugin now requires ``StyleUtils`` and ``GeneralHtmlSupport``
   dependencies for style functionality. Previous versions did not have this requirement.
```

**Version Changed:**
```rst
.. versionchanged:: 13.1.0
   Image processing now uses TYPO3's native image processing service instead
   of custom processing logic.
```

**Deprecated:**
```rst
.. deprecated:: 13.2.0
   The ``oldSetting`` configuration option is deprecated. Use ``newSetting`` instead.
   This option will be removed in version 14.0.0.
```

**Placement:** Place version directives immediately before or after the relevant content they describe.

## PHP Domain

Document PHP classes, methods, and properties.

**Class:**
```rst
.. php:class:: SelectImageController

   Main controller for image selection wizard.

   Extends: ``TYPO3\\CMS\\Backend\\Controller\\ElementBrowserController``
```

**Method:**
```rst
.. php:method:: infoAction(ServerRequestInterface $request): ResponseInterface

   Retrieves image information and processed file details.

   :param \\Psr\\Http\\Message\\ServerRequestInterface $request: PSR-7 server request
   :returns: JSON response with image data or error response
   :returntype: \\Psr\\Http\\Message\\ResponseInterface
   :throws \\RuntimeException: When file is not found or invalid
```

**Property:**
```rst
.. php:attr:: resourceFactory

   :type: \\TYPO3\\CMS\\Core\\Resource\\ResourceFactory

   Resource factory for file operations.
```

**Namespace:**
```rst
.. php:namespace:: Netresearch\\RteCKEditorImage\\Controller

.. php:class:: SelectImageController
```

## Card Grids

Create visual card layouts for navigation.

**Basic Card Grid:**
```rst
.. card-grid::
    :columns: 1
    :columns-md: 2
    :gap: 4
    :card-height: 100

    ..  card:: 📘 Introduction

        The RTE CKEditor Image extension provides comprehensive image handling
        capabilities for CKEditor in TYPO3.

        ..  card-footer:: :ref:`Read more <introduction>`
            :button-style: btn btn-primary stretched-link

    ..  card:: 🔧 Configuration

        Learn how to configure the extension with TSConfig, YAML, and TypoScript
        settings for your specific needs.

        ..  card-footer:: :ref:`Read more <configuration>`
            :button-style: btn btn-secondary stretched-link
```

**Card Grid Options:**
- `:columns:` - Number of columns (default layout)
- `:columns-md:` - Columns for medium+ screens
- `:gap:` - Gap between cards (1-5)
- `:card-height:` - Card height (100 for equal height)
- `:class:` - Additional CSS classes

**Card Footer Styles:**
- `btn btn-primary stretched-link` - Primary button with full card click
- `btn btn-secondary stretched-link` - Secondary button with full card click
- `btn btn-light stretched-link` - Light button

**UTF-8 Emoji Icons:**
Use in card titles for visual appeal:
- 📘 Documentation
- 🔧 Configuration
- 🎨 Design
- 🔍 Search
- ⚡ Performance
- 🛡️ Security
- 📊 API
- 🆘 Troubleshooting

## Intersphinx References

Cross-reference TYPO3 core documentation.

**TSRef (TypoScript Reference):**
```rst
:ref:`t3tsref:start`
:ref:`t3tsref:stdwrap`
:ref:`t3tsref:cobj-image`
```

**Core API:**
```rst
:ref:`t3coreapi:start`
:ref:`t3coreapi:fal`
:ref:`t3coreapi:dependency-injection`
```

**TSConfig:**
```rst
:ref:`t3tsconfig:start`
:ref:`t3tsconfig:pagetsconfig`
```

**TCA:**
```rst
:ref:`t3tca:start`
:ref:`t3tca:columns-types`
```

**Fluid:**
```rst
:ref:`t3viewhelper:start`
:ref:`t3viewhelper:typo3-fluid-image`
```

## Index and Glossary

**Index Entry:**
```rst
.. index:: Image Processing, FAL, CKEditor

.. _image-processing:

Image Processing
================
```

**Glossary:**
```rst
.. glossary::

   FAL
      File Abstraction Layer - TYPO3's file management system

   Magic Image
      Automatically processed image with dimension constraints
```

**Reference Glossary:**
```rst
See :term:`FAL` for details.
```

## Tabs

Create tabbed content for multiple options.

```rst
.. tabs::

   .. tab:: Composer

      .. code-block:: bash

         composer require netresearch/rte-ckeditor-image

   .. tab:: Extension Manager

      Install via TYPO3 Extension Manager:

      1. Go to Admin Tools > Extensions
      2. Search for "rte_ckeditor_image"
      3. Click Install
```

## Special TYPO3 Directives

**Include Partial:**
```rst
.. include:: ../Includes.rst.txt
```

**File Tree:**
```rst
.. directory-tree::

   * Classes/

     * Controller/
     * Database/
     * Utils/

   * Resources/

     * Public/

       * JavaScript/
```

**YouTube Video:**
```rst
.. youtube:: VIDEO_ID
```

**Download Link:**
```rst
:download:`Download PDF <../_static/manual.pdf>`
```

## Best Practices

1. **Use confval for all configuration**: Document every setting with proper metadata
2. **Version everything**: Add versionadded/versionchanged for all version-specific features
3. **Cross-reference liberally**: Link to related documentation with :ref:
4. **Card grids for navigation**: Use card-grid layouts for Index.rst files
5. **Emoji icons in titles**: Use UTF-8 emojis in card titles for visual appeal
6. **Stretched links**: Always use `stretched-link` class in card-footer for full card clicks
7. **PHP domain for APIs**: Document all public methods with php:method
8. **Intersphinx for core**: Reference TYPO3 core docs with intersphinx

## Quality Checklist

✅ All configuration options documented with confval
✅ Version information added for all version-specific features
✅ Cross-references work (no broken :ref: links)
✅ Card grids use stretched-link in card-footer
✅ UTF-8 emoji icons in card titles
✅ PHP API documented with php:method
✅ Code blocks specify language
✅ Admonitions used appropriately
✅ Local render shows no warnings
✅ All headings have proper underlines

## References

- **TYPO3 Documentation Guide:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/
- **Confval Reference:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/Confval.html
- **Version Directives:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Versions.html
- **PHP Domain:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/Phpdomain.html
- **Card Grid:** https://sphinxcontrib-typo3-theme.readthedocs.io/en-us/latest/
