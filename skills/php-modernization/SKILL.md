---
name: php-modernization
description: "Agent Skill: PHP 8.x modernization patterns for upgrading legacy PHP applications. This skill should be used when modernizing PHP codebases to PHP 8.1/8.2/8.3, implementing type safety and strict typing, adopting Symfony best practices, or achieving PHPStan level 9+ compliance. Covers constructor property promotion, readonly classes, enums, attributes, generics via PHPDoc, and migration strategies. By Netresearch."
---

# PHP Modernization Skill

Expert patterns for modernizing PHP applications to PHP 8.x with type safety, Symfony best practices, and static analysis compliance.

## Expertise Areas

### PHP 8.x Features
- Constructor property promotion
- Readonly properties and classes
- Named arguments
- Enums and match expressions
- Attributes (replacing annotations)
- Union and intersection types
- Nullsafe operator

### Type Safety Patterns
- Generic collection typing via PHPDoc
- ArrayTypeHelper for type-safe array operations
- Strict typing enforcement
- PHPStan level 9+ compliance
- Runtime type validation

### Symfony Integration
- Dependency injection patterns
- Service configuration (YAML → PHP)
- Event dispatcher and PSR-14
- Form handling modernization
- Security component updates

## Reference Files

- `references/php8-features.md` - PHP 8.0-8.4 feature adoption patterns
- `references/type-safety.md` - Type system maximization strategies
- `references/symfony-patterns.md` - Modern Symfony architecture
- `references/phpstan-compliance.md` - Static analysis configuration
- `references/migration-strategies.md` - Version upgrade planning

## Core Patterns

### Constructor Property Promotion

```php
// Before PHP 8.0
class User
{
    private string $name;
    private string $email;

    public function __construct(string $name, string $email)
    {
        $this->name = $name;
        $this->email = $email;
    }
}

// PHP 8.0+ with promotion
class User
{
    public function __construct(
        private string $name,
        private string $email,
    ) {}
}

// PHP 8.2+ readonly class
readonly class UserDTO
{
    public function __construct(
        public string $name,
        public string $email,
        public ?string $phone = null,
    ) {}
}
```

### ArrayTypeHelper Pattern

```php
/**
 * Type-safe array operations with PHPStan generics
 */
final class ArrayTypeHelper
{
    /**
     * @template T
     * @param array<mixed> $array
     * @param class-string<T> $type
     * @return array<T>
     * @throws \InvalidArgumentException
     */
    public static function ensureArrayOf(array $array, string $type): array
    {
        foreach ($array as $key => $item) {
            if (!$item instanceof $type) {
                throw new \InvalidArgumentException(
                    sprintf('Item at key "%s" must be instance of %s', $key, $type)
                );
            }
        }
        return $array;
    }

    /**
     * @template T
     * @param array<mixed> $array
     * @param class-string<T> $type
     * @return array<T>
     */
    public static function filterByType(array $array, string $type): array
    {
        return array_filter($array, fn($item) => $item instanceof $type);
    }

    /**
     * @param array<mixed> $array
     * @return array<string>
     */
    public static function ensureStringArray(array $array): array
    {
        return array_map(
            fn($item) => is_string($item) ? $item : throw new \InvalidArgumentException('Expected string'),
            $array
        );
    }
}
```

### Modern Enum Usage

```php
enum Status: string
{
    case DRAFT = 'draft';
    case PUBLISHED = 'published';
    case ARCHIVED = 'archived';

    public function label(): string
    {
        return match($this) {
            self::DRAFT => 'Draft',
            self::PUBLISHED => 'Published',
            self::ARCHIVED => 'Archived',
        };
    }

    public function isEditable(): bool
    {
        return $this === self::DRAFT;
    }

    /**
     * @return array<string, string>
     */
    public static function choices(): array
    {
        return array_combine(
            array_column(self::cases(), 'value'),
            array_map(fn($case) => $case->label(), self::cases())
        );
    }
}
```

### Service Configuration (Symfony)

```php
// config/services.php
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

return static function (ContainerConfigurator $container): void {
    $services = $container->services()
        ->defaults()
            ->autowire()
            ->autoconfigure();

    $services->load('App\\', '../src/')
        ->exclude('../src/{DependencyInjection,Entity,Kernel.php}');

    // Named service with specific configuration
    $services->set(CacheService::class)
        ->arg('$ttl', '%cache.ttl%')
        ->tag('app.cache_warmer');
};
```

### PHPStan Level 9 Configuration

```neon
# phpstan.neon
parameters:
    level: 9
    paths:
        - src
        - tests
    excludePaths:
        - src/Kernel.php

    # Strict rules
    checkMissingIterableValueType: true
    checkGenericClassInNonGenericObjectType: true
    reportUnmatchedIgnoredErrors: true

    # Custom rules
    ignoreErrors:
        - '#Call to an undefined method [^:]+::getId\(\)#'

    # Type coverage
    typeAliases:
        UserId: 'int<1, max>'
        Email: 'non-empty-string'
```

## Migration Checklist

### PHP Version Upgrade
- [ ] Update composer.json PHP requirement
- [ ] Enable strict_types in all files
- [ ] Replace annotations with attributes
- [ ] Convert to constructor property promotion
- [ ] Use readonly where applicable
- [ ] Replace switch with match expressions
- [ ] Adopt enums for status/type constants
- [ ] Update PHPStan to highest stable level

### Type Safety Enhancement
- [ ] Add return types to all methods
- [ ] Add parameter types to all methods
- [ ] Use union types instead of mixed
- [ ] Implement ArrayTypeHelper for collections
- [ ] Add @template annotations for generics
- [ ] Remove @var annotations where inferrable
- [ ] Configure PHPStan strict rules

### Symfony Modernization
- [ ] Convert YAML config to PHP
- [ ] Use constructor injection exclusively
- [ ] Implement EventSubscriberInterface
- [ ] Use attributes for routing
- [ ] Modernize form types
- [ ] Update security configuration

## Anti-Patterns to Avoid

### Type Erosion
```php
// Bad: Type information lost
/** @var User[] */
private array $users = [];

public function getUsers(): array  // Returns array, not User[]
{
    return $this->users;
}

// Good: Type preserved
/** @var array<int, User> */
private array $users = [];

/** @return array<int, User> */
public function getUsers(): array
{
    return $this->users;
}
```

### Mixed Usage
```php
// Bad: mixed allows anything
public function process(mixed $data): mixed

// Good: Union types for known possibilities
public function process(string|array|RequestInterface $data): ResponseInterface
```

### Array Shape Neglect
```php
// Bad: Untyped array
public function getConfig(): array

// Good: Documented shape
/**
 * @return array{
 *     host: string,
 *     port: int<1, 65535>,
 *     ssl: bool,
 *     timeout?: int
 * }
 */
public function getConfig(): array
```

## Verification

Run the verification script to check PHP modernization status:

```bash
./scripts/verify-php-project.sh /path/to/project
```

## Related Skills

- **security-audit-skill**: Security patterns for PHP applications
- **typo3-testing-skill**: PHPUnit patterns (applicable to any PHP project)
