#!/usr/bin/env bash
# Shared installation strategy logic for all install scripts

# Determine installation directory based on INSTALL_STRATEGY
# Usage: get_install_dir TOOL_NAME
# Returns: Directory path where tool should be installed
get_install_dir() {
  local tool_name="${1:-}"
  local strategy="${INSTALL_STRATEGY:-USER}"
  local prefix="${PREFIX:-$HOME/.local}"
  local bin_dir=""

  case "$strategy" in
    CURRENT)
      # Keep tool where it is currently installed
      if [ -n "$tool_name" ]; then
        local current_path="$(command -v "$tool_name" 2>/dev/null || true)"
        if [ -n "$current_path" ]; then
          bin_dir="$(dirname "$current_path")"
        else
          # Not installed, fall back to USER
          bin_dir="$prefix/bin"
        fi
      else
        # No specific tool, fall back to USER
        bin_dir="$prefix/bin"
      fi
      ;;
    GLOBAL)
      bin_dir="/usr/local/bin"
      ;;
    PROJECT)
      bin_dir="./.local/bin"
      ;;
    USER|*)
      bin_dir="$prefix/bin"
      ;;
  esac

  echo "$bin_dir"
}

# Get install command based on target directory
# Usage: get_install_cmd BIN_DIR
# Sets: INSTALL and RM variables
get_install_cmd() {
  local bin_dir="$1"

  if [ "$bin_dir" = "/usr/local/bin" ]; then
    if [ -w "$bin_dir" ]; then
      INSTALL="install -m 0755"
      RM="rm -f"
    else
      INSTALL="sudo install -m 0755"
      RM="sudo rm -f"
    fi
  else
    INSTALL="install -m 0755"
    RM="rm -f"
  fi
}

# Refresh snapshot for a specific tool after installation
# Usage: refresh_snapshot TOOL_NAME
# Updates tools_snapshot.json with latest version of installed tool
refresh_snapshot() {
  local tool_name="${1:-}"

  if [ -z "$tool_name" ]; then
    echo "# Warning: No tool name provided to refresh_snapshot" >&2
    return 1
  fi

  # Path to project root (scripts/lib -> scripts -> root)
  local project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  local audit_script="$project_root/audit.py"

  if [ ! -f "$audit_script" ]; then
    echo "# Warning: audit.py not found at $audit_script" >&2
    return 1
  fi

  echo "# Refreshing snapshot for $tool_name..." >&2

  # Brief delay to ensure binary is fully updated and PATH is refreshed
  sleep 0.5

  # Run audit in merge mode for this specific tool
  CLI_AUDIT_COLLECT=1 CLI_AUDIT_MERGE=1 python3 "$audit_script" "$tool_name" >/dev/null 2>&1 || {
    echo "# Warning: Failed to refresh snapshot for $tool_name" >&2
    return 1
  }

  echo "# ✓ Snapshot updated for $tool_name" >&2
  return 0
}
