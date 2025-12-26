---
name: php-modernization
description: "Agent Skill: PHP 8.x modernization patterns. Use when upgrading to PHP 8.1/8.2/8.3, implementing type safety, or achieving PHPStan level 9+. By Netresearch."
---

# PHP Modernization Skill

Modernize PHP applications to PHP 8.x with type safety, Symfony patterns, and static analysis.

## Expertise Areas

- **PHP 8.x**: Constructor promotion, readonly, enums, match, attributes, union types
- **Type Safety**: Generics via PHPDoc, ArrayTypeHelper, PHPStan level 9+
- **Symfony**: DI patterns, PHP config, PSR-14 events

## Reference Files

- `references/php8-features.md` - PHP 8.0-8.4 features
- `references/type-safety.md` - Type system strategies
- `references/symfony-patterns.md` - Modern Symfony architecture
- `references/phpstan-compliance.md` - Static analysis configuration
- `references/migration-strategies.md` - Version upgrade planning

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
- [ ] Configure PHPStan level 9+

## Verification

```bash
./scripts/verify-php-project.sh /path/to/project
```

---

> **Contributing:** https://github.com/netresearch/php-modernization-skill
