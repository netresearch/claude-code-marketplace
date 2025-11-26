---
name: netresearch-branding
version: 1.1.0
description: "Apply Netresearch brand identity and design standards to web projects, documentation, presentations, and digital content. This skill should be used when creating branded materials, designing web interfaces, building presentations, or ensuring brand consistency. Covers: color system (turquoise #40B4B4, orange #F08C1F), typography (Raleway, Open Sans, Calibri), logo usage, web design patterns, social media templates, and image guidelines. This skill ensures professional, unified Netresearch appearance across all digital touchpoints."
license: Complete terms in LICENSE.txt
---

# Netresearch Brand Guidelines

**Purpose:** Apply Netresearch brand identity and design standards to web projects, documentation, presentations, and digital content.

**Activation:** This skill activates when working on Netresearch-branded projects, designing web interfaces, creating presentations, or producing digital content for Netresearch.

## Brand Identity

### Core Brand Values

**Netresearch embodies:**
- **Innovation & Technology** - Modern, forward-thinking solutions
- **Clarity & Communication** - Clear, effective expression (turquoise symbolizes communication)
- **Professionalism** - Unified company appearance (one Netresearch, not separate teams)
- **Freshness** - Refreshing, cool, modern approach (turquoise energy)

### Brand Personality

- **Visual Identity:** Clean, modern, tech-forward
- **Color Emotion:** Refreshing (turquoise), energetic (orange), professional (grey)
- **Typography:** Contemporary sans-serif, clear and readable
- **Imagery:** Authentic team photos, modern tech environments, clean screenshots

## Color System

**Reference:** `references/colors.md`

### Primary Colors

**Turquoise (Brand Color)**
```
Hex: #2F99A4
RGB: 43, 153, 164
CMYK: 76, 19, 35, 3
Pantone: 320 CP
NCS: S 2050-B30G
```

**Usage:**
- Primary brand color
- Buttons, links, call-to-actions
- Headers, accents, highlights
- Logo symbol background (negative)
- Represents: communication, clarity, truth, creative expression

**Orange (Accent Color)**
```
Hex: #FF4D00
RGB: 255, 77, 0
CMYK: 0, 79, 94, 0
```

**Usage:**
- Visual accents and emphasis
- Headlines, highlights
- Graphics and illustrations
- Secondary call-to-actions
- Energy and action elements

### Neutral Colors

**Anthracite/Dark Grey**
```
Hex: #585961
RGB: 88, 89, 97
CMYK: 60, 50, 40, 40
Pantone: Cool Gray 11 C
```

**Usage:**
- Body text (alternative to black)
- Softer than pure black
- Harmonizes with turquoise
- Professional, modern tone

**Light Grey**
```
Hex: #CCCDCC
RGB: 238, 238, 238
CMYK: 8, 5, 7, 20
```

**Usage:**
- Text boxes, backgrounds
- Tables, dividers
- Subtle UI elements
- Light backgrounds

**White**
```
Hex: #FFFFFF
RGB: 255, 255, 255
```

**Usage:**
- Primary background color
- **High white space is essential**
- Clean, modern appearance
- Text on dark backgrounds

### Color Application Rules

**When applying colors to web interfaces**:
```css
/* Primary brand color */
.brand-primary { color: #2F99A4; }
.brand-primary-bg { background-color: #2F99A4; }

/* Accent color */
.brand-accent { color: #FF4D00; }

/* Text colors */
.text-primary { color: #585961; }
.text-muted { color: #CCCDCC; }

/* Backgrounds */
.bg-light { background-color: #CCCDCC; }
.bg-white { background-color: #FFFFFF; }
```

**When applying brand colors**:
- Use turquoise as dominant brand color in all primary elements
- Apply orange sparingly for accents and energy highlights only
- Maintain high white space ratio for clean, modern appearance
- Use grey (#585961) for text instead of pure black for softer look
- Ensure sufficient contrast for accessibility (WCAG AA minimum: 4.5:1)
- Let turquoise dominate over orange (never use them equally)
- Avoid pure black (#000000) for text (use anthracite #585961)
- Never create new color variations outside the brand palette
- Preserve white space generously (don't reduce significantly)
- Reject colors that clash with the brand palette

## Typography

**Reference:** `references/typography.md`

### Font Families

**Raleway (Primary - Headlines)**
```css
font-family: 'Raleway', sans-serif;
```

**Weights Available:**
- Thin (100)
- Extra-Light (200)
- Light (300)
- Regular (400)
- Medium (500)
- Semi-Bold (600)
- Bold (700)
- Extra-Bold (800)
- Heavy (900)

**Usage:**
- All headlines (h1-h5)
- Emphasis text
- Button labels
- Call-to-action text
- Print media headlines
- Digital document headers

**Open Sans (Secondary - Web Body Text)**
```css
font-family: 'Open Sans', sans-serif;
```

**Weights Available:**
- Light (300)
- Regular (400)
- Italic (400 italic)

**Usage:**
- Website body text
- Navigation menus
- Quotes and citations
- Long-form content

**Calibri (Alternative - Documents)**
```css
font-family: 'Calibri', sans-serif;
```

**Usage:**
- Internal documents
- Presentations (fallback)
- Email templates
- Office documents

### Typography Scale

**Website Hierarchy:**
```css
/* Headlines - Raleway */
h1 {
  font-family: 'Raleway', sans-serif;
  font-size: 48px;
  font-weight: 700;
  line-height: 1.2;
  color: #585961;
}

h2 {
  font-family: 'Raleway', sans-serif;
  font-size: 36px;
  font-weight: 600;
  line-height: 1.3;
  color: #585961;
}

h3 {
  font-family: 'Raleway', sans-serif;
  font-size: 28px;
  font-weight: 600;
  line-height: 1.4;
  color: #585961;
}

h4 {
  font-family: 'Raleway', sans-serif;
  font-size: 22px;
  font-weight: 600;
  line-height: 1.4;
  color: #585961;
}

h5 {
  font-family: 'Raleway', sans-serif;
  font-size: 18px;
  font-weight: 600;
  line-height: 1.5;
  color: #585961;
}

/* Body Text - Open Sans */
body, p {
  font-family: 'Open Sans', sans-serif;
  font-size: 16px;
  font-weight: 400;
  line-height: 1.6;
  color: #585961;
}

/* Navigation - Open Sans */
nav, .navigation {
  font-family: 'Open Sans', sans-serif;
  font-size: 14px;
  font-weight: 400;
  color: #585961;
}

/* Quotes - Open Sans Italic */
blockquote {
  font-family: 'Open Sans', sans-serif;
  font-size: 18px;
  font-style: italic;
  line-height: 1.6;
  color: #585961;
}

/* Buttons - Raleway */
button, .button {
  font-family: 'Raleway', sans-serif;
  font-size: 16px;
  font-weight: 600;
  text-transform: none;
}

/* Emphasis - Raleway */
strong, .emphasis {
  font-family: 'Raleway', sans-serif;
  font-weight: 600;
  color: #2F99A4;
}
```

### Typography Application Standards

**When applying typography**:
- Use Raleway for all headlines and emphasis text
- Use Open Sans for website body text and navigation
- Maintain consistent line-height (1.6 for body, 1.2-1.4 for headlines)
- Apply appropriate font weights to establish visual hierarchy
- Ensure readable font sizes (minimum 16px for body text)
- Keep Calibri separate from Raleway/Open Sans (documents only, not web)
- Limit font weights to Regular, Semi-Bold, and Bold (avoid extremes)
- Restrict all caps to short labels only (never for long text passages)
- Reject decorative or script fonts (maintain professional sans-serif)
- Never reduce line-height below 1.4 (preserves readability)

## Logo Usage

### Official Logo Variants

**Primary Logo (Full)**
- Netresearch wordmark + symbol
- Use for main branding applications
- Maintain minimum size: 120px width (digital), 30mm (print)

**Symbol Only "[n]"**
- Standalone symbol (brackets represent the frame)
- Use for: favicons, social media profiles, app icons, minimal branding
- Minimum size: 32px × 32px (digital)
- **Official SVG:** `assets/logos/netresearch-symbol-only.svg`
- **Format:** SVG 1.2 tiny-ps (optimized for web and print)
- **Colors:** Turquoise #2999A4 (frame) + Grey #595A62 (letter "n")

**Logo Colors:**
- **Standard:** Turquoise symbol + grey text (#2F99A4 + #585961)
- **Negative:** White on dark backgrounds
- **Monochrome:** Single color when required

### Logo Spacing (Clear Space)

**Minimum clear space = height of "N" in Netresearch wordmark**

```
┌─────────────────────────────┐
│         [CLEAR SPACE]        │
│   ┌──────────────────────┐  │
│   │   NETRESEARCH LOGO   │  │
│   └──────────────────────┘  │
│         [CLEAR SPACE]        │
└─────────────────────────────┘
```

### Logo Don'ts

**❌ Never:**
- Change logo colors (except approved variants)
- Stretch, distort, or rotate logo
- Add effects (shadows, gradients, outlines)
- Place on busy backgrounds without contrast
- Use outdated logo versions
- Use team logos in external communications
- Create custom logo variations

### Using the Symbol Only Logo

**HTML Implementation:**
```html
<!-- Inline SVG for maximum control -->
<svg viewBox="-75 -75 440 440" width="32" height="32">
  <title>Netresearch DTT GmbH</title>
  <g>
    <path fill="#2999a4" d="M209.6,0V31.62h32.77a26.38,26.38,0,0,1,26.44,26.43V242a26.38,26.38,0,0,1-26.44,26.44H209.6V300h47.93a42.77,42.77,0,0,0,42.86-42.86V42.89A42.76,42.76,0,0,0,257.53,0ZM43.25,0A42.76,42.76,0,0,0,.39,42.89V257.18A42.76,42.76,0,0,0,43.25,300H91.18V268.46H58.4A26.38,26.38,0,0,1,32,242v-184A26.37,26.37,0,0,1,58.4,31.62H91.18V0Z" transform="translate(-0.39 -0.04)"/>
    <path fill="#595a62" d="M221.44,120.41c0-34.48-13.94-57.82-48.93-57.82-26.62,0-48.54,7.74-64.17,26.56l-.7-22.06-28.31.06V232.94h31.59V124.69c7.14-18.38,32.14-34.8,53-34.5,27.38.4,25.2,26.24,26,45.81v96.94h31.58" transform="translate(-0.39 -0.04)"/>
  </g>
</svg>

<!-- Or reference the asset file -->
<img src="assets/logos/netresearch-symbol-only.svg" alt="Netresearch" width="32" height="32">
```

**Common Use Cases:**
- **Favicon:** 32×32px or 64×64px (SVG or PNG export)
- **App Icon:** 512×512px (high-resolution export)
- **Social Media Avatar:** Platform-specific sizes (typically 400×400px minimum)
- **Footer/Header Icon:** Flexible sizing with CSS
- **Loading Indicators:** Animated with CSS transforms
- **Email Signatures:** 48×48px to 64×64px

**Accessibility:**
- Always include `<title>Netresearch DTT GmbH</title>` in SVG
- Use `alt="Netresearch"` for img tags
- Ensure sufficient contrast on backgrounds

### Social Media Profile Images

**Standard Profile Image:**
- **Content:** Logo symbol only (negative)
- **Background:** Turquoise (#2F99A4)
- **Position:** Centered
- **Format:** PNG with transparency or solid background

**Platform Sizes:**
- Facebook: 180 × 180px
- XING: 1500 × 1500px
- LinkedIn: 400 × 400px
- Twitter/X: 400 × 400px

## Web Design Guidelines

**Reference:** `references/web-design.md`

### Layout Principles

**1. High White Space**
- Generous margins and padding
- Clean, uncluttered layouts
- Let content breathe
- Minimum 40px margins on desktop, 20px on mobile

**2. Responsive Grid**
- 12-column grid system
- Breakpoints: 320px, 768px, 1024px, 1440px
- Fluid containers with max-width: 1200px
- Mobile-first approach

**3. Visual Hierarchy**
- Clear content structure (h1 → h2 → h3 → body)
- Turquoise for primary actions
- Orange for secondary accents
- Grey for supporting text

### Component Styles

**Buttons:**
```css
/* Primary Button - Turquoise */
.btn-primary {
  background-color: #2F99A4;
  color: #FFFFFF;
  font-family: 'Raleway', sans-serif;
  font-weight: 600;
  font-size: 16px;
  padding: 12px 32px;
  border-radius: 4px;
  border: none;
  transition: background-color 0.3s ease;
}

.btn-primary:hover {
  background-color: #267883; /* Darker turquoise */
}

/* Secondary Button - Orange */
.btn-secondary {
  background-color: #FF4D00;
  color: #FFFFFF;
  font-family: 'Raleway', sans-serif;
  font-weight: 600;
  font-size: 16px;
  padding: 12px 32px;
  border-radius: 4px;
  border: none;
  transition: background-color 0.3s ease;
}

.btn-secondary:hover {
  background-color: #CC3D00; /* Darker orange */
}

/* Outline Button */
.btn-outline {
  background-color: transparent;
  color: #2F99A4;
  border: 2px solid #2F99A4;
  font-family: 'Raleway', sans-serif;
  font-weight: 600;
  font-size: 16px;
  padding: 10px 30px;
  border-radius: 4px;
  transition: all 0.3s ease;
}

.btn-outline:hover {
  background-color: #2F99A4;
  color: #FFFFFF;
}
```

**Links:**
```css
a {
  color: #2F99A4;
  text-decoration: none;
  transition: color 0.3s ease;
}

a:hover {
  color: #FF4D00;
  text-decoration: underline;
}
```

**Cards:**
```css
.card {
  background: #FFFFFF;
  border: 1px solid #CCCDCC;
  border-radius: 8px;
  padding: 32px;
  box-shadow: 0 2px 8px rgba(88, 89, 97, 0.1);
  transition: box-shadow 0.3s ease;
}

.card:hover {
  box-shadow: 0 4px 16px rgba(47, 153, 164, 0.2);
}

.card-header {
  font-family: 'Raleway', sans-serif;
  font-size: 24px;
  font-weight: 600;
  color: #585961;
  margin-bottom: 16px;
}
```

**Navigation:**
```css
nav {
  background-color: #FFFFFF;
  border-bottom: 1px solid #CCCDCC;
  padding: 20px 0;
}

nav a {
  font-family: 'Open Sans', sans-serif;
  font-size: 14px;
  color: #585961;
  padding: 8px 16px;
  transition: color 0.3s ease;
}

nav a:hover,
nav a.active {
  color: #2F99A4;
}
```

### Header Patterns

**Main Header (Website):**
- Turquoise background or image with turquoise overlay
- White text (Raleway Bold)
- Generous padding (80px top/bottom desktop, 40px mobile)
- Clear call-to-action button

**Section Headers:**
- Raleway Semi-Bold or Bold
- Anthracite grey (#585961)
- Optional orange accent line (4px, #FF4D00)
- 60px margin-bottom

## Image Guidelines

### Website Images

**Primary Source:** Internal photoshoot images (2022 collection)

**Characteristics:**
- Authentic team photos
- Modern office environments
- Natural lighting
- Candid, professional atmosphere
- Technology in context

**Fallback:** Stock photos (only when necessary)
- Modern, clean aesthetic
- Technology-focused
- Diverse, inclusive
- Professional quality
- Avoid cliché business imagery

### Blog & Social Media

**"Eyecatcher" Approach:**
- Attention-grabbing visuals
- Mix of: stock images, original photos, AI-generated images
- Bright, energetic
- Relevant to content topic
- Branded overlays when appropriate

**Social Media Post Templates:**
- Background: Turquoise or white
- Logo: Top-left or bottom-right
- Icons: Category indicators
- Text: Raleway headlines, Open Sans body
- Aspect ratios per platform requirements

### Case Studies

**Screenshot Treatment:**
- **Always show in context** (laptop, tablet, phone mockup)
- Never use bare screenshots
- Use realistic device frames
- High-quality, crisp images
- Annotations in brand colors (turquoise arrows, orange highlights)

**Supporting Images:**
- Schematic diagrams (brand colors)
- Technology logos (official versions)
- Process illustrations
- Before/after comparisons

### Image Technical Requirements

**Web Optimization:**
- Format: WebP with JPG fallback
- Compression: 80-85% quality
- Responsive: Multiple sizes for different viewports
- Alt text: Descriptive, SEO-friendly
- Lazy loading for below-fold images

**Dimensions:**
- Hero images: 1920 × 1080px (16:9)
- Blog headers: 1200 × 630px (Facebook OG)
- Case study headers: 1200 × 800px
- Thumbnails: 600 × 400px
- Team photos: 800 × 800px (square)

## Social Media Guidelines

### Platform Specifications

**Facebook:**
- Profile: 180 × 180px (logo symbol, turquoise bg)
- Cover: 828 × 315px (team photo)
- Post: 1200 × 630px (standard template)

**LinkedIn:**
- Profile: 400 × 400px (logo symbol, turquoise bg)
- Cover: 1584 × 396px (technology logos, abstract)
- Post: 1200 × 627px (standard template)

**XING:**
- Profile: 1500 × 1500px (logo symbol, turquoise bg)
- Cover: 1280 × 624px (technology logos, abstract)
- Post: 720 × 450px (standard template)

**Twitter/X:**
- Profile: 400 × 400px (logo symbol, turquoise bg)
- Header: 1500 × 500px (team photo)
- Post: 1200 × 675px (16:9)

### Post Templates

**Standard Post:**
- White or turquoise background
- Category icon (top-left)
- Raleway headline (28-36px)
- Open Sans body text (16-18px)
- Logo (bottom-right, small)
- 40px margins minimum

**Negative Variant:**
- Turquoise background
- White text
- Same layout structure

### Content Categorization Icons

Use consistent icons for:
- 💼 Business News
- 🚀 Innovation/Technology
- 👥 Team/Culture
- 📚 Knowledge/Blog
- 🎉 Events
- 💡 Tips/Insights

## Accessibility Requirements

### Color Contrast

**WCAG AA Minimum:**
- Body text: Minimum 4.5:1 contrast ratio
- Large text (18px+): Minimum 3:1 contrast ratio
- UI components: Minimum 3:1 contrast ratio

**Brand Color Compliance:**
- ✅ #585961 (anthracite) on #FFFFFF (white) = 8.59:1 ✓
- ✅ #FFFFFF (white) on #2F99A4 (turquoise) = 3.08:1 ✓ (large text only)
- ✅ #FFFFFF (white) on #FF4D00 (orange) = 3.94:1 ✓ (large text only)
- ⚠️  #2F99A4 (turquoise) on #FFFFFF (white) = 3.08:1 (large text or borders)

**Usage Recommendations:**
- Use anthracite (#585961) for small body text
- Use turquoise (#2F99A4) for headlines 18px+ or UI elements
- Use white text on turquoise/orange for buttons and large text only

### Keyboard Navigation

- All interactive elements must be keyboard accessible
- Visible focus states (turquoise outline, 2px)
- Logical tab order
- Skip links for main content

### Screen Readers

- Semantic HTML structure
- Descriptive alt text for images
- ARIA labels for complex interactions
- Proper heading hierarchy (h1 → h2 → h3)

## Pre-Launch Validation Procedures

Execute these validation steps systematically before launching Netresearch projects:

**Design Phase Validation**
1. Import Raleway and Open Sans fonts from Google Fonts or internal server
2. Set up color variables using CSS custom properties or Sass variables
3. Define complete typography scale (h1-h5, body, buttons)
4. Create component library with all brand styles documented
5. Establish responsive breakpoints (320px, 768px, 1024px, 1440px)
6. Plan white space allocation and layout grid system

**Development Phase Validation**
1. Implement brand colors consistently across all components
2. Apply Raleway font family to all headlines (h1-h5)
3. Apply Open Sans to body text, navigation, and UI elements
4. Add Netresearch logo using official variant with proper sizing
5. Optimize all images (WebP format, compression, responsive srcsets)
6. Test color contrast ratios (WCAG AA: minimum 4.5:1 for text)
7. Implement keyboard navigation for all interactive elements
8. Add visible focus states with turquoise outline (2px)

**Quality Assurance Validation**
1. Verify logo usage (minimum sizes, clear space, correct variant)
2. Check color accuracy across Chrome, Firefox, Safari browsers
3. Test typography rendering on different operating systems
4. Validate responsive behavior at all defined breakpoints
5. Run automated accessibility audit (axe, WAVE, Lighthouse)
6. Verify inclusive language throughout all content (no problematic terms)
7. Execute cross-browser testing (latest 2 versions minimum)
8. Measure and optimize performance (Core Web Vitals)

**Brand Compliance Validation**

Execute visual identity checks:
1. Confirm brand colors used correctly (turquoise primary, orange accent)
2. Verify logo displayed properly with adequate clear space
3. Check typography hierarchy is clear and consistent
4. Validate white space is adequate and generous

Execute content quality checks:
1. Confirm images are high-quality and align with brand aesthetics
2. Verify messaging is clear, professional, and on-brand
3. Check "one Netresearch" principle maintained (no team logos externally)
4. Validate inclusive language used throughout all content

Execute technical standards checks:
1. Verify WCAG AA accessibility compliance (automated and manual testing)
2. Confirm performance metrics acceptable (Lighthouse score 90+)
3. Validate responsive design works correctly across all viewports
4. Check all brand assets optimized (file sizes, formats, compression)

## Resources

### Design Assets

- **Logo Files:** Contact internal design team
- **Font Files:** Google Fonts (Raleway, Open Sans) or internal server
- **Image Library:** 2022 photoshoot collection (internal)
- **Social Media Templates:** Canva templates (internal access)

### Official Documentation

- **Presentation Templates:**
  - [Netresearch Template 4:3](https://docs.google.com/presentation)
  - [Netresearch Template 16:9](https://docs.google.com/presentation)
  - [Company Presentation](https://docs.google.com/presentation)

- **Website:** https://www.netresearch.de/

### External References

- **Web Fonts:**
  - [Google Fonts - Raleway](https://fonts.google.com/specimen/Raleway)
  - [Google Fonts - Open Sans](https://fonts.google.com/specimen/Open+Sans)

- **Accessibility:**
  - [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
  - [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

## Brand Voice & Messaging

### Communication Principles

**One Netresearch:**
- Present as unified company, not separate teams
- Team names internal only, not for external communication
- Consistent brand voice across all channels

**Tone:**
- Professional yet approachable
- Modern and tech-savvy
- Clear and communicative
- Innovative and forward-thinking

**Language Style:**
- Clear, concise messaging
- Avoid jargon when possible
- Technical accuracy when needed
- Active voice preferred

**Inclusive Language:**
- Use respectful, professional terminology
- Follow community values and code of conduct standards
- Avoid problematic terms that exclude or offend

**Terms to Avoid and Alternatives:**
- ❌ "master/slave" → ✅ "primary/replica", "leader/follower", "main/secondary"
- ❌ "blacklist/whitelist" → ✅ "blocklist/allowlist", "denylist/permitlist", "exclusion list/inclusion list"
- ❌ "sanity check" → ✅ "confidence check", "validation check", "coherence check"
- ❌ "dummy" → ✅ "placeholder", "sample", "test"
- ❌ "grandfathered" → ✅ "legacy status", "existing entitlement"

These guidelines apply to all written content: code, documentation, presentations, marketing materials, and internal communications.

## TYPO3 Extension Branding

**Purpose:** Ensure consistent Netresearch branding across all TYPO3 extensions developed by or for Netresearch.

### Extension Icon

**Standard:** Use the Netresearch symbol-only logo as the extension icon.

**File Location:** `Resources/Public/Icons/Extension.svg`

**SVG Source:**
```xml
<svg id="netresearch-logo" data-name="Netresearch Logo" xmlns="http://www.w3.org/2000/svg"
     xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 300 300">
    <defs>
        <style>
            .nr-frame{fill:#2999a4;}
            .nr-letter{fill:#595a62;}
        </style>
    </defs>
    <title>Netresearch DTT GmbH</title>
    <g>
        <path class="nr-frame"
              d="M209.6,0V31.62h32.77a26.38,26.38,0,0,1,26.44,26.43V242a26.38,26.38,0,0,1-26.44,26.44H209.6V300h47.93a42.77,42.77,0,0,0,42.86-42.86V42.89A42.76,42.76,0,0,0,257.53,0ZM43.25,0A42.76,42.76,0,0,0,.39,42.89V257.18A42.76,42.76,0,0,0,43.25,300H91.18V268.46H58.4A26.38,26.38,0,0,1,32,242v-184A26.37,26.37,0,0,1,58.4,31.62H91.18V0Z"
              transform="translate(-0.39 -0.04)"/>
        <path class="nr-letter"
              d="M221.44,120.41c0-34.48-13.94-57.82-48.93-57.82-26.62,0-48.54,7.74-64.17,26.56l-.7-22.06-28.31.06V232.94h31.59V124.69c7.14-18.38,32.14-34.8,53-34.5,27.38.4,25.2,26.24,26,45.81v96.94h31.58"
              transform="translate(-0.39 -0.04)"/>
    </g>
</svg>
```

**Color Values:**
- Frame (brackets): Turquoise `#2999A4`
- Letter "n": Anthracite Grey `#595A62`

### Description Field Requirements

**CRITICAL:** Both `composer.json` and `ext_emconf.php` description fields MUST mention the company name.

**Format:** `<What extension does> - by Netresearch` or include "Netresearch" naturally in the description.

**Examples:**
```
✅ "Adds image support to CKEditor5 - by Netresearch"
✅ "Netresearch extension for image handling in CKEditor5"
✅ "Image support for CKEditor5 RTE. Developed and maintained by Netresearch DTT GmbH."

❌ "Adds image support to CKEditor5"  (missing company name)
❌ "Image extension"  (too vague, missing company name)
```

**Why this matters:**
- Brand visibility in extension listings
- Clear attribution in TYPO3 Extension Repository (TER)
- Professional identification in Packagist search results

### composer.json Requirements

**All Netresearch extensions MUST include:**

```json
{
    "name": "netresearch/<extension-name>",
    "type": "typo3-cms-extension",
    "description": "<Clear description> - by Netresearch",
    "homepage": "https://github.com/netresearch/<repo-name>",
    "license": "AGPL-3.0-or-later",
    "authors": [
        {
            "name": "<Developer Name>",
            "email": "<developer>@netresearch.de",
            "role": "Developer",
            "homepage": "https://www.netresearch.de/"
        }
    ],
    "extra": {
        "typo3/cms": {
            "extension-key": "<extension_key>"
        }
    }
}
```

**Mandatory Fields:**
| Field | Format | Example |
|-------|--------|---------|
| `name` | `netresearch/<dashed-extension-key>` | `netresearch/rte-ckeditor-image` |
| `description` | Must mention "Netresearch" | `Image support for CKEditor5 - by Netresearch` |
| `homepage` | GitHub repository URL | `https://github.com/netresearch/t3x-rte_ckeditor_image` |
| `license` | SPDX identifier | `AGPL-3.0-or-later` or `GPL-2.0-or-later` |
| `authors[].email` | Netresearch email | `developer@netresearch.de` |
| `authors[].homepage` | Company website | `https://www.netresearch.de/` |

### ext_emconf.php Requirements

**All Netresearch extensions MUST include:**

```php
<?php
$EM_CONF[$_EXTKEY] = [
    'title'          => '<Extension Title>',
    'description'    => '<Clear description> - by Netresearch',
    'category'       => '<be|fe|plugin|misc>',
    'author'         => '<Developer Name(s)>',
    'author_email'   => '<developer>@netresearch.de',
    'author_company' => 'Netresearch DTT GmbH',
    'state'          => 'stable',
    'version'        => '<x.y.z>',
    'constraints'    => [
        'depends' => [
            'php'   => '<min>-<max>',
            'typo3' => '<min>-<max>',
        ],
        'conflicts' => [],
        'suggests'  => [],
    ],
];
```

**Mandatory Fields:**
| Field | Value | Notes |
|-------|-------|-------|
| `description` | Must mention "Netresearch" | Include company name in description text |
| `author_company` | `Netresearch DTT GmbH` | **Exact spelling required** |
| `author_email` | `*@netresearch.de` | Must use Netresearch email domain |
| `author` | Developer name(s) | Comma-separated for multiple |

### Configuration Files Checklist

**When creating or auditing a Netresearch TYPO3 extension:**

1. **Extension Icon**
   - [ ] `Resources/Public/Icons/Extension.svg` exists
   - [ ] Uses official Netresearch symbol-only logo
   - [ ] Colors: Frame `#2999A4`, Letter `#595A62`

2. **composer.json**
   - [ ] `name` starts with `netresearch/`
   - [ ] `description` mentions "Netresearch"
   - [ ] `homepage` points to GitHub repository
   - [ ] `authors[].homepage` is `https://www.netresearch.de/`
   - [ ] `authors[].email` uses `@netresearch.de` domain
   - [ ] `license` is specified (AGPL-3.0-or-later recommended)

3. **ext_emconf.php**
   - [ ] `description` mentions "Netresearch"
   - [ ] `author_company` is exactly `Netresearch DTT GmbH`
   - [ ] `author_email` uses `@netresearch.de` domain
   - [ ] `author` lists developer name(s)
   - [ ] All mandatory fields are populated

4. **LICENSE file**
   - [ ] LICENSE or LICENSE.txt exists in extension root
   - [ ] Contains full license text matching composer.json license

5. **README.md**
   - [ ] Mentions "Netresearch DTT GmbH" in credits/author section
   - [ ] Links to https://www.netresearch.de/

### Validation Commands

```bash
# Check composer.json vendor
jq -r '.name' composer.json | grep -q "^netresearch/" && echo "✅ Correct vendor" || echo "❌ Wrong vendor"

# Check composer.json description mentions Netresearch
jq -r '.description' composer.json | grep -qi "netresearch" && echo "✅ Description mentions Netresearch" || echo "❌ Description missing Netresearch"

# Check author homepage
jq -r '.authors[].homepage' composer.json | grep -q "netresearch.de" && echo "✅ Correct homepage" || echo "❌ Wrong homepage"

# Check ext_emconf.php description mentions Netresearch
grep "'description' =>" ext_emconf.php | grep -qi "netresearch" && echo "✅ Description mentions Netresearch" || echo "❌ Description missing Netresearch"

# Check ext_emconf.php author_company
grep -q "'author_company' => 'Netresearch DTT GmbH'" ext_emconf.php && echo "✅ Correct company" || echo "❌ Wrong company"

# Check extension icon exists
test -f Resources/Public/Icons/Extension.svg && echo "✅ Extension icon exists" || echo "❌ Missing extension icon"
```

---

## Quick Reference

### Color Codes
```
Turquoise: #2F99A4
Orange:    #FF4D00
Anthracite:#585961
Light Grey:#CCCDCC
White:     #FFFFFF
```

### Font Stack
```css
/* Headlines */
font-family: 'Raleway', sans-serif;

/* Body (Web) */
font-family: 'Open Sans', sans-serif;

/* Body (Documents) */
font-family: 'Calibri', sans-serif;
```

### Logo Minimum Sizes
```
Digital: 120px width
Print: 30mm width
Icon: 32px × 32px
```

### Breakpoints
```css
Mobile:  320px
Tablet:  768px
Desktop: 1024px
Large:   1440px
```

---

*This skill ensures consistent application of Netresearch brand identity across all digital projects. For questions or clarifications, consult the internal design team.*
