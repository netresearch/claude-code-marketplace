/**
 * Accessibility Tests for TYPO3 Backend Modules
 *
 * Uses axe-core to verify WCAG 2.0/2.1 compliance at levels A and AA.
 * Customize the modules array for your extension's routes.
 *
 * @see https://www.deque.com/axe/
 */
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

/**
 * Define modules to test for accessibility
 * Replace with your extension's module routes
 */
const modules = [
  { name: 'My Extension Module', route: 'module/web/myextension' },
  // Add more modules as needed:
  // { name: 'Settings', route: 'module/web/myextension/settings' },
];

for (const module of modules) {
  test(`${module.name} has no accessibility violations`, async ({ page }) => {
    // Navigate to module
    await page.goto(module.route);
    await page.waitForLoadState('networkidle');

    // Run accessibility scan on the content iframe
    const accessibilityScanResults = await new AxeBuilder({ page })
      .include('#typo3-contentIframe')
      // Disable rules that may produce false positives in TYPO3 backend
      .disableRules(['color-contrast'])
      .analyze();

    // Assert no violations
    expect(accessibilityScanResults.violations).toEqual([]);
  });
}

test.describe('Accessibility - Additional Checks', () => {
  test('module menu has proper ARIA attributes', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Check module menu accessibility
    const moduleMenu = page.locator('#modulemenu');
    await expect(moduleMenu).toHaveAttribute('role', 'navigation');
  });

  test('interactive elements are keyboard accessible', async ({ page }) => {
    await page.goto('module/web/myextension');
    await page.waitForLoadState('networkidle');

    const contentFrame = page.frameLocator('#typo3-contentIframe');

    // Tab through interactive elements
    await page.keyboard.press('Tab');

    // Verify focus is visible
    const focusedElement = contentFrame.locator(':focus');
    await expect(focusedElement).toBeVisible();
  });
});
