#!/usr/bin/env bash
# capability.sh - Installation method detection and availability checking
#
# This library provides capability detection for the reconciliation system:
# 1. Detect current installation method for a tool
# 2. Check if installation methods are available on the system
# 3. Get detailed information about current installations

set -euo pipefail

# Detect which installation method was used for a tool
# Args: tool_name, binary_name
# Returns: apt|cargo|npm|gem|pip|pipx|brew|github_release_binary|unknown|none
detect_install_method() {
  local tool="$1"
  local binary="${2:-$tool}"

  # Check if binary exists
  if ! command -v "$binary" >/dev/null 2>&1; then
    echo "none"
    return 0
  fi

  local binary_path
  binary_path="$(command -v "$binary")"

  # Detect by path patterns
  case "$binary_path" in
    "$HOME/.cargo/bin/"*)
      echo "cargo"
      return 0
      ;;
    "$HOME/.local/bin/"*)
      # Could be github_release_binary or pipx
      # Check if pipx knows about it
      if command -v pipx >/dev/null 2>&1 && pipx list 2>/dev/null | grep -q "package $tool"; then
        echo "pipx"
      else
        echo "github_release_binary"
      fi
      return 0
      ;;
    "$HOME/.rbenv/"*)
      echo "gem"
      return 0
      ;;
    "$HOME/.nvm/"*)
      echo "npm"
      return 0
      ;;
    "/usr/local/bin/"*)
      # Could be brew or manual install
      if command -v brew >/dev/null 2>&1 && brew list --formula 2>/dev/null | grep -q "^${tool}\$"; then
        echo "brew"
      else
        echo "unknown"
      fi
      return 0
      ;;
    "/usr/bin/"*|"/bin/"*)
      # Check if it's an apt package
      if command -v dpkg >/dev/null 2>&1; then
        if dpkg -S "$binary_path" >/dev/null 2>&1; then
          echo "apt"
          return 0
        fi
      fi
      # Check if it's pip-installed
      if command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
        local pip_cmd="${PIP:-pip3}"
        if ! command -v "$pip_cmd" >/dev/null 2>&1; then
          pip_cmd="pip"
        fi
        if "$pip_cmd" show "$tool" >/dev/null 2>&1; then
          echo "pip"
          return 0
        fi
      fi
      echo "unknown"
      return 0
      ;;
    *)
      echo "unknown"
      return 0
      ;;
  esac
}

# Check if an installation method is available on this system
# Args: method_name
# Returns: 0 if available, 1 if not
is_method_available() {
  local method="$1"

  case "$method" in
    apt)
      # Check if dpkg exists and user has sudo access (or is root)
      if ! command -v dpkg >/dev/null 2>&1; then
        return 1
      fi
      # Check sudo access (try non-interactively)
      if [ "$(id -u)" -eq 0 ]; then
        return 0  # root user
      fi
      if sudo -n true 2>/dev/null; then
        return 0  # Has cached sudo credentials
      fi
      # Can't determine sudo access without prompting, assume available
      # The actual operation will fail if sudo isn't available
      return 0
      ;;
    cargo)
      command -v cargo >/dev/null 2>&1
      return $?
      ;;
    npm)
      command -v npm >/dev/null 2>&1
      return $?
      ;;
    gem)
      command -v gem >/dev/null 2>&1
      return $?
      ;;
    pip)
      command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1
      return $?
      ;;
    pipx)
      command -v pipx >/dev/null 2>&1
      return $?
      ;;
    brew)
      command -v brew >/dev/null 2>&1
      return $?
      ;;
    github_release_binary)
      # Check if we have curl or wget, and can write to ~/.local/bin
      if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
        if [ -d "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin" 2>/dev/null; then
          return 0
        fi
      fi
      return 1
      ;;
    dedicated_script)
      # Dedicated scripts are always "available" as they handle their own logic
      return 0
      ;;
    *)
      echo "Unknown method: $method" >&2
      return 1
      ;;
  esac
}

# Get detailed information about current installation
# Args: tool_name, binary_name
# Returns: JSON-like output with path, method, package info
get_current_method_details() {
  local tool="$1"
  local binary="${2:-$tool}"

  if ! command -v "$binary" >/dev/null 2>&1; then
    echo "method=none"
    return 0
  fi

  local binary_path
  binary_path="$(command -v "$binary")"
  local method
  method="$(detect_install_method "$tool" "$binary")"

  echo "path=$binary_path"
  echo "method=$method"

  # Get additional details based on method
  case "$method" in
    apt)
      if command -v dpkg >/dev/null 2>&1; then
        local pkg
        pkg="$(dpkg -S "$binary_path" 2>/dev/null | cut -d: -f1 || echo "unknown")"
        echo "package=$pkg"
        local version
        version="$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "unknown")"
        echo "version=$version"
      fi
      ;;
    cargo)
      if command -v cargo >/dev/null 2>&1; then
        # Try to get version from cargo
        local version
        version="$("$binary" --version 2>/dev/null | head -1 || echo "unknown")"
        echo "version=$version"
      fi
      ;;
    npm)
      if command -v npm >/dev/null 2>&1; then
        local version
        version="$(npm list -g --depth=0 2>/dev/null | grep "$tool@" | sed 's/.*@//' || echo "unknown")"
        echo "version=$version"
      fi
      ;;
    pip|pipx)
      local pip_cmd="${PIP:-pip3}"
      if ! command -v "$pip_cmd" >/dev/null 2>&1; then
        pip_cmd="pip"
      fi
      if command -v "$pip_cmd" >/dev/null 2>&1; then
        local version
        version="$("$pip_cmd" show "$tool" 2>/dev/null | grep "^Version:" | awk '{print $2}' || echo "unknown")"
        echo "version=$version"
      fi
      ;;
    brew)
      if command -v brew >/dev/null 2>&1; then
        local version
        version="$(brew info "$tool" 2>/dev/null | head -1 | awk '{print $3}' || echo "unknown")"
        echo "version=$version"
      fi
      ;;
    github_release_binary)
      local version
      version="$("$binary" --version 2>/dev/null | head -1 || echo "unknown")"
      echo "version=$version"
      ;;
  esac
}

# List all available installation methods on this system
list_available_methods() {
  local methods=("apt" "cargo" "npm" "gem" "pip" "pipx" "brew" "github_release_binary")
  local available=()

  for method in "${methods[@]}"; do
    if is_method_available "$method"; then
      available+=("$method")
    fi
  done

  printf '%s\n' "${available[@]}"
}

# Check if a specific tool can be installed via a method
# This checks both method availability AND tool-specific requirements
# Args: tool_name, method, catalog_config (JSON string)
can_install_via_method() {
  local tool="$1"
  local method="$2"
  local config="${3:-{}}"

  # First check if method is available
  if ! is_method_available "$method"; then
    return 1
  fi

  # Method-specific checks could go here
  # For now, if method is available, assume tool can be installed
  return 0
}
