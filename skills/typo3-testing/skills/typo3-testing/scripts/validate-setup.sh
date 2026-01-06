#!/usr/bin/env bash

#
# Validate TYPO3 testing infrastructure setup
#
# Checks:
# - Required dependencies
# - PHPUnit configurations
# - Directory structure
# - Docker (for acceptance tests)
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="$(pwd)"
ERRORS=0
WARNINGS=0

echo -e "${GREEN}=== TYPO3 Testing Setup Validation ===${NC}"
echo

# Check composer.json
echo -e "${YELLOW}[1/5] Checking composer.json dependencies...${NC}"
if [ ! -f "${PROJECT_DIR}/composer.json" ]; then
    echo -e "${RED}✗ composer.json not found${NC}"
    ((ERRORS++))
else
    if grep -q "typo3/testing-framework" "${PROJECT_DIR}/composer.json"; then
        echo -e "${GREEN}✓ typo3/testing-framework installed${NC}"
    else
        echo -e "${RED}✗ typo3/testing-framework missing${NC}"
        ((ERRORS++))
    fi

    if grep -q "phpunit/phpunit" "${PROJECT_DIR}/composer.json"; then
        echo -e "${GREEN}✓ phpunit/phpunit installed${NC}"
    else
        echo -e "${RED}✗ phpunit/phpunit missing${NC}"
        ((ERRORS++))
    fi
fi

# Check PHPUnit configurations
echo -e "${YELLOW}[2/5] Checking PHPUnit configurations...${NC}"
if [ -f "${PROJECT_DIR}/Build/phpunit/UnitTests.xml" ]; then
    echo -e "${GREEN}✓ UnitTests.xml present${NC}"
else
    echo -e "${RED}✗ UnitTests.xml missing${NC}"
    ((ERRORS++))
fi

if [ -f "${PROJECT_DIR}/Build/phpunit/FunctionalTests.xml" ]; then
    echo -e "${GREEN}✓ FunctionalTests.xml present${NC}"
else
    echo -e "${RED}✗ FunctionalTests.xml missing${NC}"
    ((ERRORS++))
fi

if [ -f "${PROJECT_DIR}/Build/phpunit/FunctionalTestsBootstrap.php" ]; then
    echo -e "${GREEN}✓ FunctionalTestsBootstrap.php present${NC}"
else
    echo -e "${RED}✗ FunctionalTestsBootstrap.php missing${NC}"
    ((ERRORS++))
fi

# Check directory structure
echo -e "${YELLOW}[3/5] Checking directory structure...${NC}"
for dir in "Tests/Unit" "Tests/Functional" "Tests/Functional/Fixtures"; do
    if [ -d "${PROJECT_DIR}/${dir}" ]; then
        echo -e "${GREEN}✓ ${dir}/ exists${NC}"
    else
        echo -e "${YELLOW}⚠ ${dir}/ missing${NC}"
        ((WARNINGS++))
    fi
done

# Check AGENTS.md files
echo -e "${YELLOW}[4/5] Checking AGENTS.md documentation...${NC}"
for dir in "Tests/Unit" "Tests/Functional"; do
    if [ -f "${PROJECT_DIR}/${dir}/AGENTS.md" ]; then
        echo -e "${GREEN}✓ ${dir}/AGENTS.md present${NC}"
    else
        echo -e "${YELLOW}⚠ ${dir}/AGENTS.md missing${NC}"
        ((WARNINGS++))
    fi
done

# Check Docker (optional, for acceptance tests)
echo -e "${YELLOW}[5/5] Checking Docker availability (for acceptance tests)...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker installed${NC}"

    if docker ps &> /dev/null; then
        echo -e "${GREEN}✓ Docker daemon running${NC}"
    else
        echo -e "${YELLOW}⚠ Docker daemon not running${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠ Docker not installed (required for acceptance tests)${NC}"
    ((WARNINGS++))
fi

# Summary
echo
echo -e "${GREEN}=== Validation Summary ===${NC}"

if [ ${ERRORS} -eq 0 ] && [ ${WARNINGS} -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo
    echo "Your testing infrastructure is ready to use."
    echo "Generate your first test:"
    echo "  ~/.claude/skills/typo3-testing/scripts/generate-test.sh unit MyClass"
    exit 0
elif [ ${ERRORS} -eq 0 ]; then
    echo -e "${YELLOW}⚠ ${WARNINGS} warnings found${NC}"
    echo
    echo "Basic setup is complete, but some optional components are missing."
    exit 0
else
    echo -e "${RED}✗ ${ERRORS} errors found${NC}"
    if [ ${WARNINGS} -gt 0 ]; then
        echo -e "${YELLOW}⚠ ${WARNINGS} warnings found${NC}"
    fi
    echo
    echo "Run setup script to fix errors:"
    echo "  ~/.claude/skills/typo3-testing/scripts/setup-testing.sh"
    exit 1
fi
