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

## Testing DataHandler Hooks (SC_OPTIONS)

Test DataHandler SC_OPTIONS hook integration with real framework:

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Functional\Database;

use TYPO3\CMS\Core\DataHandling\DataHandler;
use TYPO3\TestingFramework\Core\Functional\FunctionalTestCase;
use Vendor\Extension\Database\MyDataHandlerHook;

final class MyDataHandlerHookTest extends FunctionalTestCase
{
    protected array $testExtensionsToLoad = [
        'typo3conf/ext/my_extension',
    ];

    protected array $coreExtensionsToLoad = [
        'typo3/cms-rte-ckeditor', // If testing RTE-related hooks
    ];

    protected function setUp(): void
    {
        parent::setUp();

        $this->importCSVDataSet(__DIR__ . '/Fixtures/pages.csv');
        $this->importCSVDataSet(__DIR__ . '/Fixtures/tt_content.csv');
    }

    private function createSubject(): MyDataHandlerHook
    {
        // Get services from container with proper DI
        return new MyDataHandlerHook(
            $this->get(ExtensionConfiguration::class),
            $this->get(LogManager::class),
            $this->get(ResourceFactory::class),
        );
    }

    /**
     * @test
     */
    public function processDatamapPostProcessFieldArrayHandlesRteField(): void
    {
        $subject = $this->createSubject();

        $status     = 'update';
        $table      = 'tt_content';
        $id         = '1';
        $fieldArray = [
            'bodytext' => '<p>Test content with <img src="image.jpg" /></p>',
        ];

        /** @var DataHandler $dataHandler */
        $dataHandler = $this->get(DataHandler::class);

        // Configure TCA for RTE field
        /** @var array<string, mixed> $tcaConfig */
        $tcaConfig = [
            'type'           => 'text',
            'enableRichtext' => true,
        ];
        // @phpstan-ignore-next-line offsetAccess.nonOffsetAccessible
        $GLOBALS['TCA']['tt_content']['columns']['bodytext']['config'] = $tcaConfig;

        $subject->processDatamap_postProcessFieldArray(
            $status,
            $table,
            $id,
            $fieldArray,
            $dataHandler,
        );

        // Field should be processed by hook
        self::assertArrayHasKey('bodytext', $fieldArray);
        self::assertIsString($fieldArray['bodytext']);
        self::assertNotEmpty($fieldArray['bodytext']);
        self::assertStringContainsString('Test content', $fieldArray['bodytext']);
    }

    /**
     * @test
     */
    public function hookIsRegisteredInGlobals(): void
    {
        // Verify hook is properly registered in TYPO3_CONF_VARS
        self::assertIsArray($GLOBALS['TYPO3_CONF_VARS']);
        self::assertArrayHasKey('SC_OPTIONS', $GLOBALS['TYPO3_CONF_VARS']);

        $scOptions = $GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS'];
        self::assertIsArray($scOptions);
        self::assertArrayHasKey('t3lib/class.t3lib_tcemain.php', $scOptions);

        $tcemainOptions = $scOptions['t3lib/class.t3lib_tcemain.php'];
        self::assertIsArray($tcemainOptions);
        self::assertArrayHasKey('processDatamapClass', $tcemainOptions);

        $registeredHooks = $tcemainOptions['processDatamapClass'];
        self::assertIsArray($registeredHooks);

        // Hook class should be registered
        self::assertContains(MyDataHandlerHook::class, $registeredHooks);
    }
}
```

### Key Patterns for DataHandler Hook Testing

1. **Use Factory Method Pattern**: Create `createSubject()` method to avoid uninitialized property PHPStan errors
2. **Test Real Framework Integration**: Don't mock DataHandler, test actual hook execution
3. **Configure TCA Dynamically**: Set up `$GLOBALS['TCA']` in tests for field configuration
4. **Verify Hook Registration**: Test that hooks are properly registered in `$GLOBALS['TYPO3_CONF_VARS']`
5. **Test Multiple Scenarios**: new vs update, single vs multiple fields, RTE vs non-RTE

## Testing File Abstraction Layer (FAL)

Test ResourceFactory and FAL storage integration:

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Functional\Controller;

use TYPO3\CMS\Core\Resource\File;
use TYPO3\CMS\Core\Resource\Folder;
use TYPO3\CMS\Core\Resource\ResourceFactory;
use TYPO3\CMS\Core\Resource\ResourceStorage;
use TYPO3\TestingFramework\Core\Functional\FunctionalTestCase;
use Vendor\Extension\Controller\ImageRenderingController;

final class ImageRenderingControllerTest extends FunctionalTestCase
{
    protected array $testExtensionsToLoad = [
        'typo3conf/ext/my_extension',
    ];

    protected function setUp(): void
    {
        parent::setUp();

        $this->importCSVDataSet(__DIR__ . '/Fixtures/sys_file_storage.csv');
        $this->importCSVDataSet(__DIR__ . '/Fixtures/sys_file.csv');
    }

    /**
     * @test
     */
    public function storageIsAccessible(): void
    {
        /** @var ResourceFactory $resourceFactory */
        $resourceFactory = $this->get(ResourceFactory::class);
        $storage         = $resourceFactory->getStorageObject(1);

        self::assertInstanceOf(ResourceStorage::class, $storage);
        self::assertTrue($storage->isOnline());
    }

    /**
     * @test
     */
    public function canRetrieveFileFromStorage(): void
    {
        /** @var ResourceFactory $resourceFactory */
        $resourceFactory = $this->get(ResourceFactory::class);

        // Get file from test data
        $file = $resourceFactory->getFileObject(1);

        self::assertInstanceOf(File::class, $file);
        self::assertSame('test-image.jpg', $file->getName());
    }

    /**
     * @test
     */
    public function canAccessStorageRootFolder(): void
    {
        /** @var ResourceFactory $resourceFactory */
        $resourceFactory = $this->get(ResourceFactory::class);
        $storage         = $resourceFactory->getStorageObject(1);

        $rootFolder = $storage->getRootLevelFolder();

        self::assertInstanceOf(Folder::class, $rootFolder);
        self::assertSame('/', $rootFolder->getIdentifier());
    }
}
```

### FAL Test Fixtures

**sys_file_storage.csv:**
```csv
uid,pid,name,driver,configuration,is_default,is_browsable,is_public,is_writable,is_online
1,0,"fileadmin","Local","<?xml version=""1.0"" encoding=""utf-8"" standalone=""yes"" ?><T3FlexForms><data><sheet index=""sDEF""><language index=""lDEF""><field index=""basePath""><value index=""vDEF"">fileadmin/</value></field><field index=""pathType""><value index=""vDEF"">relative</value></field><field index=""caseSensitive""><value index=""vDEF"">1</value></field></language></sheet></data></T3FlexForms>",1,1,1,1,1
```

**sys_file.csv:**
```csv
uid,pid,storage,identifier,name,type,mime_type,size,sha1,extension
1,0,1,"/test-image.jpg","test-image.jpg",2,"image/jpeg",12345,"da39a3ee5e6b4b0d3255bfef95601890afd80709","jpg"
```

### Key Patterns for FAL Testing

1. **Test Storage Configuration**: Verify storage is properly configured and online
2. **Test File Retrieval**: Use `getFileObject()` to retrieve files from sys_file
3. **Test Folder Operations**: Verify folder access and structure
4. **Use CSV Fixtures**: Import sys_file_storage and sys_file test data
5. **Test Real Services**: Use container's ResourceFactory, don't mock

## PHPStan Type Safety in Functional Tests

### Handling $GLOBALS['TCA'] with PHPStan Level 9

PHPStan cannot infer types for runtime-configured `$GLOBALS` arrays. Use ignore annotations:

```php
// Configure TCA for RTE field
/** @var array<string, mixed> $tcaConfig */
$tcaConfig = [
    'type'           => 'text',
    'enableRichtext' => true,
];
// @phpstan-ignore-next-line offsetAccess.nonOffsetAccessible
$GLOBALS['TCA']['tt_content']['columns']['bodytext']['config'] = $tcaConfig;
```

### Type Assertions for Dynamic Arrays

When testing field arrays that are modified by reference:

```php
// ❌ PHPStan cannot verify this is still an array
self::assertStringContainsString('Test', $fieldArray['bodytext']);

// ✅ Add type assertions
self::assertArrayHasKey('bodytext', $fieldArray);
self::assertIsString($fieldArray['bodytext']);
self::assertStringContainsString('Test', $fieldArray['bodytext']);
```

### Avoiding Uninitialized Property Errors

Use factory methods instead of properties initialized in setUp():

```php
// ❌ PHPStan warns about uninitialized property
private MyService $subject;

protected function setUp(): void
{
    $this->subject = $this->get(MyService::class);
}

// ✅ Use factory method
private function createSubject(): MyService
{
    return $this->get(MyService::class);
}

public function testSomething(): void
{
    $subject = $this->createSubject();
    // Use $subject
}
```

### PHPStan Annotations for Functional Tests

Common patterns:

```php
// Ignore $GLOBALS access
// @phpstan-ignore-next-line offsetAccess.nonOffsetAccessible
$GLOBALS['TCA']['table']['columns']['field']['config'] = $config;

// Type hint service retrieval
/** @var DataHandler $dataHandler */
$dataHandler = $this->get(DataHandler::class);

// Type hint config arrays
/** @var array<string, mixed> $tcaConfig */
$tcaConfig = ['type' => 'text'];
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
