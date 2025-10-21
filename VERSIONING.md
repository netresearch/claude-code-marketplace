# Versioning Strategy

This marketplace uses a **hybrid versioning approach** that combines semantic versioning with automated freshness tracking.

## Version Format

All skills use the format: `MAJOR.MINOR.PATCH-YYYYMMDD`

**Example:** `1.2.3-20251021`

- **Semantic Version (`1.2.3`)**: Declared by skill maintainers in SKILL.md
- **Date Suffix (`20251021`)**: Automatically appended by sync workflow from last commit date

## Semantic Versioning Rules

Skill maintainers control the semantic version (MAJOR.MINOR.PATCH) and should update it according to these rules:

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

### 1. Skill Maintainer Updates

When a skill maintainer makes changes:

```yaml
# In skill repository's SKILL.md
---
name: TYPO3 Documentation
version: 1.2.3  # ← Maintainer updates this
description: "..."
---
```

### 2. Sync Workflow Automation

When the sync workflow runs, it:

1. **Clones the skill repository** (full clone, not shallow)
   ```bash
   git clone https://github.com/netresearch/typo3-docs-skill.git
   ```

2. **Extracts the commit date** before removing .git directory
   ```bash
   COMMIT_DATE=$(git log -1 --format=%cd --date=format:%Y%m%d)
   # Result: 20251021
   ```

3. **Parses semantic version** from SKILL.md
   ```bash
   # Try YAML frontmatter first
   SEMVER=$(grep "^version:" SKILL.md | head -1 | sed 's/^version: *//')

   # Fall back to metadata section if needed
   if [ -z "$SEMVER" ]; then
     SEMVER=$(grep -A 5 "## Skill Metadata" SKILL.md | grep "version:")
   fi
   # Result: 1.2.3
   ```

4. **Combines both** into final version
   ```bash
   VERSION="${SEMVER}-${COMMIT_DATE}"
   # Result: 1.2.3-20251021
   ```

5. **Updates marketplace.json** with the combined version
   ```bash
   jq '(.plugins[] | select(.name == "typo3-docs") | .version) = $v1' marketplace.json
   ```

## Version Tracking Locations

Versions are tracked in multiple places for different purposes:

| Location | Format | Purpose | Updated By |
|----------|--------|---------|------------|
| Skill `SKILL.md` | `1.2.3` | Semantic version declaration | Skill maintainer |
| Marketplace `skills/*/SKILL.md` | `1.2.3` | Synced semantic version | Sync workflow |
| `.claude-plugin/marketplace.json` | `1.2.3-20251021` | Final version with date | Sync workflow |
| `README.md` table | `1.2.3-20251021` | User-visible version info | Sync workflow |

## Checking for Updates

### For Users

Check the version table in README.md to see:
- **Current version** installed in your marketplace
- **Last updated date** (from the YYYYMMDD suffix)
- **Semantic version** for understanding change scope

### For Maintainers

Monitor the sync workflow results to see:
```
✓ typo3-docs synced (version: 1.2.3-20251021)
✓ typo3-conformance synced (version: 1.0.5-20251020)
✓ typo3-testing synced (version: 1.1.0-20251019)
```

## Benefits of Hybrid Approach

### ✅ Advantages

1. **Automatic Freshness Tracking**
   - No manual date maintenance required
   - Reflects actual last change date
   - Easy to identify outdated skills

2. **Semantic Change Communication**
   - Users understand impact of updates (major/minor/patch)
   - Maintainers control version semantics
   - Clear versioning contract

3. **Sync Workflow Integration**
   - Version generation happens automatically
   - No possibility of stale dates
   - Consistent versioning across all skills

4. **Update Detection**
   - Compare date suffixes to check freshness
   - Identify skills needing updates
   - Track sync frequency

### ⚠️ Trade-offs

1. **Two Version Sources**
   - Semantic version in skill repository
   - Combined version in marketplace
   - Requires understanding of both

2. **Date Changes on Every Commit**
   - Even documentation fixes update the date
   - Version changes with every sync
   - May appear as "update available" for minor changes

## Example Workflow

### Scenario: Adding New Feature to TYPO3 Testing Skill

1. **Maintainer makes changes** in skill repository
   - Adds new Codeception templates
   - Updates documentation

2. **Maintainer bumps version** in SKILL.md
   ```yaml
   # Before
   version: 1.0.0

   # After (new feature = MINOR bump)
   version: 1.1.0
   ```

3. **Maintainer commits and pushes**
   ```bash
   git commit -m "feat: add Codeception acceptance test templates"
   git push
   # Commit date: 2025-10-21
   ```

4. **Sync workflow runs** (manual, scheduled, or repository_dispatch)
   - Detects version `1.1.0` from SKILL.md
   - Extracts commit date `20251021`
   - Generates final version: `1.1.0-20251021`
   - Updates marketplace.json
   - Commits to marketplace repository

5. **Users see update** in README.md version table
   ```
   TYPO3 Testing | 1.1.0-20251021 | New acceptance test templates
   ```

## Version History Tracking

Marketplace repository commits show version evolution:

```bash
git log --oneline .claude-plugin/marketplace.json

abc123 chore: sync skills from source repositories
       - typo3-testing: 1.1.0-20251021
def456 chore: sync skills from source repositories
       - typo3-testing: 1.0.0-20251015
```

## Frequently Asked Questions

### Q: When should I bump the semantic version?

**A:** Follow semantic versioning rules:
- **Breaking changes** → bump MAJOR
- **New features** → bump MINOR
- **Bug fixes** → bump PATCH

### Q: What if I forget to update the version in SKILL.md?

**A:** The sync workflow will use the existing semantic version but append the new commit date. The date suffix will still show freshness, but the semantic version won't reflect the change scope.

**Best Practice:** Always update the semantic version when making changes.

### Q: Can I see version history for a skill?

**A:** Yes, check the skill's source repository commit history:
```bash
git log --oneline -- SKILL.md
```

Or check marketplace repository for sync history:
```bash
git log --oneline -- .claude-plugin/marketplace.json
```

### Q: What happens if SKILL.md doesn't have a version?

**A:** The sync workflow falls back to `1.0.0` as the default semantic version:
```bash
if [ -z "$SEMVER" ]; then
  SEMVER="1.0.0"
fi
```

### Q: How often does the sync workflow run?

**A:** Three triggers:
1. **Manual:** `workflow_dispatch` for immediate sync
2. **Scheduled:** Weekly on Mondays at 2 AM UTC
3. **Automatic:** `repository_dispatch` when skill repositories update

## References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [GitHub Actions Workflow](.github/workflows/sync-skills.yml)
- [Marketplace Schema](.claude-plugin/marketplace.json)
