# Unit Testing in TYPO3

Unit tests are fast, isolated tests that verify individual components without external dependencies like databases or file systems.

## When to Use Unit Tests

✅ **Ideal for:**
- Testing pure business logic
- Validators, calculators, transformers
- Value objects and DTOs
- Utilities and helper functions
- Domain models without persistence
- **Controllers with dependency injection** (new in TYPO3 13)
- **Services with injected dependencies**

❌ **Not suitable for:**
- Database operations (use functional tests)
- File system operations
- Methods using `BackendUtility` or global state
- Complex TYPO3 framework integration
- Parent class behavior from framework classes

## Base Class

All unit tests extend `TYPO3\TestingFramework\Core\Unit\UnitTestCase`:

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\Domain\Validator;

use PHPUnit\Framework\Attributes\Test;
use TYPO3\TestingFramework\Core\Unit\UnitTestCase;
use Vendor\Extension\Domain\Validator\EmailValidator;

/**
 * Unit tests for EmailValidator.
 *
 * @covers \Vendor\Extension\Domain\Validator\EmailValidator
 */
final class EmailValidatorTest extends UnitTestCase
{
    private EmailValidator $subject;

    protected function setUp(): void
    {
        parent::setUp();
        $this->subject = new EmailValidator();
    }

    #[Test]
    public function validEmailPassesValidation(): void
    {
        $result = $this->subject->validate('user@example.com');

        self::assertFalse($result->hasErrors());
    }

    #[Test]
    public function invalidEmailFailsValidation(): void
    {
        $result = $this->subject->validate('invalid-email');

        self::assertTrue($result->hasErrors());
    }
}
```

> **Note:** TYPO3 13+ with PHPUnit 11/12 uses PHP attributes (`#[Test]`) instead of `@test` annotations.
> Use `private` instead of `protected` for properties when possible (better encapsulation).

## Key Principles

### 1. No External Dependencies

Unit tests should NOT:
- Access the database
- Read/write files
- Make HTTP requests
- Use TYPO3 framework services

### 2. Fast Execution

Unit tests should run in milliseconds:
- No I/O operations
- Minimal object instantiation
- Use mocks for dependencies

### 3. Test Independence

Each test should:
- Be runnable standalone
- Not depend on execution order
- Clean up in tearDown()

## Test Structure

### Arrange-Act-Assert Pattern

```php
/**
 * @test
 */
public function calculatesTotalPrice(): void
{
    // Arrange: Set up test data
    $cart = new ShoppingCart();
    $cart->addItem(new Item('product1', 10.00, 2));
    $cart->addItem(new Item('product2', 5.50, 1));

    // Act: Execute the code under test
    $total = $cart->calculateTotal();

    // Assert: Verify the result
    self::assertSame(25.50, $total);
}
```

### setUp() and tearDown()

```php
protected function setUp(): void
{
    parent::setUp();
    // Initialize test subject and dependencies
    $this->subject = new Calculator();
}

protected function tearDown(): void
{
    // Clean up resources
    unset($this->subject);
    parent::tearDown();
}
```

## Testing with Dependency Injection (TYPO3 13+)

Modern TYPO3 13 controllers and services use constructor injection. Here's how to test them:

### Basic Constructor Injection Test

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\Controller;

use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\MockObject\MockObject;
use TYPO3\CMS\Core\Resource\ResourceFactory;
use TYPO3\TestingFramework\Core\Unit\UnitTestCase;
use Vendor\Extension\Controller\ImageController;

final class ImageControllerTest extends UnitTestCase
{
    private ImageController $subject;

    /** @var ResourceFactory&MockObject */
    private ResourceFactory $resourceFactoryMock;

    protected function setUp(): void
    {
        parent::setUp();

        /** @var ResourceFactory&MockObject $resourceFactoryMock */
        $resourceFactoryMock = $this->createMock(ResourceFactory::class);

        $this->resourceFactoryMock = $resourceFactoryMock;
        $this->subject             = new ImageController($this->resourceFactoryMock);
    }

    #[Test]
    public function getFileRetrievesFileFromFactory(): void
    {
        $fileId = 123;
        $fileMock = $this->createMock(\TYPO3\CMS\Core\Resource\File::class);

        $this->resourceFactoryMock
            ->expects(self::once())
            ->method('getFileObject')
            ->with($fileId)
            ->willReturn($fileMock);

        $result = $this->subject->getFile($fileId);

        self::assertSame($fileMock, $result);
    }
}
```

### Multiple Dependencies with Intersection Types

PHPUnit mocks require proper type hints using intersection types for PHPStan compliance:

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\Controller;

use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\MockObject\MockObject;
use TYPO3\CMS\Core\Log\LogManager;
use TYPO3\CMS\Core\Resource\ResourceFactory;
use TYPO3\TestingFramework\Core\Unit\UnitTestCase;
use Vendor\Extension\Controller\ImageController;
use Vendor\Extension\Utils\ImageProcessor;

final class ImageControllerTest extends UnitTestCase
{
    private ImageController $subject;

    /** @var ResourceFactory&MockObject */
    private ResourceFactory $resourceFactoryMock;

    /** @var ImageProcessor&MockObject */
    private ImageProcessor $imageProcessorMock;

    /** @var LogManager&MockObject */
    private LogManager $logManagerMock;

    protected function setUp(): void
    {
        parent::setUp();

        /** @var ResourceFactory&MockObject $resourceFactoryMock */
        $resourceFactoryMock = $this->createMock(ResourceFactory::class);

        /** @var ImageProcessor&MockObject $imageProcessorMock */
        $imageProcessorMock = $this->createMock(ImageProcessor::class);

        /** @var LogManager&MockObject $logManagerMock */
        $logManagerMock = $this->createMock(LogManager::class);

        $this->resourceFactoryMock = $resourceFactoryMock;
        $this->imageProcessorMock  = $imageProcessorMock;
        $this->logManagerMock      = $logManagerMock;

        $this->subject = new ImageController(
            $this->resourceFactoryMock,
            $this->imageProcessorMock,
            $this->logManagerMock,
        );
    }

    #[Test]
    public function processImageUsesInjectedProcessor(): void
    {
        $fileMock = $this->createMock(\TYPO3\CMS\Core\Resource\File::class);
        $processedFileMock = $this->createMock(\TYPO3\CMS\Core\Resource\ProcessedFile::class);

        $this->imageProcessorMock
            ->expects(self::once())
            ->method('process')
            ->with($fileMock, ['width' => 800])
            ->willReturn($processedFileMock);

        $result = $this->subject->processImage($fileMock, ['width' => 800]);

        self::assertSame($processedFileMock, $result);
    }
}
```

**Key Points:**
- Use intersection types: `ResourceFactory&MockObject` for proper PHPStan type checking
- Assign mocks to properly typed variables before passing to constructor
- This pattern works with PHPUnit 11/12 and PHPStan Level 10

### Handling $GLOBALS and Singleton State

Some TYPO3 components still use global state. Handle this properly:

```php
final class BackendControllerTest extends UnitTestCase
{
    protected bool $resetSingletonInstances = true;

    #[Test]
    public function checksBackendUserPermissions(): void
    {
        // Mock backend user
        $backendUserMock = $this->createMock(BackendUserAuthentication::class);
        $backendUserMock->method('isAdmin')->willReturn(true);

        $GLOBALS['BE_USER'] = $backendUserMock;

        $result = $this->subject->hasAccess();

        self::assertTrue($result);
    }

    #[Test]
    public function returnsFalseWhenNoBackendUser(): void
    {
        $GLOBALS['BE_USER'] = null;

        $result = $this->subject->hasAccess();

        self::assertFalse($result);
    }
}
```

**Important:** Set `protected bool $resetSingletonInstances = true;` when tests interact with TYPO3 singletons to prevent test pollution.

## Mocking Dependencies

Use PHPUnit's built-in mocking (PHPUnit 11/12):

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\Service;

use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\MockObject\MockObject;
use TYPO3\TestingFramework\Core\Unit\UnitTestCase;
use Vendor\Extension\Domain\Model\User;
use Vendor\Extension\Domain\Repository\UserRepository;
use Vendor\Extension\Service\UserService;

final class UserServiceTest extends UnitTestCase
{
    private UserService $subject;

    /** @var UserRepository&MockObject */
    private UserRepository $repositoryMock;

    protected function setUp(): void
    {
        parent::setUp();

        /** @var UserRepository&MockObject $repositoryMock */
        $repositoryMock = $this->createMock(UserRepository::class);

        $this->repositoryMock = $repositoryMock;
        $this->subject        = new UserService($this->repositoryMock);
    }

    #[Test]
    public function findsUserByEmail(): void
    {
        $email = 'test@example.com';
        $user  = new User('John');

        $this->repositoryMock
            ->expects(self::once())
            ->method('findByEmail')
            ->with($email)
            ->willReturn($user);

        $result = $this->subject->getUserByEmail($email);

        self::assertSame('John', $result->getName());
    }

    #[Test]
    public function throwsExceptionWhenUserNotFound(): void
    {
        $email = 'nonexistent@example.com';

        $this->repositoryMock
            ->method('findByEmail')
            ->with($email)
            ->willReturn(null);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('User not found');

        $this->subject->getUserByEmail($email);
    }
}
```

> **Note:** TYPO3 13+ with PHPUnit 11/12 uses `createMock()` instead of Prophecy.
> Prophecy is deprecated and should not be used in new tests.

## Assertions

### Common Assertions

```php
// Equality
self::assertEquals($expected, $actual);
self::assertSame($expected, $actual); // Strict comparison

// Boolean
self::assertTrue($condition);
self::assertFalse($condition);

// Null checks
self::assertNull($value);
self::assertNotNull($value);

// Type checks
self::assertIsString($value);
self::assertIsInt($value);
self::assertIsArray($value);
self::assertInstanceOf(User::class, $object);

// Collections
self::assertCount(3, $array);
self::assertEmpty($array);
self::assertContains('item', $array);

// Exceptions
$this->expectException(\InvalidArgumentException::class);
$this->expectExceptionMessage('Invalid input');
$subject->methodThatThrows();
```

### Specific Over Generic

```php
// ❌ Too generic
self::assertTrue($result > 0);
self::assertEquals(true, $isValid);

// ✅ Specific and clear
self::assertGreaterThan(0, $result);
self::assertTrue($isValid);
```

## Data Providers

Test multiple scenarios with data providers:

```php
/**
 * @test
 * @dataProvider validEmailProvider
 */
public function validatesEmails(string $email, bool $expected): void
{
    $result = $this->subject->isValid($email);
    self::assertSame($expected, $result);
}

public static function validEmailProvider(): array
{
    return [
        'valid email' => ['user@example.com', true],
        'email with subdomain' => ['user@mail.example.com', true],
        'missing @' => ['userexample.com', false],
        'missing domain' => ['user@', false],
        'empty string' => ['', false],
    ];
}
```

## Testing Private/Protected Methods

**Preferred Approach**: Test through public API whenever possible:

```php
// ✅ Best approach - test through public interface
$result = $subject->publicMethodThatUsesPrivateMethod();
self::assertSame($expected, $result);
```

**When Reflection is Acceptable**: Sometimes protected methods contain complex logic that deserves dedicated testing (e.g., URL validation, attribute resolution). In these cases, use a helper method:

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\Controller;

use PHPUnit\Framework\Attributes\Test;
use ReflectionMethod;
use TYPO3\TestingFramework\Core\Unit\UnitTestCase;
use Vendor\Extension\Controller\ImageController;

final class ImageControllerTest extends UnitTestCase
{
    private ImageController $subject;

    /**
     * Helper method to access protected methods.
     *
     * @param array<int, mixed> $args
     */
    private function callProtectedMethod(string $methodName, array $args): mixed
    {
        $reflection = new ReflectionMethod($this->subject, $methodName);
        $reflection->setAccessible(true);

        return $reflection->invokeArgs($this->subject, $args);
    }

    #[Test]
    public function isExternalImageReturnsTrueForHttpsUrls(): void
    {
        $result = $this->callProtectedMethod('isExternalImage', ['https://example.com/image.jpg']);

        self::assertTrue($result);
    }

    #[Test]
    public function isExternalImageReturnsFalseForLocalPaths(): void
    {
        $result = $this->callProtectedMethod('isExternalImage', ['/fileadmin/images/test.jpg']);

        self::assertFalse($result);
    }
}
```

**Important Considerations**:
- Only use reflection when testing protected methods with complex logic worth testing independently
- Never test private methods - refactor to protected if testing is needed
- Prefer testing through public API when the logic is simple
- Document why reflection testing is used for a specific method

## Configuration

### PHPUnit XML (Build/phpunit/UnitTests.xml)

```xml
<phpunit
    bootstrap="../../vendor/autoload.php"
    cacheResult="false"
    beStrictAboutTestsThatDoNotTestAnything="true"
    beStrictAboutOutputDuringTests="true"
    failOnDeprecation="true"
    failOnNotice="true"
    failOnWarning="true"
    failOnRisky="true">
    <testsuites>
        <testsuite name="Unit tests">
            <directory>../../Tests/Unit/</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

## Best Practices

1. **One Assert Per Test**: Focus tests on single behavior
2. **Clear Test Names**: Describe what is tested and expected result
3. **Arrange-Act-Assert**: Follow consistent structure
4. **No Logic in Tests**: Tests should be simple and readable
5. **Test Edge Cases**: Empty strings, null, zero, negative numbers
6. **Use Data Providers**: Test multiple scenarios efficiently
7. **Mock External Dependencies**: Keep tests isolated and fast

## Testing PHP Syntax Variants

When testing code that parses or analyzes PHP (like Extension Scanner matchers), test all syntax variants that PHP allows. Different syntaxes may be parsed differently.

### Dynamic Method Calls

PHP supports multiple forms of dynamic method calls:

```php
// DataProvider for testing dynamic call handling
public static function dynamicCallSyntaxDataProvider(): array
{
    return [
        // Standard dynamic method call - variable holds method name
        'dynamic method call with variable' => [
            '<?php
            $methodName = "someMethod";
            $object->$methodName();',
            [], // no match expected, must not crash
        ],
        // Expression-based dynamic call - expression evaluated for method name
        'dynamic method call with expression' => [
            '<?php
            $object->{$this->getMethodName()}();',
            [], // no match expected, must not crash
        ],
        // Curly brace syntax with variable
        'dynamic method call with curly brace variable' => [
            '<?php
            $object->{$methodName}();',
            [], // no match expected, must not crash
        ],
    ];
}
```

**Why This Matters**: PhpParser represents these differently:
- `$obj->$var()` → `$node->name` is `PhpParser\Node\Expr\Variable`
- `$obj->{$expr}()` → `$node->name` is `PhpParser\Node\Expr\MethodCall` or other expression
- `$obj->method()` → `$node->name` is `PhpParser\Node\Identifier`

Code assuming `$node->name` is always an `Identifier` will crash on dynamic calls.

### Dynamic Function Calls

```php
'dynamic function call' => [
    '<?php
    $func = "myFunction";
    $func();',
    [],
],
'variable function with call_user_func' => [
    '<?php
    call_user_func($callback, $arg);',
    [],
],
```

### Static Method Variants

```php
'dynamic static method call' => [
    '<?php
    $method = "staticMethod";
    SomeClass::$method();',
    [],
],
'variable class static call' => [
    '<?php
    $class = "SomeClass";
    $class::staticMethod();',
    [],
],
```

### Testing Pattern

Always include regression tests with clear comments:

```php
// Regression test for issue #108413: $object->$var() syntax must not crash
'no match for dynamic method call with variable' => [
    [
        'Foo->aMethod' => [
            'numberOfMandatoryArguments' => 0,
            'maximumNumberOfArguments' => 2,
            'restFiles' => ['Foo-1.rst'],
        ],
    ],
    '<?php
    $methodName = "someMethod";
    $someVar->$methodName();',
    [], // no match, must not crash
],
```

## Common Pitfalls

❌ **Testing Framework Code**
```php
// Don't test TYPO3 core functionality
$this->assertTrue(is_array([])); // Useless test
```

❌ **Slow Tests**
```php
// Don't access file system in unit tests
file_put_contents('/tmp/test.txt', 'data');
```

❌ **Test Interdependence**
```php
// Don't depend on test execution order
/** @depends testCreate */
public function testUpdate(): void { }
```

✅ **Focused, Fast, Isolated Tests**
```php
/**
 * @test
 */
public function calculatesPriceWithDiscount(): void
{
    $calculator = new PriceCalculator();
    $price = $calculator->calculate(100.0, 0.2);
    self::assertSame(80.0, $price);
}
```

## Running Unit Tests

```bash
# Via runTests.sh
Build/Scripts/runTests.sh -s unit

# Via PHPUnit directly
vendor/bin/phpunit -c Build/phpunit/UnitTests.xml

# Via Composer
composer ci:test:php:unit

# Single test file
vendor/bin/phpunit Tests/Unit/Domain/Validator/EmailValidatorTest.php

# Single test method
vendor/bin/phpunit --filter testValidEmail
```

## Troubleshooting Common Issues

### PHPStan Errors with Mocks

**Problem**: PHPStan complains about mock type mismatches.
```
Method expects ResourceFactory but got ResourceFactory&MockObject
```

**Solution**: Use intersection type annotations:
```php
/** @var ResourceFactory&MockObject */
private ResourceFactory $resourceFactoryMock;

protected function setUp(): void
{
    parent::setUp();

    /** @var ResourceFactory&MockObject $resourceFactoryMock */
    $resourceFactoryMock = $this->createMock(ResourceFactory::class);

    $this->resourceFactoryMock = $resourceFactoryMock;
    $this->subject = new MyController($this->resourceFactoryMock);
}
```

### Undefined Array Key Warnings

**Problem**: Tests throw warnings about missing array keys.
```
Undefined array key "fileId"
```

**Solution**: Always provide all required keys in mock arrays:
```php
// ❌ Incomplete mock data
$requestMock->method('getQueryParams')->willReturn([
    'fileId' => 123,
]);

// ✅ Complete mock data
$requestMock->method('getQueryParams')->willReturn([
    'fileId' => 123,
    'table'  => 'tt_content',
    'P'      => [],
]);
```

### Tests Requiring Functional Setup

**Problem**: Unit tests fail with cache or framework errors.
```
NoSuchCacheException: A cache with identifier "runtime" does not exist.
```

**Solution**: Identify methods that require TYPO3 framework infrastructure and move them to functional tests:
- Methods using `BackendUtility::getPagesTSconfig()`
- Methods calling parent class framework behavior
- Methods requiring global state like `$GLOBALS['TYPO3_CONF_VARS']`

Add comments explaining the limitation:
```php
// Note: getMaxDimensions tests require functional test setup due to BackendUtility dependency
// These are better tested in functional tests
```

### Singleton State Pollution

**Problem**: Tests interfere with each other due to singleton state.

**Solution**: Enable singleton reset in your test class:
```php
final class MyControllerTest extends UnitTestCase
{
    protected bool $resetSingletonInstances = true;

    #[Test]
    public function testWithGlobals(): void
    {
        $GLOBALS['BE_USER'] = $this->createMock(BackendUserAuthentication::class);
        // Test will clean up automatically
    }
}
```

### Exception Flow Issues

**Problem**: Catching and re-throwing exceptions masks the original error.
```php
// ❌ Inner exception caught by outer catch
try {
    $file = $this->factory->getFile($id);
    if ($file->isDeleted()) {
        throw new RuntimeException('Deleted', 1234);
    }
} catch (Exception $e) {
    throw new RuntimeException('Not found', 5678);
}
```

**Solution**: Separate concerns - catch only what you need:
```php
// ✅ Proper exception flow
try {
    $file = $this->factory->getFile($id);
} catch (Exception $e) {
    throw new RuntimeException('Not found', 5678, $e);
}

if ($file->isDeleted()) {
    throw new RuntimeException('Deleted', 1234);
}
```

## Testing DataHandler Hooks

DataHandler hooks (`processDatamap_*`, `processCmdmap_*`) require careful testing as they interact with TYPO3 globals.

### Example: Testing processDatamap_postProcessFieldArray

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\Database;

use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\MockObject\MockObject;
use TYPO3\CMS\Core\Configuration\ExtensionConfiguration;
use TYPO3\CMS\Core\Context\Context;
use TYPO3\CMS\Core\DataHandling\DataHandler;
use TYPO3\CMS\Core\Http\RequestFactory;
use TYPO3\CMS\Core\Log\LogManager;
use TYPO3\CMS\Core\Log\Logger;
use TYPO3\CMS\Core\Resource\DefaultUploadFolderResolver;
use TYPO3\CMS\Core\Resource\ResourceFactory;
use TYPO3\TestingFramework\Core\Unit\UnitTestCase;
use Vendor\Extension\Database\MyDataHandlerHook;

/**
 * Unit tests for MyDataHandlerHook.
 *
 * @covers \Vendor\Extension\Database\MyDataHandlerHook
 */
final class MyDataHandlerHookTest extends UnitTestCase
{
    protected bool $resetSingletonInstances = true;

    private MyDataHandlerHook $subject;

    /** @var ExtensionConfiguration&MockObject */
    private ExtensionConfiguration $extensionConfigurationMock;

    /** @var LogManager&MockObject */
    private LogManager $logManagerMock;

    /** @var ResourceFactory&MockObject */
    private ResourceFactory $resourceFactoryMock;

    /** @var Context&MockObject */
    private Context $contextMock;

    /** @var RequestFactory&MockObject */
    private RequestFactory $requestFactoryMock;

    /** @var DefaultUploadFolderResolver&MockObject */
    private DefaultUploadFolderResolver $uploadFolderResolverMock;

    /** @var Logger&MockObject */
    private Logger $loggerMock;

    protected function setUp(): void
    {
        parent::setUp();

        // Create all required mocks with intersection types for PHPStan compliance
        /** @var ExtensionConfiguration&MockObject $extensionConfigurationMock */
        $extensionConfigurationMock = $this->createMock(ExtensionConfiguration::class);

        /** @var LogManager&MockObject $logManagerMock */
        $logManagerMock = $this->createMock(LogManager::class);

        /** @var ResourceFactory&MockObject $resourceFactoryMock */
        $resourceFactoryMock = $this->createMock(ResourceFactory::class);

        /** @var Context&MockObject $contextMock */
        $contextMock = $this->createMock(Context::class);

        /** @var RequestFactory&MockObject $requestFactoryMock */
        $requestFactoryMock = $this->createMock(RequestFactory::class);

        /** @var DefaultUploadFolderResolver&MockObject $uploadFolderResolverMock */
        $uploadFolderResolverMock = $this->createMock(DefaultUploadFolderResolver::class);

        /** @var Logger&MockObject $loggerMock */
        $loggerMock = $this->createMock(Logger::class);

        // Configure extension configuration mock with willReturnCallback
        $extensionConfigurationMock
            ->method('get')
            ->willReturnCallback(function ($extension, $key) {
                if ($extension === 'my_extension') {
                    return match ($key) {
                        'enableFeature' => true,
                        'timeout'       => 30,
                        default         => null,
                    };
                }

                return null;
            });

        // Configure log manager to return logger mock
        $logManagerMock
            ->method('getLogger')
            ->with(MyDataHandlerHook::class)
            ->willReturn($loggerMock);

        // Assign mocks to properties
        $this->extensionConfigurationMock = $extensionConfigurationMock;
        $this->logManagerMock             = $logManagerMock;
        $this->resourceFactoryMock        = $resourceFactoryMock;
        $this->contextMock                = $contextMock;
        $this->requestFactoryMock         = $requestFactoryMock;
        $this->uploadFolderResolverMock   = $uploadFolderResolverMock;
        $this->loggerMock                 = $loggerMock;

        // Create subject with all dependencies
        $this->subject = new MyDataHandlerHook(
            $this->extensionConfigurationMock,
            $this->logManagerMock,
            $this->resourceFactoryMock,
            $this->contextMock,
            $this->requestFactoryMock,
            $this->uploadFolderResolverMock,
        );
    }

    #[Test]
    public function constructorInitializesWithDependencyInjection(): void
    {
        // Verify subject was created successfully with all dependencies
        self::assertInstanceOf(MyDataHandlerHook::class, $this->subject);
    }

    #[Test]
    public function processDatamapPostProcessFieldArrayHandlesFieldCorrectly(): void
    {
        $status     = 'update';
        $table      = 'tt_content';
        $id         = '123';
        $fieldArray = ['bodytext' => '<p>Content with processing</p>'];

        /** @var DataHandler&MockObject $dataHandlerMock */
        $dataHandlerMock = $this->createMock(DataHandler::class);

        // Mock TCA configuration for RTE field
        $GLOBALS['TCA']['tt_content']['columns']['bodytext']['config'] = [
            'type'        => 'text',
            'enableRichtext' => true,
        ];

        // Test the hook processes the field
        $this->subject->processDatamap_postProcessFieldArray(
            $status,
            $table,
            $id,
            $fieldArray,
            $dataHandlerMock,
        );

        // Assert field was processed (actual assertion depends on implementation)
        self::assertNotEmpty($fieldArray['bodytext']);
    }

    #[Test]
    public function constructorLoadsExtensionConfiguration(): void
    {
        /** @var ExtensionConfiguration&MockObject $configMock */
        $configMock = $this->createMock(ExtensionConfiguration::class);
        $configMock
            ->expects(self::exactly(2))
            ->method('get')
            ->willReturnCallback(function ($extension, $key) {
                self::assertSame('my_extension', $extension);

                return match ($key) {
                    'enableFeature' => true,
                    'timeout'       => 30,
                    default         => null,
                };
            });

        new MyDataHandlerHook(
            $configMock,
            $this->logManagerMock,
            $this->resourceFactoryMock,
            $this->contextMock,
            $this->requestFactoryMock,
            $this->uploadFolderResolverMock,
        );
    }
}
```

**Key Testing Patterns for DataHandler Hooks:**

1. **Intersection Types for PHPStan**: Use `ResourceFactory&MockObject` for strict type compliance
2. **TCA Globals**: Set `$GLOBALS['TCA']` in tests to simulate TYPO3 table configuration
3. **Extension Configuration**: Use `willReturnCallback` with `match` expressions for flexible config mocking
4. **DataHandler Mock**: Create mock for `$dataHandler` parameter (required in hook signature)
5. **Reset Singletons**: Always set `protected bool $resetSingletonInstances = true;`
6. **Constructor DI**: Inject all dependencies via constructor (TYPO3 13+ best practice)

## Resources

- [TYPO3 Unit Testing Documentation](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/UnitTests.html)
- [PHPUnit Documentation](https://phpunit.de/documentation.html)
- [PHPUnit 11 Migration Guide](https://phpunit.de/announcements/phpunit-11.html)
- [TYPO3 DataHandler Hooks](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/Hooks/DataHandler/Index.html)
