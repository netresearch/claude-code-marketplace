# Open Source Project Branding Guidelines

**Applies to:** Netresearch public repositories on GitHub (`github.com/netresearch/*`)

## Philosophy

Open source projects require **subtle professional attribution** - not marketing materials. The balance:

**✅ Professional attribution** - Clear maintainer identity, credibility, and contact info
**✅ Technical focus** - Content centers on project value, not company promotion
**❌ Marketing materials** - No taglines, promotional copy, or commercial messaging

**Target branding footprint:** <5% of total README content

## Quick Start

### Minimal OSS README Template

```markdown
<p align="center">
  <img src="https://raw.githubusercontent.com/netresearch/[repo-name]/main/.github/netresearch-symbol.svg" alt="Netresearch" width="48" height="48">
</p>

<h1 align="center">[Project Name]</h1>
<p align="center"><em>Built by <a href="https://www.netresearch.de/">Netresearch DTT GmbH</a></em></p>

<p align="center">
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

---

## Overview

[Brief project description - what problem does it solve?]

## Features

- Feature 1
- Feature 2
- Feature 3

## Installation

```bash
# Installation instructions
```

## Usage

```bash
# Usage examples
```

## Configuration

[Configuration details if applicable]

## API Documentation

[API documentation if applicable]

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) first.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

## About

[Project Name] is developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/), a technology company specializing in [e-commerce solutions / web development / relevant domain].

For professional support, custom development, or consulting services, please visit our website.

## License

This project is licensed under the [License Name] - see the [LICENSE](LICENSE) file for details.

**Copyright © [Year] Netresearch DTT GmbH**
```

## Component Breakdown

### 1. Logo and Header

**Standard pattern:**

```markdown
<p align="center">
  <img src="https://raw.githubusercontent.com/netresearch/[repo-name]/main/.github/netresearch-symbol.svg" alt="Netresearch" width="48" height="48">
</p>

<h1 align="center">[Project Name]</h1>
<p align="center"><em>Built by <a href="https://www.netresearch.de/">Netresearch DTT GmbH</a></em></p>
```

**Alternative (logo in repository):**

```markdown
<p align="center">
  <img src=".github/netresearch-symbol.svg" alt="Netresearch" width="48" height="48">
</p>

<h1 align="center">[Project Name]</h1>
<p align="center"><em>Built by <a href="https://www.netresearch.de/">Netresearch DTT GmbH</a></em></p>
```

**Logo specifications:**
- **File:** Use symbol-only variant (`netresearch-symbol.svg`)
- **Size:** 48px × 48px (maximum)
- **Alignment:** Center
- **Location:** Repository `.github/` directory
- **Source:** `/home/cybot/.claude/plugins/marketplaces/netresearch-claude-code-marketplace/skills/netresearch-branding/assets/logos/netresearch-symbol-only.svg`

### 2. Navigation Links (Optional)

```markdown
<p align="center">
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

---
```

**Guidelines:**
- Optional for projects with clear structure
- Use bullet separator (•) between links
- Add horizontal rule after navigation
- Keep to 4-6 main sections maximum

### 3. Main Technical Content

After header, proceed with standard OSS documentation:

- Overview / Description
- Features
- Installation
- Usage / Quick Start
- Configuration
- API Documentation
- Examples
- Contributing
- Testing
- Deployment
- Troubleshooting
- FAQ
- Changelog

**Critical rules:**
- ✅ Technical, factual content only
- ✅ Code examples, configuration samples
- ✅ Clear, concise explanations
- ❌ No brand colors in content
- ❌ No marketing language ("innovative", "cutting-edge", "best-in-class")
- ❌ No promotional copy

### 4. About Section

**Placement:** At the very bottom, just before License section

**Standard pattern:**

```markdown
## About

[Project Name] is developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/), a technology company specializing in [relevant domain].

For professional support, custom development, or consulting services, please visit our website.
```

**Domain examples:**
- "e-commerce solutions and TYPO3 development"
- "web application development and cloud services"
- "digital transformation and software engineering"
- "enterprise software development"

**Guidelines:**
- Maximum 2 sentences
- Neutral, professional tone
- Brief company context relevant to project domain
- Optional contact/services mention
- No taglines or marketing speak

**Variations:**

**Minimal (maintenance only):**
```markdown
## About

This project is maintained by [Netresearch DTT GmbH](https://www.netresearch.de/).
```

**Standard (with domain context):**
```markdown
## About

[Project Name] is developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/), a technology company specializing in e-commerce solutions.

For professional support or custom development, please contact us through our website.
```

**Community-focused:**
```markdown
## About

This project is maintained by [Netresearch DTT GmbH](https://www.netresearch.de/) and the open source community.

Contributions are welcome! See our [Contributing Guidelines](CONTRIBUTING.md) for details.
```

### 5. License Section

**Standard pattern:**

```markdown
## License

This project is licensed under the [License Name] - see the [LICENSE](LICENSE) file for details.

**Copyright © [Year] Netresearch DTT GmbH**
```

**Common licenses:**
- MIT License
- Apache License 2.0
- GNU General Public License v3.0
- BSD 3-Clause License

**Full example (MIT):**

```markdown
## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Copyright © 2024 Netresearch DTT GmbH**

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

[...full license text in LICENSE file...]
```

## Repository Setup

### Adding Logo to Repository

**Steps:**

1. Create `.github/` directory in repository root:
   ```bash
   mkdir -p .github
   ```

2. Copy Netresearch symbol logo:
   ```bash
   cp /path/to/netresearch-symbol-only.svg .github/netresearch-symbol.svg
   ```

3. Add and commit:
   ```bash
   git add .github/netresearch-symbol.svg
   git commit -m "docs: add Netresearch logo for README attribution"
   ```

4. Reference in README:
   ```markdown
   <img src=".github/netresearch-symbol.svg" alt="Netresearch" width="48" height="48">
   ```

**Alternative:** Use raw.githubusercontent.com URL if logo already exists in repository

### Directory Structure

```
repository-root/
├── .github/
│   ├── netresearch-symbol.svg    # Logo for README
│   └── workflows/                # GitHub Actions (if applicable)
├── src/                          # Source code
├── tests/                        # Tests
├── docs/                         # Additional documentation
├── README.md                     # Main documentation with branding
├── CONTRIBUTING.md               # Contribution guidelines
├── CHANGELOG.md                  # Release history
├── LICENSE                       # License file with copyright
└── package.json / composer.json  # Dependencies
```

## Complete Examples

### Example 1: TYPO3 Extension (Minimal Branding)

```markdown
<p align="center">
  <img src="https://raw.githubusercontent.com/netresearch/t3x-example/main/.github/netresearch-symbol.svg" alt="Netresearch" width="48" height="48">
</p>

<h1 align="center">TYPO3 Example Extension</h1>
<p align="center"><em>Built by <a href="https://www.netresearch.de/">Netresearch DTT GmbH</a></em></p>

---

## Overview

A TYPO3 extension that provides [functionality description].

## Installation

```bash
composer require netresearch/t3x-example
```

## Configuration

Configure in Extension Manager or via TypoScript:

```typoscript
plugin.tx_example {
    settings {
        key = value
    }
}
```

## Usage

[Usage instructions]

## About

This extension is developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/), a technology company specializing in TYPO3 and e-commerce solutions.

## License

This project is licensed under the GPL-2.0-or-later - see the [LICENSE](LICENSE) file for details.

**Copyright © 2024 Netresearch DTT GmbH**
```

**Branding footprint:** 6 lines out of ~50 total = 12% (acceptable for short README)

### Example 2: PHP Library (Standard Branding)

```markdown
<p align="center">
  <img src="https://raw.githubusercontent.com/netresearch/php-library/main/.github/netresearch-symbol.svg" alt="Netresearch" width="48" height="48">
</p>

<h1 align="center">PHP Library Name</h1>
<p align="center"><em>Built by <a href="https://www.netresearch.de/">Netresearch DTT GmbH</a></em></p>

<p align="center">
  <a href="https://packagist.org/packages/netresearch/library"><img src="https://img.shields.io/packagist/v/netresearch/library" alt="Latest Version"></a>
  <a href="https://github.com/netresearch/library/actions"><img src="https://github.com/netresearch/library/workflows/tests/badge.svg" alt="Tests"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
</p>

---

## Overview

A PHP library for [purpose]. Provides [key features].

## Features

- Feature 1
- Feature 2
- Feature 3

## Requirements

- PHP 8.1 or higher
- Composer

## Installation

```bash
composer require netresearch/library
```

## Usage

```php
<?php

use Netresearch\Library\Example;

$example = new Example();
$result = $example->doSomething();
```

[...detailed documentation, API reference, examples...]

## Testing

```bash
composer test
```

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) first.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

## About

PHP Library Name is developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/), a technology company specializing in web application development and e-commerce solutions.

For professional support, custom development, or consulting services, please visit our website.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Copyright © 2024 Netresearch DTT GmbH**
```

**Branding footprint:** 8 lines out of ~200 total = 4% (ideal)

### Example 3: JavaScript/TypeScript Package (Community-Focused)

```markdown
<p align="center">
  <img src="https://raw.githubusercontent.com/netresearch/js-package/main/.github/netresearch-symbol.svg" alt="Netresearch" width="48" height="48">
</p>

<h1 align="center">JavaScript Package</h1>
<p align="center"><em>Built by <a href="https://www.netresearch.de/">Netresearch DTT GmbH</a></em></p>

<p align="center">
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#api">API</a> •
  <a href="#contributing">Contributing</a>
</p>

---

[...comprehensive technical documentation...]

## About

This project is maintained by [Netresearch DTT GmbH](https://www.netresearch.de/) and the open source community.

Contributions are welcome! See our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Copyright © 2024 Netresearch DTT GmbH**
```

## Anti-Patterns (What NOT to Do)

### ❌ Bad: Excessive Branding

```markdown
<p align="center">
  <img src="large-wordmark.svg" alt="Netresearch" width="300">
</p>

<h1 align="center" style="color: #2F99A4;">Amazing Project</h1>
<p align="center">
  <strong>Brought to you by Netresearch - Your innovative partner for cutting-edge digital solutions!</strong>
</p>

## Why Choose This Project?

Built by industry leaders with over 20 years of experience in delivering world-class software solutions...

[Turquoise-colored sections throughout]
[Multiple logo placements]
[Company service advertisements]
```

**Problems:**
- Logo too large (300px vs 48px max)
- Marketing tagline in header
- Promotional language throughout
- Brand colors in content styling
- Commercial messaging instead of technical focus

### ❌ Bad: No Attribution

```markdown
# Project Name

A library for doing things.

## Installation

```bash
npm install project-name
```

## License

MIT
```

**Problems:**
- No indication of maintainer
- No company attribution
- Missing professional credibility markers
- Incomplete license information

### ❌ Bad: Marketing Focus

```markdown
# Enterprise-Grade Solution

## Features

✨ **Innovative Technology** - Powered by cutting-edge algorithms
🚀 **Blazingly Fast** - Outperforms all competitors
🎯 **Best-in-Class** - Industry-leading performance
💡 **Award-Winning** - Recognized excellence

## Why Netresearch?

At Netresearch, we don't just build software - we craft digital experiences that transform businesses...

[3 paragraphs of company marketing copy]

## Our Services

- Custom Development
- Consulting
- Training
- Support Packages

[Pricing information]
```

**Problems:**
- Marketing superlatives throughout
- No technical substance in features
- Company promotion instead of project documentation
- Service/pricing information (belongs on website, not OSS README)

### ❌ Bad: Brand Color Usage

```markdown
<h1 style="color: #2F99A4;">Project Name</h1>

<div style="background: #2F99A4; color: white; padding: 20px;">
  Important: This is a key feature!
</div>

## <span style="color: #FF4D00;">Installation</span>

[Turquoise highlights throughout]
[Orange section headers]
[Styled divs with brand colors]
```

**Problems:**
- HTML/CSS styling in markdown
- Brand colors in technical content
- Visual branding in documentation (GitHub won't render inline styles anyway)

## Quality Checklist

Before publishing OSS project README with branding, verify:

### Logo and Header
- [ ] Logo is 48px × 48px maximum
- [ ] Logo is center-aligned
- [ ] Logo uses symbol-only variant (not full wordmark)
- [ ] Logo file is in `.github/` directory
- [ ] Project name is in `<h1>` tag, center-aligned
- [ ] Subtitle: "Built by Netresearch DTT GmbH"
- [ ] Company link uses correct URL: `https://www.netresearch.de/`

### Content
- [ ] Main sections are technical, not promotional
- [ ] No brand colors in content or styling
- [ ] No marketing language (innovative, cutting-edge, best-in-class, etc.)
- [ ] No HTML/CSS styling with brand colors
- [ ] Code examples are clear and functional
- [ ] Documentation is comprehensive and accurate

### About Section
- [ ] Placed at bottom, before License
- [ ] Maximum 2 sentences
- [ ] Neutral, professional tone
- [ ] Relevant company domain context
- [ ] No taglines or marketing speak
- [ ] Optional contact/services mention is brief

### License Section
- [ ] Clear license type stated
- [ ] Link to LICENSE file included
- [ ] Copyright line: "Copyright © [Year] Netresearch DTT GmbH"
- [ ] Year is current or project start year

### Overall
- [ ] Total branding footprint <5% of README
- [ ] Professional appearance without commercial feel
- [ ] Focus on technical value, not company promotion
- [ ] No badges for branding (only for status/metrics)
- [ ] Repository has `.github/netresearch-symbol.svg`

### Accessibility
- [ ] All images have alt text
- [ ] Links have descriptive text (not "click here")
- [ ] Headings follow logical hierarchy
- [ ] Code blocks have language identifiers

## URLs and Links

**Always use:**
- Company website: `https://www.netresearch.de/` (with www prefix)

**Link text patterns:**
- ✅ `[Netresearch DTT GmbH](https://www.netresearch.de/)`
- ✅ `[our website](https://www.netresearch.de/)`
- ✅ `[contact us](https://www.netresearch.de/)`
- ❌ `https://netresearch.de/` (missing www)
- ❌ `[click here](https://www.netresearch.de/)` (non-descriptive link text)

## Badge Guidelines

Badges should communicate **project status and metrics**, not branding.

**✅ Appropriate badges:**
- Version: `![Version](https://img.shields.io/packagist/v/netresearch/library)`
- Tests: `![Tests](https://github.com/netresearch/library/workflows/tests/badge.svg)`
- Coverage: `![Coverage](https://codecov.io/gh/netresearch/library/badge.svg)`
- License: `![License](https://img.shields.io/badge/license-MIT-blue.svg)`
- Downloads: `![Downloads](https://img.shields.io/packagist/dt/netresearch/library)`

**❌ Inappropriate badges:**
- Company logo badge
- "Built by Netresearch" badge
- Marketing tagline badge
- Brand color customized badges (unless status-related)

## CONTRIBUTING.md Integration

If repository has CONTRIBUTING.md, include company mention there as well:

```markdown
# Contributing to [Project Name]

Thank you for considering contributing to [Project Name]!

This project is maintained by [Netresearch DTT GmbH](https://www.netresearch.de/) and the open source community.

[...contribution guidelines...]

## Code of Conduct

We are committed to fostering a welcoming and inclusive community...

[...code of conduct...]
```

## When to Apply This Guidance

**✅ Apply OSS branding guidelines to:**
- Public GitHub repositories under `github.com/netresearch/*`
- Main README.md files for OSS projects
- Package registry descriptions (npm, Packagist, etc.)
- Repository metadata (description, topics, about section)

**❌ Do NOT apply to:**
- Internal/private repositories
- API documentation files
- Code comments
- Test files
- Configuration files
- Technical specifications (unless main README)
- Fork README files (preserve original branding)

---

**Questions or clarifications?** Consult the internal design team or refer to the main branding skill at `SKILL.md`.
