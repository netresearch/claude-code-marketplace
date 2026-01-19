# DDEV Testing for TYPO3 Extensions

DDEV provides a consistent, containerized environment for testing TYPO3 extensions across different PHP and TYPO3 versions.

> **IMPORTANT: DDEV is for LOCAL DEVELOPMENT only!**
>
> Do NOT use DDEV in CI/CD pipelines (GitHub Actions, GitLab CI, etc.).
> For CI, use GitHub Services + PHP built-in server instead.
> See `ci-cd.md` and the `github-actions-e2e.yml` template.

## When to Use DDEV

**USE DDEV for:**
- Local development environment
- Interactive debugging and testing
- Multi-version testing on your machine
- Full-stack testing with services (Redis, Elasticsearch, etc.)
- Team environment consistency

**DO NOT USE DDEV for:**
- CI/CD pipelines (GitHub Actions, GitLab CI)
- Automated testing in cloud environments
- Production deployments

## Why NOT DDEV in CI?

| Issue | Impact |
|-------|--------|
| **Slow startup** | 2-3+ minutes for Docker orchestration |
| **Complexity** | Docker-in-Docker, networking, volumes |
| **Resource heavy** | Multiple containers exceed runner limits |
| **Fragile** | Port conflicts, DNS issues, cert problems |
| **Non-standard** | TYPO3 Core uses direct PHP, not DDEV |

**For CI, use:** GitHub Services (MariaDB) + PHP built-in server.
See `assets/github-actions-e2e.yml` for the correct pattern.

## Basic DDEV Setup

### Minimal `.ddev/config.yaml`

```yaml
name: my-extension
type: typo3
docroot: .Build/public
php_version: "8.3"
webserver_type: nginx-fpm
database:
  type: mariadb
  version: "10.11"

# Composer settings
composer_version: "2"
composer_root: .

# Performance
mutagen_enabled: false
nfs_mount_enabled: false

# Hooks for setup
hooks:
  post-start:
    - exec: composer install --no-progress
```

### Extension Development Structure

```
my-extension/
├── .ddev/
│   ├── config.yaml
│   ├── config.local.yaml.example    # Local overrides template
│   ├── docker-compose.*.yaml        # Additional services
│   └── db-dumps/
│       └── initial.sql.gz           # Database snapshot
├── .Build/                          # Build artifacts
│   ├── public/                      # TYPO3 web root
│   └── vendor/                      # Composer packages
├── Classes/
├── Tests/
│   ├── Unit/
│   ├── Functional/
│   └── E2E/Playwright/              # E2E tests
└── composer.json
```

## Multi-Version Testing (Local)

### Matrix Testing Script

Create `Build/Scripts/test-matrix.sh`:

```bash
#!/usr/bin/env bash
set -e

# TYPO3 and PHP version combinations to test
MATRIX=(
    "12:8.2"
    "12:8.3"
    "13:8.3"
    "13:8.4"
)

for combo in "${MATRIX[@]}"; do
    IFS=':' read -r TYPO3_VERSION PHP_VERSION <<< "$combo"

    echo "Testing TYPO3 v${TYPO3_VERSION} with PHP ${PHP_VERSION}..."

    # Update DDEV config
    ddev config --php-version="${PHP_VERSION}"

    # Update composer constraint
    ddev composer require "typo3/cms-core:^${TYPO3_VERSION}" --no-update
    ddev composer update --no-progress

    # Run tests
    ddev exec vendor/bin/phpunit -c Build/phpunit/UnitTests.xml
    ddev exec vendor/bin/phpunit -c Build/phpunit/FunctionalTests.xml

    echo "TYPO3 v${TYPO3_VERSION} + PHP ${PHP_VERSION}: PASSED"
done

echo "All matrix combinations passed!"
```

### DDEV Config Override for Testing

Create `.ddev/config.testing.yaml`:

```yaml
# Testing-specific overrides
# Activate with: ddev config --project-type=typo3

# Use specific PHP version for testing
# php_version: "8.4"

# Database for isolated testing
# database:
#   type: sqlite

# Disable unnecessary services
disable_settings_management: false
omit_containers: []

# Testing-specific environment variables
web_environment:
  - TYPO3_CONTEXT=Testing
  - APP_ENV=test
```

## E2E Testing with Playwright (Local)

### Playwright Setup in DDEV

```bash
# From extension root
ddev start
ddev composer install

# Setup Playwright (if not using Build/playwright)
mkdir -p Tests/E2E/Playwright
cd Tests/E2E/Playwright
npm init -y
npm install -D @playwright/test
npx playwright install chromium
```

### Playwright Configuration for Dual-Mode (Local + CI)

Create `playwright.config.ts`:

```typescript
import { defineConfig, devices } from '@playwright/test';

// IMPORTANT: Support both DDEV (local) and localhost (CI)
const baseURL = process.env.TYPO3_BASE_URL || 'https://my-extension.ddev.site';

export default defineConfig({
  testDir: './tests',
  fullyParallel: false, // TYPO3 tests often need sequence
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [
    ['html', { outputFolder: 'reports' }],
    ['list'],
  ],
  use: {
    baseURL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    // DDEV uses self-signed certs
    ignoreHTTPSErrors: true,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
```

**Key point:** The `TYPO3_BASE_URL` environment variable allows the same tests to run:
- **Locally with DDEV:** Uses `https://my-extension.ddev.site` (default)
- **In CI:** Uses `http://localhost:8080` (set by workflow)

### TYPO3 Backend Login Setup

Create `Tests/E2E/Playwright/tests/auth.setup.ts`:

```typescript
import { test as setup, expect } from '@playwright/test';
import path from 'path';

const authFile = path.join(__dirname, '../.auth/admin.json');

setup('authenticate as admin', async ({ page }) => {
  // Navigate to TYPO3 backend login
  await page.goto('/typo3');

  // Wait for login form
  await page.waitForSelector('input[name="username"]');

  // Fill credentials
  await page.fill('input[name="username"]', 'admin');
  await page.fill('input[name="password"]', 'password');

  // Submit login
  await page.click('button[type="submit"]');

  // Wait for dashboard or module
  await page.waitForURL(/\/typo3\/module\//);

  // Verify login succeeded
  await expect(page.locator('.modulemenu')).toBeVisible();

  // Save authentication state
  await page.context().storageState({ path: authFile });
});
```

### Example E2E Test

Create `Tests/E2E/Playwright/tests/backend-module.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';

test.describe('Backend Module', () => {
  test('module is accessible', async ({ page }) => {
    // Navigate to extension module
    await page.goto('/typo3/module/web/my-extension');

    // Verify module loaded
    await expect(page.locator('h1')).toContainText('My Extension');
  });

  test('can create new record', async ({ page }) => {
    await page.goto('/typo3/module/web/my-extension');

    // Click create button
    await page.click('[data-action="create"]');

    // Fill form
    await page.fill('input[name="title"]', 'Test Record');

    // Save
    await page.click('button[name="_savedok"]');

    // Verify success message
    await expect(page.locator('.alert-success')).toBeVisible();
  });
});
```

## Running Tests in DDEV (Local)

### Via DDEV Exec

```bash
# Unit tests
ddev exec vendor/bin/phpunit -c Build/phpunit/UnitTests.xml

# Functional tests
ddev exec vendor/bin/phpunit -c Build/phpunit/FunctionalTests.xml

# PHPStan
ddev exec vendor/bin/phpstan analyse -c phpstan.neon

# PHP-CS-Fixer
ddev exec vendor/bin/php-cs-fixer fix --dry-run --diff
```

### Via Custom DDEV Commands

Create `.ddev/commands/host/test`:

```bash
#!/bin/bash
## Description: Run extension tests
## Usage: test [unit|functional|all|phpstan|cgl]
## Example: ddev test unit

case "$1" in
  unit)
    ddev exec vendor/bin/phpunit -c Build/phpunit/UnitTests.xml
    ;;
  functional)
    ddev exec vendor/bin/phpunit -c Build/phpunit/FunctionalTests.xml
    ;;
  phpstan)
    ddev exec vendor/bin/phpstan analyse -c phpstan.neon
    ;;
  cgl)
    ddev exec vendor/bin/php-cs-fixer fix --dry-run --diff
    ;;
  all|*)
    ddev exec vendor/bin/phpunit -c Build/phpunit/UnitTests.xml
    ddev exec vendor/bin/phpunit -c Build/phpunit/FunctionalTests.xml
    ddev exec vendor/bin/phpstan analyse -c phpstan.neon
    ;;
esac
```

Make executable: `chmod +x .ddev/commands/host/test`

### Via Playwright in DDEV (Local)

```bash
# Install Playwright browsers (first time)
cd Tests/E2E/Playwright && npm ci && npx playwright install chromium

# Run E2E tests against DDEV
cd Tests/E2E/Playwright && npx playwright test

# Run with UI mode (local development)
cd Tests/E2E/Playwright && npx playwright test --ui

# Run specific test file
cd Tests/E2E/Playwright && npx playwright test backend-module.spec.ts
```

## Database Snapshots

### Creating Test Snapshots

```bash
# After setting up test data
ddev export-db --gzip --file=.ddev/db-dumps/test-fixtures.sql.gz
```

### Restoring for Tests

```bash
# In local test setup
ddev import-db --file=.ddev/db-dumps/test-fixtures.sql.gz
```

## runTests.sh Integration

For running E2E tests via `runTests.sh`, use the `TYPO3_BASE_URL` environment variable:

```bash
# Local development (DDEV)
./Build/Scripts/runTests.sh playwright

# Or explicitly set the URL
TYPO3_BASE_URL=https://my-extension.ddev.site ./Build/Scripts/runTests.sh playwright
```

The script should check if TYPO3 is accessible and fail if not (unless `PLAYWRIGHT_FORCE=1` is set):

```bash
run_playwright_tests() {
    local typo3_base_url="${TYPO3_BASE_URL:-https://my-extension.ddev.site}"

    # Check if TYPO3 is accessible
    local curl_opts="-s"
    if [[ "${typo3_base_url}" == https://* ]]; then
        curl_opts="-sk"  # Allow self-signed certs for DDEV
    fi

    if ! curl ${curl_opts} "${typo3_base_url}/typo3/" > /dev/null 2>&1; then
        warning "TYPO3 not responding at ${typo3_base_url}"
        if [[ "${PLAYWRIGHT_FORCE:-0}" != "1" ]]; then
            error "Aborting. Set PLAYWRIGHT_FORCE=1 to override."
            exit 1
        fi
    fi

    export TYPO3_BASE_URL="${typo3_base_url}"
    npm run test:e2e
}
```

## Troubleshooting

### Common Issues

1. **DDEV not starting**
   ```bash
   ddev poweroff && ddev start
   ```

2. **Port conflicts**
   ```bash
   ddev config --router-http-port=8080 --router-https-port=8443
   ```

3. **Permission issues**
   ```bash
   ddev exec chmod -R 775 var/
   ```

4. **Database connection in tests**
   - Functional tests use their own database
   - E2E tests use the DDEV database

### Debug Mode

Enable TYPO3 debug in DDEV:

```bash
ddev exec vendor/bin/typo3 configuration:set SYS/devIPmask '*'
ddev exec vendor/bin/typo3 configuration:set SYS/displayErrors 1
ddev exec vendor/bin/typo3 cache:flush
```

## Resources

- [DDEV Documentation](https://ddev.readthedocs.io/)
- [TYPO3 DDEV Addon](https://github.com/ddev/ddev-contrib/tree/master/docker-compose-services/typo3)
- [Playwright Documentation](https://playwright.dev/)

---

> **Remember:** DDEV is for LOCAL development. For CI, see `ci-cd.md`.
