# TYPO3 Testing Standards

**Purpose:** Conformance validation criteria for TYPO3 extension testing
**Implementation Guide:** Use the `typo3-testing` skill for templates and patterns

## Testing Framework Requirements

Extensions MUST use **typo3/testing-framework** for comprehensive testing:

```bash
composer require --dev "typo3/testing-framework":"^8.0.9" "phpunit/phpunit":"^10.5"
```

## Unit Test Conformance

### Required Structure
- [ ] Tests extend `TYPO3\TestingFramework\Core\Unit\UnitTestCase`
- [ ] Located in `Tests/Unit/` mirroring `Classes/` structure
- [ ] Files named `<ClassName>Test.php`
- [ ] PHPUnit config at `Build/phpunit/UnitTests.xml`

### Quality Criteria
- [ ] No database access
- [ ] No file system access
- [ ] No external HTTP requests
- [ ] All public methods tested
- [ ] Edge cases and boundaries covered
- [ ] Uses `#[Test]` attribute (PHP 8.0+) or `@test` annotation
- [ ] Descriptive test method names: `methodName<Condition>Returns<Expected>`

## Functional Test Conformance

### Required Structure
- [ ] Tests extend `TYPO3\TestingFramework\Core\Functional\FunctionalTestCase`
- [ ] Located in `Tests/Functional/`
- [ ] PHPUnit config at `Build/phpunit/FunctionalTests.xml`
- [ ] Fixtures in `Tests/Functional/Fixtures/` (CSV format)

### Quality Criteria
- [ ] `setUp()` calls `parent::setUp()` first
- [ ] Extensions loaded via `$testExtensionsToLoad`
- [ ] Test data loaded via `$this->importCSVDataSet()`
- [ ] Backend user initialized when testing backend operations
- [ ] Tests database operations with proper assertions
- [ ] Fixtures minimal and well-documented

## E2E Test Conformance (Playwright)

**Reference:** [TYPO3 Core Playwright Tests](https://github.com/TYPO3/typo3/tree/main/Build/tests/playwright)

### Required Structure
- [ ] Configuration at `Build/playwright.config.ts`
- [ ] Tests in `Build/tests/playwright/e2e/`
- [ ] Files named `<feature>.spec.ts`
- [ ] Node.js version >=22.18 in `.nvmrc`
- [ ] Dependencies in `Build/package.json`

### Required Dependencies
```json
{
  "devDependencies": {
    "@playwright/test": "^1.56.1",
    "@axe-core/playwright": "^4.9.0"
  }
}
```

### Quality Criteria
- [ ] Authentication setup in `helper/login.setup.ts`
- [ ] Page Object Models in `fixtures/` directory
- [ ] Storage state for session persistence
- [ ] Tests verify user-visible behavior
- [ ] Uses specific waits, not `waitForTimeout()`
- [ ] Stable selectors (`data-testid`, roles, not CSS classes)

## Accessibility Test Conformance

### Required Structure
- [ ] Tests in `Build/tests/playwright/accessibility/`
- [ ] Uses `@axe-core/playwright` for WCAG validation
- [ ] Tests all backend modules

### Quality Criteria
- [ ] Runs axe-core analysis on module content
- [ ] Reports violations with severity levels
- [ ] No critical or serious violations in new code
- [ ] Documents any disabled rules with justification

## CI/CD Requirements

### Minimum Pipeline
- [ ] PHP lint check
- [ ] Unit tests
- [ ] Functional tests (SQLite acceptable)
- [ ] PHPStan analysis (level 5+)
- [ ] Code style check (php-cs-fixer)

### E2E Pipeline (when Playwright tests exist)
- [ ] Node.js 22.x setup
- [ ] Playwright browser installation
- [ ] TYPO3 instance running
- [ ] Test report artifact upload

## Conformance Scoring

| Criteria | Points |
|----------|--------|
| Unit tests present and passing | 10 |
| Functional tests present and passing | 10 |
| E2E tests present and passing | 10 |
| Accessibility tests present | 5 |
| CI/CD pipeline configured | 10 |
| Test coverage >70% | 5 |
| **Total** | **50** |

### Rating
- **Excellent**: 45-50 points
- **Good**: 35-44 points
- **Acceptable**: 25-34 points
- **Needs Work**: <25 points
