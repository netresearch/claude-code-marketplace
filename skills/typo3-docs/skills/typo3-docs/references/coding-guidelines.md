# RST Coding Guidelines

Complete reference for TYPO3 documentation coding standards.

Based on: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Advanced/CodingGuidelines.html

## .editorconfig (Required)

Every `Documentation/` folder **must** contain an `.editorconfig` file to enforce consistent formatting:

```editorconfig
# Documentation/.editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 4
insert_final_newline = true
trim_trailing_whitespace = true
max_line_length = 80

[*.rst]
indent_size = 4

[*.{yaml,yml}]
indent_size = 2
```

**Why .editorconfig?**
- Ensures consistent formatting across editors (VS Code, PhpStorm, Vim, etc.)
- Prevents common issues: wrong indentation, trailing whitespace, mixed line endings
- Auto-enforces TYPO3 documentation standards

## Encoding

- **UTF-8** encoding for all files
- Include special characters directly (no escape sequences)

## Indentation

| Rule | Value |
|------|-------|
| Indentation style | **Spaces only** (never tabs) |
| Indentation size | **4 spaces** per level |
| Code examples | 4 spaces indentation |

**Critical:** Incorrect indentation causes rendering failures. RST is whitespace-sensitive.

```rst
.. note::
    This is correctly indented with 4 spaces.
    The content aligns properly.

.. code-block:: php

    <?php
    // Code block content also uses 4 spaces
    $example = 'value';
```

## Line Length

- Maximum **80 characters** per line
- Shorter lines improve:
  - Source code readability
  - GitHub diff viewing
  - Side-by-side editing

**Breaking long lines:**

```rst
This is a long paragraph that needs to be broken into multiple
lines to stay under the 80-character limit. Continue on the next
line without extra indentation for paragraph text.

.. confval:: some_very_long_configuration_name
   :type: string
   :default: some_default_value

   Description wraps naturally when it exceeds the line limit.
```

## Whitespace

| Rule | Requirement |
|------|-------------|
| Trailing whitespace | **Remove** from all line endings |
| Blank lines | Use to separate sections and directives |
| Final newline | **Required** at end of file |
| Line endings | **LF** (Unix-style), not CRLF |

## Heading Hierarchy

Use consistent underlining characters per heading level:

| Level | Character | Usage |
|-------|-----------|-------|
| 1 | `=` above and below | Page title only |
| 2 | `=` below | Major sections |
| 3 | `-` below | Subsections |
| 4 | `~` below | Sub-subsections |
| 5 | `"` below | Paragraphs |
| 6 | `'` below | Deep nesting |
| 7 | `^` below | Rarely used |
| 8 | `#` below | Rarely used |

**Rules:**
- Underline must be **exactly** the same length as heading text
- Each file starts with level 1, regardless of document hierarchy
- Use **sentence case** (not Title Case)

```rst
=========================
Page title in sentence case
=========================

Section heading
===============

Subsection heading
------------------

Sub-subsection heading
~~~~~~~~~~~~~~~~~~~~~~
```

## Version Hints

Use standard TYPO3 directives for version information:

```rst
.. versionadded:: 12.0
   This feature was added in TYPO3 12.0.

.. versionchanged:: 13.0
   The behavior was modified in TYPO3 13.0.

.. deprecated:: 12.4
   This feature is deprecated and will be removed in TYPO3 14.0.
```

## GUI and Keyboard References

### Menu Paths

Use `:guilabel:` with `>` separator:

```rst
Navigate to :guilabel:`Admin Tools > Settings > Extension Configuration`.
```

### Keyboard Shortcuts

Use `:kbd:` role:

```rst
Press :kbd:`Ctrl+S` to save.
Use :kbd:`Ctrl+Shift+P` to open the command palette.
```

### Button Labels

Match exact GUI spelling:

```rst
Click :guilabel:`Save and close` to apply changes.
```

## Common Formatting Errors

### Wrong Indentation

```rst
.. note::
  Wrong: only 2 spaces

.. note::
    Correct: 4 spaces
```

### Inconsistent Heading Underlines

```rst
Section
====
Wrong: underline too short

Section
=======
Correct: matches text length
```

### Trailing Whitespace

```rst
This line has trailing spaces.
Wrong: spaces at end

This line is clean.
Correct: no trailing whitespace
```

### Mixed Tabs and Spaces

```rst
..	code-block:: php
Wrong: tab character after ..

..  code-block:: php
Correct: spaces only
```

## Pre-Commit Checklist

1. ✅ `.editorconfig` exists in `Documentation/`
2. ✅ All files use UTF-8 encoding
3. ✅ Indentation uses 4 spaces (no tabs)
4. ✅ Lines are under 80 characters
5. ✅ No trailing whitespace
6. ✅ Files end with a newline
7. ✅ Line endings are LF (Unix-style)
8. ✅ Heading underlines match text length
9. ✅ Sentence case for headings

## Editor Configuration

### VS Code

Install the EditorConfig extension. It automatically reads `.editorconfig`.

### PhpStorm / IntelliJ

EditorConfig support is built-in. Enable in Settings > Editor > Code Style.

### Vim

Install `editorconfig-vim` plugin:
```vim
Plug 'editorconfig/editorconfig-vim'
```

## References

- **Coding Guidelines:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Advanced/CodingGuidelines.html
- **EditorConfig:** https://editorconfig.org/
