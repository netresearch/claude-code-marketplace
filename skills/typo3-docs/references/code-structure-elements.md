# Code Blocks and Structure Elements

Complete reference for code blocks, inline code, and structure elements in TYPO3 documentation.

Based on:
- https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/Codeblocks.html
- https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/Confval.html
- https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/InlineCode.html
- https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/Phpdomain.html
- https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/SiteSettings.html

## When to Use What

| Content Type | Element | Example |
|--------------|---------|---------|
| Multi-line code | `code-block` directive | PHP classes, TypoScript setup |
| External code files | `literalinclude` directive | Full example files |
| Configuration options | `confval` directive | Extension settings, TCA fields |
| Inline PHP | `:php:` role | Class names, method calls |
| Inline TypoScript | `:typoscript:` role | TypoScript properties |
| File paths | `:file:` role | `ext_localconf.php` |
| UI elements | `:guilabel:` role | Button labels, menu items |
| Keyboard shortcuts | `:kbd:` role | `Ctrl+S` |
| PHP API documentation | `php:class`, `php:method` | Public API reference |
| Site settings | `typo3:site-set-settings` | Site set configuration |

## Code Blocks

### Basic Syntax

```rst
..  code-block:: <language>
    :caption: <file-path-or-description>

    <code-content>
```

**Important:** Blank line required between options and code. No blank lines between directive and options.

### Available Options

| Option | Purpose | Example |
|--------|---------|---------|
| `:caption:` | File path or description (recommended) | `:caption: EXT:my_ext/ext_localconf.php` |
| `:linenos:` | Show line numbers | `:linenos:` |
| `:lineno-start:` | Start line numbering at N | `:lineno-start: 10` |
| `:emphasize-lines:` | Highlight specific lines | `:emphasize-lines: 3,5-7` |
| `:name:` | Reference label for linking | `:name: my-code-example` |

### Common Languages

| Language | Identifier |
|----------|------------|
| PHP | `php` |
| TypoScript | `typoscript` |
| YAML | `yaml` |
| XML | `xml` |
| HTML | `html` |
| JavaScript | `javascript` or `js` |
| CSS | `css` |
| Shell/Bash | `bash` or `shell` |
| SQL | `sql` |
| JSON | `json` |
| Plain text | `plaintext` or `text` |
| Diff | `diff` |

### Examples

**PHP with caption and line numbers:**
```rst
..  code-block:: php
    :caption: EXT:my_extension/Classes/Service/MyService.php
    :linenos:

    <?php
    declare(strict_types=1);

    namespace Vendor\MyExtension\Service;

    class MyService
    {
        public function doSomething(): void
        {
            // Implementation
        }
    }
```

**TypoScript with emphasized lines:**
```rst
..  code-block:: typoscript
    :caption: EXT:my_extension/Configuration/TypoScript/setup.typoscript
    :emphasize-lines: 3-4

    lib.myContent = TEXT
    lib.myContent {
        value = Hello World
        wrap = <div class="content">|</div>
    }
```

### Placeholders

Use angle brackets for variable values:
```rst
..  code-block:: php

    $result = $this->myService->process('<your-value>');
```

For XML/HTML, use comments:
```rst
..  code-block:: xml

    <property><!-- your-value --></property>
```

## literalinclude Directive

Include code from external files. Preferred for longer examples or testable code.

### Basic Syntax

```rst
..  literalinclude:: _codesnippets/MyClass.php
    :language: php
    :caption: Classes/MyClass.php
```

### Options

| Option | Purpose |
|--------|---------|
| `:language:` | Syntax highlighting language |
| `:caption:` | Display caption |
| `:lines:` | Include only specific lines |
| `:linenos:` | Show line numbers |
| `:emphasize-lines:` | Highlight lines |
| `:start-after:` | Start after matching text |
| `:end-before:` | End before matching text |

### Example with Line Selection

```rst
..  literalinclude:: _codesnippets/CompleteClass.php
    :language: php
    :caption: Relevant excerpt
    :lines: 15-30
    :emphasize-lines: 5,10
```

### File Organization

```
Documentation/
├── Section/
│   ├── Index.rst
│   └── _codesnippets/
│       ├── MyClass.php
│       └── config.yaml
```

## Inline Code Roles

### Language-Specific Roles

| Role | Usage | Example |
|------|-------|---------|
| `:php:` | PHP code, TYPO3 classes | `:php:`\TYPO3\CMS\Core\Utility\GeneralUtility`` |
| `:php-short:` | TYPO3 classes (short name) | `:php-short:`\TYPO3\CMS\Core\Utility\GeneralUtility`` |
| `:typoscript:` | TypoScript code | `:typoscript:`lib.parseFunc`` |
| `:tsconfig:` | TSconfig | `:tsconfig:`TCEMAIN.table.pages`` |
| `:yaml:` | YAML values | `:yaml:`imports`` |
| `:html:` | HTML markup | `:html:`<div class="content">`` |
| `:css:` | CSS code | `:css:`.my-class`` |
| `:js:` | JavaScript | `:js:`document.querySelector`` |
| `:bash:` | Shell commands | `:bash:`composer require`` |
| `:fluid:` | Fluid template code | `:fluid:`{f:format.html()}`` |

### Utility Roles

| Role | Usage | Example |
|------|-------|---------|
| `:file:` | File paths | `:file:`ext_localconf.php`` |
| `:path:` | Directory paths | `:path:`Configuration/`` |
| `:guilabel:` | UI elements | `:guilabel:`Save and close`` |
| `:kbd:` | Keyboard shortcuts | `:kbd:`Ctrl+S`` |
| `:ref:` | Cross-references | `:ref:`my-section-label`` |
| `:t3src:` | TYPO3 source link | `:t3src:`core/Classes/...`` |

### Menu Paths with guilabel

Use `>` as separator:
```rst
Navigate to :guilabel:`Admin Tools > Settings > Extension Configuration`.
```

### PHP Class Linking

TYPO3 Core classes automatically link to api.typo3.org:
```rst
Use :php:`\TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance()` to create objects.
```

## confval Directive

Document configuration values in a structured, language-independent way.

### When to Use confval

- Extension configuration options
- TCA field definitions
- TypoScript properties
- YAML configuration options
- FlexForm settings

### Basic Syntax

```rst
..  confval:: option_name
    :name: unique-option-name
    :type: string
    :default: 'default value'
    :required: true

    Description of what this option does and how to use it.
```

### Available Options

| Option | Purpose |
|--------|---------|
| `:name:` | Unique identifier for linking (required for non-unique titles) |
| `:type:` | Value type (string, int, bool, array, etc.) |
| `:default:` | Default value |
| `:required:` | Whether the option is mandatory |
| `:noindex:` | Exclude from index |

Custom attributes are also supported for domain-specific properties.

### Example: Extension Configuration

```rst
..  confval:: encryptionMethod
    :name: ext-myvault-encryptionMethod
    :type: string
    :default: 'aes-256-gcm'
    :required: false

    The encryption algorithm used for storing secrets.

    Supported values:

    - ``aes-256-gcm`` (recommended)
    - ``xchacha20-poly1305``
```

### confval-menu Directive

Display a list of confval entries:

```rst
..  confval-menu::
    :name: my-extension-options
    :display: table
```

Display options: `table`, `list`, `tree`

## PHP Domain

Document PHP APIs with structured directives.

### Namespace Declaration

```rst
..  php:namespace:: Vendor\Extension\Service
```

### Class Documentation

```rst
..  php:class:: VaultService

    Manages secure storage and retrieval of secrets.

    ..  php:method:: store(string $identifier, string $secret, array $options = []): void

        Store a secret in the vault.

        :param string $identifier: Unique identifier for the secret
        :param string $secret: The secret value to store
        :param array $options: Additional storage options
        :throws: \Vendor\Extension\Exception\VaultException

    ..  php:method:: retrieve(string $identifier): ?string

        Retrieve a secret from the vault.

        :param string $identifier: The secret identifier
        :returntype: ?string
```

### Cross-Referencing PHP Elements

| Role | Purpose |
|------|---------|
| `:php:class:` | Link to class |
| `:php:interface:` | Link to interface |
| `:php:func:` | Link to method/function |
| `:php:const:` | Link to constant |
| `:php:exc:` | Link to exception |

**Note:** Escape backslashes: `:php:class:`\\Vendor\\Extension\\MyClass``

### When NOT to Use PHP Domain

Use `confval` instead of PHP domain for:
- TCA configuration
- Extension configuration arrays
- Any PHP array-based configuration

## Site Settings Documentation

Auto-document site set settings from YAML definitions.

### Syntax

```rst
..  typo3:site-set-settings:: PROJECT:/Configuration/Sets/MySet/settings.definitions.yaml
    :name: my-site-settings
```

### Options

| Option | Purpose |
|--------|---------|
| `:name:` | Namespace prefix for links |
| `:type:` | Filter by field type |
| `:Label:` | Column width for labels |
| `:default:` | Column width for defaults |

The `PROJECT:` prefix loads files from the extension directory.

## Decision Guide

### Use `code-block` When

- Showing example code inline in documentation
- Code is short (< 30 lines)
- Code is illustrative, not production-ready

### Use `literalinclude` When

- Code is long (> 30 lines)
- Code should be executable/testable
- Same code is referenced multiple times

### Use `confval` When

- Documenting configuration options
- Values have type, default, required attributes
- Need structured presentation of settings

### Use Inline Roles When

- Mentioning code elements in text
- Referencing file paths, UI elements
- Keep paragraphs readable (avoid overuse)

### Use PHP Domain When

- Documenting public API
- Creating formal class/method reference
- Need cross-referencing between API elements

## Pre-Commit Checklist

1. ✅ Code blocks have `:caption:` with file path
2. ✅ Correct language identifier used
3. ✅ Syntax is valid (highlighting works)
4. ✅ Placeholders use angle brackets
5. ✅ Long code uses `literalinclude`
6. ✅ Configuration uses `confval` directive
7. ✅ Inline code uses appropriate roles
8. ✅ UI elements use `:guilabel:`
9. ✅ File paths use `:file:` or `:path:`

## References

- **Code Blocks:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/Codeblocks.html
- **confval:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/Confval.html
- **Inline Code:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/InlineCode.html
- **PHP Domain:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/Phpdomain.html
- **Site Settings:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Code/SiteSettings.html
