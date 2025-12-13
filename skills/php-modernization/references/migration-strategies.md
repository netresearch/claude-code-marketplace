# PHP Migration Strategies

## Version Upgrade Planning

### Pre-Migration Assessment

```bash
# Check PHP compatibility
composer require --dev phpcompatibility/php-compatibility

# Run compatibility check
vendor/bin/phpcs -p --standard=PHPCompatibility \
    --runtime-set testVersion 8.2 \
    src/

# Check deprecated features
php -d error_reporting=E_ALL \
    -d display_errors=1 \
    vendor/bin/phpunit
```

### Migration Phases

1. **Assessment** (1-2 days)
   - Run compatibility checks
   - Identify deprecated features
   - Document breaking changes
   - Estimate effort

2. **Preparation** (2-5 days)
   - Update composer.json constraints
   - Fix deprecation warnings
   - Update CI configuration
   - Prepare feature branches

3. **Execution** (3-10 days)
   - Apply automated fixes (Rector)
   - Manual code updates
   - Test extensively
   - Update dependencies

4. **Validation** (2-3 days)
   - Full test suite
   - Performance benchmarks
   - Security scan
   - Staging deployment

## Rector Automation

### Basic Configuration

```php
<?php
// rector.php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Rector\Symfony\Set\SymfonySetList;

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
        SymfonySetList::SYMFONY_64,
    ]);
```

### Targeted Upgrades

```php
<?php
// rector.php for specific PHP version upgrade

use Rector\Config\RectorConfig;
use Rector\Php80\Rector\Class_\AnnotationToAttributeRector;
use Rector\Php80\Rector\Class_\ClassPropertyAssignToConstructorPromotionRector;
use Rector\Php80\Rector\FunctionLike\MixedTypeRector;
use Rector\Php81\Rector\FuncCall\NullToStrictStringFuncCallArgRector;
use Rector\Php81\Rector\Property\ReadOnlyPropertyRector;

return RectorConfig::configure()
    ->withPaths([__DIR__ . '/src'])
    ->withRules([
        // PHP 8.0
        ClassPropertyAssignToConstructorPromotionRector::class,
        AnnotationToAttributeRector::class,

        // PHP 8.1
        ReadOnlyPropertyRector::class,

        // Type declarations
        MixedTypeRector::class,
    ]);
```

### Running Rector

```bash
# Dry run (preview changes)
vendor/bin/rector process --dry-run

# Apply changes
vendor/bin/rector process

# Process specific path
vendor/bin/rector process src/Entity/

# Generate baseline for gradual adoption
vendor/bin/rector process --clear-cache
```

## Dependency Upgrades

### Composer Constraint Updates

```json
{
    "require": {
        "php": ">=8.2",
        "symfony/framework-bundle": "^7.0",
        "doctrine/orm": "^3.0"
    },
    "config": {
        "platform": {
            "php": "8.2.0"
        }
    }
}
```

### Upgrade Process

```bash
# Update constraints in composer.json first

# Show outdated packages
composer outdated --direct

# Update with dry run
composer update --dry-run

# Update specific package
composer update symfony/framework-bundle --with-dependencies

# Update all
composer update

# Validate after update
composer validate --strict
```

## Framework-Specific Migrations

### Symfony Upgrade

```bash
# Install Symfony Flex
composer require symfony/flex

# Update recipes
composer recipes:update

# Run deprecation detector
php bin/console debug:container --deprecations

# Use Symfony upgrade guide
# https://symfony.com/doc/current/setup/upgrade_major.html
```

### Doctrine Upgrade (2.x to 3.x)

```php
// Before: Annotations
/**
 * @ORM\Entity
 * @ORM\Table(name="users")
 */
class User
{
    /**
     * @ORM\Id
     * @ORM\Column(type="integer")
     */
    private $id;
}

// After: Attributes (Doctrine 3.x)
#[ORM\Entity]
#[ORM\Table(name: 'users')]
class User
{
    #[ORM\Id]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;
}
```

## Testing During Migration

### Parallel Testing

```yaml
# .github/workflows/test.yml
jobs:
  test:
    strategy:
      matrix:
        php: ['8.1', '8.2', '8.3']
        symfony: ['6.4', '7.0']

    steps:
      - name: Install dependencies
        run: |
          composer require symfony/framework-bundle:^${{ matrix.symfony }} --no-update
          composer update --prefer-dist

      - name: Run tests
        run: vendor/bin/phpunit
```

### Deprecation Tracking

```php
<?php
// tests/bootstrap.php

use Symfony\Bridge\PhpUnit\DeprecationErrorHandler;

// Fail on deprecations
DeprecationErrorHandler::register(E_USER_DEPRECATED);

// Or track with threshold
putenv('SYMFONY_DEPRECATIONS_HELPER=max[direct]=0');
```

## Common Migration Patterns

### Annotation to Attribute

```php
// Rector handles this automatically, but manual pattern:

// Before
/**
 * @Route("/api/users", name="api_users")
 * @Method({"GET", "POST"})
 */

// After
#[Route('/api/users', name: 'api_users', methods: ['GET', 'POST'])]
```

### Array to Named Arguments

```php
// Before
$response = new Response(
    '',
    200,
    ['Content-Type' => 'application/json']
);

// After
$response = new Response(
    content: '',
    status: Response::HTTP_OK,
    headers: ['Content-Type' => 'application/json']
);
```

### Switch to Match

```php
// Before
switch ($status) {
    case 'active':
        $color = 'green';
        break;
    case 'pending':
        $color = 'yellow';
        break;
    default:
        $color = 'gray';
}

// After
$color = match($status) {
    'active' => 'green',
    'pending' => 'yellow',
    default => 'gray',
};
```

### Property Initialization

```php
// Before (PHP 7.4)
class Service
{
    private LoggerInterface $logger;
    private array $config;

    public function __construct(LoggerInterface $logger, array $config)
    {
        $this->logger = $logger;
        $this->config = $config;
    }
}

// After (PHP 8.0+)
class Service
{
    public function __construct(
        private readonly LoggerInterface $logger,
        private readonly array $config,
    ) {}
}
```

## Rollback Strategy

### Version Control

```bash
# Create migration branch
git checkout -b php82-upgrade

# Tag pre-migration state
git tag pre-php82-upgrade

# If rollback needed
git checkout main
git branch -D php82-upgrade
```

### Feature Flags

```php
// Enable gradual rollout
class FeatureFlags
{
    public static function useNewParser(): bool
    {
        return getenv('USE_NEW_PARSER') === 'true'
            || PHP_VERSION_ID >= 80200;
    }
}

// Usage
if (FeatureFlags::useNewParser()) {
    return $this->newParser->parse($input);
}
return $this->legacyParser->parse($input);
```

## Post-Migration Checklist

- [ ] All tests pass on target PHP version
- [ ] No deprecation warnings in logs
- [ ] PHPStan passes at configured level
- [ ] Performance benchmarks acceptable
- [ ] Dependencies updated and compatible
- [ ] CI/CD pipelines updated
- [ ] Documentation updated
- [ ] Team trained on new features
- [ ] Rollback plan tested
- [ ] Staging environment validated
