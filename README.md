# Netresearch Agentic Skills Marketplace

Curated collection of **Agentic Skills** for AI coding agents — TYPO3, PHP, Go, Docker, Jira, security, documentation, and more.

## What are Agentic Skills?

**Agentic Skills** are portable packages of procedural knowledge that work across any AI coding agent supporting the [Agent Skills specification](https://agentskills.io).

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
```

Then use `/plugin` to browse and install individual skills.

### npx (Any Agent)

```bash
npx skills add https://github.com/netresearch/{repo-name} --skill {skill-name}
```

Browse all skills at [skills.sh/netresearch](https://skills.sh/netresearch).

## Available Skills

### TYPO3 Development

| Skill | Repository | Description |
|-------|-----------|-------------|
| typo3-conformance | [typo3-conformance-skill](https://github.com/netresearch/typo3-conformance-skill) | Evaluate TYPO3 extension quality and standards compliance |
| typo3-testing | [typo3-testing-skill](https://github.com/netresearch/typo3-testing-skill) | Test infrastructure: unit, functional, E2E, architecture, mutation |
| typo3-docs | [typo3-docs-skill](https://github.com/netresearch/typo3-docs-skill) | Create and maintain TYPO3 extension documentation for docs.typo3.org |
| typo3-ddev | [typo3-ddev-skill](https://github.com/netresearch/typo3-ddev-skill) | DDEV environment setup for TYPO3 extension development |
| typo3-extension-upgrade | [typo3-extension-upgrade-skill](https://github.com/netresearch/typo3-extension-upgrade-skill) | Systematic extension upgrades to newer LTS versions |
| typo3-project-upgrade | [typo3-project-upgrade-skill](https://github.com/netresearch/typo3-project-upgrade-skill) | TYPO3 project instance upgrades across major LTS versions |
| typo3-ckeditor5 | [typo3-ckeditor5-skill](https://github.com/netresearch/typo3-ckeditor5-skill) | CKEditor 5 plugin development for TYPO3 v12+ |
| typo3-core-contributions | [typo3-core-contributions-skill](https://github.com/netresearch/typo3-core-contributions-skill) | Guide TYPO3 core contributions via Gerrit |
| typo3-typoscript-ref | [typo3-typoscript-ref-skill](https://github.com/netresearch/typo3-typoscript-ref-skill) | Version-aware TypoScript, TSconfig, and Fluid reference lookup |
| typo3-a11y | [typo3-a11y-skill](https://github.com/netresearch/typo3-a11y-skill) | WCAG 2.1 AA accessibility patterns for TYPO3 projects |
| typo3-frontend-patterns | [typo3-frontend-patterns-skill](https://github.com/netresearch/typo3-frontend-patterns-skill) | Reusable frontend patterns (sticky header, breadcrumb, lazy loading) |
| typo3-vite | [typo3-vite-skill](https://github.com/netresearch/typo3-vite-skill) | Vite build setup, SCSS architecture, Bootstrap 5 theming |

### Code Quality & Security

| Skill | Repository | Description |
|-------|-----------|-------------|
| php-modernization | [php-modernization-skill](https://github.com/netresearch/php-modernization-skill) | PHP 8.x modernization: type safety, enums, DTOs, PHPStan, Rector |
| security-audit | [security-audit-skill](https://github.com/netresearch/security-audit-skill) | OWASP security audit patterns for PHP applications |
| enterprise-readiness | [enterprise-readiness-skill](https://github.com/netresearch/enterprise-readiness-skill) | Supply chain security, SLSA, OpenSSF, SBOMs, quality gates |
| automated-assessment | [automated-assessment-skill](https://github.com/netresearch/automated-assessment-skill) | Systematic project assessment with scripted + LLM verification |

### DevOps & Infrastructure

| Skill | Repository | Description |
|-------|-----------|-------------|
| docker-development | [docker-development-skill](https://github.com/netresearch/docker-development-skill) | Dockerfile, docker-compose, multi-stage builds, CI patterns |
| concourse-ci | [concourse-ci-skill](https://github.com/netresearch/concourse-ci-skill) | Concourse CI pipeline development and optimization |
| go-development | [go-development-skill](https://github.com/netresearch/go-development-skill) | Production-grade Go patterns: testing, Docker, LDAP, resilience |
| git-workflow | [git-workflow-skill](https://github.com/netresearch/git-workflow-skill) | Branching strategies, Conventional Commits, PR workflows |
| github-project | [github-project-skill](https://github.com/netresearch/github-project-skill) | GitHub repo setup: branch protection, CODEOWNERS, auto-merge |
| github-release | [github-release-skill](https://github.com/netresearch/github-release-skill) | Safe, automated GitHub releases with supply chain security. Prevents dangerous gh release commands, orchestrates version bumps, signed tags, and CI-driven releases across ecosystems. |

### Productivity & Integration

| Skill | Repository | Description |
|-------|-----------|-------------|
| agent-rules | [agent-rules-skill](https://github.com/netresearch/agent-rules-skill) | Generate AGENTS.md with CI rules, architecture, ADRs extraction |
| agent-harness | [agent-harness-skill](https://github.com/netresearch/agent-harness-skill) | Agent Skill for bootstrapping, verifying, and enforcing agent-harness infrastructure in repositories |
| jira-integration | [jira-skill](https://github.com/netresearch/jira-skill) | Jira API operations and wiki markup (two sub-skills) |
| matrix-communication | [matrix-skill](https://github.com/netresearch/matrix-skill) | Send messages to Matrix rooms |
| cli-tools | [cli-tools-skill](https://github.com/netresearch/cli-tools-skill) | Auto-install missing CLI tools (74+ tool catalog) |
| context7 | [context7-skill](https://github.com/netresearch/context7-skill) | Library documentation lookup via Context7 REST API |
| data-tools | [data-tools-skill](https://github.com/netresearch/data-tools-skill) | Structured data manipulation with jq, yq, dasel, qsv |
| file-search | [file-search-skill](https://github.com/netresearch/file-search-skill) | Efficient code search with ripgrep, ast-grep, fd |
| pagerangers-seo | [pagerangers-skill](https://github.com/netresearch/pagerangers-skill) | PageRangers SEO API: keyword rankings, SERP analysis |
| coach | [claude-coach-plugin](https://github.com/netresearch/claude-coach-plugin) | Self-improving learning system with hooks and commands |
| german-technical-writing | [german-technical-writing-skill](https://github.com/netresearch/german-technical-writing-skill) | Natural German technical register for Jira, internal docs, team chat — catches anglicisms, enforces lexicon |
| peer-qa-review | [peer-qa-review-skill](https://github.com/netresearch/peer-qa-review-skill) | Round-1 IT QA peer-review runbook: lifecycle, severity vocabulary, structured Jira comment template, edge cases, anti-patterns |

### Meta

| Skill | Repository | Description |
|-------|-----------|-------------|
| skill-repo | [skill-repo-skill](https://github.com/netresearch/skill-repo-skill) | Skill repository structure, validation, and distribution |
| netresearch-branding | [netresearch-branding-skill](https://github.com/netresearch/netresearch-branding-skill) | Netresearch brand guidelines: colors, typography, components |

## Architecture

This marketplace uses **source references** — it contains only a `marketplace.json` catalog that points to individual skill repositories. Claude Code fetches skills directly from their source repos when installed.

## Adding a Skill

Add an entry to `.claude-plugin/marketplace.json`:

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

## Internal Marketplace

Netresearch also maintains an internal marketplace for proprietary skills:

```bash
/plugin marketplace add git@git.netresearch.de:coding-ai/marketplace.git
```

---

**Maintained by:** [Netresearch DTT GmbH](https://www.netresearch.de), Leipzig
