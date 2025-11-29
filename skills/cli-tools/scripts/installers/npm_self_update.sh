#!/usr/bin/env bash
# npm installer - upgrades npm independently from Node.js
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$DIR/lib/common.sh"
. "$DIR/lib/install_strategy.sh"

TOOL="${1:-}"
if [ -z "$TOOL" ]; then
  echo "Usage: $0 TOOL_NAME" >&2
  exit 1
fi

CATALOG_FILE="$DIR/../catalog/$TOOL.json"
if [ ! -f "$CATALOG_FILE" ]; then
  echo "Error: Catalog file not found: $CATALOG_FILE" >&2
  exit 1
fi

BINARY_NAME="npm"

# Get current version
before="$(timeout 2 npm --version </dev/null 2>/dev/null || echo '<none>')"

# Check if npm is available
if ! command -v npm >/dev/null 2>&1; then
  echo "[$TOOL] Error: npm not found. Install Node.js first." >&2
  exit 1
fi

# Upgrade npm to latest version
# npm can be upgraded independently from Node.js
echo "[$TOOL] Upgrading npm to latest version..."
npm install -g npm@latest 2>&1 | grep -v "^npm " || true

# Get new version
after="$(timeout 2 npm --version </dev/null 2>/dev/null || echo '<none>')"
path="$(command -v npm 2>/dev/null || true)"

# Report
printf "[%s] before: %s\n" "$TOOL" "${before:-<none>}"
printf "[%s] after:  %s\n" "$TOOL" "${after:-<none>}"
if [ -n "$path" ]; then printf "[%s] path:   %s\n" "$TOOL" "$path"; fi

if [ "$before" != "$after" ]; then
  echo "[$TOOL] Successfully upgraded: $before → $after"
else
  echo "[$TOOL] Already at latest version: $after"
fi

# Refresh snapshot after successful installation
refresh_snapshot "$TOOL"
