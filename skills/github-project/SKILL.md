---
name: github-project
description: "GitHub repository setup and platform-specific features. Use when creating new GitHub repositories, configuring branch protection rules, setting up GitHub Issues/Discussions/Projects, creating sub-issues, managing PR review workflows, configuring Dependabot/Renovate auto-merge, or setting up merge queues. By Netresearch."
---

# GitHub Project Skill

## When to Use

- Creating a new GitHub repository
- Configuring branch protection rules
- Setting up GitHub Issues/Discussions/Projects
- Creating sub-issues and issue hierarchies
- Managing PR review workflows
- Configuring Dependabot/Renovate auto-merge
- Setting up merge queues
- Resolving PR merge blockers

## Scope

**This Skill:** Branch protection, CODEOWNERS, Issues, Discussions, Projects, auto-merge, releases

**Delegate To:**
- CI/CD pipelines → `go-development`, `php-modernization`, `typo3-testing`
- Security scanning → `security-audit`
- Supply chain → `enterprise-readiness`
- Git workflows → `git-workflow`

## References

| Reference | Purpose |
|-----------|---------|
| `references/repository-structure.md` | Standard files and directory layout |
| `references/dependency-management.md` | Dependabot/Renovate auto-merge patterns |
| `references/sub-issues.md` | Sub-issues GraphQL API |
| `references/branch-migration.md` | Master to main migration |

## Templates

| Template | Purpose |
|----------|---------|
| `templates/auto-merge.yml.template` | Auto-merge with branch protection |
| `templates/auto-merge-queue.yml.template` | Auto-merge with merge queue (GraphQL) |
| `templates/auto-merge-direct.yml.template` | Auto-merge without branch protection |
| `templates/CODEOWNERS.template` | Code ownership patterns |
| `templates/dependabot.yml.template` | Dependabot configuration |

## Quick CLI Reference

```bash
# Branch settings
gh repo edit --enable-rebase-merge --disable-merge-commit --disable-squash-merge --delete-branch-on-merge

# Branch protection
gh api repos/{owner}/{repo}/branches/main/protection

# PR workflow
gh pr review --approve
gh pr merge --rebase

# Releases
gh release create v1.0.0 --generate-notes
```

## Critical: Review Thread Resolution

The `gh` CLI cannot resolve review threads. Use GraphQL:

```bash
# Get thread IDs
gh api graphql -f query='{repository(owner:"OWNER",name:"REPO"){pullRequest(number:N){reviewThreads(first:50){nodes{id isResolved}}}}}'

# Resolve thread
gh api graphql -f query='mutation{resolveReviewThread(input:{threadId:"PRRT_xxx"}){thread{isResolved}}}'
```

## Auto-Merge Decision Matrix

| Configuration | Template | Method |
|---------------|----------|--------|
| Merge queue enabled | `auto-merge-queue.yml.template` | GraphQL `enqueuePullRequest` |
| Branch protection | `auto-merge.yml.template` | `gh pr merge --auto` |
| No branch protection | `auto-merge-direct.yml.template` | `gh pr merge --rebase` |

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Protected branch rules not configured" | `--auto` requires branch protection | Use direct merge template |
| "mergeMethod" invalid for enqueuePullRequest | Queue config sets merge method | Remove mergeMethod param |
| "Merge method X is not allowed" | Repo settings mismatch | Align workflow with repo settings |

## Verification

```bash
./scripts/verify-github-project.sh /path/to/repo
```

Checks: documentation, CODEOWNERS, dependency management, templates, auto-merge workflow, release configuration.
