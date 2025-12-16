# Installation Methods

Three methods for installing Netresearch skills.

## Method 1: Netresearch Marketplace (Recommended)

The marketplace aggregates all Netresearch skills in one place.

### Setup

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

### Usage

```bash
# Browse available plugins
/plugin

# Install specific skill
/plugin install {skill-name}
```

### Benefits

- Curated collection
- Automatic updates via sync
- Easy discovery
- No manual file management

## Method 2: Download Release

Download packaged skill files from GitHub Releases.

### Steps

1. Go to skill's GitHub repository
2. Navigate to Releases page
3. Download latest `.zip` or `.tar.gz`
4. Extract to `~/.claude/skills/{skill-name}/`

### Package Contents

Release packages contain only skill-relevant files:
- `SKILL.md`
- `LICENSE`
- `references/`
- `scripts/`
- `assets/`
- `templates/`

### Excluded from Packages

- `README.md` (human documentation)
- `.github/` (CI/CD)
- `composer.json` (separate distribution)
- Dev configuration files

## Method 3: Composer (PHP Projects)

For PHP projects, install skills as Composer packages.

### Prerequisites

1. PHP 8.2+
2. Composer 2.1+
3. [composer-agent-skill-plugin](https://github.com/netresearch/composer-agent-skill-plugin)

### Installation

```bash
# Install the plugin first (once per project)
composer require netresearch/composer-agent-skill-plugin

# Install skills
composer require netresearch/agent-{skill-name}
```

### How It Works

1. Plugin discovers packages with type `ai-agent-skill`
2. Generates `AGENTS.md` index in project root
3. Skills available via `composer read-skill {name}`

### Benefits

- Version management via Composer
- Dependency resolution
- Project-specific skill sets
- Easy updates with `composer update`

## Choosing a Method

| Scenario | Recommended Method |
|----------|-------------------|
| General Claude Code use | Marketplace |
| Offline/air-gapped | Release download |
| PHP project | Composer |
| CI/CD automation | Composer |
| Quick trial | Marketplace |

## Directory Locations

| Method | Location |
|--------|----------|
| Marketplace | Managed by Claude Code |
| Release | `~/.claude/skills/{skill-name}/` |
| Composer | `vendor/netresearch/agent-{skill-name}/` |
