# Composer Setup for Skills

Guide for adding Composer distribution to Netresearch skills.

## When to Add composer.json

Add `composer.json` to ALL skills **EXCEPT** those explicitly targeting non-PHP ecosystems.

| Skill Type | composer.json |
|------------|---------------|
| PHP/TYPO3 skills | ✅ Required |
| General skills | ✅ Required |
| Go-specific skills | ❌ Not needed |
| Rust-specific skills | ❌ Not needed |

## composer.json Structure

### Basic Structure

```json
{
  "name": "netresearch/agent-{skill-name}",
  "description": "{Skill description from SKILL.md}",
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

### Key Fields

| Field | Value | Purpose |
|-------|-------|---------|
| `name` | `netresearch/agent-{skill-name}` | Package identifier |
| `type` | `ai-agent-skill` | Enables plugin discovery |
| `require` | `composer-agent-skill-plugin` | Plugin dependency |
| `extra.ai-agent-skill` | Path to SKILL.md | Skill location |

### Package Naming Convention

- Prefix: `netresearch/agent-`
- Suffix: skill name without `-skill` suffix
- Examples:
  - `typo3-docs-skill` → `netresearch/agent-typo3-docs`
  - `enterprise-readiness-skill` → `netresearch/agent-enterprise-readiness`

## Multi-Skill Packages

For packages containing multiple skills:

```json
{
  "name": "netresearch/agent-{package-name}",
  "type": "ai-agent-skill",
  "extra": {
    "ai-agent-skill": [
      "skills/skill-one/SKILL.md",
      "skills/skill-two/SKILL.md"
    ]
  }
}
```

### Example: jira-skill

```json
{
  "name": "netresearch/agent-jira-skill",
  "extra": {
    "ai-agent-skill": [
      "skills/jira-communication/SKILL.md",
      "skills/jira-syntax/SKILL.md"
    ]
  }
}
```

## Publishing to Packagist

### Prerequisites

1. GitHub repository is public
2. composer.json is valid
3. Packagist account linked to GitHub

### Steps

1. Create version tag:
   ```bash
   git tag v1.0.0
   git push --tags
   ```

2. Register on Packagist:
   - Go to https://packagist.org/packages/submit
   - Enter repository URL
   - Submit

3. Enable auto-update:
   - Configure GitHub webhook for Packagist
   - Or use GitHub Actions integration

## Files to NOT Include

**Never add these to skill repos:**

- `composer.lock` - Locks are for applications, not libraries
- `vendor/` - Dependencies installed by users

## Validation

Check composer.json validity:

```bash
# Syntax check
composer validate

# Check type
grep '"type"' composer.json | grep "ai-agent-skill"

# Check plugin requirement
grep "composer-agent-skill-plugin" composer.json
```

## Integration with Plugin

The `composer-agent-skill-plugin` automatically:

1. Discovers installed `ai-agent-skill` packages
2. Parses SKILL.md frontmatter
3. Generates AGENTS.md index
4. Provides `composer list-skills` command
5. Provides `composer read-skill {name}` command

## Troubleshooting

### "Package not found"

- Ensure package is published on Packagist
- Check package name matches exactly
- Run `composer clear-cache`

### "Plugin not activated"

When prompted, allow the plugin:
```
Do you trust "netresearch/composer-agent-skill-plugin"? [y,n,d,?]
```

Or pre-authorize in composer.json:
```json
{
  "config": {
    "allow-plugins": {
      "netresearch/composer-agent-skill-plugin": true
    }
  }
}
```

### "SKILL.md not found"

- Verify path in `extra.ai-agent-skill`
- Paths must be relative from package root
- Absolute paths are rejected for security
