# Architecture Testing with phpat

PHP Architecture Tester (phpat) enforces architectural rules through automated tests.

## Installation

```bash
composer require --dev carlosas/phpat
```

## Configuration

Create `phpat.php` in project root:

```php
<?php

declare(strict_types=1);

use PhpAT\Rule\Rule;
use PhpAT\Selector\Selector;
use PhpAT\Test\ArchitectureTest;

final class ArchitectureTests extends ArchitectureTest
{
    public function testServicesDoNotDependOnControllers(): Rule
    {
        return $this->newRule
            ->classesThat(Selector::haveClassName('*Service'))
            ->mustNotDependOn()
            ->classesThat(Selector::haveClassName('*Controller'))
            ->build();
    }

    public function testDomainDoesNotDependOnInfrastructure(): Rule
    {
        return $this->newRule
            ->classesThat(Selector::havePath('Domain/*'))
            ->mustNotDependOn()
            ->classesThat(Selector::havePath('Infrastructure/*'))
            ->build();
    }

    public function testEventsAreReadonly(): Rule
    {
        return $this->newRule
            ->classesThat(Selector::havePath('Event/*'))
            ->mustBeReadonly()
            ->build();
    }
}
```

## TYPO3 Extension Rules

### Layer Constraints

```php
public function testCleanArchitecture(): Rule
{
    return $this->newRule
        ->classesThat(Selector::havePath('Classes/Domain/*'))
        ->mustNotDependOn()
        ->classesThat(Selector::havePath('Classes/Controller/*'))
        ->andClassesThat(Selector::havePath('Classes/Command/*'))
        ->build();
}
```

### Service Layer Rules

```php
public function testServicesHaveInterface(): Rule
{
    return $this->newRule
        ->classesThat(Selector::haveClassName('*Service'))
        ->excludingClassesThat(Selector::haveClassName('*Interface'))
        ->mustImplement()
        ->classesThat(Selector::haveClassName('*Interface'))
        ->build();
}
```

## Running Tests

```bash
# Via PHPUnit
vendor/bin/phpunit --testsuite Architecture

# Via runTests.sh
Build/Scripts/runTests.sh -s architecture
```

## PHPUnit Configuration

Add to `phpunit.xml`:

```xml
<testsuite name="Architecture">
    <file>phpat.php</file>
</testsuite>
```

## Common Rules

| Rule | Purpose |
|------|---------|
| `mustNotDependOn` | Prevent unwanted dependencies |
| `mustImplement` | Enforce interface usage |
| `mustBeReadonly` | Enforce immutability (PHP 8.2+) |
| `mustBeFinal` | Prevent inheritance |
| `mustNotConstruct` | Enforce DI |

## Security-Critical Extensions

For security-critical code, enforce:

1. Events are readonly
2. Services don't construct other services (use DI)
3. Domain layer is isolated
4. No circular dependencies
