# Netresearch Brand Guidelines Skill

A comprehensive Claude Code skill for implementing Netresearch brand guidelines in web projects. Ensures consistent brand application across all digital touchpoints.

## Overview

This skill provides complete brand guidelines, reference documentation, and ready-to-use templates for implementing Netresearch's visual identity on web projects. It enables Claude Code to help developers and designers maintain brand consistency across websites, applications, and digital materials.

## Features

### 📋 Comprehensive Brand Guidelines
- **SKILL.md** - Complete brand implementation guide covering:
  - Brand identity and core values
  - Color system with accessibility compliance
  - Typography standards (Raleway, Open Sans, Calibri)
  - Logo usage guidelines and restrictions
  - Web design principles and best practices
  - Component styles and patterns
  - Social media specifications
  - Image guidelines
  - Accessibility requirements (WCAG AA)
  - Implementation checklists

### 🎨 Reference Documentation
- **colors.md** - Detailed color palette with:
  - Technical specifications (Hex, RGB, CMYK, Pantone, NCS)
  - Usage guidelines and approved combinations
  - WCAG AA contrast ratios
  - CSS custom properties
  - Accessibility compliance details

- **typography.md** - Complete typography system with:
  - Font specifications and licensing
  - Web font loading strategies
  - Typography scale and hierarchy
  - Responsive typography patterns
  - Line height and spacing guidelines
  - Performance optimization

- **web-design.md** - Web implementation patterns:
  - Responsive grid system
  - Component library (buttons, cards, forms, navigation)
  - Layout patterns
  - Animations and transitions
  - Accessibility considerations

### 🎯 Templates & Examples
- **landing-page.html** - Complete landing page template
- **styles.css** - Production-ready brand CSS with all components
- **components.html** - Interactive component showcase

## Installation

### Option 1: Via Netresearch Marketplace (Recommended)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

Then browse skills with `/plugin`.

### Option 2: Download Release

Download the [latest release](https://github.com/netresearch/netresearch-branding-skill/releases/latest) and extract to `~/.claude/skills/netresearch-branding/`

### Option 3: Manual Installation

```bash
# Using curl
curl -L https://github.com/netresearch/netresearch-branding-skill/archive/refs/heads/main.zip -o netresearch-branding.zip
unzip netresearch-branding.zip -d ~/.claude/skills/
mv ~/.claude/skills/netresearch-branding-skill-main ~/.claude/skills/netresearch-branding

# Or using git
git clone https://github.com/netresearch/netresearch-branding-skill.git ~/.claude/skills/netresearch-branding
```

## Usage

### Automatic Activation

The skill activates automatically when working on:
- Netresearch web projects
- Brand implementation tasks
- UI/UX development requiring brand compliance
- Documentation needing brand guidelines

### Manual Invocation

```bash
/skill netresearch-branding
```

### Example Workflows

#### **Creating a New Landing Page**
```
User: "Create a landing page following Netresearch brand guidelines"

Claude: [Activates netresearch-branding skill]
- Uses brand colors (Turquoise #2F99A4, Orange #FF4D00)
- Applies Raleway for headlines, Open Sans for body
- Implements high white space design principle
- Creates responsive layout with brand components
- Ensures WCAG AA accessibility compliance
- Delivers production-ready HTML/CSS
```

#### **Brand Compliance Check**
```
User: "Review this website design for Netresearch brand compliance"

Claude: [Activates netresearch-branding skill]
- Verifies color usage (primary vs accent)
- Checks typography (correct fonts and weights)
- Validates spacing and white space principles
- Reviews component implementations
- Assesses accessibility compliance
- Provides specific improvement recommendations
```

#### **Component Development**
```
User: "Create a contact form with Netresearch branding"

Claude: [Activates netresearch-branding skill]
- Uses branded form components
- Applies correct input styling
- Implements brand buttons
- Ensures proper spacing
- Validates accessibility
- Provides complete HTML/CSS
```

## Brand Quick Reference

### Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Turquoise** | `#2F99A4` | Primary brand color, links, CTAs |
| **Orange** | `#FF4D00` | Accent color, emphasis only |
| **Anthracite** | `#585961` | Primary text color |
| **Light Grey** | `#CCCDCC` | Borders, backgrounds |
| **White** | `#FFFFFF` | Primary background |

### Typography

| Element | Font | Size | Weight |
|---------|------|------|--------|
| **Headlines (Web)** | Raleway | 48px-56px | 700 |
| **Body (Web)** | Open Sans | 16px | 400 |
| **Buttons** | Raleway | 16px | 600 |
| **Documents** | Calibri | 11-12pt | 400/700 |

### Key Principles

1. **High White Space** - Generous padding and margins throughout
2. **Responsive Design** - Mobile-first approach with defined breakpoints
3. **Accessibility** - WCAG AA compliance mandatory
4. **Color Hierarchy** - Turquoise primary, orange accent only
5. **Clean Typography** - Clear hierarchy with Raleway + Open Sans

## File Structure

```
netresearch-branding-skill/
├── SKILL.md                      # Main skill file with guidelines
├── README.md                     # This file
├── references/
│   ├── colors.md                 # Color palette reference
│   ├── typography.md             # Typography system
│   └── web-design.md             # Web components & patterns
├── templates/
│   ├── landing-page.html         # Landing page template
│   └── styles.css                # Brand CSS framework
└── examples/
    └── components.html           # Interactive component showcase
```

## Brand Component Library

### Buttons
```html
<!-- Primary action -->
<button class="btn-primary">Get Started</button>

<!-- Secondary action -->
<button class="btn-secondary">Learn More</button>

<!-- Tertiary action -->
<button class="btn-outline">Contact Us</button>
```

### Cards
```html
<div class="card">
  <div class="card-content">
    <h3 class="card-title">Card Title</h3>
    <p class="card-text">Card description.</p>
    <a href="#" class="link-standalone">Learn more</a>
  </div>
</div>
```

### Forms
```html
<div class="form-group">
  <label for="email" class="form-label">Email*</label>
  <input type="email" id="email" class="form-input"
         placeholder="your@email.com" required>
</div>
```

## CSS Custom Properties

The skill includes a complete set of CSS custom properties for easy implementation:

```css
:root {
  /* Brand Colors */
  --color-primary: #2F99A4;
  --color-accent: #FF4D00;
  --color-text-primary: #585961;

  /* Typography */
  --font-headline: 'Raleway', sans-serif;
  --font-body: 'Open Sans', sans-serif;

  /* Spacing */
  --spacing-xs: 8px;
  --spacing-sm: 12px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
  --spacing-xxl: 48px;
  --spacing-3xl: 64px;
  --spacing-4xl: 96px;
}
```

## Accessibility Compliance

All brand implementations must meet **WCAG AA** standards:

✅ **Text Contrast Ratios:**
- Anthracite on white: 8.3:1 (AAA)
- White on turquoise: 4.5:1 (AA)
- Turquoise on white: 3.8:1 (AA for large text)

✅ **Keyboard Navigation:**
- All interactive elements accessible
- Visible focus states
- Logical tab order

✅ **Screen Readers:**
- Semantic HTML
- ARIA labels where needed
- Alternative text for images

## Responsive Breakpoints

```css
/* Mobile First Approach */
/* Extra Small: 0-599px (default) */
/* Small: 600px+ */
/* Medium: 768px+ */
/* Large: 1024px+ */
/* Extra Large: 1440px+ */
```

## Social Media Specifications

### Profile Images
- **Facebook:** 180 × 180 px (displays at 170 × 170 px)
- **LinkedIn:** 400 × 400 px (displays at 300 × 300 px)
- **Twitter:** 400 × 400 px (displays at 200 × 200 px)
- **XING:** 1024 × 1024 px

### Header/Cover Images
- **Facebook:** 820 × 312 px
- **LinkedIn (Company):** 1128 × 191 px
- **Twitter:** 1500 × 500 px
- **XING:** 970 × 250 px

## Quality Checklist

Before deploying any branded material:

**Visual Design:**
- [ ] Colors match exact hex values
- [ ] Turquoise is primary, orange is accent only
- [ ] High white space maintained
- [ ] Typography uses Raleway + Open Sans

**Technical:**
- [ ] Responsive design implemented
- [ ] WCAG AA compliance verified
- [ ] Fonts loaded efficiently
- [ ] CSS follows naming conventions

**Content:**
- [ ] Logo used correctly
- [ ] Images follow brand guidelines
- [ ] Consistent tone and voice
- [ ] No unapproved color combinations

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes
4. Test thoroughly against brand guidelines
5. Commit your changes (`git commit -m 'Add improvement'`)
6. Push to the branch (`git push origin feature/improvement`)
7. Create a Pull Request

## License

This skill is licensed under GPL-2.0-or-later, matching the TYPO3 project license.

## Support

**Issues and Questions:**
- GitHub Issues: [Report issues](https://github.com/netresearch/netresearch-branding-skill/issues)

**Netresearch Contact:**
- **Website:** https://www.netresearch.de
- **Email:** info@netresearch.de
- **Phone:** +49 341 49288-0
- **Address:** Nonnenstraße 11d, 04229 Leipzig, Germany

## Related Skills

- **typo3-docs** - TYPO3 extension documentation creation
- **typo3-testing** - TYPO3 extension testing infrastructure
- **typo3-conformance** - TYPO3 coding standards evaluation

## Credits

Created by Netresearch DTT GmbH for consistent brand implementation across digital projects.

**Maintained By:** Netresearch DTT GmbH, Leipzig, Germany

---

**Version:** 1.0.0
**Last Updated:** 2025-10-18
