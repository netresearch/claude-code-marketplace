# TYPO3 Gerrit Workflow Guide

Comprehensive guide for working with Gerrit code review system in TYPO3 Core contributions.

## What is Gerrit?

Gerrit is a web-based code review tool that TYPO3 uses for managing patch submissions. Every code change must go through Gerrit review before being merged into TYPO3 Core.

**Key Concepts**:
- **Patch/Change**: Single commit representing your contribution
- **Patchset**: Version of a patch (same Change-Id, updated code)
- **Review**: Process of evaluating code quality and correctness
- **Merge**: Final acceptance of patch into TYPO3 Core

## Accessing Gerrit

**URL**: https://review.typo3.org

**Authentication**: Use TYPO3.org account credentials

**Search Tool**: https://forger.typo3.com (easier searching)

## Submitting Your First Patch

### Prerequisites

- Git configured for TYPO3 (see Environment Setup)
- SSH keys added to Gerrit
- Commit ready with proper message format
- All changes in single commit

### Push to Gerrit

```bash
# From your feature branch
git push origin HEAD:refs/for/main
```

**What happens**:
1. Git pushes to special Gerrit ref: `refs/for/main`
2. Gerrit creates new review
3. You receive SUCCESS message with review URL

**Expected Output**:
```
remote: Processing changes: new: 1, done
remote:
remote: SUCCESS
remote:
remote:   https://review.typo3.org/c/Packages/TYPO3.CMS/+/12345 [NEW]
remote:
To ssh://review.typo3.org:29418/Packages/TYPO3.CMS.git
 * [new branch]      HEAD -> refs/for/main
```

**Save the review URL!** You'll need it to monitor progress.

### Alternative Push Methods

If you've configured default push settings:

```bash
# Simple push (if remote.origin.push configured)
git push
```

## Continuous Integration

After submission, Gerrit automatically runs tests:

1. **GitLab CI** triggers test pipeline
2. Tests run across multiple PHP versions, code style checks, static analysis (PHPStan), and unit/functional tests
3. Results appear on Gerrit review page
4. Usually completes in 10-20 minutes

**Status Indicators**:
- ✅ Green checkmark: All tests passed
- ❌ Red X: Tests failed
- ⏳ Clock: Tests running

### IMPORTANT: New Patches Start in "Work in Progress" State

**By default, newly submitted patches are marked as WIP (Work in Progress)**. This means:

1. ⚠️ **Not visible to reviewers** - Core team won't see your patch for review
2. ✅ **CI tests still run** - You get test feedback immediately
3. 🔍 **You must verify yourself first** - Check all CI jobs before requesting review
4. ✅ **You must manually mark as ready** - Change state to "Ready for Review" when done

**Workflow for New Submissions**:

```bash
# 1. Push your patch
git push origin HEAD:refs/for/main

# 2. Note the review URL from output
# https://review.typo3.org/c/Packages/TYPO3.CMS/+/12345 [WIP]

# 3. Wait for CI to complete (10-20 minutes)

# 4. CHECK ALL FAILING JOBS (critical step!)
# - Open the review URL
# - Look for any CI failures (red X marks)
# - For each failure, find the GitLab job URL
# - Read the ACTUAL ERROR LOGS (don't guess!)
# - Fix ALL issues before marking ready

# 5. Once all tests pass, mark as ready for review
#
# Option A: Remove WIP via command line (empty push)
git commit --amend --allow-empty --no-edit
git push origin HEAD:refs/for/main%ready

# Option B: Remove WIP via web UI
# a. Open review URL: https://review.typo3.org/c/Packages/TYPO3.CMS/+/XXXXX
# b. Click "Start Review" button (top right area, near your avatar)
#
# Notes:
# - %ready flag removes WIP state (even with empty pushes)
# - %wip flag sets WIP state: git push origin HEAD:refs/for/main%wip
# - SSH 'gerrit review' command does NOT support WIP flags (use git push flags instead)
```

### Investigating CI Failures (CRITICAL!)

**NEVER assume what failed - ALWAYS check the actual job logs!**

#### Step 1: Find All Failing Jobs

On your Gerrit review page:
1. Scroll to the CI results section
2. Look for red ❌ marks next to job names
3. Note ALL failing job names (there might be multiple!)

Common failing jobs:
- `cgl pre-merge` - Code style violations (PHP CS Fixer)
- `phpstan php X.X pre-merge` - Static analysis errors
- `unit php X.X pre-merge` - Unit test failures
- `functional php X.X pre-merge` - Functional test failures

#### Step 2: Access GitLab Job Logs

For each failing job:
1. Click on the failing job name in Gerrit
2. You'll be redirected to GitLab CI (https://git.typo3.org/typo3/CI/cms/-/jobs/XXXXXX)
3. Click the job log or raw log to see the actual error

**Example**: If job #4896429 failed:
- URL: `https://git.typo3.org/typo3/CI/cms/-/jobs/4896429`
- Raw log: `https://git.typo3.org/typo3/CI/cms/-/jobs/4896429/raw`

#### Step 3: Read and Understand ACTUAL Errors

**DO NOT GUESS!** Read the actual error messages:

**Code Style (cgl) Example**:
```
Fixed 1 of 1 files in ... seconds.

Checked 1 of 1 files in ... seconds.
   1) typo3/sysext/indexed_search/Tests/Unit/IndexerTest.php (single_quote)
      ---------- begin diff ----------
-            body: "This content should not appear"
+            body: 'This content should not appear'
      ----------- end diff -----------
```
**Fix**: Change double quotes to single quotes in test file.

**PHPStan Example**:
```
------ -------------------------------------------------------------------------
 Line   indexed_search/Tests/Unit/IndexerTest.php
------ -------------------------------------------------------------------------
 236    Call to static method PHPUnit\Framework\Assert::assertNotNull()
        with string will always evaluate to true.
------ -------------------------------------------------------------------------
```
**Fix**: Remove `assertNotNull()` call - it's redundant for string return types.

**Unit Test Failure Example**:
```
FAILURES!
Tests: 11683, Assertions: 20300, Failures: 1.

There was 1 failure:

1) TYPO3\CMS\IndexedSearch\Tests\Unit\IndexerTest::bodyDescriptionReturnsEmptyStringWhenMaxLengthIsZero
Failed asserting that two strings are equal.
--- Expected
+++ Actual
@@ @@
-''
+'This content should not appear in description'
```
**Fix**: Test logic is wrong - review the test expectations.

#### Step 4: Fix ALL Issues

⚠️ **CRITICAL**: A CI pipeline may have multiple failing jobs. Fix ALL of them:

```bash
# Example: 5 jobs failed (cgl, phpstan, 3x unit tests)
# You must fix:
# 1. Code style issues (single quotes)
# 2. PHPStan warnings (remove redundant assertions)
# 3. Unit test failures (fix test logic)

# Make all fixes
vim typo3/sysext/indexed_search/Tests/Unit/IndexerTest.php

# Stage changes
git add typo3/sysext/indexed_search/Tests/Unit/IndexerTest.php

# Amend commit
git commit --amend --no-edit

# Push updated patchset
git push origin HEAD:refs/for/main
```

#### Step 5: Wait for Re-verification

After pushing fixes:
1. CI automatically runs again
2. Old failed votes (Verified-1) are removed
3. Wait for all jobs to complete
4. Verify ALL jobs are now passing (green ✅)

#### Step 6: Mark as Ready for Review

Once ALL CI jobs pass:
1. Open your review on Gerrit
2. Click **"More"** → **"Start Review"**
3. Optionally add a comment: "Ready for review. All CI checks passing."
4. Your patch is now visible to core team reviewers

### Common CI Failure Patterns

| Job Type | Common Issues | Where to Look |
|----------|---------------|---------------|
| cgl (Code Style) | Double quotes, spacing, indentation | PHP CS Fixer diff in log |
| phpstan | Type errors, redundant code, undefined vars | Line numbers + error descriptions |
| unit tests | Test failures, assertion mismatches | Test name + expected vs actual |
| functional tests | Database issues, integration problems | Full stack trace in log |

**If tests fail**:
1. ⚠️ **DO NOT GUESS** - Always read actual job logs
2. Check ALL failing jobs, not just the first one
3. Access GitLab CI job logs via links on Gerrit
4. Fix all issues in one patchset
5. Push updated patchset (next section)
6. Wait for re-verification
7. Mark as ready only when ALL jobs pass

## Updating Your Patch

When reviewers request changes or tests fail:

### Step 1: Make Changes Locally

```bash
# Make code changes
vim path/to/file.php

# Stage changes
git add path/to/file.php
```

### Step 2: Amend Commit

```bash
# Amend existing commit (DO NOT create new commit!)
git commit --amend

# CRITICAL: Keep the Change-Id line unchanged!
```

### Step 3: Push Updated Patchset

```bash
# Push to same Gerrit change
git push origin HEAD:refs/for/main
```

**What happens**:
- Gerrit matches Change-Id
- Creates new patchset (Patch Set 2, 3, etc.)
- Previous patchsets remain for comparison
- CI tests run again

**Patchset Versioning**:
- Patch Set 1: Initial submission
- Patch Set 2: First update
- Patch Set 3: Second update
- etc.

## Rebasing Your Patch

### Why Rebase?

While you're working, other contributors' patches get merged. Your patch becomes based on outdated code. Rebasing updates your patch to build on the latest codebase.

### When to Rebase

- Merge conflict indicator appears on Gerrit
- Regularly during development (best practice)
- Before running tests
- When requested by reviewers

### Method 1: Browser-Based Rebase (Easiest)

**Requirements**: No merge conflicts

**Steps**:
1. Open your patch on Gerrit
2. Click **Rebase** button (top right)
3. Select "Rebase on top of the main branch"
4. Click **Rebase**

Gerrit automatically:
- Rebases your change
- Creates new patchset
- Runs CI tests

### Method 2: Command-Line Rebase

**When to use**: Merge conflicts exist, or prefer manual control

**Steps**:

```bash
# Ensure on your feature branch
git checkout feature/105737-fix-indexed-search

# Fetch latest changes
git fetch origin

# Rebase onto main
git rebase origin/main
```

**If no conflicts**:
```bash
# Push rebased patch
git push origin HEAD:refs/for/main
```

**If conflicts occur**: See Resolving Merge Conflicts section below.

### Alternative Rebase Methods

**Option A: Pull with Rebase**
```bash
git pull --rebase origin main
```

**Option B: Interactive Rebase** (advanced)
```bash
git rebase -i origin/main
```

## Resolving Merge Conflicts

### What Are Conflicts?

Conflicts occur when:
- You modified file X
- Someone else modified same lines in file X
- Their patch merged first
- Git can't auto-merge

### Conflict Resolution Process

#### Step 1: Start Rebase

```bash
git rebase origin/main
```

**Output with conflicts**:
```
CONFLICT (content): Merge conflict in path/to/file.php
error: could not apply abc123... Your commit message
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
```

#### Step 2: Identify Conflicted Files

```bash
git status
```

**Output**:
```
On branch feature/105737-fix-indexed-search
You are currently rebasing branch 'feature/105737-fix-indexed-search' on 'abc123'.
  (fix conflicts and then run "git rebase --continue")

Unmerged paths:
  (use "git add <file>..." to mark resolution)
        both modified:   path/to/file.php
```

#### Step 3: Resolve Conflicts

Open conflicted file in editor:

```php
<<<<<<< HEAD
// Code from main branch (their changes)
$result = newFunction($data);
=======
// Your changes
$result = oldFunction($data);
>>>>>>> Your commit message
```

**Choose resolution**:

**Option A: Keep their changes**
```php
$result = newFunction($data);
```

**Option B: Keep your changes**
```php
$result = oldFunction($data);
```

**Option C: Merge both** (most common)
```php
// Updated to use new function while preserving your logic
$result = newFunction($processedData);
```

Remove conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).

#### Step 4: Mark as Resolved

```bash
# Stage resolved files
git add path/to/file.php

# Check all conflicts resolved
git status
```

#### Step 5: Continue Rebase

```bash
git rebase --continue
```

If more conflicts exist, repeat steps 3-5.

#### Step 6: Push Rebased Patch

```bash
git push origin HEAD:refs/for/main
```

### Conflict Resolution Tips

**Understand Context**:
- Review their changes: `git show HEAD:path/to/file.php`
- Review your changes: `git show feature/105737-fix-indexed-search:path/to/file.php`
- Check file history: `git log -- path/to/file.php`

**Test After Resolution**:
```bash
# Run tests locally
composer test:unit
composer test:functional

# Check syntax
php -l path/to/file.php
```

**Ask for Help**:
- Post in #typo3-cms-coredev Slack
- Comment on Gerrit review
- Reference conflicting patch if known

### Aborting Rebase

If rebase goes wrong:

```bash
git rebase --abort
```

Returns to pre-rebase state. You can try again.

## Review Process

### Voting System

**Code Review** (CR):
- **+2**: Looks good, approved
- **+1**: Looks mostly good
- **0**: Neutral (default)
- **-1**: Needs improvement
- **-2**: Do not merge (veto)

**Verified** (V):
- **+1**: Tests passed
- **0**: Not yet tested
- **-1**: Tests failed

**Merge Requirements**:
- At least **+2 Code Review** from core team member
- At least **+1 Verified** (CI tests passed)
- No unresolved **-2** votes
- At least 2 reviewers involved (one must be core team)

### Typical Review Timeline

**Simple Bugfixes**: 1-3 days
**Medium Features**: 3-7 days
**Complex Features**: 1-2 weeks
**Breaking Changes**: 2-4 weeks (more scrutiny)

**Factors affecting timeline**:
- Code quality and completeness
- Test coverage
- Documentation
- Reviewer availability (volunteers!)
- Complexity and impact

### Responding to Review Comments

#### Step 1: Read Feedback Carefully

- Understand what's being requested
- Ask questions if unclear
- Check if feedback applies to multiple locations

#### Step 2: Implement Changes

```bash
# Make requested changes
vim path/to/file.php

# Stage and amend
git add path/to/file.php
git commit --amend

# Push update
git push origin HEAD:refs/for/main
```

#### Step 3: Respond on Gerrit

- Click **Reply** button
- Address each comment:
  - "Done" - Simple confirmation
  - "Fixed in PS3" - Reference patchset number
  - Explain your approach if different from suggestion
- Thank reviewers
- Click **Send**

#### Example Response

```
Thanks for the review!

> Line 45: Consider using dependency injection

Good point! I've refactored to use DI in PS3.

> Line 120: Add type hint

Added in PS3. Also added return type hints throughout.

> Missing tests for edge case

Added test case for empty string input in Tests/Unit/IndexerTest.php
```

### Getting More Reviews

**If no reviews after 3-4 days**:

1. **Advertise on Slack** (#typo3-cms-coredev):
   ```
   I've submitted a patch for #105737 (indexed search crash).
   Would appreciate reviews when you have time: https://review.typo3.org/c/Packages/TYPO3.CMS/+/12345
   ```

2. **Check patch quality**:
   - Tests passing?
   - Documentation complete?
   - Follows coding standards?
   - Clear commit message?

3. **Ask specific reviewers** (if appropriate):
   - Maintainers of affected area
   - Previous contributors to same files
   - Don't spam or DM randomly!

## Gerrit Interface Guide

### Review Page Sections

**Header**:
- Status (Active, Merged, Abandoned)
- Subject and description
- Owner and reviewers
- CI test results

**Files**:
- List of changed files
- Click file to see diff
- Add inline comments

**History**:
- Patchset versions
- Comments and votes
- CI results per patchset

**Related Changes**:
- Depends on / Needed by
- Related topics
- Conflicts with

### Useful Gerrit Features

**Diff Views**:
- **Side-by-side**: Compare old/new code
- **Unified**: Traditional diff format
- **Between patchsets**: Compare PS1 vs PS2

**Search**:
- Find your changes: `owner:self status:open`
- Find by issue: `bug:105737`
- Find by topic: `topic:indexed-search`

**Keyboard Shortcuts**:
- `?`: Show all shortcuts
- `u`: Go up to dashboard
- `a`: Expand all inline comments
- `c`: Compose review comment
- `n/p`: Next/previous file

## Advanced Topics

### Cherry-Picking Patches

Apply someone else's patch locally:

```bash
# From Gerrit download dropdown, copy cherry-pick command
git fetch origin refs/changes/45/12345/3 && git cherry-pick FETCH_HEAD
```

### Topics

Group related changes:

```bash
git push origin HEAD:refs/for/main%topic=indexed-search-improvements
```

### Work In Progress (WIP)

Mark patch as work-in-progress:

```bash
git push origin HEAD:refs/for/main%wip
```

Or on Gerrit web UI: **More** → **Mark as Work In Progress**

**Use WIP when**:
- Patch incomplete, not ready for review
- Want CI test results before review
- Demonstrating proof of concept

**Remove WIP**: **More** → **Start Review**

### Private Changes

Keep change private (visible only to you and explicit reviewers):

```bash
git push origin HEAD:refs/for/main%private
```

### Draft Comments

Save review comments without publishing:
1. Add comments on files
2. Click **Save** instead of **Send**
3. Edit later
4. Publish when ready

## Troubleshooting

### "Change-Id not found"

**Problem**: Missing or modified Change-Id

**Solution**:
```bash
# Ensure commit-msg hook installed
ls -la .git/hooks/commit-msg

# If missing, install
composer gerrit:setup

# Amend commit to generate Change-Id
git commit --amend --no-edit
```

### "Prohibited by Gerrit"

**Problem**: Pushing to wrong branch or permissions issue

**Solution**:
```bash
# Verify push URL
git config remote.origin.pushurl
# Should be: ssh://<username>@review.typo3.org:29418/Packages/TYPO3.CMS.git

# Push to refs/for/main, not main directly
git push origin HEAD:refs/for/main
```

### "No New Changes"

**Problem**: Pushing identical commit

**Solution**:
- Make actual code changes
- Or amend commit message
- Then push again

### Multiple Commits on Branch

**Problem**: Accidentally created multiple commits

**Solution**: Squash into one commit
```bash
# Interactive rebase
git rebase -i origin/main

# In editor, change all but first "pick" to "squash"
# Save and exit
# Edit combined commit message
# Push
```

## Best Practices

1. **One commit per patch**: Squash multiple commits into one
2. **Rebase regularly**: Stay up-to-date with main branch
3. **Preserve Change-Id**: Never modify when amending
4. **Respond promptly**: Reply to reviews within 2-3 days
5. **Test locally first**: Run tests before pushing
6. **Clear communication**: Explain changes in Gerrit comments
7. **Be patient**: Reviewers are volunteers
8. **Learn from feedback**: Apply lessons to future patches

## Resources

- **Gerrit**: https://review.typo3.org
- **Forger Search**: https://forger.typo3.com
- **Gerrit Documentation**: https://review.typo3.org/Documentation/
- **Slack**: #typo3-cms-coredev

## Quick Command Reference

| Action | Command |
|--------|---------|
| Push new patch | `git push origin HEAD:refs/for/main` |
| Update patch | `git commit --amend && git push origin HEAD:refs/for/main` |
| Rebase on main | `git fetch origin && git rebase origin/main` |
| Abort rebase | `git rebase --abort` |
| Continue rebase | `git rebase --continue` |
| Cherry-pick | `git fetch origin refs/changes/XX/XXXX/X && git cherry-pick FETCH_HEAD` |
| Push as WIP | `git push origin HEAD:refs/for/main%wip` |
| Test SSH | `ssh -p 29418 <user>@review.typo3.org` |
