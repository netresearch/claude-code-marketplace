# Testing TYPO3 v14 Final Classes

TYPO3 v14 introduces many `final` and `readonly` classes that cannot be mocked directly. This guide covers patterns to maintain testability.

## The Problem

TYPO3 v14 follows modern PHP best practices with `final readonly` classes:

```php
// TYPO3 Core - cannot be mocked
final readonly class SiteConfigurationLoadedEvent
{
    public function __construct(
        private string $siteIdentifier,
        private array $configuration,
    ) {}
}
```

Attempting to mock these classes throws:

```
PHPUnit\Framework\MockObject\Generator\ClassIsFinalException:
Class "TYPO3\CMS\Core\Configuration\Event\SiteConfigurationLoadedEvent" is declared "final" and cannot be mocked.
```

## Pattern 1: Interface Extraction for Dependencies

When your class depends on a final class that you control, extract an interface.

### Before (Untestable)

```php
// Your final class
final class SiteConfigurationVaultProcessor
{
    public function processConfiguration(array $configuration): array { }
}

// Consumer - cannot mock the dependency
final readonly class SiteConfigurationVaultListener
{
    public function __construct(
        private SiteConfigurationVaultProcessor $processor,  // Cannot mock!
    ) {}
}
```

### After (Testable)

**Step 1: Create Interface**

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Configuration;

interface SiteConfigurationVaultProcessorInterface
{
    /**
     * @param array<string, mixed> $configuration
     * @return array<string, mixed>
     */
    public function processConfiguration(array $configuration): array;
}
```

**Step 2: Implement Interface**

```php
final class SiteConfigurationVaultProcessor implements SiteConfigurationVaultProcessorInterface
{
    public function processConfiguration(array $configuration): array
    {
        // Implementation
    }
}
```

**Step 3: Register in Services.yaml**

```yaml
services:
  Vendor\Extension\Configuration\SiteConfigurationVaultProcessorInterface:
    alias: Vendor\Extension\Configuration\SiteConfigurationVaultProcessor
    public: true
```

**Step 4: Inject Interface**

```php
final readonly class SiteConfigurationVaultListener
{
    public function __construct(
        private SiteConfigurationVaultProcessorInterface $processor,  // Mockable!
    ) {}
}
```

**Step 5: Mock Interface in Tests**

```php
final class SiteConfigurationVaultListenerTest extends UnitTestCase
{
    private SiteConfigurationVaultProcessorInterface&MockObject $processor;
    private SiteConfigurationVaultListener $listener;

    protected function setUp(): void
    {
        parent::setUp();
        $this->processor = $this->createMock(SiteConfigurationVaultProcessorInterface::class);
        $this->listener = new SiteConfigurationVaultListener($this->processor);
    }

    #[Test]
    public function processesConfigurationWithVaultReferences(): void
    {
        $originalConfig = ['apiKey' => '%vault(my_key)%'];
        $processedConfig = ['apiKey' => 'resolved_secret'];

        $this->processor
            ->expects($this->once())
            ->method('processConfiguration')
            ->with($originalConfig)
            ->willReturn($processedConfig);

        // Test your listener...
    }
}
```

## Pattern 2: Real Event Instances for Final Events

TYPO3 PSR-14 events are often final. Create real instances instead of mocks.

### Wrong - Will Fail

```php
#[Test]
public function handlesEvent(): void
{
    // ClassIsFinalException!
    $event = $this->createMock(SiteConfigurationLoadedEvent::class);
}
```

### Correct - Real Instance

```php
#[Test]
public function handlesEvent(): void
{
    // Create real event - it's a simple value object
    $config = ['apiKey' => '%vault(my_key)%'];
    $event = new SiteConfigurationLoadedEvent('test-site', $config);

    // Mock the dependency, not the event
    $this->processor
        ->method('processConfiguration')
        ->willReturn(['apiKey' => 'resolved']);

    ($this->listener)($event);

    self::assertSame(['apiKey' => 'resolved'], $event->getConfiguration());
}
```

### Complete Test Example

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\EventListener;

use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\TestCase;
use TYPO3\CMS\Core\Configuration\Event\SiteConfigurationLoadedEvent;
use Vendor\Extension\Configuration\SiteConfigurationVaultProcessorInterface;
use Vendor\Extension\EventListener\SiteConfigurationVaultListener;

#[CoversClass(SiteConfigurationVaultListener::class)]
final class SiteConfigurationVaultListenerTest extends TestCase
{
    private SiteConfigurationVaultProcessorInterface&MockObject $processor;
    private SiteConfigurationVaultListener $listener;

    protected function setUp(): void
    {
        parent::setUp();
        $this->processor = $this->createMock(SiteConfigurationVaultProcessorInterface::class);
        $this->listener = new SiteConfigurationVaultListener($this->processor);
    }

    #[Test]
    public function skipsProcessingWhenNoVaultReferences(): void
    {
        $config = [
            'base' => 'https://example.com',
            'languages' => [],
        ];

        // Real event instance - not mocked
        $event = new SiteConfigurationLoadedEvent('test-site', $config);

        $this->processor->expects($this->never())->method('processConfiguration');

        ($this->listener)($event);

        self::assertSame($config, $event->getConfiguration());
    }

    #[Test]
    public function processesConfigurationWithVaultReferences(): void
    {
        $originalConfig = ['apiKey' => '%vault(my_key)%'];
        $processedConfig = ['apiKey' => 'resolved_secret'];

        // Real event instance
        $event = new SiteConfigurationLoadedEvent('test-site', $originalConfig);

        $this->processor
            ->expects($this->once())
            ->method('processConfiguration')
            ->with($originalConfig)
            ->willReturn($processedConfig);

        ($this->listener)($event);

        self::assertSame($processedConfig, $event->getConfiguration());
    }

    #[Test]
    public function handlesEmptyConfiguration(): void
    {
        $config = [];
        $event = new SiteConfigurationLoadedEvent('test-site', $config);

        $this->processor->expects($this->never())->method('processConfiguration');

        ($this->listener)($event);

        self::assertSame($config, $event->getConfiguration());
    }
}
```

## Pattern 3: Test Suite Organization

Separate tests by bootstrap requirements to avoid skipped tests.

### Directory Structure

```
Tests/
├── Build/
│   ├── phpunit.xml           # Unit + Fuzz (no TYPO3 bootstrap)
│   └── FunctionalTests.xml   # Functional (requires TYPO3)
├── Unit/                     # Fast, isolated, mockable
├── Functional/               # Database, framework integration
└── Fuzz/                     # Property-based testing
```

### phpunit.xml (Unit Tests Only)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/12.5/phpunit.xsd"
    bootstrap="../bootstrap.php"
    colors="true"
    failOnRisky="true"
    failOnWarning="true"
>
    <testsuites>
        <testsuite name="Unit">
            <directory>../Unit</directory>
        </testsuite>
        <testsuite name="Fuzz">
            <directory>../Fuzz</directory>
        </testsuite>
        <!-- Functional tests require TYPO3 bootstrap - run separately -->
    </testsuites>
</phpunit>
```

### FunctionalTests.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/12.5/phpunit.xsd"
    bootstrap="FunctionalTestsBootstrap.php"
    colors="true"
>
    <testsuites>
        <testsuite name="Functional">
            <directory>../Functional</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

### composer.json Scripts

```json
{
    "scripts": {
        "test:unit": "phpunit -c Tests/Build/phpunit.xml",
        "test:functional": "phpunit -c Tests/Build/FunctionalTests.xml",
        "test:all": ["@test:unit", "@test:functional"]
    }
}
```

## Decision Tree: What to Test Where

```
Is the class under test final?
├── Yes → Can you create it directly (simple constructor)?
│   ├── Yes → Create real instance (Pattern 2)
│   └── No → Does it need framework services?
│       ├── Yes → Move to Functional tests
│       └── No → Extract interface for dependency (Pattern 1)
└── No → Mock normally with createMock()
```

## Common TYPO3 v14 Final Classes

| Class | Testing Strategy |
|-------|------------------|
| `SiteConfigurationLoadedEvent` | Create real instance |
| `AfterStdWrapFunctionsExecutedEvent` | Create real instance |
| `ModifyButtonBarEvent` | Create real instance |
| `FlexFormValueContainer` | Move to functional test |
| `DataHandler` (partial) | Mock via interface or functional test |

## Anti-Patterns to Avoid

### Don't Skip Tests

```php
// BAD - leaves gaps in coverage
#[Test]
public function testSomething(): void
{
    $this->markTestSkipped('Cannot mock final class');
}
```

### Don't Use Reflection to Bypass Final

```php
// BAD - fragile and defeats the purpose
$reflection = new ReflectionClass(FinalClass::class);
// ... hack to make it non-final
```

### Don't Copy TYPO3 Classes

```php
// BAD - maintenance nightmare
namespace Vendor\Extension\Tests\Fixtures;
class SiteConfigurationLoadedEvent { } // Copy of TYPO3's class
```

## Summary

1. **Interface Extraction**: For dependencies you control that are final
2. **Real Instances**: For simple value objects like events
3. **Test Suite Separation**: Unit vs Functional based on requirements
4. **Zero Skipped Tests**: Every test should run - reorganize if needed
