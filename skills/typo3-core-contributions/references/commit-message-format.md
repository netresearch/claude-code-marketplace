# TYPO3 Commit Message Format Specification

Complete specification for TYPO3 Core contribution commit messages with examples and validation rules.

## Structure Overview

```
[TYPE] Subject line (max 52 chars recommended, 72 absolute limit)

Detailed description explaining how and why the changes were made.
Lines wrapped at 72 characters. Explain the context and reasoning
behind the implementation approach.

Multiple paragraphs are allowed. Use bullet points with asterisks (*)
for lists:

* First item with detailed explanation
* Second item
* Third item

Resolves: #12345
Related: #12346
Releases: main, 13.4, 12.4
Change-Id: I1234567890abcdef1234567890abcdef12345678
```

## Subject Line

### Format

`[TYPE] Description starting with uppercase verb in imperative mood`

### Commit Types

| Type | Purpose | Branch Restrictions |
|------|---------|-------------------|
| `[BUGFIX]` | Bug fixes | All branches |
| `[FEATURE]` | New functionality | main branch only |
| `[TASK]` | Refactoring, cleanup, misc | All branches |
| `[DOCS]` | Documentation changes | All branches |
| `[SECURITY]` | Security vulnerability fixes | All branches |

### Breaking Changes

Use `[!!!]` prefix before type for breaking changes:

```
[!!!][FEATURE] Remove deprecated TypoScript syntax

[!!!][TASK] Drop support for PHP 7.4
```

**Important**: Deprecations must NOT use `[!!!]` prefix!

### Length Limits

- **Recommended**: 52 characters
- **Absolute maximum**: 72 characters
- Breaking changes get 5 extra chars: `[!!!]` is not counted against limit

### Imperative Mood

Subject must use imperative present tense (command form):

✅ **Correct**:
- `Fix memory leak in cache manager`
- `Add support for WebP images`
- `Remove deprecated method calls`
- `Update documentation for hooks`

❌ **Wrong**:
- `Fixed memory leak` (past tense)
- `Fixing memory leak` (present continuous)
- `Fixes memory leak` (present tense)
- `Memory leak fix` (noun phrase)

**Test**: "If applied, this commit will _[your subject]_"
- "If applied, this commit will **fix memory leak**" ✅
- "If applied, this commit will **fixed memory leak**" ❌

### Capitalization

- Start description with uppercase letter after `[TYPE]`
- No period at the end

✅ `[BUGFIX] Fix null pointer exception in indexer`
❌ `[BUGFIX] fix null pointer exception in indexer`
❌ `[BUGFIX] Fix null pointer exception in indexer.`

### What to Describe

Describe **what now works**, not what was broken:

✅ `Allow cancelling file exists modal`
❌ `Cancelling the file exists modal works now`

✅ `Limit element browser to default language pages`
❌ `Element Browser should only render default language pages`

## Description Body

### Purpose

Explain the **how** and **why** of changes, not the **what** (code shows what).

### Guidelines

- Wrap lines at 72 characters (URLs can be longer)
- Leave blank line after subject
- Explain context and reasoning
- **Don't** repeat Forge issue content
- **Don't** describe reproduction steps (belong in Forge)
- **Do** explain non-obvious implementation choices
- **Do** mention side effects or impacts

### Bullet Points

Use asterisks (`*`) with hanging indents:

```
This change improves performance by:

* Caching compiled templates in memory
* Reducing database queries from N+1 to 1
* Pre-loading frequently accessed resources
```

### Documenting Tests

When your patch includes tests, add a line to document this:

```
Added tests fixate this behavior.
```

This standard phrase indicates that tests were added to prevent regression. Place it after the main description, before the "Affected" list (if any):

**Example**:
```
[BUGFIX] Fix crash on dynamic method calls

Several matchers crash when encountering dynamic method calls
like `$object->$methodName()`. This happens because the code
assumes `$node->name` is always an identifier.

This is fixed by adding an explicit `instanceof` check
before accessing `$node->name->name`.

Added tests fixate this behavior.

Affected matchers:
- MethodCallMatcher
- MethodArgumentDroppedMatcher

Resolves: #108413
Releases: main, 14.0, 13.4
```

### Long URLs

Lines exceeding 72 chars are acceptable for URLs. Use numbered references:

```
This implements the W3C recommendation [1] for accessible forms.

Additional context can be found in the TYPO3 RFC [2].

[1] https://www.w3.org/WAI/WCAG21/Understanding/labels-or-instructions.html
[2] https://wiki.typo3.org/Category:T3DD12/Sessions/Accessibility
```

## Footer Tags

### Required Format

`Tag: value` (colon followed by space)

### Resolves **(REQUIRED)**

Closes Forge issue when patch is merged:

```
Resolves: #12345
```

Multiple issues (one per line):
```
Resolves: #12345
Resolves: #12346
```

**Critical Rule**: Every commit MUST have at least one `Resolves:` line. The commit-msg hook will reject commits without it.

**When to use**:
- Features: MUST use Resolves
- Tasks: MUST use Resolves
- Bugfixes: MUST use Resolves
- All commit types: ALWAYS use Resolves

**Note**: For features and tasks, `Resolves:` closes the issue on merge. For bugfixes, you can use `Related:` in addition to `Resolves:` if needed, but `Resolves:` is still mandatory.

### Related **(OPTIONAL)**

Links issue without closing it:

```
Related: #12345
```

**Critical Rule**: `Related:` CANNOT be used alone - you MUST have at least one `Resolves:` line in addition to any `Related:` lines. The commit-msg hook will reject commits with only `Related:` tags.

**When to use** (in addition to Resolves):
- Bugfixes: Use Related for issues that should stay open
- Partial fixes: Related for multi-step fixes where issue remains open
- Context: Link related discussions or issues
- Cross-references: Link to related work or documentation

### Releases

Target versions (comma-separated):

```
Releases: main, 13.4, 12.4
```

**Format**:
- `main` - Current development branch
- `13.4` - Patch release version
- `12.4` - LTS version

**Rules**:
- Always include target versions
- List from newest to oldest
- Features go to `main` only
- Bugfixes can target multiple releases

### Change-Id

Auto-generated by git commit-msg hook:

```
Change-Id: I1234567890abcdef1234567890abcdef12345678
```

**Critical Rules**:
- **NEVER** manually add Change-Id
- **NEVER** modify existing Change-Id
- **NEVER** remove Change-Id
- Git hook generates this automatically
- Required for Gerrit to track patch updates

### Depends (Documentation Only)

For documentation patches referencing core changes:

```
Depends: I1234567890abcdef1234567890abcdef12345678
```

Only used in typo3/cms-docs repository.

### Reverts

For reverting patches:

```
[TASK] Revert "[FEATURE] Introduce YAML imports"

This reverts commit abc123def456.

Resolves: #12347
Reverts: I1234567890abcdef1234567890abcdef12345678
```

## Complete Examples

### Example 1: Bugfix

```
[BUGFIX] Prevent null pointer in indexed search

The preg_replace function returns null on PCRE errors like
PREG_BAD_UTF8_ERROR. Passing null to mb_strcut triggers TypeError
in PHP 8.2+.

Add null check with fallback to original content, ensuring type
safety while maintaining graceful degradation for malformed input.

Resolves: #105737
Releases: main, 13.4, 12.4
Change-Id: I1234567890abcdef1234567890abcdef12345678
```

### Example 2: Feature

```
[FEATURE] Add WebP image format support

Implement WebP processing in image manipulation stack:

* Add WebP MIME type detection
* Integrate libwebp encoding/decoding
* Update image quality settings for WebP
* Add configuration options for compression

WebP provides 25-30% better compression than JPEG while maintaining
quality, significantly improving page load times.

Resolves: #98765
Releases: main
Change-Id: Iabcdef1234567890abcdef1234567890abcdef12
```

### Example 3: Task with Breaking Change

```
[!!!][TASK] Drop PHP 7.4 support

PHP 7.4 reached end-of-life in November 2022 and no longer receives
security updates. Remove compatibility code and leverage PHP 8.0+
features:

* Remove PHP 7.4 compatibility polyfills
* Update composer.json to require PHP >= 8.0
* Use union types and match expressions
* Enable strict type declarations globally

Resolves: #99888
Releases: main
Change-Id: I9876543210fedcba9876543210fedcba98765432
```

### Example 4: Documentation

```
[DOCS] Update contribution workflow guide

Clarify git setup instructions and add troubleshooting section
for common SSH key issues reported in #typo3-cms-coredev.

Related: #12345
Releases: main
Change-Id: Iaa11bb22cc33dd44ee55ff66gg77hh88ii99jj00
```

## Validation Rules

### Subject Line

- [ ] Starts with valid commit type: `[BUGFIX]`, `[FEATURE]`, `[TASK]`, `[DOCS]`, or `[SECURITY]`
- [ ] Breaking changes use `[!!!]` prefix correctly
- [ ] Description starts with uppercase letter
- [ ] Uses imperative mood
- [ ] No period at end
- [ ] Length ≤ 52 chars (recommended) or ≤ 72 chars (absolute)
- [ ] No extension names (EXT:) in subject

### Body

- [ ] Blank line after subject (if body exists)
- [ ] Lines wrapped at 72 chars (except URLs)
- [ ] Explains how and why, not what
- [ ] No reproduction steps (belong in Forge)

### Footer

- [ ] `Resolves:` present **(REQUIRED for ALL commits)**
  **Critical**: The commit-msg hook WILL REJECT commits without at least one `Resolves:` line
- [ ] `Related:` used only in addition to `Resolves:` (optional, cannot be used alone)
- [ ] `Releases:` present with valid versions
- [ ] `Change-Id:` present (added by hook)
- [ ] Proper format: `Tag: value` (colon + space)
- [ ] Issue references use `#` prefix: `#12345`

## Common Mistakes

### ❌ Wrong: Vague Subject

```
[TASK] Improve extension configuration
```

### ✅ Correct: Specific Subject

```
[TASK] Add validation for extension configuration arrays
```

---

### ❌ Wrong: Past Tense

```
[BUGFIX] Fixed cache invalidation in frontend
```

### ✅ Correct: Imperative Mood

```
[BUGFIX] Fix cache invalidation in frontend
```

---

### ❌ Wrong: No Footer Tags

```
[FEATURE] Add dark mode support

Implements dark mode toggle with user preference storage.
```

### ✅ Correct: Complete Footer

```
[FEATURE] Add dark mode support

Implements dark mode toggle with user preference storage.

Resolves: #12345
Releases: main
Change-Id: I1234567890abcdef1234567890abcdef12345678
```

---

### ❌ Wrong: Comma-Separated Issues

```
Resolves: #12345, #12346, #12347
```

### ✅ Correct: One Per Line

```
Resolves: #12345
Resolves: #12346
Resolves: #12347
```

---

### ❌ Wrong: Missing Space After Colon

```
Releases:main, 13.4
```

### ✅ Correct: Space After Colon

```
Releases: main, 13.4
```

## Tools

### Validation

Use `scripts/validate-commit-message.py`:

```bash
# Validate last commit
./scripts/validate-commit-message.py

# Validate specific file
./scripts/validate-commit-message.py --file commit-msg.txt

# Strict mode (warnings as errors)
./scripts/validate-commit-message.py --strict
```

### Generation

Use `scripts/create-commit-message.py`:

```bash
# Interactive generator
./scripts/create-commit-message.py --issue 105737 --type BUGFIX

# With breaking change
./scripts/create-commit-message.py --issue 98765 --type FEATURE --breaking
```

### Template

Copy `assets/commit-template.txt` to `~/.gitmessage.txt`:

```bash
git config --global commit.template ~/.gitmessage.txt
```

## References

- **Official Guide**: https://docs.typo3.org/m/typo3/guide-contributionworkflow/main/en-us/Appendix/CommitMessage.html
- **Gerrit Documentation**: https://review.typo3.org/Documentation/
- **TYPO3 Forge**: https://forge.typo3.org

## Quick Reference

| Element | Format | Example |
|---------|--------|---------|
| Bugfix | `[BUGFIX] Description` | `[BUGFIX] Fix null pointer in indexer` |
| Feature | `[FEATURE] Description` | `[FEATURE] Add WebP support` |
| Task | `[TASK] Description` | `[TASK] Refactor cache manager` |
| Breaking | `[!!!][TYPE] Description` | `[!!!][TASK] Drop PHP 7.4 support` |
| Resolves | `Resolves: #12345` | Closes issue on merge |
| Related | `Related: #12345` | Links without closing |
| Releases | `Releases: main, 13.4` | Target versions |
