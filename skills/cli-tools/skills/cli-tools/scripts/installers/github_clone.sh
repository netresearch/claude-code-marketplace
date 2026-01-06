#!/usr/bin/env bash
# Generic installer for GitHub repository clones
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$DIR/lib/install_strategy.sh"

TOOL="${1:-}"
if [ -z "$TOOL" ]; then
  echo "Usage: $0 TOOL_NAME [ACTION]" >&2
  exit 1
fi

ACTION="${2:-install}"

CATALOG_FILE="$DIR/../catalog/$TOOL.json"
if [ ! -f "$CATALOG_FILE" ]; then
  echo "[$TOOL] Error: Catalog file not found: $CATALOG_FILE" >&2
  exit 1
fi

# Parse catalog
GITHUB_REPO="$(jq -r '.github_repo // ""' "$CATALOG_FILE")"
CLONE_PATH="$(jq -r '.clone_path // ""' "$CATALOG_FILE")"
BRANCH="$(jq -r '.branch // "master"' "$CATALOG_FILE")"

if [ -z "$GITHUB_REPO" ]; then
  echo "[$TOOL] Error: github_repo not specified in catalog" >&2
  exit 1
fi

if [ -z "$CLONE_PATH" ]; then
  echo "[$TOOL] Error: clone_path not specified in catalog" >&2
  exit 1
fi

# Expand tilde in clone path
CLONE_PATH="${CLONE_PATH/#\~/$HOME}"

# Ensure git is available
if ! command -v git >/dev/null 2>&1; then
  echo "[$TOOL] Error: git not found. Please install git first." >&2
  exit 1
fi

# Get current version/commit if already cloned
before=""
if [ -d "$CLONE_PATH/.git" ]; then
  cd "$CLONE_PATH"
  before="$(git rev-parse --short HEAD 2>/dev/null || echo "<unknown>")"
  cd - >/dev/null
fi

# Clone or update
if [ ! -d "$CLONE_PATH" ]; then
  echo "[$TOOL] Cloning from https://github.com/$GITHUB_REPO" >&2
  mkdir -p "$(dirname "$CLONE_PATH")"
  git clone --depth=1 --branch="$BRANCH" "https://github.com/$GITHUB_REPO.git" "$CLONE_PATH" || {
    echo "[$TOOL] Error: git clone failed" >&2
    exit 1
  }
else
  echo "[$TOOL] Updating repository at $CLONE_PATH" >&2
  cd "$CLONE_PATH"
  git fetch origin "$BRANCH" --depth=1 || {
    echo "[$TOOL] Error: git fetch failed" >&2
    exit 1
  }
  git reset --hard "origin/$BRANCH" || {
    echo "[$TOOL] Error: git reset failed" >&2
    exit 1
  }
  cd - >/dev/null
fi

# Get new version/commit
after=""
if [ -d "$CLONE_PATH/.git" ]; then
  cd "$CLONE_PATH"
  after="$(git rev-parse --short HEAD 2>/dev/null || echo "<unknown>")"
  cd - >/dev/null
fi

# Report
printf "[%s] before: %s\n" "$TOOL" "${before:-<none>}"
printf "[%s] after:  %s\n" "$TOOL" "${after:-<unknown>}"
printf "[%s] path:   %s\n" "$TOOL" "$CLONE_PATH"

# Refresh snapshot after successful installation
refresh_snapshot "$TOOL"
