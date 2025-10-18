# TYPO3 Extension Conformance Checker

A comprehensive Claude Code skill for evaluating TYPO3 extensions against official TYPO3 coding standards, architecture patterns, and best practices.

## Overview

This skill enables systematic evaluation of TYPO3 extensions for conformance to official TYPO3 standards.

### Standards Checked

| Standard | Version/Specification |
|----------|----------------------|
| **TYPO3 Core** | 12.4 LTS / 13.x |
| **PHP** | 8.1 / 8.2 / 8.3 / 8.4 |
| **Coding Style** | PSR-12 (Extended Coding Style) |
| **Architecture** | Dependency Injection (PSR-11), PSR-14 Events, PSR-15 Middleware |
| **Testing** | PHPUnit 10+, TYPO3 Testing Framework |
| **Documentation** | reStructuredText (RST), TYPO3 Documentation Standards |

### Conformance Areas

- **Extension Architecture** - File structure, naming conventions, required files
- **Coding Guidelines** - PSR-12 compliance, TYPO3-specific code style
- **PHP Architecture** - Dependency injection, services, events, Extbase patterns
- **Testing Standards** - Unit, functional, and acceptance testing requirements
- **Best Practices** - Real-world patterns from Tea extension and core standards

## Features

### Automated Validation Scripts

- ✅ **check-conformance.sh** - Main orchestration script
- 📁 **check-file-structure.sh** - File structure and directory validation
- 📝 **check-coding-standards.sh** - PSR-12 and TYPO3 code style checks
- 🏗️  **check-architecture.sh** - Dependency injection and architecture patterns
- 🧪 **check-testing.sh** - Testing infrastructure and coverage analysis
- 📊 **generate-report.sh** - Comprehensive conformance report generation

### Reference Documentation

- **version-requirements.md** - Official TYPO3 and PHP version compatibility matrix
- **extension-architecture.md** - TYPO3 file structure standards
- **coding-guidelines.md** - PSR-12 and TYPO3 code style guide
- **php-architecture.md** - Dependency injection and architectural patterns
- **testing-standards.md** - Unit, functional, and acceptance testing
- **best-practices.md** - Real-world patterns and project infrastructure

## Installation

### Download the Skill

```bash
# Using curl
curl -L https://github.com/netresearch/typo3-conformance-skill/archive/refs/heads/main.zip -o typo3-conformance.zip
unzip typo3-conformance.zip -d ~/.claude/skills/
mv ~/.claude/skills/typo3-conformance-skill-main ~/.claude/skills/typo3-conformance

# Or using git
git clone https://github.com/netresearch/typo3-conformance-skill.git ~/.claude/skills/typo3-conformance
```

### Verify Installation

The skill automatically activates when analyzing TYPO3 extensions for standards compliance.

## Usage

### Automated Conformance Checking

```bash
# Check current directory
cd /path/to/your-extension
~/.claude/skills/typo3-conformance/scripts/check-conformance.sh

# Check specific directory
~/.claude/skills/typo3-conformance/scripts/check-conformance.sh /path/to/your-extension
```

### Individual Checks

```bash
# File structure only
scripts/check-file-structure.sh /path/to/extension

# Coding standards only
scripts/check-coding-standards.sh /path/to/extension

# Architecture only
scripts/check-architecture.sh /path/to/extension

# Testing only
scripts/check-testing.sh /path/to/extension
```

### Claude Code Integration

#### Manual Invocation
```
/skill typo3-conformance
```

#### Automatic Activation

The skill activates automatically when:
- Analyzing TYPO3 extensions
- Checking code quality
- Reviewing standards compliance
- Evaluating extension architecture

### Example Workflows

**Quick Conformance Check:**
```
User: "Check if my TYPO3 extension follows current standards"

Claude: [Activates typo3-conformance skill]
- Analyzes file structure
- Checks coding standards
- Evaluates architecture patterns
- Reviews testing infrastructure
- Generates comprehensive conformance report
```

**Detailed Architecture Review:**
```
User: "Review the PHP architecture of my extension for TYPO3 best practices"

Claude: [Activates typo3-conformance skill]
- Focuses on dependency injection patterns
- Checks for deprecated patterns (GeneralUtility::makeInstance, $GLOBALS)
- Evaluates PSR-14 event system usage
- Reviews Extbase architecture if applicable
- Provides specific migration recommendations
```

**Pre-TER Publication Check:**
```
User: "My extension is ready for TER publication, please verify it meets all requirements"

Claude: [Activates typo3-conformance skill]
- Verifies all required files present (composer.json, ext_emconf.php, Documentation/)
- Checks file structure compliance
- Validates coding standards
- Reviews architecture patterns
- Assesses testing coverage
- Generates publication readiness report
```

## Conformance Report

The skill generates comprehensive markdown reports with:

### Overall Score (0-100)
- Extension Architecture: 0-20 points
- Coding Guidelines: 0-20 points
- PHP Architecture: 0-20 points
- Testing Standards: 0-20 points
- Best Practices: 0-20 points

### Detailed Analysis
- ✅ Strengths and passed checks
- ❌ Critical issues requiring immediate action
- ⚠️  Warnings and recommendations
- 📊 Test coverage estimates
- 💡 Migration guides and examples

### Priority Action Items
- **High Priority** - Critical issues blocking functionality or security
- **Medium Priority** - Important conformance issues
- **Low Priority** - Minor style and optimization improvements

## Example Report Output

```markdown
# TYPO3 Extension Conformance Report

**Extension:** my_extension (v1.0.0)
**Overall Score:** 75/100

## Summary
| Category | Score | Status |
|----------|-------|--------|
| Extension Architecture | 18/20 | ✅ Passed |
| Coding Guidelines | 15/20 | ⚠️  Issues |
| PHP Architecture | 16/20 | ✅ Passed |
| Testing Standards | 14/20 | ⚠️  Issues |
| Best Practices | 12/20 | ⚠️  Issues |

## Critical Issues
- ❌ 15 files missing declare(strict_types=1)
- ❌ 12 instances of GeneralUtility::makeInstance()
- ❌ Low test coverage (45% < 70% recommended)

## Recommendations
1. Add declare(strict_types=1) to all PHP files
2. Migrate to constructor injection
3. Increase unit test coverage
```

## Reference Standards

This skill is based on official TYPO3 documentation:

- [Extension Architecture](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ExtensionArchitecture/)
- [Coding Guidelines](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/CodingGuidelines/)
- [PHP Architecture](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/PhpArchitecture/)
- [Testing](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/)
- [Tea Extension (Best Practice)](https://github.com/TYPO3BestPractices/tea)

## Scoring System

### Extension Architecture (20 points)
- Required files present: 8 points
- Directory structure conformant: 6 points
- Naming conventions followed: 4 points
- No critical violations: 2 points

### Coding Guidelines (20 points)
- PSR-12 compliance: 8 points
- Type declarations: 4 points
- PHPDoc completeness: 4 points
- Naming conventions: 4 points

### PHP Architecture (20 points)
- Dependency injection: 8 points
- No deprecated patterns: 6 points
- Modern event system: 4 points
- Service configuration: 2 points

### Testing Standards (20 points)
- Test coverage >70%: 10 points
- Proper test structure: 6 points
- Configuration files present: 4 points

### Best Practices (20 points)
- Quality tools configured: 6 points
- CI/CD pipeline: 6 points
- Security practices: 4 points
- Documentation complete: 4 points

## Common Issues Detected

### Critical (Must Fix)
- Missing composer.json or ext_emconf.php
- PHP files in extension root
- Missing Configuration/Services.yaml
- Using GeneralUtility::makeInstance() instead of DI
- Accessing $GLOBALS instead of DI
- No unit tests

### High Priority
- Missing declare(strict_types=1)
- Old array() syntax instead of []
- Missing PHPDoc comments
- ext_tables.php usage (deprecated)
- Missing test coverage

### Medium Priority
- Incomplete documentation
- Missing quality tools configuration
- No CI/CD pipeline
- Inconsistent code formatting

## Migration Guides

### From GeneralUtility::makeInstance to Constructor Injection

```php
// ❌ Before (Deprecated)
use TYPO3\CMS\Core\Utility\GeneralUtility;

class MyService
{
    public function doSomething(): void
    {
        $repository = GeneralUtility::makeInstance(ProductRepository::class);
    }
}

// ✅ After (Modern)
class MyService
{
    public function __construct(
        private readonly ProductRepository $repository
    ) {}

    public function doSomething(): void
    {
        // Use $this->repository
    }
}
```

### From ext_tables.php to Configuration/Backend/Modules.php

```php
// ❌ Before (ext_tables.php - Deprecated)
ExtensionUtility::registerModule(
    'MyExtension',
    'web',
    'mymodule',
    '',
    [
        \Vendor\MyExtension\Controller\BackendController::class => 'list,show',
    ]
);

// ✅ After (Configuration/Backend/Modules.php - Modern)
return [
    'web_myext' => [
        'parent' => 'web',
        'position' => ['after' => 'web_info'],
        'access' => 'user',
        'path' => '/module/web/myext',
        'labels' => 'LLL:EXT:my_extension/Resources/Private/Language/locallang_mod.xlf',
        'extensionName' => 'MyExtension',
        'controllerActions' => [
            \Vendor\MyExtension\Controller\BackendController::class => [
                'list',
                'show',
            ],
        ],
    ],
];
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes
4. Test thoroughly
5. Commit your changes (`git commit -m 'Add improvement'`)
6. Push to the branch (`git push origin feature/improvement`)
7. Create a Pull Request

## License

This skill is licensed under GPL-2.0-or-later, matching the TYPO3 project license.

## Support

**Issues and Questions:**
- GitHub Issues: [Report issues](https://github.com/netresearch/typo3-conformance-skill/issues)
- TYPO3 Slack: [#typo3-cms](https://typo3.slack.com/archives/typo3-cms)

## Credits

Created by Netresearch DTT GmbH for the TYPO3 community.

Based on:
- [TYPO3 Official Documentation Standards](https://docs.typo3.org/)
- [TYPO3 Extension Architecture](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ExtensionArchitecture/)
- [TYPO3 Coding Guidelines](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/CodingGuidelines/)
- [TYPO3 Best Practices Tea Extension](https://github.com/TYPO3BestPractices/tea)

---

**Version:** 1.0.0
**Maintained By:** Netresearch DTT GmbH
**Last Updated:** 2025-10-18
