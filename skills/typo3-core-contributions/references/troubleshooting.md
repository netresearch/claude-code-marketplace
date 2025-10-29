# TYPO3 Contribution Troubleshooting Guide

Common issues and solutions for TYPO3 Core contributions.

## Git Configuration Issues

### Problem: "Permission denied (publickey)"

**Symptoms**:
```
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.
```

**Causes**:
- SSH keys not configured
- Wrong SSH key being used
- Key not added to Gerrit/GitHub

**Solutions**:

**Check SSH keys exist**:
```bash
ls -la ~/.ssh/
# Look for id_ed25519 or id_rsa files
```

**Generate new SSH key if needed**:
```bash
ssh-keygen -t ed25519 -C "your-email@example.org"
```

**Add key to SSH agent**:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

**Test connection**:
```bash
# Test GitHub
ssh -T git@github.com

# Test Gerrit
ssh -p 29418 <username>@review.typo3.org
```

**Verify key on Gerrit**:
1. Visit https://review.typo3.org
2. Settings → SSH Keys
3. Ensure your public key is listed

### Problem: "fatal: refusing to merge unrelated histories"

**Symptoms**:
```
fatal: refusing to merge unrelated histories
```

**Cause**: Trying to merge branches with no common ancestor

**Solution**:
```bash
# Only if you're absolutely sure you want to merge
git pull origin main --allow-unrelated-histories

# Better: Start fresh clone
cd ..
git clone git@github.com:typo3/typo3.git typo3-new
```

### Problem: "email address is not registered in your account"

**Symptoms**:
```
remote: ERROR: commit abc123: email address user@example.com is not registered
in your account, and you lack 'forge committer' permission.
remote: The following addresses are currently registered:
remote:    other@example.com
```

**Cause**: Git commit email doesn't match any email registered in your Gerrit account

**Solution**:

**1. Check your Gerrit registered emails**:
Visit: https://review.typo3.org/settings#EmailAddresses

**2. Update Git configuration to match**:
```bash
# Use one of your registered emails
git config user.email "your-registered@email.com"

# If working in TYPO3 repo, update local config
cd /path/to/typo3
git config user.email "your-registered@email.com"
```

**3. Amend the commit with new email**:
```bash
git commit --amend --reset-author --no-edit
```

**4. Push again**:
```bash
git push origin HEAD:refs/for/main
```

**Prevention**: Always verify your Git email matches Gerrit **before** making commits. Run `verify-prerequisites.sh` script before starting work.

### Problem: "Your branch is ahead of 'origin/main' by X commits"

**Symptoms**:
```
Your branch is ahead of 'origin/main' by 5 commits.
  (use "git push" to publish your local commits)
```

**Cause**: You have commits not yet pushed

**Solutions**:

**If commits should be separate patches**:
```bash
# Push each commit separately
git push origin <commit-hash>:refs/for/main
```

**If commits should be one patch** (most common):
```bash
# Squash into single commit
git rebase -i origin/main
# Change all but first "pick" to "squash"
# Edit commit message
git push origin HEAD:refs/for/main
```

### Problem: "Branch 'main' set up to track remote branch 'main' from 'origin'"

**Symptoms**: Can't push, tracking wrong remote

**Solution**:
```bash
# Reset remote configuration
git config remote.origin.pushurl ssh://<USERNAME>@review.typo3.org:29418/Packages/TYPO3.CMS.git
git config remote.origin.push +refs/heads/main:refs/for/main
```

## Gerrit Issues

### Problem: "Change-Id not found in commit message footer"

**Symptoms**:
```
remote: ERROR: commit abc123: missing Change-Id in message footer
```

**Cause**: commit-msg hook not installed or bypassed

**Solutions**:

**Install hook**:
```bash
composer gerrit:setup

# Or manually
cp Build/git-hooks/commit-msg .git/hooks/
chmod +x .git/hooks/commit-msg
```

**Fix existing commit**:
```bash
# Amend to trigger hook
git commit --amend --no-edit

# Verify Change-Id added
git log -1
```

**If Change-Id still missing**:
```bash
# Manually run hook
.git/hooks/commit-msg .git/COMMIT_EDITMSG

# Amend with new message
git commit --amend -F .git/COMMIT_EDITMSG
```

### Problem: "Prohibited by Gerrit: not permitted to upload"

**Symptoms**:
```
remote: ERROR: [a1b2c3] missing Change-Id in message footer
remote: ERROR: Prohibited by Gerrit: not permitted to upload
```

**Causes**:
- Pushing to wrong ref
- Account permissions issue
- SSH key not configured

**Solutions**:

**Check push URL**:
```bash
git config remote.origin.pushurl
# Should be: ssh://<USERNAME>@review.typo3.org:29418/Packages/TYPO3.CMS.git
```

**Push to correct ref**:
```bash
# Push to refs/for/main, NOT directly to main
git push origin HEAD:refs/for/main
```

**Verify SSH connection**:
```bash
ssh -p 29418 <USERNAME>@review.typo3.org
```

**Check username**:
```bash
git config remote.origin.pushurl
# Ensure <USERNAME> matches your Gerrit username
```

### Problem: "Invalid Change-Id"

**Symptoms**: Gerrit rejects Change-Id format

**Cause**: Manually created or corrupted Change-Id

**Solution**:
```bash
# Remove invalid Change-Id from commit message
git commit --amend
# Delete the Change-Id line
# Save and exit

# Re-amend to generate new Change-Id
git commit --amend --no-edit

# Verify format: "Change-Id: I" followed by 40 hex characters
git log -1 | grep Change-Id
```

### Problem: "New Patchset Not Appearing"

**Symptoms**: Push succeeds but no new patchset on Gerrit

**Causes**:
- No actual changes (identical commit)
- Change-Id modified (created new review instead)

**Solutions**:

**Check if new review created**:
- Look for different review URL in push output
- Search Gerrit for your recent changes

**Ensure actual changes**:
```bash
# View last commit changes
git show HEAD

# Compare with Gerrit patchset
git fetch origin refs/changes/XX/XXXX/X
git diff FETCH_HEAD
```

**If Change-Id was modified**:
```bash
# Get original Change-Id from Gerrit
# Edit commit message to restore it
git commit --amend
# Restore original Change-Id
# Save and push
```

## Rebase and Merge Issues

### Problem: "CONFLICT (content): Merge conflict in file.php"

**Symptoms**:
```
CONFLICT (content): Merge conflict in path/to/file.php
Automatic merge failed; fix conflicts and then commit the result.
```

**Solution**: See "Resolving Merge Conflicts" in gerrit-workflow.md

**Quick steps**:
```bash
# 1. Open conflicted file, resolve conflicts
vim path/to/file.php

# 2. Remove conflict markers (<<<<<<<, =======, >>>>>>>)

# 3. Stage resolved file
git add path/to/file.php

# 4. Continue rebase
git rebase --continue

# 5. Push updated patch
git push origin HEAD:refs/for/main
```

### Problem: "Cannot rebase: You have unstaged changes"

**Symptoms**:
```
error: cannot rebase: You have unstaged changes.
error: Please commit or stash them.
```

**Solutions**:

**Option A: Stash changes**:
```bash
git stash
git rebase origin/main
git stash pop
```

**Option B: Commit changes**:
```bash
git add .
git commit --amend
git rebase origin/main
```

**Option C: Discard changes** (if unwanted):
```bash
git checkout -- .
git rebase origin/main
```

### Problem: "Already up to date"

**Symptoms**: Rebase says "up to date" but Gerrit shows conflicts

**Cause**: Rebasing wrong branch or remote not updated

**Solutions**:
```bash
# Fetch latest changes first
git fetch origin

# Ensure on correct branch
git branch
# Should show * feature/your-branch

# Try rebase again
git rebase origin/main
```

## Test Failures

### Problem: "Bamboo CI Tests Failing"

**Symptoms**: Red X on Gerrit review, tests failed

**Solutions**:

**View test results**:
1. Click test result on Gerrit
2. Read error messages
3. Identify failing tests

**Run tests locally**:
```bash
# Unit tests
composer test:unit

# Specific test class
composer test:unit -- path/to/TestClass.php

# Functional tests
composer test:functional

# All tests
composer test
```

**Common test failures**:

**PHP syntax error**:
```bash
php -l path/to/file.php
```

**Coding standards**:
```bash
composer cs:check
composer cs:fix
```

**Missing dependencies**:
```bash
composer install
```

**Fix and resubmit**:
```bash
# After fixing
git add .
git commit --amend
git push origin HEAD:refs/for/main
```

### Problem: "Tests Pass Locally But Fail on CI"

**Causes**:
- PHP version differences
- Missing dependencies
- Environment-specific issues

**Solutions**:

**Check PHP version**:
```bash
# Local version
php -v

# CI uses multiple versions (7.4, 8.0, 8.1, 8.2)
# Ensure code compatible with all
```

**Test multiple PHP versions locally**:
```bash
# Using Docker
docker run --rm -v $(pwd):/app php:8.2-cli composer test

docker run --rm -v $(pwd):/app php:8.1-cli composer test
```

**Check CI logs carefully**:
- Look for deprecation warnings
- Check for missing extensions
- Verify database-specific issues

## Development Environment Issues

### Problem: "Composer command not found"

**Solution**:
```bash
# Install Composer globally
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Or use specific version
php composer.phar <command>
```

### Problem: "DDEV not starting"

**Solutions**:

**Check Docker running**:
```bash
docker ps
```

**Restart DDEV**:
```bash
ddev restart
```

**Reset DDEV**:
```bash
ddev stop
ddev clean
ddev start
```

**Check logs**:
```bash
ddev logs
```

### Problem: "Out of memory" during Composer operations

**Solution**:
```bash
# Increase PHP memory limit
php -d memory_limit=2G /usr/local/bin/composer install

# Or set in php.ini
memory_limit = 2G
```

## Commit Message Issues

### Problem: "Subject line too long"

**Symptoms**: Validation fails, >72 characters

**Solution**:
```bash
# Amend commit
git commit --amend

# Shorten subject line to ≤52 chars (recommended)
# Or ≤72 chars (absolute max)
```

### Problem: "Wrong commit type"

**Example**: Used `[FEATURE]` on bugfix

**Solution**:
```bash
# Amend commit
git commit --amend

# Change [FEATURE] to [BUGFIX]
# Save and exit
```

### Problem: "Missing footer tags"

**Symptoms**: No Resolves or Releases tags

**Solution**:
```bash
# Amend commit
git commit --amend

# Add required footer:
# Resolves: #12345
# Releases: main, 13.4
# (Keep Change-Id unchanged!)
```

## Account Issues

### Problem: "Can't access Gerrit"

**Solutions**:

**Verify TYPO3.org account**:
- Visit https://my.typo3.org
- Confirm account active

**Sign in to Gerrit**:
- Visit https://review.typo3.org
- Click "Sign In"
- Use TYPO3.org credentials

**Clear browser cache**:
- Cookies might be stale
- Try incognito/private mode

### Problem: "SSH timeout connecting to Gerrit"

**Symptoms**:
```
ssh: connect to host review.typo3.org port 29418: Operation timed out
```

**Causes**:
- Firewall blocking port 29418
- Network restrictions
- Corporate VPN issues

**Solutions**:

**Try different network**:
- Use mobile hotspot
- Try from different location

**Check firewall**:
```bash
telnet review.typo3.org 29418
```

**Use HTTPS instead** (less common for TYPO3):
```bash
git config remote.origin.url https://review.typo3.org/Packages/TYPO3.CMS
```

## Getting Help

### Where to Ask

**Slack**: #typo3-cms-coredev
```
@here I'm having trouble with [issue]. I've tried [solutions].
Error message: [paste error]
Gerrit review: https://review.typo3.org/c/...
```

**Forge**: https://forge.typo3.org
- Create issue if you found a bug in contribution process

**Documentation**: https://docs.typo3.org/m/typo3/guide-contributionworkflow/

### What to Include When Asking

1. **What you're trying to do**
2. **What you've tried**
3. **Error messages** (full text)
4. **Links** (Gerrit review, Forge issue)
5. **Environment** (OS, PHP version, Git version)
6. **Relevant commands** and their output

### Example Help Request

```
I'm trying to push my patch for #105737 but getting this error:

```
remote: ERROR: missing Change-Id in message footer
```

I've tried:
- Running composer gerrit:setup
- Checking that .git/hooks/commit-msg exists and is executable
- Running git commit --amend --no-edit

My setup:
- macOS 12.6
- Git 2.37.1
- PHP 8.1.12

Review (if already created): https://review.typo3.org/c/Packages/TYPO3.CMS/+/12345

Any ideas what I'm missing?
```

## Preventive Measures

### Before Starting

- [ ] Run `scripts/verify-prerequisites.sh`
- [ ] Verify SSH access to Gerrit
- [ ] Check git configuration
- [ ] Ensure hooks installed

### Before Committing

- [ ] Run tests locally
- [ ] Check coding standards
- [ ] Validate commit message format
- [ ] Review changes with `git diff`

### Before Pushing

- [ ] Rebase on latest main
- [ ] Ensure single commit
- [ ] Verify Change-Id present
- [ ] Test one more time

### After Pushing

- [ ] Verify patch on Gerrit
- [ ] Watch CI test results
- [ ] Respond to initial feedback
- [ ] Update if tests fail

## CI/GitLab Issues

### Problem: "How do I find ALL failing CI jobs?"

**Critical**: Never assume what failed - always check ALL job logs!

**Step-by-Step Process**:

**1. Open your Gerrit review**:
```
https://review.typo3.org/c/Packages/TYPO3.CMS/+/YOUR_NUMBER
```

**2. Find CI Results section**:
- Scroll down to see GitLab CI results
- Look for red ❌ marks next to job names
- Note ALL failing job names (there may be multiple!)

**3. For each failing job**:
- Click the job name/link
- You'll be redirected to GitLab: `https://git.typo3.org/typo3/CI/cms/-/jobs/XXXXXX`
- Click "Show complete raw" or append `/raw` to URL
- Read the ACTUAL error messages

**Common Failing Jobs**:
- `cgl pre-merge` - Code style violations
- `phpstan php X.X pre-merge` - Static analysis errors
- `unit php X.X pre-merge` - Unit test failures (may fail on multiple PHP versions)
- `functional php X.X pre-merge` - Functional test failures

### Problem: "Code Style (cgl) Failed"

**Symptoms**:
```
1) path/to/File.php (single_quote)
   ---------- begin diff ----------
-   body: "some string"
+   body: 'some string'
   ----------- end diff -----------
```

**Cause**: Code doesn't match TYPO3 coding standards (PSR-12 + TYPO3 rules)

**Common Issues**:
- Double quotes instead of single quotes for simple strings
- Wrong indentation (spaces vs tabs)
- Missing/extra spaces
- Line length violations

**Solutions**:

**Option 1: Auto-fix with PHP CS Fixer** (recommended):
```bash
# Install PHP CS Fixer if not available
composer require --dev friendsofphp/php-cs-fixer

# Run fixer on specific file
./Build/Scripts/cglFixMyCommit.sh

# Or manually on specific files
vendor/bin/php-cs-fixer fix path/to/File.php
```

**Option 2: Manual fix**:
```bash
# Read the diff carefully
# Fix issues manually in your editor
vim path/to/File.php

# Amend and push
git add path/to/File.php
git commit --amend --no-edit
git push origin HEAD:refs/for/main
```

### Problem: "PHPStan Failed"

**Symptoms**:
```
------ ---------------------------------------------------------------------
 Line   path/to/File.php
------ ---------------------------------------------------------------------
 236    Call to static method Assert::assertNotNull()
        with string will always evaluate to true.
------ ---------------------------------------------------------------------
```

**Cause**: Static analysis detected potential bugs or redundant code

**Common Issues**:
- Redundant type checks (asserting non-null on typed return values)
- Undefined variables
- Type mismatches
- Incorrect PHPDoc annotations

**Solutions**:

```bash
# Run PHPStan locally to see all issues
./Build/Scripts/runTests.sh -s phpstan

# Fix the issues:
# - Remove redundant assertions
# - Add proper type hints
# - Fix type mismatches
# - Update PHPDoc blocks

# Example: Remove redundant assertNotNull()
# Before:
$result = $subject->bodyDescription($dto); // returns string
self::assertNotNull($result); // WRONG - string can't be null

# After:
$result = $subject->bodyDescription($dto);
self::assertNotEmpty($result); // CORRECT - checks string is not empty

# Amend and push
git add path/to/File.php
git commit --amend --no-edit
git push origin HEAD:refs/for/main
```

### Problem: "Unit Tests Failed"

**Symptoms**:
```
FAILURES!
Tests: 11683, Assertions: 20300, Failures: 1.

1) Vendor\Package\Tests\Unit\ClassTest::testMethod
Failed asserting that two strings are equal.
--- Expected
+++ Actual
@@ @@
-''
+'unexpected content'
```

**Cause**: Test assertions don't match actual behavior

**Solutions**:

**1. Read the full error**:
```bash
# Get the full test output from GitLab job log
# Look for:
# - Which test failed (full class name and method)
# - What was expected vs actual
# - Any exception messages or stack traces
```

**2. Run test locally**:
```bash
# Run specific test
./Build/Scripts/runTests.sh -s unit path/to/Tests/Unit/ClassTest.php::testMethod

# Or run all tests in file
./Build/Scripts/runTests.sh -s unit path/to/Tests/Unit/ClassTest.php
```

**3. Fix the issue**:
- If test logic is wrong: Update test assertions
- If implementation is wrong: Fix the implementation
- If test is no longer valid: Remove it (with good reason!)

**4. Verify and push**:
```bash
# Run tests locally to confirm fix
./Build/Scripts/runTests.sh -s unit

# Amend and push
git add .
git commit --amend --no-edit
git push origin HEAD:refs/for/main
```

### Problem: "Multiple jobs failed - which do I fix first?"

**Answer**: Fix ALL of them in ONE patchset!

**Process**:

```bash
# 1. List all failures
# Example: cgl, phpstan, 3x unit tests all failed

# 2. Read ALL job logs
# - cgl: Double quotes issue
# - phpstan: Redundant assertion
# - unit tests: Test logic error

# 3. Fix all issues locally
vim Tests/Unit/IndexerTest.php
# - Change double quotes to single quotes (cgl fix)
# - Remove assertNotNull() (phpstan fix)
# - Fix test logic (unit test fix)

# 4. Verify fixes locally
./Build/Scripts/cglFixMyCommit.sh
./Build/Scripts/runTests.sh -s phpstan
./Build/Scripts/runTests.sh -s unit

# 5. Commit and push ONCE
git add Tests/Unit/IndexerTest.php
git commit --amend --no-edit
git push origin HEAD:refs/for/main

# 6. Wait for re-verification
# All 5 jobs should now pass
```

### Problem: "Patch is in WIP state - reviewers can't see it"

**Symptoms**:
- Patch shows [WIP] tag on Gerrit
- No review feedback after several days
- CI tests passed but no reviews

**Cause**: New patches are WIP by default - reviewers can't see them!

**Solution**:

**1. Verify all CI jobs pass**:
```
Go to Gerrit review page
Check all CI results are green ✅
If any red ❌, fix those first!
```

**2. Mark as ready for review**:
```
Click "More" button (top right on Gerrit)
Click "Start Review"
Optionally add comment: "Ready for review. All CI checks passing."
```

**3. Advertise on Slack** (optional, for visibility):
```
#typo3-cms-coredev channel:
"Submitted patch for #105737 - ready for review when you have time:
https://review.typo3.org/c/Packages/TYPO3.CMS/+/12345"
```

### Problem: "CI takes forever to run"

**Typical Duration**: 10-20 minutes for full pipeline

**If longer than 30 minutes**:
- Check GitLab CI status page: https://git.typo3.org/typo3/CI/cms/-/pipelines
- Pipeline might be queued behind other patches
- Check Slack #typo3-cms-coredev for CI outages
- Be patient - pipelines run in order

**Don't**:
- Push multiple updates while CI is running
- Spam push repeatedly
- Rebase while CI is active

**Do**:
- Wait for current CI to finish
- Make all fixes in one commit
- Push once with all fixes

## Quick Diagnostic Commands

```bash
# Check git configuration
git config -l | grep -E "user\.|remote\.origin"

# Verify SSH connection
ssh -T -p 29418 <username>@review.typo3.org

# Check git hooks
ls -la .git/hooks/ | grep -E "commit-msg|pre-commit"

# View last commit
git log -1 --pretty=full

# Check remote configuration
git remote -v

# Verify Change-Id in last commit
git log -1 | grep Change-Id

# Check for unstaged changes
git status

# View diff of changes
git diff HEAD

# List all branches
git branch -a
```

## Additional Resources

- **Contribution Guide**: https://docs.typo3.org/m/typo3/guide-contributionworkflow/
- **Gerrit Documentation**: https://review.typo3.org/Documentation/
- **Git Documentation**: https://git-scm.com/doc
- **Slack**: https://typo3.slack.com (#typo3-cms-coredev)
- **Forge**: https://forge.typo3.org


---

## Gerrit WIP State Management

### Problem: "How do I mark my patch as ready for review?"

**Background**:
- All new patches start as WIP (Work in Progress) automatically
- Reviewers cannot see WIP patches
- You must mark patches as "ready" before reviewers can see them

**Solution A - Command Line (Recommended)**:

Remove WIP state via git push with %ready flag:

```bash
# If no code changes needed, create empty patchset
git commit --amend --allow-empty --no-edit
git push origin HEAD:refs/for/main%ready
```

**Solution B - Web UI**:

1. Open your review: `https://review.typo3.org/c/Packages/TYPO3.CMS/+/XXXXX`
2. Click "Start Review" button (top right, near your avatar)
3. Done - patch now visible to reviewers

**Solution C - Combined with Code Changes**:

If you're pushing code fixes, add %ready to remove WIP at the same time:

```bash
git commit --amend
git push origin HEAD:refs/for/main%ready
```

**Setting WIP State**:

```bash
# Mark as WIP on initial push
git push origin HEAD:refs/for/main%wip

# Or set WIP via web UI: More menu → "Mark as Work in Progress"
```

**What DOESN'T Work**:

```bash
# ❌ SSH 'gerrit review' command has NO WIP flags
ssh -p 29418 user@review.typo3.org gerrit review --ready 12345,1
ssh -p 29418 user@review.typo3.org gerrit review --wip 12345,1
```

**Key Points**:

- ✅ Use `%wip` and `%ready` flags with `git push`
- ✅ Empty pushes with `--allow-empty` are accepted
- ❌ SSH `gerrit review` command does NOT support WIP operations
- ✅ Web UI works but command line is faster

