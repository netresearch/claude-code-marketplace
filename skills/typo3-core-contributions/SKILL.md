---
name: typo3-core-contributions
version: 1.3.0
description: |
  Guide contributors through the complete TYPO3 Core contribution workflow from account setup to patch submission
  for both code and documentation contributions.

  Trigger when: working with TYPO3 Forge issues (forge.typo3.org/issues/*), preparing patches for TYPO3 Core,
  contributing to TYPO3 (code or documentation), submitting patches to Gerrit (review.typo3.org) or GitHub PRs
  (TYPO3-Documentation/*), fixing TYPO3 bugs, managing WIP state, or debugging CI failures.

  Covers: Account setup, environment configuration with DDEV, commit message formatting, Gerrit review workflow,
  GitHub PR workflow for documentation, WIP state management (command-line and web UI), CI/CD debugging (CGL,
  PHPStan, unit tests), troubleshooting (60+ scenarios), code quality enforcement, and systematic patch submission
  for both code and documentation repositories.
license: Complete terms in LICENSE
---

# TYPO3 Core Contributions

## Overview

Guide contributors through the complete TYPO3 Core contribution process, from initial setup through patch submission and review. Handle both new contributors starting from scratch and experienced contributors working on specific patches.

## When to Use This Skill

Activate when the user:
- Provides a TYPO3 Forge issue URL (e.g., `https://forge.typo3.org/issues/105737`)
- Mentions contributing to TYPO3 Core, submitting patches, or fixing TYPO3 bugs
- Needs help with Gerrit review workflow, rebasing, or patch updates
- Wants to create a new Forge issue for a bug or feature
- Requests TYPO3 development environment setup
- Asks about TYPO3 commit message format or contribution guidelines

## Scope: TYPO3 Core Contributions (Code AND Documentation)

**This skill covers**: All TYPO3 Core contributions
- **Core Code**: PHP, JavaScript, CSS, tests via Gerrit (review.typo3.org)
- **Core Documentation**: TYPO3CMS-Guide-* repositories via GitHub Pull Requests
- Forge issue tracking (for both code and documentation)
- Commit message standards
- Contribution workflow guidance

**Repository-Specific Workflows**:

### Core Code (typo3/typo3)
- **Submission**: Gerrit (review.typo3.org)
- **Validation**: Git commit-msg hooks
- **CI/CD**: GitLab pipelines
- **Format**: PHP, JavaScript, CSS, YAML
- **This skill handles**: Complete workflow

### Core Documentation (TYPO3-Documentation/*)
- **Submission**: GitHub Pull Requests
- **Validation**: GitHub Actions / pre-commit hooks
- **CI/CD**: GitHub Actions
- **Format**: reStructuredText (.rst files)
- **This skill handles**: GitHub PR workflow, commit standards

**Integration with typo3-docs-skill**:
- **typo3-docs-skill**: Validates and writes TYPO3 documentation format (reStructuredText)
  - Use for: Documentation structure, formatting, rendering
  - Validates: Extension docs, Core docs, any TYPO3 documentation
  - URL: https://github.com/netresearch/typo3-docs-skill
- **This skill (typo3-core-contributions)**: Handles contribution workflow
  - Use for: GitHub PR process, commit messages, review coordination

**Example from real experience (Issue #105737)**:
```
✅ Core code fix → This skill → Gerrit submission (#91302)
✅ Documentation fix → This skill → GitHub PR (#397)
✅ Documentation validation → typo3-docs-skill → Format checking
```

When we fixed issue #105737:
1. Used **this skill** to submit Core code patch via Gerrit
2. Discovered docs error in commit message guide
3. Used **this skill** to create GitHub PR to TYPO3CMS-Guide-ContributionWorkflow
4. Could use **typo3-docs-skill** to validate reStructuredText formatting

**When to use each skill**:
- **typo3-core-contributions** (this): For CONTRIBUTING to TYPO3 (code or docs)
- **typo3-docs-skill**: For WRITING/VALIDATING documentation format

## Workflow Decision Tree

Determine the user's current state and guide accordingly:

```
User starts contribution workflow
├─ Has Forge issue URL?
│  ├─ Yes → Proceed to Prerequisites Check
│  └─ No → Guide to Issue Creation Phase
├─ Prerequisites verified?
│  ├─ Yes → Proceed to Development Phase
│  └─ No → Guide through Setup Phase
├─ Patch ready?
│  ├─ Yes → Proceed to Submission Phase
│  └─ No → Guide through Development Phase
└─ Patch submitted?
   ├─ Yes → Guide through Review & Update Phase
   └─ No → Prepare for Gerrit submission
```

## Prerequisites Check

Before beginning any contribution work, verify the user has:

1. **Required Accounts**:
   - TYPO3.org account (my.typo3.org)
   - Gerrit account with SSH keys (review.typo3.org)
   - Slack access (typo3.slack.com) for #typo3-cms-coredev channel

2. **Development Environment**:
   - Git configured with TYPO3 settings
   - TYPO3 Core repository cloned
   - DDEV-based development environment (preferred)
   - Git hooks installed (commit-msg, pre-commit)

3. **Skill Integrations**:
   - `typo3-ddev-skill` for environment management
   - `typo3-docs-skill` for documentation contributions (optional)
   - `typo3-conformance-skill` for code quality checks (optional)

Run `scripts/verify-prerequisites.sh` to check all prerequisites. If any are missing, proceed to the Setup Phase.

**⚠️ Critical Email Requirement**: Your Git email MUST match one of your registered Gerrit emails or all pushes will be rejected:
- Check registered emails: https://review.typo3.org/settings#EmailAddresses
- Verify Git config: `git config user.email`
- If mismatch, update Git: `git config user.email "your-registered@email.com"`
- This verification is included in `verify-prerequisites.sh`

## Phase 1: Account Setup

### Check Existing Accounts

Ask the user:
- "Do you have a TYPO3.org account?"
- "Have you set up Gerrit SSH access?"
- "Are you in the TYPO3 Slack workspace?"

### Guide Account Creation

If accounts are missing, load `references/account-setup.md` for detailed instructions:

**TYPO3.org Account**:
- Visit https://my.typo3.org/index.php?id=2
- Register with username, email, full name, and strong password
- Verify email
- This account provides access to Forge and Gerrit

**Gerrit SSH Setup**:
- Sign in to https://review.typo3.org with TYPO3.org credentials
- Generate SSH key pair (platform-specific instructions in reference)
- Add public key to Gerrit: Profile → SSH Keys
- Test connection: `ssh -p 29418 <username>@review.typo3.org`

**Slack Access**:
- Join TYPO3 Slack: https://typo3.slack.com
- Required channel: #typo3-cms-coredev
- Optional channels: #typo3-cms, #random

Verify completion before proceeding to next phase.

## Phase 2: Environment Setup

### Quick Setup Options

**Option 1: Automated Setup (Recommended for Beginners)**
```bash
./scripts/setup-typo3-coredev.sh
```
Interactive script that guides through complete setup. See below for details.

**Option 2: Use typo3-ddev-skill**
```
Use typo3-ddev-skill for complete DDEV setup
```
If available, use the typo3-ddev-skill for guided setup.

**Option 3: Manual Setup**
Follow the comprehensive workflow in `references/ddev-setup-workflow.md` for step-by-step instructions.

### Automated Setup Script

The `scripts/setup-typo3-coredev.sh` script provides complete automated setup:

**What it does**:
- Checks prerequisites (Git, DDEV, Docker)
- Gathers configuration (project name, credentials, PHP version)
- Clones TYPO3 Core repository
- Configures Git for Gerrit submissions
- Sets up DDEV with optimal settings
- Installs dependencies and TYPO3
- Activates development extensions
- Generates test data (optional)

**Usage**:
```bash
cd /path/to/your/projects/
./path/to/scripts/setup-typo3-coredev.sh
```

**Interactive prompts**:
- Project name (e.g., t3coredev-14-php8-4)
- Your name for Git commits
- Your email
- Gerrit username
- PHP version (8.2, 8.3, 8.4)
- Timezone
- TYPO3 admin password

The script handles all configuration and creates a fully functional development environment.

### Manual DDEV Setup (If Automation Not Suitable)

If `typo3-ddev-skill` is not available and you prefer manual setup:

**Clone TYPO3 Repository**:
```bash
mkdir typo3-contribution && cd typo3-contribution
git clone git@github.com:typo3/typo3.git .
```

**Configure Git for TYPO3**:
```bash
# User identity (required)
git config user.name "Your Name"
git config user.email "your-email@example.org"

# Auto-rebase (required)
git config branch.autosetuprebase remote

# Gerrit push configuration (required)
git config remote.origin.pushurl ssh://<USERNAME>@review.typo3.org:29418/Packages/TYPO3.CMS.git
git config remote.origin.push +refs/heads/main:refs/for/main
```

**Install Git Hooks**:
```bash
composer gerrit:setup
```

Or manually copy from `Build/git-hooks/` to `.git/hooks/` and make executable.

**Set Up Commit Template** (optional but recommended):
Copy `assets/commit-template.txt` to `~/.gitmessage.txt`:
```bash
git config commit.template ~/.gitmessage.txt
```

### Verify Setup

Run verification checks:
```bash
# Check git configuration
git config -l | grep -E "user\.|remote\.origin\.|branch\.autosetuprebase"

# Test Gerrit connection
ssh -p 29418 <username>@review.typo3.org

# Verify hooks exist
ls -la .git/hooks/commit-msg .git/hooks/pre-commit
```

All checks must pass before proceeding.

## Phase 3: Issue Management

### Working with Existing Forge Issue

If user provides a Forge issue URL (e.g., `https://forge.typo3.org/issues/105737`):

1. **Fetch and analyze the issue**:
   ```
   Use WebFetch to extract:
   - Issue title and description
   - Issue number (e.g., #105737)
   - Status and category
   - Affected TYPO3 version
   - Steps to reproduce
   - Expected vs actual behavior
   - Any existing patches or comments
   ```

2. **Determine contribution scope**:
   - Bugfix → `[BUGFIX]` commit type
   - New feature → `[FEATURE]` commit type (main branch only)
   - Refactoring/cleanup → `[TASK]` commit type
   - Documentation → `[DOCS]` commit type
   - Security → `[SECURITY]` commit type

3. **Check for existing patches**:
   - Search Gerrit: https://review.typo3.org
   - Look for Change-Id or related patches
   - Coordinate if others are working on it

### Creating New Forge Issue

If user has a bug but no issue yet:

1. **Gather issue information**:
   - What is broken or what feature is needed?
   - Steps to reproduce (for bugs)
   - Expected behavior vs actual behavior
   - TYPO3 version affected
   - Error messages or logs

2. **Create issue on Forge**:
   - Visit https://forge.typo3.org/projects/typo3cms-core/issues/new
   - Fill in all required fields
   - Category: Choose appropriate area (Backend, Frontend, etc.)
   - Priority: Should have (most common), Must have, Could have
   - Set target version if known

3. **Note the issue number** for commit message later

**Important**: Every patch must have a matching Forge issue before submission.

### Creating Forge Issues Programmatically (Advanced)

For automation or when web UI is not accessible, Forge issues can be created via the Redmine REST API:

**Prerequisites**:
- Get API key from https://forge.typo3.org/my/account (under "API access key")
- Store securely as environment variable: `FORGE_API_KEY`

**Using the script**:
```bash
# Set your API key
export FORGE_API_KEY="your-api-key-here"

# Create issue
./scripts/create-forge-issue.sh
```

The script interactively prompts for:
- Subject line
- Description
- Tracker type (Bug, Feature, Task)
- Category (e.g., Backend, Frontend, Indexed Search)
- Priority (Should have, Must have, Could have)
- TYPO3 version affected

**Manual API usage**:
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: $FORGE_API_KEY" \
  -d '{
    "issue": {
      "project_id": "typo3cms-core",
      "subject": "Issue title",
      "description": "Detailed description",
      "tracker_id": 1,
      "category_id": 975,
      "priority_id": 4,
      "custom_fields": [
        {"id": 4, "value": "13"}
      ]
    }
  }' \
  https://forge.typo3.org/issues.json
```

**Common IDs** (query full list via API):
- Trackers: 1=Bug, 2=Feature, 4=Task
- Priority: 3=Must have, 4=Should have, 5=Could have
- Categories: Use `scripts/query-forge-metadata.sh` to list all categories

**Response includes**:
- Created issue number (for `Resolves:` line)
- Issue URL for reference

Load `references/forge-api.md` for complete API documentation and examples.

## Phase 4: Development

### Create Feature Branch

```bash
# Ensure on main branch with latest changes
git checkout main
git pull origin main

# Create feature branch (name pattern: feature/<issue-number>-<description>)
git checkout -b feature/105737-fix-indexed-search-crash
```

### Make Code Changes

Guide the user through development:

1. **Analyze the issue**: Understand root cause and scope
2. **Locate affected files**: Use code search and navigation
3. **Implement fix or feature**:
   - Follow TYPO3 coding standards
   - **Use framework patterns** (DI, service locators, event dispatchers)
   - Check if TYPO3 already provides the pattern you need
   - Add/update documentation as needed
   - Consider backwards compatibility
   - Add deprecations properly with `trigger_error()` (no `[!!!]` for deprecations)
   - For breaking changes: Document impact on extension developers

**Real-world insight**: Reviewers expect architectural alignment with TYPO3 framework patterns.
Don't reinvent what the framework provides. Study `Services.yaml` patterns and use dependency
injection over manual instance management.

4. **Write tests**:
   - Unit tests for isolated functionality
   - Functional tests for integrated behavior
   - Follow existing test patterns in codebase
   - **Use typo3-testing-skill** for comprehensive test writing:
     ```
     Activate typo3-testing-skill for:
     - Writing unit tests for new functionality
     - Creating functional tests for integrations
     - Understanding TYPO3 test patterns
     - Setting up test fixtures and data
     - Running and debugging tests locally
     ```

5. **Build frontend assets** (if needed):
   - SCSS → CSS compilation
   - JavaScript/TypeScript bundling
   - Run build commands: `npm run build` or similar

6. **Create changelog entries** (if needed):
   - Breaking changes require changelog
   - New features should have changelog
   - Location: `Build/CHANGELOG/`

### Code Quality Validation

**IMPORTANT**: Always validate code quality BEFORE committing. Use `typo3-conformance-skill`:

```
Activate typo3-conformance-skill to:
- Check TYPO3 Coding Guidelines (CGL) compliance
- Run PHP_CodeSniffer (PHPCS) validation
- Execute PHPStan static analysis
- Validate PHP syntax and compatibility
- Fix coding standard violations automatically
- Ensure code passes CI checks locally
```

**When to use**:
- ✅ Before first commit
- ✅ After making code changes
- ✅ Before pushing to Gerrit
- ✅ When CI checks fail

**Benefits**:
- Catch issues locally before submission
- Faster review process (no back-and-forth on standards)
- Learn TYPO3 coding conventions
- Avoid CI pipeline failures

### Self-Review

Before committing, review the changes:
- Code follows TYPO3 conventions (validated with typo3-conformance-skill)
- No debug statements or console.log
- Tests pass locally (written/validated with typo3-testing-skill)
- Documentation is updated
- Changelog created if needed
- No unintended file changes

## Phase 5: Commit Creation

### Commit Message Format

TYPO3 requires strict commit message formatting. Use `scripts/create-commit-message.py` for interactive generation, or follow this format:

**Structure**:
```
[TYPE] Subject line (max 52 chars, imperative mood)

Detailed description of changes explaining the how and why.
Lines wrapped at 72 characters. Use bullet points with * for
multiple items.

Resolves: #12345
Releases: main, 13.4, 12.4
```

**Commit Types**:
- `[BUGFIX]` - Bug fixes
- `[FEATURE]` - New features (main branch only)
- `[TASK]` - Refactoring, cleanup, miscellaneous
- `[DOCS]` - Documentation changes
- `[SECURITY]` - Security fixes
- `[!!!]` - Breaking change prefix (before type: `[!!!][FEATURE]`)

**Footer Tags**:
- `Resolves: #<issue>` **(REQUIRED)** - Every commit MUST have at least one Resolves line. The commit-msg hook will reject commits without it. Closes issue on merge for features/tasks.
- `Related: #<issue>` **(OPTIONAL)** - Links related issues without closing. CANNOT be used alone - you must have at least one Resolves line in addition to any Related lines.
- `Releases: main, 13.4, 12.4` **(REQUIRED)** - Target versions (comma-separated)
- `Change-Id: I<hash>` - Auto-generated by git hook (DO NOT modify, NEVER remove)

**Subject Line Rules**:
- Maximum 52 characters (72 absolute limit)
- Imperative mood: "Fix bug" not "Fixed bug" or "Fixes bug"
- Start with uppercase letter
- No period at the end
- Describe what now works, not what was broken

**Description Body**:
- Explain how and why, not what (code shows what)
- Don't repeat Forge issue content
- Don't describe reproduction steps
- Keep focused on changes made
- Wrap at 72 characters (URLs can be longer)

Load `references/commit-message-format.md` for complete specification with examples.

### Create the Commit

**Initial commit**:
```bash
git add .
git commit
# Edit commit message in editor (template will load if configured)
```

The commit-msg hook automatically adds the `Change-Id` line - never modify or remove this!

**Validate commit message**:
Run `scripts/validate-commit-message.py` to check format compliance.

### Amending Commits

For subsequent changes to the same patch:
```bash
git add .
git commit --amend
# Preserve the Change-Id line!
```

**Important**: Keep only ONE commit on the branch. All changes should be amended into the single commit.

## Phase 6: Gerrit Submission

### First-Time Submission

**Push to Gerrit**:
```bash
git push origin HEAD:refs/for/main
```

Or simply `git push` if defaults are configured.

**Expected response**:
```
remote: SUCCESS
remote: https://review.typo3.org/c/Packages/TYPO3.CMS/+/12345 [NEW]
```

Copy and save the review URL!

### Post-Submission Actions

1. **Check Continuous Integration**:
   - Gerrit automatically runs tests
   - Wait for CI results (usually 5-15 minutes)
   - Green checkmarks = passed, red X = failed

2. **Monitor for feedback**:
   - You'll receive email notifications
   - Check Gerrit review page regularly
   - Join #typo3-cms-coredev on Slack

3. **Advertise your patch** (optional, recommended for new contributors):
   - Post in #typo3-cms-coredev: "I've submitted my first patch for issue #12345, would appreciate reviews: <gerrit-url>"

## Phase 7: Review & Update Cycle

### Understanding Review Expectations

**IMPORTANT**: Multiple revisions (patch sets) are NORMAL and expected in TYPO3 Core.

**Real-world examples** (from actual merged patches):
- Extbase FileUpload tests: 24 patch sets
- Record API breaking change: 14 patch sets
- DI refactoring: 9 patch sets
- Pagetree performance fix: 7 patch sets

**What causes multiple revisions**:
- CI failures requiring fixes
- Rebases due to main branch updates
- Code quality improvements from reviewer feedback
- Architectural refinements suggested by core team
- Edge case handling
- Scope adjustments (e.g., backport constraints)

**Mindset**: Each revision makes your patch better. High revision counts show:
- Responsiveness to feedback
- Collaborative improvement
- Thorough vetting process
- Learning framework patterns

Load `references/gerrit-review-patterns.md` for comprehensive real-world review insights.

### Responding to Feedback

When reviewers request changes:

1. **Read feedback carefully**: Understand what needs to change
2. **Respond to every comment**: Even if just "Done" or "Fixed in PS X"
3. **Make requested changes**: Update code locally
4. **Use appropriate skill**:
   - Code quality issues → typo3-conformance-skill
   - Test failures → typo3-testing-skill
5. **Test thoroughly**: Validate changes work
6. **Amend the commit**:
   ```bash
   git add .
   git commit --amend
   # Keep the Change-Id unchanged!
   ```
7. **Push updated patch**:
   ```bash
   git push origin HEAD:refs/for/main
   ```

This creates a new patchset on the existing review.

**Pro tip**: Don't take high revision counts personally - they're a sign of thorough review, not failure.

### Rebasing Your Patch

If your patch falls behind main branch:

**Option 1: Browser-based (easiest)**:
1. Open your patch on Gerrit
2. Click "Rebase" button
3. Select "Rebase on top of the main branch"
4. Works only if no conflicts exist

**Option 2: Command-line**:
```bash
# Fetch latest changes
git fetch origin

# Rebase onto main
git rebase origin/main

# If conflicts occur, resolve them:
# 1. Fix conflicts in files
# 2. git add <resolved-files>
# 3. git rebase --continue

# Push rebased patch
git push origin HEAD:refs/for/main
```

Load `references/gerrit-workflow.md` for detailed rebase and conflict resolution procedures.

### Review Process

**Voting System**:
- **Code Review**: -2 (reject) to +2 (approve)
- **Verified**: -1 (fails tests) to +1 (passes tests)
- **+2 from core team member** + **+1 verified** → Ready for merge

**Typical Timeline**:
- Simple bugfixes: 1-3 days
- Complex features: 1-2 weeks
- Patches need at least 2 reviewers (one must be core team)

## Phase 8: Merge & Completion

### Pre-Merge

Once approved:
- Core merger will handle final merge
- You'll receive notification when merged
- Issue status updates automatically on Forge

### Post-Merge

1. **Clean up local branch**:
   ```bash
   git checkout main
   git pull origin main
   git branch -D feature/105737-fix-indexed-search-crash
   ```

2. **Update Forge issue if needed**:
   - Add any follow-up notes
   - Close related issues if applicable

3. **Celebrate**: You've contributed to TYPO3 Core! 🎉

## Integration with Other Skills

This skill works best when combined with specialized TYPO3 skills. Activate them proactively during the contribution workflow.

### typo3-ddev-skill

**Purpose**: DDEV-based development environment setup and management

**When to activate**:
```
Use typo3-ddev-skill when:
- Setting up TYPO3 Core development environment from scratch
- Configuring DDEV for TYPO3
- Managing local TYPO3 instances
- Database operations and management
- Troubleshooting DDEV/Docker issues
```

**Integration point**: Phase 2 (Environment Setup)

**URL**: Check if available in your environment

### typo3-docs-skill

**Purpose**: TYPO3 documentation format validation and writing

**When to activate**:
```
Use typo3-docs-skill when:
- Writing TYPO3 documentation (Core or Extension)
- Validating reStructuredText (.rst) format and structure
- Checking documentation rendering locally
- Understanding TYPO3 documentation standards
- Fixing formatting issues in .rst files
- Creating proper cross-references and code blocks
```

**Integration point**: Phase 4 (Development) - for documentation contributions

**Complementary usage**: This skill handles the contribution workflow (GitHub PRs, commit messages),
while typo3-docs-skill handles the documentation format itself.

**URL**: https://github.com/netresearch/typo3-docs-skill

### typo3-conformance-skill

**Purpose**: TYPO3 Coding Guidelines (CGL) and code quality validation

**When to activate** (PROACTIVELY):
```
Use typo3-conformance-skill:
- BEFORE committing code changes
- After implementing new functionality
- When fixing coding standard violations
- Before pushing to Gerrit
- When CI checks fail
```

**Validates**:
- TYPO3 Coding Guidelines (CGL) compliance
- PHP_CodeSniffer (PHPCS) standards
- PHPStan static analysis
- PHP syntax and version compatibility
- Best practices and patterns

**Integration points**:
- Phase 4 (Development) - Code Quality Validation section
- Phase 6 (Gerrit Submission) - Before pushing
- Phase 7 (Review & Update) - When CI fails

**Benefits**:
- Catch issues locally before submission
- Avoid CI pipeline failures
- Faster review process
- Learn TYPO3 conventions

**URL**: https://github.com/netresearch/typo3-conformance-skill

### typo3-testing-skill

**Purpose**: TYPO3 test writing and execution

**When to activate** (PROACTIVELY):
```
Use typo3-testing-skill when:
- Writing unit tests for new functionality
- Creating functional tests for integrations
- Writing acceptance/E2E tests
- Understanding TYPO3 test patterns and structure
- Setting up test fixtures and data providers
- Running and debugging tests locally
- Fixing failing tests
- Increasing test coverage
```

**Covers**:
- Unit testing (PHPUnit)
- Functional testing (database integration)
- Acceptance testing (Codeception)
- Test structure and organization
- Mocking and fixtures
- Test execution and debugging

**Integration points**:
- Phase 4 (Development) - Writing Tests subsection
- Phase 7 (Review & Update) - When tests fail
- Before submission - Ensure tests pass

**Benefits**:
- Write better, more maintainable tests
- Understand TYPO3 testing patterns
- Debug test failures effectively
- Ensure adequate test coverage

**URL**: https://github.com/netresearch/typo3-testing-skill

## Recommended Workflow with Skills

**Complete workflow using all skills**:

1. **Setup** → typo3-ddev-skill → Environment ready
2. **Development** → This skill → Feature branch created
3. **Code Implementation** → This skill → Code written
4. **Testing** → typo3-testing-skill → Tests written and passing
5. **Quality Check** → typo3-conformance-skill → CGL validated
6. **Documentation** (if applicable) → typo3-docs-skill → Docs formatted
7. **Commit** → This skill → Proper commit message
8. **Submit** → This skill → Gerrit/GitHub submission
9. **Review** → This skill → Handle feedback
10. **Merge** → This skill → Celebrate! 🎉

## Common Scenarios

### Scenario 1: Complete First Contribution

User: "I want to fix https://forge.typo3.org/issues/105737"

**Workflow with skill integrations**:
1. Run prerequisites check
2. Fetch issue details from Forge
3. Verify/setup accounts if needed
4. **Use typo3-ddev-skill** → Setup/verify environment
5. Create feature branch
6. Guide through fix development
7. **Use typo3-testing-skill** → Write unit/functional tests
8. **Use typo3-conformance-skill** → Validate code quality (CGL, PHPStan)
9. Create commit with proper message
10. Submit to Gerrit
11. Monitor review process

**Proactive skill activation**:
- Activate typo3-testing-skill when writing tests (step 7)
- Activate typo3-conformance-skill BEFORE committing (step 8)
- These skills help catch issues locally, saving review cycles

### Scenario 2: Update Existing Patch

User: "Reviewer asked me to change variable names in my patch"

**Workflow with skill integrations**:
1. Verify git setup and branch
2. Guide through changes
3. **Use typo3-conformance-skill** → Validate changes meet CGL
4. Amend commit (preserve Change-Id!)
5. Push updated patchset
6. Notify reviewer on Gerrit

**Best practice**: Always run typo3-conformance-skill after making changes to ensure
new code still passes all quality checks.

### Scenario 3: Rebase Needed

User: "My patch shows merge conflicts"

**Workflow**:
1. Load `references/gerrit-workflow.md` for conflict resolution
2. Guide through rebase process
3. Help resolve conflicts if needed
4. Test after rebase
5. Push rebased patch

### Scenario 4: Create New Issue

User: "I found a bug in TYPO3 backend but there's no issue"

**Workflow**:
1. Gather bug details systematically
2. Check if issue already exists on Forge
3. Guide through Forge issue creation
4. Proceed with contribution workflow

### Scenario 5: Root Cause Analysis and Dual-Repository Fix

User: "Documentation seems wrong, but the real issue is in the Core code"

**Real Example from Issue #105737**:
1. **Initial symptom**: Documentation mentioned both "Resolves:" and "Fixes:" tags
2. **Investigation**: Reviewer confirmed TYPO3 uses only "Resolves:" for standardization
3. **Root cause discovery**: commit-msg hook at `Build/git-hooks/commit-msg:218` displayed misleading error message
4. **Dual-repository solution**:
   - Documentation fix via GitHub PR to TYPO3CMS-Guide-ContributionWorkflow
   - Core fix via Gerrit patch to update commit-msg hook error message
5. **API usage**: Created Forge issue #107881 via Redmine API
6. **Backward compatibility**: Kept validation regex accepting both, updated only user-facing message

**Workflow**:
1. Analyze whether issue is documentation-only or has Core source
2. If Core source exists:
   - Create Forge issue for Core fix
   - Submit Core patch via Gerrit (this skill)
   - If docs also need update, create separate PR (typo3-docs-skill)
3. Ensure both fixes reference each other
4. Balance backward compatibility with standardization

### Scenario 6: CI Pipeline Failures

User: "My patch was submitted but CI checks are failing"

**Workflow with skill integrations**:
1. Check Gerrit for CI failure details
2. Identify failure type:
   - **CGL/Coding Standards** → Use typo3-conformance-skill
   - **PHPStan/Static Analysis** → Use typo3-conformance-skill
   - **Unit/Functional Tests** → Use typo3-testing-skill
   - **Build/Compilation** → This skill for troubleshooting
3. Fix issues locally using appropriate skill
4. **Validate locally BEFORE pushing**:
   - Run typo3-conformance-skill for code quality
   - Run typo3-testing-skill for test execution
5. Amend commit with fixes
6. Push updated patchset

**Pro tip**: Use typo3-conformance-skill and typo3-testing-skill BEFORE first
submission to avoid CI failures entirely. Catching issues locally is faster
than waiting for CI pipelines.

## Troubleshooting

Common issues and solutions:

**"Permission denied" when pushing**:
- Check SSH key configuration
- Test: `ssh -p 29418 <username>@review.typo3.org`
- Verify pushurl: `git config remote.origin.pushurl`

**"Missing Change-Id in commit message"**:
- Install commit-msg hook: `composer gerrit:setup`
- Or copy manually from `Build/git-hooks/commit-msg`
- Re-commit with `git commit --amend`

**"Merge conflict" during rebase**:
- Load `references/gerrit-workflow.md` for detailed steps
- Resolve conflicts manually
- Continue: `git add . && git rebase --continue`

**"CI tests failing"**:
- **For code quality issues** (CGL, PHPStan): Use **typo3-conformance-skill**
- **For test failures**: Use **typo3-testing-skill**
- Check specific failure details on Gerrit
- Fix issues locally with appropriate skill
- Validate locally before pushing updated patchset

**"Coding standards violations"**:
- Use **typo3-conformance-skill** immediately
- Run PHPCS, PHPStan, and CGL checks locally
- Fix violations automatically where possible
- Learn TYPO3 conventions to avoid future violations

Load `references/troubleshooting.md` for comprehensive troubleshooting guide.

## Resources

### scripts/

**setup-typo3-coredev.sh**: Complete automated DDEV setup (recommended for new contributors)
```bash
./scripts/setup-typo3-coredev.sh
```
Interactive script that sets up complete TYPO3 Core development environment including Git configuration, DDEV, TYPO3 installation, and test data.

**verify-prerequisites.sh**: Check all prerequisites (accounts, git config, environment)
```bash
./scripts/verify-prerequisites.sh
```

**create-commit-message.py**: Interactive commit message generator following TYPO3 format
```bash
python scripts/create-commit-message.py --issue 105737 --type BUGFIX
```

**validate-commit-message.py**: Validate commit message against TYPO3 requirements
```bash
python scripts/validate-commit-message.py
```

**create-forge-issue.sh**: Create Forge issues via Redmine REST API (interactive)
```bash
export FORGE_API_KEY="your-api-key"
./scripts/create-forge-issue.sh
```

**query-forge-metadata.sh**: Query Forge for available categories, trackers, and priorities
```bash
export FORGE_API_KEY="your-api-key"
./scripts/query-forge-metadata.sh
```

### references/

**ddev-setup-workflow.md**: Complete production-tested DDEV setup workflow (686 lines)
- Step-by-step manual setup instructions
- DDEV configuration details
- TYPO3 installation and extension activation
- Test data generation
- Troubleshooting and best practices

**account-setup.md**: Detailed account creation guides (TYPO3.org, Gerrit, Slack)

**commit-message-format.md**: Complete commit message specification with examples

**gerrit-workflow.md**: Comprehensive Gerrit usage (review, rebase, conflicts, voting)

**forge-api.md**: Complete Forge/Redmine REST API documentation with examples

**commit-msg-hook.md**: Deep dive into Build/git-hooks/commit-msg validation and error messages

**troubleshooting.md**: Common issues and solutions

### assets/

**commit-template.txt**: Git commit message template for TYPO3 (copy to `~/.gitmessage.txt`)

## Best Practices

1. **One commit per patch**: Amend changes, don't create multiple commits
2. **Preserve Change-Id**: Never modify the auto-generated Change-Id line
3. **Validate BEFORE committing**: Use typo3-conformance-skill and typo3-testing-skill proactively
4. **Test thoroughly**: Write and run tests locally (typo3-testing-skill) before submission
5. **Quality first**: Always validate with typo3-conformance-skill before pushing
6. **Rebase regularly**: Keep patch up-to-date with main branch
7. **Self-review first**: Check changes before pushing
8. **Respond promptly**: Answer reviewer feedback within 2-3 days
9. **Use complementary skills**: Leverage typo3-ddev-skill, typo3-docs-skill as needed
10. **Ask for help**: Use #typo3-cms-coredev Slack channel when stuck
11. **Follow conventions**: Read existing code patterns in affected files

**Skill integration best practices**:
- Use typo3-conformance-skill BEFORE every commit
- Use typo3-testing-skill when writing ANY test
- Use typo3-docs-skill for ALL documentation contributions
- Catch issues locally to avoid CI failures and review iterations

## References

- **Contribution Guide**: https://docs.typo3.org/m/typo3/guide-contributionworkflow/main/en-us/
- **Forge**: https://forge.typo3.org
- **Gerrit**: https://review.typo3.org
- **Forger** (search tool): https://forger.typo3.com
- **Slack**: https://typo3.slack.com (#typo3-cms-coredev)
