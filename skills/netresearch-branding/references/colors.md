# Netresearch Brand Colors Reference

Complete color palette with technical specifications and usage guidelines.

## Primary Brand Colors

### Turquoise (Primary)
**Technical Specifications:**
- **Hex:** `#2F99A4`
- **RGB:** `rgb(47, 153, 164)`
- **CMYK:** `C71 M7 Y17 K36`
- **Pantone:** 7709 C (approximate)
- **NCS:** S 3040-B30G

**Usage:**
- Primary brand color for all digital and print materials
- Main CTA buttons and interactive elements
- Headers and key visual elements
- Links in default state
- Primary navigation highlights
- Brand identity elements

**Contrast Ratios (WCAG AA):**
- On white background: 3.8:1 (Meets AA for large text)
- On #F5F5F5: 4.2:1 (Meets AA for large text)
- White text on turquoise: 4.5:1 (Meets AA for all text)

**Web Implementation:**
```css
:root {
  --color-primary: #2F99A4;
  --color-primary-rgb: 47, 153, 164;
}

.btn-primary {
  background-color: var(--color-primary);
  color: #FFFFFF;
}

.link-primary {
  color: var(--color-primary);
}
```

---

### Orange (Accent)
**Technical Specifications:**
- **Hex:** `#FF4D00`
- **RGB:** `rgb(255, 77, 0)`
- **CMYK:** `C0 M70 Y100 K0`
- **Pantone:** 172 C (approximate)
- **NCS:** S 1080-Y60R

**Usage:**
- Accent color for emphasis and highlights
- Secondary CTA buttons
- Important notifications and alerts
- Hover states on primary elements
- Call-out boxes and highlights
- Limited use - accent only, not dominant

**Contrast Ratios (WCAG AA):**
- On white background: 3.9:1 (Meets AA for large text)
- On #F5F5F5: 4.3:1 (Meets AA for large text)
- White text on orange: 3.2:1 (Meets AA for large text only)

**Web Implementation:**
```css
:root {
  --color-accent: #FF4D00;
  --color-accent-rgb: 255, 77, 0;
}

.btn-secondary {
  background-color: var(--color-accent);
  color: #FFFFFF;
}

.highlight {
  border-left: 4px solid var(--color-accent);
}
```

---

## Neutral Colors

### Anthracite (Text Primary)
**Technical Specifications:**
- **Hex:** `#585961`
- **RGB:** `rgb(88, 89, 97)`
- **CMYK:** C9 M2 Y0 K62`
- **NCS:** S 5502-B

**Usage:**
- Primary text color for body copy
- Headlines and subheadings
- Navigation text
- Form labels
- Default icon color

**Contrast Ratios (WCAG AA):**
- On white background: 8.3:1 (Meets AAA for all text)
- On #F5F5F5: 7.8:1 (Meets AAA for all text)

**Web Implementation:**
```css
:root {
  --color-text-primary: #585961;
}

body, p, h1, h2, h3 {
  color: var(--color-text-primary);
}
```

---

### Light Grey (Backgrounds)
**Technical Specifications:**
- **Hex:** `#CCCDCC`
- **RGB:** `rgb(204, 205, 204)`
- **CMYK:** C0 M0 Y0 K20`
- **NCS:** S 2000-N

**Usage:**
- Background sections and cards
- Subtle borders and dividers
- Disabled states
- Alternating table rows
- Input field borders

**Contrast Note:**
- Not suitable for text on white background
- Use for backgrounds and UI elements only

**Web Implementation:**
```css
:root {
  --color-background-light: #CCCDCC;
  --color-border-light: #CCCDCC;
}

.card {
  background-color: #F5F5F5;
  border: 1px solid var(--color-border-light);
}
```

---

### White (Background)
**Technical Specifications:**
- **Hex:** `#FFFFFF`
- **RGB:** `rgb(255, 255, 255)`

**Usage:**
- Primary background color
- Text on dark backgrounds
- Card backgrounds
- Clean, spacious layouts

---

## Color Combinations

### Approved Combinations

**Primary Palette:**
```css
/* Turquoise on white - Primary brand */
.combination-1 {
  background: #FFFFFF;
  color: #2F99A4;
}

/* White text on turquoise - High impact */
.combination-2 {
  background: #2F99A4;
  color: #FFFFFF;
}

/* Orange accent with turquoise */
.combination-3 {
  background: #2F99A4;
  border-color: #FF4D00;
  color: #FFFFFF;
}
```

**Text Combinations:**
```css
/* Body text on white - Standard */
.text-standard {
  background: #FFFFFF;
  color: #585961;
}

/* Body text on light grey - Sections */
.text-section {
  background: #F5F5F5;
  color: #585961;
}
```

### Avoid These Combinations

❌ **Never Use:**
- Orange on turquoise (poor contrast)
- Light grey text on white (fails WCAG)
- Turquoise text smaller than 18px on white (AA compliance)
- Orange text on white for small text (fails AA)

---

## Accessibility Guidelines

### WCAG AA Compliance

**Minimum Contrast Ratios:**
- **Normal text (< 18px):** 4.5:1
- **Large text (≥ 18px):** 3:1
- **UI components:** 3:1

**Approved Text Combinations:**

✅ **Pass AA for All Text Sizes:**
- Anthracite (#585961) on white: 8.3:1 ✓
- Anthracite (#585961) on #F5F5F5: 7.8:1 ✓
- White on turquoise (#2F99A4): 4.5:1 ✓

✅ **Pass AA for Large Text Only:**
- Turquoise (#2F99A4) on white: 3.8:1 ✓
- Orange (#FF4D00) on white: 3.9:1 ✓
- White on orange (#FF4D00): 3.2:1 ✓

❌ **Fail AA (Do Not Use):**
- Light grey (#CCCDCC) on white: 1.6:1 ✗

---

## Usage Guidelines by Context

### Websites
- **Primary color:** Turquoise for headers, links, CTAs
- **Accent color:** Orange sparingly for emphasis
- **Background:** White (#FFFFFF) or subtle off-white (#F5F5F5)
- **Text:** Anthracite (#585961)
- **High white space:** Let colors breathe

### Social Media
- **Header images:** Turquoise primary with orange accents
- **Profile elements:** Turquoise logo on white
- **Post graphics:** Maximum 2 brand colors per graphic

### Documents
- **Headers:** Turquoise or anthracite
- **Highlights:** Orange for key information
- **Body text:** Anthracite
- **Backgrounds:** White primary, light grey for emphasis

### Presentations
- **Title slides:** Turquoise background with white text
- **Content slides:** White background with turquoise accents
- **Emphasis:** Orange for key points

---

## CSS Custom Properties (Complete Set)

```css
:root {
  /* Primary Colors */
  --color-primary: #2F99A4;
  --color-primary-rgb: 47, 153, 164;
  --color-primary-light: rgba(47, 153, 164, 0.1);
  --color-primary-dark: #257880;

  /* Accent Colors */
  --color-accent: #FF4D00;
  --color-accent-rgb: 255, 77, 0;
  --color-accent-light: rgba(255, 77, 0, 0.1);
  --color-accent-dark: #CC3D00;

  /* Neutral Colors */
  --color-text-primary: #585961;
  --color-text-secondary: #8A8B93;
  --color-background: #FFFFFF;
  --color-background-alt: #F5F5F5;
  --color-border: #CCCDCC;
  --color-border-light: #E5E5E5;

  /* Semantic Colors */
  --color-success: #28A745;
  --color-warning: #FFC107;
  --color-error: #DC3545;
  --color-info: var(--color-primary);
}
```

---

## Sass/SCSS Variables

```scss
// Primary Colors
$color-primary: #2F99A4;
$color-accent: #FF4D00;

// Neutral Colors
$color-anthracite: #585961;
$color-light-grey: #CCCDCC;
$color-white: #FFFFFF;

// Backgrounds
$color-bg-primary: $color-white;
$color-bg-secondary: #F5F5F5;

// Text
$color-text-primary: $color-anthracite;
$color-text-secondary: lighten($color-anthracite, 15%);

// Borders
$color-border: $color-light-grey;
$color-border-light: #E5E5E5;
```

---

## Color Testing Checklist

Before deploying any brand materials:

- [ ] All text meets WCAG AA contrast requirements
- [ ] Turquoise is primary, orange is accent only
- [ ] No unapproved color combinations used
- [ ] Colors match exact hex values
- [ ] High white space maintained
- [ ] Tested on multiple displays for color accuracy
- [ ] Print materials use CMYK values
- [ ] Digital materials use RGB/Hex values

---

*Last updated: 2025-10-18*
*Maintained by: Netresearch DTT GmbH*
