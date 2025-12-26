---
name: typo3-testing
description: "Agent Skill: TYPO3 extension testing (unit, functional, E2E, fuzz, mutation). Use when setting up test infrastructure, writing tests, configuring PHPUnit, or CI/CD. By Netresearch."
---

# TYPO3 Testing Skill

Templates, scripts, and references for comprehensive TYPO3 extension testing.

## Test Type Selection

| Type | Use When | Speed |
|------|----------|-------|
| **Unit** | Pure logic, no DB, validators, utilities | Fast (ms) |
| **Functional** | DB interactions, repositories, controllers | Medium (s) |
| **E2E (Playwright)** | User workflows, browser, accessibility | Slow (s-min) |
| **Fuzz** | Security, parsers, malformed input | Manual |
| **Mutation** | Test quality verification, 70%+ coverage | CI/Release |

## Commands

```bash
# Setup infrastructure
scripts/setup-testing.sh [--with-e2e]

# Generate test class
scripts/generate-test.sh <type> <ClassName>

# Run tests via runTests.sh
Build/Scripts/runTests.sh -s unit
Build/Scripts/runTests.sh -s functional
Build/Scripts/runTests.sh -s e2e

# Quality tools
Build/Scripts/runTests.sh -s lint
Build/Scripts/runTests.sh -s phpstan
Build/Scripts/runTests.sh -s mutation
```

## References

- `references/unit-testing.md` - UnitTestCase, mocking, assertions
- `references/functional-testing.md` - FunctionalTestCase, fixtures, database
- `references/functional-test-patterns.md` - Container reset, PHPUnit 10+ migration
- `references/e2e-testing.md` - Playwright, Page Object Model
- `references/accessibility-testing.md` - axe-core, WCAG compliance
- `references/fuzz-testing.md` - nikic/php-fuzzer, security
- `references/mutation-testing.md` - Infection, test quality
- `references/ci-cd.md` - GitHub Actions, GitLab CI

## Templates

- `templates/UnitTests.xml`, `templates/FunctionalTests.xml` - PHPUnit configs
- `templates/Build/playwright/` - Playwright setup
- `templates/runTests.sh` - Test orchestration
- `templates/github-actions-tests.yml` - CI workflow

## External Resources

- [TYPO3 Testing Docs](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/)
- [Tea Extension](https://github.com/TYPO3BestPractices/tea) - Reference implementation

---

> **Contributing:** https://github.com/netresearch/typo3-testing-skill
