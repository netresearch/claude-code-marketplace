#!/usr/bin/env bash

#
# Setup TYPO3 testing infrastructure
#
# This script initializes testing infrastructure for TYPO3 extensions:
# - Composer dependencies
# - PHPUnit configurations
# - Directory structure
# - Optional: Docker Compose for acceptance tests
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_DIR="$(pwd)"

WITH_ACCEPTANCE=false

# Parse arguments
while getopts ":a" opt; do
    case ${opt} in
        a)
            WITH_ACCEPTANCE=true
            ;;
        \?)
            echo "Usage: $0 [-a]"
            echo "  -a    Include acceptance testing setup (Docker Compose, Codeception)"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}=== TYPO3 Testing Infrastructure Setup ===${NC}"
echo

# Check if composer.json exists
if [ ! -f "${PROJECT_DIR}/composer.json" ]; then
    echo -e "${RED}Error: composer.json not found in current directory${NC}"
    echo "Please run this script from your TYPO3 extension root directory"
    exit 1
fi

# 1. Install testing framework dependencies
echo -e "${YELLOW}[1/6] Installing testing framework dependencies...${NC}"
if ! grep -q "typo3/testing-framework" "${PROJECT_DIR}/composer.json"; then
    composer require --dev "typo3/testing-framework:^8.0 || ^9.0" --no-update
    echo -e "${GREEN}✓ Added typo3/testing-framework${NC}"
else
    echo -e "${GREEN}✓ typo3/testing-framework already present${NC}"
fi

# Install PHPUnit if not present
if ! grep -q "phpunit/phpunit" "${PROJECT_DIR}/composer.json"; then
    composer require --dev "phpunit/phpunit:^10.5 || ^11.0" --no-update
    echo -e "${GREEN}✓ Added phpunit/phpunit${NC}"
fi

composer update --no-progress

# 2. Create directory structure
echo -e "${YELLOW}[2/6] Creating directory structure...${NC}"
mkdir -p "${PROJECT_DIR}/Tests/Unit"
mkdir -p "${PROJECT_DIR}/Tests/Functional/Fixtures"
mkdir -p "${PROJECT_DIR}/Build/phpunit"
mkdir -p "${PROJECT_DIR}/Build/Scripts"
echo -e "${GREEN}✓ Directories created${NC}"

# 3. Copy PHPUnit configurations
echo -e "${YELLOW}[3/6] Installing PHPUnit configurations...${NC}"
if [ ! -f "${PROJECT_DIR}/Build/phpunit/UnitTests.xml" ]; then
    cp "${SKILL_DIR}/templates/UnitTests.xml" "${PROJECT_DIR}/Build/phpunit/"
    echo -e "${GREEN}✓ Created UnitTests.xml${NC}"
else
    echo -e "${YELLOW}⚠ UnitTests.xml already exists (skipped)${NC}"
fi

if [ ! -f "${PROJECT_DIR}/Build/phpunit/FunctionalTests.xml" ]; then
    cp "${SKILL_DIR}/templates/FunctionalTests.xml" "${PROJECT_DIR}/Build/phpunit/"
    echo -e "${GREEN}✓ Created FunctionalTests.xml${NC}"
else
    echo -e "${YELLOW}⚠ FunctionalTests.xml already exists (skipped)${NC}"
fi

if [ ! -f "${PROJECT_DIR}/Build/phpunit/FunctionalTestsBootstrap.php" ]; then
    cp "${SKILL_DIR}/templates/FunctionalTestsBootstrap.php" "${PROJECT_DIR}/Build/phpunit/"
    echo -e "${GREEN}✓ Created FunctionalTestsBootstrap.php${NC}"
else
    echo -e "${YELLOW}⚠ FunctionalTestsBootstrap.php already exists (skipped)${NC}"
fi

# 4. Create AGENTS.md templates
echo -e "${YELLOW}[4/6] Creating AGENTS.md templates...${NC}"
for dir in "${PROJECT_DIR}/Tests/Unit" "${PROJECT_DIR}/Tests/Functional"; do
    if [ ! -f "${dir}/AGENTS.md" ]; then
        cp "${SKILL_DIR}/templates/AGENTS.md" "${dir}/"
        echo -e "${GREEN}✓ Created ${dir}/AGENTS.md${NC}"
    else
        echo -e "${YELLOW}⚠ ${dir}/AGENTS.md already exists (skipped)${NC}"
    fi
done

# 5. Setup composer scripts
echo -e "${YELLOW}[5/6] Adding composer test scripts...${NC}"
if ! grep -q "ci:test:php:unit" "${PROJECT_DIR}/composer.json"; then
    echo -e "${GREEN}ℹ Add these scripts to your composer.json:${NC}"
    cat << 'EOF'

"scripts": {
    "ci:test": [
        "@ci:test:php:lint",
        "@ci:test:php:phpstan",
        "@ci:test:php:unit",
        "@ci:test:php:functional"
    ],
    "ci:test:php:lint": "phplint",
    "ci:test:php:phpstan": "phpstan analyze --configuration Build/phpstan.neon --no-progress",
    "ci:test:php:unit": "phpunit -c Build/phpunit/UnitTests.xml",
    "ci:test:php:functional": "phpunit -c Build/phpunit/FunctionalTests.xml"
}
EOF
else
    echo -e "${GREEN}✓ Test scripts already configured${NC}"
fi

# 6. Setup acceptance testing if requested
if [ "${WITH_ACCEPTANCE}" = true ]; then
    echo -e "${YELLOW}[6/6] Setting up acceptance testing...${NC}"

    # Install Codeception
    if ! grep -q "codeception/codeception" "${PROJECT_DIR}/composer.json"; then
        composer require --dev codeception/codeception codeception/module-webdriver --no-update
        composer update --no-progress
        echo -e "${GREEN}✓ Installed Codeception${NC}"
    fi

    # Create acceptance test directory
    mkdir -p "${PROJECT_DIR}/Tests/Acceptance"

    # Copy Docker Compose and Codeception config
    if [ ! -f "${PROJECT_DIR}/Build/docker-compose.yml" ]; then
        cp "${SKILL_DIR}/templates/docker/docker-compose.yml" "${PROJECT_DIR}/Build/"
        echo -e "${GREEN}✓ Created docker-compose.yml${NC}"
    fi

    if [ ! -f "${PROJECT_DIR}/codeception.yml" ]; then
        cp "${SKILL_DIR}/templates/docker/codeception.yml" "${PROJECT_DIR}/"
        echo -e "${GREEN}✓ Created codeception.yml${NC}"
    fi

    # Initialize Codeception
    if [ ! -d "${PROJECT_DIR}/Tests/Acceptance/_support" ]; then
        vendor/bin/codecept bootstrap
        echo -e "${GREEN}✓ Initialized Codeception${NC}"
    fi
else
    echo -e "${YELLOW}[6/6] Skipping acceptance testing setup (use -a flag to include)${NC}"
fi

echo
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo
echo "Next steps:"
echo "1. Generate your first test:"
echo "   ${SKILL_DIR}/scripts/generate-test.sh unit MyClass"
echo
echo "2. Run tests:"
echo "   composer ci:test:php:unit"
echo "   composer ci:test:php:functional"
echo
echo "3. Add CI/CD workflow (optional):"
echo "   cp ${SKILL_DIR}/templates/github-actions-tests.yml .github/workflows/tests.yml"
