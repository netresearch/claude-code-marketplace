# Test Runners and Orchestration

The `runTests.sh` script is the **required** TYPO3 pattern for test orchestration, following TYPO3 core conventions.

## Requirements

Extensions **MUST** have a Docker-based `Build/Scripts/runTests.sh` that:

1. Uses **TYPO3 core-testing images** (`ghcr.io/typo3/core-testing-php*`)
2. Supports **multiple databases** (SQLite default, MariaDB, MySQL, PostgreSQL)
3. Supports **multiple PHP versions** (8.2, 8.3, 8.4, 8.5)
4. Works in **CI environments** (auto-detects non-TTY)
5. Handles **database container orchestration** for functional tests
6. Uses **--user flag** on Linux to prevent root-owned files

## Template

Use `assets/Build/Scripts/runTests.sh` as starting point. Customize:

1. `NETWORK` variable: Replace `my-extension` with your extension key
2. `COMPOSER_ROOT_VERSION`: Set to your extension version
3. `TYPO3_BASE_URL`: Set default ddev URL for E2E tests
4. Add ddev hostnames to `DDEV_PARAMS` for E2E tests

## Basic Usage

```bash
# Show help
./Build/Scripts/runTests.sh -h

# Run unit tests (default)
./Build/Scripts/runTests.sh -s unit

# Run functional tests with SQLite (fastest, no container)
./Build/Scripts/runTests.sh -s functional

# Run functional tests in parallel (2-3x faster)
./Build/Scripts/runTests.sh -s functionalParallel

# Run functional tests with MariaDB
./Build/Scripts/runTests.sh -s functional -d mariadb

# Run with specific PHP version
./Build/Scripts/runTests.sh -p 8.3 -s unit

# Run E2E tests (requires running TYPO3)
ddev start && ./Build/Scripts/runTests.sh -s e2e

# Run quality tools
./Build/Scripts/runTests.sh -s lint
./Build/Scripts/runTests.sh -s phpstan
./Build/Scripts/runTests.sh -s cgl
```

## Script Options

| Option | Description | Values |
|--------|-------------|--------|
| `-s` | Test suite | `unit`, `functional`, `functionalParallel`, `e2e`, `lint`, `phpstan`, `cgl`, `rector`, `fuzz`, `mutation` |
| `-d` | Database | `sqlite` (default), `mariadb`, `mysql`, `postgres` |
| `-i` | DB version | mariadb: 10.11, mysql: 8.0, postgres: 16 |
| `-p` | PHP version | `8.2`, `8.3`, `8.4`, `8.5` |
| `-x` | Enable Xdebug | |
| `-n` | Dry-run | For cgl, rector |
| `-u` | Update images | |

## Test Parallelization

### E2E Tests (Playwright)

Playwright parallelizes by spec file. Configure in `playwright.config.ts`:

```typescript
export default defineConfig({
  fullyParallel: false, // Tests within file run sequentially (safer)
  workers: process.env.CI ? 4 : undefined, // CI: fixed, Local: half of CPUs
});
```

**Performance**: 3x speedup (3.8min → 1.3min for 111 tests)

**Note**: Workers are capped at the number of spec files when `fullyParallel: false`.

### Functional Tests (functionalParallel)

Uses `xargs -P` to run test files concurrently with SQLite:

```bash
# CI: 4 parallel jobs for predictable resource usage
# Local: half of available CPUs
if [ "${CI}" == "true" ]; then
    PARALLEL_JOBS=4
else
    PARALLEL_JOBS="$(($(nproc) + 1) / 2)"
fi

find Tests/Functional -name '*Test.php' | xargs -P${PARALLEL_JOBS} ...
```

**Performance**: 2-3x speedup (24s → 10s for 62 tests)

**Requirement**: SQLite with tmpfs for isolated databases per test file.

### Unit Tests

Unit tests are typically fast enough (<1s) that parallelization overhead would be counterproductive. PHPUnit's native parallelization (ParaTest) doesn't support PHPUnit 12 yet.

## Database Support

### SQLite (Default)
- **Fastest**: No container startup
- **CI-friendly**: No external services needed
- **Parallelizable**: Each test file gets isolated DB

```bash
./Build/Scripts/runTests.sh -s functional  # Uses SQLite
```

### MariaDB/MySQL
- Required for MySQL-specific syntax
- Mark incompatible tests with `#[Group('not-sqlite')]`

```bash
./Build/Scripts/runTests.sh -s functional -d mariadb -i 10.11
./Build/Scripts/runTests.sh -s functional -d mysql -i 8.0
```

### PostgreSQL
- For PostgreSQL compatibility testing

```bash
./Build/Scripts/runTests.sh -s functional -d postgres -i 16
```

## E2E Test Integration

E2E tests require a running TYPO3 instance. The script supports:

1. **ddev integration**: Auto-detects ddev, connects to ddev network
2. **Custom URL**: Via `TYPO3_BASE_URL` environment variable

```bash
# Option 1: ddev (recommended)
ddev start && ./Build/Scripts/runTests.sh -s e2e

# Option 2: Custom URL
TYPO3_BASE_URL=https://my-typo3.local ./Build/Scripts/runTests.sh -s e2e
```

### ddev Network Integration

When ddev is running, the script:
1. Gets the ddev-router IP address
2. Connects to `ddev_default` network
3. Adds `--add-host` entries for ddev hostnames

```bash
ROUTER_IP=$(docker inspect ddev-router --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
DDEV_PARAMS="--network ddev_default"
DDEV_PARAMS="${DDEV_PARAMS} --add-host my-extension.ddev.site:${ROUTER_IP}"
```

### Playwright Docker Image

Use the official Playwright image with pre-installed browsers:

```bash
IMAGE_PLAYWRIGHT="mcr.microsoft.com/playwright:v1.57.0-noble"
```

**Important**: Keep Playwright versions in sync between:
- `package.json`: `"@playwright/test": "^1.57.0"`
- `runTests.sh`: `IMAGE_PLAYWRIGHT="mcr.microsoft.com/playwright:v1.57.0-noble"`

## Helper Functions

### waitFor (TCP port)

Wait for a service to be available on a TCP port:

```bash
waitFor() {
    local HOST=${1}
    local PORT=${2}
    # Uses netcat to check port availability
    # Retries up to 10 times with 1 second delay
}

# Usage
waitFor mariadb-container 3306
```

### waitForHttp (HTTP endpoint)

Wait for an HTTP endpoint to respond:

```bash
waitForHttp() {
    local URL=${1}
    local MAX_ATTEMPTS=${2:-30}
    # Uses wget to check HTTP availability
}

# Usage: Wait for mock OAuth server
waitForHttp "http://mock-oauth-container:8080/.well-known/openid-configuration"
```

## Mock Services

### Mock OAuth Server

For testing OAuth integration without real providers:

```bash
IMAGE_MOCK_OAUTH="ghcr.io/navikt/mock-oauth2-server:3.0.1"

${CONTAINER_BIN} run --rm -d --name mock-oauth-${SUFFIX} --network ${NETWORK} \
    -e SERVER_PORT=8080 \
    -e JSON_CONFIG_PATH=/config/config.json \
    -v "${ROOT_DIR}/.ddev/mock-oauth:/config:ro" \
    ${IMAGE_MOCK_OAUTH}

waitFor mock-oauth-${SUFFIX} 8080

# Pass URL to tests
-e MOCK_OAUTH_URL="http://mock-oauth-${SUFFIX}:8080"
```

## PHP Performance Optimization

Enable opcache and JIT for faster test execution:

```bash
PHP_OPCACHE_OPTS="-d opcache.enable_cli=1 -d opcache.jit=1255 -d opcache.jit_buffer_size=128M"
```

**Note**: Disable JIT for coverage (`-d opcache.jit=off`) as it's incompatible with Xdebug.

## Permission Handling

### Linux --user Flag

On Linux, containers run as the host user to prevent root-owned files:

```bash
if [ $(uname) != "Darwin" ]; then
    USERSET="--user $(id -u)"
fi
```

### Root-owned Files Detection

For E2E tests, detect and warn about root-owned node_modules:

```bash
if [ "$(find node_modules -maxdepth 1 -user root 2>/dev/null | head -1)" ]; then
    echo "Error: node_modules contains root-owned files."
    echo "Please remove: sudo rm -rf node_modules"
    exit 1
fi
```

## Makefile Integration

Create a `Makefile` for convenient shortcuts:

```makefile
RUNTESTS = Build/Scripts/runTests.sh

.PHONY: test unit functional lint phpstan cs fix ci e2e

test: unit
unit:
	$(RUNTESTS) -s unit

functional:
	$(RUNTESTS) -s functional

functional-fast:
	$(RUNTESTS) -s functionalParallel

e2e:
	$(RUNTESTS) -s e2e

lint:
	$(RUNTESTS) -s lint

phpstan:
	$(RUNTESTS) -s phpstan

cs:
	$(RUNTESTS) -s cgl -n

fix:
	$(RUNTESTS) -s cgl

ci: lint cs phpstan unit functional
```

## CI/CD Integration

### GitHub Actions (Recommended)

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
        database: ['sqlite']
        include:
          - php: '8.4'
            suite: 'functional'
            database: 'mariadb'

    steps:
      - uses: actions/checkout@v4

      - name: Run ${{ matrix.suite }} tests
        run: |
          Build/Scripts/runTests.sh \
            -s ${{ matrix.suite }} \
            -p ${{ matrix.php }} \
            -d ${{ matrix.database }}

  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: Build/Scripts/runTests.sh -s lint
      - run: Build/Scripts/runTests.sh -s phpstan
      - run: Build/Scripts/runTests.sh -s cgl -n

  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ddev/github-action-setup-ddev@v1
      - run: ddev start
      - run: Build/Scripts/runTests.sh -s e2e
```

## Troubleshooting

### TTY Errors
Script auto-detects non-TTY environments. If issues persist:
```bash
CI=true ./Build/Scripts/runTests.sh -s unit
```

### Database Connection Errors
```bash
# Check container is running
docker ps

# Use SQLite to rule out DB issues
./Build/Scripts/runTests.sh -s functional -d sqlite
```

### Root-owned Files
```bash
# Remove root-owned files (requires sudo)
sudo rm -rf node_modules .Build
```

### Update Images
```bash
./Build/Scripts/runTests.sh -u
```

## Best Practices

1. **SQLite First**: Use SQLite for most functional tests (fastest)
2. **Parallel Tests**: Use `functionalParallel` for faster CI
3. **Matrix Testing**: Test all supported PHP versions in CI
4. **Group Incompatible Tests**: Use `#[Group('not-sqlite')]` for DB-specific tests
5. **Single Entry Point**: All tests via `runTests.sh`, not direct PHPUnit
6. **Makefile Shortcuts**: Provide `make test`, `make ci` for convenience
7. **Update Images**: Run `-u` periodically to get latest TYPO3 images
8. **Keep Versions Synced**: Playwright versions in package.json and runTests.sh

## Resources

- [TYPO3 Tea Extension](https://github.com/TYPO3BestPractices/tea) - Reference implementation
- [TYPO3 Core Testing](https://github.com/typo3/typo3) - Core approach
- [typo3/core-testing images](https://github.com/typo3/core-testing) - Official images
- [nr-vault](https://github.com/netresearch/t3x-nr-vault) - Reference with all patterns
