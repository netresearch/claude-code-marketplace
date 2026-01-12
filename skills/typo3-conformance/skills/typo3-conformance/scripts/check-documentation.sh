#!/usr/bin/env bash

#
# TYPO3 Documentation Structure Checker
#
# Validates basic documentation file structure.
# For comprehensive RST validation, Claude should invoke the typo3-docs skill.
#

set -e

PROJECT_DIR="${1:-.}"
cd "${PROJECT_DIR}"

echo "## Documentation Structure"
echo ""
echo "> Note: For comprehensive RST validation, use the typo3-docs skill"
echo ""

echo "### Required Files"
echo ""

# Check Documentation directory exists
if [ ! -d "Documentation" ]; then
    echo "- ❌ Documentation/ directory missing"
    echo ""
    exit 1
fi

# Check Documentation/Index.rst (required entry point)
if [ -f "Documentation/Index.rst" ]; then
    echo "- ✅ Documentation/Index.rst present"
elif [ -f "Documentation/Index.md" ]; then
    echo "- ✅ Documentation/Index.md present (Markdown mode)"
else
    echo "- ❌ No documentation entry point (need Index.rst or Index.md)"
fi

# Check guides.xml (modern) vs Settings.cfg (legacy)
if [ -f "Documentation/guides.xml" ]; then
    echo "- ✅ Documentation/guides.xml present (modern)"
elif [ -f "Documentation/Settings.cfg" ]; then
    echo "- ⚠️  Documentation/Settings.cfg present (legacy - migrate to guides.xml)"
else
    echo "- ❌ No documentation config (need guides.xml)"
fi

echo ""
echo "### Structure"
echo ""

# Check for Index.rst in subdirectories
if [ -d "Documentation" ]; then
    missing_index=()
    for dir in Documentation/*/; do
        if [ -d "$dir" ]; then
            dirname=$(basename "$dir")
            # Skip special directories
            if [[ "$dirname" == _* ]] || [[ "$dirname" == "Images" ]]; then
                continue
            fi
            if [ ! -f "${dir}Index.rst" ] && [ ! -f "${dir}Index.md" ]; then
                missing_index+=("$dirname")
            fi
        fi
    done

    if [ ${#missing_index[@]} -eq 0 ]; then
        echo "- ✅ All subdirectories have Index.rst"
    else
        echo "- ⚠️  Missing Index.rst in: ${missing_index[*]}"
    fi
fi

# Check for Images directory
if [ -d "Documentation/Images" ]; then
    img_count=$(find "Documentation/Images" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.gif" -o -name "*.svg" \) 2>/dev/null | wc -l)
    if [ "$img_count" -gt 0 ]; then
        echo "- ✅ Documentation/Images/ ($img_count image(s))"
    else
        echo "- ⚠️  Documentation/Images/ exists but empty"
    fi
else
    echo "- ℹ️  No Documentation/Images/ (optional)"
fi

# Check for .editorconfig
if [ -f "Documentation/.editorconfig" ]; then
    echo "- ✅ Documentation/.editorconfig present"
fi

echo ""
echo "---"
echo ""

exit 0
