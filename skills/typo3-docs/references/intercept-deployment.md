# TYPO3 Intercept Deployment & Webhook Setup

Complete guide for setting up automatic documentation deployment using TYPO3 Intercept webhooks.

## Overview

TYPO3 Intercept provides automatic documentation rendering and publishing for TYPO3 extensions. When properly configured, your documentation is automatically built and published to docs.typo3.org whenever you push commits or create version tags.

## Prerequisites

Before setting up webhooks, ensure:

1. **Extension Published in TER**: Your extension must be registered in the TYPO3 Extension Repository (TER) with the same extension key specified in `composer.json`
2. **Git Repository Referenced**: The Git repository URL must be listed on your extension's TER detail page
3. **Documentation Structure**: Your `Documentation/` directory must contain:
   - `Index.rst` (main entry point)
   - `guides.xml` (modern, preferred) OR `Settings.cfg` (legacy)
   - Valid RST files following TYPO3 documentation standards

> **Note**: `guides.xml` is the modern PHP-based rendering configuration and is preferred over `Settings.cfg` (legacy Sphinx-based). New extensions should use `guides.xml`.

## Webhook Registration

### GitHub Setup

1. **Navigate to Repository Settings**
   - Go to your GitHub repository
   - Click **Settings** → **Webhooks**
   - Click **Add webhook**

2. **Configure Webhook**
   - **Payload URL**: `https://docs-hook.typo3.org`
   - **Content type**: `application/json`
   - **SSL verification**: Enable SSL verification
   - **Which events**: Select "Just the push event"
   - **Active**: Check the "Active" checkbox

3. **Save Webhook**
   - Click **Add webhook** to save
   - GitHub will send a test ping to verify connectivity

### GitLab Setup

1. **Navigate to Webhooks**
   - Go to your GitLab project
   - Click **Settings** → **Webhooks**

2. **Configure Webhook**
   - **URL**: `https://docs-hook.typo3.org`
   - **Trigger**: Check both:
     - Push events
     - Tag push events
   - **SSL verification**: Enable SSL verification

3. **Add Webhook**
   - Click **Add webhook** to save
   - GitLab will test the connection

### GitHub CLI Automation

For faster setup using `gh` CLI:

```bash
# Create webhook
gh api repos/{owner}/{repo}/hooks \
  --method POST \
  --field name=web \
  --field "config[url]=https://docs-hook.typo3.org" \
  --field "config[content_type]=json" \
  --field "config[insecure_ssl]=0" \
  --raw-field "events[]=push" \
  --field active=true

# Trigger test delivery
gh api repos/{owner}/{repo}/hooks/{hook_id}/tests --method POST

# Check delivery status
gh api repos/{owner}/{repo}/hooks/{hook_id}/deliveries \
  --jq '.[] | {id: .id, status: .status, status_code: .status_code, event: .event}'

# List webhooks to find hook_id
gh api repos/{owner}/{repo}/hooks --jq '.[] | {id: .id, url: .config.url}'
```

## First-Time Approval

The first time you trigger documentation rendering, the TYPO3 Documentation Team must approve your repository:

1. **Automatic Hold**: First webhook trigger is automatically placed on hold
2. **Manual Review**: Documentation Team reviews:
   - TER registration matches composer.json extension key
   - Git repository is properly referenced in TER
   - Documentation structure is valid
3. **Approval**: Once approved, future builds are automatic
4. **Notification**: Check Intercept dashboard for approval status

**Typical Approval Time**: 1-3 business days

## Verification

### Check Webhook Delivery

**GitHub:**
1. Go to **Settings** → **Webhooks**
2. Click on the webhook
3. Scroll to **Recent Deliveries**
4. Verify delivery shows `200` or `204` response code

**Expected Status Codes:**
| Code | Meaning |
|------|---------|
| `200` | Success (ping events) |
| `204` | Success (push events accepted) |
| `412` | Precondition Failed - expected on first-time test pushes before approval |

> **Note**: A `412` error on test push delivery is normal for repositories not yet approved. The actual push after commits will trigger the approval workflow.

**GitLab:**
1. Go to **Settings** → **Webhooks**
2. Click **Edit** on the webhook
3. Scroll to **Recent events**
4. Verify event shows success status

### Check Intercept Dashboard

1. **Visit**: https://intercept.typo3.com/
2. **Check Recent Actions**: View recent webhook triggers
3. **Documentation Deployments**: https://intercept.typo3.com/admin/docs/deployments
4. **Search for Your Extension**: Filter by package name

### Verify Published Documentation

Once approved and rendered successfully:

**Published URL Pattern**:
```
https://docs.typo3.org/p/{vendor}/{extension}/{branch}/en-us/
```

**Example**:
```
https://docs.typo3.org/p/netresearch/rte-ckeditor-image/main/en-us/
```

**Version-Specific URLs**:
```
https://docs.typo3.org/p/{vendor}/{extension}/{version}/en-us/
```

## Triggering Documentation Builds

### Automatic Triggers

Documentation builds are triggered automatically by:

1. **Git Push to Main/Master**
   ```bash
   git push origin main
   ```

2. **Version Tags**
   ```bash
   git tag 2.1.0
   git push origin 2.1.0
   ```

3. **Branch Push** (for multi-version documentation)
   ```bash
   git push origin docs-v12
   ```

### Manual Trigger

If automatic builds fail or you need to rebuild:

1. Visit: https://intercept.typo3.com/admin/docs/deployments
2. Find your extension
3. Click **Redeploy** button
4. Monitor build progress in Recent actions

## Build Process

Understanding the rendering pipeline:

1. **Webhook Received**: Intercept receives push notification
2. **Queue Job**: Build job added to rendering queue
3. **Clone Repository**: Code checked out at specific commit/tag
4. **Render Documentation**: Using `ghcr.io/typo3-documentation/render-guides:latest`
5. **Publish**: Rendered HTML published to docs.typo3.org
6. **Index**: Documentation indexed for search

**Typical Build Time**: 2-5 minutes

## Troubleshooting

### Webhook Not Triggering

**Check**:
- Webhook URL is exactly `https://docs-hook.typo3.org`
- SSL verification is enabled
- Webhook is marked as "Active"
- Recent deliveries show `200` response

**Fix**:
1. Edit webhook settings
2. Verify URL and SSL settings
3. Click **Redeliver** on failed delivery
4. Check Intercept Recent actions

### Build Failing

**Common Issues**:

1. **RST Syntax Errors**
   ```bash
   # Validate locally before pushing
   ~/.claude/skills/typo3-docs/scripts/validate_docs.sh
   ```

2. **Missing Configuration File**
   ```bash
   # Check for guides.xml (modern) or Settings.cfg (legacy)
   ls -la Documentation/guides.xml Documentation/Settings.cfg
   ```

3. **Invalid Cross-References**
   - Render locally to check for broken `:ref:` links
   - Fix undefined labels

4. **Encoding Issues**
   - Ensure all files are UTF-8 encoded
   - Check for BOM (Byte Order Mark) issues

### First Build Stuck "On Hold"

**Expected Behavior**: First build requires manual approval

**Action**:
- Wait for Documentation Team review (1-3 business days)
- Ensure TER registration is complete
- Verify Git repository URL in TER matches webhook source

**Speed Up Approval**:
- Post in TYPO3 Slack [#typo3-documentation](https://typo3.slack.com/archives/C028JEPJL)
- Reference your extension key and repository URL

### Documentation Not Updating

**Check**:
1. **Build Status**: Visit Intercept dashboard, verify build succeeded
2. **Cache**: Browser cache might show old version
   - Hard refresh: `Ctrl+F5` / `Cmd+Shift+R`
   - Try incognito/private mode
3. **Correct URL**: Verify you're visiting the right branch/version URL

**Fix**:
1. Trigger manual rebuild from Intercept dashboard
2. Check build logs for errors
3. Verify `guides.xml` or `Settings.cfg` has correct project configuration

## Best Practices

### Pre-Push Checklist

Before pushing documentation changes:

✅ **Validate RST Syntax**
```bash
~/.claude/skills/typo3-docs/scripts/validate_docs.sh /path/to/project
```

✅ **Render Locally**
```bash
~/.claude/skills/typo3-docs/scripts/render_docs.sh /path/to/project
open Documentation-GENERATED-temp/Index.html
```

✅ **Check for Warnings**
- No rendering warnings
- No broken cross-references
- All code blocks have language specified
- UTF-8 emoji icons render correctly

✅ **Commit Message**
```bash
git commit -m "docs: update configuration guide with new settings"
```

### Version Management

**Branching Strategy**:
- `main` / `master`: Latest development documentation
- Version tags: Specific release documentation (e.g., `2.1.0`, `3.0.0`)
- Version branches: Long-term support versions (e.g., `docs-v12`, `docs-v11`)

**Tag Documentation Builds**:
```bash
# Create release tag
git tag -a 2.1.0 -m "Release 2.1.0"
git push origin 2.1.0

# Documentation auto-builds for version 2.1.0
# Published at: /p/{vendor}/{ext}/2.1.0/en-us/
```

### Multi-Version Documentation

For supporting multiple TYPO3 versions:

1. **Create Version Branches**
   ```bash
   git checkout -b docs-v12
   git push origin docs-v12
   ```

2. **Configure guides.xml** (or Settings.cfg) for each branch
   ```xml
   <!-- guides.xml (modern) -->
   <project title="Extension Name"
            version="2.1.0"
            copyright="since 2024 by Your Name"/>
   ```
   ```ini
   # Settings.cfg (legacy)
   [general]
   project = Extension Name
   release = 2.1.0
   version = 2.1
   ```

3. **Webhook Triggers All Branches**
   - Pushes to any branch trigger builds
   - Each branch published separately

## Security Considerations

### Webhook Secret (Optional)

While TYPO3 Intercept doesn't require webhook secrets, you can add them for extra security:

**GitHub**:
1. Generate random secret: `openssl rand -hex 20`
2. Add to webhook **Secret** field
3. Intercept validates using X-Hub-Signature header

**GitLab**:
1. Generate random secret
2. Add to webhook **Secret token** field
3. Intercept validates using X-Gitlab-Token header

### Access Control

**Documentation Repositories Should**:
- Be publicly readable (required for Intercept access)
- Limit push access to trusted contributors
- Use branch protection for `main`/`master`
- Require pull request reviews for documentation changes

**Avoid in Documentation**:
- API keys, passwords, secrets
- Internal URLs, server hostnames
- Sensitive configuration details
- Personal information

## Resources

**Official Documentation**:
- [How to Document - Webhook Setup](https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Howto/WritingDocForExtension/Webhook.html)
- [TYPO3 Intercept Dashboard](https://intercept.typo3.com/)
- [Documentation Deployments](https://intercept.typo3.com/admin/docs/deployments)

**Community Support**:
- TYPO3 Slack: [#typo3-documentation](https://typo3.slack.com/archives/C028JEPJL)
- TYPO3 Slack: [#typo3-cms](https://typo3.slack.com/archives/C025HCWGM)

**Related Guides**:
- [TYPO3 Documentation Standards](https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/)
- [RST Syntax Reference](rst-syntax.md)
- [TYPO3 Directives Reference](typo3-directives.md)
