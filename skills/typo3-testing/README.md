# TYPO3 Testing Skill

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/netresearch/typo3-testing-skill/releases/tag/v2.0.0)

A comprehensive Claude Code skill for creating and managing TYPO3 extension tests.

## Features

- **Test Creation**: Generate Unit, Functional, and E2E tests
- **E2E Testing**: Playwright-based browser automation (TYPO3 Core standard)
- **Accessibility Testing**: axe-core integration for WCAG compliance
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

### E2E Tests (Playwright)
Browser-based end-to-end tests using Playwright (TYPO3 Core standard). For testing complete user workflows, backend modules, and accessibility compliance with axe-core.

## Advanced Testing Patterns

### Advanced PHPUnit Configuration

The tea extension demonstrates production-grade PHPUnit configuration with parallel execution, strict mode, and comprehensive coverage analysis.

#### Parallel Test Execution

PHPUnit 10+ supports parallel test execution for significant performance improvements:

**Configuration** (`Build/phpunit/UnitTests.xml`):

```xml
<phpunit
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="../../.Build/vendor/phpunit/phpunit/phpunit.xsd"
    executionOrder="random"
    failOnRisky="true"
    failOnWarning="true"
    stopOnFailure="false"
    beStrictAboutTestsThatDoNotTestAnything="true"
    colors="true"
    cacheDirectory=".Build/.phpunit.cache">

    <testsuites>
        <testsuite name="Unit Tests">
            <directory>../../Tests/Unit/</directory>
        </testsuite>
    </testsuites>

    <coverage includeUncoveredFiles="true">
        <report>
            <clover outputFile=".Build/coverage/clover.xml"/>
            <html outputDirectory=".Build/coverage/html"/>
            <text outputFile="php://stdout" showUncoveredFiles="false"/>
        </report>
    </coverage>
</phpunit>
```

**Key Features**:

- **`executionOrder="random"`**: Detects hidden test dependencies by randomizing test order
- **`failOnRisky="true"`**: Treats risky tests as failures (tests without assertions)
- **`failOnWarning="true"`**: Fails on warnings like deprecated function usage
- **`beStrictAboutTestsThatDoNotTestAnything="true"`**: Ensures every test has assertions

#### Separate Unit and Functional Configurations

The tea extension maintains separate PHPUnit configurations:

**Unit Tests** (`Build/phpunit/UnitTests.xml`):
- No database bootstrap
- Fast execution (milliseconds per test)
- Strict mode enabled
- Code coverage analysis

**Functional Tests** (`Build/phpunit/FunctionalTests.xml`):
- Database bootstrap included
- TYPO3 testing framework integration
- SQLite for fast in-memory testing
- Test doubles for external services

Example functional test configuration:

```xml
<phpunit
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="../../.Build/vendor/phpunit/phpunit/phpunit.xsd"
    stopOnFailure="false"
    colors="true"
    cacheDirectory=".Build/.phpunit.cache">

    <testsuites>
        <testsuite name="Functional Tests">
            <directory>../../Tests/Functional/</directory>
        </testsuite>
    </testsuites>

    <php>
        <ini name="display_errors" value="1"/>
        <env name="TYPO3_CONTEXT" value="Testing"/>
    </php>
</phpunit>
```

#### Coverage Thresholds

Enforce minimum coverage requirements via composer scripts:

```json
{
  "scripts": {
    "ci:coverage:check": [
      "@ci:tests:unit",
      "phpunit --configuration Build/phpunit/UnitTests.xml --coverage-text --coverage-clover=.Build/coverage/clover.xml",
      "phpunit-coverage-check .Build/coverage/clover.xml 70"
    ]
  }
}
```

**Progressive Coverage Targets**:
- MVP Extensions: 50% minimum
- Production Extensions: 70% minimum
- Reference Extensions: 80%+ target

### CSV Fixture and Assertion Pattern

The tea extension demonstrates an elegant CSV-based pattern for functional test fixtures, significantly improving test readability and maintainability.

#### Problem Statement

Traditional fixture loading in TYPO3 functional tests uses SQL files or PHP arrays:

```php
// ❌ Traditional approach: Verbose and hard to read
protected function setUp(): void
{
    parent::setUp();
    $this->importCSVDataSet(__DIR__ . '/Fixtures/Database/pages.csv');
    $this->importCSVDataSet(__DIR__ . '/Fixtures/Database/tt_content.csv');
    $this->importCSVDataSet(__DIR__ . '/Fixtures/Database/tx_tea_domain_model_product_tea.csv');
}
```

#### CSV Fixture Pattern

**Fixture File** (`Tests/Functional/Fixtures/Database/tea.csv`):

```csv
tx_tea_domain_model_product_tea
uid,pid,title,description,owner
1,1,"Earl Grey","Classic black tea",1
2,1,"Green Tea","Organic green tea",1
3,2,"Oolong Tea","Traditional oolong",2
```

**Loading in Test**:

```php
use TYPO3\TestingFramework\Core\Functional\FunctionalTestCase;

final class TeaRepositoryTest extends FunctionalTestCase
{
    protected array $testExtensionsToLoad = [
        'typo3conf/ext/tea',
    ];

    protected function setUp(): void
    {
        parent::setUp();
        $this->importCSVDataSet(__DIR__ . '/Fixtures/Database/tea.csv');
    }

    /**
     * @test
     */
    public function findAllReturnsAllRecords(): void
    {
        $result = $this->subject->findAll();

        self::assertCount(3, $result);
    }
}
```

#### CSV Assertion Pattern

**Even More Powerful**: Assert database state using CSV format:

**Expected State File** (`Tests/Functional/Fixtures/Database/AssertTeaAfterCreate.csv`):

```csv
tx_tea_domain_model_product_tea
uid,pid,title,description,owner
1,1,"Earl Grey","Classic black tea",1
2,1,"Green Tea","Organic green tea",1
3,2,"Oolong Tea","Traditional oolong",2
4,1,"New Tea","Newly created tea",1
```

**Assertion in Test**:

```php
/**
 * @test
 */
public function createPersistsNewTea(): void
{
    $newTea = new Tea();
    $newTea->setTitle('New Tea');
    $newTea->setDescription('Newly created tea');

    $this->subject->add($newTea);
    $this->persistenceManager->persistAll();

    // Assert entire database state matches expected CSV
    $this->assertCSVDataSet(__DIR__ . '/Fixtures/Database/AssertTeaAfterCreate.csv');
}
```

#### Benefits

1. **Readability**: CSV format is human-readable and version control friendly
2. **Maintainability**: Easy to modify fixtures without PHP syntax knowledge
3. **Comprehensive Assertions**: Assert entire table state in single call
4. **Change Detection**: Diff tools show fixture changes clearly
5. **Cross-Test Reuse**: Same CSV fixtures reusable across multiple tests

#### Best Practices

**Minimal Fixtures**: Include only necessary columns for the test:

```csv
tx_tea_domain_model_product_tea
uid,title
1,"Earl Grey"
2,"Green Tea"
```

**Named Test Data**: Use descriptive titles to make test intent clear:

```csv
tx_tea_domain_model_product_tea
uid,title,deleted
1,"Active Tea",0
2,"Deleted Tea",1
```

**Fixture Organization**:

```
Tests/Functional/
├── Fixtures/
│   └── Database/
│       ├── tea_initial.csv           # Initial state
│       ├── tea_after_create.csv      # Expected after creation
│       ├── tea_after_update.csv      # Expected after update
│       └── tea_after_delete.csv      # Expected after deletion
```

### Multi-Database Testing

The tea extension demonstrates comprehensive multi-database testing across SQLite, MariaDB, MySQL, and PostgreSQL, ensuring compatibility across all TYPO3-supported database systems.

#### Why Multi-Database Testing Matters

Different databases have subtle behavioral differences:

- **SQLite**: Case-insensitive LIKE, limited ALTER TABLE support
- **MySQL**: Case sensitivity varies by OS and configuration
- **MariaDB**: Different optimizer behavior, JSON handling differences
- **PostgreSQL**: Strict type casting, different string comparison semantics

Extensions using advanced SQL features (e.g., JSON columns, full-text search, stored procedures) must test across all target databases.

#### runTests.sh Pattern

The tea extension uses `Build/Scripts/runTests.sh` for orchestrated multi-database testing:

```bash
#!/usr/bin/env bash

# Run functional tests against SQLite (default, fast)
./Build/Scripts/runTests.sh -s functional

# Run functional tests against MariaDB 10.11
./Build/Scripts/runTests.sh -s functional -d mariadb -i 10.11

# Run functional tests against MySQL 8.0
./Build/Scripts/runTests.sh -s functional -d mysql -i 8.0

# Run functional tests against PostgreSQL 16
./Build/Scripts/runTests.sh -s functional -d postgres -i 16
```

**Script Responsibilities**:
1. Docker container orchestration
2. Database initialization and schema setup
3. Test execution with proper environment variables
4. Cleanup and teardown

#### CI Matrix Configuration

**GitHub Actions** (`.github/workflows/ci.yml`):

```yaml
name: CI

on: [push, pull_request]

jobs:
  functional-tests:
    name: Functional Tests
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        php: ['8.2', '8.3', '8.4']
        typo3: ['12.4', '13.0']
        database:
          - type: 'sqlite'
          - type: 'mariadb'
            version: '10.11'
          - type: 'mysql'
            version: '8.0'
          - type: 'postgres'
            version: '16'

    steps:
      - uses: actions/checkout@v4

      - name: Set up PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}
          extensions: pdo_sqlite, pdo_mysql, pdo_pgsql

      - name: Composer Install
        run: composer install --no-progress

      - name: Functional Tests
        run: |
          if [ "${{ matrix.database.type }}" = "sqlite" ]; then
            ./Build/Scripts/runTests.sh -s functional
          else
            ./Build/Scripts/runTests.sh -s functional -d ${{ matrix.database.type }} -i ${{ matrix.database.version }}
          fi
```

This matrix runs tests across:
- 3 PHP versions × 2 TYPO3 versions × 4 databases = **24 test combinations**

#### Database-Specific Considerations

**SQLite Advantages**:
- Fast (in-memory execution)
- No external dependencies
- Ideal for local development

**SQLite Limitations**:
```php
// ❌ Won't work on SQLite (lacks ALTER TABLE support)
$connection->executeUpdate('ALTER TABLE tt_content ADD COLUMN new_field VARCHAR(255)');

// ✅ Use TYPO3 API instead (cross-database compatible)
$schemaManager = $connection->getSchemaManager();
$column = new Column('new_field', Type::getType('string'), ['length' => 255]);
$schemaManager->addColumn('tt_content', $column);
```

**PostgreSQL Strict Typing**:
```php
// ❌ MySQL/MariaDB allow implicit conversion, PostgreSQL doesn't
$queryBuilder->where(
    $queryBuilder->expr()->eq('uid', '123')  // String '123' vs INT uid
);

// ✅ Explicit type casting works everywhere
$queryBuilder->where(
    $queryBuilder->expr()->eq('uid', $queryBuilder->createNamedParameter(123, \PDO::PARAM_INT))
);
```

#### Local Multi-Database Testing

Developers can run multi-database tests locally:

```bash
# Quick SQLite test during development
composer ci:tests:functional

# Comprehensive multi-DB test before pushing
./Build/Scripts/runTests.sh -s functional -d mariadb
./Build/Scripts/runTests.sh -s functional -d mysql
./Build/Scripts/runTests.sh -s functional -d postgres
```

#### Docker Compose Alternative

For complex scenarios, use `docker-compose.yml`:

```yaml
version: '3.8'

services:
  mariadb:
    image: mariadb:10.11
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: test
    ports:
      - "3306:3306"

  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: root
      POSTGRES_DB: test
    ports:
      - "5432:5432"

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: test
    ports:
      - "3307:3306"
```

### runTests.sh Orchestration Pattern

The `runTests.sh` script from the tea extension provides comprehensive test orchestration with Docker-based isolation.

#### Core Features

**1. Test Suite Selection**:
```bash
./Build/Scripts/runTests.sh -s unit              # Unit tests only
./Build/Scripts/runTests.sh -s functional        # Functional tests
./Build/Scripts/runTests.sh -s acceptance        # Acceptance tests
./Build/Scripts/runTests.sh -s lint              # PHP linting
./Build/Scripts/runTests.sh -s phpstan           # Static analysis
```

**2. Database Selection**:
```bash
./Build/Scripts/runTests.sh -s functional -d sqlite       # Default
./Build/Scripts/runTests.sh -s functional -d mariadb      # MariaDB
./Build/Scripts/runTests.sh -s functional -d mysql        # MySQL
./Build/Scripts/runTests.sh -s functional -d postgres     # PostgreSQL
```

**3. Version Control**:
```bash
./Build/Scripts/runTests.sh -s functional -d mariadb -i 10.11
./Build/Scripts/runTests.sh -s functional -d postgres -i 16
./Build/Scripts/runTests.sh -p 8.3              # PHP version
```

**4. Cleanup and Maintenance**:
```bash
./Build/Scripts/runTests.sh -s clean            # Remove containers
./Build/Scripts/runTests.sh -s composer update  # Update dependencies
```

#### Implementation Structure

**Key Components**:

```bash
#!/usr/bin/env bash

# Parse command line arguments
while getopts "s:d:i:p:h" option; do
    case ${option} in
        s) TEST_SUITE=${OPTARG} ;;
        d) DATABASE=${OPTARG} ;;
        i) DATABASE_VERSION=${OPTARG} ;;
        p) PHP_VERSION=${OPTARG} ;;
        h) showHelp; exit 0 ;;
    esac
done

# Set defaults
DATABASE=${DATABASE:-sqlite}
PHP_VERSION=${PHP_VERSION:-8.2}

# Container configuration
CONTAINER_NAME="typo3-testing-${DATABASE}"
DOCKER_IMAGE="typo3/core-testing-${DATABASE}:${DATABASE_VERSION}"

# Execute test suite in container
docker run \
    --name ${CONTAINER_NAME} \
    --rm \
    -v $(pwd):/app \
    -w /app \
    ${DOCKER_IMAGE} \
    /bin/bash -c "composer ci:tests:${TEST_SUITE}"
```

#### Benefits

1. **Isolation**: Each test run in clean container environment
2. **Reproducibility**: Same environment locally and in CI
3. **Version Flexibility**: Test against multiple PHP/TYPO3/DB versions
4. **Developer Convenience**: Single command for all test types
5. **CI Integration**: Same script used locally and in CI

#### Integration with Composer Scripts

Composer scripts delegate to `runTests.sh`:

```json
{
  "scripts": {
    "ci:tests:unit": "Build/Scripts/runTests.sh -s unit",
    "ci:tests:functional": "Build/Scripts/runTests.sh -s functional",
    "ci:tests:functional:mariadb": "Build/Scripts/runTests.sh -s functional -d mariadb",
    "ci:tests:functional:postgres": "Build/Scripts/runTests.sh -s functional -d postgres",
    "ci:tests": [
      "@ci:tests:unit",
      "@ci:tests:functional"
    ]
  }
}
```

This maintains the local-CI parity principle: developers and CI use identical commands.

#### Example Usage Workflows

**Development Workflow**:
```bash
# Quick unit test during coding
composer ci:tests:unit

# Functional test before commit
composer ci:tests:functional

# Full test suite before push
composer ci:tests
```

**Pre-Release Workflow**:
```bash
# Test against all databases
./Build/Scripts/runTests.sh -s functional -d sqlite
./Build/Scripts/runTests.sh -s functional -d mariadb -i 10.11
./Build/Scripts/runTests.sh -s functional -d mysql -i 8.0
./Build/Scripts/runTests.sh -s functional -d postgres -i 16

# Test against multiple PHP versions
./Build/Scripts/runTests.sh -s unit -p 8.2
./Build/Scripts/runTests.sh -s unit -p 8.3
./Build/Scripts/runTests.sh -s unit -p 8.4
```

**CI/CD Workflow**:
```yaml
# .github/workflows/ci.yml
- name: Unit Tests
  run: composer ci:tests:unit

- name: Functional Tests (SQLite)
  run: composer ci:tests:functional

- name: Functional Tests (MariaDB)
  run: composer ci:tests:functional:mariadb

- name: Functional Tests (PostgreSQL)
  run: composer ci:tests:functional:postgres
```

## Documentation

- [SKILL.md](SKILL.md) - Main workflow guide with decision trees
- [references/](references/) - Detailed testing documentation
- [templates/](templates/) - PHPUnit configs, AGENTS.md, examples

## Requirements

- PHP 8.1+
- Composer
- Docker (for functional tests)
- Node.js 22.18+ (for E2E tests)
- TYPO3 v12 or v13

## Based On

- [TYPO3 Testing Framework](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/)
- [TYPO3 Best Practices: tea extension](https://github.com/TYPO3BestPractices/tea)
- TYPO3 community best practices

## License

GPL-2.0-or-later

## Maintained By

Netresearch DTT GmbH, Leipzig
