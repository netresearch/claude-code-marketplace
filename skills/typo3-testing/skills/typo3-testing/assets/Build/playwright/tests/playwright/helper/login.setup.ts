/**
 * TYPO3 Backend Login Setup
 *
 * This setup file authenticates with the TYPO3 backend and stores
 * the session state for reuse across all tests.
 *
 * @see https://playwright.dev/docs/auth
 */
import { test as setup, expect } from '@playwright/test';
import config from '../config';

setup('login', async ({ page }) => {
  // Navigate to TYPO3 backend login
  await page.goto('/');

  // Fill login form using accessibility labels
  await page.getByLabel('Username').fill(config.admin.username);
  await page.getByLabel('Password').fill(config.admin.password);

  // Submit login
  await page.getByRole('button', { name: 'Login' }).click();

  // Wait for backend to load
  await page.waitForLoadState('networkidle');

  // Verify login succeeded by checking for module menu
  await expect(page.locator('.t3js-topbar-button-modulemenu')).toBeVisible();

  // Save authentication state for reuse
  await page.context().storageState({ path: './.auth/login.json' });
});
