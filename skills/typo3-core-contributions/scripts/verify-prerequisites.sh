#!/bin/bash
# TYPO3 Core Contribution Prerequisites Checker
# Verifies accounts, git configuration, and development environment setup

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "TYPO3 Core Contribution Prerequisites Check"
echo "================================================"
echo

# Track overall status
ALL_CHECKS_PASSED=true

# Function to print status
print_status() {
    if [ "$1" = "pass" ]; then
        echo -e "${GREEN}✓${NC} $2"
    elif [ "$1" = "fail" ]; then
        echo -e "${RED}✗${NC} $2"
        ALL_CHECKS_PASSED=false
    elif [ "$1" = "warn" ]; then
        echo -e "${YELLOW}⚠${NC} $2"
    fi
}

# 1. Check Git installation
echo "1. Checking Git installation..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    print_status "pass" "Git installed: $GIT_VERSION"
else
    print_status "fail" "Git not installed"
fi
echo

# 2. Check Git user configuration
echo "2. Checking Git user configuration..."
GIT_USER_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
    print_status "pass" "Git user configured: $GIT_USER_NAME <$GIT_USER_EMAIL>"
else
    print_status "fail" "Git user not configured. Run:"
    echo "  git config --global user.name \"Your Name\""
    echo "  git config --global user.email \"your-email@example.org\""
fi
echo

# 2a. Verify Git email matches Gerrit account
echo "2a. Verifying Git email against Gerrit..."
if [ -n "$GIT_USER_EMAIL" ]; then
    echo "   Your Git email: $GIT_USER_EMAIL"
    print_status "warn" "  IMPORTANT: Verify this email is registered at:"
    echo "    https://review.typo3.org/settings#EmailAddresses"
    echo "    Gerrit will reject pushes if email doesn't match!"
fi
echo

# 3. Check if in TYPO3 repository
echo "3. Checking TYPO3 repository..."
if [ -d ".git" ]; then
    REPO_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [[ "$REPO_URL" == *"typo3"* ]]; then
        print_status "pass" "In TYPO3 repository"

        # Check TYPO3-specific git config
        echo "   Checking TYPO3-specific configuration..."

        # Check auto-rebase
        AUTO_REBASE=$(git config --get branch.autosetuprebase 2>/dev/null || echo "")
        if [ "$AUTO_REBASE" = "remote" ]; then
            print_status "pass" "  Auto-rebase configured"
        else
            print_status "fail" "  Auto-rebase not configured. Run: git config branch.autosetuprebase remote"
        fi

        # Check Gerrit push URL
        PUSH_URL=$(git config --get remote.origin.pushurl 2>/dev/null || echo "")
        if [[ "$PUSH_URL" == *"review.typo3.org"* ]]; then
            print_status "pass" "  Gerrit push URL configured"
        else
            print_status "fail" "  Gerrit push URL not configured. Run:"
            echo "    git config remote.origin.pushurl ssh://<USERNAME>@review.typo3.org:29418/Packages/TYPO3.CMS.git"
        fi

        # Check push refspec
        PUSH_REFSPEC=$(git config --get remote.origin.push 2>/dev/null || echo "")
        if [[ "$PUSH_REFSPEC" == *"refs/for/main"* ]]; then
            print_status "pass" "  Push refspec configured for Gerrit"
        else
            print_status "fail" "  Push refspec not configured. Run:"
            echo "    git config remote.origin.push +refs/heads/main:refs/for/main"
        fi

    else
        print_status "warn" "In git repository but not TYPO3. URL: $REPO_URL"
    fi
else
    print_status "warn" "Not in a git repository (run from TYPO3 repo root)"
fi
echo

# 4. Check Git hooks
echo "4. Checking Git hooks..."
if [ -f ".git/hooks/commit-msg" ]; then
    print_status "pass" "commit-msg hook installed"
else
    print_status "fail" "commit-msg hook not installed. Run: composer gerrit:setup"
fi

if [ -f ".git/hooks/pre-commit" ]; then
    print_status "pass" "pre-commit hook installed"
else
    print_status "warn" "pre-commit hook not installed (optional but recommended)"
fi
echo

# 5. Check SSH connection to Gerrit
echo "5. Checking Gerrit SSH connection..."
if timeout 5 ssh -p 29418 -o StrictHostKeyChecking=no -o BatchMode=yes review.typo3.org gerrit version &>/dev/null; then
    print_status "pass" "Gerrit SSH connection successful"
else
    print_status "fail" "Cannot connect to Gerrit via SSH. Check your SSH keys and Gerrit setup"
fi
echo

# 6. Check Composer
echo "6. Checking Composer installation..."
if command -v composer &> /dev/null; then
    COMPOSER_VERSION=$(composer --version 2>/dev/null | head -n1)
    print_status "pass" "Composer installed: $COMPOSER_VERSION"
else
    print_status "warn" "Composer not found (needed for running tests and gerrit:setup)"
fi
echo

# 7. Check PHP
echo "7. Checking PHP installation..."
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -v | head -n1)
    print_status "pass" "PHP installed: $PHP_VERSION"
else
    print_status "warn" "PHP not found (needed for development and testing)"
fi
echo

# 8. Check DDEV (optional)
echo "8. Checking DDEV installation (optional)..."
if command -v ddev &> /dev/null; then
    DDEV_VERSION=$(ddev version | head -n1)
    print_status "pass" "DDEV installed: $DDEV_VERSION"
else
    print_status "warn" "DDEV not found (recommended for development environment)"
fi
echo

# Final Summary
echo "================================================"
if [ "$ALL_CHECKS_PASSED" = true ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo "You're ready to contribute to TYPO3 Core."
else
    echo -e "${RED}✗ Some checks failed.${NC}"
    echo "Please address the issues above before contributing."
fi
echo "================================================"

# Exit with appropriate code
if [ "$ALL_CHECKS_PASSED" = true ]; then
    exit 0
else
    exit 1
fi
