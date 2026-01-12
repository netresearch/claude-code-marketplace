# TYPO3 Testing Standards

**Purpose:** Conformance validation criteria for TYPO3 extension testing
**Implementation Guide:** Use the `typo3-testing` skill for templates and patterns

## Testing Framework Requirements

Extensions MUST use **typo3/testing-framework** for comprehensive testing:

```bash
composer require --dev "typo3/testing-framework:^9.0"
```

## runTests.sh Requirements (REQUIRED)

Extensions **MUST** have a Docker-based `Build/Scripts/runTests.sh` following TYPO3 core conventions:

### Required Capabilities
- [ ] Uses `ghcr.io/typo3/core-testing-php*` images
- [ ] Supports `-s unit` for unit tests
- [ ] Supports `-s functional` for functional tests
- [ ] Supports `-d sqlite|mariadb|mysql|postgres` for database selection
- [ ] Supports `-p 8.2|8.3|8.4|8.5` for PHP version selection
- [ ] Auto-detects CI/non-TTY environments
- [ ] Handles database container orchestration

### Verification
```bash
# Check script exists and is executable
test -x Build/Scripts/runTests.sh

# Verify help output
Build/Scripts/runTests.sh -h | grep -q "sqlite"

# Run unit tests
Build/Scripts/runTests.sh -s unit

# Run functional tests (SQLite default)
Build/Scripts/runTests.sh -s functional
```

### Makefile Integration (Recommended)
```makefile
RUNTESTS = Build/Scripts/runTests.sh

test: unit
unit:
	$(RUNTESTS) -s unit

functional:
	$(RUNTESTS) -s functional

ci: lint phpstan unit
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
- [ ] Singleton instances reset between tests (see Singleton Testability below)
- [ ] `tearDown()` uses try-catch for incomplete setUp() scenarios

### Singleton Testability Pattern

Singletons can cause test isolation failures when state persists between tests.

**Problem Detection:**
```bash
# Find singleton usage that may need reset
grep -rn "GeneralUtility::makeInstance.*Singleton" Tests/
grep -rn "::getInstance()" Tests/
```

**Solution Pattern:**
```php
protected function setUp(): void
{
    parent::setUp();
    // Reset singleton before each test
    GeneralUtility::purgeInstances();
    // Or reset specific singleton
    GeneralUtility::removeSingletonInstance(
        MyService::class,
        GeneralUtility::makeInstance(MyService::class)
    );
}
```

**Safe tearDown() Pattern:**
```php
protected function tearDown(): void
{
    try {
        // Cleanup that depends on setUp() completion
        $this->cleanupTestData();
    } catch (\Throwable $e) {
        // setUp() may have failed, ignore cleanup errors
    }
    parent::tearDown();
}
```

**Severity:** Medium (causes intermittent test failures)

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
- [ ] Uses `Build/Scripts/runTests.sh` for all test execution
- [ ] PHP lint check (`-s lint`)
- [ ] Unit tests (`-s unit`)
- [ ] Functional tests (`-s functional`, SQLite default)
- [ ] PHPStan analysis (`-s phpstan`, level 5+)
- [ ] Code style check (`-s cgl -n`)

### GitHub Actions Example
```yaml
jobs:
  tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        php: ['8.2', '8.3', '8.4']
    steps:
      - uses: actions/checkout@v4
      - run: Build/Scripts/runTests.sh -p ${{ matrix.php }} -s unit
      - run: Build/Scripts/runTests.sh -p ${{ matrix.php }} -s functional
```

### E2E Pipeline (when Playwright tests exist)
- [ ] Node.js 22.x setup
- [ ] Playwright browser installation
- [ ] TYPO3 instance running
- [ ] Test report artifact upload

## Conformance Scoring

| Criteria | Points |
|----------|--------|
| Docker-based `runTests.sh` present | 10 |
| Unit tests present and passing | 10 |
| Functional tests present and passing | 10 |
| E2E tests present and passing | 5 |
| Accessibility tests present | 5 |
| CI/CD using runTests.sh | 5 |
| Test coverage >70% | 5 |
| **Total** | **50** |

### runTests.sh Scoring Details
| Capability | Points |
|------------|--------|
| Script exists and executable | 2 |
| Supports `-s unit` and `-s functional` | 2 |
| Supports database selection (`-d`) | 2 |
| Supports PHP version (`-p`) | 2 |
| CI/non-TTY auto-detection | 2 |

### Rating
- **Excellent**: 45-50 points
- **Good**: 35-44 points
- **Acceptable**: 25-34 points
- **Needs Work**: <25 points
