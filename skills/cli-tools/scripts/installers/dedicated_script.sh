#!/usr/bin/env bash
# Delegator for tools with dedicated installation scripts
# Reads catalog to find which script to run, then delegates
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

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not found" >&2
  exit 1
fi

# Read script name from catalog
SCRIPT_NAME="$(jq -r '.script' "$CATALOG_FILE")"

if [ -z "$SCRIPT_NAME" ] || [ "$SCRIPT_NAME" = "null" ]; then
  echo "[$TOOL] Error: No script specified in catalog" >&2
  exit 1
fi

SCRIPT_PATH="$DIR/$SCRIPT_NAME"

if [ ! -f "$SCRIPT_PATH" ]; then
  echo "[$TOOL] Error: Script not found: $SCRIPT_PATH" >&2
  exit 1
fi

if [ ! -x "$SCRIPT_PATH" ]; then
  echo "[$TOOL] Error: Script not executable: $SCRIPT_PATH" >&2
  exit 1
fi

# Delegate to dedicated script (skip TOOL argument, pass only ACTION)
shift  # Remove TOOL from $@
exec "$SCRIPT_PATH" "$@"
