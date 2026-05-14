import { test, expect } from "@playwright/test";

const PAGES = [
  { name: "landing-en", path: "/claude-code-marketplace/en/" },
  { name: "landing-de", path: "/claude-code-marketplace/de/" },
  { name: "detail-en-typo3-conformance", path: "/claude-code-marketplace/en/skills/typo3-conformance/" },
  { name: "detail-de-typo3-conformance", path: "/claude-code-marketplace/de/skills/typo3-conformance/" },
  { name: "detail-en-orocommerce", path: "/claude-code-marketplace/en/skills/orocommerce/" },
];

for (const { name, path } of PAGES) {
  test(`visual: ${name}`, async ({ page }) => {
    await page.goto(path, { waitUntil: "networkidle" });
    // The dynamic version-published-date inside the release badge will drift
    // every time a skill repo cuts a release. Mask it from the diff so the
    // gate doesn't flap on unrelated upstream activity.
    await expect(page).toHaveScreenshot(`${name}.png`, {
      fullPage: true,
      mask: [page.locator(".skill-detail__version time")],
    });
  });
}
