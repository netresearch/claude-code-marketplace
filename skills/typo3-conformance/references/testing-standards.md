# TYPO3 Testing Standards

**Source:** TYPO3 Core API Reference - Testing
**Purpose:** Unit, functional, and acceptance testing standards for TYPO3 extensions

## Testing Framework

TYPO3 uses **typo3/testing-framework** for comprehensive testing:

```bash
# Install testing framework
composer require --dev \
  "typo3/testing-framework":"^8.0.9" \
  "phpunit/phpunit":"^10.5"
```

## Unit Testing

### Unit Test Structure

```php
// ✅ Right: Proper unit test structure
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Tests\Unit\Service;

use TYPO3\TestingFramework\Core\Unit\UnitTestCase;
use Vendor\ExtensionKey\Service\CalculationService;

class CalculationServiceTest extends UnitTestCase
{
    private CalculationService $subject;

    protected function setUp(): void
    {
        parent::setUp();
        $this->subject = new CalculationService();
    }

    /**
     * @test
     */
    public function addReturnsCorrectSum(): void
    {
        $result = $this->subject->add(2, 3);
        $this->assertEquals(5, $result);
    }

    /**
     * @test
     */
    public function multiplyReturnsCorrectProduct(): void
    {
        $result = $this->subject->multiply(4, 5);
        $this->assertEquals(20, $result);
    }
}
```

### PHPUnit Configuration

```xml
<!-- Build/phpunit/UnitTests.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<phpunit
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/10.5/phpunit.xsd"
    bootstrap="../../vendor/typo3/testing-framework/Resources/Core/Build/UnitTestsBootstrap.php"
    colors="true"
    beStrictAboutTestsThatDoNotTestAnything="true"
    failOnWarning="true"
    failOnRisky="true"
    stopOnFailure="false"
>
    <testsuites>
        <testsuite name="Unit tests">
            <directory>../../Tests/Unit/</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

### Running Unit Tests

```bash
# Direct execution
vendor/bin/phpunit -c Build/phpunit/UnitTests.xml

# DDEV execution
ddev exec php vendor/bin/phpunit -c Build/phpunit/UnitTests.xml

# Run specific test
vendor/bin/phpunit -c Build/phpunit/UnitTests.xml --filter "CalculationServiceTest"
```

### Unit Test Best Practices

**✅ Do:**
- Test single units (methods, functions) in isolation
- Mock external dependencies
- Test edge cases and boundary conditions
- Use descriptive test method names
- Follow naming: `methodName<Condition>Returns<Expected>`
- Keep tests fast (no database, no external services)

**❌ Don't:**
- Access database in unit tests
- Depend on file system
- Make HTTP requests
- Test framework internals
- Write integration tests as unit tests

## Functional Testing

### Functional Test Structure

```php
// ✅ Right: Proper functional test structure
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Tests\Functional\Domain\Repository;

use TYPO3\TestingFramework\Core\Functional\FunctionalTestCase;
use Vendor\ExtensionKey\Domain\Repository\ProductRepository;

class ProductRepositoryTest extends FunctionalTestCase
{
    protected array $testExtensionsToLoad = [
        'typo3conf/ext/my_extension',
    ];

    protected ProductRepository $subject;

    protected function setUp(): void
    {
        parent::setUp();

        // Load test data
        $this->importCSVDataSet(__DIR__ . '/Fixtures/products.csv');

        // Set up backend user
        $this->setUpBackendUser(1);

        // Initialize subject
        $this->subject = $this->get(ProductRepository::class);
    }

    /**
     * @test
     */
    public function findAllReturnsAllProducts(): void
    {
        $products = $this->subject->findAll();
        $this->assertCount(3, $products);
    }

    /**
     * @test
     */
    public function findByPriceRangeReturnsMatchingProducts(): void
    {
        $products = $this->subject->findByPriceRange(10.0, 50.0);
        $this->assertCount(2, $products);
    }
}
```

### PHPUnit Functional Configuration

```xml
<!-- Build/phpunit/FunctionalTests.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<phpunit
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/10.5/phpunit.xsd"
    bootstrap="../../vendor/typo3/testing-framework/Resources/Core/Build/FunctionalTestsBootstrap.php"
    colors="true"
    beStrictAboutTestsThatDoNotTestAnything="true"
    failOnWarning="true"
    failOnRisky="true"
    stopOnFailure="false"
>
    <testsuites>
        <testsuite name="Functional tests">
            <directory>../../Tests/Functional/</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

### Running Functional Tests

```bash
# With MySQL/MariaDB
ddev exec \
  typo3DatabaseDriver='mysqli' \
  typo3DatabaseHost='db' \
  typo3DatabasePort=3306 \
  typo3DatabaseUsername='root' \
  typo3DatabasePassword='root' \
  typo3DatabaseName='func' \
  php vendor/bin/phpunit -c Build/phpunit/FunctionalTests.xml

# With SQLite (simpler)
ddev exec \
  typo3DatabaseDriver=pdo_sqlite \
  php vendor/bin/phpunit -c Build/phpunit/FunctionalTests.xml

# With PostgreSQL
ddev exec \
  typo3DatabaseDriver='pdo_pgsql' \
  typo3DatabaseHost='postgres' \
  typo3DatabasePort=5432 \
  typo3DatabaseUsername='postgres' \
  typo3DatabasePassword='postgres' \
  typo3DatabaseName='func' \
  php vendor/bin/phpunit -c Build/phpunit/FunctionalTests.xml
```

### Test Data Fixtures

```csv
# Tests/Functional/Fixtures/products.csv
tx_myext_product,uid,pid,title,price,available
,1,0,Product A,29.99,1
,2,0,Product B,49.99,1
,3,0,Product C,99.99,0
```

### Loading Extensions in Tests

```php
// Load extension under test
protected array $testExtensionsToLoad = [
    'typo3conf/ext/my_extension',
];

// Load additional core extensions
protected array $coreExtensionsToLoad = [
    'typo3/cms-workspaces',
];

// Load fixture extensions
protected array $testExtensionsToLoad = [
    'typo3conf/ext/my_extension',
    'typo3conf/ext/my_extension/Tests/Functional/Fixtures/Extensions/fixture_extension',
];
```

## Acceptance Testing

### Codeception Setup

```yaml
# Tests/codeception.yml
namespace: Vendor\ExtensionKey\Tests\Acceptance\Support
suites:
  acceptance:
    actor: AcceptanceTester
    path: .
    modules:
      enabled:
        - Asserts
        - WebDriver:
            url: https://myproject.ddev.site
            browser: chrome
            host: ddev-myproject-chrome
            wait: 1
            window_size: 1280x1024

extensions:
  enabled:
    - Codeception\Extension\RunFailed
    - Codeception\Extension\Recorder

paths:
  tests: Acceptance
  output: ../var/log/_output
  data: .
  support: Acceptance/Support

settings:
  shuffle: false
  lint: true
  colors: true
```

### Acceptance Test Structure

```php
// ✅ Right: Backend acceptance test
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Tests\Acceptance\Backend;

use Vendor\ExtensionKey\Tests\Acceptance\Support\BackendTester;
use TYPO3\TestingFramework\Core\Acceptance\Helper\Topbar;

class ModuleCest
{
    public function _before(BackendTester $I): void
    {
        $I->useExistingSession('admin');
    }

    /**
     * @param BackendTester $I
     */
    public function moduleCanBeAccessed(BackendTester $I): void
    {
        $I->click(Topbar::$dropdownToggleSelector, '#typo3-cms-backend-backend-toolbaritems-helptoolbaritem');
        $I->canSee('My Module');
        $I->click('My Module');
        $I->switchToContentFrame();
        $I->see('Module Content', 'h1');
    }

    /**
     * @param BackendTester $I
     */
    public function formSubmissionWorks(BackendTester $I): void
    {
        $I->amOnPage('/typo3/module/my-module');
        $I->switchToContentFrame();
        $I->fillField('title', 'Test Title');
        $I->click('Save');
        $I->see('Record saved successfully');
    }
}
```

### Frontend Acceptance Test

```php
// ✅ Right: Frontend acceptance test
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Tests\Acceptance\Frontend;

use Vendor\ExtensionKey\Tests\Acceptance\Support\AcceptanceTester;

class FrontendPagesCest
{
    /**
     * @param AcceptanceTester $I
     */
    public function homepageIsRendered(AcceptanceTester $I): void
    {
        $I->amOnPage('/');
        $I->see('Welcome to TYPO3');
        $I->seeElement('h1');
    }

    /**
     * @param AcceptanceTester $I
     */
    public function navigationWorks(AcceptanceTester $I): void
    {
        $I->amOnPage('/');
        $I->click('Products');
        $I->see('Our Products', 'h1');
        $I->seeInCurrentUrl('/products');
    }
}
```

### Running Acceptance Tests

```bash
# Run acceptance tests via DDEV
ddev exec bin/codecept run acceptance -d -c Tests/codeception.yml

# Run specific test
ddev exec bin/codecept run acceptance ModuleCest -c Tests/codeception.yml

# Generate new test
ddev exec bin/codecept generate:cest acceptance MyNewTest -c Tests/codeception.yml
```

## Test Organization

### Directory Structure

```
Tests/
├── Unit/
│   ├── Controller/
│   │   └── ProductControllerTest.php
│   ├── Domain/
│   │   ├── Model/
│   │   │   └── ProductTest.php
│   │   └── Repository/
│   │       └── ProductRepositoryTest.php
│   └── Service/
│       └── CalculationServiceTest.php
├── Functional/
│   ├── Domain/
│   │   └── Repository/
│   │       ├── ProductRepositoryTest.php
│   │       └── Fixtures/
│   │           └── products.csv
│   └── Controller/
│       └── ProductControllerTest.php
└── Acceptance/
    ├── Backend/
    │   └── ModuleCest.php
    ├── Frontend/
    │   └── FrontendPagesCest.php
    └── Support/
        ├── AcceptanceTester.php
        └── BackendTester.php
```

### Naming Conventions

**Unit Tests:**
- Pattern: `<ClassName>Test.php`
- Example: `ProductRepository.php` → `ProductRepositoryTest.php`
- Location: Mirror `Classes/` structure in `Tests/Unit/`

**Functional Tests:**
- Pattern: `<ClassName>Test.php`
- Example: `ProductRepository.php` → `ProductRepositoryTest.php`
- Location: Mirror `Classes/` structure in `Tests/Functional/`

**Acceptance Tests:**
- Pattern: `<Feature>Cest.php`
- Example: `ModuleCest.php`, `LoginCest.php`
- Location: `Tests/Acceptance/Backend/` or `Tests/Acceptance/Frontend/`

## PHPUnit Attributes (PHP 8.0+)

```php
// ✅ Right: Using PHPUnit attributes
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Tests\Unit\Service;

use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\Attributes\DataProvider;
use TYPO3\TestingFramework\Core\Unit\UnitTestCase;

class CalculationServiceTest extends UnitTestCase
{
    #[Test]
    public function addReturnsCorrectSum(): void
    {
        $this->assertEquals(5, $this->subject->add(2, 3));
    }

    public static function priceDataProvider(): \Generator
    {
        yield 'standard price' => [
            'price' => 100.0,
            'taxRate' => 0.19,
            'expected' => 119.0,
        ];
        yield 'zero price' => [
            'price' => 0.0,
            'taxRate' => 0.19,
            'expected' => 0.0,
        ];
    }

    #[Test]
    #[DataProvider('priceDataProvider')]
    public function calculatePriceWithTax(float $price, float $taxRate, float $expected): void
    {
        $result = $this->subject->calculatePriceWithTax($price, $taxRate);
        $this->assertEquals($expected, $result);
    }
}
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/tests.yml
name: Tests

on: [push, pull_request]

jobs:
  tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        php: ['8.1', '8.2', '8.3']
        typo3: ['12.4', '13.0']

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}

      - name: Install dependencies
        run: composer install

      - name: Lint PHP
        run: find . -name \*.php ! -path "./vendor/*" -exec php -l {} \;

      - name: Unit Tests
        run: vendor/bin/phpunit -c Build/phpunit/UnitTests.xml

      - name: Functional Tests
        run: |
          typo3DatabaseDriver=pdo_sqlite \
          vendor/bin/phpunit -c Build/phpunit/FunctionalTests.xml
```

## Conformance Checklist

### Unit Tests
- [ ] Unit tests extend `UnitTestCase`
- [ ] Tests located in `Tests/Unit/` mirroring `Classes/`
- [ ] Test files named `<ClassName>Test.php`
- [ ] No database access in unit tests
- [ ] No file system access in unit tests
- [ ] All public methods tested
- [ ] Edge cases and boundaries tested
- [ ] #[Test] attribute or @test annotation used

### Functional Tests
- [ ] Functional tests extend `FunctionalTestCase`
- [ ] Tests located in `Tests/Functional/`
- [ ] `setUp()` calls `parent::setUp()` first
- [ ] Extensions loaded via `$testExtensionsToLoad`
- [ ] Test data loaded via `importCSVDataSet()`
- [ ] Database operations tested
- [ ] Backend user initialized when needed

### Acceptance Tests
- [ ] Acceptance tests use Codeception
- [ ] Tests located in `Tests/Acceptance/`
- [ ] Test files named `<Feature>Cest.php`
- [ ] codeception.yml properly configured
- [ ] Backend tests use `useExistingSession('admin')`
- [ ] Frame switching used correctly
- [ ] Tests verify user-visible behavior

### General
- [ ] PHPUnit configuration files present
- [ ] All tests pass locally
- [ ] CI/CD pipeline configured
- [ ] Test coverage >70% for new code
- [ ] Data providers use named arguments
- [ ] Descriptive test method names
