#!/usr/bin/env bash

#
# Generate TYPO3 test class
#
# Usage: ./generate-test.sh <type> <ClassName>
# Example: ./generate-test.sh unit EmailValidator
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
TEST_TYPE="$1"
CLASS_NAME="$2"

if [ -z "${TEST_TYPE}" ] || [ -z "${CLASS_NAME}" ]; then
    echo "Usage: $0 <type> <ClassName>"
    echo
    echo "Types:"
    echo "  unit         - Unit test (fast, no database)"
    echo "  functional   - Functional test (with database)"
    echo "  acceptance   - Acceptance test (browser-based)"
    echo
    echo "Example:"
    echo "  $0 unit EmailValidator"
    echo "  $0 functional ProductRepository"
    echo "  $0 acceptance LoginCest"
    exit 1
fi

# Validate test type
case ${TEST_TYPE} in
    unit|functional|acceptance)
        ;;
    *)
        echo -e "${RED}Error: Invalid test type '${TEST_TYPE}'${NC}"
        echo "Valid types: unit, functional, acceptance"
        exit 1
        ;;
esac

# Determine paths
PROJECT_DIR="$(pwd)"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check if Tests directory exists
if [ ! -d "${PROJECT_DIR}/Tests" ]; then
    echo -e "${RED}Error: Tests directory not found${NC}"
    echo "Run setup-testing.sh first"
    exit 1
fi

# Set target directory based on test type
case ${TEST_TYPE} in
    unit)
        TEST_DIR="${PROJECT_DIR}/Tests/Unit"
        TEST_SUFFIX="Test"
        ;;
    functional)
        TEST_DIR="${PROJECT_DIR}/Tests/Functional"
        TEST_SUFFIX="Test"
        ;;
    acceptance)
        TEST_DIR="${PROJECT_DIR}/Tests/Acceptance"
        TEST_SUFFIX="Cest"
        ;;
esac

# Extract namespace from composer.json
NAMESPACE=$(php -r '
    $composer = json_decode(file_get_contents("composer.json"), true);
    foreach ($composer["autoload"]["psr-4"] ?? [] as $ns => $path) {
        if (strpos($path, "Classes") !== false) {
            echo rtrim($ns, "\\");
            break;
        }
    }
')

if [ -z "${NAMESPACE}" ]; then
    echo -e "${RED}Error: Could not determine namespace from composer.json${NC}"
    exit 1
fi

# Determine test file path
TEST_FILE="${TEST_DIR}/${CLASS_NAME}${TEST_SUFFIX}.php"

# Check if file already exists
if [ -f "${TEST_FILE}" ]; then
    echo -e "${RED}Error: Test file already exists: ${TEST_FILE}${NC}"
    exit 1
fi

# Create test file directory if needed
mkdir -p "$(dirname "${TEST_FILE}")"

echo -e "${GREEN}Generating ${TEST_TYPE} test for ${CLASS_NAME}...${NC}"

# Generate test class based on type
case ${TEST_TYPE} in
    unit)
        cat > "${TEST_FILE}" << EOF
<?php

declare(strict_types=1);

namespace ${NAMESPACE}\\Tests\\Unit;

use TYPO3\\TestingFramework\\Core\\Unit\\UnitTestCase;
use ${NAMESPACE}\\${CLASS_NAME};

/**
 * Unit test for ${CLASS_NAME}
 */
final class ${CLASS_NAME}${TEST_SUFFIX} extends UnitTestCase
{
    protected ${CLASS_NAME} \$subject;

    protected function setUp(): void
    {
        parent::setUp();
        \$this->subject = new ${CLASS_NAME}();
    }

    /**
     * @test
     */
    public function canBeInstantiated(): void
    {
        self::assertInstanceOf(${CLASS_NAME}::class, \$this->subject);
    }
}
EOF
        ;;

    functional)
        cat > "${TEST_FILE}" << EOF
<?php

declare(strict_types=1);

namespace ${NAMESPACE}\\Tests\\Functional;

use TYPO3\\TestingFramework\\Core\\Functional\\FunctionalTestCase;
use ${NAMESPACE}\\${CLASS_NAME};

/**
 * Functional test for ${CLASS_NAME}
 */
final class ${CLASS_NAME}${TEST_SUFFIX} extends FunctionalTestCase
{
    protected ${CLASS_NAME} \$subject;

    protected array \$testExtensionsToLoad = [
        'typo3conf/ext/your_extension',
    ];

    protected function setUp(): void
    {
        parent::setUp();
        \$this->subject = \$this->get(${CLASS_NAME}::class);
    }

    /**
     * @test
     */
    public function canBeInstantiated(): void
    {
        self::assertInstanceOf(${CLASS_NAME}::class, \$this->subject);
    }
}
EOF

        # Create fixture file
        FIXTURE_FILE="${PROJECT_DIR}/Tests/Functional/Fixtures/${CLASS_NAME}.csv"
        if [ ! -f "${FIXTURE_FILE}" ]; then
            echo "# Fixture for ${CLASS_NAME}${TEST_SUFFIX}" > "${FIXTURE_FILE}"
            echo -e "${GREEN}✓ Created fixture: ${FIXTURE_FILE}${NC}"
        fi
        ;;

    acceptance)
        cat > "${TEST_FILE}" << EOF
<?php

declare(strict_types=1);

namespace ${NAMESPACE}\\Tests\\Acceptance;

use ${NAMESPACE}\\Tests\\Acceptance\\AcceptanceTester;

/**
 * Acceptance test for ${CLASS_NAME/Cest/} workflow
 */
final class ${CLASS_NAME}${TEST_SUFFIX}
{
    public function _before(AcceptanceTester \$I): void
    {
        // Setup before each test
    }

    public function exampleTest(AcceptanceTester \$I): void
    {
        \$I->amOnPage('/');
        \$I->see('Welcome');
    }
}
EOF
        ;;
esac

echo -e "${GREEN}✓ Created: ${TEST_FILE}${NC}"
echo
echo "Run test:"
echo "  vendor/bin/phpunit ${TEST_FILE}"
echo
echo "Or via composer:"
echo "  composer ci:test:php:${TEST_TYPE}"
