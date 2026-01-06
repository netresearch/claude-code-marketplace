/**
 * Playwright Test Fixtures for TYPO3 Backend Testing
 *
 * This file provides reusable fixtures (Page Object Models) for
 * testing TYPO3 backend functionality.
 *
 * Usage:
 *   import { test, expect } from '../fixtures/setup-fixtures';
 *
 *   test('my test', async ({ backend }) => {
 *     await backend.gotoModule('web_layout');
 *   });
 */
import { test as base, type Locator, type Page, expect } from '@playwright/test';

/**
 * Backend Page Object Model
 */
export class BackendPage {
  readonly page: Page;
  readonly moduleMenu: Locator;
  readonly contentFrame: ReturnType<Page['frameLocator']>;

  constructor(page: Page) {
    this.page = page;
    this.moduleMenu = page.locator('#modulemenu');
    this.contentFrame = page.frameLocator('#typo3-contentIframe');
  }

  /**
   * Navigate to a TYPO3 backend module
   */
  async gotoModule(identifier: string): Promise<void> {
    const moduleLink = this.moduleMenu.locator(
      `[data-modulemenu-identifier="${identifier}"]`
    );
    await moduleLink.click();
    await expect(moduleLink).toHaveClass(/modulemenu-action-active/);
  }

  /**
   * Wait for module to finish loading
   */
  async moduleLoaded(): Promise<void> {
    await this.page.evaluate(() => {
      return new Promise<void>((resolve) => {
        document.addEventListener('typo3-module-loaded', () => resolve(), {
          once: true,
        });
      });
    });
  }

  /**
   * Wait for a specific backend response
   */
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

/**
 * Modal Page Object Model
 */
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

/**
 * Fixture type definitions
 */
type BackendFixtures = {
  backend: BackendPage;
  modal: Modal;
};

/**
 * Extended test with TYPO3 backend fixtures
 */
export const test = base.extend<BackendFixtures>({
  backend: async ({ page }, use) => {
    await use(new BackendPage(page));
  },
  modal: async ({ page }, use) => {
    await use(new Modal(page));
  },
});

export { expect, Locator };
