# E2E Testing with Playwright

TYPO3 Core uses **Playwright** exclusively for end-to-end and accessibility testing. This is the modern standard for browser-based testing in TYPO3 extensions.

**Reference:** [TYPO3 Core Build/tests/playwright](https://github.com/TYPO3/typo3/tree/main/Build/tests/playwright)

## When to Use E2E Tests

- Testing complete user journeys (login, browse, action)
- Frontend functionality validation
- Backend module interaction testing
- JavaScript-heavy interactions
- Visual regression testing
- Cross-browser compatibility

## Requirements

```json
// package.json
{
  "engines": {
    "node": ">=22.18.0 <23.0.0",
    "npm": ">=11.5.2"
  },
  "devDependencies": {
    "@playwright/test": "^1.56.1",
    "@axe-core/playwright": "^4.9.0"
  },
  "scripts": {
    "playwright:install": "playwright install",
    "playwright:open": "playwright test --ui --ignore-https-errors",
    "playwright:run": "playwright test",
    "playwright:codegen": "playwright codegen",
    "playwright:report": "playwright show-report"
  }
}
```

## Directory Structure

```
Build/
├── playwright.config.ts          # Main Playwright configuration
├── package.json                  # Node dependencies
├── .nvmrc                        # Node version (22.18)
└── tests/
    └── playwright/
        ├── config.ts             # TYPO3-specific config (baseUrl, credentials)
        ├── e2e/                   # End-to-end tests
        │   ├── backend/
        │   │   └── module.spec.ts
        │   └── frontend/
        │       └── pages.spec.ts
        ├── accessibility/        # Accessibility tests (axe-core)
        │   └── modules.spec.ts
        ├── fixtures/             # Page Object Models
        │   ├── setup-fixtures.ts
        │   └── backend-page.ts
        └── helper/
            └── login.setup.ts    # Authentication setup
```

## Configuration

### Playwright Config

```typescript
// Build/playwright.config.ts
import { defineConfig } from '@playwright/test';
import config from './tests/playwright/config';

export default defineConfig({
  testDir: './tests/playwright',
  timeout: 30000,
  expect: {
    timeout: 10000,
  },
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['list'],
    ['html', { outputFolder: '../typo3temp/var/tests/playwright-reports' }],
  ],
  outputDir: '../typo3temp/var/tests/playwright-results',

  use: {
    baseURL: config.baseUrl,
    ignoreHTTPSErrors: true,
    trace: 'on-first-retry',
  },

  projects: [
    {
      name: 'login setup',
      testMatch: /helper\/login\.setup\.ts/,
    },
    {
      name: 'accessibility',
      testMatch: /accessibility\/.*\.spec\.ts/,
      dependencies: ['login setup'],
      use: {
        storageState: './.auth/login.json',
      },
    },
    {
      name: 'e2e',
      testMatch: /e2e\/.*\.spec\.ts/,
      dependencies: ['login setup'],
      use: {
        storageState: './.auth/login.json',
      },
    },
  ],
});
```

### TYPO3-Specific Config

```typescript
// Build/tests/playwright/config.ts
export default {
  baseUrl: process.env.PLAYWRIGHT_BASE_URL ?? 'http://web:80/typo3/',
  admin: {
    username: process.env.PLAYWRIGHT_ADMIN_USERNAME ?? 'admin',
    password: process.env.PLAYWRIGHT_ADMIN_PASSWORD ?? 'password',
  },
};
```

## Authentication Setup

Store authentication state to avoid repeated logins:

```typescript
// Build/tests/playwright/helper/login.setup.ts
import { test as setup, expect } from '@playwright/test';
import config from '../config';

setup('login', async ({ page }) => {
  await page.goto('/');
  await page.getByLabel('Username').fill(config.admin.username);
  await page.getByLabel('Password').fill(config.admin.password);
  await page.getByRole('button', { name: 'Login' }).click();
  await page.waitForLoadState('networkidle');

  // Verify login succeeded
  await expect(page.locator('.t3js-topbar-button-modulemenu')).toBeVisible();

  // Save authentication state
  await page.context().storageState({ path: './.auth/login.json' });
});
```

## Page Object Model (Fixtures)

Create reusable page objects for TYPO3 backend:

```typescript
// Build/tests/playwright/fixtures/setup-fixtures.ts
import { test as base, type Locator, type Page, expect } from '@playwright/test';

export class BackendPage {
  readonly page: Page;
  readonly moduleMenu: Locator;
  readonly contentFrame: ReturnType<Page['frameLocator']>;

  constructor(page: Page) {
    this.page = page;
    this.moduleMenu = page.locator('#modulemenu');
    this.contentFrame = page.frameLocator('#typo3-contentIframe');
  }

  async gotoModule(identifier: string): Promise<void> {
    const moduleLink = this.moduleMenu.locator(
      `[data-modulemenu-identifier="${identifier}"]`
    );
    await moduleLink.click();
    await expect(moduleLink).toHaveClass(/modulemenu-action-active/);
  }

  async moduleLoaded(): Promise<void> {
    await this.page.evaluate(() => {
      return new Promise<void>((resolve) => {
        document.addEventListener('typo3-module-loaded', () => resolve(), {
          once: true,
        });
      });
    });
  }

  async waitForModuleResponse(urlPattern: string | RegExp): Promise<void> {
    await this.page.waitForResponse((response) => {
      const url = response.url();
      const matches =
        typeof urlPattern === 'string'
          ? url.includes(urlPattern)
          : urlPattern.test(url);
      return matches && response.status() === 200;
    });
  }
}

export class Modal {
  readonly page: Page;
  readonly container: Locator;
  readonly title: Locator;
  readonly closeButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.container = page.locator('.modal');
    this.title = this.container.locator('.modal-title');
    this.closeButton = this.container.locator('[data-bs-dismiss="modal"]');
  }

  async close(): Promise<void> {
    await this.closeButton.click();
    await expect(this.container).not.toBeVisible();
  }
}

type BackendFixtures = {
  backend: BackendPage;
  modal: Modal;
};

export const test = base.extend<BackendFixtures>({
  backend: async ({ page }, use) => {
    await use(new BackendPage(page));
  },
  modal: async ({ page }, use) => {
    await use(new Modal(page));
  },
});

export { expect, Locator };
```

## Writing E2E Tests

### Basic Test Structure

```typescript
// Build/tests/playwright/e2e/backend/module.spec.ts
import { test, expect } from '../../fixtures/setup-fixtures';

test.describe('My Extension Backend Module', () => {
  test('can access module', async ({ backend }) => {
    await backend.gotoModule('web_myextension');
    await backend.moduleLoaded();

    const contentFrame = backend.contentFrame;
    await expect(contentFrame.locator('h1')).toBeVisible();
  });

  test('can perform action in module', async ({ backend, modal }) => {
    await backend.gotoModule('web_myextension');

    await backend.contentFrame
      .getByRole('button', { name: 'Create new record' })
      .click();

    await expect(modal.container).toBeVisible();
    await expect(modal.title).toContainText('Create');
    await modal.close();
  });

  test('can save form data', async ({ backend }) => {
    await backend.gotoModule('web_myextension');

    const contentFrame = backend.contentFrame;
    await contentFrame.getByLabel('Title').fill('Test Title');
    await contentFrame.getByLabel('Description').fill('Test Description');
    await contentFrame.getByRole('button', { name: 'Save' }).click();

    await backend.waitForModuleResponse(/module\/web\/myextension/);
    await expect(contentFrame.locator('.alert-success')).toBeVisible();
  });
});
```

### Common Actions

```typescript
// Navigation
await page.goto('/module/web/layout');
await page.goBack();

// Form interaction
await page.getByLabel('Title').fill('Value');
await page.getByRole('button', { name: 'Save' }).click();
await page.getByRole('combobox').selectOption('option-value');
await page.getByRole('checkbox').check();

// Assertions
await expect(page.locator('.success')).toBeVisible();
await expect(page.locator('h1')).toContainText('Title');
await expect(page).toHaveURL(/module\/web\/layout/);

// Waiting
await page.waitForLoadState('networkidle');
await page.waitForSelector('.loaded');
await page.waitForResponse(/api\/endpoint/);
```

## Running Tests

```bash
# Install Playwright browsers
npm run playwright:install

# Run all tests
npm run playwright:run

# Run with UI mode (interactive)
npm run playwright:open

# Run specific test file
npx playwright test e2e/backend/module.spec.ts

# Run tests matching pattern
npx playwright test --grep "can access"

# Generate test code (record & playback)
npm run playwright:codegen

# Run in headed mode (see browser)
npx playwright test --headed

# Debug mode
npx playwright test --debug

# Generate HTML report
npm run playwright:report
```

## DDEV Integration

```yaml
# .ddev/docker-compose.playwright.yaml
services:
  playwright:
    container_name: ddev-${DDEV_SITENAME}-playwright
    image: mcr.microsoft.com/playwright:v1.56.1-noble
    volumes:
      - ../:/var/www/html
    working_dir: /var/www/html/Build
    environment:
      - PLAYWRIGHT_BASE_URL=http://web:80/typo3/
    depends_on:
      - web
```

```bash
# Run Playwright in DDEV
ddev exec -s playwright npx playwright test
```

## CI/CD Integration

```yaml
# .github/workflows/playwright.yml
name: Playwright Tests

on: [push, pull_request]

jobs:
  playwright:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: Install dependencies
        working-directory: ./Build
        run: npm ci

      - name: Install Playwright browsers
        working-directory: ./Build
        run: npx playwright install --with-deps chromium

      - name: Start TYPO3
        run: |
          ddev start
          ddev import-db --file=.ddev/db.sql.gz

      - name: Run Playwright tests
        working-directory: ./Build
        run: npx playwright test
        env:
          PLAYWRIGHT_BASE_URL: https://myproject.ddev.site/typo3/

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: typo3temp/var/tests/playwright-reports/
          retention-days: 30
```

## Best Practices

**Do:**
- Use Page Object Model (fixtures) for reusability
- Store authentication state to avoid repeated logins
- Test user-visible behavior, not implementation details
- Use descriptive test names that explain the scenario
- Wait for specific elements, not arbitrary timeouts
- Use `data-testid` attributes for stable selectors
- Run tests in CI with proper environment setup

**Don't:**
- Use `page.waitForTimeout()` - use specific waits instead
- Depend on CSS classes that may change
- Test internal TYPO3 Core behavior
- Ignore flaky tests - fix the root cause
- Use hard-coded credentials in code (use env vars)

## Naming Conventions

- Pattern: `<feature>.spec.ts`
- Examples: `page-module.spec.ts`, `login.spec.ts`
- Location: `Build/tests/playwright/e2e/<category>/`

## Common Pitfalls

**No Waits for Dynamic Content**
```typescript
// Wrong
await page.click('Load More');
await expect(page.locator('.item')).toBeVisible(); // May fail

// Right
await page.click('Load More');
await page.waitForSelector('.item:nth-child(11)');
await expect(page.locator('.item')).toBeVisible();
```

**Brittle Selectors**
```typescript
// Wrong - fragile CSS path
await page.click('div.container > div:nth-child(3) > button');

// Right - stable selector
await page.click('[data-testid="add-to-cart"]');
await page.click('#product-add-button');
```

## E2E Testing for AJAX Endpoints

Backend modules often use AJAX routes for dynamic functionality. Test these endpoints thoroughly:

### Intercepting AJAX Requests

```typescript
// Build/tests/playwright/e2e/backend/ajax-module.spec.ts
import { test, expect } from '../../fixtures/setup-fixtures';

test.describe('AJAX Endpoint Testing', () => {
  test('validates form via AJAX', async ({ page, backend }) => {
    await backend.gotoModule('web_myextension_wizard');

    // Intercept the AJAX validation request
    const validationPromise = page.waitForResponse(
      (response) =>
        response.url().includes('/ajax/myext/wizard/validate') &&
        response.status() === 200
    );

    // Fill form and trigger validation
    await backend.contentFrame.getByLabel('Provider Name').fill('My Provider');
    await backend.contentFrame.getByLabel('API Key').fill('sk-test-123');
    await backend.contentFrame.getByRole('button', { name: 'Next' }).click();

    // Verify AJAX response
    const response = await validationPromise;
    const json = await response.json();
    expect(json.success).toBe(true);
    expect(json.errors).toEqual({});
  });

  test('handles validation errors from AJAX', async ({ page, backend }) => {
    await backend.gotoModule('web_myextension_wizard');

    // Submit without required fields
    await backend.contentFrame.getByRole('button', { name: 'Next' }).click();

    // Wait for error response
    const response = await page.waitForResponse(
      (r) => r.url().includes('/ajax/myext/wizard/validate')
    );
    const json = await response.json();

    expect(json.success).toBe(false);
    expect(json.errors).toHaveProperty('name');

    // Verify error is displayed in UI
    await expect(
      backend.contentFrame.locator('.invalid-feedback')
    ).toBeVisible();
  });
});
```

### Testing Connection/Test Buttons

```typescript
test('tests API connection via AJAX', async ({ page, backend }) => {
  await backend.gotoModule('web_myextension_wizard');

  // Fill connection details
  await backend.contentFrame.getByLabel('API Key').fill('sk-test-123');

  // Mock successful connection response
  await page.route('**/ajax/myext/wizard/test-connection', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        success: true,
        message: 'Connection successful',
        models: [
          { id: 'gpt-4o', name: 'GPT-4o' },
          { id: 'gpt-4o-mini', name: 'GPT-4o Mini' },
        ],
      }),
    });
  });

  // Click test button
  const testButton = backend.contentFrame.getByRole('button', {
    name: 'Test Connection',
  });
  await testButton.click();

  // Verify success notification
  await expect(page.locator('.alert-success')).toBeVisible();

  // Verify models were populated
  const modelSelect = backend.contentFrame.getByLabel('Model');
  await expect(modelSelect.locator('option')).toHaveCount(3); // including empty option
});

test('handles connection failure gracefully', async ({ page, backend }) => {
  await backend.gotoModule('web_myextension_wizard');
  await backend.contentFrame.getByLabel('API Key').fill('invalid-key');

  // Mock failed connection
  await page.route('**/ajax/myext/wizard/test-connection', async (route) => {
    await route.fulfill({
      status: 400,
      contentType: 'application/json',
      body: JSON.stringify({
        success: false,
        message: 'Invalid API key',
      }),
    });
  });

  await backend.contentFrame
    .getByRole('button', { name: 'Test Connection' })
    .click();

  // Verify error notification
  await expect(page.locator('.alert-danger')).toBeVisible();
  await expect(page.locator('.alert-danger')).toContainText('Invalid API key');
});
```

### Testing Multi-Step Wizards

```typescript
test('completes multi-step wizard', async ({ page, backend }) => {
  await backend.gotoModule('web_myextension_wizard');

  // Step 1: Provider
  await backend.contentFrame.getByLabel('Provider Name').fill('OpenAI Prod');
  await backend.contentFrame.getByLabel('API Key').fill('sk-test-key');
  await backend.contentFrame
    .getByRole('button', { name: 'Test Connection' })
    .click();

  // Wait for test to complete
  await page.waitForResponse((r) =>
    r.url().includes('/ajax/myext/wizard/test-connection')
  );
  await backend.contentFrame.getByRole('button', { name: 'Next' }).click();

  // Step 2: Model (verify we advanced)
  await expect(backend.contentFrame.locator('h2')).toContainText('Step 2');
  await backend.contentFrame.getByLabel('Model').selectOption('gpt-4o');
  await backend.contentFrame.getByRole('button', { name: 'Next' }).click();

  // Step 3: Configuration
  await expect(backend.contentFrame.locator('h2')).toContainText('Step 3');
  await backend.contentFrame.getByLabel('Temperature').fill('0.7');
  await backend.contentFrame.getByRole('button', { name: 'Finish' }).click();

  // Verify completion
  const saveResponse = await page.waitForResponse(
    (r) =>
      r.url().includes('/ajax/myext/wizard/save') && r.status() === 200
  );
  const result = await saveResponse.json();
  expect(result.success).toBe(true);

  // Verify redirect or success message
  await expect(backend.contentFrame.locator('.wizard-complete')).toBeVisible();
});
```

### Testing Toggle Actions

```typescript
test('toggles record active state via AJAX', async ({ page, backend }) => {
  await backend.gotoModule('web_myextension');

  // Wait for list to load
  await expect(backend.contentFrame.locator('table tbody tr')).toHaveCount(3);

  // Click toggle button
  const toggleButton = backend.contentFrame
    .locator('tr')
    .first()
    .getByRole('button', { name: 'Toggle' });
  await toggleButton.click();

  // Verify AJAX call succeeded
  const response = await page.waitForResponse(
    (r) =>
      r.url().includes('/ajax/myext/toggle') && r.status() === 200
  );
  const json = await response.json();
  expect(json.success).toBe(true);

  // Verify UI updated
  await expect(toggleButton).toHaveAttribute('data-active', 'false');
});
```

### Network Request Assertions

```typescript
test('sends correct request payload', async ({ page, backend }) => {
  await backend.gotoModule('web_myextension_wizard');

  // Capture the request
  const requestPromise = page.waitForRequest(
    (r) => r.url().includes('/ajax/myext/wizard/validate')
  );

  await backend.contentFrame.getByLabel('Name').fill('Test Provider');
  await backend.contentFrame.getByLabel('Type').selectOption('openai');
  await backend.contentFrame.getByRole('button', { name: 'Validate' }).click();

  const request = await requestPromise;
  const postData = request.postDataJSON();

  expect(postData).toEqual({
    step: 'provider',
    data: {
      name: 'Test Provider',
      type: 'openai',
    },
  });
});
```

### AJAX Timeout and Error Handling

```typescript
test('handles AJAX timeout gracefully', async ({ page, backend }) => {
  await backend.gotoModule('web_myextension_wizard');

  // Simulate slow/timeout response
  await page.route('**/ajax/myext/wizard/test-connection', async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 35000)); // Exceed timeout
    await route.abort('timedout');
  });

  await backend.contentFrame.getByLabel('API Key').fill('sk-test');
  await backend.contentFrame
    .getByRole('button', { name: 'Test Connection' })
    .click();

  // Verify timeout error displayed
  await expect(page.locator('.alert-warning')).toBeVisible({ timeout: 40000 });
  await expect(page.locator('.alert-warning')).toContainText('timed out');
});
```

## Resources

- [Playwright Documentation](https://playwright.dev/docs/intro)
- [TYPO3 Core Playwright Tests](https://github.com/TYPO3/typo3/tree/main/Build/tests/playwright)
- [Playwright Test API](https://playwright.dev/docs/api/class-test)
- [Page Object Model](https://playwright.dev/docs/pom)
- [Playwright Network Mocking](https://playwright.dev/docs/mock)
