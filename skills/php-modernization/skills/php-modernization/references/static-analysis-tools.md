# Static Analysis Tools

Modern PHP projects require a comprehensive static analysis toolchain. This reference covers the **required tools** for quality PHP development.

## Required Toolchain

| Tool | Purpose | Requirement |
|------|---------|-------------|
| PHPStan | Type checking, bug detection | **Level 9 minimum**, level 10 recommended |
| PHPat | Architecture testing | **Required** for projects with defined architecture |
| Rector | Automated refactoring | **Required** for modernization |
| PHP-CS-Fixer | Coding style | **Required** with `@PER-CS` |

## PHPStan (Level 9+)

PHPStan performs static analysis to find bugs without running code.

> **Requirement:** Level 9 minimum, level 10 (max) recommended for production code.

### Installation

```bash
composer require --dev phpstan/phpstan
composer require --dev phpstan/extension-installer

# Recommended extensions
composer require --dev phpstan/phpstan-strict-rules
composer require --dev phpstan/phpstan-deprecation-rules
```

### Configuration

```neon
# phpstan.neon
parameters:
    level: 10  # Maximum strictness (9 is minimum acceptable)
    paths:
        - src
        - tests
    excludePaths:
        - src/*/Tests/*

    # Strict settings
    checkMissingIterableValueType: true
    checkGenericClassInNonGenericObjectType: true
    reportUnmatchedIgnoredErrors: true
    reportStaticMethodSignatures: true

    # Type aliases for domain concepts
    typeAliases:
        UserId: 'int<1, max>'
        Email: 'non-empty-string'
        PositiveInt: 'int<1, max>'
```

### Level Differences

| Level | Added Checks |
|-------|--------------|
| 8 | Nullable values, method existence |
| 9 | **Mixed type strictness** (minimum for production) |
| 10 | **Maximum strictness**, experimental checks |

### Why Level 9+?

Level 9 enforces `mixed` type handling, catching issues like:

```php
// Level 8 allows this (dangerous!)
public function process(mixed $data): void
{
    echo $data['key'];  // Could fail at runtime
}

// Level 9+ requires explicit type handling
public function process(mixed $data): void
{
    if (!is_array($data) || !isset($data['key'])) {
        throw new InvalidArgumentException('Expected array with key');
    }
    echo $data['key'];  // Safe
}
```

### CI Integration

```yaml
# .github/workflows/static-analysis.yml
name: Static Analysis

on: [push, pull_request]

jobs:
  phpstan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
      - run: composer install --no-progress
      - run: vendor/bin/phpstan analyse --error-format=github
```

## PHPat (Architecture Testing)

PHPat is a PHPStan extension for testing architectural rules.

> **Source:** [phpat.dev](https://www.phpat.dev/) | [GitHub](https://github.com/carlosas/phpat)

### Installation

```bash
composer require --dev phpat/phpat

# With extension installer (recommended)
composer require --dev phpstan/extension-installer
```

### Configuration

```neon
# phpstan.neon
includes:
    - vendor/phpat/phpat/extension.neon

parameters:
    paths:
        - src
        - tests/Architecture  # Include architecture tests

    phpat:
        ignore_built_in_classes: true
        show_rule_names: true

services:
    - class: Tests\Architecture\LayerTest
      tags:
          - phpat.test
    - class: Tests\Architecture\DependencyTest
      tags:
          - phpat.test
```

### Architecture Test Examples

```php
<?php

declare(strict_types=1);

namespace Tests\Architecture;

use PHPat\Selector\Selector;
use PHPat\Test\Builder\Rule;
use PHPat\Test\PHPat;

final class LayerTest
{
    /**
     * Domain layer must not depend on Infrastructure.
     */
    public function testDomainIndependence(): Rule
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('App\Domain'))
            ->shouldNotDependOn()
            ->classes(Selector::inNamespace('App\Infrastructure'))
            ->because('Domain must be independent of infrastructure');
    }

    /**
     * Controllers must only depend on Application layer.
     */
    public function testControllerDependencies(): Rule
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('App\Controller'))
            ->canOnlyDependOn()
            ->classes(
                Selector::inNamespace('App\Application'),
                Selector::inNamespace('Symfony'),
                Selector::inNamespace('Psr'),
            );
    }

    /**
     * Entities must not use repositories directly.
     */
    public function testEntityPurity(): Rule
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('App\Entity'))
            ->shouldNotDependOn()
            ->classes(Selector::classname('*Repository'));
    }
}
```

### Common Architecture Rules

```php
<?php

declare(strict_types=1);

namespace Tests\Architecture;

use PHPat\Selector\Selector;
use PHPat\Test\Builder\Rule;
use PHPat\Test\PHPat;

final class DependencyTest
{
    /**
     * Services must implement interfaces.
     */
    public function testServicesImplementInterfaces(): Rule
    {
        return PHPat::rule()
            ->classes(Selector::classname('*Service'))
            ->excluding(Selector::classname('*Interface'))
            ->shouldImplement()
            ->classes(Selector::classname('*Interface'));
    }

    /**
     * No class should depend on concrete implementations.
     */
    public function testDependOnAbstractions(): Rule
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('App'))
            ->shouldNotDependOn()
            ->classes(
                Selector::classname('GuzzleHttp\Client'),
                Selector::classname('Doctrine\ORM\EntityManager'),
            )
            ->because('Depend on interfaces, not implementations');
    }

    /**
     * DTOs must be final and readonly.
     */
    public function testDtoStructure(): Rule
    {
        return PHPat::rule()
            ->classes(Selector::classname('*DTO'))
            ->shouldBeFinal()
            ->shouldBeReadonly();
    }

    /**
     * Commands must not return values.
     */
    public function testCommandsAreVoid(): Rule
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('App\Command'))
            ->shouldHaveOnlyOnePublicMethod()
            ->andThisMethodShouldHaveReturnType('void');
    }
}
```

### Selectors Reference

| Selector | Description |
|----------|-------------|
| `Selector::inNamespace('App\Domain')` | All classes in namespace |
| `Selector::classname('*Service')` | Classes matching pattern |
| `Selector::implements('Interface')` | Classes implementing interface |
| `Selector::extends('BaseClass')` | Classes extending class |
| `Selector::isAbstract()` | Abstract classes only |
| `Selector::isFinal()` | Final classes only |

## Rector (Automated Refactoring)

Rector automates code migrations and refactoring.

### Installation

```bash
composer require --dev rector/rector
```

### Configuration

```php
<?php
// rector.php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Rector\TypeDeclaration\Rector\ClassMethod\AddVoidReturnTypeWhereNoReturnRector;

return RectorConfig::configure()
    ->withPaths([
        __DIR__ . '/src',
        __DIR__ . '/tests',
    ])
    ->withSkip([
        __DIR__ . '/src/Kernel.php',
    ])
    ->withSets([
        LevelSetList::UP_TO_PHP_83,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::TYPE_DECLARATION,
        SetList::PRIVATIZATION,
        SetList::EARLY_RETURN,
    ])
    ->withRules([
        AddVoidReturnTypeWhereNoReturnRector::class,
    ]);
```

### Usage

```bash
# Preview changes (dry run)
vendor/bin/rector process --dry-run

# Apply changes
vendor/bin/rector process

# Process specific path
vendor/bin/rector process src/Entity/

# Clear cache
vendor/bin/rector process --clear-cache
```

### Key Rule Sets

| Set | Purpose |
|-----|---------|
| `LevelSetList::UP_TO_PHP_83` | PHP version upgrade |
| `SetList::CODE_QUALITY` | Improve code quality |
| `SetList::DEAD_CODE` | Remove unused code |
| `SetList::TYPE_DECLARATION` | Add type declarations |
| `SetList::PRIVATIZATION` | Make code more private |
| `SetList::EARLY_RETURN` | Convert to early returns |

### CI Integration

```yaml
# In CI, run Rector in dry-run to catch unrefactored code
- name: Rector Check
  run: vendor/bin/rector process --dry-run --ansi
```

## PHP-CS-Fixer (Coding Style)

Enforces coding standards automatically.

### Installation

```bash
composer require --dev friendsofphp/php-cs-fixer
```

### Configuration

```php
<?php
// .php-cs-fixer.dist.php

declare(strict_types=1);

$finder = PhpCsFixer\Finder::create()
    ->in(__DIR__ . '/src')
    ->in(__DIR__ . '/tests');

return (new PhpCsFixer\Config())
    ->setRules([
        '@PER-CS' => true,        // Latest PER Coding Style
        '@PER-CS:risky' => true,
        'declare_strict_types' => true,
        'strict_param' => true,
        'array_syntax' => ['syntax' => 'short'],
        'no_unused_imports' => true,
        'ordered_imports' => ['sort_algorithm' => 'alpha'],
        'single_quote' => true,
        'trailing_comma_in_multiline' => true,
    ])
    ->setRiskyAllowed(true)
    ->setFinder($finder);
```

### Usage

```bash
# Check for violations (dry run)
vendor/bin/php-cs-fixer fix --dry-run --diff

# Fix violations
vendor/bin/php-cs-fixer fix

# Verbose output
vendor/bin/php-cs-fixer fix -v
```

### CI Integration

```yaml
- name: PHP-CS-Fixer
  run: vendor/bin/php-cs-fixer fix --dry-run --diff --ansi
```

## Combined CI Workflow

```yaml
name: Quality Assurance

on: [push, pull_request]

jobs:
  qa:
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

      - name: PHP-CS-Fixer
        run: vendor/bin/php-cs-fixer fix --dry-run --diff --ansi

      - name: PHPStan (Level 10)
        run: vendor/bin/phpstan analyse --error-format=github

      - name: Rector
        run: vendor/bin/rector process --dry-run --ansi
```

## Composer Scripts

```json
{
    "scripts": {
        "cs:check": "php-cs-fixer fix --dry-run --diff",
        "cs:fix": "php-cs-fixer fix",
        "stan": "phpstan analyse",
        "rector:check": "rector process --dry-run",
        "rector:fix": "rector process",
        "qa": [
            "@cs:check",
            "@stan",
            "@rector:check"
        ],
        "fix": [
            "@cs:fix",
            "@rector:fix"
        ]
    }
}
```

## Quality Gates

### Minimum Requirements

| Tool | Minimum Threshold |
|------|-------------------|
| PHPStan | Level 9 (level 10 for new projects) |
| PHPat | All architecture tests pass |
| Rector | No remaining suggestions |
| PHP-CS-Fixer | Zero violations |

### Baseline Strategy

For existing projects, use baselines to adopt tools incrementally:

```bash
# PHPStan baseline
vendor/bin/phpstan analyse --generate-baseline

# Include in phpstan.neon
includes:
    - phpstan-baseline.neon
```

Reduce baseline errors over time until reaching zero.
