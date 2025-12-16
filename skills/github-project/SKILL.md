---
name: github-project
description: "GitHub repository setup and platform-specific features. This skill should be used when creating new GitHub repositories, configuring branch protection rules, setting up GitHub Issues/Discussions/Projects, creating sub-issues and issue hierarchies, managing PR review workflows, configuring Dependabot/Renovate auto-merge, setting up merge queues with GraphQL enqueuePullRequest mutations, or checking GitHub project configuration. Focuses on GitHub platform features, not CI/CD pipelines or language-specific tooling. By Netresearch."
---

# GitHub Project Skill

GitHub platform configuration and repository management patterns. This skill focuses exclusively on **GitHub-specific features**.

## Scope Boundaries

**This Skill Covers:**
- Branch protection rules and PR workflows
- CODEOWNERS configuration
- GitHub Issues, Discussions, Projects
- Sub-issues and issue hierarchies (parent/child relationships)
- Dependabot/Renovate auto-merge
- GitHub Releases configuration
- Repository collaboration features

**Delegate to Other Skills:**
- CI/CD pipelines → `go-development`, `php-modernization`, `typo3-testing`
- Security scanning (CodeQL, gosec) → `security-audit`
- SLSA, SBOMs, supply chain → `enterprise-readiness`
- Git branching strategies, conventional commits → `git-workflow`

## Triggers

**Setup & Configuration:**
- Creating a new GitHub repository
- "Check my GitHub project setup"
- "Configure branch protection"
- "Set up GitHub Issues/Discussions"
- "How do I require PR reviews?"
- "Auto-merge Dependabot PRs"
- "Configure CODEOWNERS"

**Sub-Issues & Issue Hierarchies:**
- "Create sub-issues"
- "Add child issues to parent"
- "Link issues as parent/child"
- "Break down issue into sub-tasks"
- "Set up issue hierarchy"
- "Convert checklist to sub-issues"

**Troubleshooting (PR Merge Blocked):**
- "PR can't be merged" / "merge is blocked"
- "unresolved conversations" / "unresolved comments"
- "required reviews not met"
- "CODEOWNERS review required"
- "status checks failed" (for branch protection context)
- `gh pr merge` returns error

**Troubleshooting (Auto-Merge Failures):**
- "auto-merge not working" / "Dependabot PR not merging"
- "Merge method squash merging is not allowed"
- "Merge method merge commit is not allowed"
- "required status check not found"
- "status check name mismatch"
- PRs stuck with auto-merge enabled
- "Protected branch rules not configured" (--auto requires branch protection)
- Merge queue not processing PRs

**Merge Queue Configuration:**
- "set up merge queue"
- "enqueuePullRequest"
- "auto-merge with merge queue"
- "GraphQL merge queue mutation"

**Branch Migration:**
- "rename master to main"
- "change default branch"
- "migrate from master"
- "prevent master branch"
- "block master from being created"

## Installation

### Option 1: Via Netresearch Marketplace (Recommended)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

Then browse skills with `/plugin`.

### Option 2: Download Release

Download the [latest release](https://github.com/netresearch/github-project-skill/releases/latest) and extract to `~/.claude/skills/github-project/`

### Option 3: Manual Installation

Clone or download this repository to your Claude Code skills directory.

## Workflows

### New Repository Setup

To set up a new GitHub repository:

1. Create essential files: README.md, LICENSE, SECURITY.md
2. Configure `.github/` directory structure (see `references/repository-structure.md`)
3. Set up branch protection on `main` branch
4. Configure CODEOWNERS for automatic reviewer assignment
5. Create issue and PR templates
6. Enable Dependabot or Renovate for dependency updates
7. Configure auto-merge workflow for dependency PRs
8. Set up release notes configuration

Run verification: `./scripts/verify-github-project.sh /path/to/repo`

### Branch Configuration

**Required branch settings:**

| Setting | Value | Rationale |
|---------|-------|-----------|
| Default branch name | `main` | Industry standard |
| Default branch protected | ✅ | Prevent direct pushes |
| Allowed merge method | **Rebase only** | Clean linear history |
| Delete branch on merge | ✅ | Keep repo clean |

To configure via GitHub CLI:

```bash
# Ensure default branch is named "main"
gh api repos/{owner}/{repo} --jq '.default_branch'

# Configure merge settings (rebase only, delete on merge)
gh repo edit --enable-rebase-merge --disable-merge-commit --disable-squash-merge --delete-branch-on-merge
```

### Renaming "master" to "main"

For complete migration steps from `master` to `main` as default branch, see `references/branch-migration.md`.

Quick start:
```bash
git branch -m master main
git push -u origin main
gh repo edit --default-branch main
git push origin --delete master
```

### Branch Protection Configuration

To configure branch protection via GitHub CLI:

```bash
# View current protection
gh api repos/{owner}/{repo}/branches/main/protection

# Set branch protection
gh api repos/{owner}/{repo}/branches/main/protection \
  --method PUT \
  -f required_status_checks='{"strict":true,"contexts":["test","lint"]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":true}' \
  -f restrictions=null \
  -f required_conversation_resolution=true
```

**Recommended Settings:**
| Setting | Value | Purpose |
|---------|-------|---------|
| Require pull request | ✅ | Enforce code review |
| Required approvals | 1+ | Based on team size |
| Dismiss stale reviews | ✅ | Re-review after changes |
| Require CODEOWNERS review | ✅ | Domain expert review |
| Require conversation resolution | ✅ | All comments addressed |
| Do not allow force pushes | ✅ | Protect history |
| Allow rebase merge | ✅ | Clean linear history |
| Disable merge commits | ✅ | No merge bubbles |
| Disable squash merge | ✅ | Preserve commit granularity |
| Delete branch on merge | ✅ | Auto-cleanup merged branches |

### PR Comment Resolution Workflow

To enforce PR comment resolution:

1. Enable "Require conversation resolution" in branch protection
2. During review:
   - Reviewers leave line-specific comments
   - Author responds to each comment
   - Author clicks "Resolve conversation" after addressing
3. PR cannot merge until all conversations are resolved
4. Options for each thread:
   - "Resolve conversation" → Mark as addressed
   - Reply with explanation → Then resolve
   - "Won't fix" with reason → Then resolve

### CODEOWNERS Setup

To configure automatic reviewer assignment:

1. Create `.github/CODEOWNERS`
2. Define ownership patterns (last matching pattern wins):

```
# Default owners for everything
* @org/maintainers

# Directory ownership
/src/auth/ @org/security-team
/docs/ @org/docs-team

# File pattern ownership
*.sql @org/dba-team
/.github/ @org/maintainers
```

3. Enable "Require review from CODEOWNERS" in branch protection

### Dependency Auto-Merge Setup

To configure automatic merging of dependency updates:

1. Configure Dependabot or Renovate (see `references/dependency-management.md`)
2. Create auto-merge workflow using appropriate template (see decision matrix below)
3. Workflow auto-approves and merges minor/patch updates
4. Major updates require manual review

**Auto-Merge Decision Matrix:**

| Repository Configuration | Template | Merge Method |
|--------------------------|----------|--------------|
| Merge queue enabled | `auto-merge-queue.yml.template` | GraphQL `enqueuePullRequest` |
| Branch protection (no queue) | `auto-merge.yml.template` | `gh pr merge --auto` |
| No branch protection | `auto-merge-direct.yml.template` | `gh pr merge --rebase` (direct) |

### Merge Queue Auto-Merge Setup

For repositories with merge queues enabled, the `--auto` flag and direct merge commands don't work. Use the GraphQL `enqueuePullRequest` mutation instead.

**Key points:**
- The `mergeMethod` parameter is NOT valid for `enqueuePullRequest` - merge method is set by queue configuration
- Use `github.event.pull_request.node_id` to get the PR's GraphQL node ID
- The mutation adds the PR to the queue; actual merge happens when queue processes it

```yaml
# .github/workflows/auto-merge-deps.yml
name: Auto-merge dependency PRs
on:
  pull_request_target:
    types: [opened, synchronize, reopened]

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]' || github.actor == 'renovate[bot]'
    steps:
      - name: Approve PR
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: gh pr review --approve "$PR_URL"

      - name: Add to merge queue
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_NODE_ID: ${{ github.event.pull_request.node_id }}
        run: |
          gh api graphql -f query='
            mutation($pullRequestId: ID!) {
              enqueuePullRequest(input: {pullRequestId: $pullRequestId}) {
                mergeQueueEntry { id }
              }
            }' -f pullRequestId="$PR_NODE_ID"
```

### Direct Auto-Merge Setup (No Branch Protection)

For repositories without branch protection rules, the `--auto` flag fails with "Protected branch rules not configured". Use direct merge instead:

```yaml
# .github/workflows/auto-merge-deps.yml
- name: Merge PR
  env:
    PR_URL: ${{ github.event.pull_request.html_url }}
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: gh pr merge --rebase "$PR_URL"
```

### Troubleshooting: Auto-Merge Failures

When auto-merge is enabled but PRs aren't merging automatically:

**Step 1: Check repo merge settings vs workflow merge method**
```bash
# View current merge method settings
gh api repos/{owner}/{repo} --jq '{
  allow_squash_merge,
  allow_merge_commit,
  allow_rebase_merge,
  delete_branch_on_merge
}'
```

**Step 2: Identify merge method mismatch**

| Workflow Uses | Repo Setting Required | Error Message |
|---------------|----------------------|---------------|
| `gh pr merge --squash` | `allow_squash_merge: true` | "Merge method squash merging is not allowed" |
| `gh pr merge --merge` | `allow_merge_commit: true` | "Merge method merge commit is not allowed" |
| `gh pr merge --rebase` | `allow_rebase_merge: true` | "Merge method rebase is not allowed" |

**Step 3: Fix merge method alignment**

Either update workflow to match repo settings (`gh pr merge --rebase`) or update repo:
```bash
gh api repos/{owner}/{repo} --method PATCH -f allow_rebase_merge=true
```

**Step 4: Validate required status checks**

Status check names must **exactly match** what workflows produce:
```bash
# Compare expected vs actual check names
gh api repos/{owner}/{repo}/branches/main/protection/required_status_checks --jq '.contexts[]'
gh pr checks <number> --json name --jq '.[].name'
```

**Common status check name mismatches:**

| Expected | Actual | Issue |
|----------|--------|-------|
| `Analyze (javascript-typescript)` | `Analyze (javascript)` | Language detection |
| `build` | `Build / build` | Workflow name prefix |
| `test` | `test (ubuntu-latest, 18)` | Matrix parameters |

**Step 5: Fix and re-trigger**
```bash
# Update branch protection check names
gh api repos/{owner}/{repo}/branches/main/protection/required_status_checks \
  --method PATCH -f strict=true --input - <<< '{"contexts":["actual-check-name"]}'

# Re-trigger stuck PRs
gh pr update-branch <number> --rebase
```

**Auto-merge compatibility checklist:**

| Check | Command | Expected |
|-------|---------|----------|
| Merge method alignment | `gh api repos/{owner}/{repo} --jq '.allow_rebase_merge'` | Matches workflow flag |
| Status checks pass | `gh pr checks <number>` | All green |
| Status check names match | Compare `gh pr checks` vs branch protection | Exact match |
| Reviews complete | `gh pr view <number> --json reviewDecision` | `APPROVED` |
| No merge conflicts | `gh pr view <number> --json mergeable` | `MERGEABLE` |
| Auto-merge enabled | `gh pr view <number> --json autoMergeRequest` | Not null |

### GitHub Discussions Setup

To enable Discussions:

1. Go to **Settings → Features → Discussions**
2. Create categories:
   - 📣 Announcements (maintainers only)
   - 💬 General
   - 💡 Ideas
   - 🙏 Q&A (Question/Answer format)
3. Add Discussions link to issue template chooser

**Use Discussions for:** Questions, ideas, announcements
**Use Issues for:** Bug reports, confirmed features, actionable tasks

### GitHub Releases Configuration

To configure automatic release notes:

1. Create `.github/release.yml`:

```yaml
changelog:
  exclude:
    authors: [dependabot, renovate]
  categories:
    - title: 🚀 Features
      labels: [enhancement]
    - title: 🐛 Bug Fixes
      labels: [bug]
    - title: 📚 Documentation
      labels: [documentation]
```

2. Create releases via CLI:

```bash
gh release create v1.0.0 --generate-notes
```

### Sub-Issues Configuration

GitHub's sub-issues feature enables parent-child relationships between issues (up to 8 levels, 100 sub-issues per parent). For complete GraphQL API reference, see `references/sub-issues.md`.

**Important:** The `gh` CLI does not support sub-issues directly. Use GraphQL API.

Quick reference:
```bash
# Get issue node ID
gh api graphql -f query='{repository(owner:"OWNER",name:"REPO"){issue(number:123){id}}}'

# Add sub-issue (requires node IDs)
gh api graphql -f query='mutation{addSubIssue(input:{issueId:"PARENT_ID",subIssueId:"CHILD_ID"}){issue{number}subIssue{number}}}'

# List sub-issues
gh api graphql -f query='{repository(owner:"OWNER",name:"REPO"){issue(number:123){subIssues(first:50){nodes{number title state}}}}}'
```

### Troubleshooting: PR Merge Blocked

When a PR cannot be merged, diagnose the cause:

**Step 1: Check PR status**
```bash
# View PR details including merge state
gh pr view <number> --json mergeable,mergeStateStatus,reviewDecision,statusCheckRollup

# Check for blocking issues
gh pr checks <number>
```

**Step 2: Identify the blocker**

| Symptom | Cause | Resolution |
|---------|-------|------------|
| `BLOCKED` mergeStateStatus | Unresolved conversations | Resolve all review threads |
| `REVIEW_REQUIRED` reviewDecision | Missing approvals | Request reviews from required reviewers |
| `CHANGES_REQUESTED` reviewDecision | Changes requested | Address feedback, request re-review |
| Failed checks in `statusCheckRollup` | CI/CD failures | Fix failing tests/lints |
| `CODEOWNERS review required` | Missing code owner approval | Get approval from designated owners |

**Step 3: Resolution actions**
```bash
# For unresolved conversations: view and resolve threads
gh pr view <number> --comments

# For missing reviews: request specific reviewers
gh pr edit <number> --add-reviewer username

# For CODEOWNERS blocking: check which files need review
gh pr view <number> --json files
```

**Common `gh pr merge` errors:**

| Error Message | Meaning | Fix |
|---------------|---------|-----|
| `Pull request is not mergeable` | Branch protection blocking | Run diagnosis steps above |
| `Required status check "X" is expected` | CI not run or pending | Wait for CI or trigger manually |
| `At least 1 approving review is required` | No approvals yet | Request and obtain review |
| `Changes were made after the most recent approval` | Stale approval | Request re-review |
| `Protected branch rules not configured` | `--auto` requires branch protection | Use direct merge or enable branch protection |
| `InputObject 'EnqueuePullRequestInput' doesn't accept argument 'mergeMethod'` | Invalid GraphQL parameter | Remove `mergeMethod` from mutation - it's set by queue config |

## Quick CLI Reference

```bash
# Repository
gh repo view
gh repo edit --enable-discussions

# Issues
gh issue list
gh issue create
gh issue edit 123 --add-label "priority: high"

# Pull requests
gh pr list
gh pr create
gh pr review --approve
gh pr merge --squash

# Releases
gh release create v1.0.0 --generate-notes

# Labels
gh label create "name" --color "hex" --description "desc"

# Projects
gh project create --title "Project Name"
```

## Resources

| Resource | Purpose |
|----------|---------|
| `references/repository-structure.md` | Standard files and directory layout |
| `references/dependency-management.md` | Dependabot/Renovate and auto-merge patterns |
| `references/sub-issues.md` | GitHub sub-issues GraphQL API |
| `references/branch-migration.md` | Master to main migration guide |
| `templates/auto-merge.yml.template` | Auto-merge with branch protection (--auto flag) |
| `templates/auto-merge-queue.yml.template` | Auto-merge with merge queue (GraphQL mutation) |
| `templates/auto-merge-direct.yml.template` | Auto-merge without branch protection |
| `scripts/verify-github-project.sh` | Verification script for project setup |

---

**Made with ❤️ for Open Source by [Netresearch](https://www.netresearch.de/)**

## Verification

To check GitHub project configuration:

```bash
./scripts/verify-github-project.sh /path/to/repository
```

Checks: documentation files, CODEOWNERS, dependency management, issue/PR templates, auto-merge workflow, release configuration.
