# RST Syntax Reference

Complete reStructuredText syntax reference for TYPO3 documentation.

## Headings

```rst
=======================
Page title in sentence case
=======================

Section heading
===============

Subsection heading
------------------

Subsubsection heading
~~~~~~~~~~~~~~~~~~~~~

Paragraph heading
"""""""""""""""""

Deep heading
''''''''''''
```

**Heading Hierarchy:**

| Level | Character | Usage |
|-------|-----------|-------|
| 1 (Title) | `=` above and below | Page title only |
| 2 | `=` below | Major sections |
| 3 | `-` below | Subsections |
| 4 | `~` below | Sub-subsections |
| 5 | `"` below | Paragraphs |
| 6 | `'` below | Deep nesting |
| 7+ | `^`, `#` | Rarely used |

**Rules:**
- **CRITICAL**: Underline must be exactly the same length as the title text
- **SENTENCE CASE**: Use sentence case for all headlines, NOT title case
  - ✅ Correct: "Mass approval on Crowdin", "API endpoints", "Best practices"
  - ❌ Wrong: "Mass Approval On Crowdin", "API Endpoints", "Best Practices"
- **PERMALINK ANCHORS**: Every section MUST have a label (`.. _section-label:`)

## Inline Formatting

```rst
*italic text*
**bold text**
``code or literal text``
```

## Code Blocks

### Basic Syntax

```rst
..  code-block:: php
    :caption: Example PHP file

    <?php
    $code = 'example';
```

### Code Block Options

| Option | Purpose | Example |
|--------|---------|---------|
| `:caption:` | Descriptive label (typically file path) | `:caption: ext_localconf.php` |
| `:linenos:` | Display line numbers | `:linenos:` |
| `:lineno-start:` | Start line numbers at N | `:lineno-start: 10` |
| `:emphasize-lines:` | Highlight specific lines | `:emphasize-lines: 3,5-7` |
| `:name:` | Unique reference label | `:name: code-example-auth` |

**Example with All Options:**
```rst
..  code-block:: php
    :caption: Classes/Service/AuthService.php
    :linenos:
    :lineno-start: 15
    :emphasize-lines: 3,5
    :name: auth-service-example

    public function authenticate(string $token): bool
    {
        $user = $this->userRepository->findByToken($token);
        if ($user === null) {
            return false;
        }
        return $user->isActive();
    }
```

### Supported Languages

Over 200 languages supported including:

| Language | Identifier |
|----------|------------|
| PHP | `php` |
| TypoScript | `typoscript` |
| YAML | `yaml` |
| JavaScript | `javascript` or `js` |
| HTML | `html` |
| CSS | `css` |
| XML | `xml` |
| JSON | `json` |
| SQL | `sql` |
| Bash/Shell | `bash` or `shell` |
| Diff | `diff` |
| Plain text | `plaintext` or `text` |
| reStructuredText | `rst` |
| Markdown | `markdown` |

### Language Examples

**PHP:**
```rst
..  code-block:: php
    :caption: PHP example

    <?php
    declare(strict_types=1);
    $code = 'example';
```

**YAML:**
```rst
..  code-block:: yaml
    :caption: Configuration/RTE/Default.yaml

    setting: value
    nested:
      item: value
```

**TypoScript:**
```rst
..  code-block:: typoscript
    :caption: Configuration/TypoScript/setup.typoscript

    lib.parseFunc_RTE {
        tags.img = TEXT
    }
```

**Bash:**
```rst
..  code-block:: bash
    :caption: Install via Composer

    composer require vendor/package
```

**JavaScript:**
```rst
..  code-block:: javascript
    :caption: Resources/Public/JavaScript/Plugin.js

    const example = 'value';
```

### Best Practices

1. **Always add captions** - Include file path where code should go
2. **Use syntactically correct code** - Highlighting fails on syntax errors
3. **Specify language explicitly** - Helps contributors and tools
4. **Use placeholders** - `<placeholder-name>` for variable values
5. **Avoid `::` shorthand** - Use explicit `code-block` directive

## literalinclude (External Files)

Include code from external files instead of inline code blocks.

**Benefits:**
- DRY: Single source of truth for code
- Testable: Referenced file can be syntax-checked/executed
- GitHub link: Rendered docs include "Edit on GitHub" link
- Maintainable: Update code in one place

**Basic Usage:**
```rst
..  literalinclude:: _codesnippets/example.php
    :caption: example.php
    :language: php
```

**With Line Selection:**
```rst
..  literalinclude:: _codesnippets/example.php
    :caption: Relevant excerpt
    :language: php
    :lines: 10-25
```

**With Line Highlighting:**
```rst
..  literalinclude:: _codesnippets/example.php
    :caption: example.php
    :language: php
    :emphasize-lines: 5,10-12
```

**Directory Structure:**
```
Documentation/
├── Section/
│   ├── Index.rst
│   └── _codesnippets/
│       ├── example.php
│       └── config.yaml
```

**When to Use:**
- ✅ Scripts longer than ~20 lines
- ✅ Code that should be executable/testable
- ✅ Examples referenced from multiple places
- ❌ Short inline examples (use code-block)
- ❌ Pseudo-code or partial snippets

**Path Rules:**
- Paths are relative to the RST file location
- Use `../_codesnippets/` to reference parent directory
- Use absolute paths from Documentation root with `/`

## Lists

**Bullet Lists:**
```rst
- First item.
- Second item.

  - Nested item.
  - Another nested.
```

**Numbered Lists:**
```rst
1. First item.
2. Second item.
3. Third item.
```

**Definition Lists:**
```rst
term
   Definition of the term.

another term
   Definition of another term.
```

**Punctuation Rules:**
- **End with periods**: All list items should end with a period (`.`)
- ✅ Correct: `1. Retrieve project metadata to get available languages.`
- ❌ Wrong: `1. Retrieve project metadata to get available languages`
- Exception: Single-word or very short items may omit periods for readability

## Links

**External Links:**
```rst
`Link text <https://example.com>`__
```

**Internal Cross-References:**
```rst
.. _my-label:

Section Title
=============

Link to :ref:`my-label`
Link with custom text: :ref:`Custom Text <my-label>`
```

**Documentation Links:**
```rst
:ref:`t3tsref:start` (TYPO3 TS Reference)
:ref:`t3coreapi:start` (TYPO3 Core API)
```

## Tables

**Simple Table:**
```rst
===========  ===========
Column 1     Column 2
===========  ===========
Row 1 Col 1  Row 1 Col 2
Row 2 Col 1  Row 2 Col 2
===========  ===========
```

**Grid Table:**
```rst
+------------+------------+
| Header 1   | Header 2   |
+============+============+
| Cell 1     | Cell 2     |
+------------+------------+
```

**List Table:**
```rst
.. list-table:: Table Title
   :header-rows: 1
   :widths: 20 80

   * - Column 1
     - Column 2
   * - Value 1
     - Value 2
```

## Admonitions

```rst
.. note::
   Additional information

.. important::
   Important notice

.. warning::
   Warning message

.. attention::
   Attention required

.. tip::
   Helpful tip

.. caution::
   Caution advised
```

## Images

```rst
.. image:: ../Images/screenshot.png
   :alt: Alternative text
   :width: 600px
   :class: with-shadow
```

**Figure with Caption:**
```rst
.. figure:: ../Images/screenshot.png
   :alt: Alternative text
   :width: 600px

   This is the caption text
```

## Table of Contents

**In-page TOC:**
```rst
.. contents::
   :local:
   :depth: 2
```

**Toctree (document hierarchy):**
```rst
.. toctree::
   :maxdepth: 2
   :titlesonly:
   :hidden:

   Introduction/Index
   Configuration/Index
   API/Index
```

## Comments

```rst
.. This is a comment
   It can span multiple lines
   and will not appear in the output
```

## Line Blocks

```rst
| Line 1
| Line 2
| Line 3
```

## Substitutions

```rst
.. |TYPO3| replace:: TYPO3 CMS

Using |TYPO3| in documentation...
```

## Special Characters

```rst
\*literal asterisk\*
```

## Whitespace Rules

1. **Blank lines**: Required before and after directives
2. **Indentation**: Use 3 spaces for directive content
3. **No trailing whitespace**: Remove all trailing spaces
4. **Consistent indentation**: Maintain same level within blocks

## Common Mistakes

❌ **Wrong underline length:**
```rst
Section
====  # Too short
```

❌ **Missing blank lines:**
```rst
.. code-block:: php
   $code = 'example';  # No blank line before content
```

❌ **Incorrect indentation:**
```rst
.. note::
  Text  # Only 2 spaces instead of 3
```

✅ **Correct:**
```rst
Section
=======

.. code-block:: php

   $code = 'example';

.. note::
   Text with 3-space indentation
```

## README.md and Documentation/ Synchronization

Keep README.md and Documentation/ in sync to avoid contradictions.

**Content Parity:**
- Topics covered in README.md should have corresponding coverage in Documentation/.
- New features added to README.md should be documented in the appropriate .rst files.
- README.md serves as a quick-start; Documentation/ provides comprehensive details.

**Consistency (No Contradictions):**
When README.md and Documentation/ cover the same topics, they must not contradict each other:

- **CLI commands**: Command names and option flags must match.
  - ❌ README: `vault:master-key:rotate --new-key-file=...`
  - ✅ Docs: `vault:rotate-master-key --new-key=...`
  - Fix: Update README to match Documentation/.
- **Code examples**: TCA configs, API usage, class names must be consistent.
  - ❌ README: `'type' => 'user'`
  - ✅ Docs: `'type' => 'input'`
  - Fix: Update README to match Documentation/.
- **Configuration values**: Defaults and option names must align.

**Source of Truth:**
- Documentation/ is the authoritative source.
- When inconsistencies are found, update README.md to match Documentation/.
- Commit README.md and Documentation/ changes together atomically.

## References

- **Sphinx RST Guide:** https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html
- **Docutils RST:** https://docutils.sourceforge.io/rst.html
- **TYPO3 Documentation Guide:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/
