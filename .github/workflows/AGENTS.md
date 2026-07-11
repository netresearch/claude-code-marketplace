<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: 2026-06-10 -->

# AGENTS.md — .github/workflows/

## Overview

CI for the marketplace: catalog validation, security scanning, and the Pages
build/deploy pipeline. Root [AGENTS.md](../../AGENTS.md) applies on top.

## Workflow files

| File | Purpose |
|------|---------|
| `pages.yml` | Pages pipeline: build → compliance checks → Lighthouse → visual regression → deploy (push to main, PRs, weekly cron, dispatch) |
| `validate.yml` | Marketplace catalog validation (`scripts/validate.sh`) plus an advisory, non-blocking overlap report (`scripts/overlap-report.py`) uploaded as a build artifact |
| `security.yml` | gitleaks secret scanning + dependency review (via `netresearch/.github` reusable workflows); the separate `betterleaks` check comes from GitHub Advanced Security, not this file |

## Commands

| Task | Command |
|------|---------|
| Lint workflows locally | `actionlint .github/workflows/*.yml` |
| Check run annotations | `gh api repos/netresearch/claude-code-marketplace/commits/<SHA>/check-runs --jq '.check_runs[] | select(.output.annotations_count > 0)'` |

## Workflow conventions

- Minimal `permissions:` per job; never `permissions: write-all`.
- Job IDs kebab-case, step names sentence case.
- The deploy job runs only on push to `main`; PR runs build and gates only.

## Security

- **Pin third-party actions by full commit SHA** with a `# vX.Y.Z` comment.
  Verify the latest release via the API before pinning
  (`gh api repos/OWNER/ACTION/releases/latest`) — never copy SHAs from memory
  or other files.
- First-party `netresearch/*` reusable workflows are referenced `@main`,
  never SHA-pinned.
- Never `secrets: inherit` when calling reusable workflows — pass each secret
  explicitly by name.

## Examples

- Good: `uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5.0.5`
- Bad: `uses: actions/cache@v5` (mutable tag, supply-chain risk)
- Bad: `uses: netresearch/some-workflow@<sha>` (first-party is `@main`)

## Checklist (before PR)

1. `actionlint` clean on changed files.
2. New/updated third-party actions: latest version confirmed via API, SHA
   valid, `# vX.Y.Z` comment matches.
3. Quality gates stay blocking — never add `continue-on-error` to get green.
4. Workflow-file PRs cannot be auto-merged by bots (`GITHUB_TOKEN` lacks the
   `workflows` scope) — plan a manual merge.

## When stuck

- Site build steps mirror local commands: [../../site/AGENTS.md](../../site/AGENTS.md).
- Marketplace validation rules: [../../AGENTS.md](../../AGENTS.md).
- Check the job's Annotations tab — runs can pass while emitting warnings.
