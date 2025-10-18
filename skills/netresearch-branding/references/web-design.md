# Netresearch Web Design Guidelines

Comprehensive web design patterns, layouts, components, and responsive design standards.

## Core Design Principles

### 1. High White Space
**Philosophy:** Clean, uncluttered layouts that prioritize content and readability.

```css
/* Generous spacing throughout */
:root {
  --spacing-xs: 8px;
  --spacing-sm: 12px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
  --spacing-xxl: 48px;
  --spacing-3xl: 64px;
  --spacing-4xl: 96px;
}

/* Section spacing */
section {
  padding: var(--spacing-4xl) 0;
}

/* Content spacing */
.content {
  padding: var(--spacing-xxl);
}
```

**Guidelines:**
- Minimum 48px padding around major sections
- Minimum 24px margin between content blocks
- Generous line-height (1.6) for readability
- Never crowd elements - let designs breathe

---

### 2. Responsive Grid System

**12-Column Flexible Grid:**
```css
.grid {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: var(--spacing-lg);
  padding: 0 var(--spacing-lg);
}

/* Content within container */
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 var(--spacing-lg);
}

/* Responsive columns */
.col-12 { grid-column: span 12; }
.col-6 { grid-column: span 6; }
.col-4 { grid-column: span 4; }
.col-3 { grid-column: span 3; }

@media (max-width: 768px) {
  .col-6, .col-4, .col-3 {
    grid-column: span 12;
  }
}
```

---

### 3. Design Hierarchy
- **Primary:** Turquoise (#2F99A4) for key elements
- **Secondary:** Orange (#FF4D00) for accents only
- **Typography:** Clear hierarchy with Raleway headers and Open Sans body
- **Visual Flow:** Top to bottom, left to right reading patterns

---

## Responsive Breakpoints

### Standard Breakpoints

```css
/* Mobile First Approach */

/* Extra Small (Mobile Portrait) */
/* Default: 0px - 599px */

/* Small (Mobile Landscape) */
@media (min-width: 600px) {
  /* Adjustments for landscape phones */
}

/* Medium (Tablet) */
@media (min-width: 768px) {
  /* Two-column layouts start here */
}

/* Large (Desktop) */
@media (min-width: 1024px) {
  /* Full desktop layouts */
}

/* Extra Large (Wide Desktop) */
@media (min-width: 1440px) {
  /* Maximum content width, larger typography */
}

/* Ultra Wide */
@media (min-width: 1920px) {
  /* Optional: Enhanced spacing for ultra-wide displays */
}
```

### Container Widths

```css
.container {
  width: 100%;
  margin: 0 auto;
  padding: 0 16px;
}

@media (min-width: 600px) {
  .container { max-width: 580px; }
}

@media (min-width: 768px) {
  .container { max-width: 750px; }
}

@media (min-width: 1024px) {
  .container { max-width: 1000px; }
}

@media (min-width: 1440px) {
  .container { max-width: 1200px; }
}
```

---

## Component Library

### Buttons

```css
/* Primary Button */
.btn-primary {
  display: inline-block;
  font-family: 'Raleway', sans-serif;
  font-size: 16px;
  font-weight: 600;
  line-height: 1;
  text-align: center;
  text-decoration: none;
  padding: 12px 32px;
  border: none;
  border-radius: 4px;
  background-color: #2F99A4;
  color: #FFFFFF;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary:hover {
  background-color: #257880;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(47, 153, 164, 0.3);
}

.btn-primary:active {
  transform: translateY(0);
}

/* Secondary Button */
.btn-secondary {
  background-color: #FF4D00;
  color: #FFFFFF;
}

.btn-secondary:hover {
  background-color: #CC3D00;
  box-shadow: 0 4px 12px rgba(255, 77, 0, 0.3);
}

/* Outline Button */
.btn-outline {
  background-color: transparent;
  color: #2F99A4;
  border: 2px solid #2F99A4;
}

.btn-outline:hover {
  background-color: #2F99A4;
  color: #FFFFFF;
}

/* Button Sizes */
.btn-small {
  padding: 8px 24px;
  font-size: 14px;
}

.btn-large {
  padding: 16px 48px;
  font-size: 18px;
}

/* Button States */
.btn:disabled,
.btn[disabled] {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
}
```

**Button Usage:**
```html
<!-- Primary action -->
<button class="btn-primary">Get Started</button>

<!-- Secondary action -->
<button class="btn-secondary">Learn More</button>

<!-- Tertiary action -->
<button class="btn-outline">Contact Us</button>

<!-- Sizes -->
<button class="btn-primary btn-small">Small</button>
<button class="btn-primary">Default</button>
<button class="btn-primary btn-large">Large</button>
```

---

### Cards

```css
.card {
  background: #FFFFFF;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  overflow: hidden;
  transition: all 0.3s ease;
}

.card:hover {
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
  transform: translateY(-4px);
}

.card-image {
  width: 100%;
  height: 240px;
  object-fit: cover;
}

.card-content {
  padding: var(--spacing-lg);
}

.card-title {
  font-family: 'Raleway', sans-serif;
  font-size: 22px;
  font-weight: 600;
  color: #585961;
  margin-bottom: var(--spacing-sm);
}

.card-text {
  font-family: 'Open Sans', sans-serif;
  font-size: 16px;
  line-height: 1.6;
  color: #585961;
  margin-bottom: var(--spacing-md);
}

.card-footer {
  padding: var(--spacing-md) var(--spacing-lg);
  border-top: 1px solid #E5E5E5;
  background-color: #F5F5F5;
}
```

**Card Usage:**
```html
<div class="card">
  <img src="image.jpg" alt="Card image" class="card-image">
  <div class="card-content">
    <h3 class="card-title">Card Title</h3>
    <p class="card-text">Card description goes here.</p>
    <a href="#" class="btn-primary">Read More</a>
  </div>
  <div class="card-footer">
    <span class="card-meta">Posted: January 1, 2025</span>
  </div>
</div>
```

---

### Navigation

```css
/* Main Navigation */
.navbar {
  position: sticky;
  top: 0;
  z-index: 1000;
  background: #FFFFFF;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  padding: var(--spacing-md) 0;
}

.navbar-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 var(--spacing-lg);
}

.navbar-logo {
  height: 48px;
}

.navbar-menu {
  display: flex;
  gap: var(--spacing-lg);
  list-style: none;
  margin: 0;
  padding: 0;
}

.navbar-link {
  font-family: 'Raleway', sans-serif;
  font-size: 16px;
  font-weight: 400;
  color: #585961;
  text-decoration: none;
  padding: 8px 16px;
  transition: all 0.3s ease;
}

.navbar-link:hover,
.navbar-link.active {
  color: #2F99A4;
  font-weight: 600;
}

/* Mobile Menu Toggle */
.navbar-toggle {
  display: none;
  flex-direction: column;
  gap: 4px;
  background: none;
  border: none;
  cursor: pointer;
}

.navbar-toggle span {
  display: block;
  width: 24px;
  height: 3px;
  background: #2F99A4;
  transition: all 0.3s ease;
}

@media (max-width: 768px) {
  .navbar-toggle {
    display: flex;
  }

  .navbar-menu {
    position: absolute;
    top: 100%;
    left: 0;
    right: 0;
    flex-direction: column;
    background: #FFFFFF;
    padding: var(--spacing-lg);
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
    transform: translateY(-100%);
    opacity: 0;
    visibility: hidden;
    transition: all 0.3s ease;
  }

  .navbar-menu.active {
    transform: translateY(0);
    opacity: 1;
    visibility: visible;
  }
}
```

---

### Forms

```css
.form-group {
  margin-bottom: var(--spacing-lg);
}

.form-label {
  display: block;
  font-family: 'Open Sans', sans-serif;
  font-size: 14px;
  font-weight: 600;
  color: #585961;
  margin-bottom: var(--spacing-xs);
}

.form-input,
.form-textarea,
.form-select {
  width: 100%;
  font-family: 'Open Sans', sans-serif;
  font-size: 16px;
  color: #585961;
  padding: 12px 16px;
  border: 1px solid #CCCDCC;
  border-radius: 4px;
  background: #FFFFFF;
  transition: all 0.3s ease;
}

.form-input:focus,
.form-textarea:focus,
.form-select:focus {
  outline: none;
  border-color: #2F99A4;
  box-shadow: 0 0 0 3px rgba(47, 153, 164, 0.1);
}

.form-input::placeholder {
  color: #8A8B93;
}

.form-textarea {
  min-height: 120px;
  resize: vertical;
}

.form-error {
  color: #DC3545;
  font-size: 14px;
  margin-top: var(--spacing-xs);
}

.form-input.error {
  border-color: #DC3545;
}

.form-help {
  font-size: 14px;
  color: #8A8B93;
  margin-top: var(--spacing-xs);
}
```

**Form Example:**
```html
<form class="form">
  <div class="form-group">
    <label for="name" class="form-label">Name*</label>
    <input type="text" id="name" class="form-input" placeholder="Your name" required>
  </div>

  <div class="form-group">
    <label for="email" class="form-label">Email*</label>
    <input type="email" id="email" class="form-input" placeholder="your@email.com" required>
    <small class="form-help">We'll never share your email.</small>
  </div>

  <div class="form-group">
    <label for="message" class="form-label">Message*</label>
    <textarea id="message" class="form-textarea" placeholder="Your message" required></textarea>
  </div>

  <button type="submit" class="btn-primary">Send Message</button>
</form>
```

---

### Links

```css
/* Body Links */
a {
  color: #2F99A4;
  text-decoration: none;
  transition: all 0.3s ease;
  border-bottom: 1px solid transparent;
}

a:hover {
  color: #257880;
  border-bottom-color: #2F99A4;
}

/* External Links */
a[target="_blank"]::after {
  content: ' ↗';
  font-size: 0.9em;
}

/* Download Links */
a[download]::before {
  content: '⬇ ';
}

/* Standalone Links */
.link-standalone {
  font-family: 'Raleway', sans-serif;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.link-standalone::after {
  content: '→';
  transition: transform 0.3s ease;
}

.link-standalone:hover::after {
  transform: translateX(4px);
}
```

---

### Hero Sections

```css
.hero {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 600px;
  padding: var(--spacing-4xl) var(--spacing-lg);
  background: linear-gradient(135deg, #2F99A4 0%, #257880 100%);
  color: #FFFFFF;
  text-align: center;
}

.hero-content {
  max-width: 800px;
  z-index: 1;
}

.hero-title {
  font-family: 'Raleway', sans-serif;
  font-size: 56px;
  font-weight: 700;
  margin-bottom: var(--spacing-lg);
}

.hero-subtitle {
  font-family: 'Open Sans', sans-serif;
  font-size: 20px;
  line-height: 1.6;
  margin-bottom: var(--spacing-xl);
  opacity: 0.9;
}

.hero-cta {
  display: flex;
  gap: var(--spacing-md);
  justify-content: center;
  flex-wrap: wrap;
}

@media (max-width: 768px) {
  .hero {
    min-height: 400px;
    padding: var(--spacing-xxl) var(--spacing-lg);
  }

  .hero-title {
    font-size: 36px;
  }

  .hero-subtitle {
    font-size: 18px;
  }

  .hero-cta {
    flex-direction: column;
  }
}
```

---

### Tables

```css
.table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: var(--spacing-lg);
  background: #FFFFFF;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.table thead {
  background-color: #2F99A4;
  color: #FFFFFF;
}

.table th {
  font-family: 'Raleway', sans-serif;
  font-weight: 600;
  text-align: left;
  padding: 16px;
}

.table td {
  font-family: 'Open Sans', sans-serif;
  padding: 12px 16px;
  border-bottom: 1px solid #E5E5E5;
}

.table tbody tr:hover {
  background-color: #F5F5F5;
}

.table tbody tr:last-child td {
  border-bottom: none;
}

/* Responsive Table */
@media (max-width: 768px) {
  .table {
    display: block;
    overflow-x: auto;
  }
}
```

---

### Footer

```css
.footer {
  background-color: #585961;
  color: #FFFFFF;
  padding: var(--spacing-4xl) 0 var(--spacing-lg);
}

.footer-content {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: var(--spacing-xl);
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 var(--spacing-lg);
  margin-bottom: var(--spacing-xl);
}

.footer-section h4 {
  font-family: 'Raleway', sans-serif;
  font-size: 18px;
  font-weight: 600;
  color: #FFFFFF;
  margin-bottom: var(--spacing-md);
}

.footer-section ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.footer-section li {
  margin-bottom: var(--spacing-sm);
}

.footer-section a {
  color: rgba(255, 255, 255, 0.8);
  text-decoration: none;
  transition: color 0.3s ease;
}

.footer-section a:hover {
  color: #2F99A4;
}

.footer-bottom {
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding-top: var(--spacing-lg);
  text-align: center;
  color: rgba(255, 255, 255, 0.6);
  font-size: 14px;
}
```

---

## Layout Patterns

### Two-Column Layout

```css
.two-column {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: var(--spacing-xl);
}

@media (max-width: 768px) {
  .two-column {
    grid-template-columns: 1fr;
  }
}
```

### Three-Column Layout

```css
.three-column {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--spacing-lg);
}

@media (max-width: 1024px) {
  .three-column {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .three-column {
    grid-template-columns: 1fr;
  }
}
```

### Content + Sidebar

```css
.content-sidebar {
  display: grid;
  grid-template-columns: 3fr 1fr;
  gap: var(--spacing-xxl);
}

@media (max-width: 1024px) {
  .content-sidebar {
    grid-template-columns: 1fr;
  }
}
```

---

## Animations & Transitions

```css
/* Smooth transitions */
* {
  transition-timing-function: ease-in-out;
}

/* Fade In */
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.fade-in {
  animation: fadeIn 0.6s ease-out;
}

/* Slide In */
@keyframes slideIn {
  from {
    transform: translateX(-100%);
  }
  to {
    transform: translateX(0);
  }
}

/* Pulse (for emphasis) */
@keyframes pulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}
```

---

## Web Design Checklist

Before launching any web project:

**Layout:**
- [ ] High white space maintained throughout
- [ ] Responsive grid implemented correctly
- [ ] All breakpoints tested (mobile, tablet, desktop)
- [ ] Content max-width appropriate (≤1200px)

**Components:**
- [ ] Buttons follow brand styles (Raleway font, correct colors)
- [ ] Cards have appropriate shadows and hover states
- [ ] Navigation sticky/fixed and accessible
- [ ] Forms styled consistently with validation

**Typography:**
- [ ] Headlines use Raleway
- [ ] Body text uses Open Sans
- [ ] Font sizes scale responsively
- [ ] Line-heights appropriate for readability

**Colors:**
- [ ] Turquoise primary, orange accent only
- [ ] WCAG AA contrast compliance verified
- [ ] Brand colors match exactly (no variations)

**Performance:**
- [ ] Images optimized and responsive
- [ ] Fonts loaded efficiently (preload critical)
- [ ] CSS minified for production
- [ ] Animations use transform/opacity (GPU-accelerated)

**Accessibility:**
- [ ] All interactive elements keyboard accessible
- [ ] ARIA labels where needed
- [ ] Focus states visible
- [ ] Screen reader tested

---

*Last updated: 2025-10-18*
*Maintained by: Netresearch DTT GmbH*
