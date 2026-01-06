# Advanced Git Operations

## Rewriting History

### Interactive Rebase

```bash
# Rebase last N commits
git rebase -i HEAD~5

# Rebase from a specific commit
git rebase -i abc1234^

# Commands available:
# p, pick   - use commit
# r, reword - edit commit message
# e, edit   - stop for amending
# s, squash - combine with previous (keep message)
# f, fixup  - combine with previous (discard message)
# d, drop   - remove commit
# x, exec   - run shell command
```

### Squashing Commits

```bash
# Squash last 3 commits
git rebase -i HEAD~3
# Change 'pick' to 'squash' for commits to combine

# Squash into a specific commit
git rebase -i <commit-before-first-to-squash>^

# Auto-squash fixup commits
git commit --fixup=<commit-hash>
git rebase -i --autosquash main
```

### Splitting Commits

```bash
# Start interactive rebase
git rebase -i HEAD~3

# Mark commit to split with 'edit'
# When stopped at that commit:
git reset HEAD^
git add file1.js
git commit -m "feat: first change"
git add file2.js
git commit -m "feat: second change"
git rebase --continue
```

### Reordering Commits

```bash
# Interactive rebase
git rebase -i HEAD~5

# In editor, reorder lines to reorder commits
# Example:
# pick abc1234 feat: feature A
# pick def5678 feat: feature B
# Changes to:
# pick def5678 feat: feature B
# pick abc1234 feat: feature A
```

## Cherry-Picking

### Basic Cherry-Pick

```bash
# Pick a single commit
git cherry-pick abc1234

# Pick multiple commits
git cherry-pick abc1234 def5678 ghi9012

# Pick a range
git cherry-pick abc1234^..def5678

# Cherry-pick without committing
git cherry-pick -n abc1234
```

### Cherry-Pick Options

```bash
# Keep original author
git cherry-pick -x abc1234

# Sign off
git cherry-pick -s abc1234

# Edit commit message
git cherry-pick -e abc1234

# Continue after conflict
git cherry-pick --continue

# Abort cherry-pick
git cherry-pick --abort
```

### Cherry-Pick Workflow

```bash
# Backport fix to release branch
git checkout release/1.0
git cherry-pick abc1234  # Fix from main
git push origin release/1.0

# Apply multiple fixes
git cherry-pick abc1234 def5678
# Or create a cherry-pick branch
git checkout -b cherry-pick-fixes release/1.0
git cherry-pick abc1234 def5678
git checkout release/1.0
git merge --no-ff cherry-pick-fixes
```

## Stashing

### Basic Stash Operations

```bash
# Stash current changes
git stash

# Stash with message
git stash save "Work in progress on feature X"

# List stashes
git stash list

# Apply latest stash (keep in stash list)
git stash apply

# Apply and remove from stash list
git stash pop

# Apply specific stash
git stash apply stash@{2}

# Drop a stash
git stash drop stash@{1}

# Clear all stashes
git stash clear
```

### Advanced Stashing

```bash
# Stash including untracked files
git stash -u

# Stash including ignored files
git stash -a

# Stash specific files
git stash push -m "message" file1.js file2.js

# Create branch from stash
git stash branch new-branch stash@{0}

# Show stash contents
git stash show stash@{0}
git stash show -p stash@{0}  # With diff

# Partial stash (interactive)
git stash -p
```

## Bisecting

### Finding Bug Introduction

```bash
# Start bisect
git bisect start

# Mark current as bad
git bisect bad

# Mark known good commit
git bisect good v1.0.0

# Git will checkout middle commit
# Test, then mark:
git bisect good  # If bug not present
git bisect bad   # If bug present

# Continue until found
# Git reports: "abc1234 is the first bad commit"

# End bisect
git bisect reset
```

### Automated Bisect

```bash
# Run script at each step
git bisect start HEAD v1.0.0
git bisect run npm test

# With custom script
git bisect run ./test-for-bug.sh

# Exit codes:
# 0     - good
# 1-124 - bad
# 125   - skip (can't test this commit)
# 126+  - abort bisect
```

### Bisect Log

```bash
# Show bisect log
git bisect log

# Save bisect log
git bisect log > bisect.log

# Replay bisect
git bisect replay bisect.log
```

## Reflog

### Understanding Reflog

```bash
# Show reflog
git reflog

# Show reflog for specific ref
git reflog show main
git reflog show HEAD

# Output:
# abc1234 HEAD@{0}: commit: feat: add feature
# def5678 HEAD@{1}: checkout: moving from main to feature
# ghi9012 HEAD@{2}: commit: fix: bug fix
```

### Recovering Lost Commits

```bash
# Find lost commit in reflog
git reflog

# Recover commit
git checkout abc1234
git checkout -b recovered-branch

# Or cherry-pick
git cherry-pick abc1234

# Recover after bad reset
git reflog
git reset --hard HEAD@{2}
```

### Reflog Expiration

```bash
# Default: 90 days for reachable, 30 for unreachable
git config gc.reflogExpire 90.days
git config gc.reflogExpireUnreachable 30.days

# Expire reflog manually
git reflog expire --expire=now --all
git gc --prune=now
```

## Worktrees

### Multiple Working Directories

```bash
# Add worktree
git worktree add ../project-feature feature-branch

# Add worktree with new branch
git worktree add -b new-feature ../project-new-feature main

# List worktrees
git worktree list

# Remove worktree
git worktree remove ../project-feature

# Prune stale worktree info
git worktree prune
```

### Use Cases

```bash
# Work on hotfix while keeping feature work
git worktree add ../project-hotfix hotfix/critical-bug
cd ../project-hotfix
# Fix bug
git commit -am "fix: critical bug"
cd ../project-main

# Review PR without stashing
git worktree add ../pr-review origin/feature-branch
cd ../pr-review
# Review code
```

## Submodules

### Adding Submodules

```bash
# Add submodule
git submodule add https://github.com/org/repo.git libs/repo

# Add at specific branch
git submodule add -b main https://github.com/org/repo.git libs/repo

# Initialize submodules after clone
git submodule init
git submodule update

# Clone with submodules
git clone --recurse-submodules https://github.com/org/main-repo.git
```

### Updating Submodules

```bash
# Update all submodules to latest
git submodule update --remote

# Update specific submodule
git submodule update --remote libs/repo

# Update and merge
git submodule update --remote --merge

# Pull in main repo and submodules
git pull --recurse-submodules
```

### Submodule Commands

```bash
# Run command in all submodules
git submodule foreach 'git pull origin main'

# Check status
git submodule status

# Remove submodule
git submodule deinit libs/repo
git rm libs/repo
rm -rf .git/modules/libs/repo
```

## Git Hooks

### Client-Side Hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash
npm run lint
npm run test

# .git/hooks/commit-msg
#!/bin/bash
# Validate commit message format

# .git/hooks/pre-push
#!/bin/bash
npm run test:e2e
```

### Server-Side Hooks

```bash
# hooks/pre-receive
#!/bin/bash
# Validate pushes before accepting

# hooks/post-receive
#!/bin/bash
# Deploy after push accepted

# hooks/update
#!/bin/bash
# Per-branch validation
```

### Hook Management with Husky

```json
// package.json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged",
      "commit-msg": "commitlint -E HUSKY_GIT_PARAMS",
      "pre-push": "npm test"
    }
  },
  "lint-staged": {
    "*.{js,ts}": ["eslint --fix", "prettier --write"]
  }
}
```

## Advanced Merging

### Merge Strategies

```bash
# Recursive (default)
git merge feature

# Ours (keep our changes)
git merge -s ours feature

# Subtree (merge into subdirectory)
git merge -s subtree --allow-unrelated-histories other-repo/main

# Octopus (merge multiple branches)
git merge feature1 feature2 feature3
```

### Merge Options

```bash
# No fast-forward
git merge --no-ff feature

# Squash merge
git merge --squash feature

# Merge with message
git merge -m "Merge feature X" feature

# Abort merge
git merge --abort
```

### Rerere (Reuse Recorded Resolution)

```bash
# Enable rerere
git config rerere.enabled true

# After resolving conflict, it's recorded
# Next time same conflict occurs, auto-resolved

# View recorded resolutions
git rerere status

# Forget resolution
git rerere forget path/to/file
```

## Git Attributes

### Line Endings

```bash
# .gitattributes
* text=auto
*.sh text eol=lf
*.bat text eol=crlf
*.png binary
```

### Diff and Merge

```bash
# .gitattributes
*.min.js binary
*.lock -diff
*.pdf diff=pdf

# Custom diff driver
[diff "pdf"]
  textconv = pdftotext -layout
```

### Export Ignore

```bash
# .gitattributes
.gitignore export-ignore
.github export-ignore
tests/ export-ignore
```

## Performance Optimization

### Large Repositories

```bash
# Shallow clone
git clone --depth 1 https://github.com/org/repo.git

# Sparse checkout
git clone --filter=blob:none --sparse https://github.com/org/repo.git
cd repo
git sparse-checkout set src/

# Partial clone
git clone --filter=blob:none https://github.com/org/repo.git
```

### Git LFS

```bash
# Install LFS
git lfs install

# Track large files
git lfs track "*.psd"
git lfs track "*.zip"

# View tracked patterns
git lfs track

# View LFS files
git lfs ls-files

# Pull LFS files
git lfs pull
```

### Repository Maintenance

```bash
# Garbage collection
git gc

# Aggressive gc
git gc --aggressive

# Prune unreachable objects
git prune

# Verify repository
git fsck

# Repack
git repack -a -d
```

## Troubleshooting

### Common Issues

```bash
# Fix "detached HEAD"
git checkout -b new-branch  # If you want to keep changes
git checkout main           # If you want to discard

# Fix "refusing to merge unrelated histories"
git merge --allow-unrelated-histories other-branch

# Fix corrupted repository
git fsck --full
git gc --prune=now

# Remove file from all history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/file' \
  --prune-empty --tag-name-filter cat -- --all
```

### Recovery Operations

```bash
# Recover deleted branch
git reflog
git checkout -b recovered abc1234

# Recover deleted file
git checkout HEAD~1 -- path/to/file

# Undo hard reset
git reflog
git reset --hard HEAD@{1}

# Recover stash
git fsck --unreachable | grep commit | cut -d' ' -f3 | \
  xargs git log --merges --no-walk --grep=WIP
```
