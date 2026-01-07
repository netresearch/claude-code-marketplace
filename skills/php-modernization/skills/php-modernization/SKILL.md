---
name: php-modernization
description: "Agent Skill: PHP 8.x modernization patterns. Use when upgrading to PHP 8.1/8.2/8.3/8.4/8.5, implementing type safety, or achieving PHPStan level 10. By Netresearch."
---

# PHP Modernization Skill

Modernize PHP applications to PHP 8.x with type safety, PSR compliance, and static analysis.

## Expertise Areas

- **PHP 8.x**: Constructor promotion, readonly, enums, match, attributes, union types
- **PSR/PER Compliance**: Active PHP-FIG standards
- **Static Analysis**: PHPStan (level 9+), PHPat, Rector, PHP-CS-Fixer
- **Type Safety**: DTOs/VOs over arrays, generics via PHPDoc

## Reference Files

| Reference | Purpose |
|-----------|---------|
| `references/php8-features.md` | PHP 8.0-8.5 features |
| `references/psr-per-compliance.md` | Active PSR/PER standards |
| `references/static-analysis-tools.md` | PHPStan, PHPat, Rector, PHP-CS-Fixer configs |
| `references/type-safety.md` | Type system strategies |
| `references/request-dtos.md` | Request DTOs, safe integer handling |
| `references/symfony-patterns.md` | Modern Symfony architecture |

## Required Tools

| Tool | Requirement |
|------|-------------|
| PHPStan | **Level 9 minimum**, level 10 recommended |
| PHPat | Required for defined architectures |
| Rector | Required for modernization |
| PHP-CS-Fixer | Required with `@PER-CS` |

See `references/static-analysis-tools.md` for configuration examples.

## Core Rules

**DTOs Required** - Never pass raw arrays for structured data:
```php
// Bad: public function createUser(array $data): array
// Good: public function createUser(CreateUserDTO $dto): UserDTO
```

**Enums Required** - Never use string/int constants for fixed values:
```php
// Bad: const STATUS_DRAFT = 'draft'; function setStatus(string $s)
// Good: enum Status: string { case Draft = 'draft'; }
```

**PSR Compliance** - Type-hint against PSR interfaces (PSR-3, PSR-6, PSR-7, PSR-11, PSR-14, PSR-18).

## Migration Checklist

- [ ] `declare(strict_types=1)` in all files
- [ ] PER Coding Style via PHP-CS-Fixer (`@PER-CS`)
- [ ] PHPStan level 9+ (level 10 for new projects)
- [ ] PHPat architecture tests
- [ ] Return types and parameter types on all methods
- [ ] DTOs for data transfer, no array params/returns
- [ ] Backed enums for all status/type values
- [ ] Type-hint against PSR interfaces

## Scoring

| Criterion | Requirement |
|-----------|-------------|
| PHPStan | Level 9 minimum |
| PHP-CS-Fixer | `@PER-CS` zero violations |
| DTOs/VOs | No array params/returns for structured data |
| Enums | Backed enums for fixed value sets |

## Verification

```bash
./scripts/verify-php-project.sh /path/to/project
```

---

> **Contributing:** https://github.com/netresearch/php-modernization-skill
