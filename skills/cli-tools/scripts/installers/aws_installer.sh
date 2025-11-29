#!/usr/bin/env bash
# AWS CLI installer
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$DIR/lib/install_strategy.sh"

TOOL="${1:-aws}"
CATALOG_FILE="$DIR/../catalog/$TOOL.json"

if [ ! -f "$CATALOG_FILE" ]; then
  echo "Error: Catalog file not found: $CATALOG_FILE" >&2
  exit 1
fi

# Parse catalog
INSTALLER_URL="$(jq -r '.installer_url' "$CATALOG_FILE")"
BINARY_NAME="$(jq -r '.binary_name' "$CATALOG_FILE")"

# Get current version
before="$(command -v "$BINARY_NAME" >/dev/null 2>&1 && "$BINARY_NAME" --version || true)"

# Determine installation directory
BIN_DIR="$(get_install_dir "$BINARY_NAME")"
get_install_cmd "$BIN_DIR"
mkdir -p "$BIN_DIR" 2>/dev/null || true

# Download and install
TMP="$(mktemp -d)"
cd "$TMP"
curl -fsSL "$INSTALLER_URL" -o awscliv2.zip
unzip -q awscliv2.zip

# AWS installer supports --bin-dir and --install-dir options
./aws/install --bin-dir "$BIN_DIR" --install-dir "${BIN_DIR%/bin}/aws-cli" --update 2>/dev/null || \
  ./aws/install --bin-dir "$BIN_DIR" --install-dir "${BIN_DIR%/bin}/aws-cli" 2>/dev/null || true

cd - >/dev/null
rm -rf "$TMP"

# Report
after="$(command -v "$BINARY_NAME" >/dev/null 2>&1 && "$BINARY_NAME" --version || true)"
path="$(command -v "$BINARY_NAME" 2>/dev/null || true)"
printf "[%s] before: %s\n" "$TOOL" "${before:-<none>}"
printf "[%s] after:  %s\n" "$TOOL" "${after:-<none>}"
if [ -n "$path" ]; then printf "[%s] path:   %s\n" "$TOOL" "$path"; fi

# Refresh snapshot after successful installation
refresh_snapshot "$TOOL"
