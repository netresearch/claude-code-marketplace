# PHPStan Compliance Guide

## Configuration Levels

### Level Overview

| Level | Description | Checks Added |
|-------|-------------|--------------|
| 0 | Basic checks | Unknown classes, functions, methods |
| 1 | + Return types | Possibly undefined variables, unknown magic methods |
| 2 | + Dead code | Unknown methods on `$this` |
| 3 | + Method returns | Phpdoc types verification |
| 4 | + Basic dead code | Unreachable code, always true/false |
| 5 | + Argument types | Argument types in function calls |
| 6 | + Type hints | Missing type hints |
| 7 | + Union types | Partially wrong union types |
| 8 | + Nullable | Possibly null values |
| 9 | + Mixed | Mixed type strictness |
| 10 | Max | strictest mode, experimental features |

### Recommended Production Configuration

```neon
# phpstan.neon
parameters:
    level: 9
    paths:
        - src
        - tests
    excludePaths:
        - src/Kernel.php
        - src/*/Tests/*

    # Strict typing
    checkMissingIterableValueType: true
    checkGenericClassInNonGenericObjectType: true
    reportUnmatchedIgnoredErrors: true

    # Memory and performance
    parallel:
        maximumNumberOfProcesses: 4
        processTimeout: 300.0

    # Error handling
    reportStaticMethodSignatures: true

    # Type coverage
    typeAliases:
        UserId: 'int<1, max>'
        Email: 'non-empty-string'
        PositiveInt: 'int<1, max>'
```

## Common Error Fixes

### Parameter Type Errors

```php
// Error: Parameter #1 $items of method expects array<User>, array given
// Before:
public function processUsers(array $items): void

// Fix 1: Add PHPDoc annotation
/** @param array<User> $items */
public function processUsers(array $items): void

// Fix 2: Add runtime validation
public function processUsers(array $items): void
{
    $items = ArrayTypeHelper::ensureArrayOf($items, User::class);
    // Now PHPStan knows $items is array<User>
}
```

### Return Type Errors

```php
// Error: Method should return User but returns User|null
// Before:
public function getUser(): User
{
    return $this->repository->find($id);  // Can return null
}

// Fix 1: Add null check
public function getUser(int $id): User
{
    $user = $this->repository->find($id);
    if ($user === null) {
        throw new UserNotFoundException($id);
    }
    return $user;
}

// Fix 2: Change return type
public function getUser(int $id): ?User
{
    return $this->repository->find($id);
}
```

### Property Type Errors

```php
// Error: Property $createdAt is never assigned
// Before:
class Entity
{
    private \DateTimeImmutable $createdAt;
}

// Fix: Initialize in constructor or make nullable
class Entity
{
    private \DateTimeImmutable $createdAt;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
    }
}

// Or with default value
class Entity
{
    private ?\DateTimeImmutable $createdAt = null;
}
```

### Mixed Type Errors (Level 9)

```php
// Error: Cannot call method getName() on mixed
// Before:
foreach ($items as $item) {
    echo $item->getName();
}

// Fix 1: Type assertion
foreach ($items as $item) {
    assert($item instanceof User);
    echo $item->getName();
}

// Fix 2: PHPDoc type hint
/** @var array<User> $items */
foreach ($items as $item) {
    echo $item->getName();
}

// Fix 3: instanceof check
foreach ($items as $item) {
    if ($item instanceof User) {
        echo $item->getName();
    }
}
```

### Iterable Value Type

```php
// Error: Missing value type in iterable type array
// Before:
public function getItems(): array

// Fix: Specify element type
/** @return array<int, Item> */
public function getItems(): array

// Or for associative arrays:
/** @return array<string, mixed> */
public function getConfig(): array
```

## Type Aliases and Custom Types

### Defining Type Aliases

```neon
# phpstan.neon
parameters:
    typeAliases:
        # Scalar constraints
        UserId: 'int<1, max>'
        Email: 'non-empty-string'
        Percentage: 'int<0, 100>'

        # Complex types
        UserArray: 'array<int, \App\Entity\User>'
        ConfigArray: 'array{name: string, enabled: bool, options?: array<string, mixed>}'

        # Callable types
        UserValidator: 'callable(\App\Entity\User): bool'
```

### Using Type Aliases

```php
/**
 * @param UserId $id
 * @return UserArray
 */
public function getUsersById(int $id): array
{
    // PHPStan knows this returns array<int, User>
}

/**
 * @param ConfigArray $config
 */
public function configure(array $config): void
{
    // PHPStan knows exact structure
}
```

## Generics

### Template Annotations

```php
/**
 * @template T
 */
interface RepositoryInterface
{
    /**
     * @return T|null
     */
    public function find(int $id): ?object;

    /**
     * @return array<T>
     */
    public function findAll(): array;

    /**
     * @param T $entity
     */
    public function save(object $entity): void;
}

/**
 * @implements RepositoryInterface<User>
 */
class UserRepository implements RepositoryInterface
{
    public function find(int $id): ?User
    {
        return $this->em->find(User::class, $id);
    }

    /** @return array<User> */
    public function findAll(): array
    {
        return $this->em->getRepository(User::class)->findAll();
    }

    public function save(object $entity): void
    {
        assert($entity instanceof User);
        $this->em->persist($entity);
        $this->em->flush();
    }
}
```

### Template Constraints

```php
/**
 * @template T of EntityInterface
 */
abstract class AbstractRepository
{
    /**
     * @return class-string<T>
     */
    abstract protected function getEntityClass(): string;

    /**
     * @return T|null
     */
    public function find(int $id): ?EntityInterface
    {
        return $this->em->find($this->getEntityClass(), $id);
    }
}
```

## Ignoring Errors

### Inline Ignores

```php
// Ignore specific error on next line
/** @phpstan-ignore-next-line */
$result = $unknownMethod();

// Ignore with reason
/** @phpstan-ignore-next-line We trust this external API */
$data = $client->getData();
```

### Configuration Ignores

```neon
parameters:
    ignoreErrors:
        # Ignore specific message pattern
        - '#Call to an undefined method [^:]+::getId\(\)#'

        # Ignore in specific file
        -
            message: '#Parameter .* expects string, int given#'
            path: src/Legacy/*

        # Ignore with count limit
        -
            message: '#Access to an undefined property#'
            count: 3
            path: src/ThirdParty/Adapter.php
```

### Baseline Generation

```bash
# Generate baseline for existing errors
vendor/bin/phpstan analyse --generate-baseline

# Use baseline
# phpstan.neon:
includes:
    - phpstan-baseline.neon

# Gradually fix errors by regenerating baseline
vendor/bin/phpstan analyse --generate-baseline
```

## Custom Rules

### Creating Custom Rules

```php
<?php

declare(strict_types=1);

namespace App\PHPStan\Rules;

use PhpParser\Node;
use PhpParser\Node\Expr\MethodCall;
use PHPStan\Analyser\Scope;
use PHPStan\Rules\Rule;
use PHPStan\Rules\RuleErrorBuilder;

/**
 * @implements Rule<MethodCall>
 */
final class NoDirectEntityManagerFlushRule implements Rule
{
    public function getNodeType(): string
    {
        return MethodCall::class;
    }

    public function processNode(Node $node, Scope $scope): array
    {
        if (!$node->name instanceof Node\Identifier) {
            return [];
        }

        if ($node->name->name !== 'flush') {
            return [];
        }

        $type = $scope->getType($node->var);

        if ($type->getObjectClassNames() === ['Doctrine\ORM\EntityManagerInterface']) {
            return [
                RuleErrorBuilder::message(
                    'Direct EntityManager::flush() calls are forbidden. Use UnitOfWork pattern.'
                )->build(),
            ];
        }

        return [];
    }
}
```

### Registering Custom Rules

```neon
services:
    -
        class: App\PHPStan\Rules\NoDirectEntityManagerFlushRule
        tags:
            - phpstan.rules.rule
```

## Extension Integration

### Symfony Extension

```neon
# phpstan.neon
includes:
    - vendor/phpstan/phpstan-symfony/extension.neon
    - vendor/phpstan/phpstan-symfony/rules.neon

parameters:
    symfony:
        containerXmlPath: var/cache/dev/App_KernelDevDebugContainer.xml
        consoleApplicationLoader: tests/console-application.php
```

### Doctrine Extension

```neon
includes:
    - vendor/phpstan/phpstan-doctrine/extension.neon
    - vendor/phpstan/phpstan-doctrine/rules.neon

parameters:
    doctrine:
        objectManagerLoader: tests/object-manager.php
```

### PHPUnit Extension

```neon
includes:
    - vendor/phpstan/phpstan-phpunit/extension.neon
    - vendor/phpstan/phpstan-phpunit/rules.neon
```

## CI Integration

### GitHub Actions

```yaml
name: PHPStan

on: [push, pull_request]

jobs:
  phpstan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          coverage: none

      - name: Install dependencies
        run: composer install --no-progress

      - name: Run PHPStan
        run: vendor/bin/phpstan analyse --error-format=github
```

### Composer Script

```json
{
    "scripts": {
        "phpstan": "phpstan analyse",
        "phpstan:baseline": "phpstan analyse --generate-baseline",
        "test:static": [
            "@phpstan",
            "@psalm"
        ]
    }
}
```
