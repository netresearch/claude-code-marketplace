---
name: netresearch-branding
description: "Apply Netresearch brand identity and design standards to web projects, documentation, presentations, and digital content. This skill should be used when creating branded materials, designing web interfaces, building presentations, or ensuring brand consistency. Covers: color system (turquoise #40B4B4, orange #F08C1F), typography (Raleway, Open Sans, Calibri), logo usage, web design patterns, social media templates, and image guidelines. This skill ensures professional, unified Netresearch appearance across all digital touchpoints."
---

# Netresearch Brand Guidelines

**Purpose:** Apply Netresearch brand identity and design standards to web projects, documentation, presentations, and digital content.

**Activation:** This skill activates when working on Netresearch-branded projects, designing web interfaces, creating presentations, or producing digital content for Netresearch.

## Brand Identity

**Core Values:**
- **Innovation & Technology** - Modern, forward-thinking solutions
- **Clarity & Communication** - Clear, effective expression (turquoise symbolizes communication)
- **Professionalism** - Unified company appearance (one Netresearch, not separate teams)
- **Freshness** - Refreshing, cool, modern approach

**Visual Identity:** Clean, modern, tech-forward with contemporary sans-serif typography and authentic imagery.

## Color System

**Reference:** `references/colors.md` for complete specifications, CSS variables, and contrast ratios.

| Color | Hex | Usage |
|-------|-----|-------|
| Turquoise (Primary) | `#2F99A4` | Buttons, links, headers, accents, logo |
| Orange (Accent) | `#FF4D00` | Visual accents, highlights, secondary CTAs |
| Anthracite | `#585961` | Body text (softer than black) |
| Light Grey | `#CCCDCC` | Backgrounds, dividers, subtle elements |
| White | `#FFFFFF` | Primary background, high white space essential |

**Application Rules:**
- Turquoise dominates; orange for accents only (never equal)
- Use anthracite for text (not pure black)
- Maintain high white space ratio
- WCAG AA minimum contrast: 4.5:1 for text

## Typography

**Reference:** `references/typography.md` for complete font weights, CSS implementation, and scale.

| Font | Usage |
|------|-------|
| **Raleway** | Headlines (h1-h5), buttons, emphasis |
| **Open Sans** | Body text, navigation, quotes |
| **Calibri** | Internal documents, presentations (fallback) |

**Standards:**
- Minimum 16px body text
- Line-height: 1.6 body, 1.2-1.4 headlines
- Limit weights to Regular, Semi-Bold, Bold
- All caps only for short labels

## Logo Usage

**Primary Logo:** Netresearch wordmark + symbol (minimum 120px width digital, 30mm print)

**Symbol Only "[n]":** For favicons, social profiles, app icons (minimum 32×32px)
- Frame: Turquoise `#2999A4`
- Letter: Grey `#595A62`
- Asset: `assets/logos/netresearch-symbol-only.svg`

**Clear Space:** Height of "N" in wordmark on all sides

**Don'ts:** Never change colors, stretch, distort, add effects, or create custom variations.

## Web Design

**Reference:** `references/web-design.md` for complete component styles, layouts, and patterns.

**Layout Principles:**
- High white space (40px margins desktop, 20px mobile)
- 12-column responsive grid (breakpoints: 320, 768, 1024, 1440px)
- Mobile-first approach
- Max-width: 1200px containers

**Component Quick Reference:**
```css
/* Primary Button */
.btn-primary { background: #2F99A4; color: #FFF; font-family: 'Raleway'; }

/* Link */
a { color: #2F99A4; } a:hover { color: #FF4D00; }

/* Card */
.card { background: #FFF; border: 1px solid #CCCDCC; border-radius: 8px; }
```

## Image Guidelines

**Primary Source:** Internal photoshoot images (2022 collection) - authentic team photos, modern environments

**Fallback:** Stock photos (modern, tech-focused, diverse, avoid clichés)

**Technical:** WebP format, 80-85% quality, responsive srcsets, descriptive alt text

**Screenshots:** Always show in device mockups (laptop, tablet, phone) - never bare

## Social Media

**Profile Images:** Logo symbol (negative) on turquoise background

| Platform | Profile | Cover | Post |
|----------|---------|-------|------|
| Facebook | 180×180 | 828×315 | 1200×630 |
| LinkedIn | 400×400 | 1584×396 | 1200×627 |
| XING | 1500×1500 | 1280×624 | 720×450 |
| Twitter/X | 400×400 | 1500×500 | 1200×675 |

## Accessibility

**WCAG AA Compliance Required:**
- Body text contrast: minimum 4.5:1
- Large text (18px+): minimum 3:1
- Keyboard accessible with visible focus (turquoise 2px outline)
- Semantic HTML, ARIA labels, proper heading hierarchy

## Brand Voice

**Tone:** Professional yet approachable, modern, tech-savvy, clear

**One Netresearch:** Present as unified company, team names internal only

**Inclusive Language:**
- ❌ master/slave → ✅ primary/replica, main/secondary
- ❌ blacklist/whitelist → ✅ blocklist/allowlist
- ❌ sanity check → ✅ validation check

## TYPO3 Extension Branding

**Reference:** `references/typo3-extension-branding.md` for complete requirements and validation commands.

**Critical Requirements:**
- Extension icon: Netresearch symbol-only logo at `Resources/Public/Icons/Extension.svg`
- **Description fields MUST mention "Netresearch"** in both composer.json and ext_emconf.php
- `author_company`: `Netresearch DTT GmbH` (exact spelling)
- `authors[].homepage`: `https://www.netresearch.de/`
- Vendor prefix: `netresearch/` in composer.json name

**Description Format:** `<What extension does> - by Netresearch`

## Pre-Launch Checklist

**Design:**
- [ ] Raleway + Open Sans fonts loaded
- [ ] Color variables defined
- [ ] Typography scale implemented
- [ ] Responsive breakpoints set

**Development:**
- [ ] Brand colors applied consistently
- [ ] Logo with proper sizing and spacing
- [ ] Images optimized (WebP, responsive)
- [ ] Keyboard navigation + focus states

**QA:**
- [ ] Color accuracy across browsers
- [ ] Accessibility audit (axe, WAVE, Lighthouse 90+)
- [ ] Responsive at all breakpoints
- [ ] Inclusive language throughout

---

## Quick Reference

**Colors:** `#2F99A4` (turquoise) · `#FF4D00` (orange) · `#585961` (text) · `#CCCDCC` (grey)

**Fonts:** Raleway (headlines) · Open Sans (body) · Calibri (documents)

**Logo:** Min 120px digital · Min 32×32 icon · Clear space = N height

**Breakpoints:** 320px · 768px · 1024px · 1440px

---

*For detailed specifications, see the reference files in `references/`.*
