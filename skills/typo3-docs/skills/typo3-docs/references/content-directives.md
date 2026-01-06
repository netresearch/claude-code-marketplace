# Content Directives Reference

Complete reference for TYPO3 documentation content directives: accordions, admonitions, cards, tabs, tables, versions, and viewhelpers.

Based on:
- https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Accordion.html
- https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Admonitions.html
- https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Cards.html
- https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Tabs.html
- https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Tables.html
- https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Versions.html
- https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Viewhelper.html

## When to Use What

| Content Type | Directive | Use Case |
|--------------|-----------|----------|
| Collapsible sections | `accordion` | FAQ-style content, optional details |
| Warnings/notes | Admonitions | Important notices, tips, cautions |
| Overview grids | `card-grid` | Feature lists, navigation pages |
| Alternative code | `tabs` | Multi-language examples, version variants |
| Structured data | Tables | Comparisons, reference data |
| Version info | `versionadded` | API changes, new features |
| Fluid docs | `typo3:viewhelper` | ViewHelper reference |

## Accordion

Collapsible content sections for FAQ-style presentation or optional details.

### Basic Syntax

```rst
..  accordion::
    :name: faq-accordion

    ..  accordion-item:: First question?
        :name: faq-first

        Answer to the first question.

    ..  accordion-item:: Second question?
        :name: faq-second
        :open:

        Answer to the second question.
        This one is open by default.
```

### Options

| Option | Purpose |
|--------|---------|
| `:name:` | Unique identifier for linking (`:ref:`) |
| `:open:` | Display accordion item expanded by default |

### Best Practices

- Use for FAQ sections
- Use for optional, supplementary information
- Use for long content that would break reading flow
- Do NOT use for critical information users might miss

## Admonitions

Visual callouts to highlight important information.

### Available Types

| Type | Purpose | Visual |
|------|---------|--------|
| `note` | General information | Blue info icon |
| `tip` | Helpful suggestions | Green lightbulb |
| `hint` | Subtle suggestions | Similar to tip |
| `warning` | Potential issues | Yellow warning |
| `caution` | Exercise care | Yellow caution |
| `attention` | Important notice | Yellow attention |
| `important` | Critical information | Yellow important |
| `danger` | Serious problems | Red danger |
| `error` | Error conditions | Red error |
| `seealso` | Related links | Blue links |

### Syntax Examples

**Note (most common):**
```rst
..  note::
    This is important background information.
```

**Tip with title:**
```rst
..  tip::
    :title: Performance Optimization

    Consider caching the result for better performance.
```

**Warning:**
```rst
..  warning::
    This action cannot be undone.
```

**See Also:**
```rst
..  seealso::
    - :ref:`related-topic`
    - `External Resource <https://example.com>`_
```

### Options

| Option | Purpose |
|--------|---------|
| `:title:` | Custom heading (default: directive name) |
| `:class:` | Additional CSS classes |
| `:name:` | Label for cross-referencing |

### Decision Guide

| Situation | Use |
|-----------|-----|
| Background context | `note` |
| Helpful suggestion | `tip` |
| Potential problems | `warning` |
| Data loss risk | `danger` |
| Related resources | `seealso` |
| API deprecation | `deprecated` (version directive) |

## Cards

Grid-based presentation for overview pages and feature lists.

### Basic Card Grid

```rst
..  card-grid::
    :columns: 2
    :columns-md: 3
    :gap: 4
    :class: pb-4
    :card-height: 100

    ..  card:: Feature One

        Description of the first feature.

    ..  card:: Feature Two

        Description of the second feature.

    ..  card:: :ref:`Linked Card <target-label>`

        Card with a linked title.
```

### Card Grid Options

| Option | Purpose | Example |
|--------|---------|---------|
| `:columns:` | Columns on small screens | `:columns: 1` |
| `:columns-md:` | Columns on medium screens | `:columns-md: 2` |
| `:columns-lg:` | Columns on large screens | `:columns-lg: 3` |
| `:gap:` | Spacing between cards (0-5) | `:gap: 4` |
| `:card-height:` | Uniform card height | `:card-height: 100` |
| `:class:` | CSS classes | `:class: pb-4` |

### Card Options

| Option | Purpose |
|--------|---------|
| `:headline-level:` | Heading level (default 2) |
| `:link:` | Make entire card clickable |

### Use Cases

- Documentation landing pages
- Feature overview sections
- Navigation hub pages
- Comparison layouts

## Tabs

Grouped content with synchronized tab switching.

### Basic Syntax

```rst
..  tabs::

    ..  group-tab:: PHP

        ..  code-block:: php

            <?php
            $value = 'example';

    ..  group-tab:: TypoScript

        ..  code-block:: typoscript

            lib.example = TEXT
            lib.example.value = example
```

### Synchronized Tabs

Tabs with the same name synchronize across the page:

```rst
First example:

..  tabs::

    ..  group-tab:: Composer

        Run :bash:`composer require vendor/package`

    ..  group-tab:: Classic

        Download and install manually.

Second example (tabs sync with above):

..  tabs::

    ..  group-tab:: Composer

        Update with :bash:`composer update`

    ..  group-tab:: Classic

        Download the new version.
```

### Use Cases

- Multi-language code examples (PHP, TypoScript, Fluid)
- Installation methods (Composer vs Classic)
- TYPO3 version variations
- Platform-specific instructions (Linux, macOS, Windows)

### Best Practices

- Use consistent tab names for synchronization
- Keep tab content comparable in scope
- First tab should be the most common/recommended option
- Do NOT nest tabs inside tabs

## Tables

Structured data presentation with multiple syntaxes.

### Simple Table (Quick)

```rst
=====  =====  ======
Col 1  Col 2  Col 3
=====  =====  ======
A      B      C
D      E      F
=====  =====  ======
```

### Grid Table (Complex)

```rst
+------------+------------+-----------+
| Header 1   | Header 2   | Header 3  |
+============+============+===========+
| Cell 1     | Cell 2     | Cell 3    |
+------------+------------+-----------+
| Cell 4     | Merged cell            |
+------------+------------+-----------+
```

### CSV Table (Data-Heavy)

```rst
..  csv-table:: Example Data
    :header: "Name", "Value", "Description"
    :widths: 20, 10, 70

    "Option A", "1", "First option"
    "Option B", "2", "Second option"
```

### t3-field-list-table (TYPO3 Specific)

For TCA field documentation:

```rst
..  t3-field-list-table::
    :header-rows: 1

    -   :Field:         Name
        :Description:   Purpose

    -   :Field:         `title`
        :Description:   The page title

    -   :Field:         `hidden`
        :Description:   Visibility flag
```

### Table Options

| Option | Purpose |
|--------|---------|
| `:header-rows:` | Number of header rows |
| `:widths:` | Column width ratios |
| `:width:` | Total table width |
| `:class:` | CSS classes |
| `:name:` | Reference label |

### Decision Guide

| Scenario | Table Type |
|----------|------------|
| Quick 2-3 column | Simple table |
| Complex merging | Grid table |
| External data | csv-table |
| TCA/field docs | t3-field-list-table |

## Version Directives

Document version-specific changes.

### versionadded

New features or additions:

```rst
..  versionadded:: 12.0
    The `newMethod()` was added for improved performance.
```

### versionchanged

Modified behavior:

```rst
..  versionchanged:: 13.0
    The default value changed from `false` to `true`.
```

### deprecated

Features to be removed:

```rst
..  deprecated:: 12.4
    Use :php:`NewClass` instead. Will be removed in TYPO3 14.0.
```

### Placement

Version directives should appear:
- After the heading they relate to
- Before the detailed description
- At the beginning of the relevant section

### Example

```rst
Configuration options
=====================

..  confval:: legacyMode
    :name: ext-myext-legacyMode
    :type: bool
    :default: false

    ..  deprecated:: 13.0
        This option will be removed in TYPO3 15.0.
        Use the new :confval:`modernMode` instead.

    Enable legacy compatibility mode.
```

## ViewHelper Documentation

Document Fluid ViewHelpers using the typo3:viewhelper directive.

### Syntax

```rst
..  typo3:viewhelper:: f:format.html

    Renders the content as HTML.

    ..  rubric:: Example

    ..  code-block:: html

        <f:format.html>{content}</f:format.html>

    ..  rubric:: Arguments

    ..  include:: /CodeSnippets/ViewHelpers/Format/HtmlArguments.rst.txt
```

### Argument Documentation

```rst
..  confval:: parseFuncTSPath
    :name: f-format-html-parseFuncTSPath
    :type: string
    :default: 'lib.parseFunc_RTE'

    Path to TypoScript parseFunc configuration.
```

### Best Practices

- Document all arguments with `confval`
- Include code examples
- Show common use cases
- Link to related ViewHelpers

## Comments

RST comments are not rendered:

```rst
..  This is a comment.
    It can span multiple lines
    as long as they are indented.

Regular content continues here.
```

Use comments for:
- TODO notes during development
- Explanatory notes for other authors
- Temporarily hiding content

## Special Characters

UTF-8 encoding supports all Unicode characters directly:

```rst
The em dash — is commonly used.
Arrows: → ← ↑ ↓
Check marks: ✓ ✗
Copyright: ©
```

No escape sequences needed with UTF-8 encoding.

## Pre-Commit Checklist

1. ✅ Admonitions use correct type for message severity
2. ✅ Cards have consistent structure in grid
3. ✅ Tabs use matching names for synchronization
4. ✅ Tables use appropriate syntax for complexity
5. ✅ Version directives include version number
6. ✅ Deprecated items mention replacement and removal version
7. ✅ Accordion items have unique names
8. ✅ All directives properly indented (4 spaces)

## References

- **Accordion:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Accordion.html
- **Admonitions:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Admonitions.html
- **Cards:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Cards.html
- **Tabs:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Tabs.html
- **Tables:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Tables.html
- **Versions:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Versions.html
- **ViewHelper:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/ReStructuredText/Content/Viewhelper.html
