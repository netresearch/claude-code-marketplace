#!/bin/bash
# verify-github-project.sh
# Verify GitHub project configuration against platform best practices
#
# This script checks GitHub-specific features only:
# - Repository documentation (README, LICENSE, SECURITY.md)
# - Collaboration setup (CODEOWNERS, issue/PR templates)
# - Dependency automation (Dependabot/Renovate, auto-merge)
# - Release configuration
#
# For CI/CD pipelines, see: go-development, php-modernization skills
# For security scanning, see: security-audit skill
# For SLSA/SBOMs, see: enterprise-readiness skill
#
# Usage: ./verify-github-project.sh /path/to/repository
#
# Exit codes:
#   0 - All checks passed
#   1 - Some checks failed
#   2 - Invalid arguments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Print functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}!${NC} $1"
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}→${NC} $1"
}

header() {
    echo ""
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
}

# Check arguments
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/repository"
    exit 2
fi

REPO_PATH="$1"

if [ ! -d "$REPO_PATH" ]; then
    echo "Error: Directory does not exist: $REPO_PATH"
    exit 2
fi

cd "$REPO_PATH"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║        GitHub Project Configuration Checker               ║"
echo "║        (Platform Features Only)                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
info "Checking repository: $REPO_PATH"
info "Note: For CI/CD, security scanning, SLSA → see other skills"

# Extract repo slug for GitHub API calls
REPO_SLUG=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null)
    if [ -n "$REMOTE_URL" ]; then
        REPO_SLUG=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/](.+/[^.]+)(\.git)?$|\1|')
    fi
fi

# ─────────────────────────────────────────────────────────────────
header "Root Documentation Files"
# ─────────────────────────────────────────────────────────────────

[ -f "README.md" ] && pass "README.md exists" || fail "README.md missing"
[ -f "LICENSE" ] && pass "LICENSE exists" || fail "LICENSE missing"
[ -f "SECURITY.md" ] && pass "SECURITY.md exists" || fail "SECURITY.md missing (required for vulnerability reporting)"
[ -f "CONTRIBUTING.md" ] && pass "CONTRIBUTING.md exists" || warn "CONTRIBUTING.md missing"
[ -f "CODE_OF_CONDUCT.md" ] && pass "CODE_OF_CONDUCT.md exists" || warn "CODE_OF_CONDUCT.md missing"
[ -f "CHANGELOG.md" ] && pass "CHANGELOG.md exists" || warn "CHANGELOG.md missing"

# ─────────────────────────────────────────────────────────────────
header ".github Directory Structure"
# ─────────────────────────────────────────────────────────────────

[ -d ".github" ] && pass ".github directory exists" || fail ".github directory missing"

# CODEOWNERS for automatic reviewer assignment
if [ -f ".github/CODEOWNERS" ]; then
    pass "CODEOWNERS configured"
    # Check if CODEOWNERS has actual content
    if grep -q "^[^#]" .github/CODEOWNERS 2>/dev/null; then
        pass "CODEOWNERS has review rules defined"
    else
        warn "CODEOWNERS exists but no rules defined"
    fi
else
    warn "CODEOWNERS missing (recommended for automatic reviewer assignment)"
fi

# ─────────────────────────────────────────────────────────────────
header "Dependency Management (Dependabot/Renovate)"
# ─────────────────────────────────────────────────────────────────

DEPS_CONFIGURED=false

if [ -f ".github/dependabot.yml" ]; then
    pass "Dependabot configured"
    DEPS_CONFIGURED=true

    # Check for dependency grouping
    if grep -q "groups:" .github/dependabot.yml 2>/dev/null; then
        pass "Dependabot grouping enabled (reduces PR noise)"
    else
        warn "Consider enabling Dependabot grouping"
    fi

    # Check for GitHub Actions updates
    if grep -q "github-actions" .github/dependabot.yml 2>/dev/null; then
        pass "GitHub Actions updates configured"
    else
        warn "Consider adding github-actions ecosystem to Dependabot"
    fi
fi

if [ -f ".github/renovate.json" ] || [ -f "renovate.json" ]; then
    pass "Renovate configured"
    DEPS_CONFIGURED=true

    RENOVATE_FILE=""
    [ -f ".github/renovate.json" ] && RENOVATE_FILE=".github/renovate.json"
    [ -f "renovate.json" ] && RENOVATE_FILE="renovate.json"

    # Check for auto-merge in Renovate config
    if grep -q "automerge" "$RENOVATE_FILE" 2>/dev/null; then
        pass "Renovate auto-merge configured"
    else
        warn "Consider enabling Renovate auto-merge for minor/patch updates"
    fi
fi

if [ "$DEPS_CONFIGURED" = false ]; then
    fail "No dependency management (Dependabot or Renovate) configured"
fi

# ─────────────────────────────────────────────────────────────────
header "Auto-merge Workflow"
# ─────────────────────────────────────────────────────────────────

if [ -d ".github/workflows" ]; then
    # Check for auto-merge workflow
    if grep -rl "pull_request_target" .github/workflows/ > /dev/null 2>&1; then
        if grep -rl "dependabot\[bot\]\|renovate\[bot\]" .github/workflows/ > /dev/null 2>&1; then
            pass "Auto-merge workflow configured for dependency bots"

            # Check for metadata check (safer auto-merge)
            if grep -rl "dependabot/fetch-metadata" .github/workflows/ > /dev/null 2>&1; then
                pass "Dependabot metadata check enabled (safer auto-merge)"
            fi

            # Check for merge method compatibility
            WORKFLOW_MERGE_METHOD=""
            if grep -rq "\-\-squash" .github/workflows/ 2>/dev/null; then
                WORKFLOW_MERGE_METHOD="squash"
            elif grep -rq "\-\-rebase" .github/workflows/ 2>/dev/null; then
                WORKFLOW_MERGE_METHOD="rebase"
            elif grep -rq "\-\-merge" .github/workflows/ 2>/dev/null; then
                WORKFLOW_MERGE_METHOD="merge"
            fi

            if [ -n "$WORKFLOW_MERGE_METHOD" ]; then
                info "Auto-merge workflow uses: --$WORKFLOW_MERGE_METHOD"
            fi
        else
            warn "pull_request_target workflow exists but no bot auto-merge detected"
        fi
    else
        warn "No auto-merge workflow for dependency updates"
    fi
else
    warn ".github/workflows directory missing"
fi

# ─────────────────────────────────────────────────────────────────
header "Auto-merge Compatibility Check"
# ─────────────────────────────────────────────────────────────────

if command -v gh &> /dev/null && [ -n "$REPO_SLUG" ]; then
    # Get repo merge settings
    MERGE_SETTINGS=$(gh api "repos/$REPO_SLUG" 2>/dev/null || echo "{}")

    if [ "$MERGE_SETTINGS" != "{}" ]; then
        ALLOW_SQUASH=$(echo "$MERGE_SETTINGS" | jq -r '.allow_squash_merge // false')
        ALLOW_MERGE=$(echo "$MERGE_SETTINGS" | jq -r '.allow_merge_commit // true')
        ALLOW_REBASE=$(echo "$MERGE_SETTINGS" | jq -r '.allow_rebase_merge // false')

        # Check for merge method alignment with workflow
        if [ -n "$WORKFLOW_MERGE_METHOD" ]; then
            case "$WORKFLOW_MERGE_METHOD" in
                squash)
                    if [ "$ALLOW_SQUASH" = "true" ]; then
                        pass "Workflow merge method (squash) is allowed by repo settings"
                    else
                        fail "MISMATCH: Workflow uses --squash but repo has allow_squash_merge=false"
                        info "Fix: Update workflow to use --rebase, or enable squash merge in repo settings"
                    fi
                    ;;
                rebase)
                    if [ "$ALLOW_REBASE" = "true" ]; then
                        pass "Workflow merge method (rebase) is allowed by repo settings"
                    else
                        fail "MISMATCH: Workflow uses --rebase but repo has allow_rebase_merge=false"
                        info "Fix: Enable rebase merge in repo settings"
                    fi
                    ;;
                merge)
                    if [ "$ALLOW_MERGE" = "true" ]; then
                        pass "Workflow merge method (merge) is allowed by repo settings"
                    else
                        fail "MISMATCH: Workflow uses --merge but repo has allow_merge_commit=false"
                        info "Fix: Update workflow to use --rebase, or enable merge commits in repo settings"
                    fi
                    ;;
            esac
        fi

        # Check for rebase-only configuration (recommended)
        if [ "$ALLOW_REBASE" = "true" ] && [ "$ALLOW_MERGE" = "false" ] && [ "$ALLOW_SQUASH" = "false" ]; then
            pass "Repo configured for rebase-only merges (recommended)"
        elif [ "$ALLOW_REBASE" = "true" ]; then
            info "Multiple merge methods allowed. Consider enabling rebase-only for clean history."
        fi
    fi
else
    info "Skipping merge method compatibility check (requires gh CLI and remote)"
fi

# ─────────────────────────────────────────────────────────────────
header "Issue & PR Templates"
# ─────────────────────────────────────────────────────────────────

# Issue templates
if [ -d ".github/ISSUE_TEMPLATE" ]; then
    pass "Issue template directory exists"

    [ -f ".github/ISSUE_TEMPLATE/bug_report.md" ] && pass "Bug report template exists" || warn "Bug report template missing"
    [ -f ".github/ISSUE_TEMPLATE/feature_request.md" ] && pass "Feature request template exists" || warn "Feature request template missing"

    # Check for config.yml (template chooser)
    if [ -f ".github/ISSUE_TEMPLATE/config.yml" ]; then
        pass "Issue template chooser configured"

        # Check if blank issues are disabled
        if grep -q "blank_issues_enabled: false" .github/ISSUE_TEMPLATE/config.yml 2>/dev/null; then
            pass "Blank issues disabled (forces template use)"
        fi

        # Check for Discussions redirect
        if grep -q "discussions" .github/ISSUE_TEMPLATE/config.yml 2>/dev/null; then
            pass "Discussions link in issue chooser"
        fi
    else
        warn "Issue template config.yml missing (consider adding template chooser)"
    fi
else
    warn "Issue templates missing (.github/ISSUE_TEMPLATE/)"
fi

# PR template
if [ -f ".github/PULL_REQUEST_TEMPLATE.md" ]; then
    pass "PR template exists"

    # Check for checklist in PR template
    if grep -q "\- \[ \]" .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null; then
        pass "PR template has checklist items"
    fi
else
    warn "PR template missing (.github/PULL_REQUEST_TEMPLATE.md)"
fi

# ─────────────────────────────────────────────────────────────────
header "GitHub Release Configuration"
# ─────────────────────────────────────────────────────────────────

if [ -f ".github/release.yml" ]; then
    pass "Release notes configuration exists"

    # Check for category configuration
    if grep -q "categories:" .github/release.yml 2>/dev/null; then
        pass "Release note categories configured"
    fi

    # Check for bot exclusion
    if grep -q "dependabot\|renovate" .github/release.yml 2>/dev/null; then
        pass "Dependency bot PRs excluded from release notes"
    else
        warn "Consider excluding dependabot/renovate from release notes"
    fi
else
    warn "Release notes configuration missing (.github/release.yml)"
fi

# ─────────────────────────────────────────────────────────────────
header "Labels (via README check)"
# ─────────────────────────────────────────────────────────────────

info "Labels are configured via GitHub UI or gh CLI"
info "Recommended: bug, enhancement, documentation, good first issue, help wanted"
info "Run: gh label list (if gh CLI is available)"

# ─────────────────────────────────────────────────────────────────
header "Branch Configuration"
# ─────────────────────────────────────────────────────────────────

# Check default branch name locally
if git rev-parse --git-dir > /dev/null 2>&1; then
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [ -z "$DEFAULT_BRANCH" ]; then
        DEFAULT_BRANCH=$(git config --get init.defaultBranch 2>/dev/null || echo "unknown")
    fi

    if [ "$DEFAULT_BRANCH" = "main" ]; then
        pass "Default branch is 'main'"
    elif [ "$DEFAULT_BRANCH" = "unknown" ]; then
        warn "Could not determine default branch (check remote)"
    else
        fail "Default branch is '$DEFAULT_BRANCH' (should be 'main')"
    fi
fi

# Check repository settings via gh CLI if available
if command -v gh &> /dev/null && [ -n "$REPO_SLUG" ]; then
    info "Checking GitHub settings for $REPO_SLUG..."

    # Get repo settings
    REPO_SETTINGS=$(gh api "repos/$REPO_SLUG" 2>/dev/null || echo "{}")

    if [ "$REPO_SETTINGS" != "{}" ]; then
        # Check default branch
        GH_DEFAULT=$(echo "$REPO_SETTINGS" | jq -r '.default_branch // "unknown"')
        if [ "$GH_DEFAULT" = "main" ]; then
            pass "GitHub default branch is 'main'"
        else
            fail "GitHub default branch is '$GH_DEFAULT' (should be 'main')"
        fi

        # Check merge settings
        ALLOW_REBASE=$(echo "$REPO_SETTINGS" | jq -r '.allow_rebase_merge // false')
        ALLOW_MERGE=$(echo "$REPO_SETTINGS" | jq -r '.allow_merge_commit // true')
        ALLOW_SQUASH=$(echo "$REPO_SETTINGS" | jq -r '.allow_squash_merge // true')
        DELETE_ON_MERGE=$(echo "$REPO_SETTINGS" | jq -r '.delete_branch_on_merge // false')

        if [ "$ALLOW_REBASE" = "true" ]; then
            pass "Rebase merge enabled"
        else
            fail "Rebase merge disabled (should be enabled)"
        fi

        if [ "$ALLOW_MERGE" = "false" ]; then
            pass "Merge commits disabled"
        else
            fail "Merge commits enabled (should be disabled - rebase only)"
        fi

        if [ "$ALLOW_SQUASH" = "false" ]; then
            pass "Squash merge disabled"
        else
            fail "Squash merge enabled (should be disabled - rebase only)"
        fi

        if [ "$DELETE_ON_MERGE" = "true" ]; then
            pass "Delete branch on merge enabled"
        else
            fail "Delete branch on merge disabled (should be enabled)"
        fi
    else
        warn "Could not fetch GitHub repo settings (check gh auth)"
    fi
else
    info "Install gh CLI for remote settings verification"
fi

# ─────────────────────────────────────────────────────────────────
header "Branch Protection Readiness"
# ─────────────────────────────────────────────────────────────────

info "Branch protection is configured via GitHub Settings or API"
info "Key settings to enable for 'main' branch:"
echo "  - Require pull request before merging"
echo "  - Require approvals (1+ based on team size)"
echo "  - Dismiss stale reviews on new commits"
echo "  - Require review from CODEOWNERS"
echo "  - Require conversation resolution"
echo "  - Do not allow force pushes"
echo "  - Do not allow deletions"
echo "  - Allow rebase merge only (disable merge & squash)"
echo "  - Delete branch on merge"
info "Check with: gh api repos/{owner}/{repo}/branches/main/protection"

# Check if local indicators suggest protection is needed
if [ -f ".github/CODEOWNERS" ]; then
    pass "CODEOWNERS present (enables CODEOWNER review requirement)"
fi

if [ -d ".github/workflows" ] && ls .github/workflows/*.yml > /dev/null 2>&1; then
    pass "CI workflows present (enables required status checks)"
fi

# ─────────────────────────────────────────────────────────────────
header "Workflow Permissions"
# ─────────────────────────────────────────────────────────────────

if [ -d ".github/workflows" ]; then
    # Check for explicit permissions
    if grep -rl "permissions:" .github/workflows/ > /dev/null 2>&1; then
        pass "Workflow permissions explicitly configured"
    else
        warn "No explicit permissions in workflows (using repository defaults)"
    fi
fi

# ─────────────────────────────────────────────────────────────────
header "Summary"
# ─────────────────────────────────────────────────────────────────

echo ""
TOTAL=$((PASSED + FAILED + WARNINGS))
if [ $TOTAL -gt 0 ]; then
    SCORE=$((PASSED * 100 / TOTAL))
else
    SCORE=0
fi

echo "┌─────────────────────────────────────────────────────────┐"
echo "│           GitHub Platform Features Summary              │"
echo "├─────────────────────────────────────────────────────────┤"
printf "│  ${GREEN}Passed${NC}:   %3d                                         │\n" $PASSED
printf "│  ${RED}Failed${NC}:   %3d                                         │\n" $FAILED
printf "│  ${YELLOW}Warnings${NC}: %3d                                         │\n" $WARNINGS
echo "├─────────────────────────────────────────────────────────┤"
printf "│  Score:    %3d%% (%d/%d)                                │\n" $SCORE $PASSED $TOTAL
echo "└─────────────────────────────────────────────────────────┘"
echo ""

info "This checks GitHub platform features only."
info "For CI/CD pipelines → use go-development, php-modernization skills"
info "For security scanning → use security-audit skill"
info "For SLSA/SBOMs → use enterprise-readiness skill"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Some critical GitHub features are missing. Please address the issues above.${NC}"
    exit 1
else
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Core GitHub features configured. Consider addressing warnings for best practices.${NC}"
    else
        echo -e "${GREEN}All GitHub platform features configured correctly!${NC}"
    fi
    exit 0
fi
