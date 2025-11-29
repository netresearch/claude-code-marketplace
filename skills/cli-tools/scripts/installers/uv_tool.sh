#!/usr/bin/env bash
# Generic installer for uv tools
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
PACKAGE_NAME="$(jq -r '.package_name' "$CATALOG_FILE")"
PYTHON_VERSION="$(jq -r '.python_version // empty' "$CATALOG_FILE")"

# Ensure uv is available
if ! command -v uv >/dev/null 2>&1; then
  echo "[$TOOL] Error: uv not found. Please install uv first." >&2
  exit 1
fi

# Get current version (skip for tools that hang on --version)
if [ "$TOOL" = "codex" ] || [ "$TOOL" = "gam" ]; then
  # codex/gam binaries hang on --version - will use uv tool list instead
  before="<none>"
else
  before="$(command -v "$TOOL" >/dev/null 2>&1 && timeout 2 "$TOOL" --version </dev/null 2>/dev/null || true)"
fi

# Install or upgrade with optional Python version pinning
if [ -n "$PYTHON_VERSION" ]; then
  echo "[$TOOL] Installing with Python $PYTHON_VERSION..."
  uv tool install --force --upgrade --python "$PYTHON_VERSION" "$PACKAGE_NAME" || true
else
  uv tool install --force --upgrade "$PACKAGE_NAME" || true
fi

# Report
if [ "$TOOL" = "codex" ] || [ "$TOOL" = "gam" ]; then
  # codex/gam binaries hang on --version - use uv tool list instead
  after="$(uv tool list 2>/dev/null | grep -E "^(codex|gam7) " | head -1 || echo "<failed>")"
else
  after="$(command -v "$TOOL" >/dev/null 2>&1 && timeout 2 "$TOOL" --version 2>/dev/null || true)"
fi
path="$(command -v "$TOOL" 2>/dev/null || true)"
printf "[%s] before: %s\n" "$TOOL" "${before:-<none>}"
printf "[%s] after:  %s\n" "$TOOL" "${after:-<none>}"
if [ -n "$path" ]; then printf "[%s] path:   %s\n" "$TOOL" "$path"; fi

# Refresh snapshot after successful installation
# Source install_strategy.sh for refresh_snapshot function
. "$(dirname "${BASH_SOURCE[0]}")/../lib/install_strategy.sh"
refresh_snapshot "$TOOL"
