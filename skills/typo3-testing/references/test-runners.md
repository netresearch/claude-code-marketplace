# Test Runners and Orchestration

The `runTests.sh` script is the standard TYPO3 pattern for orchestrating all quality checks and test suites.

## Purpose

- Single entry point for all testing and quality checks
- Consistent environment across local and CI/CD
- Handles Docker, database setup, and test execution
- Based on [TYPO3 Best Practices tea extension](https://github.com/TYPO3BestPractices/tea)

## Script Location

```
Build/Scripts/runTests.sh
```

## Basic Usage

```bash
# Show help
./Build/Scripts/runTests.sh -h

# Run specific test suite
./Build/Scripts/runTests.sh -s unit
./Build/Scripts/runTests.sh -s functional
./Build/Scripts/runTests.sh -s acceptance

# Run quality tools
./Build/Scripts/runTests.sh -s lint
./Build/Scripts/runTests.sh -s phpstan
./Build/Scripts/runTests.sh -s cgl
./Build/Scripts/runTests.sh -s rector
```

## Script Options

```
-s <suite>     Test suite to run (required)
               unit, functional, acceptance, lint, phpstan, cgl, rector

-d <driver>    Database driver for functional tests
               mysqli (default), pdo_mysql, postgres, sqlite

-p <version>   PHP version (7.4, 8.1, 8.2, 8.3)

-e <command>   Execute specific command in container

-n             Don't pull Docker images

-u             Update composer dependencies

-v             Enable verbose output

-x             Stop on first error (PHPUnit --stop-on-error)
```

## Examples

### Run Unit Tests

```bash
# Default PHP version
./Build/Scripts/runTests.sh -s unit

# Specific PHP version
./Build/Scripts/runTests.sh -s unit -p 8.3

# Stop on first error
./Build/Scripts/runTests.sh -s unit -x
```

### Run Functional Tests

```bash
# Default database (mysqli)
./Build/Scripts/runTests.sh -s functional

# PostgreSQL
./Build/Scripts/runTests.sh -s functional -d postgres

# SQLite (fastest for local development)
./Build/Scripts/runTests.sh -s functional -d sqlite
```

### Run Quality Tools

```bash
# Lint all PHP files
./Build/Scripts/runTests.sh -s lint

# PHPStan static analysis
./Build/Scripts/runTests.sh -s phpstan

# Code style check
./Build/Scripts/runTests.sh -s cgl

# Rector automated refactoring
./Build/Scripts/runTests.sh -s rector
```

### Custom Commands

```bash
# Run specific test file
./Build/Scripts/runTests.sh -s unit -e "bin/phpunit Tests/Unit/Domain/Model/ProductTest.php"

# Run with coverage
./Build/Scripts/runTests.sh -s unit -e "bin/phpunit --coverage-html coverage/"
```

## Composer Integration

Integrate runTests.sh into composer.json:

```json
{
    "scripts": {
        "ci:test": [
            "@ci:test:php:lint",
            "@ci:test:php:phpstan",
            "@ci:test:php:cgl",
            "@ci:test:php:rector",
            "@ci:test:php:unit",
            "@ci:test:php:functional"
        ],
        "ci:test:php:lint": "Build/Scripts/runTests.sh -s lint",
        "ci:test:php:phpstan": "Build/Scripts/runTests.sh -s phpstan",
        "ci:test:php:cgl": "Build/Scripts/runTests.sh -s cgl",
        "ci:test:php:rector": "Build/Scripts/runTests.sh -s rector",
        "ci:test:php:unit": "Build/Scripts/runTests.sh -s unit",
        "ci:test:php:functional": "Build/Scripts/runTests.sh -s functional"
    }
}
```

Then run via composer:

```bash
composer ci:test              # All checks
composer ci:test:php:unit     # Just unit tests
composer ci:test:php:phpstan  # Just PHPStan
```

## Script Structure

### Basic Template

```bash
#!/usr/bin/env bash

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default values
TEST_SUITE=""
DATABASE_DRIVER="mysqli"
PHP_VERSION="8.4"
VERBOSE=""

# Parse arguments
while getopts ":s:d:p:e:nuvx" opt; do
    case ${opt} in
        s) TEST_SUITE=${OPTARG} ;;
        d) DATABASE_DRIVER=${OPTARG} ;;
        p) PHP_VERSION=${OPTARG} ;;
        *) showHelp; exit 1 ;;
    esac
done

# Validate required arguments
if [ -z "${TEST_SUITE}" ]; then
    echo "Error: -s parameter (test suite) is required"
    showHelp
    exit 1
fi

# Execute test suite
case ${TEST_SUITE} in
    unit)
        runUnitTests
        ;;
    functional)
        runFunctionalTests
        ;;
    lint)
        runLint
        ;;
    *)
        echo "Error: Unknown test suite: ${TEST_SUITE}"
        showHelp
        exit 1
        ;;
esac
```

### Docker Integration

```bash
runUnitTests() {
    CONTAINER_PATH="/app"

    docker run \
        --rm \
        -v "${PROJECT_DIR}:${CONTAINER_PATH}" \
        -w "${CONTAINER_PATH}" \
        php:${PHP_VERSION}-cli \
        bin/phpunit -c Build/phpunit/UnitTests.xml
}

runFunctionalTests() {
    CONTAINER_PATH="/app"

    docker run \
        --rm \
        -v "${PROJECT_DIR}:${CONTAINER_PATH}" \
        -w "${CONTAINER_PATH}" \
        -e typo3DatabaseDriver="${DATABASE_DRIVER}" \
        -e typo3DatabaseHost="localhost" \
        -e typo3DatabaseName="typo3_test" \
        php:${PHP_VERSION}-cli \
        bin/phpunit -c Build/phpunit/FunctionalTests.xml
}
```

### Quality Tool Functions

```bash
runLint() {
    docker run \
        --rm \
        -v "${PROJECT_DIR}:/app" \
        -w /app \
        php:${PHP_VERSION}-cli \
        vendor/bin/phplint
}

runPhpstan() {
    docker run \
        --rm \
        -v "${PROJECT_DIR}:/app" \
        -w /app \
        php:${PHP_VERSION}-cli \
        vendor/bin/phpstan analyze --configuration Build/phpstan.neon
}

runCgl() {
    docker run \
        --rm \
        -v "${PROJECT_DIR}:/app" \
        -w /app \
        php:${PHP_VERSION}-cli \
        vendor/bin/php-cs-fixer fix --config Build/php-cs-fixer.php --dry-run --diff
}
```

## Environment Variables

Configure via environment variables:

```bash
# Database configuration
export typo3DatabaseDriver=pdo_mysql
export typo3DatabaseHost=db
export typo3DatabasePort=3306
export typo3DatabaseName=typo3_test
export typo3DatabaseUsername=root
export typo3DatabasePassword=root

# TYPO3 context
export TYPO3_CONTEXT=Testing

# Run tests
./Build/Scripts/runTests.sh -s functional
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Tests

on: [push, pull_request]

jobs:
  tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        php: '8.2', '8.2', '8.3']
        suite: ['unit', 'functional', 'lint', 'phpstan']

    steps:
      - uses: actions/checkout@v4

      - name: Run ${{ matrix.suite }} tests
        run: Build/Scripts/runTests.sh -s ${{ matrix.suite }} -p ${{ matrix.php }}
```

### GitLab CI

```yaml
.test:
  image: php:${PHP_VERSION}-cli
  script:
    - Build/Scripts/runTests.sh -s ${TEST_SUITE} -p ${PHP_VERSION}

unit:8.2:
  extends: .test
  variables:
    PHP_VERSION: "8.2"
    TEST_SUITE: "unit"

functional:8.2:
  extends: .test
  variables:
    PHP_VERSION: "8.2"
    TEST_SUITE: "functional"
```

## Performance Optimization

### Parallel Execution

```bash
# Run linting in parallel (fast)
find . -name '*.php' -print0 | xargs -0 -n1 -P8 php -l

# PHPUnit parallel execution
vendor/bin/paratest -c Build/phpunit/UnitTests.xml --processes=4
```

### Caching

```bash
# Cache Composer dependencies
if [ ! -d "${PROJECT_DIR}/.cache/composer" ]; then
    mkdir -p "${PROJECT_DIR}/.cache/composer"
fi

docker run \
    --rm \
    -v "${PROJECT_DIR}:/app" \
    -v "${PROJECT_DIR}/.cache/composer:/tmp/composer-cache" \
    php:${PHP_VERSION}-cli \
    composer install --no-progress --no-suggest
```

## Best Practices

1. **Single Source of Truth**: Use runTests.sh for all test execution
2. **CI/CD Alignment**: CI should use same script as local development
3. **Docker Isolation**: Run tests in containers for consistency
4. **Fast Feedback**: Run lint and unit tests first (fastest)
5. **Matrix Testing**: Test multiple PHP versions and databases
6. **Caching**: Cache dependencies to speed up execution
7. **Verbose Mode**: Use `-v` flag for debugging test failures

## Troubleshooting

### Docker Permission Issues

```bash
# Run with current user
docker run \
    --rm \
    --user $(id -u):$(id -g) \
    -v "${PROJECT_DIR}:/app" \
    php:${PHP_VERSION}-cli \
    bin/phpunit
```

### Database Connection Errors

```bash
# Verify database is accessible
docker run --rm --network host mysql:8.0 \
    mysql -h localhost -u root -p -e "SELECT 1"

# Use SQLite for simple tests
./Build/Scripts/runTests.sh -s functional -d sqlite
```

### Missing Dependencies

```bash
# Update dependencies
./Build/Scripts/runTests.sh -s unit -u
```

## Resources

- [TYPO3 Tea Extension runTests.sh](https://github.com/TYPO3BestPractices/tea/blob/main/Build/Scripts/runTests.sh)
- [TYPO3 Testing Documentation](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/)
- [PHPUnit Documentation](https://phpunit.de/documentation.html)

## Multi-PHP Version Testing

TYPO3 extensions should support multiple PHP versions to maximize compatibility. This section covers testing strategies for all supported PHP versions.

### Standard Approach: Using Build/Scripts/runTests.sh

The `runTests.sh` script with Docker containers is the recommended TYPO3 testing approach. It provides isolated environments and consistent results.

#### Testing Across PHP Versions with Docker

```bash
# Test with PHP 8.2
./Build/Scripts/runTests.sh -s unit -p 8.2
./Build/Scripts/runTests.sh -s functional -p 8.2 -d sqlite

# Test with PHP 8.3
./Build/Scripts/runTests.sh -s unit -p 8.3
./Build/Scripts/runTests.sh -s functional -p 8.3 -d sqlite

# Test with PHP 8.4
./Build/Scripts/runTests.sh -s unit -p 8.4
./Build/Scripts/runTests.sh -s functional -p 8.4 -d sqlite
```

**Advantages:**
- Isolated Docker containers per PHP version
- Consistent environment across local and CI/CD
- No need to install multiple PHP versions locally
- Handles database setup automatically
- Based on official TYPO3 best practices

#### Complete Test Matrix Example

```bash
#!/bin/bash
# Test all supported PHP versions and databases

PHP_VERSIONS=("8.2" "8.3" "8.4")
DATABASES=("sqlite" "mysql" "postgres")

for PHP in "${PHP_VERSIONS[@]}"; do
    echo "Testing PHP ${PHP}..."
    
    # Unit tests
    ./Build/Scripts/runTests.sh -s unit -p "${PHP}"
    
    # Functional tests with different databases
    for DB in "${DATABASES[@]}"; do
        echo "  Functional tests with ${DB}..."
        ./Build/Scripts/runTests.sh -s functional -p "${PHP}" -d "${DB}"
    done
    
    # Quality tools (run once per PHP version)
    ./Build/Scripts/runTests.sh -s lint -p "${PHP}"
    ./Build/Scripts/runTests.sh -s phpstan -p "${PHP}"
done
```

### Alternative Approach: Native PHP Versions (Without Docker)

For CI/CD environments or when Docker is unavailable, use locally installed PHP versions.

#### Testing with Native PHP Installations

```bash
# Test with PHP 8.2
php8.2 /usr/local/bin/composer update --no-interaction
php8.2 .Build/bin/phpunit --configuration=Build/phpunit/UnitTests.xml
typo3DatabaseDriver=pdo_sqlite php8.2 .Build/bin/phpunit --configuration=Build/phpunit/FunctionalTests.xml

# Test with PHP 8.3
php8.3 /usr/local/bin/composer update --no-interaction
php8.3 .Build/bin/phpunit --configuration=Build/phpunit/UnitTests.xml
typo3DatabaseDriver=pdo_sqlite php8.3 .Build/bin/phpunit --configuration=Build/phpunit/FunctionalTests.xml

# Test with PHP 8.4
php8.4 /usr/local/bin/composer update --no-interaction
php8.4 .Build/bin/phpunit --configuration=Build/phpunit/UnitTests.xml
typo3DatabaseDriver=pdo_sqlite php8.4 .Build/bin/phpunit --configuration=Build/phpunit/FunctionalTests.xml
```

**CRITICAL**: Always run `composer update` with the target PHP version FIRST. This ensures:
- Correct PHPUnit version selection (PHPUnit 11 for PHP 8.2, PHPUnit 12 for PHP 8.3+)
- Proper dependency resolution for the PHP version
- Compatible autoloader generation

### PHPUnit Version Compatibility

The `typo3/testing-framework` supports both PHPUnit 11 and 12, allowing Composer to automatically select the compatible version:

| PHP Version | PHPUnit Version | Auto-Selected by Composer |
|-------------|-----------------|---------------------------|
| 8.2         | 11.x            | ✅ Yes                     |
| 8.3         | 11.x or 12.x    | ✅ Yes (12.x preferred)    |
| 8.4         | 11.x or 12.x    | ✅ Yes (12.x preferred)    |

**Example: Automatic PHPUnit Selection**

```bash
# PHP 8.2 automatically gets PHPUnit 11
$ php8.2 /usr/local/bin/composer update
# Installing typo3/testing-framework (v8.0.14)
# Installing phpunit/phpunit (11.5.42)

# PHP 8.3 automatically gets PHPUnit 12
$ php8.3 /usr/local/bin/composer update
# Installing typo3/testing-framework (v8.0.14)
# Installing phpunit/phpunit (12.4.1)
```

### GitHub Actions CI/CD Integration

#### Using runTests.sh (Recommended)

```yaml
name: CI

on: [push, pull_request]

jobs:
  tests:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        php: ['8.2', '8.3', '8.4']
        suite: ['unit', 'functional']
        database: ['sqlite', 'mysql', 'postgres']
        exclude:
          # Only test sqlite for unit tests
          - suite: unit
            database: mysql
          - suite: unit
            database: postgres

    steps:
      - uses: actions/checkout@v4

      - name: Run ${{ matrix.suite }} tests on PHP ${{ matrix.php }}
        run: |
          Build/Scripts/runTests.sh \
            -s ${{ matrix.suite }} \
            -p ${{ matrix.php }} \
            -d ${{ matrix.database }}
```

#### Using Native PHP (Alternative)

```yaml
name: CI

on: [push, pull_request]

jobs:
  tests:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        php: ['8.2', '8.3', '8.4']

    steps:
      - uses: actions/checkout@v4

      - name: Set up PHP ${{ matrix.php }}
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}
          extensions: dom, libxml, sqlite3
          coverage: none

      - name: Install dependencies
        run: composer update --no-interaction --no-progress

      - name: Run unit tests
        run: .Build/bin/phpunit -c Build/phpunit/UnitTests.xml

      - name: Run functional tests
        env:
          typo3DatabaseDriver: pdo_sqlite
        run: .Build/bin/phpunit -c Build/phpunit/FunctionalTests.xml
```

### Common Pitfalls

#### ❌ Wrong: Testing Without Updating Dependencies

```bash
# This will use wrong PHPUnit version
php8.2 .Build/bin/phpunit -c Build/phpunit/UnitTests.xml
```

**Problem:** Uses PHPUnit version from previous `composer update`, may be incompatible.

#### ✅ Right: Update Dependencies First

```bash
# This ensures correct PHPUnit version
php8.2 /usr/local/bin/composer update --no-interaction
php8.2 .Build/bin/phpunit -c Build/phpunit/UnitTests.xml
```

#### ❌ Wrong: Removing PHP Version Support Due to Test Failures

```bash
# Don't do this!
# composer.json: "php": "^8.3 || ^8.4"  # Removed 8.2
```

**Problem:** Unnecessarily reduces compatibility. Fix the testing approach instead.

#### ✅ Right: Fix Testing Process

```bash
# Run composer update with the problematic PHP version
php8.2 /usr/local/bin/composer update
# Composer automatically selects compatible dependencies
# Now tests work correctly
```

### Best Practices

1. **Standard Approach First**: Use `Build/Scripts/runTests.sh` with Docker whenever possible
2. **Update Before Testing**: Always run `composer update` with target PHP version first (native approach)
3. **Trust Composer**: Let Composer select compatible PHPUnit versions automatically
4. **Test All Versions**: Run full test suite on all supported PHP versions in CI
5. **SQLite for Speed**: Use SQLite for local functional testing (fastest)
6. **Matrix Testing**: Use CI matrix to test all PHP versions in parallel
7. **Don't Remove Support**: Fix testing process, don't remove PHP version support

### Troubleshooting

#### Docker Issues

```bash
# Update Docker images
./Build/Scripts/runTests.sh -u

# Check Docker is running
docker ps

# Clean up old containers
docker system prune -a
```

#### Native PHP Issues

```bash
# Verify PHP version
php8.2 --version

# Check installed extensions
php8.2 -m | grep -E 'dom|libxml|sqlite'

# Clean and reinstall dependencies
rm -rf .Build vendor composer.lock
php8.2 /usr/local/bin/composer install
```

#### PHPUnit Version Conflicts

```bash
# Clear Composer cache
php8.2 /usr/local/bin/composer clear-cache

# Show why PHPUnit version was selected
php8.2 /usr/local/bin/composer why phpunit/phpunit

# Force dependency resolution
rm composer.lock
php8.2 /usr/local/bin/composer update --with-all-dependencies
```

### Summary

| Aspect | Docker/runTests.sh | Native PHP |
|--------|-------------------|------------|
| **Use Case** | Standard TYPO3 development | CI/CD, no Docker available |
| **Isolation** | ✅ Full container isolation | ⚠️ System-wide PHP |
| **Setup** | Docker required | Multiple PHP versions required |
| **Speed** | Slower (container overhead) | Faster (native execution) |
| **Consistency** | ✅ Guaranteed environment | ⚠️ Depends on system config |
| **Recommendation** | **Recommended** | Alternative when needed |

**Choose Docker/runTests.sh for:**
- Local development and testing
- Consistent environment across team
- Official TYPO3 best practices

**Choose Native PHP for:**
- GitHub Actions/GitLab CI environments
- Systems without Docker
- Performance-critical testing pipelines
