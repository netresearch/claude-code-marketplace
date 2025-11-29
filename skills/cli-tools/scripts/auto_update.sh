#!/usr/bin/env bash
set -euo pipefail

# Auto-update all package managers and their packages
# Detects installed package managers and runs their native update tools

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/lib/common.sh"
. "$DIR/lib/scope_detection.sh"

DRY_RUN="${DRY_RUN:-0}"
VERBOSE="${VERBOSE:-0}"
SKIP_SYSTEM="${SKIP_SYSTEM:-0}"
SCOPE="${SCOPE:-}"  # Can be: system, user, project, all, or auto-detect if empty

log() {
  printf "[auto-update] %s\n" "$*" >&2
}

vlog() {
  if [ "$VERBOSE" = "1" ]; then
    printf "[auto-update] %s\n" "$*" >&2
  fi
}

run_cmd() {
  local desc="$1"
  shift
  if [ "$DRY_RUN" = "1" ]; then
    log "DRY-RUN: $desc"
    log "  Command: $*"
  else
    log "$desc"
    if [ "$VERBOSE" = "1" ]; then
      "$@"
    else
      "$@" >/dev/null 2>&1 || true
    fi
  fi
}

# ============================================================================
# Package Manager Detection
# ============================================================================

detect_apt() {
  command -v apt-get >/dev/null 2>&1
}

detect_brew() {
  command -v brew >/dev/null 2>&1
}

detect_cargo() {
  command -v cargo >/dev/null 2>&1
}

detect_pip() {
  command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1
}

detect_pipx() {
  command -v pipx >/dev/null 2>&1
}

detect_uv() {
  command -v uv >/dev/null 2>&1
}

detect_npm() {
  command -v npm >/dev/null 2>&1
}

detect_pnpm() {
  command -v pnpm >/dev/null 2>&1
}

detect_yarn() {
  command -v yarn >/dev/null 2>&1
}

detect_go() {
  command -v go >/dev/null 2>&1
}

detect_gem() {
  command -v gem >/dev/null 2>&1
}

detect_snap() {
  command -v snap >/dev/null 2>&1
}

detect_flatpak() {
  command -v flatpak >/dev/null 2>&1
}

detect_rustup() {
  command -v rustup >/dev/null 2>&1
}

detect_nvm() {
  [ -s "$HOME/.nvm/nvm.sh" ] && return 0
  command -v nvm >/dev/null 2>&1
}

detect_gcloud() {
  command -v gcloud >/dev/null 2>&1
}

detect_az() {
  command -v az >/dev/null 2>&1
}

detect_composer() {
  command -v composer >/dev/null 2>&1
}

detect_poetry() {
  command -v poetry >/dev/null 2>&1
}

detect_conda() {
  command -v conda >/dev/null 2>&1
}

detect_mamba() {
  command -v mamba >/dev/null 2>&1
}

detect_bundler() {
  command -v bundle >/dev/null 2>&1
}

detect_jspm() {
  command -v jspm >/dev/null 2>&1
}

detect_nuget() {
  command -v nuget >/dev/null 2>&1 || command -v dotnet >/dev/null 2>&1
}

# ============================================================================
# System Package Managers (requires sudo)
# ============================================================================

update_apt() {
  if ! detect_apt; then return; fi
  log "APT: Updating package lists and upgrading packages"

  if [ "$DRY_RUN" = "1" ]; then
    log "DRY-RUN: sudo apt-get update && sudo apt-get upgrade -y"
  else
    if [ "$VERBOSE" = "1" ]; then
      sudo apt-get update && sudo apt-get upgrade -y
    else
      sudo apt-get update >/dev/null 2>&1 || true
      sudo apt-get upgrade -y >/dev/null 2>&1 || true
    fi
    log "APT: Complete"
  fi
}

update_brew() {
  if ! detect_brew; then return; fi
  log "Homebrew: Updating and upgrading all packages"

  run_cmd "Brew: Update package index" brew update
  run_cmd "Brew: Upgrade packages" brew upgrade
  run_cmd "Brew: Cleanup old versions" brew cleanup

  log "Homebrew: Complete"
}

update_snap() {
  if ! detect_snap; then return; fi
  log "Snap: Refreshing all snaps"

  run_cmd "Snap: Refresh all" sudo snap refresh

  log "Snap: Complete"
}

update_flatpak() {
  if ! detect_flatpak; then return; fi
  log "Flatpak: Updating all applications"

  run_cmd "Flatpak: Update" flatpak update -y

  log "Flatpak: Complete"
}

# ============================================================================
# Language-Specific Package Managers
# ============================================================================

update_cargo() {
  if ! detect_cargo; then return; fi
  log "Cargo: Updating installed packages"

  # Update rustup first
  if detect_rustup; then
    run_cmd "Rustup: Update toolchains" rustup update

    # Update rustup components (clippy, rustfmt, rust-analyzer, etc.)
    vlog "Rustup: Updating components"
    for component in clippy rustfmt rust-analyzer rust-src; do
      if rustup component list 2>/dev/null | grep -q "^${component}.*installed"; then
        vlog "Rustup: Component $component is installed"
        # Components are updated with rustup update, no separate update needed
      fi
    done
  fi

  # Install cargo-update if not present
  if ! command -v cargo-install-update >/dev/null 2>&1; then
    vlog "Installing cargo-update for package upgrades"
    run_cmd "Cargo: Install cargo-update" cargo install cargo-update
  fi

  # Update all cargo-installed packages
  if command -v cargo-install-update >/dev/null 2>&1; then
    run_cmd "Cargo: Upgrade all packages" cargo install-update -a
  fi

  log "Cargo: Complete"
}

update_uv() {
  if ! detect_uv; then return; fi
  log "UV: Updating UV tools"

  # Update uv itself
  run_cmd "UV: Self-update" uv self update

  # Update all uv-managed tools
  if [ "$DRY_RUN" = "0" ]; then
    local tools
    # Filter out binary lines (starting with dash) and keep only tool names
    tools="$(uv tool list 2>/dev/null | grep -v '^-' | awk 'NF > 0 {print $1}' || true)"
    if [ -n "$tools" ]; then
      log "UV: Upgrading $(echo "$tools" | wc -l) installed tools"
      while IFS= read -r tool; do
        [ -z "$tool" ] && continue
        run_cmd "UV: Upgrade $tool" uv tool upgrade "$tool"
      done <<< "$tools"
    fi
  else
    log "DRY-RUN: uv self update"
    log "DRY-RUN: uv tool upgrade <all-tools>"
  fi

  log "UV: Complete"
}

update_pipx() {
  if ! detect_pipx; then return; fi
  log "Pipx: Updating all packages"

  run_cmd "Pipx: Upgrade pipx" pip3 install --user --upgrade pipx
  run_cmd "Pipx: Upgrade all packages" pipx upgrade-all

  # Explicitly list important dev tools we track via pipx
  local important_tools=("semgrep" "pre-commit" "coverage" "tox" "checkov" "black" "flake8" "pylint" "mypy")
  for tool in "${important_tools[@]}"; do
    if pipx list 2>/dev/null | grep -q "package $tool"; then
      vlog "Pipx: $tool is installed"
    fi
  done

  log "Pipx: Complete"
}

update_pip() {
  if ! detect_pip; then return; fi
  log "Pip: Updating user-installed packages"

  # Update pip itself
  run_cmd "Pip: Self-update" python3 -m pip install --user --upgrade pip

  # List and upgrade user packages
  if [ "$DRY_RUN" = "0" ]; then
    local outdated
    outdated="$(python3 -m pip list --user --outdated --format=json 2>/dev/null || echo '[]')"
    if [ "$outdated" != "[]" ] && [ -n "$outdated" ]; then
      vlog "Found outdated pip packages"
      # Extract package names and upgrade them
      echo "$outdated" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for pkg in data:
        print(pkg['name'])
except:
    pass
" | while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        run_cmd "Pip: Upgrade $pkg" python3 -m pip install --user --upgrade "$pkg"
      done
    fi
  else
    log "DRY-RUN: pip list --outdated and upgrade packages"
  fi

  log "Pip: Complete"
}

update_npm() {
  if ! detect_npm; then return; fi
  log "NPM: Updating global packages"

  # Update npm itself
  run_cmd "NPM: Self-update" npm install -g npm@latest

  # Update all global packages
  run_cmd "NPM: Upgrade global packages" npm update -g

  log "NPM: Complete"
}

update_pnpm() {
  if ! detect_pnpm; then return; fi
  log "PNPM: Updating global packages"

  # Update pnpm itself via corepack if available
  if command -v corepack >/dev/null 2>&1; then
    run_cmd "PNPM: Update via corepack" corepack prepare pnpm@latest --activate
  else
    run_cmd "PNPM: Self-update" npm install -g pnpm@latest
  fi

  # Update global packages
  run_cmd "PNPM: Upgrade global packages" pnpm update -g

  log "PNPM: Complete"
}

update_yarn() {
  if ! detect_yarn; then return; fi
  log "Yarn: Updating global packages"

  # Update yarn itself via corepack if available
  if command -v corepack >/dev/null 2>&1; then
    run_cmd "Yarn: Update via corepack" corepack prepare yarn@stable --activate
  else
    run_cmd "Yarn: Self-update" npm install -g yarn@latest
  fi

  # Yarn doesn't have a built-in global package upgrade command
  # Users typically manage this per-project
  vlog "Yarn: Global package upgrades managed per-project"

  log "Yarn: Complete"
}

update_go() {
  if ! detect_go; then return; fi
  log "Go: Updating installed binaries"

  # Go doesn't have a built-in package manager for updating binaries
  # List common go-installed tools and suggest updating
  local gobin gopath
  gobin="$(go env GOBIN 2>/dev/null || true)"
  gopath="$(go env GOPATH 2>/dev/null || true)"

  if [ -z "$gobin" ] && [ -n "$gopath" ]; then
    gobin="$gopath/bin"
  fi

  if [ -n "$gobin" ] && [ -d "$gobin" ]; then
    vlog "Go: Binaries in $gobin (manual upgrade needed: go install <package>@latest)"
    log "Go: Update via go install <package>@latest for each tool"
  fi

  log "Go: Manual updates required"
}

update_gem() {
  if ! detect_gem; then return; fi
  log "RubyGems: Updating all gems"

  run_cmd "Gem: Update system" gem update --system
  run_cmd "Gem: Upgrade all gems" gem update
  run_cmd "Gem: Cleanup old versions" gem cleanup

  log "RubyGems: Complete"
}

update_composer() {
  if ! detect_composer; then return; fi
  log "Composer: Updating"

  run_cmd "Composer: Self-update" composer self-update
  run_cmd "Composer: Update global packages" composer global update

  log "Composer: Complete"
}

update_poetry() {
  if ! detect_poetry; then return; fi
  log "Poetry: Updating"

  # Try poetry self update first (Poetry 1.2+)
  if poetry self update --help >/dev/null 2>&1; then
    run_cmd "Poetry: Self-update" poetry self update
  # Fallback to uv tool upgrade if poetry is managed by uv
  elif command -v uv >/dev/null 2>&1 && uv tool list 2>/dev/null | grep -q "^poetry"; then
    run_cmd "Poetry: Upgrade via UV" uv tool upgrade poetry
  # Fallback to pipx upgrade if poetry is managed by pipx
  elif command -v pipx >/dev/null 2>&1 && pipx list 2>/dev/null | grep -q "poetry"; then
    run_cmd "Poetry: Upgrade via pipx" pipx upgrade poetry
  else
    vlog "Poetry: No automatic update method available"
    log "Poetry: Manual update required (see https://python-poetry.org/docs/#updating-poetry)"
  fi

  log "Poetry: Complete"
}

update_gcloud() {
  if ! detect_gcloud; then return; fi
  log "Google Cloud SDK: Updating components"

  run_cmd "gcloud: Update all components" gcloud components update --quiet

  log "Google Cloud SDK: Complete"
}

update_az() {
  if ! detect_az; then return; fi
  log "Azure CLI: Updating"

  # Azure CLI update method depends on installation type
  if command -v apt-get >/dev/null 2>&1 && dpkg -l azure-cli >/dev/null 2>&1; then
    # Installed via apt
    run_cmd "Azure CLI: Update via apt" sudo apt-get update && sudo apt-get install --only-upgrade -y azure-cli
  elif command -v brew >/dev/null 2>&1 && brew list azure-cli >/dev/null 2>&1; then
    # Installed via brew
    run_cmd "Azure CLI: Update via brew" brew upgrade azure-cli
  else
    # Try az upgrade command (available in az CLI 2.11.0+)
    run_cmd "Azure CLI: Self-upgrade" az upgrade --yes
  fi

  log "Azure CLI: Complete"
}

# ============================================================================
# Main Orchestration
# ============================================================================

get_manager_stats() {
  local mgr="$1"
  local location version pkg_count

  case "$mgr" in
    apt)
      location="$(command -v apt-get 2>/dev/null || echo "N/A")"
      version="$(apt-get --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "unknown")"
      pkg_count="$(dpkg -l 2>/dev/null | grep '^ii' | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    brew)
      location="$(command -v brew 2>/dev/null || echo "N/A")"
      version="$(brew --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "unknown")"
      pkg_count="$(brew list --formula 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    snap)
      location="$(command -v snap 2>/dev/null || echo "N/A")"
      version="$(snap version 2>/dev/null | grep '^snap' | awk '{print $2}' || echo "unknown")"
      pkg_count="$(snap list 2>/dev/null | tail -n +2 | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    flatpak)
      location="$(command -v flatpak 2>/dev/null || echo "N/A")"
      version="$(flatpak --version 2>/dev/null | awk '{print $2}' || echo "unknown")"
      pkg_count="$(flatpak list --app 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    cargo)
      location="$(command -v cargo 2>/dev/null || echo "N/A")"
      version="$(cargo --version 2>/dev/null | awk '{print $2}' || echo "unknown")"
      pkg_count="$(cargo install --list 2>/dev/null | grep -c '^[^ ]' | tr -d '[:space:]' || echo "0")"
      ;;
    rustup)
      location="$(command -v rustup 2>/dev/null || echo "N/A")"
      version="$(rustup --version 2>/dev/null | awk '{print $2}' || echo "unknown")"
      pkg_count="$(rustup toolchain list 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    uv)
      location="$(command -v uv 2>/dev/null || echo "N/A")"
      version="$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")"
      pkg_count="$(uv tool list 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    pipx)
      location="$(command -v pipx 2>/dev/null || echo "N/A")"
      version="$(pipx --version 2>/dev/null || echo "unknown")"
      pkg_count="$(pipx list --short 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    pip)
      location="$(command -v pip3 2>/dev/null || command -v pip 2>/dev/null || echo "N/A")"
      version="$(/usr/bin/python3 -m pip --version 2>/dev/null | awk '{print $2}' || echo "unknown")"
      pkg_count="$(/usr/bin/python3 -m pip list --user 2>/dev/null | tail -n +3 | wc -l | tr -d '[:space:]' || echo "0")"
      pkg_count="${pkg_count:-0}"
      ;;
    npm)
      location="$(command -v npm 2>/dev/null || echo "N/A")"
      version="$(npm --version 2>/dev/null || echo "unknown")"
      pkg_count="$(npm list -g --depth=0 2>/dev/null | grep -c '^[├└]' | tr -d '[:space:]' || echo "0")"
      ;;
    pnpm)
      location="$(command -v pnpm 2>/dev/null || echo "N/A")"
      version="$(pnpm --version 2>/dev/null || echo "unknown")"
      pkg_count="$(pnpm list -g --depth=0 2>/dev/null | grep -c '^[├└]' | tr -d '[:space:]' || echo "0")"
      ;;
    yarn)
      location="$(command -v yarn 2>/dev/null || echo "N/A")"
      version="$(yarn --version 2>/dev/null || echo "unknown")"
      pkg_count="$(yarn global list 2>/dev/null | grep -c '^info' | tr -d '[:space:]' || echo "0")"
      ;;
    go)
      location="$(command -v go 2>/dev/null || echo "N/A")"
      version="$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || echo "unknown")"
      local gobin="$(go env GOBIN 2>/dev/null || echo "$(go env GOPATH 2>/dev/null)/bin")"
      pkg_count="$([ -d "$gobin" ] && ls -1 "$gobin" 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    gem)
      location="$(command -v gem 2>/dev/null || echo "N/A")"
      version="$(gem --version 2>/dev/null || echo "unknown")"
      pkg_count="$(gem list --no-versions 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    composer)
      location="$(command -v composer 2>/dev/null || echo "N/A")"
      version="$(composer --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")"
      pkg_count="$(composer global show 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    poetry)
      location="$(command -v poetry 2>/dev/null || echo "N/A")"
      version="$(poetry --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")"
      pkg_count="N/A"
      ;;
    conda)
      location="$(command -v conda 2>/dev/null || echo "N/A")"
      version="$(conda --version 2>/dev/null | awk '{print $2}' || echo "unknown")"
      pkg_count="$(conda list 2>/dev/null | tail -n +4 | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    mamba)
      location="$(command -v mamba 2>/dev/null || echo "N/A")"
      version="$(mamba --version 2>/dev/null | awk '{print $2}' || echo "unknown")"
      pkg_count="$(mamba list 2>/dev/null | tail -n +4 | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    bundler)
      location="$(command -v bundle 2>/dev/null || echo "N/A")"
      version="$(bundle --version 2>/dev/null | awk '{print $3}' || echo "unknown")"
      pkg_count="N/A"
      ;;
    jspm)
      location="$(command -v jspm 2>/dev/null || echo "N/A")"
      version="$(jspm --version 2>/dev/null || echo "unknown")"
      pkg_count="N/A"
      ;;
    nuget)
      if command -v nuget >/dev/null 2>&1; then
        location="$(command -v nuget)"
        version="$(nuget help 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")"
      else
        location="$(command -v dotnet 2>/dev/null || echo "N/A")"
        version="$(dotnet --version 2>/dev/null || echo "unknown")"
      fi
      pkg_count="N/A"
      ;;
    gcloud)
      location="$(command -v gcloud 2>/dev/null || echo "N/A")"
      version="$(gcloud version 2>/dev/null | grep 'Google Cloud SDK' | awk '{print $4}' || echo "unknown")"
      pkg_count="$(gcloud components list --filter='State.name:Installed' --format='value(id)' 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")"
      ;;
    az)
      location="$(command -v az 2>/dev/null || echo "N/A")"
      version="$(az version --output tsv 2>/dev/null | grep '^azure-cli' | awk '{print $2}' || echo "unknown")"
      pkg_count="$(az extension list 2>/dev/null | grep -c '"name":' | tr -d '[:space:]' || echo "0")"
      ;;
    *)
      location="unknown"
      version="unknown"
      pkg_count="0"
      ;;
  esac

  printf "%s|%s|%s" "$location" "$version" "$pkg_count"
}

# Check if a package manager is outdated by querying the snapshot
check_manager_outdated() {
  local mgr="$1"
  local current_version="$2"

  # Skip if version is unknown
  [ "$current_version" = "unknown" ] && return 1

  # Use tools_snapshot.json directly (fast, no subprocess needed)
  local snapshot_file="${CLI_AUDIT_SNAPSHOT_FILE:-tools_snapshot.json}"

  # Check if snapshot exists
  [ ! -f "$snapshot_file" ] && return 1

  # Extract status for this tool from JSON snapshot
  local status
  status="$(python3 -c "
import json, sys
try:
    with open('$snapshot_file') as f:
        data = json.load(f)
        for tool in data.get('tools', []):
            if tool.get('tool') == '$mgr':
                print(tool.get('status', ''))
                sys.exit(0)
except:
    pass
" 2>/dev/null)" || status=""

  # Check if status is OUTDATED
  if [ "$status" = "OUTDATED" ]; then
    return 0  # Outdated
  else
    return 1  # Up-to-date or unknown
  fi
}

# Show update hint for a specific manager
show_manager_update_hint() {
  local mgr="$1"

  case "$mgr" in
    apt)
      echo "  • $mgr: Run 'sudo apt-get update && sudo apt-get upgrade -y' or 'make auto-update-system'"
      ;;
    snap)
      echo "  • $mgr: Run 'sudo snap refresh' or 'make auto-update-system'"
      ;;
    brew)
      echo "  • $mgr: Run 'brew update && brew upgrade' or 'make auto-update'"
      ;;
    flatpak)
      echo "  • $mgr: Run 'flatpak update -y' or 'make auto-update'"
      ;;
    cargo)
      echo "  • $mgr: Run 'cargo install cargo-update && cargo install-update -a' or 'make auto-update'"
      ;;
    rustup)
      echo "  • $mgr: Run 'rustup update' or 'make auto-update'"
      ;;
    uv)
      echo "  • $mgr: Run 'uv self update' or './scripts/auto_update.sh uv'"
      ;;
    pipx)
      echo "  • $mgr: Run 'pip3 install --user --upgrade pipx' or './scripts/auto_update.sh pipx'"
      ;;
    pip)
      echo "  • $mgr: Run 'python3 -m pip install --user --upgrade pip' or './scripts/auto_update.sh pip'"
      ;;
    npm)
      echo "  • $mgr: Run 'npm install -g npm@latest' or './scripts/auto_update.sh npm'"
      ;;
    pnpm)
      echo "  • $mgr: Run 'npm install -g pnpm@latest' or './scripts/auto_update.sh pnpm'"
      ;;
    yarn)
      echo "  • $mgr: Run 'npm install -g yarn@latest' or './scripts/auto_update.sh yarn'"
      ;;
    go)
      echo "  • $mgr: Download latest from https://go.dev/dl/ and install"
      ;;
    gem)
      echo "  • $mgr: Run 'gem update --system' or './scripts/auto_update.sh gem'"
      ;;
    composer)
      echo "  • $mgr: Run 'composer self-update'"
      ;;
    poetry)
      echo "  • $mgr: Run 'poetry self update' or 'uv tool upgrade poetry'"
      ;;
    conda)
      echo "  • $mgr: Run 'conda update -n base conda'"
      ;;
    mamba)
      echo "  • $mgr: Run 'conda update -n base mamba' or 'mamba update mamba'"
      ;;
    gcloud)
      echo "  • $mgr: Run 'gcloud components update' or './scripts/auto_update.sh gcloud'"
      ;;
    az)
      echo "  • $mgr: Run 'az upgrade' or './scripts/auto_update.sh az'"
      ;;
    *)
      echo "  • $mgr: Check official documentation for update instructions"
      ;;
  esac
}

show_detected() {
  log "Detecting installed package managers with scope information..."
  echo ""

  local all_managers=(apt snap brew flatpak cargo rustup uv pipx pip npm pnpm yarn go gem composer poetry conda mamba bundler jspm nuget gcloud az)
  local found_managers=0
  local found_scopes=0
  local outdated_managers=()

  # First pass: detect which managers are installed
  local managers=()
  for mgr in "${all_managers[@]}"; do
    if command -v "$mgr" >/dev/null 2>&1 || \
       ([ "$mgr" = "apt" ] && command -v apt-get >/dev/null 2>&1) || \
       ([ "$mgr" = "bundler" ] && command -v bundle >/dev/null 2>&1) || \
       ([ "$mgr" = "nuget" ] && command -v dotnet >/dev/null 2>&1); then
      managers+=("$mgr")
      found_managers=$((found_managers + 1))
    fi
  done

  if [ $found_managers -eq 0 ]; then
    echo "No package managers detected."
    return
  fi

  echo "Found $found_managers package managers:"
  echo ""
  printf "%-12s %-8s %-8s %-8s %s\n" "MANAGER" "VERSION" "SCOPE" "PACKAGES" "LOCATION"
  printf "%-12s %-8s %-8s %-8s %s\n" "-------" "-------" "-----" "--------" "--------"

  # Second pass: display one line per scope and check for updates
  for mgr in "${managers[@]}"; do
    # Get scopes for this manager
    local scopes
    scopes="$(get_manager_scopes "$mgr")"

    # Skip if no scopes detected
    [ -z "$scopes" ] && continue

    # Get version and location once (reuse for all scopes)
    local version location stats
    stats="$(get_manager_stats "$mgr")"
    IFS='|' read -r location version _ <<< "$stats"

    # Check if manager itself is outdated (only once per manager)
    # Wrap in subshell to prevent pipefail from exiting on check failure
    if ( check_manager_outdated "$mgr" "$version" ); then
      outdated_managers+=("$mgr")
    fi

    # Split scopes and print one line per scope
    IFS=',' read -ra SCOPE_ARRAY <<< "$scopes"
    for scope in "${SCOPE_ARRAY[@]}"; do
      local pkg_count
      pkg_count="$(get_manager_packages_by_scope "$mgr" "$scope")"

      printf "%-12s %-8s %-8s %-8s %s\n" "$mgr" "$version" "$scope" "$pkg_count" "$location"
      found_scopes=$((found_scopes + 1))
    done
  done

  echo ""
  log "$found_scopes total scopes across $found_managers managers"
  echo ""

  # Show outdated package managers if any
  if [ ${#outdated_managers[@]} -gt 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  Outdated Package Managers Detected"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The following package managers have updates available:"
    echo ""
    for mgr in "${outdated_managers[@]}"; do
      show_manager_update_hint "$mgr"
    done
    echo ""
    echo "Run 'make auto-update' or './scripts/auto_update.sh update' to update all."
    echo ""
  fi
}

confirm_project_update() {
  local mgr="$1"
  local project_file="$2"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 PROJECT SCOPE UPDATE: $mgr"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Project: $(pwd)"
  echo "File:    $project_file"
  echo ""
  echo "This will update project dependencies"
  echo ""
  echo "⚠️  WARNING: This may break your project if dependencies are"
  echo "            version-pinned or have breaking changes"
  echo ""

  read -p "Continue with project update? [y/N] " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    return 0
  else
    log "$mgr: Project update cancelled"
    return 1
  fi
}

run_all_updates() {
  # Determine target scope
  local target_scope="${SCOPE:-$(determine_default_scope)}"

  log "Starting auto-update for scope: $target_scope"
  echo ""

  # System scope updates
  if [ "$target_scope" = "system" ] || [ "$target_scope" = "all" ]; then
    if [ "$SKIP_SYSTEM" = "0" ]; then
      update_apt
      update_snap
      # Check if system-scoped
      [ "$(get_brew_scopes)" = "system" ] && update_brew
      [[ "$(get_flatpak_scopes)" == *"system"* ]] && update_flatpak
      [[ "$(get_gem_scopes)" == *"system"* ]] && update_gem
    else
      log "Skipping system package managers (SKIP_SYSTEM=1)"
    fi
  fi

  # User scope updates
  if [ "$target_scope" = "user" ] || [ "$target_scope" = "all" ]; then
    # User-only managers
    update_cargo
    update_uv
    update_pipx
    update_pip
    update_npm
    update_pnpm
    update_yarn
    update_go
    update_composer
    update_poetry
    update_gcloud

    # Check if user-scoped (conditional updates based on scope detection)
    [ "$(get_brew_scopes)" = "user" ] && update_brew
    [[ "$(get_flatpak_scopes)" == *"user"* ]] && update_flatpak
    [[ "$(get_gem_scopes)" == *"user"* ]] && update_gem
    [ "$(get_az_scopes)" = "user" ] && update_az
  fi

  # Project scope updates (require confirmation)
  if [ "$target_scope" = "project" ]; then
    log "Project scope update - checking for project dependencies..."

    # NPM/PNPM/Yarn
    if [ -f "./package.json" ]; then
      if command -v npm >/dev/null 2>&1 && confirm_project_update "npm" "./package.json"; then
        run_cmd "NPM: Update project dependencies" npm update
      fi
    fi

    # Pip/UV
    if [ -f "./pyproject.toml" ] || [ -d "./.venv" ]; then
      if command -v pip3 >/dev/null 2>&1 && [ -n "${VIRTUAL_ENV:-}" ] && confirm_project_update "pip" "./.venv"; then
        run_cmd "Pip: Update project dependencies" python3 -m pip install --upgrade -r requirements.txt 2>/dev/null || true
      fi
    fi

    # Bundler/Gem
    if [ -f "./Gemfile" ] && command -v bundle >/dev/null 2>&1 && confirm_project_update "bundler" "./Gemfile"; then
      run_cmd "Bundler: Update project dependencies" bundle update
    fi

    # Composer
    if [ -f "./composer.json" ] && command -v composer >/dev/null 2>&1 && confirm_project_update "composer" "./composer.json"; then
      run_cmd "Composer: Update project dependencies" composer update
    fi
  fi

  echo ""
  log "Auto-update complete for scope: $target_scope"
}

# ============================================================================
# CLI Interface
# ============================================================================

usage() {
  cat <<EOF
Usage: $0 [OPTIONS] [COMMAND]

Auto-update all package managers and their packages with scope-aware filtering.

Commands:
  detect    Show detected package managers with scope information (default)
  update    Run updates for detected package managers (scope-aware)
  apt       Update only APT packages
  brew      Update only Homebrew packages
  cargo     Update only Cargo packages (includes rustup components)
  uv        Update only UV tools
  pipx      Update only Pipx packages
  pip       Update only Pip packages
  npm       Update only NPM packages
  pnpm      Update only PNPM packages
  yarn      Update only Yarn packages
  go        Show Go update instructions
  gem       Update only RubyGems packages
  snap      Update only Snap packages
  flatpak   Update only Flatpak packages
  gcloud    Update Google Cloud SDK components
  az        Update Azure CLI

Options:
  --dry-run         Show what would be updated without making changes
  --verbose         Show detailed output
  --skip-system     Skip system package managers (apt, brew, snap, flatpak)
  -h, --help        Show this help message

Environment Variables:
  DRY_RUN=1         Enable dry-run mode
  VERBOSE=1         Enable verbose output
  SKIP_SYSTEM=1     Skip system package managers
  SCOPE=<scope>     Set update scope: system, user, project, all
                    (Default: auto-detect based on current directory)

Scope Behavior:
  - In project directory (has package.json, Gemfile, etc.): defaults to 'project'
  - Outside project directory: defaults to 'user'
  - 'system' scope: Updates system-wide packages (requires sudo)
  - 'all' scope: Updates system + user (skips project for safety)
  - Project updates always require explicit confirmation

Examples:
  $0 detect                     # List detected managers with scopes
  $0 update                     # Update based on directory context
  SCOPE=user $0 update          # Update only user-scoped packages
  SCOPE=system $0 update        # Update only system-scoped packages
  SCOPE=project $0 update       # Update project dependencies (with confirmation)
  SCOPE=all $0 update           # Update system + user scopes
  $0 --dry-run update           # Show what would be updated
  $0 cargo                      # Update only Cargo packages
  DRY_RUN=1 SCOPE=user $0 update # Dry-run user-scope updates

EOF
}

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    --skip-system)
      SKIP_SYSTEM=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    detect)
      show_detected
      exit 0
      ;;
    update)
      run_all_updates
      exit 0
      ;;
    apt)
      update_apt
      exit 0
      ;;
    brew)
      update_brew
      exit 0
      ;;
    cargo)
      update_cargo
      exit 0
      ;;
    uv)
      update_uv
      exit 0
      ;;
    pipx)
      update_pipx
      exit 0
      ;;
    pip)
      update_pip
      exit 0
      ;;
    npm)
      update_npm
      exit 0
      ;;
    pnpm)
      update_pnpm
      exit 0
      ;;
    yarn)
      update_yarn
      exit 0
      ;;
    go)
      update_go
      exit 0
      ;;
    gem)
      update_gem
      exit 0
      ;;
    snap)
      update_snap
      exit 0
      ;;
    flatpak)
      update_flatpak
      exit 0
      ;;
    gcloud)
      update_gcloud
      exit 0
      ;;
    az)
      update_az
      exit 0
      ;;
    *)
      echo "Error: Unknown command '$1'" >&2
      echo "Run '$0 --help' for usage information." >&2
      exit 1
      ;;
  esac
done

# Default: show detected managers
show_detected
