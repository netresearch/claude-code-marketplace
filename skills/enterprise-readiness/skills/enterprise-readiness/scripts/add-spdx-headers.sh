#!/bin/bash
# add-spdx-headers.sh - Add SPDX license headers to source files
# Usage: ./add-spdx-headers.sh [--license MIT|Apache-2.0|...] [--copyright "Your Name"]
set -euo pipefail

LICENSE="${1:-MIT}"
COPYRIGHT="${2:-$(git config user.name 2>/dev/null || echo "Project Authors")}"
YEAR=$(date +%Y)

echo "=== Adding SPDX Headers ==="
echo "License: $LICENSE"
echo "Copyright: $COPYRIGHT"
echo "Year: $YEAR"
echo ""

# Go files
add_go_header() {
    local file="$1"
    if ! grep -q "SPDX-License-Identifier" "$file"; then
        local temp_file
        temp_file=$(mktemp)
        {
            echo "// SPDX-License-Identifier: $LICENSE"
            echo "// Copyright (c) $YEAR $COPYRIGHT"
            echo ""
            cat "$file"
        } > "$temp_file" && cat "$temp_file" > "$file" && rm -f "$temp_file" || rm -f "$temp_file"
        echo "Added header to: $file"
    fi
}

# Python files
add_python_header() {
    local file="$1"
    if ! grep -q "SPDX-License-Identifier" "$file"; then
        local temp_file
        temp_file=$(mktemp)
        # Handle shebang
        if head -1 "$file" | grep -q "^#!"; then
            {
                head -1 "$file"
                echo "# SPDX-License-Identifier: $LICENSE"
                echo "# Copyright (c) $YEAR $COPYRIGHT"
                echo ""
                tail -n +2 "$file"
            } > "$temp_file" && cat "$temp_file" > "$file" && rm -f "$temp_file" || rm -f "$temp_file"
        else
            {
                echo "# SPDX-License-Identifier: $LICENSE"
                echo "# Copyright (c) $YEAR $COPYRIGHT"
                echo ""
                cat "$file"
            } > "$temp_file" && cat "$temp_file" > "$file" && rm -f "$temp_file" || rm -f "$temp_file"
        fi
        echo "Added header to: $file"
    fi
}

# JavaScript/TypeScript files
add_js_header() {
    local file="$1"
    if ! grep -q "SPDX-License-Identifier" "$file"; then
        local temp_file
        temp_file=$(mktemp)
        {
            echo "// SPDX-License-Identifier: $LICENSE"
            echo "// Copyright (c) $YEAR $COPYRIGHT"
            echo ""
            cat "$file"
        } > "$temp_file" && cat "$temp_file" > "$file" && rm -f "$temp_file" || rm -f "$temp_file"
        echo "Added header to: $file"
    fi
}

# Find and process files
echo "Processing Go files..."
find . -name "*.go" -not -path "./vendor/*" -not -path "./.git/*" | while read -r file; do
    add_go_header "$file"
done

echo ""
echo "Processing Python files..."
find . -name "*.py" -not -path "./vendor/*" -not -path "./.git/*" -not -path "./.venv/*" | while read -r file; do
    add_python_header "$file"
done

echo ""
echo "Processing JavaScript/TypeScript files..."
find . \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) \
    -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./dist/*" | while read -r file; do
    add_js_header "$file"
done

echo ""
echo "Done! Verify changes with: git diff"
