# CI/CD Integration for TYPO3 Testing

Continuous Integration and Continuous Deployment workflows for automated TYPO3 extension testing.

## GitHub Actions

### Basic Workflow

Create `.github/workflows/tests.yml`:

```yaml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    name: Lint PHP
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.4'

      - name: Install dependencies
        run: composer install --no-progress

      - name: Run linting
        run: composer ci:test:php:lint

  phpstan:
    name: PHPStan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.4'

      - name: Install dependencies
        run: composer install --no-progress

      - name: Run PHPStan
        run: composer ci:test:php:phpstan

  unit:
    name: Unit Tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        php: ['8.1', '8.2', '8.3', '8.4']

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP ${{ matrix.php }}
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}
          coverage: pcov

      - name: Install dependencies
        run: composer install --no-progress

      - name: Run unit tests
        run: composer ci:test:php:unit

      - name: Upload coverage
        # Upload coverage for all PHP versions
        uses: codecov/codecov-action@v3

  functional:
    name: Functional Tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        php: ['8.1', '8.2', '8.3', '8.4']
        database: ['mysqli', 'pdo_mysql', 'postgres', 'sqlite']

    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: typo3_test
        ports:
          - 3306:3306
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3

      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: typo3_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP ${{ matrix.php }}
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}
          extensions: ${{ matrix.database == 'postgres' && 'pdo_pgsql' || 'mysqli' }}

      - name: Install dependencies
        run: composer install --no-progress

      - name: Run functional tests
        run: |
          export typo3DatabaseDriver=${{ matrix.database }}
          export typo3DatabaseHost=127.0.0.1
          export typo3DatabaseName=typo3_test
          export typo3DatabaseUsername=${{ matrix.database == 'postgres' && 'postgres' || 'root' }}
          export typo3DatabasePassword=${{ matrix.database == 'postgres' && 'postgres' || 'root' }}
          composer ci:test:php:functional
```

### Matrix Strategy

Test multiple PHP and TYPO3 versions:

```yaml
strategy:
  fail-fast: false
  matrix:
    php: ['8.1', '8.2', '8.3', '8.4']
    typo3: ['12.4', '13.0']
    exclude:
      - php: '8.1'
        typo3: '13.0'  # TYPO3 v13 requires PHP 8.2+

steps:
  - name: Install TYPO3 v${{ matrix.typo3 }}
    run: |
      composer require "typo3/cms-core:^${{ matrix.typo3 }}" --no-update
      composer update --no-progress
```

### Caching Dependencies

```yaml
- name: Cache Composer dependencies
  uses: actions/cache@v3
  with:
    path: ~/.composer/cache
    key: composer-${{ runner.os }}-${{ matrix.php }}-${{ hashFiles('composer.lock') }}
    restore-keys: |
      composer-${{ runner.os }}-${{ matrix.php }}-
      composer-${{ runner.os }}-

- name: Install dependencies
  run: composer install --no-progress --prefer-dist
```

### Code Coverage

```yaml
- name: Run tests with coverage
  run: vendor/bin/phpunit -c Build/phpunit/UnitTests.xml --coverage-clover coverage.xml

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v3
  with:
    file: ./coverage.xml
    flags: unittests
    name: codecov-umbrella
```

### PCOV vs Xdebug for Coverage

**PCOV is recommended for CI/CD** due to significant performance advantages:

| Aspect | PCOV | Xdebug |
|--------|------|--------|
| **Speed** | 2-5x faster | Slower (debugger overhead) |
| **Purpose** | Coverage only | Debugger + Profiler + Coverage |
| **Memory** | Lower footprint | Higher (full debugger loaded) |
| **CI/CD** | Ideal | Overkill for just coverage |

**Why PCOV is faster:**
- Xdebug hooks into every opcode execution for debugging capabilities
- PCOV only instruments line coverage — no step debugging, no profiling
- Less overhead = faster test runs

**When to use which:**
- **PCOV**: CI pipelines, large test suites, coverage reports
- **Xdebug**: Local debugging, step-through, profiling, breakpoints

**GitHub Actions setup:**
```yaml
- name: Setup PHP with PCOV (recommended for CI)
  uses: shivammathur/setup-php@v2
  with:
    php-version: ${{ matrix.php }}
    coverage: pcov

- name: Setup PHP with Xdebug (for debugging)
  uses: shivammathur/setup-php@v2
  with:
    php-version: ${{ matrix.php }}
    coverage: xdebug
```

**Local development with runTests.sh:**
```bash
# Fast coverage with PCOV (if available in Docker image)
php -d pcov.enabled=1 -d xdebug.mode=off \
    vendor/bin/phpunit --coverage-clover coverage.xml

# Coverage with Xdebug
php -d xdebug.mode=coverage \
    vendor/bin/phpunit --coverage-clover coverage.xml
```

> **Note:** PHPUnit auto-detects available coverage drivers and prefers PCOV
> if both are present. The TYPO3 core-testing Docker images
> (`ghcr.io/typo3/core-testing-php*`) include both PCOV and Xdebug.

## E2E Testing in CI

> **IMPORTANT: Do NOT use DDEV in CI!**
>
> DDEV is for local development only. Use GitHub Services + PHP built-in server for E2E tests in CI.

### Why NOT DDEV in CI?

| Issue | Impact |
|-------|--------|
| **Slow startup** | 2-3+ minutes for Docker orchestration |
| **Complexity** | Docker-in-Docker, networking, volumes |
| **Resource heavy** | Multiple containers exceed runner limits |
| **Fragile** | Port conflicts, DNS issues, cert problems |
| **Non-standard** | TYPO3 Core uses direct PHP, not DDEV |

### Correct E2E CI Pattern: GitHub Services

```yaml
# .github/workflows/e2e.yml
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    timeout-minutes: 20

    # GitHub Services - database container
    services:
      db:
        image: mariadb:11.4
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: typo3
          MYSQL_CHARSET: utf8mb4
          MYSQL_COLLATION: utf8mb4_unicode_ci
        ports:
          - 3306:3306
        options: >-
          --health-cmd="healthcheck.sh --connect --innodb_initialized"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.4'
          extensions: mysqli, pdo_mysql, gd, intl

      - name: Install Composer dependencies
        run: composer install --prefer-dist --no-progress

      - name: Setup TYPO3
        run: |
          mkdir -p .Build/Web/typo3conf
          cat > .Build/Web/typo3conf/LocalConfiguration.php << 'EOF'
          <?php
          return [
              'DB' => ['Connections' => ['Default' => [
                  'driver' => 'mysqli',
                  'host' => '127.0.0.1',
                  'dbname' => 'typo3',
                  'user' => 'root',
                  'password' => 'root',
              ]]],
              'SYS' => [
                  'encryptionKey' => '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
                  'trustedHostsPattern' => 'localhost|127\\.0\\.0\\.1',
              ],
          ];
          EOF

          # Wait for database
          for i in {1..30}; do
            mysqladmin ping -h127.0.0.1 -uroot -proot --silent 2>/dev/null && break
            sleep 2
          done

          .Build/bin/typo3 extension:setup --no-interaction
          .Build/bin/typo3 backend:user:create --username=admin --password='Joh316!!' --admin --no-interaction
          .Build/bin/typo3 cache:flush

      - uses: actions/setup-node@v4
        with:
          node-version: '20'  # Use LTS

      - name: Install Playwright
        run: |
          npm ci
          npx playwright install --with-deps chromium

      # PHP built-in server (NOT DDEV)
      - name: Start PHP server
        run: |
          php -S 0.0.0.0:8080 -t .Build/Web > /tmp/php-server.log 2>&1 &
          for i in $(seq 1 30); do
            curl -sf http://localhost:8080/typo3/ > /dev/null 2>&1 && break
            sleep 1
          done

      - name: Run Playwright tests
        env:
          TYPO3_BASE_URL: http://localhost:8080
        run: npm run test:e2e

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: Tests/E2E/Playwright/reports/
```

### Dual-Mode Playwright Configuration

Support both local (DDEV) and CI (localhost) environments:

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    // DDEV for local, CI sets TYPO3_BASE_URL=http://localhost:8080
    baseURL: process.env.TYPO3_BASE_URL || 'https://my-extension.ddev.site',
    ignoreHTTPSErrors: true, // For DDEV self-signed certs
  },
});
```

### runTests.sh Integration

The `runTests.sh` script should support both modes:

```bash
run_playwright_tests() {
    local typo3_base_url="${TYPO3_BASE_URL:-https://my-extension.ddev.site}"

    # Check if TYPO3 is accessible (use -k for https/DDEV)
    local curl_opts="-s"
    [[ "${typo3_base_url}" == https://* ]] && curl_opts="-sk"

    if ! curl ${curl_opts} "${typo3_base_url}/typo3/" > /dev/null 2>&1; then
        if [[ "${PLAYWRIGHT_FORCE:-0}" != "1" ]]; then
            echo "Error: TYPO3 not responding at ${typo3_base_url}"
            echo "Set PLAYWRIGHT_FORCE=1 to override."
            exit 1
        fi
    fi

    export TYPO3_BASE_URL="${typo3_base_url}"
    npm run test:e2e
}
```

## GitLab CI

### Basic Pipeline

Create `.gitlab-ci.yml`:

```yaml
variables:
  COMPOSER_CACHE_DIR: ".composer-cache"
  MYSQL_ROOT_PASSWORD: "root"
  MYSQL_DATABASE: "typo3_test"

cache:
  key: "$CI_COMMIT_REF_SLUG"
  paths:
    - .composer-cache/

stages:
  - lint
  - analyze
  - test

.php:
  image: php:${PHP_VERSION}-cli
  before_script:
    - apt-get update && apt-get install -y git zip unzip
    - curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    - composer install --no-progress

lint:
  extends: .php
  stage: lint
  variables:
    PHP_VERSION: "8.2"
  script:
    - composer ci:test:php:lint

phpstan:
  extends: .php
  stage: analyze
  variables:
    PHP_VERSION: "8.2"
  script:
    - composer ci:test:php:phpstan

cgl:
  extends: .php
  stage: analyze
  variables:
    PHP_VERSION: "8.2"
  script:
    - composer ci:test:php:cgl

unit:8.1:
  extends: .php
  stage: test
  variables:
    PHP_VERSION: "8.1"
  script:
    - composer ci:test:php:unit

unit:8.2:
  extends: .php
  stage: test
  variables:
    PHP_VERSION: "8.2"
  script:
    - composer ci:test:php:unit
  coverage: '/^\s*Lines:\s*\d+.\d+\%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml

functional:8.2:
  extends: .php
  stage: test
  variables:
    PHP_VERSION: "8.2"
    typo3DatabaseDriver: "mysqli"
    typo3DatabaseHost: "mysql"
    typo3DatabaseName: "typo3_test"
    typo3DatabaseUsername: "root"
    typo3DatabasePassword: "root"
  services:
    - mysql:8.0
  script:
    - composer ci:test:php:functional
```

### Multi-Database Testing

```yaml
.functional:
  extends: .php
  stage: test
  variables:
    PHP_VERSION: "8.2"
  script:
    - composer ci:test:php:functional

functional:mysql:
  extends: .functional
  variables:
    typo3DatabaseDriver: "mysqli"
    typo3DatabaseHost: "mysql"
    typo3DatabaseName: "typo3_test"
    typo3DatabaseUsername: "root"
    typo3DatabasePassword: "root"
  services:
    - mysql:8.0

functional:postgres:
  extends: .functional
  variables:
    typo3DatabaseDriver: "pdo_pgsql"
    typo3DatabaseHost: "postgres"
    typo3DatabaseName: "typo3_test"
    typo3DatabaseUsername: "postgres"
    typo3DatabasePassword: "postgres"
  services:
    - postgres:15
  before_script:
    - apt-get update && apt-get install -y libpq-dev
    - docker-php-ext-install pdo_pgsql

functional:sqlite:
  extends: .functional
  variables:
    typo3DatabaseDriver: "pdo_sqlite"
```

## Best Practices

### 1. Fast Feedback Loop

Order jobs by execution time (fastest first):

```yaml
stages:
  - lint        # ~30 seconds
  - analyze     # ~1-2 minutes (PHPStan, CGL)
  - unit        # ~2-5 minutes
  - functional  # ~5-15 minutes
  - acceptance  # ~15-30 minutes
```

### 2. Fail Fast

```yaml
strategy:
  fail-fast: true  # Stop on first failure
  matrix:
    php: ['8.1', '8.2', '8.3', '8.4']
```

### 3. Parallel Execution

```yaml
# GitHub Actions - parallel jobs
jobs:
  lint: ...
  phpstan: ...
  unit: ...
  # All run in parallel

# GitLab CI - parallel jobs
test:
  parallel:
    matrix:
      - PHP_VERSION: ['8.1', '8.2', '8.3']
```

### 4. Cache Dependencies

GitHub Actions:
```yaml
- uses: actions/cache@v3
  with:
    path: ~/.composer/cache
    key: ${{ runner.os }}-composer-${{ hashFiles('**/composer.lock') }}
```

GitLab CI:
```yaml
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .composer-cache/
```

### 5. Matrix Testing

Test critical combinations:

```yaml
strategy:
  matrix:
    include:
      # Minimum supported versions
      - php: '8.1'
        typo3: '12.4'

      # Current stable
      - php: '8.2'
        typo3: '12.4'

      # Latest versions
      - php: '8.3'
        typo3: '13.0'
```

### 6. Artifacts and Reports

```yaml
- name: Archive test results
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: test-results
    path: |
      var/log/
      typo3temp/var/tests/
```

### 7. Notifications

GitHub Actions:
```yaml
- name: Slack Notification
  if: failure()
  uses: rtCamp/action-slack-notify@v2
  env:
    SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
```

## Quality Gates

### Required Checks

Define which checks must pass:

GitHub:
```yaml
# .github/branch-protection.json
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "lint",
      "phpstan",
      "unit (8.2)",
      "functional (8.2, mysqli)"
    ]
  }
}
```

GitLab:
```yaml
# .gitlab-ci.yml
unit:8.2:
  only:
    - merge_requests
  allow_failure: false  # Required check
```

### Coverage Driver Issues

When PHPUnit config files include `<coverage>` sections, tests will fail if no coverage driver (xdebug/pcov) is available. Add `--no-coverage` flag when coverage is disabled:

```yaml
- name: Run unit tests
  run: |
    if [ "$COVERAGE_ENABLED" = "true" ]; then
      vendor/bin/phpunit -c Build/phpunit/UnitTests.xml
    else
      vendor/bin/phpunit -c Build/phpunit/UnitTests.xml --no-coverage
    fi
```

**Common error**: `PHPUnit\Framework\InvalidArgumentException: No code coverage driver available`

**Solution**: Either install a coverage driver (xdebug, pcov) or pass `--no-coverage`:

```bash
# Install pcov for faster coverage
pecl install pcov

# Or disable coverage in CI
vendor/bin/phpunit --no-coverage
```

### Coverage Requirements

```yaml
- name: Check code coverage
  run: |
    coverage=$(vendor/bin/phpunit --coverage-text | grep "Lines:" | awk '{print $2}' | sed 's/%//')
    if (( $(echo "$coverage < 80" | bc -l) )); then
      echo "Coverage $coverage% is below 80%"
      exit 1
    fi
```

## Environment-Specific Configuration

### Development Branch

```yaml
on:
  push:
    branches: [ develop ]

# Run all checks, allow failures
jobs:
  experimental:
    continue-on-error: true
    strategy:
      matrix:
        php: ['8.4']  # Experimental PHP version
```

### Production Branch

```yaml
on:
  push:
    branches: [ main ]

# Strict checks only
jobs:
  tests:
    strategy:
      fail-fast: true
      matrix:
        php: ['8.2']  # LTS version only
```

### Pull Requests

```yaml
on:
  pull_request:

# Full test matrix
jobs:
  tests:
    strategy:
      matrix:
        php: ['8.1', '8.2', '8.3', '8.4']
        database: ['mysqli', 'postgres']
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [GitLab CI Documentation](https://docs.gitlab.com/ee/ci/)
- [TYPO3 Tea Extension CI](https://github.com/TYPO3BestPractices/tea/tree/main/.github/workflows)
- [shivammathur/setup-php](https://github.com/shivammathur/setup-php)
