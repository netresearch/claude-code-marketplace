# Pull Request Workflow

## PR Best Practices

### Size Guidelines

| Size | Lines Changed | Review Time | Defect Risk |
|------|--------------|-------------|-------------|
| XS | 0-10 | < 5 min | Very Low |
| S | 11-100 | 15-30 min | Low |
| M | 101-400 | 30-60 min | Medium |
| L | 401-1000 | 1-2 hours | High |
| XL | 1000+ | Multiple sessions | Very High |

**Target**: Keep PRs under 400 lines when possible.

### PR Structure

```markdown
## Summary
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)

## Changes Made
- Added user authentication service
- Implemented JWT token generation
- Added login/logout endpoints

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Screenshots (if applicable)
[Before/After screenshots for UI changes]

## Related Issues
Fixes #123
Related to #456

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review performed
- [ ] Documentation updated
- [ ] No new warnings introduced
- [ ] Tests pass locally
```

## Creating PRs

### GitHub CLI

```bash
# Create PR with title and body
gh pr create \
  --title "feat(auth): add user authentication" \
  --body "## Summary
Implements JWT-based authentication.

## Changes
- Add AuthService
- Add login/logout endpoints
- Add auth middleware

Fixes #123"

# Create draft PR
gh pr create --draft

# Create PR and assign reviewers
gh pr create \
  --title "fix: resolve memory leak" \
  --reviewer "@team-lead,@senior-dev" \
  --assignee "@me"

# Create PR from template
gh pr create --template .github/PULL_REQUEST_TEMPLATE.md
```

### PR Templates

```markdown
<!-- .github/PULL_REQUEST_TEMPLATE.md -->
## Description
<!-- Describe your changes in detail -->

## Motivation and Context
<!-- Why is this change required? What problem does it solve? -->

## How Has This Been Tested?
<!-- Describe how you tested your changes -->

## Types of Changes
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation

## Checklist
- [ ] My code follows the code style of this project
- [ ] I have updated the documentation accordingly
- [ ] I have added tests to cover my changes
- [ ] All new and existing tests passed
```

### Multiple Templates

```
.github/
├── PULL_REQUEST_TEMPLATE.md          # Default
└── PULL_REQUEST_TEMPLATE/
    ├── feature.md
    ├── bugfix.md
    └── documentation.md
```

## Code Review Process

### Reviewer Responsibilities

1. **Code Quality**
   - Readability and maintainability
   - Adherence to coding standards
   - Appropriate error handling

2. **Functionality**
   - Logic correctness
   - Edge cases handled
   - Requirements met

3. **Testing**
   - Test coverage adequate
   - Tests meaningful and correct
   - Edge cases tested

4. **Security**
   - No obvious vulnerabilities
   - Sensitive data handling
   - Input validation

5. **Performance**
   - No obvious bottlenecks
   - Resource usage appropriate
   - Scaling considerations

### Review Comments

```markdown
# Levels of feedback

# 🔴 Blocking - Must be addressed
This introduces a security vulnerability. User input is not sanitized
before being used in the SQL query.

# 🟡 Suggestion - Should consider
Consider extracting this logic into a separate function for reusability
and testing.

# 🟢 Nit - Minor issue
Nit: This variable name could be more descriptive.
`data` → `userProfileData`

# 💡 Question - Seeking understanding
Question: What's the reasoning behind using a Map here instead of an Object?

# 👍 Praise - Positive feedback
Nice catch handling the edge case where the array might be empty!
```

### Review Checklist

```markdown
## Code Review Checklist

### Code Quality
- [ ] Code is readable and self-documenting
- [ ] No unnecessary complexity
- [ ] DRY principle followed
- [ ] SOLID principles followed

### Testing
- [ ] Unit tests present and passing
- [ ] Edge cases covered
- [ ] Integration tests if needed
- [ ] No flaky tests introduced

### Security
- [ ] No hardcoded credentials
- [ ] Input validation present
- [ ] No SQL injection risks
- [ ] No XSS vulnerabilities

### Performance
- [ ] No N+1 queries
- [ ] Appropriate data structures used
- [ ] No memory leaks
- [ ] Caching considered

### Documentation
- [ ] README updated if needed
- [ ] API documentation updated
- [ ] Comments for complex logic
- [ ] CHANGELOG entry added
```

## Merge Strategies

### Merge Commit

```bash
# Creates a merge commit, preserves all history
git checkout main
git merge --no-ff feature/my-feature

# Result:
#   * Merge branch 'feature/my-feature'
#   |\
#   | * feat: add feature part 2
#   | * feat: add feature part 1
#   |/
#   * Previous main commit
```

**Use when:**
- Want to preserve complete branch history
- Complex features with meaningful intermediate commits
- Audit trail required

### Squash and Merge

```bash
# Combines all commits into one
git checkout main
git merge --squash feature/my-feature
git commit -m "feat: complete feature implementation"

# Result:
#   * feat: complete feature implementation
#   * Previous main commit
```

**Use when:**
- Feature branch has messy history
- WIP commits, fixups, "oops" commits
- Want clean linear history

### Rebase and Merge

```bash
# Replays commits on top of main
git checkout feature/my-feature
git rebase main
git checkout main
git merge --ff-only feature/my-feature

# Result:
#   * feat: add feature part 2
#   * feat: add feature part 1
#   * Previous main commit
```

**Use when:**
- Clean commit history in feature branch
- Each commit is meaningful and tested
- Want linear history without merge commits

### Comparison

| Strategy | History | Complexity | Traceability |
|----------|---------|------------|--------------|
| Merge | Preserved | High | High |
| Squash | Combined | Low | Medium |
| Rebase | Linear | Low | Medium |

## Automated Checks

### GitHub Actions for PRs

```yaml
# .github/workflows/pr-checks.yml
name: PR Checks

on:
  pull_request:
    branches: [main, develop]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm test -- --coverage

  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run build

  pr-size:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Check PR size
        run: |
          ADDITIONS=$(gh pr view ${{ github.event.pull_request.number }} --json additions -q '.additions')
          if [ "$ADDITIONS" -gt 1000 ]; then
            echo "::warning::Large PR detected ($ADDITIONS lines). Consider splitting."
          fi
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Required Status Checks

```yaml
# Branch protection settings
required_status_checks:
  strict: true
  contexts:
    - lint
    - test
    - build
    - security-scan
```

### CODEOWNERS

```bash
# .github/CODEOWNERS

# Default owners for everything
* @default-team

# Frontend owners
/src/components/ @frontend-team
/src/styles/ @frontend-team @design-team

# Backend owners
/src/api/ @backend-team
/src/database/ @backend-team @dba-team

# DevOps owners
/.github/ @devops-team
/docker/ @devops-team
/terraform/ @devops-team

# Documentation
/docs/ @docs-team
*.md @docs-team

# Security-sensitive files
/src/auth/ @security-team @backend-team
/src/crypto/ @security-team
```

## PR Lifecycle

### States

```
Draft → Ready for Review → Changes Requested → Approved → Merged
         ↑_____________________|
```

### Commands

```bash
# Check PR status
gh pr status
gh pr view 123

# Request review
gh pr edit 123 --add-reviewer "@reviewer1,@reviewer2"

# Mark ready for review
gh pr ready 123

# Convert to draft
gh pr ready 123 --undo

# Approve PR
gh pr review 123 --approve

# Request changes
gh pr review 123 --request-changes --body "Please fix X"

# Merge PR
gh pr merge 123 --squash --delete-branch

# Close without merging
gh pr close 123
```

### Handling Stale PRs

```yaml
# .github/workflows/stale.yml
name: Mark Stale PRs

on:
  schedule:
    - cron: '0 0 * * *'  # Daily

jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v9
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          stale-pr-message: 'This PR has been inactive for 14 days. Please update or close.'
          days-before-stale: 14
          days-before-close: 7
          stale-pr-label: 'stale'
```

## Conflict Resolution

### Before Merging

```bash
# Update feature branch with latest main
git checkout feature/my-feature
git fetch origin
git rebase origin/main

# If conflicts occur
# 1. Edit conflicting files
# 2. Stage resolved files
git add <resolved-file>
# 3. Continue rebase
git rebase --continue

# Force push (only on feature branches!)
git push --force-with-lease
```

### Merge Conflicts in PR

```bash
# Option 1: Rebase (preferred for clean history)
git checkout feature/my-feature
git fetch origin
git rebase origin/main
# Resolve conflicts
git push --force-with-lease

# Option 2: Merge main into feature
git checkout feature/my-feature
git merge origin/main
# Resolve conflicts
git commit
git push
```

### Complex Conflicts

```bash
# Use a merge tool
git mergetool

# Or use specific tool
git mergetool --tool=vscode
git mergetool --tool=meld

# Configure default tool
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'
```

## PR Analytics

### Metrics to Track

1. **PR Size**: Average lines changed
2. **Review Time**: Time from creation to first review
3. **Time to Merge**: Creation to merge
4. **Review Rounds**: Number of change requests
5. **Throughput**: PRs merged per week

### GitHub Insights

```bash
# List PR stats
gh pr list --state merged --json number,title,createdAt,mergedAt,additions,deletions

# PR age analysis
gh pr list --state open --json number,createdAt | jq 'map({number, age: (now - (.createdAt | fromdateiso8601)) / 86400})'
```
