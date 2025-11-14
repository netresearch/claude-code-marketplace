---
name: typo3-testing
version: 1.1.0
description: Create, configure, and manage TYPO3 extension tests (unit, functional, acceptance) following official TYPO3 testing framework patterns. Use when setting up tests, writing test cases, configuring PHPUnit, managing fixtures, or integrating CI/CD pipelines for TYPO3 extensions. Covers PHPUnit 11/12, TYPO3 v12/v13 LTS, modern dependency injection testing patterns, and comprehensive quality tooling (PHPStan level 10, Rector, php-cs-fixer).
license: Complete terms in LICENSE.txt
---

# TYPO3 Testing Skill

## Purpose

This skill helps developers create, configure, and manage TYPO3 extension tests following official TYPO3 testing framework patterns and community best practices.

## Quick Start Decision Tree

### 1. What do you need?

```
├─ Create new test
│  ├─ Unit test (no database, fast)
│  ├─ Functional test (with database)
│  └─ Acceptance test (browser-based E2E)
│
├─ Setup testing infrastructure
│  ├─ Basic (unit + functional)
│  └─ Full (+ acceptance with Docker)
│
├─ Add CI/CD
│  ├─ GitHub Actions
│  └─ GitLab CI
│
├─ Manage fixtures
│  ├─ Create fixture
│  └─ Update fixture
│
└─ Understand testing patterns
   └─ Check references/
```

### 2. Which test type?

**Unit Tests** → Use when:
- Testing pure logic without external dependencies
- No database access needed
- Fast execution required (milliseconds)
- Examples: Validators, Value Objects, Utilities

**Functional Tests** → Use when:
- Testing database interactions
- Full TYPO3 instance needed
- Testing repositories, controllers, hooks
- Slower execution acceptable (seconds)

**Acceptance Tests** → Use when:
- Testing complete user workflows
- Browser interaction required
- Frontend functionality validation
- Slowest execution (minutes)

### 3. Infrastructure exists?

**No** → Run setup script:
```bash
# Basic setup (unit + functional)
scripts/setup-testing.sh

# With acceptance testing
scripts/setup-testing.sh --with-acceptance
```

**Yes** → Generate test:
```bash
# Generate test class
scripts/generate-test.sh <type> <ClassName>

# Examples:
scripts/generate-test.sh unit UserValidator
scripts/generate-test.sh functional ProductRepository
scripts/generate-test.sh acceptance LoginCest
```

## Commands

### Setup Testing Infrastructure
```bash
scripts/setup-testing.sh [--with-acceptance]
```
Creates:
- composer.json dependencies
- Build/phpunit/ configs
- Build/Scripts/runTests.sh
- Tests/ directory structure
- .github/workflows/ CI configs (optional)
- docker-compose.yml (with --with-acceptance)

### Generate Test Class
```bash
scripts/generate-test.sh <type> <ClassName>
```
Creates:
- Test class file
- Fixture file (for functional tests)
- AGENTS.md in test directory (if missing)

### Validate Setup
```bash
scripts/validate-setup.sh
```
Checks:
- Required composer dependencies
- PHPUnit configuration files
- Test directory structure
- Docker availability (for acceptance tests)

## Test Execution

### via runTests.sh (Recommended)
```bash
# Unit tests
Build/Scripts/runTests.sh -s unit

# Functional tests
Build/Scripts/runTests.sh -s functional

# Acceptance tests
Build/Scripts/runTests.sh -s acceptance

# All quality checks
Build/Scripts/runTests.sh -s lint
Build/Scripts/runTests.sh -s phpstan
Build/Scripts/runTests.sh -s cgl
```

### via Composer
```bash
# All tests
composer ci:test

# Specific suites
composer ci:test:php:unit
composer ci:test:php:functional

# Quality tools
composer ci:test:php:lint
composer ci:test:php:phpstan
composer ci:test:php:cgl
```

## References

Detailed documentation for each testing aspect:

- [Unit Testing](references/unit-testing.md) - UnitTestCase patterns, mocking, assertions
- [Functional Testing](references/functional-testing.md) - FunctionalTestCase, fixtures, database
- [Acceptance Testing](references/acceptance-testing.md) - Codeception, Selenium, page objects
- [JavaScript Testing](references/javascript-testing.md) - CKEditor plugins, data-* attributes, frontend tests
- [Test Runners](references/test-runners.md) - runTests.sh orchestration patterns
- [CI/CD Integration](references/ci-cd.md) - GitHub Actions, GitLab CI workflows
- [Quality Tools](references/quality-tools.md) - PHPStan, Rector, php-cs-fixer

## Templates

Ready-to-use configuration files and examples:

- `templates/AGENTS.md` - AI assistant context template for test directories
- `templates/UnitTests.xml` - PHPUnit config for unit tests
- `templates/FunctionalTests.xml` - PHPUnit config for functional tests
- `templates/FunctionalTestsBootstrap.php` - Bootstrap for functional tests
- `templates/runTests.sh` - Test orchestration script
- `templates/github-actions-tests.yml` - GitHub Actions workflow
- `templates/docker-compose.yml` - Docker services for acceptance tests
- `templates/codeception.yml` - Codeception configuration
- `templates/example-tests/` - Example test classes

## Fixture Management (Functional Tests)

### Create Fixture
1. Create CSV file in `Tests/Functional/Fixtures/`
2. Define database table structure
3. Add test data rows
4. Import in test via `$this->importCSVDataSet()`

### Fixture Strategy
- Keep fixtures minimal (only required data)
- One fixture per test scenario
- Use descriptive names (e.g., `ProductWithCategories.csv`)
- Document fixture purpose in AGENTS.md

## CI/CD Integration

### GitHub Actions
```bash
# Add workflow
cp templates/github-actions-tests.yml .github/workflows/tests.yml

# Customize matrix (PHP versions, TYPO3 versions, databases)
```

### GitLab CI
See `references/ci-cd.md` for GitLab CI example configuration.

## Test Organization Standards

**When organizing tests**, apply these patterns:
1. Group tests by feature or domain, not by test type
2. Name unit and functional tests with `*Test.php` suffix
3. Name acceptance tests with `*Cest.php` suffix
4. Keep fixtures minimal, reusable, and well-documented
5. Use specific assertions (assertSame, assertInstanceOf) over generic assertEquals
6. Ensure each test can run independently without side effects
7. Apply setUp() and tearDown() methods consistently across test classes
8. Document test strategy in AGENTS.md to explain what each directory tests

## Troubleshooting

**Tests not found:**
- Check PHPUnit XML testsuites configuration
- Verify test class extends correct base class
- Check file naming convention (*Test.php)

**Database errors in functional tests:**
- Verify database driver in FunctionalTests.xml
- Check fixture CSV format (proper escaping)
- Ensure bootstrap file is configured

**Acceptance tests fail:**
- Verify Docker and Docker Compose installed
- Check Selenium service is running
- Review Codeception configuration

## Reference Material Usage

**When understanding TYPO3 testing patterns**, read [TYPO3 Testing Documentation](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/) for:
- Official testing framework usage
- Best practices and patterns
- Version-specific requirements

**When working with test framework internals**, check [TYPO3 Testing Framework](https://github.com/typo3/testing-framework) for:
- Framework API reference
- Base test case implementations
- Fixture handling utilities

**When seeking reference implementations**, study [Tea Extension](https://github.com/TYPO3BestPractices/tea) for:
- Production-quality test examples
- Complete testing infrastructure setup
- Best practice patterns in action

**When writing PHPUnit tests**, consult [PHPUnit Documentation](https://phpunit.de/documentation.html) for:
- Assertion methods
- Test doubles and mocking
- Configuration options

**When implementing acceptance tests**, reference [Codeception Documentation](https://codeception.com/docs/) for:
- Page object patterns
- Browser automation
- E2E test scenarios
