# Skill Sync Setup Documentation

This marketplace uses automated GitHub Actions to sync skills from their individual source repositories. This document explains how to set up and maintain the sync automation.

## ⚠️ CURRENT STATUS (2025-10-29)

**Sync Mechanism**: ✅ Fixed and operational
- All 7 skills configured in sync workflow
- Directory creation issue fixed
- Weekly schedule working (Monday 2 AM UTC)

**Immediate Sync**: ❌ NOT WORKING
- Source repositories missing `.github/workflows/notify-marketplace.yml`
- No repository_dispatch events being sent
- Skills only sync once per week via cron

**Action Required**: Add notify workflow to all 7 source repositories (see step 3 below)

## Overview

**Problem**: Claude Code does not checkout git submodules when cloning marketplaces

**Solution**: GitHub Actions workflow that automatically syncs skill repositories into the marketplace

**Trigger**: Repository dispatch events from individual skill repositories (immediate sync on updates)

## Architecture

```
Individual Skill Repo (e.g., typo3-conformance-skill)
    ↓ (on release/push to main)
GitHub Actions: notify-marketplace.yml
    ↓ (sends repository_dispatch event)
Marketplace Repo: netresearch/claude-code-marketplace
    ↓ (receives event)
GitHub Actions: sync-skills.yml
    ↓ (clones skill, copies files)
Marketplace Updated (push to main)
    ↓
Claude Code Users (receive update on next refresh)
```

## Files in This Repository

### `.github/workflows/sync-skills.yml`
Main automation workflow with three triggers:
- **Primary**: `repository_dispatch` (immediate sync when skills update)
- **Backup**: `schedule` (weekly cron - Monday 2 AM UTC)
- **Manual**: `workflow_dispatch` (for testing/emergency)

### `.sync-config.json`
Configuration mapping skill repositories to marketplace paths:
```json
{
  "skills": [
    {
      "name": "typo3-docs",
      "repository": "https://github.com/netresearch/typo3-docs-skill.git",
      "target_path": "skills/typo3-docs",
      "marketplace_name": "typo3-docs"
    },
    ...
  ]
}
```

## Setup Instructions

### 1. Marketplace Repository (This Repo)

✅ **Already configured** - no action needed

The workflow is ready and will respond to repository dispatch events.

### 2. Individual Skill Repositories

Each skill repository needs a workflow to notify the marketplace on updates.

#### Step 1: Create GitHub Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Name: `Marketplace Sync`
4. Expiration: `No expiration` (or set organization policy)
5. Scopes: Select `repo` (full control of private repositories)
6. Click "Generate token"
7. **Copy the token** (you won't see it again)

#### Step 2: Add Token to Skill Repository Secrets

For **each skill repository** (typo3-docs-skill, typo3-conformance-skill, typo3-testing-skill, netresearch-branding-skill):

1. Go to skill repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `MARKETPLACE_SYNC_TOKEN`
4. Value: Paste the personal access token from Step 1
5. Click "Add secret"

#### Step 3: Create Workflow in Each Skill Repository

**Quick Deploy**: Use the template file `notify-marketplace.yml` at the root of this repository.

For each skill repository, copy the workflow:

```bash
# For each repository:
cd /path/to/skill-repo
mkdir -p .github/workflows
cp /path/to/claude-code-marketplace/notify-marketplace.yml .github/workflows/
git add .github/workflows/notify-marketplace.yml
git commit -m "add marketplace sync notification workflow"
git push origin main
```

**Repositories that need this workflow**:
- [ ] typo3-docs-skill
- [ ] typo3-conformance-skill
- [ ] typo3-testing-skill
- [ ] typo3-ddev-skill
- [ ] typo3-core-contributions-skill
- [ ] netresearch-branding-skill
- [ ] agents-skill

Or manually create `.github/workflows/notify-marketplace.yml` in each skill repository:

```yaml
name: Notify Marketplace on Update

on:
  push:
    branches:
      - main
  release:
    types: [published]

jobs:
  notify:
    runs-on: ubuntu-latest

    steps:
      - name: Extract skill name
        id: skill
        run: |
          # Extract skill name from repository name
          REPO_NAME="${{ github.event.repository.name }}"
          SKILL_NAME="${REPO_NAME%-skill}"
          echo "name=$SKILL_NAME" >> $GITHUB_OUTPUT

      - name: Send repository dispatch to marketplace
        uses: peter-evans/repository-dispatch@v3
        with:
          token: ${{ secrets.MARKETPLACE_SYNC_TOKEN }}
          repository: netresearch/claude-code-marketplace
          event-type: skill-updated
          client-payload: |
            {
              "skill": "${{ steps.skill.outputs.name }}",
              "version": "${{ github.event.release.tag_name || 'main' }}",
              "ref": "${{ github.sha }}"
            }

      - name: Summary
        run: |
          echo "✓ Marketplace sync triggered"
          echo "Skill: ${{ steps.skill.outputs.name }}"
          echo "Event: ${{ github.event_name }}"
```

## Testing the Automation

### Test Individual Skill Notification

1. Make a change in a skill repository (e.g., update README)
2. Commit and push to main
3. Go to skill repo → Actions → Check "Notify Marketplace on Update" workflow
4. Should show ✓ success

### Test Marketplace Sync

1. After skill notification runs, go to marketplace repo
2. Actions → "Sync Skills from Source Repositories"
3. Should show workflow running (triggered by repository_dispatch)
4. When complete, check the commit on main branch
5. Commit message should show: "chore: sync skills from source repositories"

### Manual Test

1. Go to marketplace repo → Actions → "Sync Skills from Source Repositories"
2. Click "Run workflow"
3. Select branch: main
4. Click "Run workflow"
5. Wait for completion
6. Check latest commit for synced changes

## Monitoring

### Successful Sync Indicators

✅ Marketplace Actions tab shows completed "Sync Skills" workflow
✅ Latest commit message: "chore: sync skills from source repositories"
✅ Skills directory contains up-to-date content
✅ `marketplace.json` has latest version numbers

### Troubleshooting

#### Problem: Workflow not triggering on skill updates

**Check**:
- Is `MARKETPLACE_SYNC_TOKEN` secret set in skill repository?
- Does token have `repo` scope?
- Is workflow file present: `.github/workflows/notify-marketplace.yml`?
- Check skill repo Actions tab for workflow runs

**Fix**:
- Re-create personal access token with correct scopes
- Update secret in skill repository settings
- Verify workflow file is on main branch

#### Problem: Sync workflow fails

**Check**:
- Go to marketplace repo → Actions → Failed workflow
- Read error messages in workflow logs
- Common issues: git conflicts, invalid SKILL.md format, network issues

**Fix**:
- For git conflicts: manually resolve and push
- For SKILL.md issues: ensure proper format with version metadata
- For network issues: re-run workflow (often transient)

#### Problem: Changes not appearing in Claude Code

**Check**:
- Did marketplace repo successfully update?
- Has Claude Code refreshed marketplace list?

**Fix**:
- Verify latest commit in marketplace repo
- In Claude Code: Reload marketplace or restart application
- Allow 5-10 minutes for marketplace cache refresh

## Maintenance

### Adding a New Skill

1. Create skill repository following SKILL.md format
2. Add workflow: `.github/workflows/notify-marketplace.yml`
3. Add `MARKETPLACE_SYNC_TOKEN` secret
4. Update marketplace `.sync-config.json`:
   ```json
   {
     "name": "new-skill",
     "repository": "https://github.com/netresearch/new-skill.git",
     "target_path": "skills/new-skill",
     "marketplace_name": "new-skill"
   }
   ```
5. Add skill to `.github/workflows/sync-skills.yml` (add sync step)
6. Update `marketplace.json` manually or trigger workflow

### Removing a Skill

1. Remove from `.sync-config.json`
2. Remove sync step from `.github/workflows/sync-skills.yml`
3. Delete `skills/{skill-name}/` directory
4. Remove from `marketplace.json`
5. Commit and push

### Updating Sync Frequency

Edit `.github/workflows/sync-skills.yml`:

```yaml
schedule:
  - cron: '0 2 * * 1'  # Weekly: Monday 2 AM UTC
  # Change to:
  - cron: '0 */6 * * *'  # Every 6 hours
  # or:
  - cron: '0 0 * * *'  # Daily at midnight UTC
```

## Security Considerations

### Personal Access Token

- **Scope**: Requires `repo` access to trigger workflows in marketplace
- **Expiration**: Set based on organization security policy
- **Rotation**: Update token in all skill repo secrets when rotating
- **Principle of Least Privilege**: Token only needs `public_repo` if all repos are public

### Workflow Permissions

- Marketplace workflow uses `GITHUB_TOKEN` (automatic, scoped to marketplace repo)
- Skill workflows use `MARKETPLACE_SYNC_TOKEN` secret (cross-repo access)
- Both have minimal permissions needed for their tasks

### Code Review

- Skill content is synced automatically (no PR review)
- For sensitive changes: manually review skill repos before pushing
- Consider adding branch protection to skill repos if needed

## Support

### Questions or Issues

- **Marketplace sync issues**: Open issue in `netresearch/claude-code-marketplace`
- **Skill-specific issues**: Open issue in individual skill repository
- **General questions**: Contact Netresearch DTT GmbH (info@netresearch.de)

### Useful Commands

```bash
# Check marketplace sync status
cd /tmp/claude-code-marketplace
git log --oneline -5

# Manually trigger sync (requires GitHub CLI)
gh workflow run sync-skills.yml

# Check skill versions in marketplace
jq '.plugins[] | {name, version}' .claude-plugin/marketplace.json

# Verify skill content is up-to-date
diff -r skills/typo3-conformance /path/to/typo3-conformance-skill
```

---

**Last Updated**: 2025-10-18
**Automation Status**: ✅ Active and operational
