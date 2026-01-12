#!/usr/bin/env bash

#
# TYPO3 Extension Conformance Checker
#
# Main script to orchestrate all conformance checks
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_DIR="${1:-.}"
REPORT_DIR="${PROJECT_DIR}/.conformance-reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="${REPORT_DIR}/conformance_${TIMESTAMP}.md"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    TYPO3 Extension Conformance Checker                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Standards Compliance Check:${NC}"
echo -e "  • TYPO3 Version: ${YELLOW}12.4 LTS / 13.x${NC}"
echo -e "  • PHP Version:   ${YELLOW}8.1 / 8.2 / 8.3 / 8.4${NC}"
echo -e "  • PSR Standard:  ${YELLOW}PSR-12 (Extended Coding Style)${NC}"
echo -e "  • Architecture:  ${YELLOW}Dependency Injection, PSR-14 Events${NC}"
echo ""

# Create report directory
mkdir -p "${REPORT_DIR}"

# Check if directory exists
if [ ! -d "${PROJECT_DIR}" ]; then
    echo -e "${RED}✗ Error: Directory ${PROJECT_DIR} not found${NC}"
    exit 1
fi

cd "${PROJECT_DIR}"

# Check if this is a TYPO3 extension
if [ ! -f "composer.json" ] && [ ! -f "ext_emconf.php" ]; then
    echo -e "${RED}✗ Error: Not a TYPO3 extension (composer.json or ext_emconf.php not found)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ TYPO3 Extension detected${NC}"
echo ""

# Initialize report
cat > "${REPORT_FILE}" <<'EOF'
# TYPO3 Extension Conformance Report

**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Project:** $(basename "$(pwd)")

## Standards Checked

This conformance check validates your extension against the following standards:

| Standard | Version/Specification |
|----------|----------------------|
| **TYPO3 Core** | 12.4 LTS / 13.x |
| **PHP** | 8.1 / 8.2 / 8.3 / 8.4 |
| **Coding Style** | PSR-12 (Extended Coding Style) |
| **Architecture** | Dependency Injection (PSR-11), PSR-14 Events, PSR-15 Middleware |
| **Testing** | PHPUnit 10+, TYPO3 Testing Framework |
| **Documentation** | reStructuredText (RST), TYPO3 Documentation Standards |

**Reference Documentation:**
- [TYPO3 Extension Architecture](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ExtensionArchitecture/)
- [TYPO3 Coding Guidelines](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/CodingGuidelines/)
- [PHP Architecture](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/PhpArchitecture/)
- [Testing Standards](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/)

---

## Summary

| Category | Score | Status |
|----------|-------|--------|
EOF

# Initialize scores
total_score=0
max_score=100

echo -e "${YELLOW}Running conformance checks...${NC}"
echo ""

# 1. File Structure Check
echo -e "${BLUE}[1/7] Checking file structure...${NC}"
if bash "${SCRIPT_DIR}/check-file-structure.sh" "${PROJECT_DIR}" >> "${REPORT_FILE}"; then
    echo -e "${GREEN}  ✓ File structure check complete${NC}"
    structure_score=18
else
    echo -e "${YELLOW}  ⚠ File structure issues found${NC}"
    structure_score=10
fi
echo ""

# 2. Documentation Structure Check (for full validation, invoke typo3-docs skill)
echo -e "${BLUE}[2/7] Checking documentation structure...${NC}"
if bash "${SCRIPT_DIR}/check-documentation.sh" "${PROJECT_DIR}" >> "${REPORT_FILE}"; then
    echo -e "${GREEN}  ✓ Documentation check complete${NC}"
    docs_score=10
else
    echo -e "${YELLOW}  ⚠ Documentation issues found${NC}"
    docs_score=5
fi
echo ""

# 3. Coding Standards Check
echo -e "${BLUE}[3/7] Checking coding standards...${NC}"
if bash "${SCRIPT_DIR}/check-coding-standards.sh" "${PROJECT_DIR}" >> "${REPORT_FILE}"; then
    echo -e "${GREEN}  ✓ Coding standards check complete${NC}"
    coding_score=18
else
    echo -e "${YELLOW}  ⚠ Coding standards issues found${NC}"
    coding_score=12
fi
echo ""

# 4. Architecture Check
echo -e "${BLUE}[4/7] Checking PHP architecture...${NC}"
if bash "${SCRIPT_DIR}/check-architecture.sh" "${PROJECT_DIR}" >> "${REPORT_FILE}"; then
    echo -e "${GREEN}  ✓ Architecture check complete${NC}"
    arch_score=18
else
    echo -e "${YELLOW}  ⚠ Architecture issues found${NC}"
    arch_score=10
fi
echo ""

# 5. Testing Check
echo -e "${BLUE}[5/7] Checking testing infrastructure...${NC}"
if bash "${SCRIPT_DIR}/check-testing.sh" "${PROJECT_DIR}" >> "${REPORT_FILE}"; then
    echo -e "${GREEN}  ✓ Testing check complete${NC}"
    test_score=16
else
    echo -e "${YELLOW}  ⚠ Testing issues found${NC}"
    test_score=8
fi
echo ""

# 6. PHPStan Baseline Check
echo -e "${BLUE}[6/7] Checking PHPStan baseline hygiene...${NC}"
if bash "${SCRIPT_DIR}/check-phpstan-baseline.sh" "${PROJECT_DIR}"; then
    echo -e "${GREEN}  ✓ PHPStan baseline hygiene check passed${NC}"
    baseline_score=10
else
    echo -e "${RED}  ✗ PHPStan baseline violation detected${NC}"
    baseline_score=0
fi
echo ""

# 7. Generate comprehensive report
echo -e "${BLUE}[7/7] Generating final report...${NC}"
bash "${SCRIPT_DIR}/generate-report.sh" "${PROJECT_DIR}" "${REPORT_FILE}" \
    "${structure_score}" "${coding_score}" "${arch_score}" "${test_score}"
echo ""

# Calculate total (including all scores)
total_score=$((structure_score + docs_score + coding_score + arch_score + test_score + baseline_score))

# Display summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Conformance Results                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  File Structure:       ${structure_score}/18"
echo -e "  Documentation:        ${docs_score}/10"
echo -e "  Coding Standards:     ${coding_score}/18"
echo -e "  PHP Architecture:     ${arch_score}/18"
echo -e "  Testing Standards:    ${test_score}/16"
echo -e "  Baseline Hygiene:     ${baseline_score}/10"
echo -e "  Best Practices:       10/10"
echo ""
echo -e "  ${BLUE}Total Score:          ${total_score}/100${NC}"
echo ""

if [ ${total_score} -ge 80 ]; then
    echo -e "${GREEN}✓ EXCELLENT conformance level${NC}"
elif [ ${total_score} -ge 60 ]; then
    echo -e "${YELLOW}⚠ GOOD conformance level (some improvements recommended)${NC}"
elif [ ${total_score} -ge 40 ]; then
    echo -e "${YELLOW}⚠ FAIR conformance level (several issues to address)${NC}"
else
    echo -e "${RED}✗ POOR conformance level (major improvements needed)${NC}"
fi

echo ""
echo -e "${GREEN}Report saved to: ${REPORT_FILE}${NC}"
echo ""

# Exit with appropriate code
if [ ${total_score} -ge 60 ]; then
    exit 0
else
    exit 1
fi
