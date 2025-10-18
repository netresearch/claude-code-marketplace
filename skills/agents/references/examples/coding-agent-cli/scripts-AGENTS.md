<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: 2025-10-09 -->

# Installation Scripts - Agent Guide

**Scope:** Shell scripts for tool installation, update, uninstall, reconcile

## Overview

13+ Bash scripts for installing developer tools with multiple actions:
- **install**: Fresh installation (default action)
- **update**: Upgrade to latest version
- **uninstall**: Remove installation
- **reconcile**: Switch to preferred installation method (e.g., system → user)

**Key scripts:**
- `install_core.sh`: Core tools (fd, fzf, ripgrep, jq, yq, bat, delta, just)
- `install_python.sh`: Python toolchain via uv
- `install_node.sh`: Node.js via nvm
- `install_rust.sh`: Rust via rustup
- `install_go.sh`, `install_aws.sh`, `install_kubectl.sh`, etc.
- `guide.sh`: Interactive upgrade guide
- `test_smoke.sh`: Smoke test for audit output

**Shared utilities:** `lib/` directory (colors, logging, common functions)

## Setup

**Requirements:**
- Bash 4.0+
- `curl` or `wget` for downloads
- Internet access for fresh installs
- Appropriate permissions (user for `~/.local/bin`, sudo for system)

**Environment variables:**
```bash
INSTALL_PREFIX=${INSTALL_PREFIX:-~/.local}  # Default: user-level
FORCE_INSTALL=1                              # Skip confirmation prompts
DEBUG=1                                      # Verbose output
```

**Permissions:**
```bash
make scripts-perms  # Ensure all scripts are executable
```

## Build & Tests

**Run individual script:**
```bash
# Install action (default)
./scripts/install_python.sh

# Update action
./scripts/install_python.sh update

# Uninstall action
./scripts/install_python.sh uninstall

# Reconcile action (switch installation method)
./scripts/install_node.sh reconcile
```

**Via Make:**
```bash
make install-python              # Install Python toolchain
make update-python               # Update Python toolchain
make uninstall-python            # Uninstall Python toolchain
make reconcile-node              # Switch Node.js to nvm-managed
```

**Smoke test:**
```bash
./scripts/test_smoke.sh          # Verify audit output format
```

**Debug mode:**
```bash
DEBUG=1 ./scripts/install_python.sh
bash -x ./scripts/install_python.sh  # Trace execution
```

## Code Style

**Shell standards:**
- Bash 4.0+ features allowed
- Shebang: `#!/usr/bin/env bash` or `#!/bin/bash`
- Set strict mode: `set -euo pipefail`
  - `-e`: Exit on error
  - `-u`: Error on undefined variables
  - `-o pipefail`: Fail on pipe errors

**Formatting:**
- 4-space indentation (matches EditorConfig)
- Function names: lowercase_with_underscores
- Constants: UPPER_CASE
- Local variables: lowercase

**Structure:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/colors.sh" || true
source "${SCRIPT_DIR}/lib/common.sh" || true

# Main function per action
install_tool() {
    echo_info "Installing <tool>..."
    # Implementation
}

update_tool() {
    echo_info "Updating <tool>..."
    # Implementation
}

uninstall_tool() {
    echo_info "Uninstalling <tool>..."
    # Implementation
}

reconcile_tool() {
    echo_info "Reconciling <tool>..."
    # Implementation
}

# Action dispatcher
ACTION="${1:-install}"
case "$ACTION" in
    install) install_tool ;;
    update) update_tool ;;
    uninstall) uninstall_tool ;;
    reconcile) reconcile_tool ;;
    *) echo "Usage: $0 {install|update|uninstall|reconcile}"; exit 1 ;;
esac
```

**Error handling:**
```bash
# Good: Check command exists before using
if ! command -v curl >/dev/null 2>&1; then
    echo_error "curl not found. Install it first."
    exit 1
fi

# Good: Check return codes
if ! download_file "$URL" "$DEST"; then
    echo_error "Download failed"
    exit 1
fi

# Good: Cleanup on error
trap 'rm -rf "$TMPDIR"' EXIT ERR
```

**Confirmation prompts:**
```bash
# Good: Skip prompt if FORCE_INSTALL=1
if [[ "${FORCE_INSTALL:-0}" != "1" ]]; then
    read -p "Install <tool>? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi
```

## Security

**Download verification:**
```bash
# Always use HTTPS
URL="https://github.com/owner/repo/releases/download/..."

# Verify checksums when available
EXPECTED_SHA256="abc123..."
ACTUAL_SHA256=$(sha256sum "$FILE" | awk '{print $1}')
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
    echo_error "Checksum mismatch!"
    exit 1
fi
```

**Path safety:**
```bash
# Good: Quote variables, use absolute paths
INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"
mv "$TMPFILE" "$INSTALL_DIR/tool"

# Bad: Unquoted, relative paths
mkdir -p $INSTALL_DIR
mv tool bin/
```

**Sudo usage:**
```bash
# Good: Prompt for sudo only when needed
if [[ "$INSTALL_PREFIX" == "/usr/local" ]]; then
    if ! sudo -v; then
        echo_error "Sudo required for system installation"
        exit 1
    fi
    sudo mv "$FILE" "$INSTALL_PREFIX/bin/"
else
    # User-level, no sudo
    mv "$FILE" "$INSTALL_PREFIX/bin/"
fi
```

**No secrets in scripts:**
- No API keys, tokens, passwords in scripts
- Use environment variables: `${GITHUB_TOKEN:-}`
- Document required env vars in script comments

## PR/Commit Checklist

**Before commit:**
- [ ] Run `shellcheck <script>` (if available)
- [ ] Test install action: `./scripts/install_<tool>.sh`
- [ ] Test update action: `./scripts/install_<tool>.sh update`
- [ ] Test uninstall action: `./scripts/install_<tool>.sh uninstall`
- [ ] Update `scripts/README.md` if new script or behavior change
- [ ] Verify script permissions: `make scripts-perms`

**Script checklist:**
- [ ] Shebang: `#!/usr/bin/env bash`
- [ ] Strict mode: `set -euo pipefail`
- [ ] Source shared lib: `source "${SCRIPT_DIR}/lib/colors.sh"`
- [ ] Action dispatcher (install/update/uninstall/reconcile)
- [ ] Error handling (check return codes, trap on exit)
- [ ] Confirmation prompts (respect FORCE_INSTALL)
- [ ] PATH updates (add to ~/.bashrc or ~/.zshrc if needed)

**Commit messages:**
- `feat(scripts): add install_terraform.sh`
- `fix(install-python): handle uv bootstrap failure`
- `docs(scripts): update README with reconcile action`

## Good vs Bad Examples

**Good: Robust download with fallback**
```bash
download_file() {
    local url="$1"
    local dest="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$dest"
    else
        echo_error "Neither curl nor wget found"
        return 1
    fi
}
```

**Bad: Assumes curl exists**
```bash
download_file() {
    curl -fsSL "$1" -o "$2"  # Fails if curl not installed
}
```

**Good: Version comparison**
```bash
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

CURRENT_VERSION="1.2.3"
LATEST_VERSION="1.3.0"

if version_gt "$LATEST_VERSION" "$CURRENT_VERSION"; then
    echo "Upgrade available"
fi
```

**Bad: String comparison for versions**
```bash
if [[ "$LATEST_VERSION" > "$CURRENT_VERSION" ]]; then
    # Wrong: "1.10.0" < "1.9.0" (string comparison)
    echo "Upgrade available"
fi
```

**Good: Cleanup on exit**
```bash
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT ERR

# Download to temp
download_file "$URL" "$TMPDIR/file"
# ... process ...
# Cleanup happens automatically via trap
```

**Bad: Manual cleanup (error-prone)**
```bash
TMPDIR=$(mktemp -d)
download_file "$URL" "$TMPDIR/file"
# ... process ...
rm -rf "$TMPDIR"  # Skipped if earlier command fails
```

**Good: Action-specific logic**
```bash
install_rust() {
    if command -v rustup >/dev/null 2>&1; then
        echo_warn "rustup already installed"
        return 0
    fi

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
}

update_rust() {
    if ! command -v rustup >/dev/null 2>&1; then
        echo_error "rustup not installed. Run install first."
        return 1
    fi

    rustup update
}
```

## When Stuck

**Script fails silently:**
1. Add debug: `bash -x ./scripts/install_<tool>.sh`
2. Check logs: `./scripts/install_<tool>.sh 2>&1 | tee install.log`
3. Verify permissions: `ls -la scripts/`

**Download fails:**
1. Check network: `curl -I https://github.com`
2. Check URL: `echo "$URL"` (verify it's correct)
3. Try manual download: `curl -fsSL "$URL"`

**Installation fails:**
1. Check prerequisites (e.g., Python for uv, curl for rustup)
2. Check disk space: `df -h`
3. Check permissions: `ls -ld "$INSTALL_PREFIX"`

**PATH not updated:**
1. Source shell config: `source ~/.bashrc` or `source ~/.zshrc`
2. Check PATH: `echo $PATH | tr ':' '\n' | grep local`
3. Verify binary location: `ls -la ~/.local/bin/<tool>`

**Reconcile fails:**
1. Check current installation: `which <tool>`
2. Check installation method: `cli_audit.py --only <tool>`
3. Manually remove old version first: `apt remove <tool>` or `cargo uninstall <tool>`

**Documentation:**
- Script-specific docs: [README.md](README.md) (this directory)
- Troubleshooting: [../docs/TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)
- Architecture: [../docs/DEPLOYMENT.md](../docs/DEPLOYMENT.md#installation-scripts)

## House Rules

**Installation preferences** (Phase 2 planning):
- User-level preferred: `~/.local/bin` (workstations)
- System-level for servers: `/usr/local/bin`
- Vendor tools first: rustup, nvm, uv over system packages
- See [../docs/adr/ADR-002-package-manager-hierarchy.md](../docs/adr/ADR-002-package-manager-hierarchy.md)

**Reconciliation strategy:**
- Parallel approach: Keep both installations, prefer user via PATH
- No automatic removal (user chooses)
- See [../docs/adr/ADR-003-parallel-installation-approach.md](../docs/adr/ADR-003-parallel-installation-approach.md)

**Version policy:**
- Always latest by default
- Warn on major version upgrades
- See [../docs/adr/ADR-004-always-latest-version-policy.md](../docs/adr/ADR-004-always-latest-version-policy.md)

**Script structure:**
- Multi-action support: install, update, uninstall, reconcile
- Shared utilities in `lib/`
- Consistent error handling and logging
- Make integration via `make install-<tool>`

---

**Quick Start:** Run `make install-core` to install essential tools, then `make audit` to verify.

**Troubleshooting:** See [README.md](README.md) for per-script troubleshooting and [../docs/TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) for general issues.
