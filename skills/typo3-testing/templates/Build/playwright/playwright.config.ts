/**
 * Playwright E2E Test Configuration for TYPO3 Extensions
 *
 * Based on TYPO3 Core configuration:
 * @see https://github.com/TYPO3/typo3/blob/main/Build/playwright.config.ts
 */
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
