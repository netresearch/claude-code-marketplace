#!/bin/bash
# analyze-bus-factor.sh - Analyze commit distribution for bus factor assessment
# Usage: ./analyze-bus-factor.sh [--days 365] [--threshold 2]
# OpenSSF Badge Criteria: bus_factor (Silver/Gold)
set -euo pipefail

DAYS="${1:-365}"
THRESHOLD="${2:-2}"

echo "=== Bus Factor Analysis ==="
echo "Period: Last $DAYS days"
echo "Target: Bus factor >= $THRESHOLD"
echo ""

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not a git repository"
    exit 1
fi

# Get commit counts by author
echo "=== Commit Distribution ==="
echo ""
echo "Author                                    Commits    %"
echo "----------------------------------------  --------  ----"

# Calculate total commits first
TOTAL_COMMITS=$(git log --since="$DAYS days ago" --format="%ae" 2>/dev/null | wc -l | tr -d ' ')

if [ "$TOTAL_COMMITS" -eq 0 ]; then
    echo "No commits found in the last $DAYS days"
    echo ""
    echo "Bus Factor: 0 (no activity)"
    exit 1
fi

# Get unique authors with commit counts, sorted by count descending
git log --since="$DAYS days ago" --format="%aN <%aE>" 2>/dev/null | \
    sort | uniq -c | sort -rn | head -20 | while read -r count author; do
    # Calculate percentage using awk (POSIX-compatible, no bc dependency)
    PCT=$(awk -v c="$count" -v t="$TOTAL_COMMITS" 'BEGIN { printf "%.1f", (c/t)*100 }')
    printf "%-40s  %8d  %4s%%\n" "$author" "$count" "$PCT"
done

echo ""
echo "Total commits: $TOTAL_COMMITS"
echo ""

# Calculate bus factor
# Bus factor = number of authors needed to cover 50% of commits
echo "=== Bus Factor Calculation ==="
echo ""

CUMULATIVE=0
BUS_FACTOR=0
HALF_COMMITS=$((TOTAL_COMMITS / 2))
RESULT=""

# Process authors in order of commit count
# Use process substitution to keep loop in main shell (fixes subshell exit issue)
while read -r count author; do
    CUMULATIVE=$((CUMULATIVE + count))
    BUS_FACTOR=$((BUS_FACTOR + 1))

    if [ "$CUMULATIVE" -ge "$HALF_COMMITS" ]; then
        RESULT="found"
        echo "Authors needed for 50% of commits: $BUS_FACTOR"

        if [ "$BUS_FACTOR" -ge "$THRESHOLD" ]; then
            echo ""
            echo "✓ Bus factor ($BUS_FACTOR) meets threshold ($THRESHOLD)"
            exit 0
        else
            echo ""
            echo "✗ Bus factor ($BUS_FACTOR) below threshold ($THRESHOLD)"
            echo ""
            echo "Recommendations:"
            echo "1. Recruit additional maintainers"
            echo "2. Document critical code paths for knowledge transfer"
            echo "3. Pair programming to spread knowledge"
            exit 1
        fi
    fi
done < <(git log --since="$DAYS days ago" --format="%aN" 2>/dev/null | sort | uniq -c | sort -rn)

# If we get here with only one author or no commits matched threshold
if [ -z "$RESULT" ]; then
    echo ""
    echo "✗ Single maintainer project - bus factor = 1"
    echo ""
    echo "Recommendations for solo maintainers:"
    echo "1. Document architecture and decision rationale"
    echo "2. Create comprehensive onboarding documentation"
    echo "3. Consider recruiting co-maintainers"
    echo "4. Mark bus_factor as N/A with justification in badge application"
    exit 1
fi
