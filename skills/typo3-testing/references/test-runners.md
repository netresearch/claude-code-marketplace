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
PHP_VERSION="8.2"
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
        php: ['8.1', '8.2', '8.3']
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
