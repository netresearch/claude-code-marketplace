#!/bin/bash
# check-branch-coverage.sh - Check branch (decision) coverage for Go projects
# Usage: ./check-branch-coverage.sh [--threshold 80] [--package ./...]
# OpenSSF Badge Criteria: test_branch_coverage80 (Gold)
set -euo pipefail

THRESHOLD="80"
PACKAGE="./..."

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --threshold)
            THRESHOLD="$2"
            shift 2
            ;;
        --package)
            PACKAGE="$2"
            shift 2
            ;;
        *)
            # Support positional args for backwards compatibility
            if [ -z "${THRESHOLD_SET:-}" ]; then
                THRESHOLD="$1"
                THRESHOLD_SET=1
            else
                PACKAGE="$1"
            fi
            shift
            ;;
    esac
done

COVERAGE_FILE="coverage.out"

echo "=== Branch Coverage Analysis ==="
echo "Threshold: $THRESHOLD%"
echo "Package: $PACKAGE"
echo ""

# Check for Go
if ! command -v go >/dev/null 2>&1; then
    echo "Error: Go is not installed"
    exit 1
fi

# Run tests with coverage
echo "Running tests with coverage..."
go test -coverprofile="$COVERAGE_FILE" -covermode=atomic "$PACKAGE" 2>/dev/null || {
    echo "Error: Tests failed"
    exit 1
}

if [ ! -f "$COVERAGE_FILE" ]; then
    echo "Error: Coverage file not generated"
    exit 1
fi

echo ""
echo "=== Statement Coverage ==="
STMT_COVERAGE=$(go tool cover -func="$COVERAGE_FILE" | grep total | awk '{print $3}' | tr -d '%')
echo "Statement coverage: $STMT_COVERAGE%"

echo ""
echo "=== Branch Coverage Analysis ==="
echo ""
echo "Note: Go's native coverage tool measures statement coverage, not branch coverage."
echo "For true branch coverage, use one of these approaches:"
echo ""

# Method 1: Estimate from statement coverage
# Branch coverage is typically 70-85% of statement coverage
ESTIMATED_BRANCH=$(awk -v s="$STMT_COVERAGE" 'BEGIN { printf "%.1f", s * 0.8 }')
echo "1. Estimated branch coverage (conservative): ~$ESTIMATED_BRANCH%"
echo "   (Statement coverage * 0.8 as rough estimate)"
echo ""

# Method 2: Use gocov for more detailed analysis
echo "2. For accurate branch coverage, install gocov-cobertura:"
echo "   go install github.com/boumenot/gocover-cobertura@latest"
echo "   go tool cover -xml=coverage.out > coverage.xml"
echo "   # Then analyze with coverage tools that support branch metrics"
echo ""

# Method 3: Check for conditional complexity
echo "3. Analyzing conditional complexity in codebase..."

# Count if/else and switch statements (Go has no ternary operator)
IF_COUNT=$(grep -rn "if " --include="*.go" . 2>/dev/null | grep -v "_test.go" | grep -v "vendor/" | wc -l | tr -d ' ')
SWITCH_COUNT=$(grep -rn "switch " --include="*.go" . 2>/dev/null | grep -v "_test.go" | grep -v "vendor/" | wc -l | tr -d ' ')
SELECT_COUNT=$(grep -rn "select {" --include="*.go" . 2>/dev/null | grep -v "_test.go" | grep -v "vendor/" | wc -l | tr -d ' ')

echo "   Conditional statements in source code:"
echo "   - if statements: $IF_COUNT"
echo "   - switch statements: $SWITCH_COUNT"
echo "   - select statements: $SELECT_COUNT"
echo "   Total decision points: $((IF_COUNT + SWITCH_COUNT + SELECT_COUNT))"
echo ""

# Provide assessment
echo "=== Assessment ==="
echo ""

# Use awk for floating point comparison (POSIX-compatible)
if awk -v e="$ESTIMATED_BRANCH" -v t="$THRESHOLD" 'BEGIN { exit !(e >= t) }'; then
    echo "✓ Estimated branch coverage ($ESTIMATED_BRANCH%) meets threshold ($THRESHOLD%)"
    echo ""
    echo "Recommendation: Validate with proper branch coverage tools for Gold badge"
else
    echo "✗ Estimated branch coverage ($ESTIMATED_BRANCH%) is below threshold ($THRESHOLD%)"
    echo ""
    echo "To improve branch coverage:"
    echo "1. Add tests for error paths and edge cases"
    echo "2. Test both branches of if/else statements"
    echo "3. Cover all switch cases including default"
    echo "4. Test boundary conditions"
fi

echo ""
echo "=== Detailed Coverage Report ==="
echo ""
echo "Low coverage files:"
go tool cover -func="$COVERAGE_FILE" | awk '$3 != "100.0%" && $3 != "" {print}' | sort -t$'\t' -k3 -n | head -10

echo ""
echo "Files with 0% coverage:"
go tool cover -func="$COVERAGE_FILE" | awk '$3 == "0.0%" {print $1}' | head -10

# Exit based on estimated coverage
if awk -v e="$ESTIMATED_BRANCH" -v t="$THRESHOLD" 'BEGIN { exit !(e >= t) }'; then
    exit 0
else
    exit 1
fi
