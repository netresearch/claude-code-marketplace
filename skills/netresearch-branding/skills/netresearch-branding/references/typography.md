# Netresearch Typography Reference

Complete typography system with font specifications, hierarchy, and implementation guidelines.

## Font Family Overview

| Context | Typeface | Purpose |
|---------|----------|---------|
| Web Headlines | **Raleway** | Digital headers, navigation, buttons |
| Web Body Text | **Open Sans** | Digital body copy, captions, lists |
| Documents | **Calibri** | Word, PowerPoint, Excel, email |
| Print | **Raleway + Open Sans** | Brochures, flyers, business cards |

---

## Raleway (Headlines & Display)

### Font Specifications

**Family:** Raleway
**Designer:** Matt McInerney, Pablo Impallari, Rodrigo Fuenzalida
**License:** Open Font License (free for commercial use)
**Classification:** Sans-serif, Geometric

**Recommended Weights for Netresearch:**
- **Regular (400)** - Secondary headlines, navigation
- **Semi-Bold (600)** - Buttons, emphasized text
- **Bold (700)** - Primary headlines, h1-h2

### Web Font Loading

**Google Fonts CDN:**
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Raleway:wght@400;600;700&display=swap" rel="stylesheet">
```

**CSS @import:**
```css
@import url('https://fonts.googleapis.com/css2?family=Raleway:wght@400;600;700&display=swap');
```

**Self-Hosted (Recommended for Performance):**
```css
@font-face {
  font-family: 'Raleway';
  font-style: normal;
  font-weight: 400;
  font-display: swap;
  src: url('/fonts/raleway-regular.woff2') format('woff2'),
       url('/fonts/raleway-regular.woff') format('woff');
}

@font-face {
  font-family: 'Raleway';
  font-style: normal;
  font-weight: 600;
  font-display: swap;
  src: url('/fonts/raleway-semibold.woff2') format('woff2'),
       url('/fonts/raleway-semibold.woff') format('woff');
}

@font-face {
  font-family: 'Raleway';
  font-style: normal;
  font-weight: 700;
  font-display: swap;
  src: url('/fonts/raleway-bold.woff2') format('woff2'),
       url('/fonts/raleway-bold.woff') format('woff');
}
```

### Usage Guidelines

**Use Raleway For:**
- ✅ Page headlines (h1, h2, h3)
- ✅ Navigation menu items
- ✅ Button labels
- ✅ Section headers
- ✅ Pull quotes and callouts
- ✅ Hero text and taglines

**Do Not Use Raleway For:**
- ❌ Body paragraphs (use Open Sans)
- ❌ Long-form content (readability issues)
- ❌ Small text below 14px (legibility)
- ❌ Dense information tables

---

## Open Sans (Body Text)

### Font Specifications

**Family:** Open Sans
**Designer:** Steve Matteson
**License:** Apache License 2.0 (free for commercial use)
**Classification:** Sans-serif, Humanist

**Recommended Weights for Netresearch:**
- **Regular (400)** - Body text, lists, captions
- **Semi-Bold (600)** - Emphasized body text, labels
- **Bold (700)** - Strong emphasis, sub-headers

### Web Font Loading

**Google Fonts CDN:**
```html
<link href="https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;600;700&display=swap" rel="stylesheet">
```

**CSS @import:**
```css
@import url('https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;600;700&display=swap');
```

**Self-Hosted:**
```css
@font-face {
  font-family: 'Open Sans';
  font-style: normal;
  font-weight: 400;
  font-display: swap;
  src: url('/fonts/opensans-regular.woff2') format('woff2'),
       url('/fonts/opensans-regular.woff') format('woff');
}

@font-face {
  font-family: 'Open Sans';
  font-style: normal;
  font-weight: 600;
  font-display: swap;
  src: url('/fonts/opensans-semibold.woff2') format('woff2'),
       url('/fonts/opensans-semibold.woff') format('woff');
}

@font-face {
  font-family: 'Open Sans';
  font-style: normal;
  font-weight: 700;
  font-display: swap;
  src: url('/fonts/opensans-bold.woff2') format('woff2'),
       url('/fonts/opensans-bold.woff') format('woff');
}
```

### Usage Guidelines

**Use Open Sans For:**
- ✅ All body copy and paragraphs
- ✅ Lists (ordered and unordered)
- ✅ Form input text
- ✅ Captions and metadata
- ✅ Table content
- ✅ Footer text

**Do Not Use Open Sans For:**
- ❌ Main page headlines (use Raleway)
- ❌ Large display text above 48px (use Raleway)

---

## Calibri (Documents)

### Font Specifications

**Family:** Calibri
**Designer:** Luc(as) de Groot
**License:** Microsoft bundled (available on Windows/Office)
**Classification:** Sans-serif, Humanist

**Weights Available:**
- Regular (400)
- Bold (700)
- Italic (400)
- Bold Italic (700)

### Usage Guidelines

**Use Calibri For:**
- ✅ Microsoft Word documents
- ✅ PowerPoint presentations
- ✅ Excel spreadsheets
- ✅ Outlook emails
- ✅ Internal documentation

**Fallback for Non-Microsoft Platforms:**
```css
font-family: Calibri, 'Open Sans', Arial, sans-serif;
```

**Document Templates:**
- **Headings:** Calibri Bold, Turquoise (#2F99A4)
- **Body Text:** Calibri Regular, Anthracite (#585961)
- **Emphasis:** Calibri Bold or Calibri Italic

---

## Typography Scale

### Web Typography Hierarchy

```css
/* h1 - Page Title */
h1 {
  font-family: 'Raleway', sans-serif;
  font-size: 48px;
  font-weight: 700;
  line-height: 1.2;
  color: #585961;
  margin-bottom: 24px;
}

/* h2 - Section Header */
h2 {
  font-family: 'Raleway', sans-serif;
  font-size: 36px;
  font-weight: 700;
  line-height: 1.3;
  color: #585961;
  margin-bottom: 20px;
}

/* h3 - Subsection Header */
h3 {
  font-family: 'Raleway', sans-serif;
  font-size: 28px;
  font-weight: 600;
  line-height: 1.4;
  color: #585961;
  margin-bottom: 16px;
}

/* h4 - Minor Header */
h4 {
  font-family: 'Raleway', sans-serif;
  font-size: 22px;
  font-weight: 600;
  line-height: 1.4;
  color: #585961;
  margin-bottom: 12px;
}

/* h5 - Small Header */
h5 {
  font-family: 'Raleway', sans-serif;
  font-size: 18px;
  font-weight: 600;
  line-height: 1.5;
  color: #585961;
  margin-bottom: 12px;
}

/* Body Text */
body, p {
  font-family: 'Open Sans', sans-serif;
  font-size: 16px;
  font-weight: 400;
  line-height: 1.6;
  color: #585961;
  margin-bottom: 16px;
}

/* Small Text / Captions */
.text-small, small {
  font-family: 'Open Sans', sans-serif;
  font-size: 14px;
  font-weight: 400;
  line-height: 1.6;
  color: #585961;
}

/* Lead Paragraph */
.lead {
  font-family: 'Open Sans', sans-serif;
  font-size: 20px;
  font-weight: 400;
  line-height: 1.6;
  color: #585961;
}
```

### Responsive Typography

```css
/* Mobile First Approach */

/* Base (Mobile) */
h1 { font-size: 32px; }
h2 { font-size: 26px; }
h3 { font-size: 22px; }
h4 { font-size: 18px; }
body, p { font-size: 16px; }

/* Tablet (768px+) */
@media (min-width: 768px) {
  h1 { font-size: 40px; }
  h2 { font-size: 32px; }
  h3 { font-size: 26px; }
  h4 { font-size: 20px; }
}

/* Desktop (1024px+) */
@media (min-width: 1024px) {
  h1 { font-size: 48px; }
  h2 { font-size: 36px; }
  h3 { font-size: 28px; }
  h4 { font-size: 22px; }
}

/* Large Desktop (1440px+) */
@media (min-width: 1440px) {
  h1 { font-size: 56px; }
  h2 { font-size: 40px; }
}
```

---

## Line Height & Spacing

### Line Height Guidelines

```css
/* Headlines - Tighter Leading */
h1, h2, h3 {
  line-height: 1.2;
}

h4, h5, h6 {
  line-height: 1.4;
}

/* Body Text - Comfortable Reading */
p, li, td {
  line-height: 1.6;
}

/* Small Text */
small, .caption {
  line-height: 1.5;
}
```

### Vertical Rhythm

```css
/* Consistent spacing system */
:root {
  --spacing-xs: 8px;
  --spacing-sm: 12px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
  --spacing-xxl: 48px;
}

/* Apply to typography */
h1 { margin-bottom: var(--spacing-lg); }
h2 { margin-bottom: var(--spacing-lg); }
h3 { margin-bottom: var(--spacing-md); }
h4, h5 { margin-bottom: var(--spacing-sm); }
p { margin-bottom: var(--spacing-md); }
```

---

## Special Typography Elements

### Buttons

```css
.btn {
  font-family: 'Raleway', sans-serif;
  font-size: 16px;
  font-weight: 600;
  line-height: 1;
  letter-spacing: 0.5px;
  text-transform: none;
}

.btn-large {
  font-size: 18px;
}

.btn-small {
  font-size: 14px;
}
```

### Navigation

```css
.nav-link {
  font-family: 'Raleway', sans-serif;
  font-size: 16px;
  font-weight: 400;
  letter-spacing: 0.3px;
}

.nav-link:hover,
.nav-link.active {
  font-weight: 600;
}
```

### Blockquotes / Pull Quotes

```css
blockquote {
  font-family: 'Raleway', sans-serif;
  font-size: 24px;
  font-weight: 400;
  line-height: 1.5;
  font-style: italic;
  color: #2F99A4;
  border-left: 4px solid #FF4D00;
  padding-left: 24px;
  margin: 32px 0;
}

blockquote cite {
  font-family: 'Open Sans', sans-serif;
  font-size: 14px;
  font-weight: 600;
  font-style: normal;
  color: #585961;
  display: block;
  margin-top: 12px;
}
```

### Lists

```css
ul, ol {
  font-family: 'Open Sans', sans-serif;
  font-size: 16px;
  line-height: 1.6;
  margin-bottom: 16px;
  padding-left: 24px;
}

li {
  margin-bottom: 8px;
}

/* Custom bullet points using brand color */
ul.branded {
  list-style: none;
  padding-left: 0;
}

ul.branded li::before {
  content: '●';
  color: #2F99A4;
  font-weight: bold;
  display: inline-block;
  width: 1em;
  margin-left: -1em;
}
```

---

## Font Loading Strategy

### Performance Optimization

```html
<!-- Critical CSS with system font fallback -->
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont,
                 'Segoe UI', sans-serif;
  }
</style>

<!-- Preload critical fonts -->
<link rel="preload"
      href="/fonts/raleway-bold.woff2"
      as="font"
      type="font/woff2"
      crossorigin>
<link rel="preload"
      href="/fonts/opensans-regular.woff2"
      as="font"
      type="font/woff2"
      crossorigin>
```

### Font Display Strategy

```css
@font-face {
  font-family: 'Raleway';
  font-display: swap; /* Show fallback immediately, swap when loaded */
  /* ... other properties */
}
```

### Fallback Stack

```css
/* Complete fallback chain */
--font-headlines: 'Raleway', 'Helvetica Neue', Arial, sans-serif;
--font-body: 'Open Sans', -apple-system, BlinkMacSystemFont,
             'Segoe UI', Roboto, sans-serif;
--font-documents: Calibri, 'Open Sans', Arial, sans-serif;
```

---

## Accessibility Considerations

### Minimum Font Sizes

- **Body text:** Never below 16px (1rem)
- **Small text:** Never below 14px (0.875rem)
- **Buttons:** Minimum 16px for touch targets

### Contrast Requirements

All text must meet WCAG AA:
- **Normal text:** 4.5:1 contrast ratio
- **Large text (≥18px):** 3:1 contrast ratio

### Readability

**Line Length:**
- Optimal: 50-75 characters per line
- Maximum: 90 characters per line

```css
.content {
  max-width: 75ch; /* Character-based width */
}
```

**Paragraph Spacing:**
```css
p + p {
  margin-top: 16px; /* Clear paragraph separation */
}
```

---

## CSS Custom Properties (Complete Set)

```css
:root {
  /* Font Families */
  --font-headline: 'Raleway', sans-serif;
  --font-body: 'Open Sans', sans-serif;
  --font-document: Calibri, 'Open Sans', sans-serif;

  /* Font Sizes */
  --font-size-xs: 12px;
  --font-size-sm: 14px;
  --font-size-base: 16px;
  --font-size-lg: 18px;
  --font-size-xl: 20px;
  --font-size-2xl: 24px;
  --font-size-3xl: 28px;
  --font-size-4xl: 36px;
  --font-size-5xl: 48px;
  --font-size-6xl: 56px;

  /* Font Weights */
  --font-weight-normal: 400;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;

  /* Line Heights */
  --line-height-tight: 1.2;
  --line-height-snug: 1.4;
  --line-height-normal: 1.6;
  --line-height-relaxed: 1.8;

  /* Letter Spacing */
  --letter-spacing-tight: -0.5px;
  --letter-spacing-normal: 0;
  --letter-spacing-wide: 0.5px;
}
```

---

## Typography Testing Checklist

Before deploying:

- [ ] Fonts load correctly on all major browsers
- [ ] Fallback fonts provide acceptable experience
- [ ] All text meets WCAG AA contrast requirements
- [ ] Font files optimized (woff2 format preferred)
- [ ] Font-display: swap implemented
- [ ] Line lengths within 50-90 character range
- [ ] Responsive typography scales appropriately
- [ ] No text smaller than 14px in production
- [ ] Headlines use Raleway, body uses Open Sans
- [ ] Documents use Calibri with proper fallbacks

---

*Last updated: 2025-10-18*
*Maintained by: Netresearch DTT GmbH*
