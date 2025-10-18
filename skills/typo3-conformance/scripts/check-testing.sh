#!/usr/bin/env bash

#
# TYPO3 Testing Standards Conformance Checker
#
# Validates testing infrastructure and test coverage
#

set -e

PROJECT_DIR="${1:-.}"
cd "${PROJECT_DIR}"

echo "## 4. Testing Standards Conformance"
echo ""

has_issues=0

### Check for Tests directory
echo "### Test Infrastructure"
echo ""

if [ ! -d "Tests" ]; then
    echo "- ❌ Tests/ directory missing (CRITICAL)"
    has_issues=1
    echo ""
    echo "---"
    echo ""
    exit 1
fi

echo "- ✅ Tests/ directory present"

### Check for PHPUnit configuration
echo ""
echo "### PHPUnit Configuration"
echo ""

if [ -f "Build/phpunit/UnitTests.xml" ] || [ -f "phpunit.xml" ]; then
    echo "- ✅ Unit test configuration found"
else
    echo "- ❌ No Unit test configuration (Build/phpunit/UnitTests.xml or phpunit.xml)"
    has_issues=1
fi

if [ -f "Build/phpunit/FunctionalTests.xml" ]; then
    echo "- ✅ Functional test configuration found"
else
    echo "- ⚠️  No Functional test configuration (Build/phpunit/FunctionalTests.xml)"
fi

### Unit Tests
echo ""
echo "### Unit Tests"
echo ""

if [ -d "Tests/Unit" ]; then
    unit_test_count=$(find Tests/Unit/ -name "*Test.php" 2>/dev/null | wc -l)
    echo "- ✅ Tests/Unit/ directory present"
    echo "  - **${unit_test_count} unit test files found**"

    if [ $unit_test_count -eq 0 ]; then
        echo "  - ⚠️  No unit tests found"
    fi

    # Check if tests mirror Classes structure
    if [ -d "Classes/Controller" ] && [ ! -d "Tests/Unit/Controller" ]; then
        echo "  - ⚠️  Tests/Unit/Controller/ missing (Classes/Controller/ exists)"
    fi

    if [ -d "Classes/Service" ] && [ ! -d "Tests/Unit/Service" ]; then
        echo "  - ⚠️  Tests/Unit/Service/ missing (Classes/Service/ exists)"
    fi

    if [ -d "Classes/Domain/Repository" ] && [ ! -d "Tests/Unit/Domain/Repository" ]; then
        echo "  - ⚠️  Tests/Unit/Domain/Repository/ missing (Classes/Domain/Repository/ exists)"
    fi
else
    echo "- ❌ Tests/Unit/ directory missing"
    has_issues=1
fi

### Functional Tests
echo ""
echo "### Functional Tests"
echo ""

if [ -d "Tests/Functional" ]; then
    func_test_count=$(find Tests/Functional/ -name "*Test.php" 2>/dev/null | wc -l)
    echo "- ✅ Tests/Functional/ directory present"
    echo "  - **${func_test_count} functional test files found**"

    # Check for fixtures
    if [ -d "Tests/Functional/Fixtures" ]; then
        fixture_count=$(find Tests/Functional/Fixtures/ -name "*.csv" -o -name "*.xml" 2>/dev/null | wc -l)
        echo "  - ✅ Tests/Functional/Fixtures/ found (${fixture_count} fixture files)"
    else
        if [ $func_test_count -gt 0 ]; then
            echo "  - ⚠️  No Tests/Functional/Fixtures/ (functional tests may need fixtures)"
        fi
    fi
else
    echo "- ⚠️  Tests/Functional/ directory missing"
    echo "  - Functional tests recommended for repository and database operations"
fi

### Acceptance Tests
echo ""
echo "### Acceptance Tests"
echo ""

if [ -d "Tests/Acceptance" ]; then
    accept_test_count=$(find Tests/Acceptance/ -name "*Cest.php" 2>/dev/null | wc -l)
    echo "- ✅ Tests/Acceptance/ directory present"
    echo "  - **${accept_test_count} acceptance test files found**"

    if [ -f "Tests/codeception.yml" ]; then
        echo "  - ✅ codeception.yml configuration found"
    else
        echo "  - ⚠️  codeception.yml configuration missing"
    fi
else
    echo "- ℹ️  Tests/Acceptance/ not found (optional for most extensions)"
fi

### Test Coverage Estimate
echo ""
echo "### Test Coverage Estimate"
echo ""

if [ -d "Classes" ]; then
    class_count=$(find Classes/ -name "*.php" 2>/dev/null | wc -l)

    if [ -d "Tests/Unit" ]; then
        unit_count=$(find Tests/Unit/ -name "*Test.php" 2>/dev/null | wc -l)
    else
        unit_count=0
    fi

    if [ -d "Tests/Functional" ]; then
        func_count=$(find Tests/Functional/ -name "*Test.php" 2>/dev/null | wc -l)
    else
        func_count=0
    fi

    total_tests=$((unit_count + func_count))

    echo "- **Total Classes:** $class_count"
    echo "- **Total Tests:** $total_tests"

    if [ $class_count -gt 0 ]; then
        coverage_ratio=$((total_tests * 100 / class_count))
        echo "- **Test Ratio:** ${coverage_ratio}%"

        if [ $coverage_ratio -ge 70 ]; then
            echo "  - ✅ Good test coverage (≥70%)"
        elif [ $coverage_ratio -ge 50 ]; then
            echo "  - ⚠️  Moderate test coverage (50-70%)"
        else
            echo "  - ❌ Low test coverage (<50%)"
            has_issues=1
        fi
    fi
fi

### Check for testing framework dependency
echo ""
echo "### Testing Framework Dependency"
echo ""

if [ -f "composer.json" ]; then
    if grep -q "typo3/testing-framework" composer.json; then
        echo "- ✅ typo3/testing-framework in composer.json"
    else
        echo "- ⚠️  typo3/testing-framework not found in composer.json"
    fi

    if grep -q "phpunit/phpunit" composer.json; then
        echo "- ✅ phpunit/phpunit in composer.json"
    else
        echo "- ⚠️  phpunit/phpunit not found in composer.json"
    fi
fi

echo ""
echo "### Summary"
echo ""

if [ $has_issues -eq 0 ]; then
    echo "- ✅ **Testing Standards: PASSED**"
else
    echo "- ⚠️  **Testing Standards: ISSUES FOUND**"
fi

echo ""
echo "---"
echo ""

exit $has_issues
