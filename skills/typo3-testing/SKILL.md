---
name: typo3-testing
description: "Agent Skill: Create, configure, and manage TYPO3 extension tests (unit, functional, E2E, fuzz, mutation) following official TYPO3 testing framework patterns. Use when setting up test infrastructure, writing test cases, configuring PHPUnit, managing fixtures, or integrating CI/CD pipelines. Covers PHPUnit 11/12, TYPO3 v12/v13 LTS, Playwright E2E with axe-core, nikic/php-fuzzer, Infection mutation testing, and quality tooling (PHPStan level 10, Rector, php-cs-fixer). By Netresearch."
---

# TYPO3 Testing Skill

## Overview

Provides templates, scripts, and reference documentation for implementing comprehensive TYPO3 extension testing following official patterns and community best practices.

## Quick Start Decision Tree

### 1. What do you need?

```
├─ Create new test
│  ├─ Unit test (no database, fast)
│  ├─ Functional test (with database)
│  ├─ E2E test (Playwright browser automation)
│  ├─ Fuzz test (security, input mutation)
│  └─ Mutation test (test quality verification)
│
├─ Setup testing infrastructure
│  ├─ Basic (unit + functional)
│  └─ Full (+ E2E with Playwright)
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

**E2E Tests (Playwright)** → Use when:
- Testing complete user workflows
- Browser interaction required
- Frontend functionality validation
- Accessibility testing with axe-core
- Execution time: seconds to minutes

**Fuzz Tests (php-fuzzer)** → Use when:
- Testing HTML/XML parsers
- Security-critical input handling
- Finding crashes with malformed input
- DOMDocument-based code
- Run manually before releases

**Mutation Tests (Infection)** → Use when:
- Verifying test suite quality
- After achieving 70%+ code coverage
- Finding weak/missing test assertions
- Critical code paths require validation
- Run in CI or before releases

### 3. Infrastructure exists?

**No** → Run setup script:
```bash
# Basic setup (unit + functional)
scripts/setup-testing.sh

# With E2E testing (Playwright)
scripts/setup-testing.sh --with-e2e
```

**Yes** → Generate test:
```bash
# Generate test class
scripts/generate-test.sh <type> <ClassName>

# Examples:
scripts/generate-test.sh unit UserValidator
scripts/generate-test.sh functional ProductRepository
scripts/generate-test.sh e2e backend-module
```

## Commands

### Setup Testing Infrastructure
```bash
scripts/setup-testing.sh [--with-e2e]
```
Creates:
- composer.json dependencies
- Build/phpunit/ configs
- Build/Scripts/runTests.sh
- Tests/ directory structure
- .github/workflows/ CI configs (optional)
- Build/playwright.config.ts (with --with-e2e)

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
- Node.js/Playwright availability (for E2E tests)

## Test Execution

### via runTests.sh (Recommended)
```bash
# Unit tests
Build/Scripts/runTests.sh -s unit

# Functional tests
Build/Scripts/runTests.sh -s functional

# E2E tests (Playwright)
Build/Scripts/runTests.sh -s e2e

# All quality checks
Build/Scripts/runTests.sh -s lint
Build/Scripts/runTests.sh -s phpstan
Build/Scripts/runTests.sh -s cgl

# Fuzz tests (security)
Build/Scripts/runTests.sh -s fuzz

# Mutation tests (test quality)
Build/Scripts/runTests.sh -s mutation
```

### via Composer/npm
```bash
# All PHP tests
composer ci:test

# Specific suites
composer ci:test:php:unit
composer ci:test:php:functional

# E2E tests (Playwright)
cd Build && npm run playwright:run

# Quality tools
composer ci:test:php:lint
composer ci:test:php:phpstan
composer ci:test:php:cgl

# Fuzz tests (security - manual runs)
composer ci:fuzz

# Mutation tests (test quality)
composer ci:test:mutation
```

## References

Detailed documentation for each testing aspect:

- [Unit Testing](references/unit-testing.md) - UnitTestCase patterns, mocking, assertions
- [Functional Testing](references/functional-testing.md) - FunctionalTestCase, fixtures, database
- [Functional Test Patterns](references/functional-test-patterns.md) - Container reset, PHPUnit 10+ migration, DDEV setup
- [E2E Testing](references/e2e-testing.md) - Playwright, Page Object Model, browser automation
- [Accessibility Testing](references/accessibility-testing.md) - axe-core, WCAG compliance
- [JavaScript Testing](references/javascript-testing.md) - CKEditor plugins, data-* attributes, frontend tests
- [Fuzz Testing](references/fuzz-testing.md) - nikic/php-fuzzer, security testing, input mutation
- [Mutation Testing](references/mutation-testing.md) - Infection, test quality verification, code mutation
- [Test Runners](references/test-runners.md) - runTests.sh orchestration patterns
- [CI/CD Integration](references/ci-cd.md) - GitHub Actions, GitLab CI workflows
- [Quality Tools](references/quality-tools.md) - PHPStan, Rector, php-cs-fixer

## Templates

Ready-to-use configuration files and examples:

### PHPUnit Templates
- `templates/UnitTests.xml` - PHPUnit config for unit tests
- `templates/FunctionalTests.xml` - PHPUnit config for functional tests
- `templates/FunctionalTestsBootstrap.php` - Bootstrap for functional tests

### Playwright Templates
- `templates/Build/playwright/playwright.config.ts` - Playwright configuration
- `templates/Build/playwright/package.json` - Node.js dependencies
- `templates/Build/playwright/.nvmrc` - Node version (22.18)
- `templates/Build/playwright/tests/playwright/config.ts` - TYPO3-specific config
- `templates/Build/playwright/tests/playwright/helper/login.setup.ts` - Auth setup
- `templates/Build/playwright/tests/playwright/fixtures/setup-fixtures.ts` - Page Objects
- `templates/Build/playwright/tests/playwright/e2e/` - E2E test examples
- `templates/Build/playwright/tests/playwright/accessibility/` - Accessibility tests

### Other Templates
- `templates/AGENTS.md` - AI assistant context template for test directories
- `templates/runTests.sh` - Test orchestration script
- `templates/github-actions-tests.yml` - GitHub Actions workflow
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

Apply these patterns when organizing tests:
1. Group tests by feature or domain, not by test type
2. Name unit and functional tests with `*Test.php` suffix
3. Name E2E tests with `*.spec.ts` suffix
4. Keep fixtures minimal, reusable, and well-documented
5. Prefer specific assertions (assertSame, assertInstanceOf) over generic assertEquals
6. Ensure each test runs independently without side effects
7. Apply setUp() and tearDown() methods consistently across test classes
8. Document test strategy in AGENTS.md for each test directory

## Troubleshooting

**Tests not found:**
- Check PHPUnit XML testsuites configuration
- Verify test class extends correct base class
- Check file naming convention (*Test.php for PHP, *.spec.ts for Playwright)

**Database errors in functional tests:**
- Verify database driver in FunctionalTests.xml
- Check fixture CSV format (proper escaping)
- Ensure bootstrap file is configured

**E2E tests fail:**
- Verify Node.js 22.18+ installed (`node --version`)
- Run `npm run playwright:install` to install browsers
- Check Playwright config baseURL matches your TYPO3 instance
- Ensure TYPO3 backend is running and accessible

## External References

Consult these resources for additional context:

| Resource | Use For |
|----------|---------|
| [TYPO3 Testing Documentation](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/) | Official framework usage, best practices, version requirements |
| [TYPO3 Testing Framework](https://github.com/typo3/testing-framework) | Framework API, base test cases, fixture utilities |
| [Tea Extension](https://github.com/TYPO3BestPractices/tea) | Production-quality examples, complete infrastructure setup |
| [PHPUnit Documentation](https://phpunit.de/documentation.html) | Assertions, test doubles, configuration |
| [Playwright Documentation](https://playwright.dev/docs/intro) | Browser automation, Page Object Model |
| [TYPO3 Core Playwright Tests](https://github.com/TYPO3/typo3/tree/main/Build/tests/playwright) | E2E patterns, authentication, accessibility testing |
