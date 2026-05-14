import { defineConfig, devices } from "@playwright/test";

/**
 * Visual regression for the built _site/ tree.
 *
 * Run order:
 *   1. `npm run build:all` (or the CI's prebuild chain) — produces _site/
 *   2. `npm run test:visual` — boots a static server against _site/ and runs the specs
 *
 * Snapshots live next to the specs in `tests/visual/<spec>.spec.js-snapshots/`.
 * Update them locally with `npm run test:visual -- --update-snapshots`.
 */
export default defineConfig({
  testDir: "./tests/visual",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: process.env.CI ? [["line"], ["html", { open: "never" }]] : "list",
  use: {
    baseURL: "http://localhost:8081",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  // Lock down screenshot dimensions + reduce moving parts (animations off,
  // fonts forced to system stack via prefers-reduced-motion in the page).
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.005,
      animations: "disabled",
    },
  },
  projects: [
    {
      name: "chromium-desktop",
      use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 800 } },
    },
  ],
  webServer: {
    // Build a temporary mirror that mounts _site at /claude-code-marketplace/
    // (the live deploy path) so the same URLs work locally as in production.
    // The mirror is rebuilt on every test run from the latest _site/.
    command:
      "rm -rf .visual-site && mkdir -p .visual-site && cp -r _site .visual-site/claude-code-marketplace && http-server .visual-site -p 8081 -c-1 --silent",
    url: "http://localhost:8081/claude-code-marketplace/en/",
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
});
