---
name: typo3-core-contributions
description: "Guide contributors through the complete TYPO3 Core contribution workflow from account setup to patch submission for both code and documentation contributions. Use when working with TYPO3 Forge issues (forge.typo3.org/issues/*), preparing patches for TYPO3 Core, contributing to TYPO3 (code or documentation), submitting patches to Gerrit (review.typo3.org) or GitHub PRs (TYPO3-Documentation/*), fixing TYPO3 bugs, managing WIP state, or debugging CI failures."
---

# TYPO3 Core Contributions

Guide contributors through the complete TYPO3 Core contribution workflow for both code and documentation.

## When to Use This Skill

Activate when:
- User provides a TYPO3 Forge issue URL (e.g., `https://forge.typo3.org/issues/105737`)
- Contributing to TYPO3 Core, submitting patches, or fixing TYPO3 bugs
- Help with Gerrit review workflow, rebasing, or patch updates
- Creating a new Forge issue for a bug or feature
- TYPO3 development environment setup
- TYPO3 commit message format or contribution guidelines

## Scope

| Repository | Submission | Workflow |
|------------|------------|----------|
| Core Code (typo3/typo3) | Gerrit (review.typo3.org) | This skill |
| Core Docs (TYPO3-Documentation/*) | GitHub PRs | This skill |

**Related Skills**:
- `typo3-ddev-skill`: Development environment setup
- `typo3-docs-skill`: Documentation format validation
- `typo3-conformance-skill`: Code quality checks
- `typo3-testing-skill`: Test writing and execution

## Workflow Decision Tree

```
User starts contribution
├─ Has Forge issue URL?
│  ├─ Yes → Prerequisites Check
│  └─ No → Guide to Issue Creation
├─ Prerequisites verified?
│  ├─ Yes → Development Phase
│  └─ No → Setup Phase
├─ Patch ready?
│  ├─ Yes → Submission Phase
│  └─ No → Development Phase
└─ Patch submitted?
   ├─ Yes → Review & Update Phase
   └─ No → Prepare for Gerrit
```

## Prerequisites

Run `scripts/verify-prerequisites.sh` to check:

1. **Accounts**: TYPO3.org, Gerrit SSH, Slack (#typo3-cms-coredev)
2. **Environment**: Git configured, TYPO3 Core cloned, DDEV setup
3. **Git Hooks**: commit-msg, pre-commit installed

**Critical**: Git email MUST match Gerrit email or pushes will be rejected.

## Phase Overview

### Phase 1: Account Setup
- TYPO3.org account → Gerrit SSH → Slack access
- Details: `references/account-setup.md`

### Phase 2: Environment Setup

**Automated (recommended)**:
```bash
./scripts/setup-typo3-coredev.sh
```

**With typo3-ddev-skill**: Use for guided DDEV setup

**Manual**: See `references/ddev-setup-workflow.md`

### Phase 3: Issue Management

**Existing issue**: Fetch from Forge URL, determine commit type
**New issue**: Create at https://forge.typo3.org or via API (`scripts/create-forge-issue.sh`)

### Phase 4: Development

```bash
git checkout main && git pull
git checkout -b feature/105737-fix-description
```

1. Implement fix following TYPO3 patterns
2. Write tests → Use `typo3-testing-skill`
3. Validate quality → Use `typo3-conformance-skill` BEFORE commit
4. Build frontend assets if needed
5. Create changelog if breaking/new feature

### Phase 5: Commit Creation

**Format**:
```
[TYPE] Subject line (max 52 chars, imperative)

Description explaining how and why.

Resolves: #12345
Releases: main, 13.4, 12.4
```

**Types**: `[BUGFIX]`, `[FEATURE]`, `[TASK]`, `[DOCS]`, `[SECURITY]`, `[!!!]` (breaking)

**Required**:
- `Resolves: #<issue>` - Every commit MUST have this
- `Releases: main, 13.4, 12.4` - Target versions
- `Change-Id:` - Auto-generated, never modify

Details: `references/commit-message-format.md`

### Phase 6: Gerrit Submission

```bash
git push origin HEAD:refs/for/main
```

Expected: `remote: https://review.typo3.org/c/Packages/TYPO3.CMS/+/12345 [NEW]`

### Phase 7: Review & Update

**Multiple revisions are NORMAL** - Real patches often have 7-24 patch sets.

When feedback arrives:
```bash
git add .
git commit --amend  # Preserve Change-Id!
git push origin HEAD:refs/for/main
```

**Rebasing**:
- Browser: Click "Rebase" on Gerrit
- CLI: `git fetch origin && git rebase origin/main && git push`

Details: `references/gerrit-workflow.md`, `references/gerrit-review-patterns.md`

### Phase 8: Merge & Completion

After approval (+2 Code Review, +1 Verified):
```bash
git checkout main && git pull
git branch -D feature/105737-fix-description
```

## Common Scenarios

| Scenario | Workflow |
|----------|----------|
| First contribution | Prerequisites → fetch issue → setup → develop → test → validate → commit → submit |
| Update patch | Make changes → typo3-conformance-skill → amend → push |
| Rebase needed | `references/gerrit-workflow.md` |
| CI failures | typo3-conformance-skill (CGL) or typo3-testing-skill (tests) |
| Dual-repo fix | Core via Gerrit + Docs via GitHub PR |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied (push) | Check SSH: `ssh -p 29418 <user>@review.typo3.org` |
| Missing Change-Id | Run `composer gerrit:setup` |
| Merge conflict | See `references/gerrit-workflow.md` |
| CI failing | Use typo3-conformance-skill or typo3-testing-skill |

Full troubleshooting: `references/troubleshooting.md`

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/setup-typo3-coredev.sh` | Complete automated setup |
| `scripts/verify-prerequisites.sh` | Check accounts, git, environment |
| `scripts/create-commit-message.py` | Interactive commit message generator |
| `scripts/validate-commit-message.py` | Validate against TYPO3 format |
| `scripts/create-forge-issue.sh` | Create issues via API |

## References

| Topic | File |
|-------|------|
| Account setup | `references/account-setup.md` |
| DDEV setup workflow | `references/ddev-setup-workflow.md` |
| Commit message format | `references/commit-message-format.md` |
| Commit-msg hook details | `references/commit-msg-hook.md` |
| Gerrit workflow | `references/gerrit-workflow.md` |
| Review patterns | `references/gerrit-review-patterns.md` |
| Forge API | `references/forge-api.md` |
| Troubleshooting | `references/troubleshooting.md` |

## External Resources

- [Contribution Guide](https://docs.typo3.org/m/typo3/guide-contributionworkflow/main/en-us/)
- [Forge](https://forge.typo3.org)
- [Gerrit](https://review.typo3.org)
- [Forger](https://forger.typo3.com)
- [Slack](https://typo3.slack.com) (#typo3-cms-coredev)
