# Enterprise Readiness Skill

Netresearch AI skill for assessing and enhancing software projects to meet enterprise-grade standards for security, quality, and automation.

## 🔌 Compatibility

This is an **Agent Skill** following the [open standard](https://agentskills.io) originally developed by Anthropic and released for cross-platform use.

**Supported Platforms:**
- ✅ Claude Code (Anthropic)
- ✅ Cursor
- ✅ GitHub Copilot
- ✅ Other skills-compatible AI agents

> Skills are portable packages of procedural knowledge that work across any AI agent supporting the Agent Skills specification.


## Features

- **OpenSSF Framework Alignment** - Complete coverage across Scorecard, Best Practices Badge (Passing/Silver/Gold), SLSA, and S2C2F
- **Dynamic Scoring** - Fair cross-stack assessment with platform/language-specific criteria
- **Supply Chain Security** - SLSA provenance, artifact signing, SBOM generation, dependency scanning
- **Quality Gates** - Testing layers, coverage thresholds, static analysis, secret scanning
- **Automation Scripts** - Ready-to-use scripts for security hardening and compliance checks
- **Badge Progression** - Guided path from Passing → Silver → Gold certification

## Installation

### Option 1: Via Netresearch Marketplace (Recommended)

```bash
claude mcp add-json netresearch-skills-bundle '{"type":"url","url":"https://raw.githubusercontent.com/netresearch/claude-code-marketplace/main/.claude-plugin/marketplace.json"}'
```

Then browse skills with `/plugin`.

### Option 2: Download Release

Download the [latest release](https://github.com/netresearch/enterprise-readiness-skill/releases/latest) and extract to `~/.claude/skills/enterprise-readiness/`

### Option 3: Composer (PHP projects)

```bash
composer require netresearch/agent-enterprise-readiness
```

**Requires:** [netresearch/composer-agent-skill-plugin](https://github.com/netresearch/composer-agent-skill-plugin)

## Usage

The skill triggers on keywords like:
- "enterprise readiness", "production ready"
- "OpenSSF", "security scorecard", "best practices badge"
- "SLSA", "supply chain security", "SBOM"
- "quality gates", "CI/CD hardening"

### Example Prompts

```
"Assess this project for enterprise readiness"
"What's needed for OpenSSF Best Practices Silver badge?"
"Help me reach SLSA Level 2"
"Set up supply chain security for this Go project"
```

## Structure

```
enterprise-readiness/
├── SKILL.md              # AI instructions
├── README.md             # This file
├── LICENSE               # MIT license
├── composer.json         # PHP distribution
├── references/           # OpenSSF criteria documentation
│   ├── general.md        # Universal checks (60 points)
│   ├── github.md         # GitHub-specific (40 points)
│   ├── go.md             # Go-specific (20 points)
│   ├── openssf-badge-silver.md
│   └── openssf-badge-gold.md
├── scripts/              # Automation scripts
│   ├── check-*.sh        # Validation scripts
│   └── setup-*.sh        # Configuration scripts
└── assets/               # Templates and configs
    └── templates/        # CI/CD, SBOM, policy templates
```

## Contributing

Contributions welcome! Please submit PRs for:
- Additional platform support (GitLab, Bitbucket)
- New language-specific checks
- Script improvements
- Documentation updates

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

Developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/).

---

**Made with ❤️ for Open Source by [Netresearch](https://www.netresearch.de/)**
