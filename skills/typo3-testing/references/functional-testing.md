# Functional Testing in TYPO3

Functional tests verify components that interact with external systems like databases, using a full TYPO3 instance.

## When to Use Functional Tests

- Testing database operations (repositories, queries)
- Controller and plugin functionality
- Hook and event implementations
- DataHandler operations
- File and folder operations
- Extension configuration behavior

## Base Class

All functional tests extend `TYPO3\TestingFramework\Core\Functional\FunctionalTestCase`:

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Functional\Domain\Repository;

use TYPO3\TestingFramework\Core\Functional\FunctionalTestCase;
use Vendor\Extension\Domain\Model\Product;
use Vendor\Extension\Domain\Repository\ProductRepository;

final class ProductRepositoryTest extends FunctionalTestCase
{
    protected ProductRepository $subject;

    protected array $testExtensionsToLoad = [
        'typo3conf/ext/my_extension',
    ];

    protected function setUp(): void
    {
        parent::setUp();
        $this->subject = $this->get(ProductRepository::class);
    }

    /**
     * @test
     */
    public function findsProductsByCategory(): void
    {
        $this->importCSVDataSet(__DIR__ . '/../Fixtures/Products.csv');

        $products = $this->subject->findByCategory(1);

        self::assertCount(3, $products);
    }
}
```

## Test Database

Functional tests use an isolated test database:

- Created before test execution
- Populated with fixtures
- Destroyed after test completion
- Supports: MySQL, MariaDB, PostgreSQL, SQLite

### Database Configuration

Set via environment or `FunctionalTests.xml`:

```xml
<php>
    <env name="typo3DatabaseDriver" value="mysqli"/>
    <env name="typo3DatabaseHost" value="localhost"/>
    <env name="typo3DatabasePort" value="3306"/>
    <env name="typo3DatabaseUsername" value="root"/>
    <env name="typo3DatabasePassword" value=""/>
    <env name="typo3DatabaseName" value="typo3_test"/>
</php>
```

## Database Fixtures

### CSV Format

Create fixtures in `Tests/Functional/Fixtures/`:

```csv
# pages.csv
uid,pid,title,doktype
1,0,"Root",1
2,1,"Products",1
3,1,"Services",1
```

```csv
# tx_myext_domain_model_product.csv
uid,pid,title,price,category
1,2,"Product A",10.00,1
2,2,"Product B",20.00,1
3,2,"Product C",15.00,2
```

### Import Fixtures

```php
/**
 * @test
 */
public function findsProducts(): void
{
    // Import fixture
    $this->importCSVDataSet(__DIR__ . '/../Fixtures/Products.csv');

    // Test repository
    $products = $this->subject->findAll();

    self::assertCount(3, $products);
}
```

### Multiple Fixtures

```php
protected function setUp(): void
{
    parent::setUp();

    // Import common fixtures
    $this->importCSVDataSet(__DIR__ . '/../Fixtures/pages.csv');
    $this->importCSVDataSet(__DIR__ . '/../Fixtures/be_users.csv');

    $this->subject = $this->get(ProductRepository::class);
}
```

## Dependency Injection

Use `$this->get()` to retrieve services:

```php
protected function setUp(): void
{
    parent::setUp();

    // Get service from container
    $this->subject = $this->get(ProductRepository::class);
    $this->dataMapper = $this->get(DataMapper::class);
}
```

## Testing Extensions

### Load Test Extensions

```php
protected array $testExtensionsToLoad = [
    'typo3conf/ext/my_extension',
    'typo3conf/ext/dependency_extension',
];
```

### Core Extensions

```php
protected array $coreExtensionsToLoad = [
    'form',
    'workspaces',
];
```

## Site Configuration

Create site configuration for frontend tests:

```php
protected function setUp(): void
{
    parent::setUp();

    $this->importCSVDataSet(__DIR__ . '/../Fixtures/pages.csv');

    $this->writeSiteConfiguration(
        'test',
        [
            'rootPageId' => 1,
            'base' => 'http://localhost/',
        ]
    );
}
```

## Frontend Requests

Test frontend rendering:

```php
use TYPO3\TestingFramework\Core\Functional\Framework\Frontend\InternalRequest;

/**
 * @test
 */
public function rendersProductList(): void
{
    $this->importCSVDataSet(__DIR__ . '/../Fixtures/pages.csv');
    $this->importCSVDataSet(__DIR__ . '/../Fixtures/Products.csv');

    $this->writeSiteConfiguration('test', ['rootPageId' => 1]);

    $response = $this->executeFrontendSubRequest(
        new InternalRequest('http://localhost/products')
    );

    self::assertStringContainsString('Product A', (string)$response->getBody());
}
```

## Backend User Context

Test with backend user:

```php
use TYPO3\TestingFramework\Core\Functional\Framework\Frontend\InternalRequest;

/**
 * @test
 */
public function editorCanEditRecord(): void
{
    $this->importCSVDataSet(__DIR__ . '/../Fixtures/be_users.csv');
    $this->importCSVDataSet(__DIR__ . '/../Fixtures/Products.csv');

    $this->setUpBackendUser(1); // uid from be_users.csv

    $dataHandler = $this->get(DataHandler::class);
    $dataHandler->start(
        [
            'tx_myext_domain_model_product' => [
                1 => ['title' => 'Updated Product']
            ]
        ],
        []
    );
    $dataHandler->process_datamap();

    self::assertEmpty($dataHandler->errorLog);
}
```

## File Operations

Test file handling:

```php
/**
 * @test
 */
public function uploadsFile(): void
{
    $fileStorage = $this->get(StorageRepository::class)->getDefaultStorage();

    $file = $fileStorage->addFile(
        __DIR__ . '/../Fixtures/Files/test.jpg',
        $fileStorage->getDefaultFolder(),
        'test.jpg'
    );

    self::assertFileExists($file->getForLocalProcessing(false));
}
```

## Configuration

### PHPUnit XML (Build/phpunit/FunctionalTests.xml)

```xml
<phpunit
    bootstrap="FunctionalTestsBootstrap.php"
    cacheResult="false"
    beStrictAboutTestsThatDoNotTestAnything="true"
    failOnDeprecation="true"
    failOnNotice="true"
    failOnWarning="true">
    <testsuites>
        <testsuite name="Functional tests">
            <directory>../../Tests/Functional/</directory>
        </testsuite>
    </testsuites>
    <php>
        <const name="TYPO3_TESTING_FUNCTIONAL_REMOVE_ERROR_HANDLER" value="true" />
        <env name="TYPO3_CONTEXT" value="Testing"/>
        <env name="typo3DatabaseDriver" value="mysqli"/>
    </php>
</phpunit>
```

### Bootstrap (Build/phpunit/FunctionalTestsBootstrap.php)

```php
<?php

declare(strict_types=1);

call_user_func(static function () {
    $testbase = new \TYPO3\TestingFramework\Core\Testbase();
    $testbase->defineOriginalRootPath();
    $testbase->createDirectory(ORIGINAL_ROOT . 'typo3temp/var/tests');
    $testbase->createDirectory(ORIGINAL_ROOT . 'typo3temp/var/transient');
});
```

## Fixture Strategy

### Minimal Fixtures

Keep fixtures focused on test requirements:

```php
// ❌ Too much data
$this->importCSVDataSet(__DIR__ . '/../Fixtures/AllProducts.csv'); // 500 records

// ✅ Minimal test data
$this->importCSVDataSet(__DIR__ . '/../Fixtures/ProductsByCategory.csv'); // 3 records
```

### Reusable Fixtures

Create shared fixtures for common scenarios:

```
Tests/Functional/Fixtures/
├── pages.csv              # Basic page tree
├── be_users.csv           # Test backend users
├── Products/
│   ├── BasicProducts.csv  # 3 simple products
│   ├── ProductsWithCategories.csv
│   └── ProductsWithImages.csv
```

### Fixture Documentation

Document fixture purpose in test or AGENTS.md:

```php
/**
 * @test
 */
public function findsProductsByCategory(): void
{
    // Fixture contains: 3 products in category 1, 2 products in category 2
    $this->importCSVDataSet(__DIR__ . '/../Fixtures/ProductsByCategory.csv');

    $products = $this->subject->findByCategory(1);

    self::assertCount(3, $products);
}
```

## Best Practices

1. **Use setUp() for Common Setup**: Import shared fixtures in setUp()
2. **One Test Database**: Each test gets clean database instance
3. **Test Isolation**: Don't depend on other test execution
4. **Minimal Fixtures**: Only data required for specific test
5. **Clear Assertions**: Test specific behavior, not implementation
6. **Cleanup**: Testing framework handles cleanup automatically

## Common Pitfalls

❌ **Large Fixtures**
```php
// Don't import unnecessary data
$this->importCSVDataSet('AllData.csv'); // 10,000 records
```

❌ **No Fixtures**
```php
// Don't expect data to exist
$products = $this->subject->findAll();
self::assertCount(0, $products); // Always true without fixtures
```

❌ **Missing Extensions**
```php
// Don't forget to load extension under test
// Missing: protected array $testExtensionsToLoad = ['typo3conf/ext/my_extension'];
```

✅ **Focused, Well-Documented Tests**
```php
/**
 * @test
 */
public function findsByCategory(): void
{
    // Fixture: 3 products in category 1
    $this->importCSVDataSet(__DIR__ . '/../Fixtures/CategoryProducts.csv');

    $products = $this->subject->findByCategory(1);

    self::assertCount(3, $products);
    self::assertSame('Product A', $products[0]->getTitle());
}
```

## Running Functional Tests

```bash
# Via runTests.sh
Build/Scripts/runTests.sh -s functional

# Via PHPUnit directly
vendor/bin/phpunit -c Build/phpunit/FunctionalTests.xml

# Via Composer
composer ci:test:php:functional

# With specific database
typo3DatabaseDriver=pdo_mysql vendor/bin/phpunit -c Build/phpunit/FunctionalTests.xml

# Single test
vendor/bin/phpunit Tests/Functional/Domain/Repository/ProductRepositoryTest.php
```

## Resources

- [TYPO3 Functional Testing Documentation](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/FunctionalTests.html)
- [Testing Framework](https://github.com/typo3/testing-framework)
- [CSV Fixture Format](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/FunctionalTests.html#importing-data)
