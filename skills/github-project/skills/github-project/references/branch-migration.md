# Branch Migration Reference

Guide for migrating from `master` to `main` as default branch.

## Migration Steps

### Step 1: Rename locally and push
```bash
# Rename local branch
git branch -m master main

# Push new branch to remote
git push -u origin main
```

### Step 2: Update GitHub default branch
```bash
# Set main as default (via API)
gh api repos/{owner}/{repo} --method PATCH -f default_branch=main

# Or via gh repo edit
gh repo edit --default-branch main
```

### Step 3: Update branch protection
```bash
# Copy protection rules from master to main (if any existed)
# Then delete master protection
gh api repos/{owner}/{repo}/branches/master/protection --method DELETE 2>/dev/null || true

# Set up protection on main (see Branch Protection Configuration in SKILL.md)
```

### Step 4: Delete old master branch
```bash
# Delete remote master
git push origin --delete master
```

### Step 5: Prevent master from being re-created

Create a branch protection rule for `master` that blocks all pushes:

```bash
# Create restrictive rule for "master" branch name
gh api repos/{owner}/{repo}/branches/master/protection \
  --method PUT \
  -f required_status_checks=null \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"required_approving_review_count":6,"dismiss_stale_reviews":true}' \
  -f restrictions='{"users":[],"teams":[]}' \
  -f allow_force_pushes=false \
  -f allow_deletions=false
```

This creates a "ghost" protection rule that:
- Requires 6 approvals (effectively blocking all PRs)
- Restricts pushes to nobody
- Prevents the branch from being created

### Step 6: Update CI/CD workflows
```bash
# Find and update workflow files
grep -rl "master" .github/workflows/ | xargs sed -i 's/master/main/g'

# Common patterns to update:
# - branches: [master] → branches: [main]
# - on: push: branches: master → main
# - refs/heads/master → refs/heads/main
```

### Step 7: Update documentation

Search and replace branch references:
```bash
# Find all references to master branch in docs
grep -rn "master" --include="*.md" --include="*.rst" --include="*.txt"
```

| File | Pattern | Update to |
|------|---------|-----------|
| README.md | `badge/branch-master` | `badge/branch-main` |
| README.md | `github.com/org/repo/tree/master` | `tree/main` |
| README.md | `github.com/org/repo/blob/master` | `blob/main` |
| README.md | `?branch=master` | `?branch=main` |
| CONTRIBUTING.md | "merge into master" | "merge into main" |
| docs/*.md | `/master/` links | `/main/` |
| package.json | `"repository": "...#master"` | `#main` |
| composer.json | `"dev-master"` or `#master` | `"dev-main"` or `#main` |

```bash
# Bulk update in markdown files
find . -name "*.md" -exec sed -i 's|/master/|/main/|g; s|/master"|/main"|g; s|branch-master|branch-main|g' {} \;
```

### Step 8: Notify team

Team members must update local repos:
```bash
git checkout master
git branch -m master main
git fetch origin
git branch -u origin/main main
git remote set-head origin -a
```
