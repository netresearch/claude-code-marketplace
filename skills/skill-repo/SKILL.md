---
name: skill-repo
description: "Agent Skill: Guide for structuring Netresearch skill repositories. Use when creating new skills, standardizing existing skill repos, setting up composer distribution, or creating release workflows. Extends Anthropic's skill-creator with Netresearch-specific repository layout, multi-channel distribution (marketplace, releases, composer), and PHP ecosystem integration. By Netresearch."
---

# Skill Repository Structure Guide

Standards for Netresearch skill repository layout, distribution, and packaging.

## When to Use This Skill

Use when:
- Creating a new skill repository
- Standardizing an existing skill repo
- Adding composer.json for PHP distribution
- Setting up release workflows
- Validating skill repository structure

## Repository Structure

```
{skill-name}/
├── SKILL.md              # AI instructions (required)
├── README.md             # Human documentation (required)
├── LICENSE               # MIT license (required)
├── composer.json         # PHP distribution (if applicable)
├── references/           # Extended documentation
├── scripts/              # Automation scripts
├── assets/               # Templates, configs
│   └── templates/
└── .github/
    └── workflows/
        └── release.yml   # Release packaging workflow
```

## File Purposes

| File | Audience | Purpose |
|------|----------|---------|
| SKILL.md | AI Agent | Instructions for Claude Code |
| README.md | Humans | Installation, usage, contributing |
| composer.json | PHP devs | Composer package distribution |
| LICENSE | Legal | MIT license |

## SKILL.md Requirements

Follow Anthropic's skill-creator specification:

```yaml
---
name: skill-name          # lowercase, hyphens, max 64 chars
description: "Agent Skill: When to use this skill and what it does. By Netresearch."
---
```

**Rules:**
- Name: `^[a-z0-9-]{1,64}$`
- Description: Max 1024 chars, include "By Netresearch."
- Content: Under 500 lines, use references/ for extended docs

## README.md Template

Use `templates/README.md.template` with these sections:
1. Title and description
2. Features list
3. Installation (3 methods)
4. Usage and triggers
5. Structure overview
6. Contributing
7. License
8. Netresearch credits footer

## Installation Methods

### Method 1: Netresearch Marketplace (Recommended)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

### Method 2: Download Release

Download from GitHub Releases page and extract to `~/.claude/skills/{skill-name}/`

### Method 3: Composer (PHP Projects)

```bash
composer require netresearch/agent-{skill-name}
```

Requires: `netresearch/composer-agent-skill-plugin`

## Composer Package Setup

### When to Include composer.json

Include for ALL skills EXCEPT those explicitly targeting non-PHP ecosystems (e.g., go-development-skill).

### composer.json Structure

```json
{
  "name": "netresearch/agent-{skill-name}",
  "description": "{skill description}",
  "type": "ai-agent-skill",
  "license": "MIT",
  "authors": [
    {
      "name": "Netresearch DTT GmbH",
      "email": "plugins@netresearch.de",
      "homepage": "https://www.netresearch.de/",
      "role": "Manufacturer"
    }
  ],
  "require": {
    "netresearch/composer-agent-skill-plugin": "*"
  },
  "extra": {
    "ai-agent-skill": "SKILL.md"
  }
}
```

### Multi-Skill Packages

For packages with multiple skills:

```json
{
  "extra": {
    "ai-agent-skill": [
      "skills/skill-one/SKILL.md",
      "skills/skill-two/SKILL.md"
    ]
  }
}
```

## Release Packaging

### Release Contents (Include)

- `SKILL.md`
- `LICENSE`
- `references/`
- `scripts/`
- `assets/`
- `templates/`

### Release Exclusions (Do NOT Include)

- `README.md` (human-facing, not needed in skill package)
- `.github/`
- `.gitignore`
- `composer.json`
- `.editorconfig`
- `phpunit.xml`, `phpstan.neon`
- `claudedocs/`
- Any dev/CI configuration files

### Release Workflow

Use `.github/workflows/release.yml` template to:
1. Trigger on version tags (v*)
2. Package only skill-relevant files
3. Create GitHub release with artifact
4. Optionally notify marketplace

## Validation Checklist

Run `scripts/validate-skill.sh` or manually check:

| Check | Required |
|-------|----------|
| SKILL.md exists | Always |
| SKILL.md has valid frontmatter | Always |
| SKILL.md under 500 lines | Always |
| README.md exists | Always |
| README.md follows template | Always |
| LICENSE file exists | Always |
| composer.json exists | Unless non-PHP skill |
| composer.json has correct type | If exists |
| Netresearch footer in README | Always |
| No composer.lock | Always |

## Workflow

### Creating a New Skill

1. Create repository from template or manually
2. Write SKILL.md with proper frontmatter
3. Create README.md from template
4. Add composer.json (if applicable)
5. Add LICENSE (MIT)
6. Set up release workflow
7. Validate with `scripts/validate-skill.sh`
8. Create initial release

### Updating Existing Skill

1. Ensure README.md follows template
2. Add/update composer.json if missing
3. Verify SKILL.md frontmatter
4. Add release workflow if missing
5. Validate and create new release

## References

- `references/installation-methods.md` - Detailed installation guides
- `references/composer-setup.md` - Composer integration details
- `references/marketplace-integration.md` - Marketplace sync process
- `templates/README.md.template` - README template
- `templates/composer.json.template` - Composer template
- `templates/release.yml.template` - Release workflow template

## Related Skills

- **Anthropic skill-creator** - SKILL.md content creation (this skill extends it)
- **enterprise-readiness-skill** - OpenSSF compliance for skill repos
- **git-workflow-skill** - Git best practices for releases

---

> **Contributing:** Improvements to this skill should be submitted to the source repository:
> https://github.com/netresearch/skill-repo-skill
