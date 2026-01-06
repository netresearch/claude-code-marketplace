---
name: git-workflow
description: "Agent Skill: Git workflow best practices for teams and CI/CD. Use when establishing branching strategies, implementing Conventional Commits, configuring PRs, or integrating Git with CI/CD. By Netresearch."
---

# Git Workflow Skill

Expert patterns for Git version control: branching, commits, collaboration, and CI/CD.

## Expertise Areas

- **Branching**: Git Flow, GitHub Flow, Trunk-based development
- **Commits**: Conventional Commits, semantic versioning
- **Collaboration**: PR workflows, code review, merge strategies
- **CI/CD**: GitHub Actions, GitLab CI, branch protection

## Reference Files

Detailed documentation for each area:

- `references/branching-strategies.md` - Branch management patterns
- `references/commit-conventions.md` - Commit message standards
- `references/pull-request-workflow.md` - PR and review processes
- `references/ci-cd-integration.md` - Automation patterns
- `references/advanced-git.md` - Advanced Git operations
- `references/github-releases.md` - Release management, immutable releases

## Conventional Commits (Quick Reference)

```
<type>[scope]: <description>
```

**Types**: `feat` (MINOR), `fix` (PATCH), `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Breaking change**: Add `!` after type or `BREAKING CHANGE:` in footer.

## Branch Naming

```bash
feature/TICKET-123-description
fix/TICKET-456-bug-name
release/1.2.0
hotfix/1.2.1-security-patch
```

## GitHub Flow (Default)

```bash
git checkout main && git pull
git checkout -b feature/my-feature
# ... work ...
git push -u origin HEAD
gh pr create && gh pr merge --squash
```

## Verification

```bash
./scripts/verify-git-workflow.sh /path/to/repository
```

## GitHub Immutable Releases

**CRITICAL**: Deleted releases block tag names PERMANENTLY. Get releases right first time.

See `references/github-releases.md` for prevention and recovery patterns.

---

> **Contributing:** https://github.com/netresearch/git-workflow-skill
