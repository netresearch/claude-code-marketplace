# Commit Conventions

## Conventional Commits

### Specification

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Commit Types

| Type | Description | Version Bump |
|------|-------------|--------------|
| `feat` | New feature | MINOR |
| `fix` | Bug fix | PATCH |
| `docs` | Documentation only | - |
| `style` | Code style (formatting) | - |
| `refactor` | Code refactoring | - |
| `perf` | Performance improvement | PATCH |
| `test` | Adding/updating tests | - |
| `build` | Build system changes | - |
| `ci` | CI configuration | - |
| `chore` | Maintenance tasks | - |
| `revert` | Reverting changes | - |

### Examples

```bash
# Simple feature
feat: add user authentication

# Feature with scope
feat(auth): add OAuth2 login support

# Bug fix
fix: resolve null pointer in user service

# Bug fix with issue reference
fix(api): handle empty response from external service

Fixes #123

# Breaking change
feat!: remove deprecated v1 API endpoints

BREAKING CHANGE: The /api/v1/* endpoints have been removed.
Migrate to /api/v2/* before upgrading.

# Multiple footers
fix(security): patch XSS vulnerability in comment parser

Reviewed-by: John Doe
Refs: #456
```

### Scope Guidelines

Scopes should be consistent across the project:

```bash
# By feature area
feat(auth): ...
feat(payment): ...
feat(notification): ...

# By layer
fix(api): ...
fix(db): ...
fix(ui): ...

# By component
style(button): ...
refactor(modal): ...
```

## Commit Message Best Practices

### Subject Line

```bash
# ✅ Good: Imperative mood, present tense
feat: add password reset functionality
fix: prevent duplicate form submissions

# ❌ Bad: Past tense, not imperative
feat: added password reset functionality
fix: fixed duplicate form submissions

# ✅ Good: Specific and concise
feat: implement rate limiting for API endpoints

# ❌ Bad: Vague
feat: improve API

# ✅ Good: Under 72 characters
fix: resolve race condition in cache invalidation

# ❌ Bad: Too long
fix: resolve the race condition that was occurring in the cache invalidation process when multiple users were accessing the same resource simultaneously
```

### Body

```bash
# When to include a body:
# - Complex changes needing explanation
# - Non-obvious implementation choices
# - Context for future readers

fix: prevent race condition in order processing

The previous implementation allowed concurrent modifications to the
same order, leading to inconsistent state.

This change introduces optimistic locking using version numbers.
When a conflict is detected, the operation is retried with fresh data.

The retry limit is set to 3 attempts to prevent infinite loops.
```

### Footer

```bash
# Issue references
fix: resolve login timeout

Fixes #123
Closes #456

# Breaking changes
feat!: update authentication API

BREAKING CHANGE: The `authenticate()` method now returns a Promise
instead of using callbacks. Update all call sites to use async/await.

# Co-authors
feat: implement new dashboard

Co-authored-by: Jane Doe <jane@example.com>
Co-authored-by: John Smith <john@example.com>

# Review references
fix: patch security vulnerability

Reviewed-by: Security Team
Approved-by: @security-lead
```

## Atomic Commits

### Principles

1. **One logical change per commit**
2. **Each commit should compile/pass tests**
3. **Related changes grouped together**
4. **Unrelated changes in separate commits**

### Examples

```bash
# ❌ Bad: Multiple unrelated changes
git add .
git commit -m "feat: add login page and fix typo in readme and update deps"

# ✅ Good: Separate commits
git add src/pages/Login.tsx src/components/LoginForm.tsx
git commit -m "feat(auth): add login page with form validation"

git add README.md
git commit -m "docs: fix typo in installation instructions"

git add package.json package-lock.json
git commit -m "build: update dependencies to latest versions"
```

### Interactive Staging

```bash
# Stage specific hunks
git add -p

# Options:
# y - stage this hunk
# n - skip this hunk
# s - split into smaller hunks
# e - manually edit hunk
# q - quit

# Stage specific files
git add src/feature/
git commit -m "feat: add feature files"

git add tests/feature/
git commit -m "test: add tests for feature"
```

## Commit Templates

### Setup

```bash
# Create template file
cat > ~/.gitmessage << 'EOF'
# <type>(<scope>): <subject>
# |<----  Using a Maximum Of 50 Characters  ---->|

# Explain why this change is being made
# |<----   Try To Limit Each Line to a Maximum Of 72 Characters   ---->|

# Provide links or keys to any relevant tickets, articles or other resources
# Example: Fixes #23

# --- COMMIT END ---
# Type can be:
#   feat     (new feature)
#   fix      (bug fix)
#   docs     (changes to documentation)
#   style    (formatting, missing semi colons, etc; no code change)
#   refactor (refactoring production code)
#   test     (adding missing tests, refactoring tests; no production code change)
#   chore    (updating grunt tasks etc; no production code change)
#   perf     (performance improvements)
#   ci       (CI configuration)
#   build    (build system changes)
# --------------------
EOF

# Configure git to use template
git config --global commit.template ~/.gitmessage
```

### Project-Specific Template

```bash
# .gitmessage in project root
# <type>(<scope>): <subject>

# Body: Explain the motivation for the change

# Footer:
# Fixes #issue
# BREAKING CHANGE: description

# ---
# Remember:
# - Use present tense ("add" not "added")
# - Use imperative mood ("move" not "moves")
# - First line max 50 chars, body wrap at 72
# - Reference issues and PRs at the bottom
```

## Commit Message Validation

### Git Hook (commit-msg)

```bash
#!/bin/bash
# .git/hooks/commit-msg

commit_msg_file=$1
commit_msg=$(cat "$commit_msg_file")

# Skip merge commits
if echo "$commit_msg" | grep -qE "^Merge"; then
    exit 0
fi

# Conventional commit pattern
pattern="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9-]+\))?(!)?: .{1,50}"

if ! echo "$commit_msg" | head -1 | grep -qE "$pattern"; then
    echo "ERROR: Invalid commit message format"
    echo ""
    echo "Expected: <type>(<scope>): <subject>"
    echo "  type:    feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert"
    echo "  scope:   optional, lowercase with hyphens"
    echo "  subject: max 50 chars, imperative mood"
    echo ""
    echo "Your message:"
    echo "  $(head -1 "$commit_msg_file")"
    exit 1
fi

# Check subject line length
subject=$(echo "$commit_msg" | head -1)
if [ ${#subject} -gt 72 ]; then
    echo "ERROR: Subject line too long (${#subject} > 72 chars)"
    exit 1
fi

# Check for trailing period
if echo "$subject" | grep -qE "\.$"; then
    echo "ERROR: Subject line should not end with a period"
    exit 1
fi

exit 0
```

### commitlint Configuration

```javascript
// commitlint.config.js
module.exports = {
    extends: ['@commitlint/config-conventional'],
    rules: {
        'type-enum': [2, 'always', [
            'feat', 'fix', 'docs', 'style', 'refactor',
            'perf', 'test', 'build', 'ci', 'chore', 'revert'
        ]],
        'scope-case': [2, 'always', 'kebab-case'],
        'subject-case': [2, 'always', 'lower-case'],
        'subject-max-length': [2, 'always', 72],
        'body-max-line-length': [2, 'always', 100],
    },
};
```

```json
// package.json
{
    "husky": {
        "hooks": {
            "commit-msg": "commitlint -E HUSKY_GIT_PARAMS"
        }
    }
}
```

## Semantic Release Integration

### Configuration

```json
// .releaserc
{
    "branches": ["main"],
    "plugins": [
        ["@semantic-release/commit-analyzer", {
            "preset": "conventionalcommits",
            "releaseRules": [
                {"type": "feat", "release": "minor"},
                {"type": "fix", "release": "patch"},
                {"type": "perf", "release": "patch"},
                {"type": "revert", "release": "patch"},
                {"breaking": true, "release": "major"}
            ]
        }],
        ["@semantic-release/release-notes-generator", {
            "preset": "conventionalcommits"
        }],
        "@semantic-release/changelog",
        "@semantic-release/npm",
        "@semantic-release/github"
    ]
}
```

### Version Bumping

```bash
# These commits determine version bumps:

# PATCH (1.0.x)
fix: correct typo in error message
perf: optimize database query

# MINOR (1.x.0)
feat: add user profile page
feat(api): implement caching layer

# MAJOR (x.0.0)
feat!: redesign authentication system
fix!: change API response format

BREAKING CHANGE: Response format changed from XML to JSON
```

## Rewriting History

### Amending Commits

```bash
# Fix last commit message
git commit --amend -m "feat: correct commit message"

# Add files to last commit
git add forgotten-file.js
git commit --amend --no-edit

# Change author
git commit --amend --author="Name <email@example.com>"
```

### Interactive Rebase

```bash
# Rewrite last 5 commits
git rebase -i HEAD~5

# Commands in editor:
# pick   - use commit
# reword - edit message
# edit   - stop and amend
# squash - combine with previous
# fixup  - combine, discard message
# drop   - remove commit

# Example: Squash fixup commits
pick abc1234 feat: add user API
fixup def5678 fixup! feat: add user API
pick ghi9012 feat: add admin API
```

### Fixup Commits

```bash
# Create fixup commit
git add .
git commit --fixup=abc1234

# Auto-squash during rebase
git rebase -i --autosquash main
```

## Best Practices Summary

1. **Write meaningful messages**: Future you will thank present you
2. **Use conventional commits**: Enable automated versioning
3. **Keep commits atomic**: One logical change per commit
4. **Reference issues**: Link commits to project management
5. **Use scopes consistently**: Help with changelog generation
6. **Don't include generated files**: Keep commits focused on source changes
7. **Sign commits** (optional): Verify authorship with GPG
