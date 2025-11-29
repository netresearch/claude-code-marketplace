#!/usr/bin/env bash
# Generic installer for package manager tools
# Installs tools via system package managers (apt, brew, etc.)
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

# Parse catalog
BINARY_NAME="$(jq -r '.binary_name // .name' "$CATALOG_FILE")"
PACKAGES="$(jq -r '.packages // {}' "$CATALOG_FILE")"
NOTES="$(jq -r '.notes // empty' "$CATALOG_FILE")"
VERSION_CMD="$(jq -r '.version_command // empty' "$CATALOG_FILE")"

# Get current version
if [ -n "$VERSION_CMD" ]; then
  # Use custom version command if specified
  before="$(eval "$VERSION_CMD" 2>/dev/null || true)"
else
  # Default version detection
  before="$(command -v "$BINARY_NAME" >/dev/null 2>&1 && timeout 2 "$BINARY_NAME" --version </dev/null 2>/dev/null | head -1 || true)"
fi

# Check if tool is already available (e.g., comes with runtime)
if command -v "$BINARY_NAME" >/dev/null 2>&1; then
  if [ -n "$NOTES" ] && echo "$NOTES" | grep -q "comes with\|bundled with"; then
    # Tool is already available and comes bundled
    after="$before"
    path="$(command -v "$BINARY_NAME" 2>/dev/null || true)"
    printf "[%s] before: %s\n" "$TOOL" "${before:-<none>}"
    printf "[%s] after:  %s\n" "$TOOL" "${after:-<none>}"
    if [ -n "$path" ]; then printf "[%s] path:   %s\n" "$TOOL" "$path"; fi
    printf "[%s] note:   %s\n" "$TOOL" "Already available (bundled with runtime)"

    # Refresh snapshot to record current version
    refresh_snapshot "$TOOL"
    exit 0
  fi
fi

# Install via appropriate package manager
installed=false

if have brew; then
  pkg="$(echo "$PACKAGES" | jq -r '.brew // empty')"
  if [ "$pkg" != "null" ] && [ -n "$pkg" ]; then
    brew install "$pkg" || brew upgrade "$pkg" || true
    installed=true
  fi
fi

if ! $installed && have apt-get; then
  pkg="$(echo "$PACKAGES" | jq -r '.apt // empty')"
  if [ "$pkg" != "null" ] && [ -n "$pkg" ]; then
    sudo apt-get update && sudo apt-get install -y "$pkg" || true
    installed=true
  fi
fi

if ! $installed && have dnf; then
  pkg="$(echo "$PACKAGES" | jq -r '.dnf // .rpm // empty')"
  if [ "$pkg" != "null" ] && [ -n "$pkg" ]; then
    sudo dnf install -y "$pkg" || true
    installed=true
  fi
fi

if ! $installed && have pacman; then
  pkg="$(echo "$PACKAGES" | jq -r '.pacman // .arch // empty')"
  if [ "$pkg" != "null" ] && [ -n "$pkg" ]; then
    sudo pacman -S --noconfirm "$pkg" || true
    installed=true
  fi
fi

if ! $installed; then
  echo "[$TOOL] No supported package manager found (tried: brew, apt, dnf, pacman)" >&2
  exit 1
fi

# Report
if [ -n "$VERSION_CMD" ]; then
  # Use custom version command if specified
  after="$(eval "$VERSION_CMD" 2>/dev/null || true)"
else
  # Default version detection
  after="$(command -v "$BINARY_NAME" >/dev/null 2>&1 && timeout 2 "$BINARY_NAME" --version </dev/null 2>/dev/null | head -1 || true)"
fi
path="$(command -v "$BINARY_NAME" 2>/dev/null || true)"
printf "[%s] before: %s\n" "$TOOL" "${before:-<none>}"
printf "[%s] after:  %s\n" "$TOOL" "${after:-<none>}"
if [ -n "$path" ]; then printf "[%s] path:   %s\n" "$TOOL" "$path"; fi

# Refresh snapshot after successful installation
# Need to source install_strategy.sh for refresh_snapshot function
. "$(dirname "${BASH_SOURCE[0]}")/../lib/install_strategy.sh"
refresh_snapshot "$TOOL"
