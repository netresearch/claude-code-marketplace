# PHP Modernization Skill

Expert patterns for modernizing PHP applications to PHP 8.x with type safety, PSR/PER compliance, static analysis tools, and Symfony best practices.

## Compatibility

This is an **Agent Skill** following the [open standard](https://agentskills.io) originally developed by Anthropic and released for cross-platform use.

**Supported Platforms:**
- Claude Code (Anthropic)
- Cursor
- GitHub Copilot
- Other skills-compatible AI agents

> Skills are portable packages of procedural knowledge that work across any AI agent supporting the Agent Skills specification.


## Features

- **PHP 8.x Features**: Constructor property promotion, readonly properties and classes, named arguments, enums and match expressions, attributes (replacing annotations), union and intersection types, nullsafe operator
- **Static Analysis Tools**: PHPStan (level 9+), PHPat (architecture testing), Rector (automated refactoring), PHP-CS-Fixer (coding style)
- **PSR/PER Compliance**: Enforces all active PHP-FIG standards (PSR-1, 3, 4, 6, 7, 11, 12, 13, 14, 15, 16, 17, 18, 20) and PER Coding Style
- **Type Safety Patterns**: Generic collection typing via PHPDoc, ArrayTypeHelper for type-safe array operations, strict typing enforcement, PHPStan level 10 compliance, runtime type validation
- **Symfony Integration**: Dependency injection patterns, service configuration (YAML to PHP), event dispatcher and PSR-14, form handling modernization, security component updates

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

- Modernizing PHP codebases to PHP 8.1/8.2/8.3/8.4/8.5
- Implementing type safety and strict typing
- Setting up static analysis tools (PHPStan, PHPat, Rector, PHP-CS-Fixer)
- Ensuring PSR/PER compliance
- Adopting Symfony best practices
- Achieving PHPStan level 9+/10 compliance
- Upgrading from older PHP versions
- Implementing generic collection patterns

Example queries:
- "Modernize this PHP class to PHP 8.2"
- "Add strict type safety with PHPStan level 10"
- "Set up PHPat architecture tests"
- "Configure Rector for PHP 8.3 upgrade"
- "Ensure this code follows PSR standards"
- "Convert YAML service configuration to PHP"
- "Implement readonly class with constructor promotion"
- "Make this HTTP client PSR-18 compliant"

## Structure

```
php-modernization-skill/
├── SKILL.md                              # Skill metadata and core patterns
├── references/
│   ├── static-analysis-tools.md          # PHPStan, PHPat, Rector, PHP-CS-Fixer
│   ├── psr-per-compliance.md             # Active PSR and PER standards
│   ├── php8-features.md                  # PHP 8.0-8.5 feature adoption patterns
│   ├── type-safety.md                    # Type system maximization strategies
│   ├── symfony-patterns.md               # Modern Symfony architecture
│   ├── phpstan-compliance.md             # PHPStan configuration details
│   └── migration-strategies.md           # Version upgrade planning
└── scripts/
    └── verify-php-project.sh             # Verification script
```

## Expertise Areas

### Required Static Analysis Tools

All modern PHP projects must use these tools:

| Tool | Purpose | Requirement |
|------|---------|-------------|
| [PHPStan](https://phpstan.org/) | Type checking, bug detection | **Level 9 minimum**, level 10 recommended |
| [PHPat](https://www.phpat.dev/) | Architecture testing | **Required** for projects with defined architecture |
| [Rector](https://getrector.com/) | Automated refactoring | **Required** for modernization |
| [PHP-CS-Fixer](https://cs.symfony.com/) | Coding style | **Required** with `@PER-CS` |

### PSR/PER Compliance

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
- PHPStan level 9+/10 compliance
- Runtime type validation

### Symfony Integration
- Dependency injection patterns
- Service configuration (YAML to PHP)
- Event dispatcher and PSR-14
- Form handling modernization
- Security component updates

## Migration Checklist

### Static Analysis Setup
- PHPStan at level 9+ (level 10 for new projects)
- PHPat architecture tests for layer dependencies
- Rector with `LevelSetList::UP_TO_PHP_83` and `SetList::CODE_QUALITY`
- PHP-CS-Fixer with `@PER-CS` ruleset

### PHP Version Upgrade
- Update composer.json PHP requirement
- Enable strict_types in all files
- Replace annotations with attributes
- Convert to constructor property promotion
- Use readonly where applicable
- Replace switch with match expressions
- Adopt enums for status/type constants

### PSR/PER Compliance
- Configure PSR-4 autoloading in composer.json
- Enforce PER Coding Style via PHP-CS-Fixer (`@PER-CS`)
- Type-hint against PSR interfaces (not implementations)
- Use PSR-3 for logging
- Use PSR-14 for event dispatching
- Use PSR-18/17 for HTTP clients
- Use PSR-20 for time-dependent code

### Type Safety Enhancement
- Add return types to all methods
- Add parameter types to all methods
- Use union types instead of mixed
- Implement ArrayTypeHelper for collections
- Add @template annotations for generics
- Remove @var annotations where inferrable

## Related Skills

- **security-audit-skill**: Security patterns for PHP applications
- **typo3-testing-skill**: PHPUnit patterns (applicable to any PHP project)

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

Developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/).

---

**Made with love for Open Source by [Netresearch](https://www.netresearch.de/)**
