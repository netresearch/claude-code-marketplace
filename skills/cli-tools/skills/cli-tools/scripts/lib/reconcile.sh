#!/usr/bin/env bash
# reconcile.sh - Installation method reconciliation
#
# This library aligns reality with policy:
# - Detects current installation method
# - Resolves best method via policy
# - Removes current installation if it doesn't match best
# - Installs via best method

set -euo pipefail

RECONCILE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$RECONCILE_LIB_DIR/common.sh"
. "$RECONCILE_LIB_DIR/capability.sh"
. "$RECONCILE_LIB_DIR/policy.sh"

# Remove an installation via a specific method
# Args: tool_name, method, binary_name
remove_installation() {
  local tool="$1"
  local method="$2"
  local binary="${3:-$tool}"

  echo "[$tool] Removing installation via $method..." >&2

  case "$method" in
    apt)
      # Find package name
      local binary_path
      binary_path="$(command -v "$binary" 2>/dev/null || echo "")"
      if [ -z "$binary_path" ]; then
        echo "[$tool] Binary not found, nothing to remove" >&2
        return 0
      fi

      if command -v dpkg >/dev/null 2>&1; then
        local pkg
        pkg="$(dpkg -S "$binary_path" 2>/dev/null | cut -d: -f1 || echo "")"
        if [ -n "$pkg" ]; then
          echo "[$tool] Removing apt package: $pkg" >&2
          apt_remove_if_present "$pkg" || true
        fi
      fi
      ;;
    cargo)
      if command -v cargo >/dev/null 2>&1; then
        echo "[$tool] Uninstalling cargo package: $tool" >&2
        cargo uninstall "$tool" 2>/dev/null || true
      fi
      ;;
    npm)
      if command -v npm >/dev/null 2>&1; then
        echo "[$tool] Uninstalling npm global package: $tool" >&2
        npm uninstall -g "$tool" 2>/dev/null || true
      fi
      ;;
    gem)
      if command -v gem >/dev/null 2>&1; then
        echo "[$tool] Uninstalling gem: $tool" >&2
        gem uninstall -x "$tool" 2>/dev/null || true
      fi
      ;;
    pip|pipx)
      if command -v pipx >/dev/null 2>&1 && pipx list 2>/dev/null | grep -q "package $tool"; then
        echo "[$tool] Uninstalling pipx package: $tool" >&2
        pipx uninstall "$tool" 2>/dev/null || true
      elif command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
        local pip_cmd="${PIP:-pip3}"
        if ! command -v "$pip_cmd" >/dev/null 2>&1; then
          pip_cmd="pip"
        fi
        echo "[$tool] Uninstalling pip package: $tool" >&2
        "$pip_cmd" uninstall -y "$tool" 2>/dev/null || true
      fi
      ;;
    brew)
      if command -v brew >/dev/null 2>&1; then
        echo "[$tool] Uninstalling brew formula: $tool" >&2
        brew uninstall "$tool" 2>/dev/null || true
      fi
      ;;
    github_release_binary)
      local binary_path
      binary_path="$(command -v "$binary" 2>/dev/null || echo "")"
      if [ -n "$binary_path" ] && [ -f "$binary_path" ]; then
        echo "[$tool] Removing binary: $binary_path" >&2
        rm -f "$binary_path" || true
      fi
      ;;
    unknown|none)
      echo "[$tool] Unknown installation method, cannot remove automatically" >&2
      return 1
      ;;
    *)
      echo "[$tool] Unsupported removal method: $method" >&2
      return 1
      ;;
  esac

  return 0
}

# Install a tool via a specific method
# Args: tool_name, method, config_json, binary_name
install_via_method() {
  local tool="$1"
  local method="$2"
  local config="${3:-{}}"
  local binary="${4:-$tool}"

  echo "[$tool] Installing via $method..." >&2

  case "$method" in
    apt)
      local package
      if command -v jq >/dev/null 2>&1; then
        package="$(echo "$config" | jq -r '.package // ""')"
      fi
      package="${package:-$tool}"

      echo "[$tool] Installing apt package: $package" >&2
      apt_install_if_missing "$package" || return 1
      ;;
    cargo)
      local crate
      if command -v jq >/dev/null 2>&1; then
        crate="$(echo "$config" | jq -r '.crate // ""')"
      fi
      crate="${crate:-$tool}"

      echo "[$tool] Installing cargo crate: $crate" >&2
      cargo install "$crate" || return 1
      ;;
    npm)
      local package
      if command -v jq >/dev/null 2>&1; then
        package="$(echo "$config" | jq -r '.package // ""')"
      fi
      package="${package:-$tool}"

      echo "[$tool] Installing npm global package: $package" >&2
      npm install -g "$package" || return 1
      ;;
    gem)
      local gem_name
      if command -v jq >/dev/null 2>&1; then
        gem_name="$(echo "$config" | jq -r '.gem // ""')"
      fi
      gem_name="${gem_name:-$tool}"

      echo "[$tool] Installing gem: $gem_name" >&2
      gem install "$gem_name" || return 1
      ;;
    pip)
      local package
      if command -v jq >/dev/null 2>&1; then
        package="$(echo "$config" | jq -r '.package // ""')"
      fi
      package="${package:-$tool}"

      local pip_cmd="${PIP:-pip3}"
      if ! command -v "$pip_cmd" >/dev/null 2>&1; then
        pip_cmd="pip"
      fi

      echo "[$tool] Installing pip package: $package" >&2
      "$pip_cmd" install "$package" || return 1
      ;;
    pipx)
      local package
      if command -v jq >/dev/null 2>&1; then
        package="$(echo "$config" | jq -r '.package // ""')"
      fi
      package="${package:-$tool}"

      echo "[$tool] Installing pipx package: $package" >&2
      pipx install "$package" || return 1
      ;;
    brew)
      local formula
      if command -v jq >/dev/null 2>&1; then
        formula="$(echo "$config" | jq -r '.formula // ""')"
      fi
      formula="${formula:-$tool}"

      echo "[$tool] Installing brew formula: $formula" >&2
      brew install "$formula" || return 1
      ;;
    github_release_binary)
      # Use existing github_release_binary.sh installer
      local installer="$RECONCILE_LIB_DIR/../installers/github_release_binary.sh"
      if [ ! -f "$installer" ]; then
        echo "[$tool] Error: github_release_binary installer not found" >&2
        return 1
      fi

      # The github_release_binary installer expects catalog file as input
      # We need to temporarily set up environment for it
      echo "[$tool] Installing via GitHub release binary installer" >&2
      "$installer" "$tool" install || return 1
      ;;
    *)
      echo "[$tool] Unsupported installation method: $method" >&2
      return 1
      ;;
  esac

  return 0
}

# Main reconciliation function
# Args: catalog_file, action (reconcile|status)
reconcile_tool() {
  local catalog_file="$1"
  local action="${2:-reconcile}"
  local tool
  tool="$(basename "$catalog_file" .json)"

  # Load catalog metadata
  if ! command -v jq >/dev/null 2>&1; then
    echo "[$tool] Error: jq not available, cannot parse catalog" >&2
    return 1
  fi

  local install_method
  install_method="$(jq -r '.install_method // ""' "$catalog_file" 2>/dev/null || echo "")"

  # Check if tool uses reconciliation
  if [ "$install_method" != "auto" ]; then
    if [ "$action" = "status" ]; then
      echo "[$tool] Uses dedicated installer (install_method: $install_method), reconciliation not applicable"
    fi
    return 0
  fi

  local binary_name
  binary_name="$(jq -r '.binary_name // ""' "$catalog_file" 2>/dev/null || echo "$tool")"

  # Detect current installation
  local current_method
  current_method="$(detect_install_method "$tool" "$binary_name")"

  # Resolve best method via policy
  local best_method
  best_method="$(resolve_best_method "$catalog_file" 2>&1)"
  if [ $? -ne 0 ]; then
    echo "[$tool] Error resolving best method: $best_method" >&2
    return 1
  fi

  # Status mode: just report
  if [ "$action" = "status" ]; then
    echo "[$tool] Current method: $current_method"
    echo "[$tool] Best method: $best_method"
    if [ "$current_method" = "$best_method" ]; then
      echo "[$tool] Status: ✓ Already using best method"
    elif [ "$current_method" = "none" ]; then
      echo "[$tool] Status: Not installed, would install via $best_method"
    else
      echo "[$tool] Status: ⚠ Reconciliation needed (current: $current_method → best: $best_method)"
    fi
    return 0
  fi

  # Reconcile mode: align current with best
  if [ "$current_method" = "$best_method" ]; then
    # If action is "reconcile" (not update/install), skip if already via best method
    if [ "$action" = "reconcile" ]; then
      echo "[$tool] ✓ Already installed via best method: $best_method" >&2
      return 0
    fi
    # For update/install action, continue to reinstall/upgrade even if via best method
    echo "[$tool] Upgrading (currently via $best_method)" >&2
  fi

  if [ "$current_method" = "none" ]; then
    echo "[$tool] Not installed, installing via best method: $best_method" >&2
  else
    echo "[$tool] Reconciliation needed: current=$current_method, best=$best_method" >&2

    # Remove current installation
    if ! remove_installation "$tool" "$current_method" "$binary_name"; then
      echo "[$tool] Error: Failed to remove current installation via $current_method" >&2
      return 1
    fi
  fi

  # Get method config
  local method_config
  method_config="$(get_method_config "$catalog_file" "$best_method")"

  # Install via best method
  if ! install_via_method "$tool" "$best_method" "$method_config" "$binary_name"; then
    echo "[$tool] Error: Failed to install via $best_method" >&2
    return 1
  fi

  # Verify installation
  if command -v "$binary_name" >/dev/null 2>&1; then
    local new_method
    new_method="$(detect_install_method "$tool" "$binary_name")"
    echo "[$tool] ✓ Reconciliation complete: now installed via $new_method" >&2
    return 0
  else
    echo "[$tool] Error: Installation via $best_method completed but binary not found" >&2
    return 1
  fi
}

# Batch reconciliation for multiple tools
# Args: catalog_dir, action (reconcile|status)
reconcile_all_tools() {
  local catalog_dir="$1"
  local action="${2:-reconcile}"

  if [ ! -d "$catalog_dir" ]; then
    echo "Error: Catalog directory not found: $catalog_dir" >&2
    return 1
  fi

  local tool_count=0
  local reconciled_count=0
  local error_count=0

  for catalog_file in "$catalog_dir"/*.json; do
    [ -f "$catalog_file" ] || continue

    local tool
    tool="$(basename "$catalog_file" .json)"
    tool_count=$((tool_count + 1))

    if reconcile_tool "$catalog_file" "$action"; then
      reconciled_count=$((reconciled_count + 1))
    else
      error_count=$((error_count + 1))
    fi
  done

  echo ""
  echo "Summary: $tool_count tools processed, $reconciled_count succeeded, $error_count errors"
  return 0
}
