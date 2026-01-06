#!/usr/bin/env bash
# path_check.sh - PATH validation and auto-fix for package managers and language environments

set -euo pipefail

PATH_CHECK_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect user's shell RC file
detect_shell_rc() {
  local shell_name="${SHELL##*/}"
  
  case "$shell_name" in
    bash)
      # Prefer .bashrc for interactive shells
      if [ -f "$HOME/.bashrc" ]; then
        echo "$HOME/.bashrc"
      elif [ -f "$HOME/.bash_profile" ]; then
        echo "$HOME/.bash_profile"
      else
        echo "$HOME/.bashrc"  # Create it
      fi
      ;;
    zsh)
      if [ -f "$HOME/.zshrc" ]; then
        echo "$HOME/.zshrc"
      else
        echo "$HOME/.zshrc"  # Create it
      fi
      ;;
    fish)
      echo "$HOME/.config/fish/config.fish"
      ;;
    *)
      # Fallback to .profile
      echo "$HOME/.profile"
      ;;
  esac
}

# Check if a PATH entry exists
path_contains() {
  local dir="$1"
  case ":$PATH:" in
    *":$dir:"*) return 0 ;;
    *) return 1 ;;
  esac
}

# Check if a PATH entry comes before another
path_order_ok() {
  local earlier="$1"
  local later="$2"
  
  # Get positions
  local pos_earlier=-1
  local pos_later=-1
  local pos=0
  
  IFS=':' read -ra PATHS <<< "$PATH"
  for p in "${PATHS[@]}"; do
    if [ "$p" = "$earlier" ]; then
      pos_earlier=$pos
    fi
    if [ "$p" = "$later" ]; then
      pos_later=$pos
    fi
    pos=$((pos + 1))
  done
  
  # If earlier not found, bad
  [ $pos_earlier -eq -1 ] && return 1
  
  # If later not found, order is OK (nothing to conflict with)
  [ $pos_later -eq -1 ] && return 0
  
  # Earlier should have lower position number
  [ $pos_earlier -lt $pos_later ]
}

# Package manager PATH requirements
# Format: name|path|init_command|description|priority(1=highest)
declare -A PATH_REQUIREMENTS=(
  # Python/UV
  ["uv"]="$HOME/.local/bin|export PATH=\"\$HOME/.local/bin:\$PATH\"|UV package manager binaries|1"

  # Ruby/rbenv
  ["rbenv"]="$HOME/.rbenv/bin|export PATH=\"\$HOME/.rbenv/bin:\$PATH\"\neval \"\$(rbenv init - bash)\"|rbenv Ruby version manager|2"
  ["rbenv-shims"]="$HOME/.rbenv/shims||rbenv shims (auto-managed)|1"

  # Node/nvm (requires sourcing, not just PATH)
  ["nvm"]="$HOME/.nvm|export NVM_DIR=\"\$HOME/.nvm\"\n[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"|nvm Node.js version manager|1"

  # Python/pyenv
  ["pyenv"]="$HOME/.pyenv/bin|export PYENV_ROOT=\"\$HOME/.pyenv\"\nexport PATH=\"\$PYENV_ROOT/bin:\$PATH\"\neval \"\$(pyenv init --path)\"\neval \"\$(pyenv init -)\"|pyenv Python version manager|2"
  ["pyenv-shims"]="$HOME/.pyenv/shims||pyenv shims (auto-managed)|1"

  # Rust/cargo
  ["cargo"]="$HOME/.cargo/bin|. \"\$HOME/.cargo/env\"|Rust cargo package manager|3"

  # Go
  ["go-bin"]="$HOME/go/bin|export PATH=\"\$HOME/go/bin:\$PATH\"|Go installed binaries|3"

  # General user binaries
  ["local-bin"]="$HOME/.local/bin|export PATH=\"\$HOME/.local/bin:\$PATH\"|User-installed binaries|2"
)

# Shell integration requirements (tools that need hooks/eval, not just PATH)
# Format: name|command_to_check|hook_command|description
declare -A SHELL_INTEGRATIONS=(
  # Environment managers
  ["direnv"]="direnv|eval \"\$(direnv hook bash)\"|direnv environment variable manager"

  # Version managers (check for the manager command itself)
  ["nvm"]="nvm|[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"|nvm Node.js version manager"
  ["pyenv"]="pyenv|eval \"\$(pyenv init -)\"|pyenv Python version manager"
  ["rbenv"]="rbenv|eval \"\$(rbenv init - bash)\"|rbenv Ruby version manager"
  ["asdf"]="asdf|. \"\$HOME/.asdf/asdf.sh\"|asdf universal version manager"

  # Shell enhancements
  ["starship"]="starship|eval \"\$(starship init bash)\"|starship cross-shell prompt"
  ["zoxide"]="zoxide|eval \"\$(zoxide init bash)\"|zoxide smarter cd"
  ["atuin"]="atuin|eval \"\$(atuin init bash)\"|atuin shell history sync"

  # Completions
  ["kubectl"]="kubectl|source <(kubectl completion bash)|Kubernetes CLI completion"
)

# Priority order rules: lower number = should come earlier in PATH
# This ensures language version managers take precedence over system packages

# Check if a tool is properly configured in RC file
is_configured_in_rc() {
  local init_cmd="$1"
  local rc_file
  rc_file=$(detect_shell_rc)

  # Extract first significant line from init command
  local first_line
  first_line=$(echo -e "$init_cmd" | head -1)

  # Check if it's in the RC file
  grep -qF "${first_line}" "$rc_file" 2>/dev/null
}

# Check if shell integration is properly configured
check_shell_integration() {
  local name="$1"
  local integration="${SHELL_INTEGRATIONS[$name]}"

  IFS='|' read -r command hook_cmd description <<< "$integration"

  local result=""
  local warning=""
  local fix=""

  # Check if tool is installed (special handling for nvm which is a function)
  if [ "$name" = "nvm" ]; then
    # Check if nvm directory exists instead of command
    if [ ! -d "$HOME/.nvm" ]; then
      result="not_installed"
      echo "$result|$warning|$fix"
      return 0
    fi
  elif ! command -v "$command" >/dev/null 2>&1; then
    result="not_installed"
    echo "$result|$warning|$fix"
    return 0
  fi

  # Check if hook is in RC file
  local rc_file
  rc_file=$(detect_shell_rc)

  # Extract key part of hook command for matching
  local hook_pattern
  case "$name" in
    direnv)
      hook_pattern="direnv hook"
      ;;
    nvm)
      hook_pattern="NVM_DIR/nvm.sh"
      ;;
    pyenv)
      hook_pattern="pyenv init"
      ;;
    rbenv)
      hook_pattern="rbenv init"
      ;;
    asdf)
      hook_pattern="asdf.sh"
      ;;
    starship)
      hook_pattern="starship init"
      ;;
    zoxide)
      hook_pattern="zoxide init"
      ;;
    atuin)
      hook_pattern="atuin init"
      ;;
    kubectl)
      hook_pattern="kubectl completion"
      ;;
    *)
      hook_pattern="$name"
      ;;
  esac

  if grep -q "$hook_pattern" "$rc_file" 2>/dev/null; then
    result="ok"
  else
    result="missing"
    warning="⚠️  $description needs shell integration (hook not configured)"
    fix="add_shell_hook|$name|$hook_cmd"
  fi

  echo "$result|$warning|$fix"
}

# Check all shell integrations
check_all_shell_integrations() {
  local issues=()

  for name in "${!SHELL_INTEGRATIONS[@]}"; do
    local check_result
    check_result=$(check_shell_integration "$name")

    IFS='|' read -r result warning fix <<< "$check_result"

    if [ "$result" = "missing" ]; then
      issues+=("$name|$warning|$fix")
    fi
  done

  # Print issues if found
  if [ ${#issues[@]} -gt 0 ]; then
    echo "# Shell Integration Issues Found:" >&2
    echo "#" >&2
    for issue in "${issues[@]}"; do
      IFS='|' read -r name warning fix <<< "$issue"
      echo "#   $warning" >&2
    done
    echo "#" >&2
    echo "# Run 'make fix-path' to automatically configure shell integrations" >&2
    return 1
  fi

  return 0
}

# Check a single PATH requirement
check_path_requirement() {
  local name="$1"
  local requirement="${PATH_REQUIREMENTS[$name]}"

  IFS='|' read -r dir init_cmd description priority <<< "$requirement"

  # Expand home directory
  dir="${dir/#\~/$HOME}"

  local result=""
  local warning=""
  local fix=""

  # Check if directory exists
  if [ ! -d "$dir" ]; then
    result="not_installed"
    return 0
  fi

  # Check if already configured in RC file (more reliable than checking current PATH)
  if is_configured_in_rc "$init_cmd"; then
    result="ok"
    echo "$result|$warning|$fix"
    return 0
  fi

  # Not in RC file - check if in current PATH (might be manually set)
  if ! path_contains "$dir"; then
    result="missing"
    warning="⚠️  $description not configured in shell RC file"
    fix="add_to_path|$name|$dir|$init_cmd"
  else
    result="ok"

    # Check priority ordering (e.g., ~/.local/bin should come before /usr/bin)
    if [ "$name" = "local-bin" ] || [ "$name" = "cargo" ] || [ "$name" = "rbenv-shims" ]; then
      if ! path_order_ok "$dir" "/usr/bin"; then
        result="wrong_order"
        warning="⚠️  $description should come before /usr/bin in PATH"
        fix="reorder_path|$name|$dir|$init_cmd"
      fi
    fi
  fi

  echo "$result|$warning|$fix"
}

# Check all PATH requirements
check_all_paths() {
  local path_issues=()
  local shell_issues=()

  # Check PATH requirements
  for name in "${!PATH_REQUIREMENTS[@]}"; do
    local check_result
    check_result=$(check_path_requirement "$name")

    IFS='|' read -r result warning fix <<< "$check_result"

    if [ "$result" = "missing" ] || [ "$result" = "wrong_order" ]; then
      path_issues+=("$name|$warning|$fix")
    fi
  done

  # Check shell integrations
  for name in "${!SHELL_INTEGRATIONS[@]}"; do
    local check_result
    check_result=$(check_shell_integration "$name")

    IFS='|' read -r result warning fix <<< "$check_result"

    if [ "$result" = "missing" ]; then
      shell_issues+=("$name|$warning|$fix")
    fi
  done

  # Print PATH issues
  if [ ${#path_issues[@]} -gt 0 ]; then
    echo "# PATH Configuration Issues Found:" >&2
    echo "#" >&2
    for issue in "${path_issues[@]}"; do
      IFS='|' read -r name warning fix <<< "$issue"
      echo "#   $warning" >&2
    done
    echo "#" >&2
  fi

  # Print shell integration issues
  if [ ${#shell_issues[@]} -gt 0 ]; then
    echo "# Shell Integration Issues Found:" >&2
    echo "#" >&2
    for issue in "${shell_issues[@]}"; do
      IFS='|' read -r name warning fix <<< "$issue"
      echo "#   $warning" >&2
    done
    echo "#" >&2
  fi

  # Summary
  if [ ${#path_issues[@]} -gt 0 ] || [ ${#shell_issues[@]} -gt 0 ]; then
    echo "# Run 'make fix-path' to automatically fix these issues" >&2
    return 1
  fi

  return 0
}

# Add init commands to shell RC file
add_to_shell_rc() {
  local name="$1"
  local init_cmd="$2"
  local rc_file
  rc_file=$(detect_shell_rc)

  # Check if already present
  local first_line
  first_line=$(echo -e "$init_cmd" | head -1)

  if grep -qF "${first_line}" "$rc_file" 2>/dev/null; then
    echo "# [$name] Already configured in $rc_file" >&2
    return 0
  fi

  echo "# [$name] Adding to $rc_file..." >&2

  # Add with clear section marker
  {
    echo ""
    echo "# $name initialization (added by ai_cli_preparation)"
    echo -e "$init_cmd"
  } >> "$rc_file"

  echo "# [$name] ✓ Added to $rc_file" >&2
}

# Add shell hook to RC file
add_shell_hook() {
  local name="$1"
  local hook_cmd="$2"
  local rc_file
  rc_file=$(detect_shell_rc)

  # Check if _eval_if helper exists
  if ! grep -q "^_eval_if()" "$rc_file" 2>/dev/null; then
    echo "# [shell-helper] Adding _eval_if helper function..." >&2
    {
      echo ""
      echo "# Shell integration helper (added by ai_cli_preparation)"
      echo "_eval_if() { command -v \"\$1\" >/dev/null 2>&1 && eval \"\$2\"; }"
    } >> "$rc_file"
  fi

  # Extract command name from hook_cmd for pattern matching
  local hook_pattern
  case "$name" in
    direnv) hook_pattern="direnv hook" ;;
    nvm) hook_pattern="NVM_DIR/nvm.sh" ;;
    pyenv) hook_pattern="pyenv init" ;;
    rbenv) hook_pattern="rbenv init" ;;
    asdf) hook_pattern="asdf.sh" ;;
    starship) hook_pattern="starship init" ;;
    zoxide) hook_pattern="zoxide init" ;;
    atuin) hook_pattern="atuin init" ;;
    kubectl) hook_pattern="kubectl completion" ;;
    *) hook_pattern="$name" ;;
  esac

  # Check if already present
  if grep -q "$hook_pattern" "$rc_file" 2>/dev/null; then
    echo "# [$name] Shell integration already configured in $rc_file" >&2
    return 0
  fi

  echo "# [$name] Adding shell integration to $rc_file..." >&2

  # Add with clear section marker
  {
    echo ""
    echo "# $name shell integration (added by ai_cli_preparation)"
    echo -e "$hook_cmd"
  } >> "$rc_file"

  echo "# [$name] ✓ Shell integration added to $rc_file" >&2
}

# Fix all PATH issues
fix_all_paths() {
  local rc_file
  rc_file=$(detect_shell_rc)
  local path_fixed=0
  local shell_fixed=0

  echo "# Fixing PATH and shell integration issues..." >&2
  echo "# Target RC file: $rc_file" >&2
  echo "#" >&2

  # Fix PATH requirements
  for name in "${!PATH_REQUIREMENTS[@]}"; do
    local check_result
    check_result=$(check_path_requirement "$name")

    IFS='|' read -r result warning fix <<< "$check_result"

    if [ "$result" = "missing" ] || [ "$result" = "wrong_order" ]; then
      IFS='|' read -r fix_type fix_name fix_dir fix_init_cmd <<< "$fix"

      if [ -n "$fix_init_cmd" ]; then
        add_to_shell_rc "$fix_name" "$fix_init_cmd"
        path_fixed=$((path_fixed + 1))
      fi
    fi
  done

  # Fix shell integrations
  for name in "${!SHELL_INTEGRATIONS[@]}"; do
    local check_result
    check_result=$(check_shell_integration "$name")

    IFS='|' read -r result warning fix <<< "$check_result"

    if [ "$result" = "missing" ]; then
      IFS='|' read -r fix_type fix_name fix_hook_cmd <<< "$fix"

      if [ -n "$fix_hook_cmd" ]; then
        add_shell_hook "$fix_name" "$fix_hook_cmd"
        shell_fixed=$((shell_fixed + 1))
      fi
    fi
  done

  # Summary
  if [ $path_fixed -gt 0 ] || [ $shell_fixed -gt 0 ]; then
    echo "#" >&2
    [ $path_fixed -gt 0 ] && echo "# ✓ Fixed $path_fixed PATH issues" >&2
    [ $shell_fixed -gt 0 ] && echo "# ✓ Fixed $shell_fixed shell integration issues" >&2
    echo "#" >&2
    echo "# To apply changes, run:" >&2
    echo "#   source $rc_file" >&2
    echo "# Or start a new shell session" >&2
  else
    echo "# No PATH or shell integration issues found" >&2
  fi
}

# Export functions for use in other scripts
export -f detect_shell_rc
export -f path_contains
export -f path_order_ok
export -f check_path_requirement
export -f check_shell_integration
export -f check_all_shell_integrations
export -f check_all_paths
export -f add_to_shell_rc
export -f add_shell_hook
export -f fix_all_paths
