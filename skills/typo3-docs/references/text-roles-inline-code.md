# Text Roles and Inline Code Reference

Comprehensive reference for TYPO3 documentation text roles and inline code highlighting.

## Text Roles Overview

Text roles provide semantic markup for different types of content. They render with appropriate styling and often provide interactive features like copy buttons or link generation.

## General Text Roles

### File and Path Roles

| Role | Syntax | Purpose | Example |
|------|--------|---------|---------|
| `:file:` | `:file:\`config/system/settings.php\`` | File names | :file:`settings.php` |
| `:path:` | `:path:\`public/fileadmin\`` | Directory paths | :path:`public/fileadmin` |

**Usage Guidelines:**
- Use `:file:` for specific files with extensions
- Use `:path:` for directories or general paths
- Both render as monospace with appropriate styling

### GUI and Interface Roles

| Role | Syntax | Purpose | Example |
|------|--------|---------|---------|
| `:guilabel:` | `:guilabel:\`Site Management > Sites\`` | GUI labels, buttons, menu items | :guilabel:`Save` |
| `:menuselection:` | `:menuselection:\`File --> Save As\`` | Menu navigation paths | :menuselection:`File --> Export` |
| `:kbd:` | `:kbd:\`Ctrl+S\`` | Keyboard shortcuts | :kbd:`Ctrl+C` |

**Usage Guidelines:**
- Use `:guilabel:` for any clickable UI element (buttons, tabs, links)
- Use `:menuselection:` for menu navigation with `-->` separator
- Use `:kbd:` for individual keys or key combinations

### Reference Roles

| Role | Syntax | Purpose | Example |
|------|--------|---------|---------|
| `:ref:` | `:ref:\`section-label\`` | Internal cross-references | :ref:`introduction` |
| `:confval:` | `:confval:\`setting-name\`` | Configuration value references | :confval:`fetchExternalImages` |
| `:term:` | `:term:\`FAL\`` | Glossary term references | :term:`magic image` |
| `:doc:` | `:doc:\`/Introduction/Index\`` | Document references | :doc:`/API/Index` |

**Usage Guidelines:**
- Always prefer `:ref:` over `:doc:` for internal links (more stable)
- Use `:confval:` to reference documented configuration values
- Use `:term:` only for terms defined in a glossary

### TYPO3-Specific Roles

| Role | Syntax | Purpose | Example |
|------|--------|---------|---------|
| `:composer:` | `:composer:\`typo3/cms-core\`` | Composer packages | :composer:`netresearch/rte-ckeditor-image` |
| `:issue:` | `:issue:\`102056\`` | TYPO3 Forge issues | :issue:`12345` |
| `:t3ext:` | `:t3ext:\`news\`` | TER extensions | :t3ext:`rte_ckeditor_image` |
| `:t3src:` | `:t3src:\`backend/Classes/Controller\`` | TYPO3 source code | :t3src:`core/Classes/Utility` |

### Other Useful Roles

| Role | Syntax | Purpose | Example |
|------|--------|---------|---------|
| `:abbr:` | `:abbr:\`LIFO (last-in, first-out)\`` | Abbreviations with expansion | :abbr:`FAL (File Abstraction Layer)` |
| `:samp:` | `:samp:\`{variable} text\`` | Sample text with variables | :samp:`width × height` |
| `:command:` | `:command:\`composer\`` | Command names | :command:`git` |
| `:mailheader:` | `:mailheader:\`Content-Type\`` | Mail headers | :mailheader:`From` |
| `:code:` | `:code:\`inline code\`` | Generic inline code | :code:`$variable` |

## Inline Code Roles (Language-Specific)

These roles provide syntax highlighting, copy buttons, and in some cases automatic linking.

### Primary Language Roles

| Role | Syntax | Purpose |
|------|--------|---------|
| `:php:` | `:php:\`$GLOBALS['TYPO3_CONF_VARS']\`` | PHP code |
| `:php-short:` | `:php-short:\`GeneralUtility\`` | Shortened TYPO3 class names |
| `:typoscript:` | `:typoscript:\`lib.parseFunc_RTE\`` | TypoScript code |
| `:tsconfig:` | `:tsconfig:\`RTE.default.preset\`` | TSConfig values |

### Markup and Styling Roles

| Role | Syntax | Purpose |
|------|--------|---------|
| `:html:` | `:html:\`<img src="...">\`` | HTML markup |
| `:css:` | `:css:\`.my-class { color: red; }\`` | CSS code |
| `:fluid:` | `:fluid:\`{f:if(condition: ...)}\`` | Fluid template syntax |
| `:xml:` | `:xml:\`<extension>\`` | XML markup |
| `:xliff:` | `:xliff:\`<trans-unit>\`` | XLIFF translation files |

### Data Format Roles

| Role | Syntax | Purpose |
|------|--------|---------|
| `:yaml:` | `:yaml:\`key: value\`` | YAML configuration |
| `:json:` | `:json:\`{"key": "value"}\`` | JSON data |
| `:sql:` | `:sql:\`SELECT * FROM tt_content\`` | SQL queries |

### Scripting Roles

| Role | Syntax | Purpose |
|------|--------|---------|
| `:js:` or `:javascript:` | `:js:\`const x = 1;\`` | JavaScript code |
| `:bash:` or `:shell:` | `:bash:\`composer install\`` | Shell commands |
| `:rst:` | `:rst:\`.. code-block:: php\`` | reStructuredText |

## Best Practices

### Choosing the Right Role

```rst
# For PHP classes and code
:php:`ImageResolverService`
:php:`$GLOBALS['TYPO3_CONF_VARS']`

# For file paths
:file:`ext_localconf.php`
:path:`Configuration/TypoScript/`

# For TypoScript
:typoscript:`lib.parseFunc_RTE.tags.img`

# For GUI elements
:guilabel:`Site Management > Sites`
:guilabel:`Save`

# For HTML elements
:html:`<img>`
:html:`data-htmlarea-file-uid`

# For configuration values
:confval:`fetchExternalImages <confval-fetchexternalimages>`
```

### Common Mistakes

```rst
# ❌ Wrong: Using backticks for everything
``ImageResolverService`` renders images

# ✅ Correct: Using appropriate roles
:php:`ImageResolverService` renders images

# ❌ Wrong: Plain text for file paths
See ext_localconf.php for details

# ✅ Correct: Using file role
See :file:`ext_localconf.php` for details

# ❌ Wrong: Plain text for UI elements
Click the Save button

# ✅ Correct: Using guilabel
Click the :guilabel:`Save` button
```

### Role Selection Decision Tree

```
Is it a file or path?
├── File with extension → :file:`filename.ext`
└── Directory path → :path:`path/to/dir`

Is it code or a technical term?
├── PHP code/class → :php:`ClassName` or :php:`$variable`
├── TypoScript → :typoscript:`setting.path`
├── HTML element → :html:`<element>`
├── YAML config → :yaml:`key: value`
├── SQL query → :sql:`SELECT ...`
└── Shell command → :bash:`command`

Is it a UI element?
├── Button/label → :guilabel:`Button Text`
├── Menu path → :menuselection:`Menu --> Submenu`
└── Keyboard key → :kbd:`Ctrl+S`

Is it a reference?
├── Section link → :ref:`section-label`
├── Config value → :confval:`setting-name`
├── Glossary term → :term:`term-name`
└── Other doc → :doc:`/Path/Index`

Is it TYPO3-specific?
├── Composer package → :composer:`vendor/package`
├── Forge issue → :issue:`12345`
├── TER extension → :t3ext:`ext_key`
└── Core source → :t3src:`path/to/file`
```

## PHP Class Auto-Linking

When using `:php:` for TYPO3 Core classes, they are automatically linked to https://api.typo3.org:

```rst
# Automatically linked to API docs
:php:`\TYPO3\CMS\Core\Utility\GeneralUtility`

# Shortened version (also linked)
:php-short:`GeneralUtility`
```

## Copy Button Feature

All inline code roles display an overlay with a copy button when hovered:

- Allows quick copying of code snippets
- Shows language information
- For PHP classes, shows PHPDoc comment

## References

- **Text Roles:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/InlineMarkup/TextRoles/Index.html
- **Inline Code:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/InlineCode.html
