# Versioning Strategy

This marketplace uses a **hybrid versioning approach** that combines semantic versioning from git tags with automated freshness tracking.

## Version Format

All agentic skills use the format: `MAJOR.MINOR.PATCH-YYYYMMDD`

**Example:** `2.1.0-20251206`

- **Semantic Version (`2.1.0`)**: Extracted from git tags in skill repositories
- **Date Suffix (`20251206`)**: Automatically appended by sync workflow from last commit date

## Semantic Versioning Rules

Agentic skill maintainers control the semantic version (MAJOR.MINOR.PATCH) by creating git tags:

### MAJOR version (X.0.0)
Increment when making **incompatible changes**:
- Breaking changes to skill behavior or interface
- Removal of previously supported features
- Changes requiring user action to maintain compatibility
- TYPO3 version compatibility changes (e.g., dropping support for TYPO3 11)

**Example:** `1.5.2` → `2.0.0` (dropped TYPO3 11 support)

### MINOR version (1.X.0)
Increment when adding **new features** in a backward-compatible manner:
- New capabilities or commands
- New reference documentation sections
- New templates or examples
- Enhanced functionality that doesn't break existing usage

**Example:** `1.2.3` → `1.3.0` (added new testing templates)

### PATCH version (1.2.X)
Increment for **backward-compatible bug fixes** and improvements:
- Documentation corrections or clarifications
- Bug fixes in templates or scripts
- Performance improvements
- Code quality enhancements

**Example:** `1.2.3` → `1.2.4` (fixed typo in documentation)

## How Version Generation Works

### 1. Agentic Skill Maintainer Creates Release

When an agentic skill maintainer makes changes and wants to release:

```bash
# In agentic skill repository
git add .
git commit -m "feat: add new feature"
git tag v2.1.0  # or 2.1.0 (both formats supported)
git push && git push --tags
```

### 2. Sync Workflow Automation

When the sync workflow runs, it:

1. **Clones the agentic skill repository** (full clone, not shallow)
   ```bash
   git clone https://github.com/netresearch/typo3-docs-skill.git
   ```

2. **Extracts the commit date** before removing .git directory
   ```bash
   COMMIT_DATE=$(git log -1 --format=%cd --date=format:%Y%m%d)
   # Result: 20251206
   ```

3. **Extracts semantic version from git tags**
   ```bash
   # Get latest semantic version tag (supports v prefix)
   LATEST_TAG=$(git tag --sort=-v:refname | grep -E '^v?[0-9]+\.[0-9]+' | head -1)

   # Strip 'v' prefix if present
   SEMVER=$(echo "$LATEST_TAG" | sed 's/^v//')

   # Fall back to 1.0.0 if no tags exist
   if [ -z "$SEMVER" ]; then
     SEMVER="1.0.0"
   fi
   # Result: 2.1.0
   ```

4. **Combines both** into final version
   ```bash
   VERSION="${SEMVER}-${COMMIT_DATE}"
   # Result: 2.1.0-20251206
   ```

5. **Updates marketplace.json** with the combined version
   ```bash
   jq '(.plugins[] | select(.name == "typo3-docs") | .version) = $v1' marketplace.json
   ```

## Version Tracking Locations

Versions are tracked in multiple places for different purposes:

| Location | Format | Purpose | Updated By |
|----------|--------|---------|------------|
| Agentic skill repository git tags | `v2.1.0` or `2.1.0` | Semantic version declaration | Agentic skill maintainer |
| `.claude-plugin/marketplace.json` | `2.1.0-20251206` | Final version with date | Sync workflow |

## Checking for Updates

### For Users

Check the marketplace.json or run the sync workflow to see:
- **Current version** of each agentic skill
- **Last updated date** (from the YYYYMMDD suffix)
- **Semantic version** for understanding change scope

### For Maintainers

Monitor the sync workflow results to see:
```
✓ typo3-docs synced (version: 2.1.0-20251206)
✓ typo3-conformance synced (version: 1.0.5-20251203)
✓ typo3-testing synced (version: 1.1.0-20251203)
```

## Benefits of Hybrid Approach

### Advantages

1. **Git-Native Versioning**
   - Uses standard git tagging workflow
   - No need for version metadata in SKILL.md
   - Integrates with GitHub releases

2. **Automatic Freshness Tracking**
   - No manual date maintenance required
   - Reflects actual last change date
   - Easy to identify outdated skills

3. **Semantic Change Communication**
   - Users understand impact of updates (major/minor/patch)
   - Maintainers control version semantics
   - Clear versioning contract

4. **Sync Workflow Integration**
   - Version generation happens automatically
   - No possibility of stale dates
   - Consistent versioning across all agentic skills

5. **Update Detection**
   - Compare date suffixes to check freshness
   - Identify agentic skills needing updates
   - Track sync frequency

### Trade-offs

1. **Date Changes on Every Commit**
   - Even documentation fixes update the date
   - Version changes with every sync
   - May appear as "update available" for minor changes

2. **Tag Discipline Required**
   - Maintainers must create tags for version bumps
   - Untagged repositories default to 1.0.0

## Example Workflow

### Scenario: Adding New Feature to TYPO3 Testing Agentic Skill

1. **Maintainer makes changes** in agentic skill repository
   - Adds new Codeception templates
   - Updates documentation

2. **Maintainer commits and creates tag**
   ```bash
   git add .
   git commit -m "feat: add Codeception acceptance test templates"
   git tag v1.1.0
   git push && git push --tags
   # Commit date: 2025-12-06
   ```

3. **GitHub release (optional)**
   - Maintainer can create a GitHub release from the tag
   - Provides changelog and release notes

4. **Sync workflow runs** (manual, scheduled, or repository_dispatch)
   - Detects tag `v1.1.0` → extracts `1.1.0`
   - Extracts commit date `20251206`
   - Generates final version: `1.1.0-20251206`
   - Updates marketplace.json
   - Commits to marketplace repository

5. **Users see update** in marketplace
   ```
   TYPO3 Testing | 1.1.0-20251206
   ```

## Version History Tracking

Marketplace repository commits show version evolution:

```bash
git log --oneline .claude-plugin/marketplace.json

abc123 chore: sync skills from source repositories
       - typo3-testing: 1.1.0-20251206
def456 chore: sync skills from source repositories
       - typo3-testing: 1.0.0-20251203
```

## Frequently Asked Questions

### Q: When should I create a new version tag?

**A:** Follow semantic versioning rules:
- **Breaking changes** → bump MAJOR (v1.0.0 → v2.0.0)
- **New features** → bump MINOR (v1.0.0 → v1.1.0)
- **Bug fixes** → bump PATCH (v1.0.0 → v1.0.1)

### Q: What tag format should I use?

**A:** Both formats are supported:
- With prefix: `v1.2.3` (recommended, GitHub convention)
- Without prefix: `1.2.3`

The sync workflow automatically strips the `v` prefix when extracting the version.

### Q: What if my repository has no tags?

**A:** The sync workflow falls back to `1.0.0` as the default semantic version:
```bash
if [ -z "$SEMVER" ]; then
  SEMVER="1.0.0"
fi
```

**Best Practice:** Create at least one version tag (e.g., `v1.0.0`) for your agentic skill.

### Q: Can I see version history for an agentic skill?

**A:** Yes, check the agentic skill's source repository tag history:
```bash
git tag --sort=-v:refname
```

Or check marketplace repository for sync history:
```bash
git log --oneline -- .claude-plugin/marketplace.json
```

### Q: How often does the sync workflow run?

**A:** Three triggers:
1. **Manual:** `workflow_dispatch` for immediate sync
2. **Scheduled:** Weekly on Mondays at 2 AM UTC
3. **Automatic:** `repository_dispatch` when agentic skill repositories update (requires notify workflow)

### Q: What about pre-release versions?

**A:** The workflow extracts only stable semantic versions matching `^v?[0-9]+\.[0-9]+`. Pre-release tags like `v2.0.0-beta.1` will be skipped in favor of the latest stable tag.

## Creating Your First Release

For new agentic skill repositories:

```bash
# After initial development is complete
git add .
git commit -m "feat: initial skill implementation"
git tag v1.0.0
git push origin main --tags

# Optional: Create GitHub release
gh release create v1.0.0 --title "Initial Release" --notes "First stable release"
```

## References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [GitHub Actions Workflow](.github/workflows/sync-skills.yml)
- [Marketplace Schema](.claude-plugin/marketplace.json)
- [Git Tagging Documentation](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
