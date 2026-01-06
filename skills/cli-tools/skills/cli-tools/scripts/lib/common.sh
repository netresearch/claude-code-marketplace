#!/usr/bin/env bash
set -euo pipefail

# Common helpers for installer scripts

have() { command -v "$1" >/dev/null 2>&1; }

log() { printf '%s\n' "$*" >&2; }

os_id() {
  if [ -f /etc/os-release ]; then . /etc/os-release; echo "${ID:-unknown}"; else echo unknown; fi
}

ensure_sudo() { have sudo || { log "sudo not available"; exit 1; }; }

apt_remove_if_present() {
  have apt-get || return 0
  ensure_sudo
  for pkg in "$@"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then sudo apt-get remove -y "$pkg" || true; fi
  done
}

apt_purge_if_present() {
  have apt-get || return 0
  ensure_sudo
  for pkg in "$@"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then sudo apt-get purge -y "$pkg" || true; fi
  done
}

brew_install() { brew install "$@"; }
brew_upgrade() { brew upgrade "$@" || true; }
brew_uninstall() { brew uninstall -f "$@" || true; }

pipx_install() { have pipx || python3 -m pip install --user pipx; pipx install "$1" || true; }
pipx_upgrade() { have pipx && pipx upgrade "$1" || true; }
pipx_uninstall() { have pipx && pipx uninstall "$1" || true; }

# nvm helpers
ensure_nvm_loaded() {
  # shellcheck disable=SC1090
  [ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh" || true
}

nvm_install_lts() { ensure_nvm_loaded; have nvm || return 1; nvm install --lts; }
nvm_use_lts() { ensure_nvm_loaded; have nvm || return 1; nvm use --lts || nvm alias default 'lts/*' || true; }

# rustup helpers
rustup_update() { have rustup && rustup self update && rustup update || true; }
rustup_uninstall() { have rustup && rustup self uninstall -y || true; }

# Paths helpers for preferred sources
is_path_under() { case "$1" in "$2"*) return 0 ;; *) return 1 ;; esac }

prefers_nvm_node() {
  local p
  p="$(command -v node || true)"
  is_path_under "$p" "$HOME/.nvm" || return 1
}

prefers_rustup() {
  local p
  p="$(command -v cargo || true)"
  is_path_under "$p" "$HOME/.cargo" || return 1
}

# rbenv helpers
ensure_rbenv_loaded() {
  # Add rbenv to PATH and initialize if available
  if [ -d "$HOME/.rbenv" ]; then
    export PATH="$HOME/.rbenv/bin:$PATH"
    if command -v rbenv >/dev/null 2>&1; then
      eval "$(rbenv init - bash)" || true
    fi
  fi
}

prefers_rbenv_ruby() {
  local p
  p="$(command -v ruby || true)"
  is_path_under "$p" "$HOME/.rbenv" || return 1
}


