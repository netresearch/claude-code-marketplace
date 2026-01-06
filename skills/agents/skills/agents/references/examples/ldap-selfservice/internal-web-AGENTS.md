# Frontend - TypeScript & Tailwind CSS

<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: 2025-10-09 -->

**Scope**: Frontend assets in `internal/web/` directory - TypeScript, Tailwind CSS, HTML templates

**See also**: [../../AGENTS.md](../../AGENTS.md) for global standards, [../AGENTS.md](../AGENTS.md) for Go backend

## Overview

Frontend implementation for LDAP selfservice password changer with strict accessibility compliance:

- **static/**: Client-side TypeScript, compiled CSS, static assets
  - **js/**: TypeScript source files (compiled to ES modules)
  - **styles.css**: Tailwind CSS output
  - Icons, logos, favicons, manifest
- **templates/**: Go HTML templates (\*.gohtml)
- **handlers.go**: HTTP route handlers
- **middleware.go**: Security headers, CORS, etc.
- **server.go**: Fiber server setup

**Key characteristics**:

- **WCAG 2.2 AAA**: 7:1 contrast, keyboard navigation, screen reader support, adaptive density
- **Ultra-strict TypeScript**: All strict flags enabled, no `any` types
- **Tailwind CSS 4**: Utility-first, dark mode, responsive, accessible patterns
- **Progressive enhancement**: Works without JavaScript (forms submit via HTTP)
- **Password manager friendly**: Proper autocomplete attributes

## Setup/Environment

**Prerequisites**: Node.js 24+, pnpm 10.18+ (from root `package.json`)

```bash
# From project root
pnpm install          # Install dependencies

# Development (watch mode)
pnpm css:dev          # Tailwind CSS watch
pnpm js:dev           # TypeScript watch
# OR
pnpm dev              # Concurrent: CSS + TS + Go hot-reload
```

**No .env needed for frontend** - all config comes from Go backend

**Browser targets**: Modern browsers with ES module support (Chrome 90+, Firefox 88+, Safari 14+, Edge 90+)

## Build & Tests

```bash
# Build frontend assets
pnpm build:assets     # TypeScript + CSS (production builds)

# TypeScript
pnpm js:build         # Compile TS → ES modules + minify
pnpm js:dev           # Watch mode with preserveWatchOutput
tsc --noEmit          # Type check only (no output)

# CSS
pnpm css:build        # Tailwind + PostCSS → styles.css
pnpm css:dev          # Watch mode

# Formatting
pnpm prettier --write internal/web/    # Format TS, CSS, HTML templates
pnpm prettier --check internal/web/    # Check formatting (CI)
```

**No unit tests yet** - TypeScript strict mode catches most errors, integration via Go tests

**CI validation** (from `.github/workflows/check.yml`):

```bash
pnpm install
pnpm js:build         # TypeScript strict compilation
pnpm prettier --check .
```

**Accessibility testing**:

- Keyboard navigation: Tab through all interactive elements
- Screen reader: Test with VoiceOver (macOS/iOS) or NVDA (Windows)
- Contrast: Verify 7:1 ratios with browser dev tools
- See [../../docs/accessibility.md](../../docs/accessibility.md) for comprehensive guide

## Code Style

**TypeScript Ultra-Strict** (from `tsconfig.json`):

```json
{
  "strict": true,
  "noUncheckedIndexedAccess": true,
  "exactOptionalPropertyTypes": true,
  "noPropertyAccessFromIndexSignature": true,
  "noImplicitReturns": true,
  "noFallthroughCasesInSwitch": true,
  "noUnusedLocals": true,
  "noUnusedParameters": true
}
```

**No `any` types allowed**:

```typescript
// ✅ Good: explicit types
function validatePassword(password: string, minLength: number): boolean {
  return password.length >= minLength;
}

// ❌ Bad: any type
function validatePassword(password: any): boolean {
  return password.length >= 8; // ❌ unsafe
}
```

**Prettier formatting**:

- 120 char width
- 2-space indentation
- Semicolons required
- Double quotes (not single)
- Trailing comma: none

**File organization**:

- TypeScript source: `static/js/*.ts`
- Output: `static/js/*.js` (minified ES modules)
- CSS input: `tailwind.css` (Tailwind directives)
- CSS output: `static/styles.css` (PostCSS processed)

## Accessibility Standards (WCAG 2.2 AAA)

**Required compliance** - not optional:

### Keyboard Navigation

- All interactive elements focusable with Tab
- Visual focus indicators (4px outline, 7:1 contrast)
- Logical tab order (top to bottom, left to right)
- No keyboard traps
- Skip links where needed

### Screen Readers

- Semantic HTML: `<button>`, `<input>`, `<label>`, not `<div onclick>`
- ARIA labels on icon-only buttons: `aria-label="Submit"`
- Error messages: `aria-describedby` linking to error text
- Live regions for dynamic content: `aria-live="polite"`
- Form field associations: `<label for="id">` + `<input id="id">`

### Color & Contrast

- Text: 7:1 contrast ratio (AAA)
- Large text (18pt+): 4.5:1 minimum
- Focus indicators: 3:1 against adjacent colors
- Dark mode: same contrast requirements
- Never rely on color alone (use icons, text, patterns)

### Responsive & Adaptive

- Responsive: layout adapts to viewport size
- Text zoom: 200% without horizontal scroll
- Adaptive density: spacing adjusts for user preferences
- Touch targets: 44×44 CSS pixels minimum (mobile)

### Examples

**✅ Good: Accessible button**

```html
<button type="submit" class="btn-primary focus:ring-4 focus:ring-blue-300" aria-label="Submit password change">
  <svg aria-hidden="true">...</svg>
  Change Password
</button>
```

**❌ Bad: Inaccessible div-button**

```html
<div onclick="submit()" class="button">❌ not keyboard accessible Submit</div>
```

**✅ Good: Form with error handling**

```html
<form>
  <label for="password">New Password</label>
  <input
    id="password"
    type="password"
    aria-describedby="password-error"
    aria-invalid="true"
    autocomplete="new-password"
  />
  <div id="password-error" role="alert">Password must be at least 8 characters</div>
</form>
```

**❌ Bad: Form without associations**

```html
<form>
  <div>Password</div>
  ❌ not a label, no association <input type="password" /> ❌ no autocomplete, no error linkage
  <div style="color: red">Error</div>
  ❌ no role="alert", only color
</form>
```

## Tailwind CSS Patterns

**Use utility classes**, not custom CSS:

**✅ Good: Utility classes**

```html
<button
  class="rounded-lg bg-blue-600 px-4 py-2 font-semibold text-white hover:bg-blue-700 focus:ring-4 focus:ring-blue-300"
>
  Submit
</button>
```

**❌ Bad: Custom CSS**

```html
<button class="custom-button">Submit</button>
<style>
  .custom-button {
    background: blue;
  } /* ❌ Use Tailwind utilities */
</style>
```

**Dark mode support**:

```html
<div class="bg-white text-gray-900 dark:bg-gray-900 dark:text-gray-100">Content</div>
```

**Responsive design**:

```html
<div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
  <!-- Responsive grid: 1 col mobile, 2 tablet, 3 desktop -->
</div>
```

**Focus states (required)**:

```html
<button class="focus:ring-4 focus:ring-blue-300 focus:outline-none">
  <!-- 4px focus ring, 7:1 contrast -->
</button>
```

## TypeScript Patterns

**Strict null checking**:

```typescript
// ✅ Good: handle nulls explicitly
function getElement(id: string): HTMLElement | null {
  return document.getElementById(id);
}

const el = getElement("password");
if (el) {
  // ✅ null check
  el.textContent = "Hello";
}

// ❌ Bad: assume non-null
const el = getElement("password");
el.textContent = "Hello"; // ❌ may crash if null
```

**Type guards**:

```typescript
// ✅ Good: type guard for forms
function isHTMLFormElement(element: Element): element is HTMLFormElement {
  return element instanceof HTMLFormElement;
}

const form = document.querySelector("form");
if (form && isHTMLFormElement(form)) {
  form.addEventListener("submit", handleSubmit);
}
```

**No unsafe array access**:

```typescript
// ✅ Good: check array bounds
const items = ["a", "b", "c"];
const first = items[0]; // string | undefined (noUncheckedIndexedAccess)
if (first) {
  console.log(first.toUpperCase());
}

// ❌ Bad: unsafe access
console.log(items[0].toUpperCase()); // ❌ may crash if empty array
```

## PR/Commit Checklist

**Before committing frontend code**:

- [ ] Run `pnpm js:build` (TypeScript strict check)
- [ ] Run `pnpm prettier --write internal/web/`
- [ ] Verify keyboard navigation works
- [ ] Test with screen reader (VoiceOver/NVDA)
- [ ] Check contrast ratios (7:1 for text)
- [ ] Test dark mode
- [ ] Verify password manager autofill works
- [ ] No console errors in browser
- [ ] Test on mobile viewport (responsive)

**Accessibility checklist**:

- [ ] All interactive elements keyboard accessible
- [ ] Focus indicators visible (4px outline, 7:1 contrast)
- [ ] ARIA labels on icon-only buttons
- [ ] Form fields properly labeled
- [ ] Error messages linked with aria-describedby
- [ ] No color-only information conveyance
- [ ] Touch targets ≥44×44 CSS pixels (mobile)

**Performance checklist**:

- [ ] Minified JS (via `pnpm js:minify`)
- [ ] CSS optimized (cssnano via PostCSS)
- [ ] No unused Tailwind classes (purged automatically)
- [ ] No console.log in production code

## Good vs Bad Examples

**✅ Good: Type-safe DOM access**

```typescript
function setupPasswordToggle(): void {
  const toggle = document.getElementById("toggle-password");
  const input = document.getElementById("password");

  if (!toggle || !(input instanceof HTMLInputElement)) {
    return; // Guard against missing elements
  }

  toggle.addEventListener("click", () => {
    input.type = input.type === "password" ? "text" : "password";
  });
}
```

**❌ Bad: Unsafe DOM access**

```typescript
function setupPasswordToggle() {
  const toggle = document.getElementById("toggle-password")!; // ❌ non-null assertion
  const input = document.getElementById("password") as any; // ❌ any type

  toggle.addEventListener("click", () => {
    input.type = input.type === "password" ? "text" : "password"; // ❌ may crash
  });
}
```

**✅ Good: Accessible form validation**

```typescript
function showError(input: HTMLInputElement, message: string): void {
  const errorId = `${input.id}-error`;
  let errorEl = document.getElementById(errorId);

  if (!errorEl) {
    errorEl = document.createElement("div");
    errorEl.id = errorId;
    errorEl.setAttribute("role", "alert");
    errorEl.className = "text-red-600 dark:text-red-400 text-sm mt-1";
    input.parentElement?.appendChild(errorEl);
  }

  errorEl.textContent = message;
  input.setAttribute("aria-invalid", "true");
  input.setAttribute("aria-describedby", errorId);
}
```

**❌ Bad: Inaccessible validation**

```typescript
function showError(input: any, message: string) {
  // ❌ any type
  input.style.borderColor = "red"; // ❌ color only, no text
  alert(message); // ❌ blocks UI, not persistent
}
```

## When Stuck

**TypeScript issues**:

1. **Type errors**: Check `tsconfig.json` flags, use proper types (no `any`)
2. **Null errors**: Add null checks or type guards
3. **Module errors**: Ensure ES module syntax (`import`/`export`)
4. **Build errors**: `pnpm install` to refresh dependencies

**CSS issues**:

1. **Styles not applying**: Check Tailwind purge config, rebuild with `pnpm css:build`
2. **Dark mode broken**: Use `dark:` prefix on utilities
3. **Responsive broken**: Use `md:`, `lg:` breakpoint prefixes
4. **Custom classes**: Don't - use Tailwind utilities instead

**Accessibility issues**:

1. **Keyboard nav broken**: Check tab order, focus indicators
2. **Screen reader confusion**: Verify ARIA labels, semantic HTML
3. **Contrast failure**: Use darker colors, test with dev tools
4. **See**: [../../docs/accessibility.md](../../docs/accessibility.md)

**Browser dev tools**:

- Accessibility tab: Check ARIA, contrast, structure
- Lighthouse: Run accessibility audit (aim for 100 score)
- Console: No errors in production code

## Testing Workflow

**Manual testing required** (no automated frontend tests yet):

1. **Visual testing**: Check all pages in light/dark mode
2. **Keyboard testing**: Tab through all interactive elements
3. **Screen reader testing**: Use VoiceOver (Cmd+F5) or NVDA
4. **Responsive testing**: Test mobile, tablet, desktop viewports
5. **Browser testing**: Chrome, Firefox, Safari, Edge
6. **Password manager**: Test autofill with 1Password, LastPass, etc.

**Accessibility testing tools**:

- Browser dev tools Lighthouse
- axe DevTools extension
- WAVE browser extension
- Manual keyboard/screen reader testing (required)

**Integration testing**: Go backend tests exercise full request/response flow including frontend templates
