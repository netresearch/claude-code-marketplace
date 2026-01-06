#!/usr/bin/env bash
# Main orchestrator for tool installation
# Reads catalog and delegates to appropriate installer or reconciliation system
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source reconciliation libraries
. "$DIR/lib/reconcile.sh"

TOOL="${1:-}"
ACTION="${2:-install}"

if [ -z "$TOOL" ]; then
  echo "Usage: $0 TOOL_NAME [ACTION]" >&2
  echo "Actions: install, update, reconcile, status, uninstall" >&2
  exit 1
fi

CATALOG_FILE="$DIR/../catalog/$TOOL.json"

# Check if tool has catalog entry
if [ ! -f "$CATALOG_FILE" ]; then
  echo "[$TOOL] Error: No catalog entry found" >&2
  echo "[$TOOL] Available tools: $(find "$DIR/../catalog" -name '*.json' -exec basename {} .json \; | tr '\n' ' ')" >&2
  exit 1
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not found" >&2
  exit 1
fi

# Read install method from catalog
INSTALL_METHOD="$(jq -r '.install_method' "$CATALOG_FILE")"

if [ -z "$INSTALL_METHOD" ] || [ "$INSTALL_METHOD" = "null" ]; then
  echo "[$TOOL] Error: No install_method specified in catalog" >&2
  exit 1
fi

# Check if tool uses reconciliation system (install_method == "auto")
if [ "$INSTALL_METHOD" = "auto" ]; then
  # Use reconciliation system
  case "$ACTION" in
    install|update|reconcile)
      # Pass the actual action to reconcile_tool
      reconcile_tool "$CATALOG_FILE" "$ACTION"
      exit $?
      ;;
    status)
      reconcile_tool "$CATALOG_FILE" "status"
      exit $?
      ;;
    uninstall)
      # Get current method and remove it
      binary_name="$(jq -r '.binary_name // ""' "$CATALOG_FILE" 2>/dev/null || echo "$TOOL")"
      current_method="$(detect_install_method "$TOOL" "$binary_name")"
      if [ "$current_method" != "none" ]; then
        remove_installation "$TOOL" "$current_method" "$binary_name"
        echo "[$TOOL] Uninstalled (was via $current_method)"
      else
        echo "[$TOOL] Not installed"
      fi
      exit 0
      ;;
    *)
      echo "[$TOOL] Error: Unknown action: $ACTION" >&2
      exit 1
      ;;
  esac
fi

# Traditional path: delegate to appropriate installer
INSTALLER_SCRIPT="$DIR/installers/${INSTALL_METHOD}.sh"

if [ ! -f "$INSTALLER_SCRIPT" ]; then
  echo "[$TOOL] Error: Installer not found: $INSTALLER_SCRIPT" >&2
  echo "[$TOOL] install_method: $INSTALL_METHOD" >&2
  exit 1
fi

if [ ! -x "$INSTALLER_SCRIPT" ]; then
  echo "[$TOOL] Error: Installer not executable: $INSTALLER_SCRIPT" >&2
  exit 1
fi

# Execute installer with all remaining arguments
shift  # Remove TOOL from $@
exec "$INSTALLER_SCRIPT" "$TOOL" "$@"
