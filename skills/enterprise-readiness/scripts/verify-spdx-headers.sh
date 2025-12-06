#!/bin/bash
# verify-spdx-headers.sh - Verify SPDX license headers exist in source files
# Usage: ./verify-spdx-headers.sh [--fix] [directory]
# OpenSSF Badge Criteria: license_per_file, copyright_per_file (Gold)
set -euo pipefail

FIX_MODE=false
TARGET_DIR="."

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix)
            FIX_MODE=true
            shift
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

echo "=== SPDX Header Verification ==="
echo "Directory: $TARGET_DIR"
echo "Mode: $([ "$FIX_MODE" = true ] && echo 'Fix' || echo 'Check only')"
echo ""

# Supported file extensions (POSIX-compatible, no bash 4+ associative arrays)
SUPPORTED_EXTS="go py js ts jsx tsx rs java c cpp h sh rb"

# Exclude patterns
EXCLUDE_DIRS="vendor|node_modules|.git|dist|build|.venv|__pycache__"

TOTAL=0
MISSING=0
MISSING_FILES=""

echo "=== Checking Files ==="
echo ""

for ext in $SUPPORTED_EXTS; do
    # Find files with this extension, excluding common non-source directories
    while IFS= read -r -d '' file; do
        TOTAL=$((TOTAL + 1))

        # Check for SPDX header in first 10 lines
        if ! head -10 "$file" | grep -q "SPDX-License-Identifier"; then
            MISSING=$((MISSING + 1))
            MISSING_FILES="${MISSING_FILES}${file}
"
            echo "✗ Missing SPDX header: $file"
        fi
    done < <(find "$TARGET_DIR" -type f -name "*.$ext" \
        ! -path "*/$EXCLUDE_DIRS/*" \
        -print0 2>/dev/null)
done

echo ""
echo "=== Summary ==="
echo "Total files checked: $TOTAL"
echo "Files with SPDX headers: $((TOTAL - MISSING))"
echo "Files missing headers: $MISSING"

if [ "$TOTAL" -eq 0 ]; then
    echo ""
    echo "No source files found to check."
    exit 0
fi

# Calculate percentage using awk (POSIX-compatible)
PCT=$(awk -v m="$MISSING" -v t="$TOTAL" 'BEGIN { printf "%.1f", ((t-m)/t)*100 }')
echo "Coverage: $PCT%"
echo ""

if [ "$MISSING" -eq 0 ]; then
    echo "✓ All source files have SPDX license headers"
    exit 0
else
    echo "✗ $MISSING file(s) missing SPDX headers"
    echo ""

    if [ "$FIX_MODE" = true ]; then
        # Check if add-spdx-headers.sh exists in the same directory
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
        if [ -x "$SCRIPT_DIR/add-spdx-headers.sh" ]; then
            echo "Running add-spdx-headers.sh to fix missing headers..."
            "$SCRIPT_DIR/add-spdx-headers.sh"
            exit $?
        else
            echo "Error: add-spdx-headers.sh not found or not executable"
            echo "Please run: ./add-spdx-headers.sh [license] [copyright]"
            exit 1
        fi
    else
        echo "Files missing headers:"
        printf "%s" "$MISSING_FILES" | head -20
        if [ "$MISSING" -gt 20 ]; then
            echo "... and $((MISSING - 20)) more"
        fi
        echo ""
        echo "To add headers automatically, run:"
        echo "  ./add-spdx-headers.sh [license] [copyright]"
        echo ""
        echo "Or run this script with --fix flag:"
        echo "  ./verify-spdx-headers.sh --fix"
    fi
    exit 1
fi
