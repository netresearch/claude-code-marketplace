#!/usr/bin/env bash
# Scope Detection Library for Package Managers
# Provides functions to detect and count packages by scope (system/user/project)

# ============================================================================
# Project Marker Detection
# ============================================================================

has_project_markers() {
  # Check for common project markers
  [ -f "./package.json" ] || \
  [ -f "./Gemfile" ] || \
  [ -f "./composer.json" ] || \
  [ -f "./Cargo.toml" ] || \
  [ -f "./pyproject.toml" ] || \
  [ -f "./environment.yml" ] || \
  [ -d "./.venv" ] || \
  [ -d "./venv" ] || \
  [ -d "./node_modules" ] || \
  [ -d "./vendor" ]
}

determine_default_scope() {
  # Determine default scope based on current directory context
  if has_project_markers; then
    echo "project"
  else
    echo "user"
  fi
}

# ============================================================================
# System-Only Managers (2)
# ============================================================================

get_apt_scopes() {
  echo "system"
}

get_apt_packages_by_scope() {
  local scope="$1"
  if [ "$scope" = "system" ]; then
    dpkg -l 2>/dev/null | grep '^ii' | wc -l | tr -d '[:space:]'
  else
    echo "0"
  fi
}

get_snap_scopes() {
  echo "system"
}

get_snap_packages_by_scope() {
  local scope="$1"
  if [ "$scope" = "system" ]; then
    snap list 2>/dev/null | tail -n +2 | wc -l | tr -d '[:space:]'
  else
    echo "0"
  fi
}

# ============================================================================
# User-Only Managers (7)
# ============================================================================

get_cargo_scopes() {
  echo "user"
}

get_cargo_packages_by_scope() {
  local scope="$1"
  if [ "$scope" = "user" ]; then
    cargo install --list 2>/dev/null | grep -c '^[^ ]' | tr -d '[:space:]' || echo "0"
  else
    echo "0"
  fi
}

get_rustup_scopes() {
  echo "user"
}

get_rustup_packages_by_scope() {
  local scope="$1"
  if [ "$scope" = "user" ]; then
    rustup toolchain list 2>/dev/null | wc -l | tr -d '[:space:]'
  else
    echo "0"
  fi
}

get_pipx_scopes() {
  echo "user"
}

get_pipx_packages_by_scope() {
  local scope="$1"
  if [ "$scope" = "user" ]; then
    pipx list --short 2>/dev/null | wc -l | tr -d '[:space:]'
  else
    echo "0"
  fi
}

get_go_scopes() {
  echo "user"
}

get_go_packages_by_scope() {
  local scope="$1"
  if [ "$scope" = "user" ]; then
    local gobin
    gobin="$(go env GOBIN 2>/dev/null || echo "$(go env GOPATH 2>/dev/null)/bin")"
    if [ -d "$gobin" ]; then
      ls -1 "$gobin" 2>/dev/null | wc -l | tr -d '[:space:]'
    else
      echo "0"
    fi
  else
    echo "0"
  fi
}

get_gcloud_scopes() {
  echo "user"
}

get_gcloud_packages_by_scope() {
  local scope="$1"
  if [ "$scope" = "user" ]; then
    gcloud components list --filter='State.name:Installed' --format='value(id)' 2>/dev/null | wc -l | tr -d '[:space:]'
  else
    echo "0"
  fi
}

get_poetry_scopes() {
  echo "user"
}

get_poetry_packages_by_scope() {
  local scope="$1"
  if [ "$scope" = "user" ]; then
    echo "N/A"
  else
    echo "0"
  fi
}

# ============================================================================
# System or User Managers (5)
# ============================================================================

get_brew_scopes() {
  local brew_prefix
  brew_prefix="$(brew --prefix 2>/dev/null || echo "")"

  if [ -z "$brew_prefix" ]; then
    echo ""
    return
  fi

  # Check if in user's home directory
  if [[ "$brew_prefix" == "$HOME"* ]] || [ -d "$HOME/.linuxbrew" ]; then
    echo "user"
  else
    echo "system"
  fi
}

get_brew_packages_by_scope() {
  local scope="$1"
  local detected_scope
  detected_scope="$(get_brew_scopes)"

  if [ "$scope" = "$detected_scope" ]; then
    brew list --formula 2>/dev/null | wc -l | tr -d '[:space:]'
  else
    echo "0"
  fi
}

get_flatpak_scopes() {
  local scopes=""
  local sys_count usr_count

  sys_count="$(flatpak list --system --app 2>/dev/null | wc -l | tr -d '[:space:]')"
  usr_count="$(flatpak list --user --app 2>/dev/null | wc -l | tr -d '[:space:]')"

  [ "${sys_count:-0}" -gt 0 ] && scopes="system"
  [ "${usr_count:-0}" -gt 0 ] && { [ -n "$scopes" ] && scopes="$scopes,user" || scopes="user"; }

  echo "$scopes"
}

get_flatpak_packages_by_scope() {
  local scope="$1"
  case "$scope" in
    system)
      flatpak list --system --app 2>/dev/null | wc -l | tr -d '[:space:]'
      ;;
    user)
      flatpak list --user --app 2>/dev/null | wc -l | tr -d '[:space:]'
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_gem_scopes() {
  local scopes=""
  local gem_dir

  gem_dir="$(gem environment gemdir 2>/dev/null || echo "")"

  if [ -n "$gem_dir" ]; then
    if [[ "$gem_dir" == "$HOME"* ]]; then
      scopes="user"
    else
      scopes="system"
    fi
  fi

  if [ -f "./Gemfile" ]; then
    [ -n "$scopes" ] && scopes="$scopes,project" || scopes="project"
  fi

  echo "$scopes"
}

get_gem_packages_by_scope() {
  local scope="$1"
  case "$scope" in
    user|system)
      gem list --no-versions 2>/dev/null | wc -l | tr -d '[:space:]'
      ;;
    project)
      if [ -f "./Gemfile" ]; then
        bundle list 2>/dev/null | grep -c '^\s*\*' | tr -d '[:space:]' || echo "0"
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_nuget_scopes() {
  local scopes=""

  if command -v nuget >/dev/null 2>&1; then
    scopes="system"
  elif command -v dotnet >/dev/null 2>&1; then
    scopes="user"
  fi

  if compgen -G "./*.csproj" >/dev/null 2>&1 || compgen -G "./*.sln" >/dev/null 2>&1; then
    [ -n "$scopes" ] && scopes="$scopes,project" || scopes="project"
  fi

  echo "$scopes"
}

get_nuget_packages_by_scope() {
  local scope="$1"
  case "$scope" in
    system|user)
      echo "N/A"
      ;;
    project)
      if command -v dotnet >/dev/null 2>&1; then
        dotnet list package 2>/dev/null | grep -c '>' | tr -d '[:space:]' || echo "0"
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_az_scopes() {
  if command -v apt-get >/dev/null 2>&1 && dpkg -l azure-cli >/dev/null 2>&1; then
    echo "system"
  else
    echo "user"
  fi
}

get_az_packages_by_scope() {
  local scope="$1"
  local detected_scope
  detected_scope="$(get_az_scopes)"

  if [ "$scope" = "$detected_scope" ]; then
    az extension list 2>/dev/null | grep -c '"name":' | tr -d '[:space:]' || echo "0"
  else
    echo "0"
  fi
}

# ============================================================================
# User + Project Managers (7)
# ============================================================================

get_uv_scopes() {
  local scopes="user"

  if [ -d "./.venv" ] || [ -f "./pyproject.toml" ]; then
    scopes="user,project"
  fi

  echo "$scopes"
}

get_uv_packages_by_scope() {
  local scope="$1"
  case "$scope" in
    user)
      uv tool list 2>/dev/null | wc -l | tr -d '[:space:]'
      ;;
    project)
      if [ -d "./.venv" ]; then
        ./.venv/bin/python -m pip list 2>/dev/null | tail -n +3 | wc -l | tr -d '[:space:]'
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_pip_scopes() {
  local scopes="user"

  if [ -n "${VIRTUAL_ENV:-}" ] || [ -d "./.venv" ] || [ -d "./venv" ] || [ -f "./pyproject.toml" ]; then
    scopes="user,project"
  fi

  echo "$scopes"
}

get_pip_packages_by_scope() {
  local scope="$1"
  local count
  case "$scope" in
    user)
      # Use system python3 explicitly (not virtualenv)
      count=$(/usr/bin/python3 -m pip list --user 2>/dev/null | tail -n +3 | wc -l | tr -d '[:space:]') || count="0"
      echo "${count:-0}"
      ;;
    project)
      if [ -n "${VIRTUAL_ENV:-}" ]; then
        count=$(python3 -m pip list 2>/dev/null | tail -n +3 | wc -l | tr -d '[:space:]') || count="0"
        echo "${count:-0}"
      elif [ -d "./.venv" ]; then
        count=$(./.venv/bin/python -m pip list 2>/dev/null | tail -n +3 | wc -l | tr -d '[:space:]') || count="0"
        echo "${count:-0}"
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_npm_scopes() {
  local scopes=""
  local npm_prefix

  npm_prefix="$(npm config get prefix 2>/dev/null || echo "")"

  if [ -n "$npm_prefix" ]; then
    if [[ "$npm_prefix" == "$HOME"* ]]; then
      scopes="user"
    else
      scopes="system"
    fi
  fi

  if [ -f "./package.json" ]; then
    [ -n "$scopes" ] && scopes="$scopes,project" || scopes="project"
  fi

  echo "$scopes"
}

get_npm_packages_by_scope() {
  local scope="$1"
  case "$scope" in
    user|system)
      npm list -g --depth=0 2>/dev/null | grep -c '^[├└]' | tr -d '[:space:]' || echo "0"
      ;;
    project)
      if [ -f "./package.json" ]; then
        npm list --depth=0 2>/dev/null | grep -c '^[├└]' | tr -d '[:space:]' || echo "0"
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_pnpm_scopes() {
  local scopes=""
  local pnpm_prefix

  pnpm_prefix="$(pnpm config get prefix 2>/dev/null || echo "")"

  if [ -n "$pnpm_prefix" ]; then
    if [[ "$pnpm_prefix" == "$HOME"* ]]; then
      scopes="user"
    else
      scopes="system"
    fi
  fi

  if [ -f "./package.json" ]; then
    [ -n "$scopes" ] && scopes="$scopes,project" || scopes="project"
  fi

  echo "$scopes"
}

get_pnpm_packages_by_scope() {
  local scope="$1"
  local count
  case "$scope" in
    user|system)
      count=$(pnpm list -g --depth=0 2>/dev/null | grep -c '^[├└]' | tr -d '[:space:]') || count="0"
      echo "${count:-0}"
      ;;
    project)
      if [ -f "./package.json" ]; then
        count=$(pnpm list --depth=0 2>/dev/null | grep -c '^[├└]' | tr -d '[:space:]') || count="0"
        echo "${count:-0}"
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_yarn_scopes() {
  local scopes=""
  local yarn_prefix

  yarn_prefix="$(yarn global dir 2>/dev/null | head -n1 || echo "")"

  if [ -n "$yarn_prefix" ]; then
    if [[ "$yarn_prefix" == "$HOME"* ]]; then
      scopes="user"
    else
      scopes="system"
    fi
  fi

  if [ -f "./package.json" ]; then
    [ -n "$scopes" ] && scopes="$scopes,project" || scopes="project"
  fi

  echo "$scopes"
}

get_yarn_packages_by_scope() {
  local scope="$1"
  local count
  case "$scope" in
    user|system)
      count=$(yarn global list 2>/dev/null | grep -c '^info' | tr -d '[:space:]') || count="0"
      echo "${count:-0}"
      ;;
    project)
      if [ -f "./package.json" ]; then
        count=$(yarn list --depth=0 2>/dev/null | grep -c '^├─' | tr -d '[:space:]') || count="0"
        echo "${count:-0}"
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_composer_scopes() {
  local scopes="user"

  if [ -f "./composer.json" ]; then
    scopes="user,project"
  fi

  echo "$scopes"
}

get_composer_packages_by_scope() {
  local scope="$1"
  case "$scope" in
    user)
      composer global show 2>/dev/null | wc -l | tr -d '[:space:]'
      ;;
    project)
      if [ -f "./composer.json" ]; then
        composer show 2>/dev/null | wc -l | tr -d '[:space:]'
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_jspm_scopes() {
  local scopes="user"

  if [ -f "./package.json" ]; then
    scopes="user,project"
  fi

  echo "$scopes"
}

get_jspm_packages_by_scope() {
  local scope="$1"
  case "$scope" in
    user)
      echo "N/A"
      ;;
    project)
      if [ -f "./package.json" ] && [ -d "./jspm_packages" ]; then
        find ./jspm_packages -maxdepth 2 -type d 2>/dev/null | wc -l | tr -d '[:space:]'
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

# ============================================================================
# System + User + Project Managers (3)
# ============================================================================

get_conda_scopes() {
  local scopes=""
  local conda_prefix="${CONDA_PREFIX:-}"

  if [ -n "$conda_prefix" ]; then
    if [[ "$conda_prefix" == *"/base"* ]]; then
      scopes="system"
    else
      scopes="user"
    fi
  else
    scopes="user"
  fi

  if [ -f "./environment.yml" ]; then
    [ -n "$scopes" ] && scopes="$scopes,project" || scopes="project"
  fi

  echo "$scopes"
}

get_conda_packages_by_scope() {
  local scope="$1"
  case "$scope" in
    system|user)
      conda list 2>/dev/null | tail -n +4 | wc -l | tr -d '[:space:]'
      ;;
    project)
      if [ -f "./environment.yml" ]; then
        echo "N/A"
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_mamba_scopes() {
  local scopes=""
  local mamba_prefix="${MAMBA_PREFIX:-${CONDA_PREFIX:-}}"

  if [ -n "$mamba_prefix" ]; then
    if [[ "$mamba_prefix" == *"/base"* ]]; then
      scopes="system"
    else
      scopes="user"
    fi
  else
    scopes="user"
  fi

  if [ -f "./environment.yml" ]; then
    [ -n "$scopes" ] && scopes="$scopes,project" || scopes="project"
  fi

  echo "$scopes"
}

get_mamba_packages_by_scope() {
  local scope="$1"
  case "$scope" in
    system|user)
      mamba list 2>/dev/null | tail -n +4 | wc -l | tr -d '[:space:]'
      ;;
    project)
      if [ -f "./environment.yml" ]; then
        echo "N/A"
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_bundler_scopes() {
  if [ -f "./Gemfile" ]; then
    echo "project"
  else
    echo ""
  fi
}

get_bundler_packages_by_scope() {
  local scope="$1"
  if [ "$scope" = "project" ] && [ -f "./Gemfile" ]; then
    bundle list 2>/dev/null | grep -c '^\s*\*' | tr -d '[:space:]' || echo "0"
  else
    echo "0"
  fi
}

# ============================================================================
# Unified Scope Detection
# ============================================================================

get_manager_scopes() {
  local mgr="$1"

  case "$mgr" in
    # System-only
    apt) get_apt_scopes ;;
    snap) get_snap_scopes ;;

    # User-only
    cargo) get_cargo_scopes ;;
    rustup) get_rustup_scopes ;;
    pipx) get_pipx_scopes ;;
    go) get_go_scopes ;;
    gcloud) get_gcloud_scopes ;;
    poetry) get_poetry_scopes ;;

    # System or User
    brew) get_brew_scopes ;;
    flatpak) get_flatpak_scopes ;;
    gem) get_gem_scopes ;;
    nuget) get_nuget_scopes ;;
    az) get_az_scopes ;;

    # User + Project
    uv) get_uv_scopes ;;
    pip) get_pip_scopes ;;
    npm) get_npm_scopes ;;
    pnpm) get_pnpm_scopes ;;
    yarn) get_yarn_scopes ;;
    composer) get_composer_scopes ;;
    jspm) get_jspm_scopes ;;

    # System + User + Project
    conda) get_conda_scopes ;;
    mamba) get_mamba_scopes ;;
    bundler) get_bundler_scopes ;;

    *)
      echo "unknown"
      ;;
  esac
}

get_manager_packages_by_scope() {
  local mgr="$1"
  local scope="$2"

  case "$mgr" in
    apt) get_apt_packages_by_scope "$scope" ;;
    snap) get_snap_packages_by_scope "$scope" ;;
    cargo) get_cargo_packages_by_scope "$scope" ;;
    rustup) get_rustup_packages_by_scope "$scope" ;;
    pipx) get_pipx_packages_by_scope "$scope" ;;
    go) get_go_packages_by_scope "$scope" ;;
    gcloud) get_gcloud_packages_by_scope "$scope" ;;
    poetry) get_poetry_packages_by_scope "$scope" ;;
    brew) get_brew_packages_by_scope "$scope" ;;
    flatpak) get_flatpak_packages_by_scope "$scope" ;;
    gem) get_gem_packages_by_scope "$scope" ;;
    nuget) get_nuget_packages_by_scope "$scope" ;;
    az) get_az_packages_by_scope "$scope" ;;
    uv) get_uv_packages_by_scope "$scope" ;;
    pip) get_pip_packages_by_scope "$scope" ;;
    npm) get_npm_packages_by_scope "$scope" ;;
    pnpm) get_pnpm_packages_by_scope "$scope" ;;
    yarn) get_yarn_packages_by_scope "$scope" ;;
    composer) get_composer_packages_by_scope "$scope" ;;
    jspm) get_jspm_packages_by_scope "$scope" ;;
    conda) get_conda_packages_by_scope "$scope" ;;
    mamba) get_mamba_packages_by_scope "$scope" ;;
    bundler) get_bundler_packages_by_scope "$scope" ;;
    *)
      echo "0"
      ;;
  esac
}
