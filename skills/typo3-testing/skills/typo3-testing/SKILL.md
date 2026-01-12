---
name: typo3-testing
description: "Agent Skill: TYPO3 extension testing (unit, functional, E2E, architecture, mutation). Use when setting up test infrastructure, writing tests, configuring PHPUnit, or CI/CD. By Netresearch."
---

# TYPO3 Testing Skill

Templates, scripts, and references for comprehensive TYPO3 extension testing.

## Test Type Selection

To select the appropriate test type, use this decision table:

| Type | Use When | Speed |
|------|----------|-------|
| **Unit** | Pure logic, no DB, validators, utilities | Fast (ms) |
| **Functional** | DB interactions, repositories, controllers | Medium (s) |
| **Architecture** | Layer constraints, dependency rules (phpat) | Fast (ms) |
| **E2E (Playwright)** | User workflows, browser, accessibility | Slow (s-min) |
| **Integration** | HTTP client, API mocking, OAuth flows | Medium (ms) |
| **Fuzz** | Security, parsers, malformed input | Manual |
| **Crypto** | Encryption, secrets, key management | Fast (ms) |
| **Mutation** | Test quality verification, 70%+ coverage | CI/Release |

## Setting Up Test Infrastructure

To initialize testing infrastructure for an extension, run:

```bash
scripts/setup-testing.sh [--with-e2e]
```

To validate an existing setup, run:

```bash
scripts/validate-setup.sh
```

To generate a new test file, run:

```bash
scripts/generate-test.sh <TestType> <ClassName>
```

## Running Tests

To execute tests via the Docker-based runner, use these commands:

```bash
# Unit tests
Build/Scripts/runTests.sh -s unit

# Functional tests
Build/Scripts/runTests.sh -s functional

# Architecture tests (phpat)
Build/Scripts/runTests.sh -s architecture

# E2E tests (Playwright)
Build/Scripts/runTests.sh -s e2e

# Quality tools
Build/Scripts/runTests.sh -s lint
Build/Scripts/runTests.sh -s phpstan
Build/Scripts/runTests.sh -s mutation
```

## Scoring Requirements

To achieve full conformance scores, ensure:

| Criterion | Requirement |
|-----------|-------------|
| Unit tests | Required, 70%+ coverage |
| Functional tests | Required for DB operations |
| Architecture tests | **phpat required** for full points |
| PHPStan | Level 10 (max) |

> **Note:** Full conformance requires phpat architecture tests enforcing layer boundaries.

## Using Reference Documentation

### Core Testing References

When writing unit tests, consult `references/unit-testing.md` for UnitTestCase patterns, mocking strategies, and assertion examples.

When writing functional tests, consult `references/functional-testing.md` for FunctionalTestCase setup, CSV fixtures, and database testing patterns.

When migrating to PHPUnit 10+ or fixing container issues, consult `references/functional-test-patterns.md` for container reset patterns and migration guides.

When testing HTTP clients or external APIs, consult `references/integration-testing.md` for PSR-18 mocking, OAuth flow testing, and request capturing.

When writing browser-based E2E tests, consult `references/e2e-testing.md` for Playwright setup, Page Object Model patterns, and PHP-based E2E alternatives.

When setting up DDEV for testing, consult `references/ddev-testing.md` for multi-version matrix testing, Playwright integration, and CI/CD with DDEV.

When configuring test runners, consult `references/test-runners.md` for runTests.sh customization and Docker orchestration.

### Specialized Testing References

When enforcing architecture rules, consult `references/architecture-testing.md` for phpat configuration, layer constraints, and dependency rules.

When testing accessibility, consult `references/accessibility-testing.md` for axe-core integration and WCAG compliance testing.

When testing parsers or security-critical code, consult `references/fuzz-testing.md` for nikic/php-fuzzer patterns and malformed input generation.

When testing encryption or secrets, consult `references/crypto-testing.md` for sodium testing patterns and key management verification.

When measuring test quality, consult `references/mutation-testing.md` for Infection configuration and MSI interpretation.

When benchmarking performance, consult `references/performance-testing.md` for timing measurements, memory leak detection, and throughput testing.

### TYPO3 Specific References

When testing against TYPO3 v14 final/readonly classes, consult `references/typo3-v14-final-classes.md` for interface extraction and mock strategies.

When writing JavaScript/TypeScript tests, consult `references/javascript-testing.md` for Jest and frontend testing patterns.

### Quality & CI References

When configuring static analysis, consult `references/quality-tools.md` for PHPStan, PHP-CS-Fixer, and Rector setup.

When setting up CI/CD pipelines, consult `references/ci-cd.md` for GitHub Actions and GitLab CI workflows.

When integrating SonarCloud, consult `references/sonarcloud.md` for quality gate configuration.

## Using Asset Templates

### Infrastructure Setup

To set up Docker-based test orchestration, copy `assets/Build/Scripts/runTests.sh` to your extension. This is the **required** foundation for all test execution.

To initialize test bootstrapping, use these templates:
- `assets/bootstrap.php` - General test bootstrap with autoloader detection
- `assets/UnitTestsBootstrap.php` - Unit test bootstrap with optional TYPO3 stub autoloader
- `assets/FunctionalTestsBootstrap.php` - Functional test bootstrap for TYPO3 testing framework

### PHPUnit Configuration

To configure PHPUnit, copy and customize:
- `assets/UnitTests.xml` - Unit test suite configuration
- `assets/FunctionalTests.xml` - Functional test suite configuration

### Code Quality Tools

To set up static analysis and code style, use:
- `assets/phpstan.neon` - PHPStan level 10 configuration
- `assets/phpstan-baseline.neon` - Baseline template for legacy code migration
- `assets/phpat.php` - Architecture test rules for layer enforcement
- `assets/phpat.neon` - PHPat PHPStan extension configuration
- `assets/.php-cs-fixer.dist.php` - PHP-CS-Fixer code style rules
- `assets/rector.php` - Rector automated refactoring configuration

### Mutation Testing & Coverage

To configure mutation testing, copy `assets/infection.json5` and adjust mutator settings and MSI thresholds.

To configure coverage reporting, copy `assets/codecov.yml` for Codecov integration.

### CI/CD Workflows

To set up GitHub Actions, use:
- `assets/github-actions-tests.yml` - Main CI workflow (lint, phpstan, unit, functional tests)
- `assets/github-actions-e2e.yml` - E2E workflow with DDEV and Playwright

### E2E Testing Setup

To set up Playwright E2E testing, copy the `assets/Build/playwright/` directory containing:
- `package.json` - Node.js dependencies
- `playwright.config.ts` - Playwright configuration
- `tests/playwright/` - Test structure with login setup, fixtures, and example specs

### Development Shortcuts

To add common command shortcuts, copy `assets/Makefile` for make-based task execution.

### Docker Services

To configure additional Docker services for testing, use templates from `assets/docker/`:
- `docker-compose.yml` - Base Docker Compose configuration
- `codeception.yml` - Codeception-specific Docker setup

### Example Tests

To see test patterns in action, review examples in `assets/example-tests/`:
- `ExampleUnitTest.php` - Unit test structure and assertions
- `ExampleFunctionalTest.php` - Functional test with fixtures
- `ExampleAcceptanceCest.php` - Codeception acceptance test

### Database Fixtures

To set up test data, use CSV fixtures from `assets/fixtures/`:
- `be_users.csv` - Backend user fixture with password hashes
- `pages.csv` - Page tree structure
- `tt_content.csv` - Content elements
- `sys_category.csv` - Category hierarchy

Consult `assets/fixtures/README.md` for fixture format documentation.

### AI Agent Documentation

To document AI agent behavior for your extension, use `assets/AGENTS.md` as a template.

## External Resources

When understanding TYPO3 testing patterns, consult the [TYPO3 Testing Documentation](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/).

When seeking reference implementations, study the [Tea Extension](https://github.com/TYPO3BestPractices/tea).

When implementing architecture tests, consult [phpat documentation](https://github.com/carlosas/phpat).

When configuring mutation testing, consult [Infection PHP documentation](https://infection.github.io/).

When setting up DDEV environments, consult [DDEV documentation](https://ddev.readthedocs.io/).

---

> **Contributing:** https://github.com/netresearch/typo3-testing-skill
