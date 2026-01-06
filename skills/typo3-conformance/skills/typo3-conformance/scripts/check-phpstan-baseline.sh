#!/usr/bin/env bash

# TYPO3 Extension Conformance Checker - PHPStan Baseline Validation
# Verifies that new code does not add errors to phpstan-baseline.neon
#
# Usage:
#   ./check-phpstan-baseline.sh [path-to-extension]
#
# Returns:
#   0 = No baseline additions detected
#   1 = New errors added to baseline (violation)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT" || exit 1

echo "Checking PHPStan baseline hygiene in: $PROJECT_ROOT"
echo

# Check if git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}⚠️  Not a git repository - skipping baseline check${NC}"
    exit 0
fi

# Find baseline file
BASELINE_FILE=""
for path in "Build/phpstan-baseline.neon" "phpstan-baseline.neon" ".phpstan/baseline.neon"; do
    if [ -f "$path" ]; then
        BASELINE_FILE="$path"
        break
    fi
done

if [ -z "$BASELINE_FILE" ]; then
    echo -e "${GREEN}✅ No baseline file found - all code passes PHPStan level 10!${NC}"
    exit 0
fi

echo "Found baseline file: $BASELINE_FILE"
echo

# Check if baseline is modified in current changes
if ! git diff --quiet "$BASELINE_FILE" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Baseline file has uncommitted changes${NC}"
    echo

    # Extract error counts from diff
    BEFORE_COUNT=$(git show "HEAD:$BASELINE_FILE" 2>/dev/null | grep -E "^\s+count:\s+[0-9]+" | head -1 | grep -oE "[0-9]+" || echo "0")
    AFTER_COUNT=$(grep -E "^\s+count:\s+[0-9]+" "$BASELINE_FILE" | head -1 | grep -oE "[0-9]+" || echo "0")

    if [ "$AFTER_COUNT" -gt "$BEFORE_COUNT" ]; then
        ADDED=$((AFTER_COUNT - BEFORE_COUNT))
        echo -e "${RED}❌ BASELINE VIOLATION DETECTED${NC}"
        echo
        echo "Error count increased: $BEFORE_COUNT → $AFTER_COUNT (+$ADDED errors)"
        echo
        echo "New code added $ADDED errors to the baseline!"
        echo
        echo "The baseline exists only for legacy code."
        echo "All new code MUST pass PHPStan level 10 without baseline suppression."
        echo
        echo -e "${YELLOW}How to fix:${NC}"
        echo "1. Run: composer ci:php:stan"
        echo "2. Review the new errors reported"
        echo "3. Fix the underlying issues (see coding-guidelines.md for patterns)"
        echo "4. Revert baseline changes: git checkout $BASELINE_FILE"
        echo "5. Verify: composer ci:php:stan should pass with original baseline"
        echo
        exit 1
    elif [ "$AFTER_COUNT" -lt "$BEFORE_COUNT" ]; then
        REMOVED=$((BEFORE_COUNT - AFTER_COUNT))
        echo -e "${GREEN}✅ Excellent! Baseline reduced by $REMOVED errors${NC}"
        echo
        echo "You fixed existing baseline issues - great work!"
        echo
    else
        echo -e "${YELLOW}⚠️  Baseline modified but count unchanged${NC}"
        echo
        echo "Review the baseline diff to ensure changes are intentional:"
        echo "  git diff $BASELINE_FILE"
        echo
    fi
else
    echo -e "${GREEN}✅ No changes to baseline file${NC}"
fi

# Check for baseline in staged changes
if git diff --cached --quiet "$BASELINE_FILE" 2>/dev/null; then
    echo -e "${GREEN}✅ No baseline changes staged for commit${NC}"
else
    echo
    echo -e "${YELLOW}⚠️  Warning: Baseline file is staged for commit${NC}"
    echo
    echo "Review staged baseline changes:"
    echo "  git diff --cached $BASELINE_FILE"
    echo
fi

echo
echo -e "${GREEN}✅ PHPStan baseline hygiene check passed${NC}"
exit 0
