#!/usr/bin/env bash

#
# TYPO3 Coding Standards Conformance Checker
#
# Validates PSR-12 compliance and TYPO3-specific code style
#

set -e

PROJECT_DIR="${1:-.}"
cd "${PROJECT_DIR}"

echo "## 2. Coding Standards Conformance"
echo ""

has_issues=0

# Find all PHP files in Classes/
if [ ! -d "Classes" ]; then
    echo "- ❌ Classes/ directory not found"
    echo ""
    echo "---"
    echo ""
    exit 1
fi

php_files=$(find Classes/ -name "*.php" 2>/dev/null || echo "")

if [ -z "$php_files" ]; then
    echo "- ⚠️  No PHP files found in Classes/"
    echo ""
    echo "---"
    echo ""
    exit 0
fi

total_files=$(echo "$php_files" | wc -l)
echo "**Total PHP files:** $total_files"
echo ""

### Check for strict types
echo "### Strict Types Declaration"
echo ""
missing_strict=0
for file in $php_files; do
    if ! grep -q "declare(strict_types=1)" "$file"; then
        missing_strict=$((missing_strict + 1))
    fi
done

if [ $missing_strict -eq 0 ]; then
    echo "- ✅ All files have declare(strict_types=1)"
else
    echo "- ❌ ${missing_strict} files missing declare(strict_types=1)"
    has_issues=1
fi

### Check for old array syntax
echo ""
echo "### Array Syntax"
echo ""
old_array_count=$(grep -r "array(" Classes/ 2>/dev/null | wc -l)
if [ $old_array_count -eq 0 ]; then
    echo "- ✅ No old array() syntax found"
else
    echo "- ❌ ${old_array_count} instances of old array() syntax (should use [])"
    has_issues=1
fi

### Check for proper namespace
echo ""
echo "### Namespace Structure"
echo ""
files_without_namespace=0
for file in $php_files; do
    if ! grep -q "^namespace " "$file"; then
        files_without_namespace=$((files_without_namespace + 1))
    fi
done

if [ $files_without_namespace -eq 0 ]; then
    echo "- ✅ All files have namespace declaration"
else
    echo "- ❌ ${files_without_namespace} files missing namespace declaration"
    has_issues=1
fi

### Check for PHPDoc comments on classes
echo ""
echo "### PHPDoc Comments"
echo ""
classes_without_doc=0
for file in $php_files; do
    # Simple check: look for /** before class declaration
    if grep -q "^class " "$file" || grep -q "^final class " "$file"; then
        if ! grep -B 5 "^class \|^final class " "$file" | grep -q "/\*\*"; then
            classes_without_doc=$((classes_without_doc + 1))
        fi
    fi
done

if [ $classes_without_doc -eq 0 ]; then
    echo "- ✅ All classes have PHPDoc comments"
else
    echo "- ⚠️  ${classes_without_doc} classes missing PHPDoc comments"
fi

### Check naming conventions
echo ""
echo "### Naming Conventions"
echo ""

# Check for snake_case in class names (should be UpperCamelCase)
snake_case_classes=$(grep -rE "^(final )?class [a-z][a-z0-9_]*" Classes/ 2>/dev/null | wc -l)
if [ $snake_case_classes -gt 0 ]; then
    echo "- ❌ ${snake_case_classes} classes using incorrect naming (should be UpperCamelCase)"
    has_issues=1
else
    echo "- ✅ Class naming follows UpperCamelCase convention"
fi

### Check for tabs instead of spaces
echo ""
echo "### Indentation"
echo ""
files_with_tabs=0
for file in $php_files; do
    if grep -qP "\t" "$file"; then
        files_with_tabs=$((files_with_tabs + 1))
    fi
done

if [ $files_with_tabs -eq 0 ]; then
    echo "- ✅ No tabs found (using spaces for indentation)"
else
    echo "- ❌ ${files_with_tabs} files using tabs instead of spaces"
    has_issues=1
fi

### Check for proper use statements
echo ""
echo "### Use Statements"
echo ""

# Check if use statements are present and not duplicated
duplicate_uses=$(grep -rh "^use " Classes/ 2>/dev/null | sort | uniq -d | wc -l)
if [ $duplicate_uses -gt 0 ]; then
    echo "- ⚠️  ${duplicate_uses} duplicate use statements found"
else
    echo "- ✅ No duplicate use statements"
fi

echo ""
echo "### Summary"
echo ""

if [ $has_issues -eq 0 ]; then
    echo "- ✅ **Coding standards: PASSED**"
else
    echo "- ⚠️  **Coding standards: ISSUES FOUND**"
fi

echo ""
echo "---"
echo ""

exit $has_issues
