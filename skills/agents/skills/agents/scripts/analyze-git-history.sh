#!/usr/bin/env bash
# Analyze git history for patterns (commit conventions, branching, releases)
set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo '{"error": "Not a git repository"}'
    exit 0
fi

SAMPLE_SIZE=100

# Helper to count grep matches (returns 0 if no matches instead of error)
count_matches() {
    local pattern="$1"
    local input="$2"
    local flags="${3:-}"
    local count
    count=$(echo "$input" | grep $flags -cE "$pattern" 2>/dev/null) || count=0
    echo "$count"
}

# Analyze commit message conventions
analyze_commit_convention() {
    local commits
    commits=$(git log --oneline -"$SAMPLE_SIZE" --pretty=format:"%s" 2>/dev/null || echo "")

    if [ -z "$commits" ]; then
        echo '{"convention": "unknown", "confidence": 0}'
        return
    fi

    local total_commits
    total_commits=$(echo "$commits" | wc -l)

    # Count conventional commits (feat:, fix:, docs:, style:, refactor:, test:, chore:, etc.)
    local conventional_count
    conventional_count=$(count_matches '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?(!)?:' "$commits")

    # Count [TAG] style commits
    local tag_count
    tag_count=$(count_matches '^\[.+\]' "$commits")

    # Count ticket reference commits (JIRA-123, #123, etc.)
    local ticket_count
    ticket_count=$(count_matches '([A-Z]+-[0-9]+|#[0-9]+)' "$commits" "-i")

    # Count emoji commits
    local emoji_count
    emoji_count=$(count_matches '^(✨|🐛|📝|🎨|♻️|🚀|✅|🔧|⬆️|🔒)' "$commits")

    # Determine convention
    local convention="freeform"
    local confidence=0

    local conventional_pct=$((conventional_count * 100 / total_commits))
    local tag_pct=$((tag_count * 100 / total_commits))
    local ticket_pct=$((ticket_count * 100 / total_commits))
    local emoji_pct=$((emoji_count * 100 / total_commits))

    if [ "$conventional_pct" -ge 50 ]; then
        convention="conventional-commits"
        confidence=$conventional_pct
    elif [ "$tag_pct" -ge 50 ]; then
        convention="tag-prefix"
        confidence=$tag_pct
    elif [ "$emoji_pct" -ge 30 ]; then
        convention="emoji"
        confidence=$emoji_pct
    elif [ "$ticket_pct" -ge 50 ]; then
        convention="ticket-reference"
        confidence=$ticket_pct
    fi

    # Extract common prefixes
    local prefixes=()
    if [ "$convention" = "conventional-commits" ]; then
        mapfile -t prefixes < <(echo "$commits" | grep -oE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)' | sort | uniq -c | sort -rn | head -5 | awk '{print $2}')
    elif [ "$convention" = "tag-prefix" ]; then
        mapfile -t prefixes < <(echo "$commits" | grep -oE '^\[[^\]]+\]' | sort | uniq -c | sort -rn | head -5 | awk '{print $2}')
    fi

    local prefixes_json="[]"
    [ ${#prefixes[@]} -gt 0 ] && prefixes_json=$(printf '%s\n' "${prefixes[@]}" | jq -R . | jq -s .)

    jq -n \
        --arg convention "$convention" \
        --arg confidence "$confidence" \
        --argjson prefixes "$prefixes_json" \
        --arg total "$total_commits" \
        --arg conventional "$conventional_count" \
        --arg tag "$tag_count" \
        --arg ticket "$ticket_count" \
        '{
            convention: $convention,
            confidence: ($confidence | tonumber),
            common_prefixes: $prefixes,
            stats: {
                total_analyzed: ($total | tonumber),
                conventional_commits: ($conventional | tonumber),
                tag_style: ($tag | tonumber),
                ticket_references: ($ticket | tonumber)
            }
        }'
}

# Analyze branch naming
analyze_branch_naming() {
    local branches
    branches=$(git branch -r 2>/dev/null | grep -v HEAD | sed 's/.*\///' | head -50 || echo "")

    if [ -z "$branches" ]; then
        echo '{"pattern": "unknown", "stats": {"total_branches": 0}}'
        return
    fi

    local total_branches
    total_branches=$(echo "$branches" | grep -c . || echo "0")

    if [ "$total_branches" -eq 0 ]; then
        echo '{"pattern": "unknown", "stats": {"total_branches": 0}}'
        return
    fi

    # Count different patterns
    local feature_count
    feature_count=$(count_matches '^feature[/-]' "$branches")

    local fix_count
    fix_count=$(count_matches '^(fix|bugfix|hotfix)[/-]' "$branches")

    local release_count
    release_count=$(count_matches '^release[/-]' "$branches")

    local ticket_count
    ticket_count=$(count_matches '[A-Z]+-[0-9]+' "$branches" "-i")

    # Determine pattern
    local pattern="freeform"
    local has_feature="false"
    local has_fix="false"

    [[ "$feature_count" -gt 2 ]] && has_feature="true"
    [[ "$fix_count" -gt 2 ]] && has_fix="true"

    if [[ "$has_feature" == "true" ]] || [[ "$has_fix" == "true" ]]; then
        pattern="gitflow-style"
    fi
    if [ "$total_branches" -gt 0 ] && [ "$ticket_count" -gt $((total_branches / 3)) ]; then
        pattern="ticket-based"
    fi

    jq -n \
        --arg pattern "$pattern" \
        --argjson has_feature "$has_feature" \
        --argjson has_fix "$has_fix" \
        --arg total "$total_branches" \
        --arg feature "$feature_count" \
        --arg fix "$fix_count" \
        --arg release "$release_count" \
        '{
            pattern: $pattern,
            uses_feature_branches: $has_feature,
            uses_fix_branches: $has_fix,
            stats: {
                total_branches: ($total | tonumber),
                feature_branches: ($feature | tonumber),
                fix_branches: ($fix | tonumber),
                release_branches: ($release | tonumber)
            }
        }'
}

# Analyze merge strategy
analyze_merge_strategy() {
    local merge_commits
    merge_commits=$(git log --oneline -"$SAMPLE_SIZE" --merges 2>/dev/null | wc -l || echo "0")

    local total_commits
    total_commits=$(git log --oneline -"$SAMPLE_SIZE" 2>/dev/null | wc -l || echo "0")

    if [ "$total_commits" -eq 0 ]; then
        echo '{"strategy": "unknown"}'
        return
    fi

    local merge_pct=$((merge_commits * 100 / total_commits))

    local strategy="unknown"
    if [ "$merge_pct" -lt 5 ]; then
        strategy="squash-and-merge"
    elif [ "$merge_pct" -gt 20 ]; then
        strategy="merge-commits"
    else
        strategy="mixed"
    fi

    # Check for squash patterns in commit messages
    local squash_patterns
    squash_patterns=$(git log --oneline -"$SAMPLE_SIZE" 2>/dev/null | grep -cE '\(#[0-9]+\)$' || echo "0")

    if [ "$squash_patterns" -gt $((total_commits / 3)) ]; then
        strategy="squash-and-merge"
    fi

    jq -n \
        --arg strategy "$strategy" \
        --arg merge_pct "$merge_pct" \
        --arg merge_commits "$merge_commits" \
        --arg total "$total_commits" \
        '{
            strategy: $strategy,
            merge_commit_percentage: ($merge_pct | tonumber),
            stats: {
                merge_commits: ($merge_commits | tonumber),
                total_commits: ($total | tonumber)
            }
        }'
}

# Analyze release tagging
analyze_releases() {
    local tags
    tags=$(git tag -l 2>/dev/null | tail -20 || echo "")

    if [ -z "$tags" ]; then
        echo '{"pattern": "none", "total_tags": 0}'
        return
    fi

    local total_tags
    total_tags=$(echo "$tags" | wc -l)

    # Check for semver pattern (v1.2.3 or 1.2.3)
    local semver_count
    semver_count=$(echo "$tags" | grep -cE '^v?[0-9]+\.[0-9]+\.[0-9]+' 2>/dev/null || echo "0")

    # Check for calver pattern (2024.01.15 or similar)
    local calver_count
    calver_count=$(echo "$tags" | grep -cE '^[0-9]{4}\.[0-9]{2}' 2>/dev/null || echo "0")

    local pattern="custom"
    if [ "$semver_count" -gt $((total_tags / 2)) ]; then
        pattern="semver"
    elif [ "$calver_count" -gt $((total_tags / 2)) ]; then
        pattern="calver"
    fi

    # Check for v prefix
    local has_v_prefix
    has_v_prefix=$([[ $(echo "$tags" | grep -cE '^v' || echo "0") -gt $((total_tags / 2)) ]] && echo "true" || echo "false")

    # Get latest tag
    local latest_tag
    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

    jq -n \
        --arg pattern "$pattern" \
        --argjson has_v_prefix "$has_v_prefix" \
        --arg latest "$latest_tag" \
        --arg total "$total_tags" \
        --arg semver "$semver_count" \
        '{
            pattern: $pattern,
            uses_v_prefix: $has_v_prefix,
            latest_tag: $latest,
            stats: {
                total_tags: ($total | tonumber),
                semver_tags: ($semver | tonumber)
            }
        }'
}

# Analyze default branch
analyze_default_branch() {
    local default_branch
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "")

    if [ -z "$default_branch" ]; then
        # Try to detect from common names
        if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
            default_branch="main"
        elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
            default_branch="master"
        fi
    fi

    jq -n --arg branch "$default_branch" '{default_branch: $branch}'
}

# Run all analyses
COMMIT_CONVENTION=$(analyze_commit_convention)
BRANCH_NAMING=$(analyze_branch_naming)
MERGE_STRATEGY=$(analyze_merge_strategy)
RELEASES=$(analyze_releases)
DEFAULT_BRANCH=$(analyze_default_branch)

# Build final JSON output
jq -n \
    --argjson commits "$COMMIT_CONVENTION" \
    --argjson branches "$BRANCH_NAMING" \
    --argjson merge "$MERGE_STRATEGY" \
    --argjson releases "$RELEASES" \
    --argjson default "$DEFAULT_BRANCH" \
    '{
        commit_convention: $commits,
        branch_naming: $branches,
        merge_strategy: $merge,
        releases: $releases,
        default_branch: $default.default_branch
    }'
