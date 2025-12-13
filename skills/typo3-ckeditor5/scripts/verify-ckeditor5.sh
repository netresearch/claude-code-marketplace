#!/bin/bash
# CKEditor 5 TYPO3 Integration Verification Script
# Verifies CKEditor 5 plugin structure and configuration

set -e

EXTENSION_DIR="${1:-.}"
ERRORS=0
WARNINGS=0

echo "=== CKEditor 5 TYPO3 Integration Verification ==="
echo "Extension: $EXTENSION_DIR"
echo ""

# Check for RTE configuration
echo "=== Checking RTE Configuration ==="
if [[ -d "$EXTENSION_DIR/Configuration/RTE" ]]; then
    YAML_FILES=$(find "$EXTENSION_DIR/Configuration/RTE" -name "*.yaml" 2>/dev/null | wc -l)
    if [[ $YAML_FILES -gt 0 ]]; then
        echo "✅ Found $YAML_FILES RTE YAML configuration file(s)"

        # Check YAML structure
        for yaml in "$EXTENSION_DIR/Configuration/RTE"/*.yaml; do
            if [[ -f "$yaml" ]]; then
                echo "   Checking: $(basename "$yaml")"

                # Check for required sections
                if grep -q "^editor:" "$yaml" 2>/dev/null; then
                    echo "   ✅ Has 'editor' configuration"
                else
                    echo "   ⚠️  Missing 'editor' section"
                    ((WARNINGS++))
                fi

                if grep -q "^processing:" "$yaml" 2>/dev/null; then
                    echo "   ✅ Has 'processing' configuration"
                else
                    echo "   ⚠️  Missing 'processing' section (HTML sanitization)"
                    ((WARNINGS++))
                fi

                # Check for toolbar configuration
                if grep -q "toolbar:" "$yaml" 2>/dev/null; then
                    echo "   ✅ Has toolbar configuration"
                else
                    echo "   ⚠️  Missing toolbar configuration"
                    ((WARNINGS++))
                fi

                # Check for importModules
                if grep -q "importModules:" "$yaml" 2>/dev/null; then
                    echo "   ✅ Has module imports configured"
                fi
            fi
        done
    else
        echo "⚠️  No YAML configuration files found in Configuration/RTE/"
        ((WARNINGS++))
    fi
else
    echo "⚠️  No Configuration/RTE directory found"
    ((WARNINGS++))
fi

# Check for CKEditor JavaScript plugins
echo ""
echo "=== Checking CKEditor 5 Plugins ==="
JS_DIRS=("Resources/Public/JavaScript/Ckeditor" "Resources/Public/JavaScript/CKEditor" "Resources/Public/JavaScript/ckeditor")

FOUND_JS_DIR=""
for dir in "${JS_DIRS[@]}"; do
    if [[ -d "$EXTENSION_DIR/$dir" ]]; then
        FOUND_JS_DIR="$EXTENSION_DIR/$dir"
        break
    fi
done

if [[ -n "$FOUND_JS_DIR" ]]; then
    echo "✅ Found CKEditor JavaScript directory: $FOUND_JS_DIR"

    JS_FILES=$(find "$FOUND_JS_DIR" -name "*.js" 2>/dev/null | wc -l)
    if [[ $JS_FILES -gt 0 ]]; then
        echo "✅ Found $JS_FILES JavaScript file(s)"

        # Check for ES module patterns
        for jsfile in $(find "$FOUND_JS_DIR" -name "*.js" 2>/dev/null); do
            filename=$(basename "$jsfile")
            echo "   Checking: $filename"

            # Check for ES module imports
            if grep -q "import.*from" "$jsfile" 2>/dev/null; then
                echo "   ✅ Uses ES module imports"
            else
                echo "   ⚠️  No ES module imports found"
                ((WARNINGS++))
            fi

            # Check for Plugin class pattern
            if grep -q "extends Plugin" "$jsfile" 2>/dev/null; then
                echo "   ✅ Uses CKEditor 5 Plugin class"
            fi

            # Check for Command pattern
            if grep -q "extends Command" "$jsfile" 2>/dev/null; then
                echo "   ✅ Uses CKEditor 5 Command class"
            fi

            # Check for export
            if grep -q "export" "$jsfile" 2>/dev/null; then
                echo "   ✅ Has exports"
            else
                echo "   ⚠️  No exports found - may not be loadable"
                ((WARNINGS++))
            fi
        done
    else
        echo "⚠️  No JavaScript files found"
        ((WARNINGS++))
    fi
else
    echo "ℹ️  No CKEditor JavaScript directory found (optional)"
fi

# Check for CSS stylesheets
echo ""
echo "=== Checking CKEditor 5 Stylesheets ==="
CSS_DIRS=("Resources/Public/Css/Ckeditor" "Resources/Public/Css/CKEditor" "Resources/Public/Css/ckeditor")

FOUND_CSS_DIR=""
for dir in "${CSS_DIRS[@]}"; do
    if [[ -d "$EXTENSION_DIR/$dir" ]]; then
        FOUND_CSS_DIR="$EXTENSION_DIR/$dir"
        break
    fi
done

if [[ -n "$FOUND_CSS_DIR" ]]; then
    echo "✅ Found CKEditor CSS directory: $FOUND_CSS_DIR"
    CSS_FILES=$(find "$FOUND_CSS_DIR" -name "*.css" 2>/dev/null | wc -l)
    echo "✅ Found $CSS_FILES CSS file(s)"
else
    echo "ℹ️  No CKEditor CSS directory found (optional)"
fi

# Check ext_localconf.php for plugin registration
echo ""
echo "=== Checking Plugin Registration ==="
if [[ -f "$EXTENSION_DIR/ext_localconf.php" ]]; then
    # Check for RTE preset registration
    if grep -q "RTE.*Presets" "$EXTENSION_DIR/ext_localconf.php" 2>/dev/null; then
        echo "✅ RTE preset registration found"
    else
        echo "ℹ️  No RTE preset registration in ext_localconf.php"
    fi

    # Check for CKEditor 5 plugin registration
    if grep -q "CKEditor5.*plugins" "$EXTENSION_DIR/ext_localconf.php" 2>/dev/null; then
        echo "✅ CKEditor 5 plugin registration found"
    else
        echo "ℹ️  No CKEditor 5 plugin registration in ext_localconf.php"
    fi
else
    echo "⚠️  No ext_localconf.php found"
    ((WARNINGS++))
fi

# Check for TCA with RTE configuration
echo ""
echo "=== Checking TCA RTE Configuration ==="
if [[ -d "$EXTENSION_DIR/Configuration/TCA" ]]; then
    RTE_TCA=$(grep -rl "enableRichtext" "$EXTENSION_DIR/Configuration/TCA" 2>/dev/null | wc -l)
    if [[ $RTE_TCA -gt 0 ]]; then
        echo "✅ Found $RTE_TCA TCA file(s) with RTE configuration"

        # Check for richtextConfiguration
        PRESET_CONFIG=$(grep -rl "richtextConfiguration" "$EXTENSION_DIR/Configuration/TCA" 2>/dev/null | wc -l)
        if [[ $PRESET_CONFIG -gt 0 ]]; then
            echo "✅ Custom RTE preset assignments found"
        fi
    else
        echo "ℹ️  No TCA files with RTE configuration found"
    fi
else
    echo "ℹ️  No TCA directory found"
fi

# Check for CKEditor 4 remnants (migration check)
echo ""
echo "=== Migration Check (CKEditor 4 Remnants) ==="
CKE4_PATTERNS=0

# Check for old widget patterns in JS
if [[ -n "$FOUND_JS_DIR" ]]; then
    OLD_PATTERNS=$(grep -rl "CKEDITOR\." "$FOUND_JS_DIR" 2>/dev/null | wc -l)
    if [[ $OLD_PATTERNS -gt 0 ]]; then
        echo "⚠️  Found CKEditor 4 global namespace usage in $OLD_PATTERNS file(s)"
        ((WARNINGS++))
        ((CKE4_PATTERNS++))
    fi
fi

# Check for old configuration patterns
if [[ -d "$EXTENSION_DIR/Configuration/RTE" ]]; then
    OLD_YAML=$(grep -rl "extraPlugins\|removePlugins\|allowedContent" "$EXTENSION_DIR/Configuration/RTE" 2>/dev/null | wc -l)
    if [[ $OLD_YAML -gt 0 ]]; then
        echo "⚠️  Found CKEditor 4 configuration patterns in YAML"
        ((WARNINGS++))
        ((CKE4_PATTERNS++))
    fi
fi

# Check for old PageTSConfig patterns
if [[ -d "$EXTENSION_DIR/Configuration/TsConfig" ]] || [[ -d "$EXTENSION_DIR/Configuration/TSconfig" ]]; then
    OLD_TS=$(grep -rl "RTE.default.proc\|RTE.default.buttons" "$EXTENSION_DIR/Configuration" 2>/dev/null | wc -l)
    if [[ $OLD_TS -gt 0 ]]; then
        echo "⚠️  Found CKEditor 4 PageTSConfig patterns"
        ((WARNINGS++))
        ((CKE4_PATTERNS++))
    fi
fi

if [[ $CKE4_PATTERNS -eq 0 ]]; then
    echo "✅ No CKEditor 4 patterns detected"
fi

# Check processing configuration
echo ""
echo "=== Processing Configuration Check ==="
if [[ -d "$EXTENSION_DIR/Configuration/RTE" ]]; then
    for yaml in "$EXTENSION_DIR/Configuration/RTE"/*.yaml; do
        if [[ -f "$yaml" ]]; then
            # Check for allowTags
            if grep -q "allowTags:" "$yaml" 2>/dev/null; then
                echo "✅ $(basename "$yaml"): Has allowTags configuration"
            fi

            # Check for allowAttributes
            if grep -q "allowAttributes:" "$yaml" 2>/dev/null; then
                echo "✅ $(basename "$yaml"): Has allowAttributes configuration"
            fi

            # Check for dangerous tags not denied
            if grep -q "script\|iframe\|object" "$yaml" 2>/dev/null; then
                # Check if they're in denyTags
                if grep -q "denyTags:" "$yaml" 2>/dev/null; then
                    echo "✅ $(basename "$yaml"): Has denyTags configuration"
                else
                    echo "⚠️  $(basename "$yaml"): May allow dangerous tags without denyTags"
                    ((WARNINGS++))
                fi
            fi
        fi
    done
fi

# Check for documentation
echo ""
echo "=== Documentation Check ==="
if [[ -f "$EXTENSION_DIR/README.md" ]] || [[ -f "$EXTENSION_DIR/Documentation/Index.rst" ]]; then
    echo "✅ Documentation found"
else
    echo "⚠️  No README.md or Documentation/Index.rst found"
    ((WARNINGS++))
fi

# Summary
echo ""
echo "=== Summary ==="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [[ $ERRORS -gt 0 ]]; then
    echo "❌ Verification FAILED"
    exit 1
elif [[ $WARNINGS -gt 3 ]]; then
    echo "⚠️  Verification completed with significant warnings"
    exit 0
else
    echo "✅ Verification PASSED"
    exit 0
fi
