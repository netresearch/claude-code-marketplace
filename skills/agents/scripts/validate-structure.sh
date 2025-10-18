#!/usr/bin/env bash
# Validate AGENTS.md structure compliance
set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

ERRORS=0
WARNINGS=0

error() {
    echo "❌ ERROR: $*"
    ((ERRORS++))
}

warning() {
    echo "⚠️  WARNING: $*"
    ((WARNINGS++))
}

success() {
    echo "✅ $*"
}

# Check if file has managed header
check_managed_header() {
    local file="$1"

    if grep -q "^<!-- Managed by agent:" "$file"; then
        success "Managed header present: $file"
        return 0
    else
        warning "Missing managed header: $file"
        return 1
    fi
}

# Check if root is thin (≤50 lines or has scope index)
check_root_is_thin() {
    local file="$1"
    local line_count=$(wc -l < "$file")

    if [ "$line_count" -le 50 ]; then
        success "Root is thin: $line_count lines"
        return 0
    elif grep -q "## Index of scoped AGENTS.md" "$file"; then
        success "Root has scope index (verbose style acceptable)"
        return 0
    else
        error "Root is bloated: $line_count lines and no scope index"
        return 1
    fi
}

# Check if root has precedence statement
check_precedence_statement() {
    local file="$1"

    if grep -qi "precedence" "$file" && grep -qi "closest.*AGENTS.md.*wins" "$file"; then
        success "Precedence statement present"
        return 0
    else
        error "Missing precedence statement in root"
        return 1
    fi
}

# Check if scoped file has all 9 sections
check_scoped_sections() {
    local file="$1"
    local required_sections=(
        "## Overview"
        "## Setup & environment"
        "## Build & tests"
        "## Code style & conventions"
        "## Security & safety"
        "## PR/commit checklist"
        "## Good vs. bad examples"
        "## When stuck"
    )

    local missing=()

    for section in "${required_sections[@]}"; do
        if ! grep -q "^$section" "$file"; then
            missing+=("$section")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        success "All required sections present: $file"
        return 0
    else
        error "Missing sections in $file: ${missing[*]}"
        return 1
    fi
}

# Check if scope index links work
check_scope_links() {
    local root_file="$1"

    if ! grep -q "## Index of scoped AGENTS.md" "$root_file"; then
        return 0  # No index, skip check
    fi

    # Extract links from scope index
    local links=$(sed -n '/## Index of scoped AGENTS.md/,/^##/p' "$root_file" | grep -o '\./[^)]*AGENTS.md' || true)

    if [ -z "$links" ]; then
        warning "Scope index present but no links found"
        return 1
    fi

    local broken=()
    while read -r link; do
        # Remove leading ./
        local clean_link="${link#./}"
        local full_path="$PROJECT_DIR/$clean_link"

        if [ ! -f "$full_path" ]; then
            broken+=("$link")
        fi
    done <<< "$links"

    if [ ${#broken[@]} -eq 0 ]; then
        success "All scope index links work"
        return 0
    else
        error "Broken scope index links: ${broken[*]}"
        return 1
    fi
}

# Main validation
echo "Validating AGENTS.md structure in: $PROJECT_DIR"
echo ""

# Check root AGENTS.md
ROOT_FILE="$PROJECT_DIR/AGENTS.md"

if [ ! -f "$ROOT_FILE" ]; then
    error "Root AGENTS.md not found"
else
    echo "=== Root AGENTS.md ==="
    check_managed_header "$ROOT_FILE"
    check_root_is_thin "$ROOT_FILE"
    check_precedence_statement "$ROOT_FILE"
    check_scope_links "$ROOT_FILE"
    echo ""
fi

# Check scoped AGENTS.md files
SCOPED_FILES=$(find "$PROJECT_DIR" -name "AGENTS.md" -not -path "$ROOT_FILE" 2>/dev/null || true)

if [ -n "$SCOPED_FILES" ]; then
    echo "=== Scoped AGENTS.md Files ==="
    while read -r file; do
        rel_path="${file#$PROJECT_DIR/}"
        echo "Checking: $rel_path"
        check_managed_header "$file"
        check_scoped_sections "$file"
        echo ""
    done <<< "$SCOPED_FILES"
fi

# Summary
echo "=== Validation Summary ==="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ All checks passed!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  Validation passed with $WARNINGS warning(s)"
    exit 0
else
    echo "❌ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)"
    exit 1
fi
