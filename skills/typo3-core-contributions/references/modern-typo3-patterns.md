# Modern TYPO3 Core Patterns

Architectural patterns and best practices for TYPO3 Core contributions in v13+.

## PHP 8 Attributes for Auto-Discovery

TYPO3 v13+ uses PHP 8 Attributes for automatic class discovery and registration. This replaces manual configuration arrays and makes code more self-documenting.

### Pattern: Attribute-Based Registration

**Creating a Discovery Attribute:**

```php
<?php

declare(strict_types=1);

namespace TYPO3\CMS\Install\ExtensionScanner\Php\Matcher;

/**
 * Attribute to mark a class for automatic discovery.
 *
 * @internal This class is only meant to be used within EXT:install
 */
#[\Attribute(\Attribute::TARGET_CLASS)]
final class ExtensionScannerMatcher
{
    public function __construct(
        public readonly ?string $configurationFile = null
    ) {}
}
```

**Using the Attribute:**

```php
<?php

declare(strict_types=1);

namespace TYPO3\CMS\Install\ExtensionScanner\Php\Matcher;

#[ExtensionScannerMatcher]
class ArrayDimensionMatcher extends AbstractCoreMatcher
{
    // Implementation...
}

// With custom configuration file
#[ExtensionScannerMatcher('CustomConfig.php')]
class SpecialMatcher extends AbstractCoreMatcher
{
    // Implementation...
}
```

**Registry for Discovery:**

```php
<?php

declare(strict_types=1);

namespace TYPO3\CMS\Install\ExtensionScanner\Php;

class MatcherRegistry
{
    private ?array $matcherClasses = null;

    public function getMatcherClasses(): array
    {
        if ($this->matcherClasses !== null) {
            return $this->matcherClasses;
        }

        $this->discoverMatchers();
        return $this->matcherClasses;
    }

    private function discoverMatchers(): void
    {
        $this->matcherClasses = [];
        $matcherDirectory = GeneralUtility::getFileAbsFileName('EXT:install/Classes/.../Matcher/');

        foreach (glob($matcherDirectory . '*.php') as $phpFile) {
            $className = 'TYPO3\\CMS\\Install\\...' . pathinfo($phpFile, PATHINFO_FILENAME);

            if (!class_exists($className)) {
                continue;
            }

            $reflection = new \ReflectionClass($className);

            // Skip abstract classes
            if ($reflection->isAbstract()) {
                continue;
            }

            // Check for attribute
            $attributes = $reflection->getAttributes(ExtensionScannerMatcher::class);
            if (empty($attributes)) {
                continue;
            }

            $this->matcherClasses[] = $className;
        }
    }
}
```

### TYPO3's registerAttributeForAutoconfiguration Pattern

For DI-integrated auto-discovery, TYPO3 uses `registerAttributeForAutoconfiguration()` in `Configuration/Services.php`:

```php
<?php

declare(strict_types=1);

namespace TYPO3\CMS\Core;

use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

return static function (ContainerConfigurator $container, ContainerBuilder $containerBuilder) {
    // Register attribute for auto-tagging
    $containerBuilder->registerAttributeForAutoconfiguration(
        Attribute\AsEventListener::class,
        static function (ChildDefinition $definition, AsEventListener $attribute): void {
            $definition->addTag(AsEventListener::TAG_NAME, [
                'identifier' => $attribute->identifier,
                'event' => $attribute->event,
                'method' => $attribute->method,
                'before' => $attribute->before,
                'after' => $attribute->after,
            ]);
        }
    );
};
```

**Attribute with TAG_NAME constant:**

```php
<?php

declare(strict_types=1);

namespace TYPO3\CMS\Core\Attribute;

#[\Attribute(\Attribute::TARGET_CLASS | \Attribute::TARGET_METHOD | \Attribute::IS_REPEATABLE)]
final class AsEventListener
{
    public const TAG_NAME = 'event.listener';

    public function __construct(
        public readonly ?string $identifier = null,
        public readonly ?string $event = null,
        public readonly ?string $method = null,
        public readonly ?string $before = null,
        public readonly ?string $after = null,
    ) {}
}
```

### When to Use Each Pattern

| Pattern | Use Case | DI Integration |
|---------|----------|----------------|
| Simple Attribute + Registry | Internal discovery, no DI needed | No |
| registerAttributeForAutoconfiguration | Public API, DI services | Yes |

**Real TYPO3 Core Examples:**
- `AsEventListener` - Event listener registration
- `AsController` - Backend controller registration
- `UpgradeWizard` - Upgrade wizard discovery
- `AsSchedulableTask` - Scheduler task registration

## Error Handling Patterns

### Silent Failure with Graceful Degradation

When loading external configuration that might be malformed:

```php
// Load configuration, skip matcher if config file is malformed
try {
    $configuration = require $configPath;
} catch (\Throwable) {
    // Configuration file has syntax errors or other issues
    // Skip this matcher rather than crashing the entire scanner
    continue;
}

// Only add to registry after successful load
$this->matcherClasses[] = $className;
$this->matcherConfigurations[$className] = $configuration;
```

**Trade-off Consideration:**
- **Silent failure**: System continues working, but debugging is harder
- **Recommendation from reviewers**: Add `trigger_error()` or logging:

```php
try {
    $configuration = require $configPath;
} catch (\Throwable $e) {
    trigger_error(
        sprintf('Failed to load matcher configuration %s: %s', $configPath, $e->getMessage()),
        E_USER_WARNING
    );
    continue;
}
```

## Memoization Pattern

Cache expensive operations in nullable properties:

```php
class MatcherRegistry
{
    private ?array $matcherClasses = null;
    private ?array $matcherConfigurations = null;

    public function getMatcherClasses(): array
    {
        if ($this->matcherClasses !== null) {
            return $this->matcherClasses;
        }

        $this->discoverMatchers();
        return $this->matcherClasses;
    }

    public function getMatcherConfigurations(): array
    {
        if ($this->matcherConfigurations !== null) {
            return $this->matcherConfigurations;
        }

        $this->discoverMatchers();
        return $this->matcherConfigurations;
    }

    private function discoverMatchers(): void
    {
        // Populate both arrays in single discovery pass
        $this->matcherClasses = [];
        $this->matcherConfigurations = [];
        // ... discovery logic
    }
}
```

**Benefits:**
- Lazy initialization (only compute when needed)
- Single computation even with multiple calls
- Atomic population (both arrays filled together)

## Convention over Configuration

**File naming conventions:**
- Matcher class `ArrayDimensionMatcher` → Config file `ArrayDimensionMatcher.php`
- Override via attribute: `#[ExtensionScannerMatcher('CustomConfig.php')]`

```php
// Determine configuration file name
$configFile = $attribute->configurationFile ?? $reflection->getShortName() . '.php';
$configPath = $configurationDirectory . $configFile;
```

## PHPStan Level 9+ Compatibility

### Test-Specific Ignore Patterns

When tests validate runtime behavior that PHPStan already knows from types:

```php
#[Test]
public function allDiscoveredMatcherClassesExtendAbstractCoreMatcher(): void
{
    $subject = new MatcherRegistry();
    $result = $subject->getMatcherClasses();

    foreach ($result as $matcherClass) {
        // @phpstan-ignore staticMethod.alreadyNarrowedType
        self::assertTrue(
            is_subclass_of($matcherClass, AbstractCoreMatcher::class), // @phpstan-ignore function.alreadyNarrowedType
            sprintf('%s should extend AbstractCoreMatcher', $matcherClass)
        );
    }
}
```

**Common identifiers:**
- `staticMethod.alreadyNarrowedType` - For assertTrue/assertFalse/assertIsArray
- `function.alreadyNarrowedType` - For is_subclass_of/is_array/is_string

## Code Review Insights

From real TYPO3 Core review feedback:

### Multi-Model Consensus Findings

**Strengths typically approved:**
- Modern PHP 8 patterns (attributes, named arguments, constructor promotion)
- Strong typing with `declare(strict_types=1)`
- Memoization for expensive operations
- Convention-over-configuration approaches

**Common review concerns:**
1. **Silent failures** - Reviewers prefer logging/trigger_error over silent catch
2. **Test brittleness** - `assertCount(22)` breaks when matchers added; prefer `assertGreaterThan(0)`
3. **Flat directory assumption** - Document if subdirectories aren't supported
4. **DI bypass** - `new $class()` prevents future service injection

### Reviewer Expectations

- **Architectural alignment**: Use framework patterns, don't reinvent
- **Study existing code**: Match patterns in affected areas
- **Multiple revisions normal**: 7-24 patch sets common for complex features
- **Documentation**: Comment non-obvious design decisions

## Resources

- [TYPO3 Core Coding Guidelines](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/CodingGuidelines/)
- [PHP 8 Attributes RFC](https://wiki.php.net/rfc/attributes_v2)
- [Symfony DI Auto-configuration](https://symfony.com/doc/current/service_container/tags.html#autoconfiguring-tags)
