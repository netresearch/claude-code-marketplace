# Release Labeling Reference

**Purpose:** Automatically track which PRs and issues shipped in each release using labels.

## Overview

When a release is published, the release-labeler workflow:
1. Creates a label `released:vX.Y.Z`
2. Finds all PRs merged since the previous release
3. Labels those PRs and their linked issues
4. Adds comments linking to the release

## Benefits

| Benefit | Description |
|---------|-------------|
| **Traceability** | Know exactly which release contains a fix or feature |
| **User communication** | Issue reporters see when their request shipped |
| **Release notes** | Easy to generate changelogs from labeled PRs |
| **Audit trail** | Historical record of what shipped when |

## Label Format

```
released:vX.Y.Z
```

- **Prefix:** `released:` (consistent, searchable)
- **Version:** Full semver tag (e.g., `v1.2.3`, `v13.2.0`)
- **Color:** Green (`#0e8a16`) indicating shipped/done

## Setup

### 1. Add the workflow

Copy `assets/release-labeler.yml.template` to `.github/workflows/release-labeler.yml`:

```bash
curl -o .github/workflows/release-labeler.yml \
  https://raw.githubusercontent.com/netresearch/github-project-skill/main/skills/github-project/assets/release-labeler.yml.template
```

### 2. Ensure permissions

The workflow needs:
- `issues: write` - To label issues and add comments
- `pull-requests: write` - To label PRs and add comments
- `contents: read` - To compare releases

### 3. Link issues to PRs

For automatic issue labeling, PRs must reference issues using:
- `Fixes #123`
- `Closes #123`
- `Resolves #123`

GitHub automatically creates the linking when these keywords are used.

## How It Works

```
┌─────────────────┐
│ Release v1.2.0  │
│   published     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Get previous    │
│ release (v1.1.0)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Find commits    │
│ v1.1.0...v1.2.0 │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Find PRs for    │
│ those commits   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│ Label PRs with  │────▶│ Find linked     │
│ released:v1.2.0 │     │ issues          │
└─────────────────┘     └────────┬────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │ Label issues    │
                        │ released:v1.2.0 │
                        └─────────────────┘
```

## Querying Releases

### Find all items in a release

```bash
gh issue list --repo OWNER/REPO --label "released:v1.2.0" --state all
gh pr list --repo OWNER/REPO --label "released:v1.2.0" --state all
```

### GitHub web search

```
https://github.com/OWNER/REPO/issues?q=label:released:v1.2.0
```

### Find which release contains an issue

```bash
gh issue view 123 --json labels --jq '.labels[].name | select(startswith("released:"))'
```

## Manual Labeling

If you need to manually label items for a release:

```bash
# Create label
gh label create "released:v1.2.0" --color 0e8a16 --description "Released in v1.2.0"

# Label PRs
gh pr edit 100 101 102 --add-label "released:v1.2.0"

# Label issues
gh issue edit 50 51 --add-label "released:v1.2.0"

# Add comments
gh issue comment 50 --body "Fixed in [v1.2.0](https://github.com/OWNER/REPO/releases/tag/v1.2.0)"
```

## Integration with Other Tools

### Changelog generation

Use labeled PRs to generate changelogs:

```bash
gh pr list --repo OWNER/REPO --label "released:v1.2.0" --state merged \
  --json number,title,labels \
  --jq '.[] | "- \(.title) (#\(.number))"'
```

### Release notes automation

Reference labels in release body:

```markdown
## What's Changed

See all changes: [released:v1.2.0](https://github.com/OWNER/REPO/issues?q=label:released:v1.2.0)
```

## Troubleshooting

### PRs not being labeled

1. **Check tag format** - Must be semver (e.g., `v1.2.0`)
2. **Check previous release** - Workflow compares between releases
3. **Check permissions** - Workflow needs `pull-requests: write`

### Issues not being labeled

1. **Check PR linking** - Issues must be linked with `Fixes #123`
2. **Check issue state** - Only closed issues are labeled
3. **Check permissions** - Workflow needs `issues: write`

### First release

For the first release (no previous release to compare), the workflow labels recently merged PRs as a fallback.

## Examples

### Real-world usage

- [netresearch/ofelia](https://github.com/netresearch/ofelia/issues?q=label%3Areleased%3Av0.18.0)
- [netresearch/t3x-rte_ckeditor_image](https://github.com/netresearch/t3x-rte_ckeditor_image/issues?q=label%3Areleased%3Av13.2.0)
