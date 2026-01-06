#!/usr/bin/env bash
# Generic installer for HashiCorp zip releases
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
PRODUCT_NAME="$(jq -r '.product_name' "$CATALOG_FILE")"
BINARY_NAME="$(jq -r '.binary_name' "$CATALOG_FILE")"
GITHUB_REPO="$(jq -r '.github_repo // empty' "$CATALOG_FILE")"

# Get current version
before="$(command -v "$BINARY_NAME" >/dev/null 2>&1 && "$BINARY_NAME" version 2>/dev/null | head -n1 || true)"

# Detect OS and architecture
OS="linux"
ARCH_RAW="$(uname -m)"
ARCH="$ARCH_RAW"

# Apply architecture mapping if present
if jq -e ".arch_map.\"$ARCH_RAW\"" "$CATALOG_FILE" >/dev/null 2>&1; then
  ARCH="$(jq -r ".arch_map.\"$ARCH_RAW\"" "$CATALOG_FILE")"
fi

# Determine installation directory
BIN_DIR="$(get_install_dir "$BINARY_NAME")"
get_install_cmd "$BIN_DIR"
mkdir -p "$BIN_DIR" 2>/dev/null || true

# Remove distro package first if it exists
apt_remove_if_present "$BINARY_NAME" || true

# Get latest version from GitHub releases
LATEST_TAG=""
if [ -n "$GITHUB_REPO" ]; then
  LATEST_TAG="$(curl -fsSIL -H "User-Agent: cli-audit" -o /dev/null -w '%{url_effective}' \
    "https://github.com/$GITHUB_REPO/releases/latest" 2>/dev/null | awk -F'/' '{print $NF}')"
fi

VER="${LATEST_TAG#v}"
if [ -z "$VER" ]; then
  echo "[$TOOL] Error: Could not resolve latest version" >&2
  echo "[$TOOL] before: ${before:-<none>}" >&2
  exit 1
fi

# Download and install
TMP="$(mktemp -d)"
URL="https://releases.hashicorp.com/${PRODUCT_NAME}/${VER}/${PRODUCT_NAME}_${VER}_${OS}_${ARCH}.zip"

if curl -fsSL "$URL" -o "$TMP/${PRODUCT_NAME}.zip"; then
  unzip -q "$TMP/${PRODUCT_NAME}.zip" -d "$TMP" || true
  if [ -f "$TMP/$BINARY_NAME" ]; then
    $INSTALL "$TMP/$BINARY_NAME" "$BIN_DIR/$BINARY_NAME"
  else
    echo "[$TOOL] Error: Binary not found in zip" >&2
    rm -rf "$TMP"
    exit 1
  fi
else
  echo "[$TOOL] Error: Download failed from $URL" >&2
  rm -rf "$TMP"
  exit 1
fi

rm -rf "$TMP"

# Report
after="$(command -v "$BINARY_NAME" >/dev/null 2>&1 && "$BINARY_NAME" version 2>/dev/null | head -n1 || true)"
path="$(command -v "$BINARY_NAME" 2>/dev/null || true)"
printf "[%s] before: %s\n" "$TOOL" "${before:-<none>}"
printf "[%s] after:  %s\n" "$TOOL" "${after:-<none>}"
if [ -n "$path" ]; then printf "[%s] path:   %s\n" "$TOOL" "$path"; fi

# Refresh snapshot after successful installation
refresh_snapshot "$TOOL"
