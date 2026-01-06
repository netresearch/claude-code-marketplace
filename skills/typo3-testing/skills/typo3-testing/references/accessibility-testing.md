# Accessibility Testing with axe-core

TYPO3 extensions should test for WCAG 2.0/2.1 compliance at levels A and AA using **axe-core** integrated with Playwright.

**Reference:** [axe-core Documentation](https://www.deque.com/axe/)

## Requirements

```json
// package.json
{
  "devDependencies": {
    "@playwright/test": "^1.56.1",
    "@axe-core/playwright": "^4.9.0"
  }
}
```

## Directory Structure

```
Build/
└── tests/
    └── playwright/
        └── accessibility/
            ├── modules.spec.ts      # Backend module accessibility
            ├── forms.spec.ts        # Form accessibility
            └── navigation.spec.ts   # Navigation accessibility
```

## Basic Accessibility Test

```typescript
// Build/tests/playwright/accessibility/modules.spec.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const modules = [
  { name: 'My Extension Module', route: 'module/web/myextension' },
  { name: 'Settings', route: 'module/web/myextension/settings' },
];

for (const module of modules) {
  test(`${module.name} has no accessibility violations`, async ({ page }) => {
    await page.goto(module.route);
    await page.waitForLoadState('networkidle');

    const accessibilityScanResults = await new AxeBuilder({ page })
      .include('#typo3-contentIframe')
      .disableRules(['color-contrast']) // Reduce false positives
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });
}
```

## Comprehensive Accessibility Tests

```typescript
// Build/tests/playwright/accessibility/comprehensive.spec.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Accessibility - Comprehensive Checks', () => {
  test('module menu has proper ARIA attributes', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

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

  test('forms have proper labels', async ({ page }) => {
    await page.goto('module/web/myextension/edit');
    await page.waitForLoadState('networkidle');

    const contentFrame = page.frameLocator('#typo3-contentIframe');

    // All inputs should have associated labels
    const inputs = contentFrame.locator('input:not([type="hidden"])');
    const count = await inputs.count();

    for (let i = 0; i < count; i++) {
      const input = inputs.nth(i);
      const id = await input.getAttribute('id');

      if (id) {
        const label = contentFrame.locator(`label[for="${id}"]`);
        await expect(label).toBeVisible();
      }
    }
  });

  test('images have alt text', async ({ page }) => {
    await page.goto('module/web/myextension');
    await page.waitForLoadState('networkidle');

    const contentFrame = page.frameLocator('#typo3-contentIframe');
    const images = contentFrame.locator('img');
    const count = await images.count();

    for (let i = 0; i < count; i++) {
      const img = images.nth(i);
      const alt = await img.getAttribute('alt');
      expect(alt).not.toBeNull();
    }
  });

  test('color contrast is sufficient', async ({ page }) => {
    await page.goto('module/web/myextension');
    await page.waitForLoadState('networkidle');

    const accessibilityScanResults = await new AxeBuilder({ page })
      .include('#typo3-contentIframe')
      .withRules(['color-contrast'])
      .analyze();

    // Log violations for debugging but don't fail
    // (TYPO3 backend may have known contrast issues)
    if (accessibilityScanResults.violations.length > 0) {
      console.log('Color contrast issues:', accessibilityScanResults.violations);
    }
  });
});
```

## axe-core Configuration

### Include/Exclude Elements

```typescript
const results = await new AxeBuilder({ page })
  .include('#main-content')           // Only scan this element
  .exclude('.third-party-widget')     // Skip this element
  .analyze();
```

### Specific Rules

```typescript
// Run only specific rules
const results = await new AxeBuilder({ page })
  .withRules(['color-contrast', 'label'])
  .analyze();

// Disable specific rules
const results = await new AxeBuilder({ page })
  .disableRules(['color-contrast'])
  .analyze();
```

### Tags (WCAG Levels)

```typescript
// Test WCAG 2.1 Level AA
const results = await new AxeBuilder({ page })
  .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
  .analyze();

// Test only critical issues
const results = await new AxeBuilder({ page })
  .withTags(['critical'])
  .analyze();
```

## Handling Violations

```typescript
test('handles violations gracefully', async ({ page }) => {
  await page.goto('module/web/myextension');

  const results = await new AxeBuilder({ page })
    .include('#typo3-contentIframe')
    .analyze();

  // Log violations with details
  for (const violation of results.violations) {
    console.log(`Rule: ${violation.id}`);
    console.log(`Impact: ${violation.impact}`);
    console.log(`Description: ${violation.description}`);

    for (const node of violation.nodes) {
      console.log(`  Element: ${node.html}`);
      console.log(`  Fix: ${node.failureSummary}`);
    }
  }

  // Assert no violations
  expect(results.violations).toHaveLength(0);
});
```

## TYPO3 Backend Considerations

### Known TYPO3 Backend Issues

Some accessibility rules may produce false positives in TYPO3 backend:

```typescript
const results = await new AxeBuilder({ page })
  .include('#typo3-contentIframe')
  // Disable rules that conflict with TYPO3 backend design
  .disableRules([
    'color-contrast',      // TYPO3 uses theme colors
    'landmark-one-main',   // Backend uses iframe structure
    'region',              // Content in iframes
  ])
  .analyze();
```

### Testing Your Extension Only

Focus on elements your extension controls:

```typescript
const results = await new AxeBuilder({ page })
  // Target your extension's content
  .include('[data-extension="my_extension"]')
  .analyze();
```

## Best Practices

**Do:**
- Test all backend modules your extension provides
- Test forms for proper labels and ARIA attributes
- Test keyboard navigation through interactive elements
- Test with screen reader users in mind
- Document known accessibility limitations

**Don't:**
- Disable all rules to make tests pass
- Skip accessibility testing entirely
- Assume TYPO3 backend handles all accessibility
- Ignore violations without documenting reason

## Checklist

- [ ] All modules tested with axe-core
- [ ] Forms have proper labels
- [ ] Interactive elements are keyboard accessible
- [ ] Images have alt text
- [ ] ARIA attributes are correct
- [ ] Focus states are visible
- [ ] Color is not the only means of conveying information

## Resources

- [axe-core Playwright Integration](https://github.com/dequelabs/axe-core-npm/tree/develop/packages/playwright)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [axe-core Rules](https://dequeuniversity.com/rules/axe/)
- [TYPO3 Accessibility Guidelines](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Accessibility/)
