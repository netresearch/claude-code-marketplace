# Netresearch Agentic Skills Marketplace

Curated collection of **Agentic Skills** for TYPO3 development, PHP modernization, and technical documentation workflows.

## What are Agentic Skills?

**Agentic Skills** are portable packages of procedural knowledge that work across any AI coding agent supporting the [Agent Skills specification](https://agentskills.io).

**Supported Platforms:**
- Claude Code (Anthropic)
- Cursor
- GitHub Copilot
- Windsurf
- Any agent supporting the Agentic Skills specification

## Installation

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

Then use `/plugin` to browse and install individual plugins.

## Available Plugins

| Plugin | Type | Description |
|--------|------|-------------|
| [enterprise-readiness](https://github.com/netresearch/enterprise-readiness-skill) | Skill | OpenSSF security assessment and compliance |
| [typo3-docs](https://github.com/netresearch/typo3-docs-skill) | Skill | Create TYPO3 extension documentation |
| [typo3-testing](https://github.com/netresearch/typo3-testing-skill) | Skill | Manage TYPO3 extension tests |
| [typo3-ddev](https://github.com/netresearch/typo3-ddev-skill) | Skill | Automate DDEV environment setup |
| [typo3-core-contributions](https://github.com/netresearch/typo3-core-contributions-skill) | Skill | Guide TYPO3 core contributions |
| [typo3-conformance](https://github.com/netresearch/typo3-conformance-skill) | Skill | Evaluate TYPO3 standards compliance |
| [typo3-ckeditor5](https://github.com/netresearch/typo3-ckeditor5-skill) | Skill | CKEditor 5 development for TYPO3 v12+ |
| [typo3-extension-upgrade](https://github.com/netresearch/typo3-extension-upgrade-skill) | Skill | Systematic extension upgrades to newer LTS versions |
| [jira-integration](https://github.com/netresearch/jira-skill) | Skill | Jira API operations and wiki markup |
| [git-workflow](https://github.com/netresearch/git-workflow-skill) | Skill | Git branching strategies and Conventional Commits |
| [github-project](https://github.com/netresearch/github-project-skill) | Skill | GitHub repository setup and platform features |
| [security-audit](https://github.com/netresearch/security-audit-skill) | Skill | OWASP security audit patterns for PHP |
| [php-modernization](https://github.com/netresearch/php-modernization-skill) | Skill | PHP 8.x modernization and type safety |
| [go-development](https://github.com/netresearch/go-development-skill) | Skill | Production-grade Go development patterns |
| [netresearch-branding](https://github.com/netresearch/netresearch-branding-skill) | Skill | Apply Netresearch brand guidelines |
| [agents](https://github.com/netresearch/agents-skill) | Skill | Generate AGENTS.md documentation |
| [cli-tools](https://github.com/netresearch/cli-tools-skill) | Skill | Auto-install missing CLI tools |
| [concourse-ci](https://github.com/netresearch/concourse-ci-skill) | Skill | Concourse CI pipeline development and optimization |
| [docker-development](https://github.com/netresearch/docker-development-skill) | Skill | Docker image development, CI testing patterns |
| [context7](https://github.com/netresearch/context7-skill) | Skill | Library documentation lookup via Context7 REST API |
| [skill-repo](https://github.com/netresearch/skill-repo-skill) | Skill | Guide for structuring skill repositories |
| [coach](https://github.com/netresearch/claude-coach-plugin) | Feature | Self-improving learning system with hooks and commands |

## Architecture

This marketplace uses **source references** - it contains only a `marketplace.json` catalog that points to individual plugin repositories. Claude Code fetches plugins directly from their source repositories when installed.

```
marketplace.json (this repo)
    ↓
Claude Code reads catalog
    ↓
User installs plugin
    ↓
Claude Code fetches from source repo (e.g., netresearch/typo3-docs-skill)
```

**Benefits:**
- Single source of truth - each plugin in its own repository
- No sync workflows needed
- Always fetches latest from source
- Simple maintenance

## Adding a Plugin

To add a new plugin to this marketplace, add an entry to `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-plugin",
  "description": "Plugin description",
  "source": {
    "source": "github",
    "repo": "netresearch/my-plugin-repo"
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
