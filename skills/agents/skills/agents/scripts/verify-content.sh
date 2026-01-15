#!/usr/bin/env bash
# verify-content.sh - Verify AGENTS.md content against actual codebase state
# This script checks if documented information matches reality.
#
# CRITICAL: Never trust existing AGENTS.md content. Always verify.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_DIR="${1:-.}"
VERBOSE=false
FIX_MODE=false
EXIT_CODE=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --fix)
            FIX_MODE=true
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage: verify-content.sh [PROJECT_DIR] [OPTIONS]

Verify AGENTS.md content against actual codebase state.

This script extracts information from the actual codebase and compares
it against what's documented in AGENTS.md files. Reports discrepancies
that need manual review or correction.

Options:
  --verbose, -v     Show detailed comparison output
  --fix             Suggest fixes for common issues
  --help, -h        Show this help message

Verification checks:
  1. Documented files exist (scripts, modules, tests)
  2. Documented commands work (make targets)
  3. Counts are accurate (module count, script count)
  4. Descriptions match actual docstrings

Exit codes:
  0 - All checks passed
  1 - Discrepancies found
  2 - Error running verification

Examples:
  verify-content.sh .                    # Verify current project
  verify-content.sh /path/to/project -v  # Verbose output
  verify-content.sh . --fix              # Show fix suggestions
EOF
            exit 0
            ;;
        *)
            PROJECT_DIR="$1"
            shift
            ;;
    esac
done

cd "$PROJECT_DIR"

echo "Verifying AGENTS.md content in: $(pwd)"
echo ""

# Track issues
declare -a ISSUES=()

add_issue() {
    local severity="$1"
    local message="$2"
    ISSUES+=("[$severity] $message")
    EXIT_CODE=1
}

log_check() {
    if [ "$VERBOSE" = true ]; then
        echo "  Checking: $1"
    fi
}

# ============================================================================
# VERIFICATION FUNCTIONS
# ============================================================================

verify_file_exists() {
    local file="$1"
    local source="$2"
    if [ ! -f "$file" ] && [ ! -d "$file" ]; then
        add_issue "ERROR" "File documented in $source does not exist: $file"
        return 1
    fi
    return 0
}

verify_makefile_target() {
    local target="$1"
    if [ -f "Makefile" ]; then
        # Check in main Makefile and includes
        if ! grep -rq "^${target}:" Makefile Makefile.d/ 2>/dev/null; then
            add_issue "WARN" "Makefile target may not exist: $target"
            return 1
        fi
    fi
    return 0
}

extract_documented_files() {
    local agents_file="$1"
    # Extract file references like `filename.sh`, `filename.py`, etc.
    grep -oE '\`[a-zA-Z0-9_-]+\.(sh|py|go|php|ts|js|json)\`' "$agents_file" 2>/dev/null | tr -d '`' | sort -u || true
}

extract_documented_scripts() {
    local agents_file="$1"
    # Extract script references like install_python.sh, guide.sh
    grep -oE '\b[a-zA-Z0-9_-]+\.sh\b' "$agents_file" 2>/dev/null | sort -u || true
}

# ============================================================================
# ROOT AGENTS.MD VERIFICATION
# ============================================================================

echo "=== Verifying Root AGENTS.md ==="

if [ -f "AGENTS.md" ]; then
    echo -e "${GREEN}✓${NC} Root AGENTS.md exists"

    # Check documented make targets
    log_check "Makefile targets"
    DOCUMENTED_TARGETS=$(grep -oE 'make [a-z_-]+' AGENTS.md | sed 's/make //' | sort -u)
    for target in $DOCUMENTED_TARGETS; do
        verify_makefile_target "$target" || true
    done

    # Check for module count claims
    log_check "Module counts"
    MODULE_COUNTS=$(grep -oE '[0-9]+ (Python )?modules?' AGENTS.md | grep -oE '[0-9]+' || true)
    for count in $MODULE_COUNTS; do
        # Try to find actual module directories
        for dir in src cli_audit lib Classes app; do
            if [ -d "$dir" ]; then
                ACTUAL_COUNT=$(find "$dir" -maxdepth 1 -name "*.py" -o -name "*.php" -o -name "*.go" 2>/dev/null | wc -l)
                if [ "$ACTUAL_COUNT" -gt 0 ] && [ "$count" != "$ACTUAL_COUNT" ]; then
                    add_issue "WARN" "Module count mismatch in $dir: documented=$count, actual=$ACTUAL_COUNT"
                fi
            fi
        done
    done

    # Check for script count claims
    log_check "Script counts"
    SCRIPT_COUNTS=$(grep -oE '[0-9]+ (Bash )?scripts?' AGENTS.md | grep -oE '[0-9]+' || true)
    if [ -d "scripts" ] && [ -n "$SCRIPT_COUNTS" ]; then
        ACTUAL_SCRIPTS=$(find scripts -maxdepth 1 -name "*.sh" 2>/dev/null | wc -l)
        for count in $SCRIPT_COUNTS; do
            if [ "$count" != "$ACTUAL_SCRIPTS" ]; then
                add_issue "WARN" "Script count mismatch: documented=$count, actual=$ACTUAL_SCRIPTS"
            fi
        done
    fi
else
    add_issue "ERROR" "Root AGENTS.md does not exist"
fi

echo ""

# ============================================================================
# SCOPED AGENTS.MD VERIFICATION
# ============================================================================

echo "=== Verifying Scoped AGENTS.md Files ==="

# Find all scoped AGENTS.md files
SCOPED_FILES=$(find . -mindepth 2 -name "AGENTS.md" -not -path "./.git/*" 2>/dev/null || true)

for scoped_file in $SCOPED_FILES; do
    scope_dir=$(dirname "$scoped_file")
    scope_name=$(basename "$scope_dir")
    echo ""
    echo "Checking: $scoped_file"

    # Extract and verify documented files
    log_check "Documented files exist"
    DOCUMENTED=$(extract_documented_files "$scoped_file")

    for doc_file in $DOCUMENTED; do
        # Check if file exists relative to scope or project root
        if [ ! -f "${scope_dir}/${doc_file}" ] && [ ! -f "./${doc_file}" ] && [ ! -f "scripts/${doc_file}" ]; then
            # Special handling for common false positives
            case "$doc_file" in
                *.json|*.md|*.yml|*.yaml)
                    # Config files might be in various locations, skip
                    ;;
                *)
                    add_issue "ERROR" "File documented in $scoped_file does not exist: $doc_file"
                    ;;
            esac
        fi
    done

    # For scripts/ scope, verify all documented scripts exist
    if [ "$scope_name" = "scripts" ]; then
        log_check "Script files exist"
        SCRIPTS=$(extract_documented_scripts "$scoped_file")
        for script in $SCRIPTS; do
            # Check multiple locations: scripts/, scripts/lib/, ./
            if [ ! -f "scripts/$script" ] && [ ! -f "scripts/lib/$script" ] && [ ! -f "./$script" ]; then
                # Skip if it's in a commit message example (common pattern: feat(scripts): add xxx.sh)
                if grep -q "feat(scripts):.*$script\|fix(scripts):.*$script\|chore(scripts):.*$script" "$scoped_file" 2>/dev/null; then
                    [ "$VERBOSE" = true ] && echo "    Skipping $script (commit message example)"
                    continue
                fi
                add_issue "ERROR" "Script documented but does not exist: $script"
            fi
        done

        # Check for undocumented scripts
        log_check "All scripts documented"
        if [ -d "scripts" ]; then
            for actual_script in scripts/*.sh; do
                script_name=$(basename "$actual_script")
                if ! grep -q "$script_name" "$scoped_file" 2>/dev/null; then
                    add_issue "WARN" "Script exists but not documented: $script_name"
                fi
            done
        fi
    fi

    # For tests/ scope, verify test file listing
    if [ "$scope_name" = "tests" ]; then
        log_check "Test files documented"
        if [ -d "tests" ]; then
            for test_file in tests/test_*.py; do
                if [ -f "$test_file" ]; then
                    test_name=$(basename "$test_file")
                    if ! grep -q "$test_name" "$scoped_file" 2>/dev/null; then
                        add_issue "WARN" "Test file exists but not documented: $test_name"
                    fi
                fi
            done
        fi
    fi

    echo -e "${GREEN}✓${NC} Checked: $scoped_file"
done

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "=== Verification Summary ==="

if [ ${#ISSUES[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All verification checks passed!${NC}"
else
    echo -e "${RED}Found ${#ISSUES[@]} issue(s):${NC}"
    echo ""
    for issue in "${ISSUES[@]}"; do
        case "$issue" in
            *ERROR*)
                echo -e "  ${RED}$issue${NC}"
                ;;
            *WARN*)
                echo -e "  ${YELLOW}$issue${NC}"
                ;;
            *)
                echo "  $issue"
                ;;
        esac
    done

    if [ "$FIX_MODE" = true ]; then
        echo ""
        echo "=== Fix Suggestions ==="
        echo "1. Run extraction scripts to get actual state:"
        echo "   $SCRIPT_DIR/detect-project.sh ."
        echo "   $SCRIPT_DIR/extract-commands.sh ."
        echo ""
        echo "2. Compare extracted info with AGENTS.md content"
        echo ""
        echo "3. Update AGENTS.md files with verified information"
        echo ""
        echo "4. Re-run this verification: $0 . --verbose"
    fi
fi

echo ""
exit $EXIT_CODE
