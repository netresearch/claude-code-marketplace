#!/bin/bash
# Update source skill repositories to new subdirectory structure
# This script clones each repo, restructures it, commits, pushes, and creates a release

set -e

WORK_DIR="/tmp/skill-updates"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

# Skills to update (name|github_repo)
SKILLS=(
  "enterprise-readiness|netresearch/enterprise-readiness-skill"
  "typo3-docs|netresearch/typo3-docs-skill"
  "typo3-conformance|netresearch/typo3-conformance-skill"
  "typo3-testing|netresearch/typo3-testing-skill"
  "typo3-ddev|netresearch/typo3-ddev-skill"
  "netresearch-branding|netresearch/netresearch-branding-skill"
  "agents|netresearch/agents-skill"
  "typo3-core-contributions|netresearch/typo3-core-contributions-skill"
  "cli-tools|netresearch/cli-tools-skill"
  "typo3-extension-upgrade|netresearch/typo3-extension-upgrade-skill"
  "go-development|netresearch/go-development-skill"
  "php-modernization|netresearch/php-modernization-skill"
  "security-audit|netresearch/security-audit-skill"
  "typo3-ckeditor5|netresearch/typo3-ckeditor5-skill"
  "git-workflow|netresearch/git-workflow-skill"
  "skill-repo|netresearch/skill-repo-skill"
  "github-project|netresearch/github-project-skill"
  "context7|netresearch/context7-skill"
)

update_skill() {
  local skill_name="$1"
  local github_repo="$2"
  local repo_dir="$WORK_DIR/$skill_name"

  echo ""
  echo "=========================================="
  echo "Updating: $skill_name ($github_repo)"
  echo "=========================================="

  # Clone the repo
  git clone "https://github.com/$github_repo.git" "$repo_dir"
  cd "$repo_dir"

  # Check if already has subdirectory structure
  if [ -d "skills/$skill_name" ] && [ -f "skills/$skill_name/SKILL.md" ]; then
    echo "✓ $skill_name already has correct structure - skipping"
    return 0
  fi

  # Check if has SKILL.md at root
  if [ ! -f "SKILL.md" ]; then
    echo "⚠ $skill_name has no SKILL.md at root - skipping"
    return 0
  fi

  # Get current version from plugin.json
  local current_version="1.0.0"
  if [ -f ".claude-plugin/plugin.json" ]; then
    current_version=$(jq -r '.version // "1.0.0"' .claude-plugin/plugin.json)
  fi

  # Calculate new version (increment patch)
  local major minor patch
  IFS='.' read -r major minor patch <<< "$current_version"
  patch=$((patch + 1))
  local new_version="${major}.${minor}.${patch}"

  echo "  Current version: $current_version"
  echo "  New version: $new_version"

  # Create skills subdirectory
  mkdir -p "skills/$skill_name"

  # Move SKILL.md
  mv "SKILL.md" "skills/$skill_name/SKILL.md"
  echo "  Moved SKILL.md"

  # Move AGENTS.md if present
  if [ -f "AGENTS.md" ]; then
    mv "AGENTS.md" "skills/$skill_name/AGENTS.md"
    echo "  Moved AGENTS.md"
  fi

  # Move references/ if present
  if [ -d "references" ]; then
    mv "references" "skills/$skill_name/references"
    echo "  Moved references/"
  fi

  # Move templates/ if present
  if [ -d "templates" ]; then
    mv "templates" "skills/$skill_name/templates"
    echo "  Moved templates/"
  fi

  # Move scripts/ if present
  if [ -d "scripts" ]; then
    mv "scripts" "skills/$skill_name/scripts"
    echo "  Moved scripts/"
  fi

  # Read existing plugin.json values
  local description=""
  local repository=""
  if [ -f ".claude-plugin/plugin.json" ]; then
    description=$(jq -r '.description // ""' .claude-plugin/plugin.json)
    repository=$(jq -r '.repository // ""' .claude-plugin/plugin.json)
  fi

  # If no description, try to extract from SKILL.md frontmatter
  if [ -z "$description" ] && [ -f "skills/$skill_name/SKILL.md" ]; then
    description=$(sed -n '/^---$/,/^---$/p' "skills/$skill_name/SKILL.md" | grep -E '^description:' | sed 's/^description:[[:space:]]*//' | tr -d '"' | head -1)
  fi

  # Create updated plugin.json with subdirectory structure
  mkdir -p ".claude-plugin"
  cat > ".claude-plugin/plugin.json" << EOF
{
  "name": "$skill_name",
  "version": "$new_version",
  "description": "$description",
  "repository": "$repository",
  "license": "MIT",
  "author": {
    "name": "Netresearch DTT GmbH",
    "email": "info@netresearch.de"
  },
  "skills": [
    {
      "name": "$skill_name",
      "path": "skills/$skill_name"
    }
  ]
}
EOF
  echo "  Updated plugin.json (version $new_version)"

  # Commit changes
  git add -A
  git commit -m "refactor: restructure skill for Claude Code compatibility

Move skill files to skills/$skill_name/ subdirectory structure.
This fixes installation in Claude Code which requires skills in subdirectories.

Changes:
- Moved SKILL.md to skills/$skill_name/SKILL.md
- Moved references/, templates/, scripts/ directories
- Updated plugin.json with new structure and version $new_version"

  # Push changes
  echo "  Pushing changes..."
  git push origin main

  # Create new release
  echo "  Creating release v$new_version..."
  gh release create "v$new_version" \
    --title "v$new_version" \
    --notes "## Changes

- Restructured skill for Claude Code compatibility
- Skill files now in \`skills/$skill_name/\` subdirectory
- Fixes installation issues in Claude Code plugin system

This is a structural change with no functional differences."

  echo "✓ $skill_name updated and released as v$new_version"
}

echo "=== Updating Source Skill Repositories ==="
echo "Working directory: $WORK_DIR"
echo ""

for skill_entry in "${SKILLS[@]}"; do
  IFS='|' read -r skill_name github_repo <<< "$skill_entry"
  update_skill "$skill_name" "$github_repo" || echo "⚠ Failed to update $skill_name"
done

echo ""
echo "=== All skills updated ==="
echo "Cleanup: rm -rf $WORK_DIR"
