# Marketplace Integration

How skills are synced to the Netresearch Claude Code Marketplace.

## Overview

The [claude-code-marketplace](https://github.com/netresearch/claude-code-marketplace) aggregates skills from individual repositories via automated sync workflows.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  skill-repo-1   │     │  skill-repo-2   │     │  skill-repo-N   │
│  (source)       │     │  (source)       │     │  (source)       │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │  claude-code-marketplace│
                    │  (aggregator)           │
                    │                         │
                    │  skills/                │
                    │  ├── skill-1/           │
                    │  ├── skill-2/           │
                    │  └── skill-N/           │
                    └────────────────────────┘
```

## Sync Workflow

### Automatic Sync (Scheduled)

- **Frequency:** Weekly (Monday 2 AM UTC)
- **Trigger:** GitHub Actions schedule
- **Process:**
  1. Clone each source repository
  2. Extract semantic version from SKILL.md
  3. Append commit date for versioning
  4. Copy skill files to `skills/` directory
  5. Update marketplace metadata

### On-Demand Sync

Source repositories can trigger immediate sync via:

```yaml
# notify-marketplace.yml in source repo
name: Notify Marketplace

on:
  release:
    types: [published]

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger marketplace sync
        run: |
          gh workflow run sync-skills.yml \
            --repo netresearch/claude-code-marketplace
        env:
          GH_TOKEN: ${{ secrets.MARKETPLACE_SYNC_TOKEN }}
```

## Adding a Skill to Marketplace

### Prerequisites

1. Skill repository follows standard structure
2. SKILL.md has valid frontmatter with version
3. Repository is public

### Configuration

Add skill to `.sync-config.json` in marketplace repo:

```json
{
  "skills": [
    {
      "name": "my-skill",
      "repo": "netresearch/my-skill",
      "path": "skills/my-skill"
    }
  ]
}
```

### Versioning

Marketplace versions combine:
- Semantic version from SKILL.md frontmatter
- Last commit date

Example: `1.2.3-20251021`

## Sync Workflow Details

### Files Synced

From source repository:
- `SKILL.md`
- `references/`
- `scripts/`
- `assets/`
- `templates/`
- `LICENSE`

### Files NOT Synced

- `README.md` (marketplace has its own)
- `.github/`
- `composer.json`
- Dev configuration files
- `claudedocs/`

### Marketplace Metadata

Updated in `.claude-plugin/marketplace.json`:

```json
{
  "skills": {
    "my-skill": {
      "version": "1.2.3-20251021",
      "description": "Skill description",
      "source": "netresearch/my-skill"
    }
  }
}
```

## User Installation

### Add Marketplace

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

### Browse Skills

```bash
/plugin
```

### Install Skill

```bash
/plugin install {skill-name}
```

## Benefits of Marketplace Distribution

| Benefit | Description |
|---------|-------------|
| Discoverability | All skills in one place |
| Curation | Quality-controlled collection |
| Versioning | Automatic version tracking |
| Updates | Sync keeps skills current |
| Simplicity | One-command installation |

## Troubleshooting

### Skill Not Appearing

1. Check `.sync-config.json` includes the skill
2. Verify source repo is accessible
3. Check sync workflow logs
4. Ensure SKILL.md has valid frontmatter

### Outdated Version

1. Check last sync time in marketplace README
2. Trigger manual sync if needed
3. Verify source repo has new commits/releases

### Sync Failures

Common causes:
- Invalid SKILL.md frontmatter
- Missing required files
- Network/API issues
- Permission problems

Check GitHub Actions logs in marketplace repo.
