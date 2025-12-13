---
name: git-workflow
description: "Git workflow best practices for teams and CI/CD pipelines. This skill should be used when establishing branching strategies (Git Flow, GitHub Flow, Trunk-based), implementing Conventional Commits for semantic versioning, configuring pull request workflows, or integrating Git with CI/CD systems. Covers branch protection, code review processes, GitHub Actions, GitLab CI, and advanced Git operations. By Netresearch."
---

# Git Workflow Skill

Expert patterns for Git version control workflows including branching strategies, commit conventions, collaborative workflows, and CI/CD integration.

## Expertise Areas

### Branching Strategies
- Git Flow (feature/release/hotfix branches)
- GitHub Flow (simple feature branches)
- Trunk-based development
- Release management patterns

### Commit Conventions
- Conventional Commits standard
- Semantic versioning integration
- Commit message best practices
- Atomic commit patterns

### Collaborative Workflows
- Pull request best practices
- Code review processes
- Merge strategies (merge, squash, rebase)
- Conflict resolution patterns

### CI/CD Integration
- GitHub Actions workflows
- GitLab CI patterns
- Branch protection rules
- Automated versioning

## Reference Files

- `references/branching-strategies.md` - Branch management patterns
- `references/commit-conventions.md` - Commit message standards
- `references/pull-request-workflow.md` - PR and review processes
- `references/ci-cd-integration.md` - Automation patterns
- `references/advanced-git.md` - Advanced Git operations

## Core Patterns

### Conventional Commits

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature (MINOR version bump)
- `fix`: Bug fix (PATCH version bump)
- `docs`: Documentation only
- `style`: Code style (formatting, no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding/updating tests
- `build`: Build system changes
- `ci`: CI configuration changes
- `chore`: Maintenance tasks
- `revert`: Reverting changes

**Breaking Changes:**
```
feat!: remove deprecated API endpoints

BREAKING CHANGE: The /api/v1/users endpoint has been removed.
Use /api/v2/users instead.
```

### Branch Naming Convention

```bash
# Feature branches
feature/TICKET-123-add-user-authentication
feature/add-dark-mode

# Bug fix branches
fix/TICKET-456-login-redirect-loop
bugfix/memory-leak-in-cache

# Release branches
release/1.2.0
release/v2.0.0-beta.1

# Hotfix branches
hotfix/1.2.1-security-patch
hotfix/critical-payment-bug
```

### Git Flow Commands

```bash
# Initialize Git Flow
git flow init

# Feature workflow
git flow feature start user-authentication
# ... work on feature ...
git flow feature finish user-authentication

# Release workflow
git flow release start 1.2.0
# ... final testing, version bumps ...
git flow release finish 1.2.0

# Hotfix workflow
git flow hotfix start 1.2.1
# ... fix critical bug ...
git flow hotfix finish 1.2.1
```

### GitHub Flow (Simplified)

```bash
# 1. Create feature branch from main
git checkout main
git pull origin main
git checkout -b feature/new-feature

# 2. Work on feature with regular commits
git add .
git commit -m "feat: implement user profile page"

# 3. Push and create PR
git push -u origin feature/new-feature
gh pr create --title "feat: implement user profile page" --body "..."

# 4. After review and CI passes, merge
gh pr merge --squash

# 5. Clean up
git checkout main
git pull origin main
git branch -d feature/new-feature
```

### Useful Git Aliases

```bash
# ~/.gitconfig
[alias]
    # Status and logs
    st = status -sb
    lg = log --oneline --graph --decorate -20
    lga = log --oneline --graph --decorate --all
    last = log -1 HEAD --stat

    # Branch management
    br = branch -vv
    brd = branch -d
    brD = branch -D
    co = checkout
    cob = checkout -b

    # Commit shortcuts
    cm = commit -m
    ca = commit --amend
    can = commit --amend --no-edit

    # Diff shortcuts
    df = diff
    dfs = diff --staged
    dfw = diff --word-diff

    # Stash shortcuts
    ss = stash save
    sp = stash pop
    sl = stash list

    # Reset shortcuts
    unstage = reset HEAD --
    undo = reset --soft HEAD~1

    # Rebase shortcuts
    rb = rebase
    rbi = rebase -i
    rbc = rebase --continue
    rba = rebase --abort

    # Pull/push shortcuts
    pl = pull --rebase
    pf = push --force-with-lease
    pu = push -u origin HEAD

    # Cleanup
    cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d"
```

### Pre-commit Hook Example

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run linting
echo "Running linter..."
npm run lint
if [ $? -ne 0 ]; then
    echo "Linting failed. Please fix errors before committing."
    exit 1
fi

# Run tests
echo "Running tests..."
npm run test
if [ $? -ne 0 ]; then
    echo "Tests failed. Please fix failing tests before committing."
    exit 1
fi

# Check for debug statements
if git diff --cached --name-only | xargs grep -l "console.log\|debugger\|var_dump\|dd(" 2>/dev/null; then
    echo "Warning: Debug statements found. Remove before committing."
    exit 1
fi

echo "Pre-commit checks passed!"
exit 0
```

### Commit Message Hook

```bash
#!/bin/bash
# .git/hooks/commit-msg

commit_msg=$(cat "$1")

# Conventional commit pattern
pattern="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?(!)?: .{1,72}"

if ! echo "$commit_msg" | grep -qE "$pattern"; then
    echo "Invalid commit message format!"
    echo ""
    echo "Expected format: <type>[optional scope]: <description>"
    echo ""
    echo "Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"
    echo ""
    echo "Examples:"
    echo "  feat: add user authentication"
    echo "  fix(auth): resolve login redirect loop"
    echo "  feat!: remove deprecated API"
    exit 1
fi

exit 0
```

### GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  lint-and-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Test
        run: npm run test

      - name: Build
        run: npm run build

  release:
    needs: lint-and-test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Semantic Release
        uses: cycjimmy/semantic-release-action@v4
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## Verification

Run the verification script:

```bash
./scripts/verify-git-workflow.sh /path/to/repository
```

## Quick Reference

### Daily Workflow

```bash
# Start of day
git checkout main && git pull
git checkout -b feature/my-feature

# During development
git add -p                    # Stage hunks interactively
git commit -m "feat: ..."     # Commit with conventional message

# Ready for review
git push -u origin HEAD
gh pr create

# After merge
git checkout main && git pull
git branch -d feature/my-feature
```

### Emergency Fixes

```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Revert a specific commit
git revert <commit-hash>

# Fix last commit message
git commit --amend -m "new message"

# Fix last commit (add forgotten file)
git add forgotten-file.txt
git commit --amend --no-edit
```

### Conflict Resolution

```bash
# During merge/rebase conflict
git status                    # See conflicting files
# Edit files to resolve conflicts
git add <resolved-file>
git rebase --continue         # Or: git merge --continue

# Abort if needed
git rebase --abort            # Or: git merge --abort
```

## Related Skills

- **enterprise-readiness-skill**: Git workflow is part of CI/CD maturity
- **security-audit-skill**: Git hooks for security checks
