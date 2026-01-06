#!/bin/bash
# verify-review-requirements.sh - Verify PR review requirements meet badge level
# Usage: ./verify-review-requirements.sh [--level silver|gold] [--owner owner] [--repo repo]
# OpenSSF Badge Criteria: two_person_review (Gold), code_review (Silver)
set -euo pipefail

LEVEL="silver"
OWNER=""
REPO=""
BRANCH="main"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --level)
            LEVEL="$2"
            shift 2
            ;;
        --owner)
            OWNER="$2"
            shift 2
            ;;
        --repo)
            REPO="$2"
            shift 2
            ;;
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo "=== PR Review Requirements Verification ==="
echo "Badge Level: $LEVEL"
echo ""

# Determine required reviewers based on level
case "$LEVEL" in
    passing)
        REQUIRED_REVIEWERS=0
        ;;
    silver)
        REQUIRED_REVIEWERS=1
        ;;
    gold)
        REQUIRED_REVIEWERS=2
        ;;
    *)
        echo "Error: Invalid level. Use passing, silver, or gold."
        exit 1
        ;;
esac

echo "Required reviewers for $LEVEL level: $REQUIRED_REVIEWERS"
echo ""

# Try to detect owner/repo from git remote
if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE_URL" ]; then
        # Extract owner/repo from various URL formats
        if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
            OWNER="${BASH_REMATCH[1]}"
            REPO="${BASH_REMATCH[2]}"
        fi
    fi
fi

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
    echo "Error: Could not determine repository. Use --owner and --repo flags."
    exit 1
fi

echo "Repository: $OWNER/$REPO"
echo "Branch: $BRANCH"
echo ""

# Check if gh CLI is available
if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is required but not installed."
    echo "Install from: https://cli.github.com/"
    exit 1
fi

# Check authentication
if ! gh auth status >/dev/null 2>&1; then
    echo "Error: GitHub CLI is not authenticated."
    echo "Run: gh auth login"
    exit 1
fi

# Fetch branch protection settings
echo "Fetching branch protection settings..."
echo ""

PROTECTION=$(gh api "repos/$OWNER/$REPO/branches/$BRANCH/protection" 2>/dev/null || echo "")

if [ -z "$PROTECTION" ]; then
    echo "✗ No branch protection configured for $BRANCH"
    echo ""
    echo "To enable branch protection via GitHub CLI:"
    echo "  gh api repos/$OWNER/$REPO/branches/$BRANCH/protection -X PUT -f required_approving_review_count=$REQUIRED_REVIEWERS"
    exit 1
fi

# Extract review requirements
REVIEW_PROTECTION=$(gh api "repos/$OWNER/$REPO/branches/$BRANCH/protection/required_pull_request_reviews" 2>/dev/null || echo "")

if [ -z "$REVIEW_PROTECTION" ]; then
    ACTUAL_REVIEWERS=0
    DISMISS_STALE="false"
    REQUIRE_CODEOWNERS="false"
else
    ACTUAL_REVIEWERS=$(echo "$REVIEW_PROTECTION" | jq -r '.required_approving_review_count // 0')
    DISMISS_STALE=$(echo "$REVIEW_PROTECTION" | jq -r '.dismiss_stale_reviews // false')
    REQUIRE_CODEOWNERS=$(echo "$REVIEW_PROTECTION" | jq -r '.require_code_owner_reviews // false')
fi

echo "=== Current Settings ==="
echo "Required approving reviews: $ACTUAL_REVIEWERS"
echo "Dismiss stale reviews: $DISMISS_STALE"
echo "Require code owner reviews: $REQUIRE_CODEOWNERS"
echo ""

# Check required status checks
STATUS_CHECKS=$(echo "$PROTECTION" | jq -r '.required_status_checks.contexts[]? // empty' 2>/dev/null | wc -l | tr -d ' ')
echo "Required status checks: $STATUS_CHECKS"

# Check enforce admins
ENFORCE_ADMINS=$(echo "$PROTECTION" | jq -r '.enforce_admins.enabled // false')
echo "Enforce for admins: $ENFORCE_ADMINS"

echo ""
echo "=== Assessment ==="
echo ""

PASSED=true

# Check reviewer count
if [ "$ACTUAL_REVIEWERS" -ge "$REQUIRED_REVIEWERS" ]; then
    if [ "$LEVEL" = "gold" ] && [ "$ACTUAL_REVIEWERS" -ge 2 ]; then
        echo "✓ Two-person review requirement met ($ACTUAL_REVIEWERS reviewers)"
    elif [ "$LEVEL" = "silver" ] && [ "$ACTUAL_REVIEWERS" -ge 1 ]; then
        echo "✓ Code review requirement met ($ACTUAL_REVIEWERS reviewer(s))"
    else
        echo "✓ Review requirement met ($ACTUAL_REVIEWERS reviewer(s))"
    fi
else
    echo "✗ Insufficient reviewers: $ACTUAL_REVIEWERS < $REQUIRED_REVIEWERS required"
    PASSED=false
fi

# Additional checks for Silver/Gold
if [ "$LEVEL" = "silver" ] || [ "$LEVEL" = "gold" ]; then
    if [ "$DISMISS_STALE" = "true" ]; then
        echo "✓ Stale reviews dismissed on new commits"
    else
        echo "⚠ Recommend: Enable 'Dismiss stale reviews'"
    fi

    if [ "$STATUS_CHECKS" -gt 0 ]; then
        echo "✓ Status checks required ($STATUS_CHECKS checks)"
    else
        echo "⚠ Recommend: Add required status checks"
    fi
fi

# Additional checks for Gold
if [ "$LEVEL" = "gold" ]; then
    if [ "$REQUIRE_CODEOWNERS" = "true" ]; then
        echo "✓ Code owner reviews required"
    else
        echo "⚠ Recommend: Enable code owner reviews"
    fi

    if [ "$ENFORCE_ADMINS" = "true" ]; then
        echo "✓ Rules enforced for administrators"
    else
        echo "⚠ Recommend: Enable 'Do not allow bypassing'"
    fi
fi

echo ""
if [ "$PASSED" = true ]; then
    echo "OpenSSF Badge: Review requirements for $LEVEL level = Met"
    exit 0
else
    echo "OpenSSF Badge: Review requirements for $LEVEL level = Unmet"
    echo ""
    echo "To update via GitHub CLI:"
    echo "  gh api repos/$OWNER/$REPO/branches/$BRANCH/protection/required_pull_request_reviews \\"
    echo "    -X PATCH -f required_approving_review_count=$REQUIRED_REVIEWERS"
    exit 1
fi
