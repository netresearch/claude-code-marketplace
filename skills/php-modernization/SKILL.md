---
name: php-modernization
description: "Agent Skill: PHP 8.x modernization patterns. Use when upgrading to PHP 8.1/8.2/8.3/8.4/8.5, implementing type safety, or achieving PHPStan level 10. By Netresearch."
---

# PHP Modernization Skill

Modernize PHP applications to PHP 8.x with type safety, Symfony patterns, and static analysis.

## Expertise Areas

- **PHP 8.x**: Constructor promotion, readonly, enums, match, attributes, union types
- **Type Safety**: Generics via PHPDoc, ArrayTypeHelper, PHPStan level 10 (max)
- **Symfony**: DI patterns, PHP config, PSR-14 events

## Reference Files

- `references/php8-features.md` - PHP 8.0-8.5 features
- `references/type-safety.md` - Type system strategies
- `references/request-dtos.md` - Request DTOs, safe integer handling
- `references/symfony-patterns.md` - Modern Symfony architecture
- `references/phpstan-compliance.md` - Static analysis configuration
- `references/migration-strategies.md` - Version upgrade planning
- `references/adapter-registry-pattern.md` - Dynamic adapter instantiation

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

**Typed arrays (PHPDoc generics):**
```php
/** @return array<int, User> */
public function getUsers(): array
```

## Migration Checklist

- [ ] `declare(strict_types=1)` in all files
- [ ] Return types and parameter types on all methods
- [ ] Replace annotations with attributes
- [ ] Use readonly, enums, match expressions
- [ ] PHPStan level 10 (max) - required for full conformance

## Scoring

| Criterion | Requirement |
|-----------|-------------|
| PHPStan | Level 10 (max) required for full points |
| PHP-CS-Fixer | Must pass with project rules |
| Rector | No remaining suggestions |

> **Note:** PHPStan level 9 is insufficient for security-critical code. Level 10 enforces strict `mixed` type handling.

## Verification

```bash
./scripts/verify-php-project.sh /path/to/project
```

---

> **Contributing:** https://github.com/netresearch/php-modernization-skill
