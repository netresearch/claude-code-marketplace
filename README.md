<!-- SPDX-License-Identifier: MIT -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# Netresearch Agentic Skills Marketplace

> **You ship code. Your agent should know your stack.**

40 curated catalog entries for TYPO3, PHP, Go, Docker, Jira, security, and documentation. Each entry points to a source package; some packages contain several Agent Skills. Instructions follow the Agent Skills format, while tools and client-specific components depend on the package and installer.

[![Marketplace site](https://img.shields.io/badge/marketplace-netresearch.github.io-2F99A4)](https://netresearch.github.io/claude-code-marketplace/)
[![Catalog entries](https://img.shields.io/badge/catalog_entries-40-2F99A4)](https://netresearch.github.io/claude-code-marketplace/en/#skills)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/netresearch/claude-code-marketplace/badge)](https://scorecard.dev/viewer/?uri=github.com/netresearch/claude-code-marketplace)

**Browse the full catalog →** [netresearch.github.io/claude-code-marketplace](https://netresearch.github.io/claude-code-marketplace/) — per-skill detail pages, grouped by stack and category, in English and German.

## What are Agentic Skills?

**Agentic Skills** are portable packages of procedural knowledge that work across any AI coding agent supporting the [Agent Skills specification](https://agentskills.io).

Source packages may include several skills and additional components such as hooks or commands. [Agent Plugins](https://agent-plugins.org) standardizes portable packaging; component support and installation remain client-specific. The per-package detail pages link to the source README and explain available installation routes.

**Supported Platforms:**
- Claude Code (Anthropic)
- Cursor
- GitHub Copilot
- OpenAI Codex
- Gemini CLI
- Amp, Goose, Roo Code, OpenCode, and [30+ more](https://agentskills.io)

## Installation

### Claude Code (Marketplace)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
/plugin install typo3-conformance@netresearch-claude-code-marketplace
```

The first command registers the catalog; the second installs one example plugin. Use `/plugin` to browse and choose other packages. Adding the marketplace does not install all entries.

### ChatGPT workspace (GitHub marketplace sync)

Workspace admins can import `https://github.com/netresearch/claude-code-marketplace` under **Admin > Plugins > Add > Import marketplace**. Leave **Path** empty and select **main** to follow catalog updates. After merging a catalog update, choose **Sync now** under **Plugins > Marketplaces** to request an import without waiting for the daily sync.

The native catalog is [`.agents/plugins/marketplace.json`](.agents/plugins/marketplace.json). It references the same source repositories using ChatGPT-supported URL sources; the Claude catalog remains available for Claude Code. The GitHub account authorizing import must be able to read every referenced repository. Review the per-plugin import results and configure workspace installation policies after import. See the [official workspace import documentation](https://learn.chatgpt.com/docs/enterprise/plugin-management#supported-formats).

ChatGPT requires each catalog entry name to match the referenced plugin manifest. The generator maps `jira-integration` to the package name `jira` and `orocommerce` to `orocommerce-skills`. The Claude catalog and website keep their established IDs.

### npx (Skill Instructions)

```bash
npx skills add https://github.com/netresearch/{repo-name} --skill {skill-name}
```

Browse all skills at [skills.sh/netresearch](https://skills.sh/netresearch).

Use a skill name from the source repository, which can differ from its catalog entry ID. For example, the Jira package contains `jira-communication` and `jira-syntax`; OroCommerce contains multiple `oro-*` skills. The [skills CLI installation guide](https://github.com/vercel-labs/skills#install-a-skill) currently requires Node.js 22.20+.

A skill-only installer does not install a plugin's extra hooks or commands, and registration does not set up external runtime tools. Check the package's detail page and source installation guide. Composer skill registration uses the [Composer skill installer](https://github.com/netresearch/composer-agent-skill-plugin); an engine-only installation may deliberately disable it. Package availability and direct-source setup differ by entry.

## Available Skills

### Skill-skills

A small family of skills whose subject matter is other skills. At the center runs a loop — Harness, Assessment, Retro — and around it sit authoring tools that feed the loop.

| Skill | Repository | Description |
|-------|-----------|-------------|
| agent-harness | [agent-harness-skill](https://github.com/netresearch/agent-harness-skill) | Agent Skill for bootstrapping, verifying, and enforcing agent-harness infrastructure in repositories |
| automated-assessment | [automated-assessment-skill](https://github.com/netresearch/automated-assessment-skill) | Systematic project assessment with scripted + LLM verification |
| retro | [retro-skill](https://github.com/netresearch/retro-skill) | LLM-driven session retrospection: detects friction and materializes learnings into user memory, project rules, skill PRs, checkpoints, or harness artifacts. Includes `/retro outcome` and `/retro audit` modes |
| agent-rules | [agent-rules-skill](https://github.com/netresearch/agent-rules-skill) | Generate AGENTS.md with CI rules, architecture, ADRs extraction |
| skill-repo | [skill-repo-skill](https://github.com/netresearch/skill-repo-skill) | Skill repository structure, validation, and distribution |

Host-side tooling (not Agent Skills themselves, but part of the same family):

- [composer-agent-skill-plugin](https://github.com/netresearch/composer-agent-skill-plugin) — Composer plugin that pulls Agent Skills into PHP projects.
- [node-agent-skill-coordinator](https://github.com/netresearch/node-agent-skill-coordinator) — Discovers skills shipped via npm packages and registers them in the project's `AGENTS.md`.

### TYPO3 Development

| Skill | Repository | Description |
|-------|-----------|-------------|
| typo3-conformance | [typo3-conformance-skill](https://github.com/netresearch/typo3-conformance-skill) | Evaluate TYPO3 extension quality and standards compliance |
| typo3-site-conformance | [typo3-site-conformance-skill](https://github.com/netresearch/typo3-site-conformance-skill) | Conformance for deployable TYPO3 site/project repos (containers / CI / supply-chain / secrets) |
| typo3-testing | [typo3-testing-skill](https://github.com/netresearch/typo3-testing-skill) | Test infrastructure: unit, functional, E2E, architecture, mutation |
| typo3-docs | [typo3-docs-skill](https://github.com/netresearch/typo3-docs-skill) | Create and maintain TYPO3 extension documentation for docs.typo3.org |
| typo3-ddev | [typo3-ddev-skill](https://github.com/netresearch/typo3-ddev-skill) | DDEV environment setup for TYPO3 extension development |
| typo3-extension-upgrade | [typo3-extension-upgrade-skill](https://github.com/netresearch/typo3-extension-upgrade-skill) | Systematic extension upgrades to newer LTS versions |
| typo3-project-upgrade | [typo3-project-upgrade-skill](https://github.com/netresearch/typo3-project-upgrade-skill) | TYPO3 project instance upgrades across major LTS versions |
| typo3-ckeditor5 | [typo3-ckeditor5-skill](https://github.com/netresearch/typo3-ckeditor5-skill) | CKEditor 5 plugin development for TYPO3 v12+ |
| typo3-core-contributions | [typo3-core-contributions-skill](https://github.com/netresearch/typo3-core-contributions-skill) | Guide TYPO3 core contributions via Gerrit |
| typo3-typoscript-ref | [typo3-typoscript-ref-skill](https://github.com/netresearch/typo3-typoscript-ref-skill) | Version-aware TypoScript, TSconfig, and Fluid reference lookup |
| typo3-a11y | [typo3-a11y-skill](https://github.com/netresearch/typo3-a11y-skill) | WCAG 2.2 AA accessibility patterns for TYPO3 sitepackages |
| typo3-vite | [typo3-vite-skill](https://github.com/netresearch/typo3-vite-skill) | Vite build setup, SCSS architecture, Bootstrap 5 theming |
| typo3-upgrade-effort-model | [typo3-upgrade-effort-model-skill](https://github.com/netresearch/typo3-upgrade-effort-model-skill) | TYPO3 LTS upgrade effort model: risk multipliers, baselines, version compatibility, Rector coverage, 7-phase workflow |

### OroCommerce

| Skill | Repository | Description |
|-------|-----------|-------------|
| orocommerce | [orocommerce-skill](https://github.com/netresearch/orocommerce-skill) | Fourteen OroCommerce 6.1 skills covering development, integration, security, Behat, functional tests and performance tests |

### Code Quality & Security

| Skill | Repository | Description |
|-------|-----------|-------------|
| php-modernization | [php-modernization-skill](https://github.com/netresearch/php-modernization-skill) | PHP 8.x modernization: type safety, enums, DTOs, PHPStan, Rector |
| php-structured-edit | [php-ast-edit-skill](https://github.com/netresearch/php-ast-edit-skill) | Select PHP symbols, apply typed edits in guarded batches, and review the diff; project tests remain necessary |
| security-audit | [security-audit-skill](https://github.com/netresearch/security-audit-skill) | OWASP security audit patterns for PHP applications |
| enterprise-readiness | [enterprise-readiness-skill](https://github.com/netresearch/enterprise-readiness-skill) | Supply chain security, SLSA, OpenSSF, SBOMs, quality gates |

### DevOps & Infrastructure

| Skill | Repository | Description |
|-------|-----------|-------------|
| docker-development | [docker-development-skill](https://github.com/netresearch/docker-development-skill) | Dockerfile, docker-compose, multi-stage builds, CI patterns |
| concourse-ci | [concourse-ci-skill](https://github.com/netresearch/concourse-ci-skill) | Concourse CI pipeline development and optimization |
| go-development | [go-development-skill](https://github.com/netresearch/go-development-skill) | Production-grade Go patterns: testing, Docker, LDAP, resilience |
| git-workflow | [git-workflow-skill](https://github.com/netresearch/git-workflow-skill) | Branching strategies, Conventional Commits, PR workflows |
| github-project | [github-project-skill](https://github.com/netresearch/github-project-skill) | GitHub repo setup: branch protection, CODEOWNERS, auto-merge |
| github-release | [github-release-skill](https://github.com/netresearch/github-release-skill) | Safe, automated GitHub releases with supply chain security. Prevents dangerous gh release commands, orchestrates version bumps, signed tags, and CI-driven releases across ecosystems. |
| jujutsu-workflow | [jujutsu-workflow-skill](https://github.com/netresearch/jujutsu-workflow-skill) | Local change management with Jujutsu (jj), reversible history and a Git-based handoff to reviews and CI |

### Productivity & Integration

| Skill | Repository | Description |
|-------|-----------|-------------|
| jira-integration | [jira-skill](https://github.com/netresearch/jira-skill) | Jira API operations and wiki markup (two sub-skills) |
| matrix-communication | [matrix-skill](https://github.com/netresearch/matrix-skill) | Separate skills for Matrix chat, Synapse administration and announcement composition; component coverage varies by installer |
| cli-tools | [coding_agent_cli_toolset](https://github.com/netresearch/coding_agent_cli_toolset) | Auto-install missing CLI tools (100+ tool catalog) |
| context7 | [context7-skill](https://github.com/netresearch/context7-skill) | Library documentation lookup via Context7 REST API |
| data-tools | [data-tools-skill](https://github.com/netresearch/data-tools-skill) | Structured data manipulation with jq, yq, dasel, qsv |
| file-search | [file-search-skill](https://github.com/netresearch/file-search-skill) | Efficient code search with ripgrep, ast-grep, fd |
| german-technical-writing | [german-technical-writing-skill](https://github.com/netresearch/german-technical-writing-skill) | Natural German technical register for Jira, internal docs, team chat — catches anglicisms, enforces lexicon |
| peer-qa-review | [peer-qa-review-skill](https://github.com/netresearch/peer-qa-review-skill) | Round-1 IT QA peer-review runbook: lifecycle, severity vocabulary, structured Jira comment template, edge cases, anti-patterns |
| markdown-to-pdf | [markdown-to-pdf-skill](https://github.com/netresearch/markdown-to-pdf-skill) | Convert Markdown files to styled PDFs via WeasyPrint; CSS-overridable for branded output |

### Brand & visual identity

| Skill | Repository | Description |
|-------|-----------|-------------|
| netresearch-branding | [netresearch-branding-skill](https://github.com/netresearch/netresearch-branding-skill) | Netresearch brand guidelines: colors, typography, components |

## Architecture

This marketplace uses **source references**: `marketplace.json` points to source package repositories. Claude Code fetches a selected plugin from its source repository when installed. A plugin can contain several skills and additional components.

The GitHub Pages site is built from [`site/`](site/README.md); the design decisions behind it are recorded as [ADRs in `docs/decisions/`](docs/decisions/README.md).

## Adding a Skill

Add an entry to `.claude-plugin/marketplace.json` (the canonical catalog):

```json
{
  "name": "my-skill",
  "description": "What it does and when to use it",
  "source": {
    "source": "github",
    "repo": "netresearch/my-skill-repo"
  },
  "category": "development"
}
```

Regenerate the ChatGPT/Codex catalog, then validate both catalogs:

```bash
./scripts/sync-codex-marketplace.sh
./scripts/validate.sh
```

Commit both manifest files. The validator checks that the native catalog matches the canonical catalog after applying the documented package-name aliases, including categories, repository URLs and any source revision pins. Generation fails if aliases produce duplicate native plugin names.

## Internal Marketplace

Netresearch also maintains an internal marketplace for proprietary skills:

```bash
/plugin marketplace add git@git.netresearch.de:coding-ai/marketplace.git
```

## Organization sync

The private copy `netresearch/claude-code-marketplace-P` feeds the Claude organization marketplace. A workflow force-pushes this repository's `main` there after every push, and an update of its `main` may start an organization plugin sync. The catalog carries no `version` fields, so each sync resolves every plugin to the current commit of its source.

## Discover

Browse the full catalog with per-skill detail pages on the marketplace website:

**[netresearch.github.io/claude-code-marketplace](https://netresearch.github.io/claude-code-marketplace/)** — DE + EN, canonical landing per skill, grouped by stack and category.

## Governance and policies

This repository follows the organisation-wide policies of `netresearch`:

- [Governance](https://github.com/netresearch/.github/blob/main/GOVERNANCE.md): roles, how changes are decided and disputes resolved, and who controls access to sensitive resources.
- [Roadmap](https://github.com/netresearch/.github/blob/main/ROADMAP.md): the maintenance work planned and excluded for the coming year.
- [Handling of dependency and code analysis findings](https://github.com/netresearch/.github/blob/main/SECURITY.md#handling-of-dependency-and-code-analysis-findings): which vulnerability, licence and static-analysis findings block a change, the deadlines for the others, and how exceptions are recorded.
- [Secret management](https://github.com/netresearch/.github/blob/main/SECURITY.md#secret-management): where CI secrets are stored, who can access them, and when they are rotated.
- [Access roster](https://github.com/netresearch/.github/blob/main/docs/access-roster.md): the accounts with admin, maintain and write access to this repository.

Checks that run on every pull request to `main`:

- Dependency review (`.github/workflows/security.yml`): fails on a known vulnerability of severity high or critical in a dependency the pull request adds or changes.
- Betterleaks (`.github/workflows/security.yml`): scans the Git history and fails on a committed secret.
- CodeQL (`.github/workflows/codeql.yml`): static security analysis of the GitHub Actions workflows, the JavaScript of `site/` and the Python in `scripts/`; results go to code scanning.
- DCO (`.github/workflows/dco.yml`): every commit carries a `Signed-off-by` line.
- Site build (`.github/workflows/pages.yml`): installs `site/` with `npm ci --ignore-scripts`, runs the catalogue checks and the unit tests (`npm run check`), builds the site and checks the language pairs; Lighthouse and Playwright visual regression then test the built site.

`scripts/validate.sh` and the advisory overlap report (`.github/workflows/validate.yml`) run on pull requests that change either marketplace manifest, the validation, catalog generation or overlap-report scripts, or that workflow. The pre-commit hook (`.githooks/pre-commit`, enabled by `.envrc`) runs `scripts/validate.sh`.

A ruleset on `main` requires the DCO check, and branch protection of `main` requires signed commits. The other checks run on every pull request but are not required checks.

What you can and cannot expect from this repository in terms of security, with its threat model: [docs/SECURITY-ASSURANCE.md](docs/SECURITY-ASSURANCE.md).

---

**Maintained by:** [Netresearch DTT GmbH](https://www.netresearch.de), Leipzig
