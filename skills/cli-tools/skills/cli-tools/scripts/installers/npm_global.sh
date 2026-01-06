#!/usr/bin/env bash
# Generic installer for npm global packages
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$DIR/lib/install_strategy.sh"

# Load nvm if available (needed for node-based package managers)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh" --no-use
  nvm use default >/dev/null 2>&1 || true
fi

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

# Parse catalog
PACKAGE_NAME="$(jq -r '.package_name // .name' "$CATALOG_FILE")"

# Detect available package manager (pnpm > npm > yarn)
PKG_MANAGER=""
if command -v pnpm >/dev/null 2>&1; then
  PKG_MANAGER="pnpm"
elif command -v npm >/dev/null 2>&1; then
  PKG_MANAGER="npm"
elif command -v yarn >/dev/null 2>&1; then
  PKG_MANAGER="yarn"
fi

if [ -z "$PKG_MANAGER" ]; then
  echo "[$TOOL] Error: No package manager found (pnpm, npm, or yarn required)" >&2
  exit 1
fi

# Get current version
before=""
if command -v "$TOOL" >/dev/null 2>&1; then
  before="$("$TOOL" --version 2>/dev/null || true)"
fi

# Install or upgrade globally
echo "[$TOOL] Installing package globally via $PKG_MANAGER: $PACKAGE_NAME" >&2
case "$PKG_MANAGER" in
  pnpm)
    pnpm add -g "$PACKAGE_NAME" || {
      echo "[$TOOL] Error: pnpm install failed" >&2
      exit 1
    }
    ;;
  npm)
    npm install -g "$PACKAGE_NAME" || {
      echo "[$TOOL] Error: npm install failed" >&2
      exit 1
    }
    ;;
  yarn)
    yarn global add "$PACKAGE_NAME" || {
      echo "[$TOOL] Error: yarn install failed" >&2
      exit 1
    }
    ;;
esac

# Report
after=""
if command -v "$TOOL" >/dev/null 2>&1; then
  after="$("$TOOL" --version 2>/dev/null || true)"
fi

path="$(command -v "$TOOL" 2>/dev/null || true)"
printf "[%s] before: %s\n" "$TOOL" "${before:-<none>}"
printf "[%s] after:  %s\n" "$TOOL" "${after:-<none>}"
if [ -n "$path" ]; then printf "[%s] path:   %s\n" "$TOOL" "$path"; fi

# Refresh snapshot after successful installation
refresh_snapshot "$TOOL"
