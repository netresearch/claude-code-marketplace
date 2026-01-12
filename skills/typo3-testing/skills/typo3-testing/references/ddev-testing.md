# DDEV Testing for TYPO3 Extensions

DDEV provides a consistent, containerized environment for testing TYPO3 extensions across different PHP and TYPO3 versions.

## When to Use DDEV Testing

- **E2E Tests**: Full browser testing with Playwright
- **Multi-Version Testing**: Test against TYPO3 12/13/14 and PHP 8.2/8.3/8.4
- **Real Environment**: Test with actual TYPO3 instance, database, web server
- **CI/CD Integration**: Reproducible testing in GitHub Actions

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
│   └── playwright/                  # E2E tests
└── composer.json
```

## Multi-Version Testing

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

## E2E Testing with Playwright

### Playwright Setup in DDEV

```bash
# From extension root
ddev start
ddev composer install

# Setup Playwright (if not using Build/playwright)
mkdir -p Tests/playwright
cd Tests/playwright
npm init -y
npm install -D @playwright/test
npx playwright install chromium
```

### Playwright Configuration for DDEV

Create `Tests/playwright/playwright.config.ts`:

```typescript
import { defineConfig, devices } from '@playwright/test';

const baseURL = process.env.BASE_URL || 'https://my-extension.ddev.site';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: false, // TYPO3 tests often need sequence
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['list'],
  ],
  use: {
    baseURL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    // Auth setup
    {
      name: 'setup',
      testMatch: /.*\.setup\.ts/,
    },
    // Main tests
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'playwright/.auth/admin.json',
      },
      dependencies: ['setup'],
    },
    // Accessibility tests
    {
      name: 'accessibility',
      testMatch: /.*\.a11y\.ts/,
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'playwright/.auth/admin.json',
      },
      dependencies: ['setup'],
    },
  ],
});
```

### TYPO3 Backend Login Setup

Create `Tests/playwright/e2e/auth.setup.ts`:

```typescript
import { test as setup, expect } from '@playwright/test';
import path from 'path';

const authFile = path.join(__dirname, '../playwright/.auth/admin.json');

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

Create `Tests/playwright/e2e/backend-module.spec.ts`:

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

## Running Tests in DDEV

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

### Via Playwright in DDEV

```bash
# Install Playwright browsers (first time)
cd Tests/playwright && npm ci && npx playwright install chromium

# Run E2E tests
cd Tests/playwright && npx playwright test

# Run with UI mode (local development)
cd Tests/playwright && npx playwright test --ui

# Run specific test file
cd Tests/playwright && npx playwright test backend-module.spec.ts
```

## GitHub Actions Integration

### E2E Workflow with DDEV

```yaml
name: E2E Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  e2e:
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - uses: actions/checkout@v4

      - name: Setup DDEV
        uses: ddev/github-action-setup-ddev@v1

      - name: Start DDEV
        run: |
          ddev start
          ddev composer install --no-progress

      - name: Setup TYPO3
        run: |
          ddev exec vendor/bin/typo3 extension:setup
          ddev exec vendor/bin/typo3 cache:flush

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: Install Playwright
        working-directory: Tests/playwright
        run: |
          npm ci
          npx playwright install --with-deps chromium

      - name: Run E2E tests
        working-directory: Tests/playwright
        run: npx playwright test
        env:
          BASE_URL: https://my-extension.ddev.site

      - name: Upload report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: Tests/playwright/playwright-report/
```

## Database Snapshots

### Creating Test Snapshots

```bash
# After setting up test data
ddev export-db --gzip --file=.ddev/db-dumps/test-fixtures.sql.gz
```

### Restoring for Tests

```bash
# In test setup or CI
ddev import-db --file=.ddev/db-dumps/test-fixtures.sql.gz
```

### In CI Workflow

```yaml
- name: Import test database
  run: |
    if [ -f ".ddev/db-dumps/test-fixtures.sql.gz" ]; then
      ddev import-db --file=.ddev/db-dumps/test-fixtures.sql.gz
    fi
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
- [DDEV GitHub Action](https://github.com/ddev/github-action-setup-ddev)
- [TYPO3 DDEV Addon](https://github.com/ddev/ddev-contrib/tree/master/docker-compose-services/typo3)
- [Playwright Documentation](https://playwright.dev/)
