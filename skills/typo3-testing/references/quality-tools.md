# Quality Tools for TYPO3 Development

Automated code quality and static analysis tools for TYPO3 extensions.

## Overview

- **PHPStan**: Static analysis for type safety and bugs
- **Rector**: Automated code refactoring and modernization
- **php-cs-fixer**: Code style enforcement (PSR-12, TYPO3 CGL)
- **phplint**: PHP syntax validation

## PHPStan

### Installation

```bash
composer require --dev phpstan/phpstan phpstan/phpstan-strict-rules saschaegerer/phpstan-typo3
```

### Configuration

Create `Build/phpstan.neon`:

```neon
includes:
    - vendor/phpstan/phpstan-strict-rules/rules.neon
    - vendor/saschaegerer/phpstan-typo3/extension.neon

parameters:
    level: max  # Level 10 - maximum strictness
    paths:
        - Classes
        - Tests
    excludePaths:
        - Tests/Acceptance/_output/*
    reportUnmatchedIgnoredErrors: true
    checkGenericClassInNonGenericObjectType: false
    checkMissingIterableValueType: false
```

### Running PHPStan

```bash
# Via runTests.sh
Build/Scripts/runTests.sh -s phpstan

# Directly
vendor/bin/phpstan analyze --configuration Build/phpstan.neon

# With baseline (ignore existing errors)
vendor/bin/phpstan analyze --generate-baseline Build/phpstan-baseline.neon

# Clear cache
vendor/bin/phpstan clear-result-cache
```

### PHPStan Rule Levels

**Level 0-10** (use `max` for level 10): Increasing strictness
- **Level 0**: Basic checks (undefined variables, unknown functions)
- **Level 5**: Type checks, unknown properties, unknown methods
- **Level 9**: Strict mixed types, unused parameters
- **Level 10 (max)**: Maximum strictness - explicit mixed types, pure functions

**Recommendation**: Start with level 5, aim for level 10 (max) in modern TYPO3 13 projects.

**Why Level 10?**
- Enforces explicit type declarations (`mixed` must be declared, not implicit)
- Catches more potential bugs at development time
- Aligns with TYPO3 13 strict typing standards (`declare(strict_types=1)`)
- Required for PHPStan Level 10 compliant extensions

### Ignoring Errors

```php
/** @phpstan-ignore-next-line */
$value = $this->legacyMethod();

// Or in neon file
parameters:
    ignoreErrors:
        - '#Call to an undefined method.*::getRepository\(\)#'
```

### TYPO3-Specific Rules

```php
// PHPStan understands TYPO3 classes
$queryBuilder = GeneralUtility::makeInstance(ConnectionPool::class)
    ->getQueryBuilderForTable('pages');
// ✅ PHPStan knows this returns QueryBuilder

// Detects TYPO3 API misuse
TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance(MyService::class);
// ✅ Checks if MyService is a valid class
```

## Rector

### Installation

```bash
composer require --dev rector/rector ssch/typo3-rector
```

### Configuration

Create `rector.php`:

```php
<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Ssch\TYPO3Rector\Set\Typo3SetList;

return RectorConfig::configure()
    ->withPaths([
        __DIR__ . '/Classes',
        __DIR__ . '/Tests',
    ])
    ->withSkip([
        __DIR__ . '/Tests/Acceptance/_output',
    ])
    ->withPhpSets(php82: true)
    ->withSets([
        LevelSetList::UP_TO_PHP_82,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::TYPE_DECLARATION,
        Typo3SetList::TYPO3_13,
    ]);
```

### Running Rector

```bash
# Dry run (show changes)
vendor/bin/rector process --dry-run

# Apply changes
vendor/bin/rector process

# Via runTests.sh
Build/Scripts/runTests.sh -s rector
```

### Common Refactorings

**TYPO3 API Modernization**:
```php
// Before
$GLOBALS['TYPO3_DB']->exec_SELECTgetRows('*', 'pages', 'uid=1');

// After (Rector auto-refactors)
GeneralUtility::makeInstance(ConnectionPool::class)
    ->getConnectionForTable('pages')
    ->select(['*'], 'pages', ['uid' => 1])
    ->fetchAllAssociative();
```

**Type Declarations**:
```php
// Before
public function process($data)
{
    return $data;
}

// After
public function process(array $data): array
{
    return $data;
}
```

## php-cs-fixer

### Installation

```bash
composer require --dev friendsofphp/php-cs-fixer
```

### Configuration

Create `Build/php-cs-fixer.php`:

```php
<?php

declare(strict_types=1);

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__ . '/../Classes')
    ->in(__DIR__ . '/../Tests')
    ->exclude('_output');

return (new PhpCsFixer\Config())
    ->setRules([
        '@PSR12' => true,
        '@PhpCsFixer' => true,
        'array_syntax' => ['syntax' => 'short'],
        'concat_space' => ['spacing' => 'one'],
        'declare_strict_types' => true,
        'ordered_imports' => ['sort_algorithm' => 'alpha'],
        'no_unused_imports' => true,
        'single_line_throw' => false,
        'phpdoc_align' => false,
        'phpdoc_no_empty_return' => false,
        'phpdoc_summary' => false,
    ])
    ->setRiskyAllowed(true)
    ->setFinder($finder);
```

### Running php-cs-fixer

```bash
# Check only (dry run)
vendor/bin/php-cs-fixer fix --config Build/php-cs-fixer.php --dry-run --diff

# Fix files
vendor/bin/php-cs-fixer fix --config Build/php-cs-fixer.php

# Via runTests.sh
Build/Scripts/runTests.sh -s cgl
```

### Common Rules

```php
// array_syntax: short
$array = [1, 2, 3]; // ✅
$array = array(1, 2, 3); // ❌

// concat_space: one
$message = 'Hello ' . $name; // ✅
$message = 'Hello '.$name; // ❌

// declare_strict_types
<?php

declare(strict_types=1); // ✅ Required at top of file

// ordered_imports
use Vendor\Extension\Domain\Model\Product; // ✅ Alphabetical
use Vendor\Extension\Domain\Repository\ProductRepository;
```

## phplint

### Installation

```bash
composer require --dev overtrue/phplint
```

### Configuration

Create `.phplint.yml`:

```yaml
path: ./
jobs: 10
cache: var/cache/phplint.cache
exclude:
    - vendor
    - var
    - .Build
extensions:
    - php
```

### Running phplint

```bash
# Lint all PHP files
vendor/bin/phplint

# Via runTests.sh
Build/Scripts/runTests.sh -s lint

# Specific directory
vendor/bin/phplint Classes/
```

## Composer Script Integration

```json
{
    "scripts": {
        "ci:test:php:lint": "phplint",
        "ci:test:php:phpstan": "phpstan analyze --configuration Build/phpstan.neon --no-progress",
        "ci:test:php:rector": "rector process --dry-run",
        "ci:test:php:cgl": "php-cs-fixer fix --config Build/php-cs-fixer.php --dry-run --diff",
        "ci:test:php:security": "composer audit",

        "fix:cgl": "php-cs-fixer fix --config Build/php-cs-fixer.php",
        "fix:rector": "rector process",

        "ci:test": [
            "@ci:test:php:lint",
            "@ci:test:php:phpstan",
            "@ci:test:php:rector",
            "@ci:test:php:cgl",
            "@ci:test:php:security"
        ]
    }
}
```

> **Security Note**: `composer audit` checks for known security vulnerabilities in dependencies. Run this regularly and especially before releases.

## Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh

echo "Running quality checks..."

# Lint
vendor/bin/phplint || exit 1

# PHPStan
vendor/bin/phpstan analyze --configuration Build/phpstan.neon --error-format=table --no-progress || exit 1

# Code style
vendor/bin/php-cs-fixer fix --config Build/php-cs-fixer.php --dry-run --diff || exit 1

echo "✓ All checks passed"
```

## CI/CD Integration

### GitHub Actions

```yaml
quality:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: shivammathur/setup-php@v2
      with:
        php-version: '8.4'  # Use latest PHP for quality tools
    - run: composer install
    - run: composer ci:test:php:lint
    - run: composer ci:test:php:phpstan
    - run: composer ci:test:php:cgl
    - run: composer ci:test:php:rector
    - run: composer ci:test:php:security
```

## IDE Integration

### PHPStorm

1. **PHPStan**: Settings → PHP → Quality Tools → PHPStan
2. **php-cs-fixer**: Settings → PHP → Quality Tools → PHP CS Fixer
3. **File Watchers**: Auto-run on file save

### VS Code

```json
{
    "php.validate.executablePath": "/usr/bin/php",
    "phpstan.enabled": true,
    "phpstan.configFile": "Build/phpstan.neon",
    "php-cs-fixer.onsave": true,
    "php-cs-fixer.config": "Build/php-cs-fixer.php"
}
```

## Best Practices

1. **PHPStan Level 10**: Aim for `level: max` in modern TYPO3 13 projects
2. **Baseline for Legacy**: Use baselines to track existing issues during migration
3. **Security Audits**: Run `composer audit` regularly and in CI
4. **Auto-fix in CI**: Run fixes automatically, fail on violations
5. **Consistent Rules**: Share config across team
6. **Pre-commit Checks**: Catch issues before commit (lint, PHPStan, CGL, security)
7. **Latest PHP**: Run quality tools with latest PHP version (8.4+)
8. **Regular Updates**: Keep tools and rules updated

## Resources

- [PHPStan Documentation](https://phpstan.org/user-guide/getting-started)
- [Rector Documentation](https://getrector.com/documentation)
- [PHP CS Fixer Documentation](https://github.com/PHP-CS-Fixer/PHP-CS-Fixer)
- [TYPO3 Coding Guidelines](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/CodingGuidelines/)
