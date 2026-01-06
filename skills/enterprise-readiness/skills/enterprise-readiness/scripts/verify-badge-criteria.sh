#!/bin/bash
# verify-badge-criteria.sh - Automated verification of OpenSSF Badge criteria
# Usage: ./verify-badge-criteria.sh [--level passing|silver|gold]
set -euo pipefail

# Validate level argument
case "${1:-passing}" in
    passing|silver|gold) LEVEL="${1:-passing}" ;;
    --help|-h)
        echo "Usage: $0 [--level passing|silver|gold]"
        echo "  passing  - Check basic OpenSSF criteria (default)"
        echo "  silver   - Check Silver level criteria"
        echo "  gold     - Check Gold level criteria"
        exit 0
        ;;
    *) echo "Error: Level must be passing, silver, or gold"; exit 1 ;;
esac

SCORE=0
MAX_SCORE=0

echo "=== OpenSSF Best Practices Badge Verification ==="
echo "Level: $LEVEL"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}✓${NC} $1"; SCORE=$((SCORE+1)); MAX_SCORE=$((MAX_SCORE+1)); }
fail() { echo -e "${RED}✗${NC} $1"; MAX_SCORE=$((MAX_SCORE+1)); }
skip() { echo -e "${YELLOW}○${NC} $1 (N/A)"; }

echo "=== Basics ==="

# Check for required files
[[ -f "README.md" ]] && pass "README.md exists" || fail "README.md missing"
[[ -f "LICENSE" || -f "LICENSE.md" || -f "COPYING" ]] && pass "LICENSE file exists" || fail "LICENSE file missing"
[[ -f "CONTRIBUTING.md" ]] && pass "CONTRIBUTING.md exists" || fail "CONTRIBUTING.md missing"
[[ -f "SECURITY.md" ]] && pass "SECURITY.md exists" || fail "SECURITY.md missing"

if [[ "$LEVEL" != "passing" ]]; then
    echo ""
    echo "=== Silver Level Checks ==="

    [[ -f "GOVERNANCE.md" ]] && pass "GOVERNANCE.md exists" || fail "GOVERNANCE.md missing"
    [[ -f "CODE_OF_CONDUCT.md" ]] && pass "CODE_OF_CONDUCT.md exists" || fail "CODE_OF_CONDUCT.md missing"
    [[ -f "ARCHITECTURE.md" ]] && pass "ARCHITECTURE.md exists" || fail "ARCHITECTURE.md missing"

    # Check for DCO in CONTRIBUTING.md
    if grep -qi "Developer Certificate of Origin\|DCO\|sign-off" CONTRIBUTING.md 2>/dev/null; then
        pass "DCO mentioned in CONTRIBUTING.md"
    else
        fail "DCO not mentioned in CONTRIBUTING.md"
    fi

    # Check for 80% coverage threshold in CI
    if grep -rq "coverage.*80\|80.*coverage" .github/workflows/ 2>/dev/null; then
        pass "80% coverage threshold in CI"
    else
        fail "80% coverage threshold not found in CI"
    fi
fi

if [[ "$LEVEL" == "gold" ]]; then
    echo ""
    echo "=== Gold Level Checks ==="

    # Check for SPDX headers
    SPDX_COUNT=$(grep -rl "SPDX-License-Identifier" --include="*.go" --include="*.py" --include="*.js" . 2>/dev/null | wc -l)
    SOURCE_COUNT=$(find . -name "*.go" -o -name "*.py" -o -name "*.js" 2>/dev/null | wc -l)
    if [[ "$SOURCE_COUNT" -gt 0 && "$SPDX_COUNT" -eq "$SOURCE_COUNT" ]]; then
        pass "SPDX headers in all source files ($SPDX_COUNT/$SOURCE_COUNT)"
    else
        fail "SPDX headers missing in some files ($SPDX_COUNT/$SOURCE_COUNT)"
    fi

    # Check for 90% coverage threshold
    if grep -rq "coverage.*90\|90.*coverage" .github/workflows/ 2>/dev/null; then
        pass "90% coverage threshold in CI"
    else
        fail "90% coverage threshold not found in CI"
    fi

    # Check for signed tags
    LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [[ -n "$LATEST_TAG" ]]; then
        if git tag -v "$LATEST_TAG" 2>/dev/null | grep -q "Good signature"; then
            pass "Latest tag ($LATEST_TAG) is signed"
        else
            fail "Latest tag ($LATEST_TAG) is not signed"
        fi
    else
        skip "No tags found"
    fi
fi

echo ""
echo "=== Supply Chain Security ==="

# Check for SLSA provenance
if grep -rq "slsa-framework\|slsa-github-generator" .github/workflows/ 2>/dev/null; then
    pass "SLSA provenance generation configured"
else
    fail "SLSA provenance not configured"
fi

# Check for Cosign signing
if grep -rq "cosign\|sigstore" .github/workflows/ 2>/dev/null; then
    pass "Artifact signing (Cosign) configured"
else
    fail "Artifact signing not configured"
fi

# Check for SBOM generation
if grep -rq "syft\|sbom\|cyclonedx\|spdx" .github/workflows/ 2>/dev/null; then
    pass "SBOM generation configured"
else
    fail "SBOM generation not configured"
fi

echo ""
echo "=== Quality Gates ==="

# Check for linting
if grep -rq "golangci-lint\|eslint\|pylint\|flake8" .github/workflows/ 2>/dev/null; then
    pass "Linting configured in CI"
else
    fail "Linting not configured"
fi

# Check for security scanning
if grep -rq "codeql\|gosec\|snyk\|trivy" .github/workflows/ 2>/dev/null; then
    pass "Security scanning configured"
else
    fail "Security scanning not configured"
fi

# Check for secret scanning
if grep -rq "gitleaks\|trufflehog\|detect-secrets" .github/workflows/ 2>/dev/null; then
    pass "Secret scanning configured"
else
    fail "Secret scanning not configured"
fi

echo ""
echo "=== Summary ==="
# Guard against division by zero
if [[ "$MAX_SCORE" -eq 0 ]]; then
    PERCENTAGE=0
else
    PERCENTAGE=$((SCORE * 100 / MAX_SCORE))
fi
echo "Score: $SCORE/$MAX_SCORE ($PERCENTAGE%)"

if [[ $PERCENTAGE -ge 90 ]]; then
    echo -e "${GREEN}Status: Excellent - Ready for $LEVEL certification${NC}"
elif [[ $PERCENTAGE -ge 70 ]]; then
    echo -e "${YELLOW}Status: Good - Minor improvements needed${NC}"
else
    echo -e "${RED}Status: Needs improvement${NC}"
fi
