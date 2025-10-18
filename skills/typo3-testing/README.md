# TYPO3 Testing Skill

A comprehensive Claude Code skill for creating and managing TYPO3 extension tests.

## Features

- **Test Creation**: Generate Unit, Functional, and Acceptance tests
- **Infrastructure Setup**: Automated testing infrastructure installation
- **CI/CD Integration**: GitHub Actions and GitLab CI templates
- **Quality Tools**: PHPStan, Rector, php-cs-fixer integration
- **Fixture Management**: Database fixture templates and tooling
- **Test Orchestration**: runTests.sh script pattern from TYPO3 best practices

## Installation

Install the skill globally in Claude Code:

```bash
cd ~/.claude/skills
git clone https://github.com/netresearch/typo3-testing-skill.git typo3-testing
```

Or via Claude Code marketplace:

```bash
/plugin marketplace add netresearch/claude-code-marketplace
/plugin install typo3-testing
```

## Quick Start

1. **Setup testing infrastructure:**
   ```bash
   cd your-extension
   ~/.claude/skills/typo3-testing/scripts/setup-testing.sh
   ```

2. **Generate a test:**
   ```bash
   ~/.claude/skills/typo3-testing/scripts/generate-test.sh unit MyService
   ```

3. **Run tests:**
   ```bash
   Build/Scripts/runTests.sh -s unit
   composer ci:test
   ```

## Test Types

### Unit Tests
Fast, isolated tests without external dependencies. Perfect for testing services, utilities, and domain logic.

### Functional Tests
Tests with database and full TYPO3 instance. Use for repositories, controllers, and integration scenarios.

### Acceptance Tests
Browser-based end-to-end tests using Codeception and Selenium. For testing complete user workflows.

## Documentation

- [SKILL.md](SKILL.md) - Main workflow guide with decision trees
- [references/](references/) - Detailed testing documentation
- [templates/](templates/) - PHPUnit configs, AGENTS.md, examples

## Requirements

- PHP 8.1+
- Composer
- Docker (for functional and acceptance tests)
- TYPO3 v12 or v13

## Based On

- [TYPO3 Testing Framework](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/)
- [TYPO3 Best Practices: tea extension](https://github.com/TYPO3BestPractices/tea)
- TYPO3 community best practices

## License

GPL-2.0-or-later

## Maintained By

Netresearch DTT GmbH, Leipzig
