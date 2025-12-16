# PHP Modernization Skill

Expert patterns for modernizing PHP applications to PHP 8.x with type safety, Symfony best practices, and static analysis compliance.

## Features

- **PHP 8.x Features**: Constructor property promotion, readonly properties and classes, named arguments, enums and match expressions, attributes (replacing annotations), union and intersection types, nullsafe operator
- **Type Safety Patterns**: Generic collection typing via PHPDoc, ArrayTypeHelper for type-safe array operations, strict typing enforcement, PHPStan level 9+ compliance, runtime type validation
- **Symfony Integration**: Dependency injection patterns, service configuration (YAML → PHP), event dispatcher and PSR-14, form handling modernization, security component updates
- **Static Analysis**: PHPStan level 9 configuration and compliance strategies
- **Migration Strategies**: Version upgrade planning and systematic modernization approaches

## Installation

### Option 1: Via Netresearch Marketplace (Recommended)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

### Option 2: Download Release

Download the [latest release](https://github.com/netresearch/php-modernization-skill/releases/latest) and extract to `~/.claude/skills/php-modernization-skill/`

### Option 3: Composer (PHP projects)

```bash
composer require netresearch/agent-php-modernization-skill
```

**Requires:** [netresearch/composer-agent-skill-plugin](https://github.com/netresearch/composer-agent-skill-plugin)

## Usage

This skill is automatically triggered when:

- Modernizing PHP codebases to PHP 8.1/8.2/8.3
- Implementing type safety and strict typing
- Adopting Symfony best practices
- Achieving PHPStan level 9+ compliance
- Upgrading from older PHP versions
- Implementing generic collection patterns

Example queries:
- "Modernize this PHP class to PHP 8.2"
- "Add strict type safety with PHPStan level 9"
- "Convert YAML service configuration to PHP"
- "Implement readonly class with constructor promotion"
- "Create type-safe array helper with generics"

## Structure

```
php-modernization-skill/
├── SKILL.md                              # Skill metadata and core patterns
├── references/
│   ├── php8-features.md                  # PHP 8.0-8.4 feature adoption patterns
│   ├── type-safety.md                    # Type system maximization strategies
│   ├── symfony-patterns.md               # Modern Symfony architecture
│   ├── phpstan-compliance.md             # Static analysis configuration
│   └── migration-strategies.md           # Version upgrade planning
└── scripts/
    └── verify-php-project.sh             # Verification script
```

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

## Migration Checklist

### PHP Version Upgrade
- Update composer.json PHP requirement
- Enable strict_types in all files
- Replace annotations with attributes
- Convert to constructor property promotion
- Use readonly where applicable
- Replace switch with match expressions
- Adopt enums for status/type constants
- Update PHPStan to highest stable level

### Type Safety Enhancement
- Add return types to all methods
- Add parameter types to all methods
- Use union types instead of mixed
- Implement ArrayTypeHelper for collections
- Add @template annotations for generics
- Remove @var annotations where inferrable
- Configure PHPStan strict rules

## Related Skills

- **security-audit-skill**: Security patterns for PHP applications
- **typo3-testing-skill**: PHPUnit patterns (applicable to any PHP project)

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

Developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/).

---

**Made with ❤️ for Open Source by [Netresearch](https://www.netresearch.de/)**
