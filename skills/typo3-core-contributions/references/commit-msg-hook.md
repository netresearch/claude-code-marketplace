# TYPO3 Commit Message Hook

Deep dive into the `Build/git-hooks/commit-msg` hook: validation rules, error messages, and troubleshooting.

## Overview

The commit-msg hook is a Git client-side hook that validates commit messages before they're created. TYPO3 uses this to enforce commit message standards and automatically add Change-Id for Gerrit tracking.

**Location**: `Build/git-hooks/commit-msg`
**Installed to**: `.git/hooks/commit-msg`

## Installation

### Automated (Recommended)

```bash
composer gerrit:setup
```

This command:
1. Copies hook from `Build/git-hooks/commit-msg` to `.git/hooks/commit-msg`
2. Makes it executable
3. Sets up Gerrit configuration

### Manual

```bash
# Copy hook
cp Build/git-hooks/commit-msg .git/hooks/commit-msg

# Make executable
chmod +x .git/hooks/commit-msg
```

### Verify Installation

```bash
# Check if hook exists and is executable
ls -la .git/hooks/commit-msg

# Expected output:
# -rwxr-xr-x 1 user group 8192 Dec 15 10:00 .git/hooks/commit-msg
```

## Hook Functions

### 1. Change-Id Generation

**Purpose**: Auto-generate unique Change-Id for Gerrit patch tracking

**Function**: `add_ChangeId()`

**Behavior**:
- Generates unique hash based on commit content
- Adds `Change-Id: I<hash>` to commit message footer
- Skips if Change-Id already exists
- Skips for fixup!/squash! commits
- Places Change-Id after Resolves/Releases footer

**Format**:
```
Change-Id: I1234567890abcdef1234567890abcdef12345678
```

**Critical Rules**:
- NEVER manually add Change-Id
- NEVER modify existing Change-Id
- NEVER remove Change-Id
- Same Change-Id = same patch (for updates)
- Different Change-Id = new patch

### 2. Line Length Validation

**Function**: `checkForLineLength()`

**Rules**:
- Maximum line length: 72 characters
- Applies to subject and body
- Excludes comment lines (starting with `#`)
- URLs can exceed limit

**Error Message**:
```
The maximum line length of 72 characters is exceeded.
```

**Location**: Line 200 in hook

### 3. Commit Type Validation

**Function**: `checkForCommitType()`

**Rules**:
- First line must contain commit type in brackets
- Valid types: `[BUGFIX]`, `[FEATURE]`, `[TASK]`, `[DOCS]`, `[SECURITY]`
- Breaking changes: `[!!!][TYPE]`

**Regex**: `/^\[^]]+\] .+$/`

**Error Message**:
```
Your first line has to contain a commit type like '[BUGFIX]'.
```

**Location**: Line 209 in hook

### 4. Resolves Tag Validation

**Function**: `checkForResolves()`

**Rules**:
- Every commit MUST have at least one `Resolves:` or `Fixes:` line
- Format: `Resolves: #<number>` or `Fixes: #<number>`
- Must be on separate line (not inline)
- Issue number must be numeric

**Regex**: `/^(Resolves|Fixes): #[0-9]+$/`

**Error Message** (as of v1.1):
```
You need at least one 'Resolves|Fixes: #<issue number>' line.
```

**Updated Message** (as of v1.2, see Issue #107881):
```
You need at least one 'Resolves: #<issue number>' line.
```

**Location**: Line 218 in hook

**Important Context**:
- The regex accepts both `Resolves:` and `Fixes:` for backward compatibility
- TYPO3 community standard is to use ONLY `Resolves:`
- The error message guides users toward the standard
- This was the source of documentation confusion in Issue #105737

### 5. Releases Tag Validation

**Function**: `checkForReleases()`

**Rules**:
- Every commit MUST have `Releases:` line
- Format: `Releases: main, 13.4, 12.4` (comma-separated)
- Valid values: `main`, version numbers like `13.4`, `12.4`

**Regex**: `/^Releases: (main|[0-9]+\.[0-9])(, *(main|[0-9]+\.[0-9]))*$/`

**Error Message**:
```
You need a 'Releases:' line. For instance: Releases: main, 8.7
```

**Location**: Line 227 in hook

## Complete Validation Flow

```
Commit attempted
    ↓
1. Check line length (≤ 72 chars)
    ↓
2. Check commit type ([BUGFIX], etc.)
    ↓
3. Check Resolves/Fixes tag exists
    ↓
4. Check Releases tag exists
    ↓
All pass? → Add Change-Id → Commit succeeds
Any fail? → Show errors → Commit rejected
```

## Error Messages

### Full Error Output

When validation fails:
```
------------------------------------------------------------------
 >> ERROR in your commit message:

 - The maximum line length of 72 characters is exceeded.
 - You need at least one 'Resolves: #<issue number>' line.
 - You need a 'Releases:' line. For instance: Releases: main, 8.7

  Please refer to [1] for details on the commit requirements.
  You should fix this and then do commit --amend etc.
  [1] https://docs.typo3.org/typo3cms/ContributionWorkflowGuide/latest/singlehtml/Index.html#commit-message-rules-for-typo3-cms
------------------------------------------------------------------
```

### Individual Errors

| Check | Error Message |
|-------|---------------|
| Line length | `The maximum line length of 72 characters is exceeded.` |
| Commit type | `Your first line has to contain a commit type like '[BUGFIX]'.` |
| Resolves tag | `You need at least one 'Resolves: #<issue number>' line.` |
| Releases tag | `You need a 'Releases:' line. For instance: Releases: main, 8.7` |

## Troubleshooting

### Hook Not Running

**Symptom**: Commits succeed without validation

**Causes**:
1. Hook not installed
2. Hook not executable
3. Git hooks disabled

**Solutions**:
```bash
# Check if hook exists
ls -la .git/hooks/commit-msg

# Reinstall hook
composer gerrit:setup

# Verify permissions
chmod +x .git/hooks/commit-msg

# Check Git config (hooks disabled?)
git config --get core.hooksPath
```

### Hook Rejecting Valid Commit

**Symptom**: Valid commit message rejected

**Debug**:
```bash
# Test commit message manually
bash .git/hooks/commit-msg .git/COMMIT_EDITMSG

# Check for hidden characters
cat -A .git/COMMIT_EDITMSG

# Verify line endings (should be LF, not CRLF)
file .git/COMMIT_EDITMSG
```

**Common issues**:
- Windows line endings (CRLF) instead of Unix (LF)
- Trailing whitespace
- Non-ASCII characters in unexpected places
- Tabs vs spaces

### Change-Id Not Generated

**Symptom**: Commit succeeds but no Change-Id added

**Causes**:
1. Change-Id already exists (manual addition)
2. Config disables it: `git config --get gerrit.createChangeId` returns `false`
3. fixup!/squash! commit (intentionally skipped)

**Solutions**:
```bash
# Enable Change-Id generation
git config gerrit.createChangeId true

# Re-commit to generate
git commit --amend --no-edit

# Verify Change-Id added
git log -1
```

### Multiple Change-Ids

**Symptom**: Commit has multiple Change-Id lines

**Impact**: Gerrit will reject or behave unexpectedly

**Fix**:
```bash
# Edit commit message
git commit --amend

# Remove duplicate Change-Id lines (keep only one)
# Save and exit
```

## Hook Customization

### When to Customize

**Valid reasons**:
- Project-specific validation rules
- Additional required tags
- Custom commit message format

**Invalid reasons**:
- Bypassing validation (use `--no-verify` temporarily instead)
- Making validation more lenient (breaks standardization)

### Safe Customization Pattern

```bash
# 1. Fork the hook
cp .git/hooks/commit-msg .git/hooks/commit-msg.custom

# 2. Add custom validation
# Edit .git/hooks/commit-msg.custom

# 3. Call from main hook
# In .git/hooks/commit-msg, add:
# .git/hooks/commit-msg.custom "$1"

# 4. Document customization
echo "Custom validation: <description>" >> .git/hooks/commit-msg.custom
```

### Example: Additional Tag

Add optional `Sponsored-by:` tag:

```bash
# Add to checkForResolves() section
checkForSponsor() {
    if grep -q -E '^Sponsored-by: ' "$MSG"; then
        # Valid sponsor tag found
        return 0
    fi
}

# Call in validation sequence
checkForLineLength
checkForCommitType
checkForResolves
checkForReleases
checkForSponsor  # Custom check
```

## Bypassing Hook

### When to Bypass

**Valid cases**:
- Emergency hotfixes
- Rebasing with preserved commits
- Importing historical commits
- Temporary testing

**Invalid cases**:
- Avoiding fixing commit message
- Regular development workflow

### How to Bypass

```bash
# Single commit
git commit --no-verify

# Amend without hook
git commit --amend --no-verify

# Rebase without hook
GIT_EDITOR=true git rebase -i HEAD~5 --no-verify
```

**Warning**: Gerrit will still reject invalid commits! Bypassing hook locally doesn't bypass Gerrit validation.

## Hook History

### Version 1.1 (Current)

**From**: TYPO3 CI Review 1.1
**Based on**: Gerrit Code Review 2.14.6

**Changes from Gerrit original**:
- Added line length check (72 chars)
- Added commit type check ([BUGFIX], etc.)
- Added Resolves/Fixes check
- Added Releases check
- Modified Change-Id placement (after footer)

### Proposed Version 1.2 (Issue #107881)

**Change**: Update error message for Resolves check
- **Old**: `'Resolves|Fixes: #<issue number>'`
- **New**: `'Resolves: #<issue number>'`

**Rationale**:
- TYPO3 standard is `Resolves:` only
- `Fixes:` accepted for backward compatibility only
- Error message should guide toward standard practice

**Validation regex unchanged**: Still accepts both for compatibility

## Hook Source Code Structure

```bash
Build/git-hooks/commit-msg
├── License header (Apache 2.0)
├── TYPO3 changes documentation
├── add_ChangeId() function
│   ├── clean_message preprocessing
│   ├── Skip conditions (fixup, squash, existing)
│   ├── ID generation
│   └── AWK script for placement
├── _gen_ChangeId() helper
├── _gen_ChangeIdInput() helper
├── Validation functions:
│   ├── checkForLineLength()
│   ├── checkForCommitType()
│   ├── checkForResolves()
│   └── checkForReleases()
├── Validation execution
└── add_ChangeId() call
```

## Best Practices

### For Contributors

1. **Install hook early**: First thing after cloning
2. **Never bypass**: Fix messages instead of bypassing
3. **Don't fight the hook**: Learn requirements, follow them
4. **Use templates**: `git config commit.template ~/.gitmessage.txt`
5. **Test locally**: Use `scripts/validate-commit-message.py`

### For Maintainers

1. **Document changes**: Keep this reference updated
2. **Test thoroughly**: Validate changes don't break existing commits
3. **Backward compatible**: Keep regex accepting old patterns
4. **Clear errors**: Make error messages actionable
5. **Version carefully**: Changes affect all contributors

## Related Files

- `Build/git-hooks/commit-msg` - The hook itself
- `Build/git-hooks/pre-commit` - Code quality checks
- `assets/commit-template.txt` - Commit message template
- `scripts/validate-commit-message.py` - Offline validator
- `references/commit-message-format.md` - Commit message specification

## References

- **Hook Source**: https://github.com/TYPO3/typo3/blob/main/Build/git-hooks/commit-msg
- **Git Hooks Docs**: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks
- **Gerrit Hooks**: https://gerrit-review.googlesource.com/Documentation/cmd-hook-commit-msg.html
- **Issue #107881**: Standardize error message to mention only Resolves

## Quick Reference

| Validation | Required Format | Error if Missing |
|------------|----------------|------------------|
| Commit type | `[TYPE]` in first line | Yes |
| Line length | ≤ 72 characters | Yes |
| Resolves | `Resolves: #123` | Yes |
| Releases | `Releases: main` | Yes |
| Change-Id | Auto-generated | N/A (added by hook) |

## See Also

- `scripts/validate-commit-message.py` - Test messages offline
- `scripts/create-commit-message.py` - Generate compliant messages
- `assets/commit-template.txt` - Pre-filled template
