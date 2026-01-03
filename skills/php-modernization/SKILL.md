---
name: php-modernization
description: "Agent Skill: PHP 8.x modernization patterns. Use when upgrading to PHP 8.1/8.2/8.3/8.4/8.5, implementing type safety, or achieving PHPStan level 10. By Netresearch."
---

# PHP Modernization Skill

Modernize PHP applications to PHP 8.x with type safety, PSR compliance, Symfony patterns, and static analysis.

## Expertise Areas

- **PHP 8.x**: Constructor promotion, readonly, enums, match, attributes, union types
- **PSR/PER Compliance**: Active PHP-FIG standards (PSR-1,3,4,6,7,11,12,13,14,15,16,17,18,20, PER Coding Style)
- **Static Analysis**: PHPStan (level 9+), PHPat, Rector, PHP-CS-Fixer
- **Type Safety**: DTOs/VOs over arrays, generics via PHPDoc, PHPStan level 10 (max)
- **Symfony**: DI patterns, PHP config, PSR-14 events

## Reference Files

- `references/php8-features.md` - PHP 8.0-8.5 features
- `references/psr-per-compliance.md` - Active PSR and PER standards
- `references/static-analysis-tools.md` - **PHPStan, PHPat, Rector, PHP-CS-Fixer (required)**
- `references/type-safety.md` - Type system strategies
- `references/request-dtos.md` - Request DTOs, safe integer handling
- `references/symfony-patterns.md` - Modern Symfony architecture
- `references/phpstan-compliance.md` - PHPStan configuration details
- `references/migration-strategies.md` - Version upgrade planning
- `references/adapter-registry-pattern.md` - Dynamic adapter instantiation

## Required Static Analysis Tools

All modern PHP projects must use these tools:

| Tool | Purpose | Requirement |
|------|---------|-------------|
| PHPStan | Type checking, bug detection | **Level 9 minimum**, level 10 recommended |
| PHPat | Architecture testing | **Required** for projects with defined architecture |
| Rector | Automated refactoring | **Required** for modernization |
| PHP-CS-Fixer | Coding style | **Required** with `@PER-CS` |

### PHPStan (Level 9+)

Level 9 enforces strict `mixed` type handling. Level 10 is maximum strictness.

```neon
# phpstan.neon
parameters:
    level: 10
    paths: [src, tests]
```

### PHPat (Architecture Testing)

Test architectural rules as code. [phpat.dev](https://www.phpat.dev/)

```php
public function testDomainIndependence(): Rule
{
    return PHPat::rule()
        ->classes(Selector::inNamespace('App\Domain'))
        ->shouldNotDependOn()
        ->classes(Selector::inNamespace('App\Infrastructure'));
}
```

### Rector (Automated Refactoring)

```php
// rector.php
return RectorConfig::configure()
    ->withSets([
        LevelSetList::UP_TO_PHP_83,
        SetList::CODE_QUALITY,
        SetList::TYPE_DECLARATION,
    ]);
```

### PHP-CS-Fixer

```php
// .php-cs-fixer.dist.php
return (new PhpCsFixer\Config())
    ->setRules([
        '@PER-CS' => true,
        '@PER-CS:risky' => true,
        'declare_strict_types' => true,
    ])
    ->setRiskyAllowed(true);
```

## PSR/PER Compliance

All modern PHP code must follow active PHP-FIG standards:

| Standard | Purpose | Requirement |
|----------|---------|-------------|
| PSR-1 | Basic Coding | **Required** |
| PSR-4 | Autoloading | **Required** |
| PER Coding Style | Coding Style | **Required** (supersedes PSR-12) |
| PSR-3 | Logger | Use when logging |
| PSR-6/16 | Cache | Use when caching |
| PSR-7/17/18 | HTTP | Use for HTTP clients |
| PSR-11 | Container | Use for DI containers |
| PSR-14 | Events | Use for event dispatching |
| PSR-15 | Middleware | Use for HTTP middleware |
| PSR-20 | Clock | Use for time-dependent code |

**Source of truth:** https://www.php-fig.org/psr/ and https://www.php-fig.org/per/

## DTOs and Value Objects (Required)

**Never pass or return raw arrays** for structured data. Use typed objects:

```php
// ❌ Bad: Array passing
public function createUser(array $data): array

// ✅ Good: DTO pattern
public function createUser(CreateUserDTO $dto): UserDTO
```

| Instead of | Use |
|------------|-----|
| `array $userData` | `UserDTO` |
| `array $config` | `readonly class Config` |
| `return ['success' => true]` | `return new ResultDTO()` |

See `references/request-dtos.md` for Request DTOs, Command/Query DTOs, and Value Objects.

## Quick Patterns

**Constructor promotion (PHP 8.0+):**
```php
readonly class UserDTO {
    public function __construct(
        public string $name,
        public string $email,
    ) {}
}
```

**PSR-18 HTTP client (minimal interface):**
```php
use Psr\Http\Client\ClientInterface;
use Psr\Http\Message\RequestFactoryInterface;

final class ApiService
{
    public function __construct(
        private readonly ClientInterface $client,
        private readonly RequestFactoryInterface $requestFactory,
    ) {}

    public function fetch(string $uri): array
    {
        $request = $this->requestFactory->createRequest('GET', $uri);
        $response = $this->client->sendRequest($request);
        return json_decode($response->getBody()->getContents(), true);
    }
}
```

**Typed arrays (PHPDoc generics):**
```php
/** @return array<int, User> */
public function getUsers(): array
```

## Migration Checklist

- [ ] `declare(strict_types=1)` in all files
- [ ] PSR-4 autoloading configured in composer.json
- [ ] PER Coding Style enforced via PHP-CS-Fixer (`@PER-CS`)
- [ ] PHPStan level 9+ (level 10 for new projects)
- [ ] PHPat architecture tests for layer dependencies
- [ ] Rector with no remaining suggestions
- [ ] Return types and parameter types on all methods
- [ ] **DTOs for data transfer, Value Objects for domain concepts**
- [ ] **No array parameters/returns for structured data**
- [ ] Replace annotations with attributes
- [ ] Use readonly, enums, match expressions
- [ ] Type-hint against PSR interfaces (not implementations)

## Scoring

| Criterion | Requirement |
|-----------|-------------|
| PHPStan | Level 9 minimum, level 10 for full points |
| PHPat | All architecture tests pass |
| Rector | No remaining suggestions |
| PHP-CS-Fixer | `@PER-CS` with zero violations |
| PSR Compliance | Type-hint against PSR interfaces |
| DTOs/VOs | No array params/returns for structured data |

> **Note:** PHPStan level 8 or below is insufficient for production code. Level 9+ enforces strict `mixed` type handling.

## Verification

```bash
./scripts/verify-php-project.sh /path/to/project
```

---

> **Contributing:** https://github.com/netresearch/php-modernization-skill
