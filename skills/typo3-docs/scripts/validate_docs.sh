#!/usr/bin/env bash
#
# Validate TYPO3 documentation RST files
#
# Usage: ./validate_docs.sh [project_root]
#

set -e

PROJECT_ROOT="${1:-.}"
DOC_DIR="$PROJECT_ROOT/Documentation"

if [ ! -d "$DOC_DIR" ]; then
    echo "Error: Documentation/ directory not found at $PROJECT_ROOT"
    echo "Usage: $0 [project_root]"
    exit 1
fi

echo "🔍 Validating TYPO3 documentation..."
echo "   Directory: $DOC_DIR"
echo ""

# Check for RST files
RST_FILES=$(find "$DOC_DIR" -name "*.rst" 2>/dev/null | wc -l)
if [ "$RST_FILES" -eq 0 ]; then
    echo "❌ No RST files found in Documentation/"
    exit 1
fi

echo "Found $RST_FILES RST files"
echo ""

# Check for Settings.cfg
if [ ! -f "$DOC_DIR/Settings.cfg" ]; then
    echo "⚠️  Warning: Settings.cfg not found"
    echo "   This file is required for TYPO3 Intercept builds"
fi

# Check for Index.rst
if [ ! -f "$DOC_DIR/Index.rst" ]; then
    echo "❌ Error: Index.rst not found"
    echo "   This is the main entry point and is required"
    exit 1
fi

echo "✅ Index.rst found"

# Validate RST syntax if rst2html.py is available
if command -v rst2html.py &> /dev/null; then
    echo ""
    echo "Checking RST syntax..."

    ERRORS=0
    while IFS= read -r -d '' file; do
        if ! rst2html.py --strict "$file" > /dev/null 2>&1; then
            echo "❌ Syntax error in: $file"
            ((ERRORS++))
        fi
    done < <(find "$DOC_DIR" -name "*.rst" -print0)

    if [ $ERRORS -eq 0 ]; then
        echo "✅ All RST files have valid syntax"
    else
        echo ""
        echo "❌ Found $ERRORS files with syntax errors"
        exit 1
    fi
else
    echo "⚠️  rst2html.py not found - skipping syntax validation"
    echo "   Install with: pip install docutils"
fi

# Check for common issues
echo ""
echo "Checking for common issues..."

# Check for broken internal references (basic check)
WARNINGS=0

# Check for :ref: without proper labels
while IFS= read -r -d '' file; do
    if grep -q ':ref:`[^<]*`' "$file"; then
        REF_COUNT=$(grep -o ':ref:`[^`]*`' "$file" | wc -l)
        if [ "$REF_COUNT" -gt 0 ]; then
            echo "ℹ️  Found $REF_COUNT :ref: references in $(basename "$file")"
        fi
    fi
done < <(find "$DOC_DIR" -name "*.rst" -print0)

# Check for UTF-8 encoding
while IFS= read -r -d '' file; do
    if ! file -b --mime-encoding "$file" | grep -q utf-8; then
        echo "⚠️  Non-UTF-8 encoding in: $file"
        ((WARNINGS++))
    fi
done < <(find "$DOC_DIR" -name "*.rst" -print0)

# Check for trailing whitespace
while IFS= read -r -d '' file; do
    if grep -q '[[:space:]]$' "$file"; then
        echo "⚠️  Trailing whitespace in: $file"
        ((WARNINGS++))
    fi
done < <(find "$DOC_DIR" -name "*.rst" -print0)

echo ""
if [ $WARNINGS -eq 0 ]; then
    echo "✅ No common issues found"
else
    echo "⚠️  Found $WARNINGS warnings (not blocking)"
fi

echo ""
echo "Validation summary:"
echo "  RST files: $RST_FILES"
echo "  Warnings: $WARNINGS"
echo ""
echo "✅ Documentation validation complete"
echo ""
echo "Next step: Render locally to check for broken references"
echo "   ./render_docs.sh $PROJECT_ROOT"
