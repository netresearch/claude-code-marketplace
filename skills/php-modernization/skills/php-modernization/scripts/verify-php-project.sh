#!/bin/bash
# PHP Project Modernization Verification Script
# Checks PHP version compatibility, type safety, and code quality

set -e

PROJECT_DIR="${1:-.}"
ERRORS=0
WARNINGS=0

echo "=== PHP Modernization Verification ==="
echo "Directory: $PROJECT_DIR"
echo ""

# Check composer.json exists
if [[ -f "$PROJECT_DIR/composer.json" ]]; then
    echo "✅ composer.json found"

    # Check PHP version requirement
    PHP_REQ=$(grep -o '"php"[^,]*' "$PROJECT_DIR/composer.json" | head -1 || true)
    if [[ -n "$PHP_REQ" ]]; then
        echo "   PHP requirement: $PHP_REQ"
        if [[ "$PHP_REQ" == *"7."* ]]; then
            echo "⚠️  PHP 7.x detected - consider upgrading to PHP 8.x"
            ((WARNINGS++))
        fi
    fi
else
    echo "❌ composer.json not found"
    ((ERRORS++))
fi

# Check for strict types declaration
echo ""
echo "=== Strict Types Usage ==="
if [[ -d "$PROJECT_DIR/src" ]]; then
    TOTAL_PHP=$(find "$PROJECT_DIR/src" -name "*.php" 2>/dev/null | wc -l)
    STRICT_PHP=$(grep -l "declare(strict_types=1)" "$PROJECT_DIR/src"/**/*.php 2>/dev/null | wc -l || echo "0")

    echo "Files with strict_types: $STRICT_PHP / $TOTAL_PHP"

    if [[ "$STRICT_PHP" -lt "$TOTAL_PHP" ]]; then
        MISSING=$((TOTAL_PHP - STRICT_PHP))
        echo "⚠️  $MISSING files missing declare(strict_types=1)"
        ((WARNINGS++))
    else
        echo "✅ All PHP files have strict_types enabled"
    fi
else
    echo "⚠️  No src/ directory found"
    ((WARNINGS++))
fi

# Check for type hints
echo ""
echo "=== Type Declaration Coverage ==="
if [[ -d "$PROJECT_DIR/src" ]]; then
    # Check for functions without return types
    NO_RETURN=$(grep -r "function [a-zA-Z_]*(" "$PROJECT_DIR/src" --include="*.php" | grep -v "): " | wc -l || echo "0")
    if [[ "$NO_RETURN" -gt 0 ]]; then
        echo "⚠️  ~$NO_RETURN functions may be missing return type declarations"
        ((WARNINGS++))
    else
        echo "✅ Functions appear to have return types"
    fi
fi

# Check for PHPStan configuration
echo ""
echo "=== Static Analysis ==="
if [[ -f "$PROJECT_DIR/phpstan.neon" ]] || [[ -f "$PROJECT_DIR/phpstan.neon.dist" ]]; then
    echo "✅ PHPStan configuration found"

    LEVEL=$(grep -o "level: [0-9]*" "$PROJECT_DIR/phpstan.neon"* 2>/dev/null | head -1 | grep -o "[0-9]*" || echo "unknown")
    echo "   Level: $LEVEL"

    if [[ "$LEVEL" != "unknown" ]] && [[ "$LEVEL" -lt 6 ]]; then
        echo "⚠️  Consider increasing PHPStan level (current: $LEVEL, recommended: 8+)"
        ((WARNINGS++))
    fi
else
    echo "⚠️  No PHPStan configuration found"
    ((WARNINGS++))
fi

# Check for Rector configuration
if [[ -f "$PROJECT_DIR/rector.php" ]]; then
    echo "✅ Rector configuration found"
else
    echo "⚠️  No Rector configuration found (recommended for automated upgrades)"
    ((WARNINGS++))
fi

# Check for deprecated patterns
echo ""
echo "=== Deprecated Patterns ==="
if [[ -d "$PROJECT_DIR/src" ]]; then
    # Check for old array syntax
    OLD_ARRAY=$(grep -r "array(" "$PROJECT_DIR/src" --include="*.php" | wc -l || echo "0")
    if [[ "$OLD_ARRAY" -gt 0 ]]; then
        echo "⚠️  Found ~$OLD_ARRAY uses of array() syntax (prefer [])"
        ((WARNINGS++))
    fi

    # Check for annotations (should use attributes in PHP 8+)
    ANNOTATIONS=$(grep -r "@ORM\\\\" "$PROJECT_DIR/src" --include="*.php" | wc -l || echo "0")
    if [[ "$ANNOTATIONS" -gt 0 ]]; then
        echo "⚠️  Found ~$ANNOTATIONS Doctrine annotations (consider attributes)"
        ((WARNINGS++))
    fi
fi

# Check for tests
echo ""
echo "=== Test Coverage ==="
if [[ -d "$PROJECT_DIR/tests" ]]; then
    TEST_FILES=$(find "$PROJECT_DIR/tests" -name "*Test.php" 2>/dev/null | wc -l)
    echo "✅ Found $TEST_FILES test files"
else
    echo "⚠️  No tests/ directory found"
    ((WARNINGS++))
fi

# Run PHPStan if available
echo ""
echo "=== Running PHPStan ==="
if command -v vendor/bin/phpstan &> /dev/null; then
    cd "$PROJECT_DIR"
    if vendor/bin/phpstan analyse --no-progress --error-format=raw 2>&1 | head -20; then
        echo "✅ PHPStan completed"
    else
        echo "⚠️  PHPStan found issues"
        ((WARNINGS++))
    fi
elif [[ -f "$PROJECT_DIR/vendor/bin/phpstan" ]]; then
    cd "$PROJECT_DIR"
    if ./vendor/bin/phpstan analyse --no-progress 2>&1 | head -20; then
        echo "✅ PHPStan completed"
    fi
else
    echo "⚠️  PHPStan not installed"
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
elif [[ $WARNINGS -gt 5 ]]; then
    echo "⚠️  Verification PASSED with significant warnings"
    exit 0
else
    echo "✅ Verification PASSED"
    exit 0
fi
