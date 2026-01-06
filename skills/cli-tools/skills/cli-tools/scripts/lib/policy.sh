#!/usr/bin/env bash
# policy.sh - Installation method policy resolution
#
# This library resolves which installation method to use by evaluating:
# 1. Catalog available methods + priorities (maintainer knowledge)
# 2. User preferences (user configuration)
# 3. System capabilities (what's actually available)
#
# Decision: best_method = highest priority from (catalog ∩ user ∩ available)

set -euo pipefail

POLICY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$POLICY_LIB_DIR/capability.sh"

# Default config location
CONFIG_FILE="${AI_CLI_PREP_CONFIG:-$HOME/.ai_cli_prep/config.json}"

# Get user's preferred strategy from config
# Returns: auto|github_first|cargo_first|apt_first|npm_first
get_user_strategy() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "auto"
    return 0
  fi

  # Parse JSON config for preferred_strategy
  if command -v jq >/dev/null 2>&1; then
    local strategy
    strategy="$(jq -r '.preferred_strategy // "auto"' "$CONFIG_FILE" 2>/dev/null || echo "auto")"
    echo "$strategy"
  else
    # Fallback without jq - simple grep
    if grep -q '"preferred_strategy"' "$CONFIG_FILE" 2>/dev/null; then
      grep '"preferred_strategy"' "$CONFIG_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/' || echo "auto"
    else
      echo "auto"
    fi
  fi
}

# Get user override for a specific tool
# Args: tool_name
# Returns: method name or empty string
get_user_override() {
  local tool="$1"

  if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    return 0
  fi

  # Parse JSON config for overrides.tool
  if command -v jq >/dev/null 2>&1; then
    local override
    override="$(jq -r ".overrides.\"$tool\" // empty" "$CONFIG_FILE" 2>/dev/null || echo "")"
    echo "$override"
  else
    # Fallback without jq
    if grep -q "\"$tool\"" "$CONFIG_FILE" 2>/dev/null; then
      grep "\"$tool\"" "$CONFIG_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/' || echo ""
    else
      echo ""
    fi
  fi
}

# Check if user config allows sudo operations
# Returns: 0 if allowed, 1 if not
is_sudo_allowed() {
  if [ ! -f "$CONFIG_FILE" ]; then
    return 0  # Default: allow sudo
  fi

  if command -v jq >/dev/null 2>&1; then
    local allow_sudo
    allow_sudo="$(jq -r '.allow_sudo // true' "$CONFIG_FILE" 2>/dev/null || echo "true")"
    [ "$allow_sudo" = "true" ]
  else
    # Fallback: check for explicit "allow_sudo": false
    if grep -q '"allow_sudo" *: *false' "$CONFIG_FILE" 2>/dev/null; then
      return 1
    fi
    return 0
  fi
}

# Apply user strategy to adjust method priorities
# Args: method, base_priority, strategy
# Returns: adjusted priority
apply_strategy_to_priority() {
  local method="$1"
  local base_priority="$2"
  local strategy="$3"

  case "$strategy" in
    auto)
      # Use catalog priorities as-is
      echo "$base_priority"
      ;;
    github_first)
      case "$method" in
        github_release_binary) echo 1 ;;
        cargo) echo 2 ;;
        npm) echo 3 ;;
        apt) echo 4 ;;
        brew) echo 5 ;;
        *) echo "$base_priority" ;;
      esac
      ;;
    cargo_first)
      case "$method" in
        cargo) echo 1 ;;
        github_release_binary) echo 2 ;;
        npm) echo 3 ;;
        apt) echo 4 ;;
        brew) echo 5 ;;
        *) echo "$base_priority" ;;
      esac
      ;;
    npm_first)
      case "$method" in
        npm) echo 1 ;;
        github_release_binary) echo 2 ;;
        cargo) echo 3 ;;
        apt) echo 4 ;;
        brew) echo 5 ;;
        *) echo "$base_priority" ;;
      esac
      ;;
    apt_first)
      case "$method" in
        apt) echo 1 ;;
        brew) echo 2 ;;
        github_release_binary) echo 3 ;;
        cargo) echo 4 ;;
        npm) echo 5 ;;
        *) echo "$base_priority" ;;
      esac
      ;;
    *)
      echo "$base_priority"
      ;;
  esac
}

# Parse catalog available_methods and resolve best method
# Args: catalog_json_file
# Returns: method name or empty string if error
resolve_best_method() {
  local catalog_file="$1"
  local tool
  tool="$(basename "$catalog_file" .json)"

  if [ ! -f "$catalog_file" ]; then
    echo "Error: Catalog file not found: $catalog_file" >&2
    return 1
  fi

  # Check if tool uses reconciliation (install_method == "auto")
  local install_method
  if command -v jq >/dev/null 2>&1; then
    install_method="$(jq -r '.install_method // ""' "$catalog_file" 2>/dev/null || echo "")"
  else
    install_method="$(grep '"install_method"' "$catalog_file" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/' || echo "")"
  fi

  if [ "$install_method" != "auto" ]; then
    echo "Error: Tool $tool does not use reconciliation (install_method != 'auto')" >&2
    return 1
  fi

  # Get user preferences
  local user_strategy
  user_strategy="$(get_user_strategy)"
  local user_override
  user_override="$(get_user_override "$tool")"

  # If user has an override, use it (if available)
  if [ -n "$user_override" ]; then
    if is_method_available "$user_override"; then
      echo "$user_override"
      return 0
    else
      echo "Error: User override method '$user_override' not available for $tool" >&2
      return 1
    fi
  fi

  # Parse available_methods from catalog
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq not available, cannot parse catalog" >&2
    return 1
  fi

  # Get all available methods with priorities
  local best_method=""
  local best_priority=9999

  # Read available_methods array
  local methods_count
  methods_count="$(jq '.available_methods | length' "$catalog_file" 2>/dev/null || echo "0")"

  if [ "$methods_count" -eq 0 ]; then
    echo "Error: No available_methods defined in catalog for $tool" >&2
    return 1
  fi

  for ((i=0; i<methods_count; i++)); do
    local method
    method="$(jq -r ".available_methods[$i].method" "$catalog_file" 2>/dev/null || echo "")"
    [ -z "$method" ] && continue

    local catalog_priority
    catalog_priority="$(jq -r ".available_methods[$i].priority // 999" "$catalog_file" 2>/dev/null || echo "999")"

    # Check if method is available on system
    if ! is_method_available "$method"; then
      continue
    fi

    # Skip apt if sudo not allowed
    if [ "$method" = "apt" ] && ! is_sudo_allowed; then
      continue
    fi

    # Apply user strategy to adjust priority
    local adjusted_priority
    adjusted_priority="$(apply_strategy_to_priority "$method" "$catalog_priority" "$user_strategy")"

    # Track best (lowest priority number)
    if [ "$adjusted_priority" -lt "$best_priority" ]; then
      best_priority="$adjusted_priority"
      best_method="$method"
    fi
  done

  if [ -z "$best_method" ]; then
    echo "Error: No available installation method found for $tool" >&2
    return 1
  fi

  echo "$best_method"
  return 0
}

# Get configuration for a specific method from catalog
# Args: catalog_file, method
# Returns: JSON config object or empty
get_method_config() {
  local catalog_file="$1"
  local method="$2"

  if ! command -v jq >/dev/null 2>&1; then
    echo "{}"
    return 0
  fi

  # Find the method in available_methods array and return its config
  local config
  config="$(jq -r ".available_methods[] | select(.method == \"$method\") | .config // {}" "$catalog_file" 2>/dev/null || echo "{}")"
  echo "$config"
}

# Explain the decision made for a tool
# Args: catalog_file
# Returns: human-readable explanation
explain_method_decision() {
  local catalog_file="$1"
  local tool
  tool="$(basename "$catalog_file" .json)"

  local best_method
  best_method="$(resolve_best_method "$catalog_file" 2>/dev/null || echo "none")"

  echo "[$tool] Policy decision:"
  echo "[$tool]   User strategy: $(get_user_strategy)"
  local override
  override="$(get_user_override "$tool")"
  if [ -n "$override" ]; then
    echo "[$tool]   User override: $override"
  fi
  echo "[$tool]   Best available method: $best_method"
}
