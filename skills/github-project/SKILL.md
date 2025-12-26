---
name: github-project
description: "GitHub repository setup and configuration. This skill should be used when creating new GitHub repositories, configuring branch protection or rulesets, setting up CODEOWNERS, or troubleshooting PR merge issues. By Netresearch."
---

# GitHub Project Skill

## Triggers

- Creating a new GitHub repository
- Configuring branch protection rules or rulesets
- Setting up CODEOWNERS
- Troubleshooting "merge is blocked" or "not allowed merge method" errors
- Configuring auto-merge for Dependabot/Renovate

## Usage

For workflows, CLI commands, templates, and troubleshooting guides, see `README.md`.

Key references:
- `references/repository-structure.md` - Standard repo layout
- `references/sub-issues.md` - Sub-issues GraphQL API
- `references/dependency-management.md` - Dependabot/Renovate configuration
- `templates/` - Auto-merge workflow templates

## Go Project CI Checklist

For Go projects, ensure these GitHub configurations:

| Setting | Purpose | How |
|---------|---------|-----|
| Branch protection | Require tests pass before merge | Branch settings or Rulesets |
| Dependabot/Renovate | Automated dependency updates | `.github/dependabot.yml` or `renovate.json` |
| Auto-merge workflow | Merge minor/patch updates automatically | `templates/auto-merge*.yml` |
| Required checks | CI workflow names in branch protection | Match exact workflow job names |

For CI/CD workflow content (test, lint, build), see `go-development` skill.
For security workflows (Scorecard, CodeQL, SLSA), see `enterprise-readiness` skill.

## Related Skills

| Skill | Purpose |
|-------|---------|
| `go-development` | Go code patterns, Makefile interface, testing, linting |
| `enterprise-readiness` | OpenSSF Scorecard, SLSA provenance, signed releases |
| `git-workflow` | Git branching strategies, conventional commits |
| `security-audit` | Deep security audits (OWASP, CVE analysis) |
