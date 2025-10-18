# Unit Testing in TYPO3

Unit tests are fast, isolated tests that verify individual components without external dependencies like databases or file systems.

## When to Use Unit Tests

- Testing pure business logic
- Validators, calculators, transformers
- Value objects and DTOs
- Utilities and helper functions
- Domain models without persistence

## Base Class

All unit tests extend `TYPO3\TestingFramework\Core\Unit\UnitTestCase`:

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\Domain\Validator;

use TYPO3\TestingFramework\Core\Unit\UnitTestCase;
use Vendor\Extension\Domain\Validator\EmailValidator;

final class EmailValidatorTest extends UnitTestCase
{
    protected EmailValidator $subject;

    protected function setUp(): void
    {
        parent::setUp();
        $this->subject = new EmailValidator();
    }

    /**
     * @test
     */
    public function validEmailPassesValidation(): void
    {
        $result = $this->subject->validate('user@example.com');
        self::assertFalse($result->hasErrors());
    }

    /**
     * @test
     */
    public function invalidEmailFailsValidation(): void
    {
        $result = $this->subject->validate('invalid-email');
        self::assertTrue($result->hasErrors());
    }
}
```

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

## Mocking Dependencies

Use Prophecy (included in TYPO3 testing framework) for mocking:

```php
use Prophecy\PhpUnit\ProphecyTrait;

final class UserServiceTest extends UnitTestCase
{
    use ProphecyTrait;

    /**
     * @test
     */
    public function findsUserByEmail(): void
    {
        // Create mock repository
        $repository = $this->prophesize(UserRepository::class);
        $repository->findByEmail('test@example.com')
            ->willReturn(new User('John'));

        // Inject mock into service
        $service = new UserService($repository->reveal());

        // Test service
        $user = $service->getUserByEmail('test@example.com');

        self::assertSame('John', $user->getName());
    }
}
```

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

Don't test private methods directly. Test them through public API:

```php
// ❌ Don't do this
$reflection = new \ReflectionClass($subject);
$method = $reflection->getMethod('privateMethod');
$method->setAccessible(true);
$result = $method->invoke($subject);

// ✅ Do this instead
$result = $subject->publicMethodThatUsesPrivateMethod();
self::assertSame($expected, $result);
```

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

## Resources

- [TYPO3 Unit Testing Documentation](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/UnitTests.html)
- [PHPUnit Documentation](https://phpunit.de/documentation.html)
- [Prophecy Documentation](https://github.com/phpspec/prophecy)
