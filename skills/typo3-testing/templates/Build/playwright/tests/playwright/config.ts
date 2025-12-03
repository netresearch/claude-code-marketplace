/**
 * TYPO3-specific Playwright configuration
 *
 * Environment variables:
 * - PLAYWRIGHT_BASE_URL: Base URL for the TYPO3 backend (default: http://web:80/typo3/)
 * - PLAYWRIGHT_ADMIN_USERNAME: Admin username (default: admin)
 * - PLAYWRIGHT_ADMIN_PASSWORD: Admin password (default: password)
 */
export default {
  // Base URL with trailing slash for relative navigation
  // Example: page.goto('module/web/layout') navigates to {baseUrl}module/web/layout
  baseUrl: process.env.PLAYWRIGHT_BASE_URL ?? 'http://web:80/typo3/',

  // Backend admin credentials
  admin: {
    username: process.env.PLAYWRIGHT_ADMIN_USERNAME ?? 'admin',
    password: process.env.PLAYWRIGHT_ADMIN_PASSWORD ?? 'password',
  },
};
