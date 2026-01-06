#!/usr/bin/env bash
# check_environment.sh - Audit development environment and report issues
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh" 2>/dev/null || true
source "$DIR/lib/capability.sh" 2>/dev/null || true

# Colors (fallback if lib not loaded)
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[0;33m}"
BLUE="${BLUE:-\033[0;34m}"
NC="${NC:-\033[0m}"

ACTION="${1:-audit}"
PROJECT_DIR="${2:-.}"

log_ok()    { printf "${GREEN}✓${NC} %s\n" "$*"; }
log_warn()  { printf "${YELLOW}⚠${NC} %s\n" "$*"; }
log_error() { printf "${RED}✗${NC} %s\n" "$*"; }
log_info()  { printf "${BLUE}→${NC} %s\n" "$*"; }

# Check if a tool is installed
check_tool() {
    local tool="$1"
    local binary="${2:-$tool}"

    if command -v "$binary" >/dev/null 2>&1; then
        local version
        version=$("$binary" --version 2>&1 | head -1 || echo "unknown")
        log_ok "$tool: $version"
        return 0
    else
        log_error "$tool: NOT INSTALLED"
        return 1
    fi
}

# Check PATH configuration
check_path() {
    log_info "Checking PATH configuration..."
    local issues=0

    # Check common user paths
    local user_paths=(
        "$HOME/.local/bin"
        "$HOME/.cargo/bin"
        "$HOME/.nvm"
        "$HOME/.rbenv/bin"
        "$HOME/go/bin"
    )

    for p in "${user_paths[@]}"; do
        if [ -d "$p" ]; then
            if [[ ":$PATH:" != *":$p:"* ]]; then
                log_warn "$p exists but not in PATH"
                issues=$((issues + 1))
            fi
        fi
    done

    # Check for shadowing (user should come before system)
    if command -v node >/dev/null 2>&1; then
        local node_path
        node_path=$(command -v node)
        if [[ "$node_path" == /usr/* ]] && [ -d "$HOME/.nvm" ]; then
            log_warn "System node ($node_path) may shadow nvm-managed node"
            issues=$((issues + 1))
        fi
    fi

    if [ $issues -eq 0 ]; then
        log_ok "PATH configuration looks good"
    else
        log_warn "$issues PATH issue(s) found"
    fi

    return $issues
}

# Check for duplicate installations
check_duplicates() {
    log_info "Checking for duplicate installations..."
    local issues=0

    # Tools commonly installed multiple ways
    local tools=("node" "python3" "ruby" "cargo")

    for tool in "${tools[@]}"; do
        local paths
        paths=$(type -a "$tool" 2>/dev/null | grep -c "is" || echo 0)
        if [ "$paths" -gt 1 ]; then
            log_warn "$tool has multiple installations:"
            type -a "$tool" 2>/dev/null | head -5
            issues=$((issues + 1))
        fi
    done

    if [ $issues -eq 0 ]; then
        log_ok "No duplicate installations detected"
    fi

    return $issues
}

# Detect and check project requirements
check_project() {
    local project_dir="$1"
    log_info "Checking project requirements in $project_dir..."

    local missing=0
    local outdated=0

    # Use detect_project_type.sh
    if [ -x "$DIR/detect_project_type.sh" ]; then
        local types
        types=$("$DIR/detect_project_type.sh" text "$project_dir" 2>/dev/null || echo "")
        echo "$types"
        echo ""

        # Extract required tools and check each
        local required
        required=$("$DIR/detect_project_type.sh" json "$project_dir" 2>/dev/null | grep -o '"required_tools":\[.*\]' | sed 's/"required_tools":\[//;s/\]//;s/"//g;s/,/ /g' || echo "")

        for tool in $required; do
            if ! check_tool "$tool" >/dev/null 2>&1; then
                missing=$((missing + 1))
            fi
        done
    fi

    if [ $missing -gt 0 ]; then
        log_warn "$missing required tool(s) missing"
    else
        log_ok "All required tools installed"
    fi
}

# Check package managers
check_package_managers() {
    log_info "Checking package managers..."

    local managers=(
        "apt:apt-get"
        "brew:brew"
        "cargo:cargo"
        "npm:npm"
        "pnpm:pnpm"
        "yarn:yarn"
        "pip:pip3"
        "uv:uv"
        "pipx:pipx"
        "gem:gem"
        "go:go"
    )

    local found=0
    for entry in "${managers[@]}"; do
        local name="${entry%%:*}"
        local binary="${entry##*:}"
        if command -v "$binary" >/dev/null 2>&1; then
            local version
            version=$("$binary" --version 2>&1 | head -1 | cut -d' ' -f1-3 || echo "")
            printf "  ${GREEN}●${NC} %s: %s\n" "$name" "$version"
            found=$((found + 1))
        fi
    done

    log_ok "$found package manager(s) available"
}

# Main audit
run_audit() {
    echo ""
    echo "═══════════════════════════════════════════════"
    echo "  CLI Tools Environment Audit"
    echo "═══════════════════════════════════════════════"
    echo ""

    check_path
    echo ""

    check_duplicates
    echo ""

    check_package_managers
    echo ""

    check_project "$PROJECT_DIR"
    echo ""

    echo "═══════════════════════════════════════════════"
    echo "  Core Tools Status"
    echo "═══════════════════════════════════════════════"
    echo ""

    # Check core tools
    check_tool "git" || true
    check_tool "jq" || true
    check_tool "ripgrep" "rg" || true
    check_tool "fd" "fd" || check_tool "fd" "fdfind" || true
    check_tool "fzf" || true
    check_tool "bat" "bat" || check_tool "bat" "batcat" || true

    echo ""
}

# Run update check
run_update_check() {
    log_info "Checking for updates..."

    if [ -x "$DIR/auto_update.sh" ]; then
        DRY_RUN=1 "$DIR/auto_update.sh" update
    else
        log_warn "auto_update.sh not found"
    fi
}

case "$ACTION" in
    audit|check)
        run_audit
        ;;
    update-check)
        run_update_check
        ;;
    path)
        check_path
        ;;
    duplicates)
        check_duplicates
        ;;
    project)
        check_project "$PROJECT_DIR"
        ;;
    managers)
        check_package_managers
        ;;
    *)
        echo "Usage: $0 {audit|update-check|path|duplicates|project|managers} [project_dir]"
        exit 1
        ;;
esac
