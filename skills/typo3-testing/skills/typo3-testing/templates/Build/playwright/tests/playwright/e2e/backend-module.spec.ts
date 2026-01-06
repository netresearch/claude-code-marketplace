/**
 * Example E2E Test for TYPO3 Backend Module
 *
 * Replace 'my_extension' with your extension key and
 * customize the tests for your module's functionality.
 */
import { test, expect } from '../fixtures/setup-fixtures';

test.describe('My Extension Backend Module', () => {
  test('can access module', async ({ backend }) => {
    // Navigate to your extension's module
    // Replace 'web_myextension' with your module identifier
    await backend.gotoModule('web_myextension');
    await backend.moduleLoaded();

    // Verify module content is visible
    const contentFrame = backend.contentFrame;
    await expect(contentFrame.locator('h1')).toBeVisible();
  });

  test('can perform action in module', async ({ backend, modal }) => {
    await backend.gotoModule('web_myextension');

    // Example: Click a button that opens a modal
    await backend.contentFrame
      .getByRole('button', { name: 'Create new record' })
      .click();

    // Verify modal appears
    await expect(modal.container).toBeVisible();
    await expect(modal.title).toContainText('Create');

    // Close modal
    await modal.close();
  });

  test('can save form data', async ({ backend }) => {
    await backend.gotoModule('web_myextension');

    const contentFrame = backend.contentFrame;

    // Fill form fields
    await contentFrame.getByLabel('Title').fill('Test Title');
    await contentFrame.getByLabel('Description').fill('Test Description');

    // Save the form
    await contentFrame.getByRole('button', { name: 'Save' }).click();

    // Wait for save response
    await backend.waitForModuleResponse(/module\/web\/myextension/);

    // Verify success message
    await expect(contentFrame.locator('.alert-success')).toBeVisible();
  });
});
