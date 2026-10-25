// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
import { test, expect } from "@playwright/test";
import marketplace from "../../../.claude-plugin/marketplace.json" with { type: "json" };

const prefix = "/claude-code-marketplace";
const visibleCards = page => page.locator(".skill-card:not([hidden])");

for (const lang of ["en", "de"]) {
  test(`global links preserve the selected language on catalog and detail pages (${lang})`, async ({ page }) => {
    const origin = "https://netresearch.github.io";
    const destinations = lang === "de"
      ? ["/de/", "/de/projekte/", "/modularer-ki-stack-page/", `${prefix}/de/`, "/maint/de/"]
      : ["/", "/projects/", "/modularer-ki-stack-page/en/", `${prefix}/en/`, "/maint/"];
    const expected = destinations.map(path => origin + path);
    const contact = `https://www.netresearch.de${lang === "de" ? "/kontakt/" : "/en/contact/"}`;
    for (const suffix of ["", "skills/typo3-conformance/"]) {
      await page.goto(`${prefix}/${lang}/${suffix}`);
      for (const selector of [".nr-shell-desktop", ".nr-shell-menu-panel"]) {
        const links = page.locator(`${selector} .nr-shell-link`);
        expect(await links.evaluateAll(elements => elements.map(link => link.href))).toEqual(expected);
        await expect(links.filter({ hasText: /^Skills$/ })).toHaveAttribute("aria-current", "page");
      }
      await expect(page.locator(".nr-shell-contact")).toHaveAttribute("href", contact);
      await expect(page.locator(".nr-shell-menu-contact")).toHaveAttribute("href", contact);
      await page.setViewportSize({ width: 320, height: 844 });
      await page.locator("[data-nr-mobile-menu] > summary").click();
      await expect(page.locator(".nr-shell-menu-panel .nr-shell-link").filter({ hasText: /^Skills$/ })).toBeVisible();
      expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(320);
    }
  });

  for (const scheme of ["light", "dark"]) {
    test(`fresh narrow landing keeps the enabled hero copy action on screen (${lang}, ${scheme})`, async ({ page }) => {
      await page.setViewportSize({ width: 320, height: 844 });
      await page.emulateMedia({ colorScheme: scheme });
      await page.goto(`${prefix}/${lang}/`, { waitUntil: "networkidle" });
      await page.evaluate(() => document.fonts.ready);
      const copy = page.locator('[data-copy-target="hero-install"]');
      await expect(copy).toBeVisible();
      for (let sample = 0; sample < 3; sample++) {
        const rect = await copy.boundingBox();
        expect(rect.x).toBeGreaterThanOrEqual(0);
        expect(rect.x + rect.width).toBeLessThanOrEqual(320);
        expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(320);
        await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
      }
    });
  }

  test(`reset keeps the complete catalog when a pending search completes (${lang})`, async ({ page }) => {
    let release;
    let reached;
    const hold = new Promise(resolve => { release = resolve; });
    const requested = new Promise(resolve => { reached = resolve; });
    await page.route(`**/${lang}/search-index.json`, async route => {
      reached();
      await hold;
      await route.continue();
    });
    await page.goto(`${prefix}/${lang}/`);
    await page.locator("[data-search-input]").fill("typo3");
    await requested;
    await page.locator("[data-search-clear]").click();
    const response = page.waitForResponse(r => r.url().endsWith(`/${lang}/search-index.json`));
    release();
    await response;
    await page.waitForLoadState("networkidle");
    await expect(page.locator("[data-search-input]")).toHaveValue("");
    await expect(visibleCards(page)).toHaveCount(marketplace.plugins.length);
    await expect(page.locator("[data-search-status]")).toHaveText("");
  });

  test(`unavailable package routes never copy a substitute message (${lang})`, async ({ page }) => {
    await page.addInitScript(() => {
      Object.defineProperty(navigator, "clipboard", { value: { writeText: async text => { window.copiedCommand = text; } } });
    });
    await page.goto(`${prefix}/${lang}/`);
    const card = page.locator(".skill-card").filter({ has: page.locator('a[href$="/skills/cli-tools/"]') });
    const copy = card.locator("[data-copy-active-install]");
    const unavailable = card.locator("p.install--composer-require");
    await expect(unavailable).toBeHidden();
    await page.getByRole("button", { name: /composer require/ }).click();
    await expect(unavailable).toBeVisible();
    await expect(card.locator("code.install--claude-code")).toBeHidden();
    await expect(copy).toBeDisabled();
    await page.getByRole("button", { name: /^composer skills:add/ }).click();
    await expect(unavailable).toBeHidden();
    await expect(card.locator("code.install--composer-skills")).toBeVisible();
    await page.getByRole("button", { name: /^npx / }).click();
    await expect(unavailable).toBeHidden();
    await expect(card.locator("code.install--npx")).toBeVisible();
    await expect(copy).toBeEnabled();
    const label = await copy.getAttribute("aria-label");
    await copy.click();
    await expect.poll(() => page.evaluate(() => window.copiedCommand)).toBe("npx skills add https://github.com/netresearch/coding_agent_cli_toolset");
    await expect(copy).toHaveAttribute("aria-label", label);
    await expect(page.locator("[data-copy-status]")).not.toBeEmpty();
  });

  test(`catalog and native navigation work without JavaScript (${lang})`, async ({ browser }) => {
    const context = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 320, height: 844 } });
    const page = await context.newPage();
    await page.goto(`${test.info().project.use.baseURL || "http://localhost:8081"}${prefix}/${lang}/`);
    await expect(visibleCards(page)).toHaveCount(marketplace.plugins.length);
    await expect(page.locator(".skill-card__unavailable:visible")).toHaveCount(0);
    await expect(page.locator("[data-enhance-only]:visible")).toHaveCount(0);
    await page.locator("[data-nr-mobile-menu] > summary").click();
    await expect(page.locator("[data-nr-mobile-menu]")).toHaveAttribute("open", "");
    await expect(page.locator("[data-nr-mobile-menu] nav")).toBeVisible();
    await expect(page.locator(".nr-shell-menu-panel .nr-shell-link").filter({ hasText: /^Skills$/ })).toHaveAttribute("href", `https://netresearch.github.io${prefix}/${lang}/`);
    const width = await page.evaluate(() => ({ viewport: innerWidth, document: document.documentElement.scrollWidth }));
    expect(width.document).toBeLessThanOrEqual(width.viewport);
    await context.close();
  });

  test(`reduced motion removes component transitions and preserves the visible skip link (${lang})`, async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.goto(`${prefix}/${lang}/`, { waitUntil: "networkidle" });
    await page.evaluate(() => document.fonts.ready);
    await expect(page.locator("html")).toHaveCSS("scroll-behavior", "auto");
    const moving = await page.locator("body *").evaluateAll(elements => elements.filter(element => {
      const style = getComputedStyle(element);
      return style.transitionDuration.split(",").some(value => Number.parseFloat(value) > 0)
        || (style.animationName !== "none" && style.animationDuration.split(",").some(value => Number.parseFloat(value) > 0));
    }).map(element => element.className));
    expect(moving).toEqual([]);
    await page.keyboard.press("Tab");
    const skip = page.locator(".skip-link");
    await expect(skip).toBeFocused();
    await expect(skip).toHaveCSS("transition-duration", "0s");
    const rect = await skip.boundingBox();
    expect(rect.y).toBeGreaterThanOrEqual(0);
    await page.locator(".nr-hero .copy-btn").hover();
    await expect(page.locator(".nr-hero .copy-btn")).toHaveCSS("transition-duration", "0s");
  });
}

test("theme choice changes page colors, survives a locale change and follows the system", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await page.goto(`${prefix}/en/skills/typo3-conformance/`);
  await page.locator("[data-nr-theme-picker] > summary").click();
  await page.getByRole("radio", { name: "Dark", exact: true }).check();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await expect(page.locator("body")).toHaveCSS("background-color", "rgb(26, 26, 26)");
  await page.getByRole("link", { name: "DE – Deutsch", exact: true }).click();
  await expect(page).toHaveURL(new RegExp(`${prefix}/de/skills/typo3-conformance/$`));
  await expect(page.locator("html")).toHaveAttribute("data-theme-preference", "dark");
  await page.locator("[data-nr-theme-picker] > summary").click();
  await page.getByRole("radio", { name: "System", exact: true }).check();
  await expect(page.locator("body")).toHaveCSS("background-color", "rgb(255, 255, 255)");
  await page.emulateMedia({ colorScheme: "dark" });
  await expect(page.locator("body")).toHaveCSS("background-color", "rgb(26, 26, 26)");
});

test("an unavailable search index preserves the visible catalog and explains the error", async ({ page }) => {
  await page.route("**/en/search-index.json", route => route.abort());
  await page.goto(`${prefix}/en/`);
  await page.locator("[data-search-input]").fill("typo3");
  const expected = await page.locator("[data-search]").getAttribute("data-search-error");
  expect(expected).toBeTruthy();
  await expect(page.locator("[data-search-status]")).toHaveText(expected);
  await expect(visibleCards(page)).toHaveCount(marketplace.plugins.length);
});

test("dark CTA hover and keyboard focus retain contrast and a visible solid outline", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "dark" });
  await page.goto(`${prefix}/en/`);
  const cta = page.locator(".cta-links a").first();
  await cta.hover();
  const ratio = await cta.evaluate(element => {
    const luminance = value => {
      const channels = value.match(/[\d.]+/g).slice(0, 3).map(n => Number(n) / 255)
        .map(n => n <= 0.04045 ? n / 12.92 : ((n + 0.055) / 1.055) ** 2.4);
      return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
    };
    const style = getComputedStyle(element);
    const values = [luminance(style.color), luminance(style.backgroundColor)].sort((a, b) => b - a);
    return (values[0] + 0.05) / (values[1] + 0.05);
  });
  expect(ratio).toBeGreaterThanOrEqual(7);
  await page.keyboard.press("Tab");
  for (const control of [page.locator('[data-install-mode-id="npx"]'), page.locator("[data-search-input]")]) {
    await control.focus();
    await expect(control).toHaveCSS("outline-style", "solid");
    expect(Number.parseFloat(await control.evaluate(element => getComputedStyle(element).outlineWidth))).toBeGreaterThanOrEqual(3);
  }
});
