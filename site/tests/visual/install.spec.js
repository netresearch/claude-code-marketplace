import { test, expect } from "@playwright/test";
import overrides from "../../src/_data/installOverrides.json" with { type: "json" };

for (const language of ["en", "de"]) {
  test(`PHP engine install command survives card copy (${language})`, async ({ page }) => {
    // Capture this page's own copy request without reading the system clipboard.
    await page.addInitScript(() => {
      Object.defineProperty(navigator, "clipboard", {
        value: { writeText: async (text) => { window.installCommandCopied = text; } },
      });
    });
    await page.goto(`/claude-code-marketplace/${language}/`);
    await page.getByRole("tab", { name: /composer require/ }).click();
    const card = page.locator(".skill-card").filter({
      has: page.getByRole("link", { name: "PHP Structured Edit", exact: true }),
    });
    await card.locator(".copy-btn").click();
    const install = overrides["php-structured-edit"];
    await expect.poll(() => page.evaluate(() => window.installCommandCopied))
      .toBe(install.methods["composer-require"].command);

    await card.getByRole("link", { name: install.linkLabel[language] }).click();
    const hint = install.methods["composer-require"].hint[language];
    await expect(page.locator(".install-methods__hint").filter({ hasText: hint.text })).toBeVisible();
    await expect(page.locator("#skill-install-composer-require"))
      .toHaveText(install.methods["composer-require"].command);
  });
}
