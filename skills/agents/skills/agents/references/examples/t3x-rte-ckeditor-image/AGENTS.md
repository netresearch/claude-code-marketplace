# AI Agent Development Guide

**Project:** rte_ckeditor_image - TYPO3 CKEditor 5 Image Extension
**Type:** TYPO3 CMS Extension (PHP 8.2+ + JavaScript/ES6)
**License:** GPL-2.0-or-later

## 📋 Documentation Structure

This project uses a three-tier documentation system:

- **[claudedocs/](claudedocs/)** - AI session context (Markdown, gitignored, temporary)
- **[Documentation/](Documentation/)** - Official TYPO3 docs (RST, published, permanent)
- **Root** - Project essentials (README, CONTRIBUTING, SECURITY, LICENSE)

See **[claudedocs/INDEX.md](claudedocs/INDEX.md)** for AI context navigation and **[Documentation/AGENTS.md](Documentation/AGENTS.md)** for TYPO3 documentation system guide.

## 🎯 Quick Start

```bash
# First time setup
composer install
make help                    # See all available targets

# Development workflow
make lint                    # Run all linters
make format                  # Fix code style
make test                    # Run tests
make ci                      # Full CI check (pre-commit)

# Composer shortcuts (if make unavailable)
composer ci:test:php:lint    # PHP syntax check
composer ci:test:php:phpstan # Static analysis
composer ci:test:php:cgl     # Code style check
composer ci:cgl              # Fix code style
```

## 🏗️ Setup

### Prerequisites

- **PHP:** 8.2-8.9 with extensions: dom, libxml
- **Composer:** Latest stable
- **TYPO3:** 13.4+ (cms-core, cms-backend, cms-frontend, cms-rte-ckeditor)
- **direnv:** Optional but recommended

### Installation

```bash
# Clone and install
git clone https://github.com/netresearch/t3x-rte_ckeditor_image.git
cd t3x-rte_ckeditor_image
composer install

# Enable direnv (optional)
direnv allow
```

## 🔧 Build & Test Commands

### Fast Quality Checks (Pre-commit)

```bash
make lint          # PHP lint + PHPStan + style check
make format        # Auto-fix code style
make typecheck     # PHPStan static analysis
```

### Full CI Suite

```bash
make ci            # Complete CI pipeline
make test          # All tests (when available)
```

### Individual Commands

```bash
# PHP Linting
composer ci:test:php:lint

# Static Analysis
composer ci:test:php:phpstan

# Code Style Check
composer ci:test:php:cgl

# Code Style Fix
composer ci:cgl

# Rector (PHP Modernization)
composer ci:test:php:rector
composer ci:rector              # Apply changes
```

## 📝 Code Style

### PHP Standards

- **Base:** PSR-12 + PER-CS 2.0
- **Strict types:** Required in all files (`declare(strict_types=1);`)
- **Header comments:** Auto-managed by PHP-CS-Fixer
- **Config:** `Build/.php-cs-fixer.dist.php`

### Key Rules

```php
<?php

declare(strict_types=1);

/**
 * This file is part of the package netresearch/rte-ckeditor-image.
 *
 * For the full copyright and license information, please read the
 * LICENSE file that was distributed with this source code.
 */

namespace Netresearch\RteCKEditorImage\Controller;

// Imports: Classes, constants, functions
use TYPO3\CMS\Core\Utility\GeneralUtility;

// Alignment on = and =>
$config = [
    'short'  => 'value',
    'longer' => 'another',
];
```

### JavaScript Standards

- **ES6 modules:** CKEditor 5 plugin format
- **No npm tooling:** TYPO3-managed assets
- **Style:** Follow CKEditor 5 conventions
- **Location:** `Resources/Public/JavaScript/`

## 🔒 Security

- **No secrets in VCS:** Use TYPO3's environment configuration
- **Dependency scanning:** Renovate enabled (see `renovate.json`)
- **Static analysis:** PHPStan with strict rules
- **TYPO3 security:** Follow TYPO3 Security Guidelines
- **File uploads:** Use FAL (File Abstraction Layer)
- **XSS prevention:** All output escaped via Fluid templates

## ✅ PR/Commit Checklist

Before committing:

1. ✅ **Lint passed:** `make lint` or `composer ci:test:php:lint`
2. ✅ **Style fixed:** `make format` or `composer ci:cgl`
3. ✅ **Static analysis:** `composer ci:test:php:phpstan` (no new errors)
4. ✅ **Rector check:** `composer ci:test:php:rector` (no suggestions)
5. ✅ **Docs updated:** Update relevant docs/ files if API changed
6. ✅ **CHANGELOG:** Add entry if user-facing change
7. ✅ **Conventional Commits:** Use format: `type(scope): message`
8. ✅ **Small PRs:** Keep ≤300 net LOC changed

### Commit Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
**Scopes:** `backend`, `frontend`, `config`, `docs`, `build`

**Examples:**
```
feat(backend): add image processing hook for WebP
fix(frontend): resolve style drop-down disabled for typo3image
docs(api): update DataHandling API reference
```

## 🎓 Good vs Bad Examples

### ✅ Good: TYPO3 Pattern

```php
<?php

declare(strict_types=1);

namespace Netresearch\RteCKEditorImage\Controller;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Core\Resource\ResourceFactory;

final class SelectImageController
{
    public function __construct(
        private readonly ResourceFactory $resourceFactory
    ) {
    }

    public function infoAction(ServerRequestInterface $request): ResponseInterface
    {
        $fileUid = (int)($request->getQueryParams()['fileId'] ?? 0);
        // Implementation...
    }
}
```

### ❌ Bad: Missing strict types, no DI

```php
<?php
namespace Netresearch\RteCKEditorImage\Controller;

class SelectImageController
{
    public function infoAction($request)
    {
        $fileUid = $_GET['fileId'];  // Direct superglobal access
        $factory = new ResourceFactory();  // No DI
    }
}
```

### ✅ Good: CKEditor 5 Plugin

```javascript
export default class Typo3Image extends Core.Plugin {
    static get requires() {
        return ['StyleUtils', 'GeneralHtmlSupport'];
    }

    init() {
        const editor = this.editor;
        this.listenTo(styleUtils, 'isStyleEnabledForBlock', (event, [style]) => {
            // Event handling...
        });
    }
}
```

### ❌ Bad: Missing dependencies

```javascript
class Typo3Image extends Core.Plugin {
    // Missing requires() - breaks style integration
    init() {
        // Implementation...
    }
}
```

## 🆘 When Stuck

1. **AI Context:** Start with [claudedocs/INDEX.md](claudedocs/INDEX.md) for project navigation
2. **Architecture:** Review [claudedocs/ARCHITECTURE.md](claudedocs/ARCHITECTURE.md)
3. **Security:** Check [claudedocs/SECURITY.md](claudedocs/SECURITY.md)
4. **API Reference:** See [claudedocs/API_REFERENCE.md](claudedocs/API_REFERENCE.md)
5. **Development Guide:** Follow [claudedocs/DEVELOPMENT_GUIDE.md](claudedocs/DEVELOPMENT_GUIDE.md)
6. **TYPO3 Docs Guide:** Read [Documentation/AGENTS.md](Documentation/AGENTS.md)
7. **Published Manual:** https://docs.typo3.org/p/netresearch/rte-ckeditor-image/main/en-us/
8. **TYPO3 Core Docs:** https://docs.typo3.org/
9. **Issues:** https://github.com/netresearch/t3x-rte_ckeditor_image/issues

### Common Issues

- **Style drop-down disabled:** Missing `GeneralHtmlSupport` dependency (v13.0.0+)
- **Images not in frontend:** Missing static template include
- **PHPStan errors:** Run `composer ci:test:php:phpstan:baseline` to update baseline
- **Code style fails:** Run `composer ci:cgl` to auto-fix

## 📐 House Rules

### Commits & PRs

- **Atomic commits:** One logical change per commit
- **Conventional Commits:** Required format (see checklist)
- **Small PRs:** Target ≤300 net LOC changed
- **Branch naming:** `feature/short-description`, `fix/issue-123`

### Design Principles

- **SOLID:** Single responsibility, Open/closed, Liskov, Interface segregation, Dependency inversion
- **KISS:** Keep it simple, stupid
- **DRY:** Don't repeat yourself
- **YAGNI:** You aren't gonna need it
- **Composition > Inheritance:** Prefer composition
- **Law of Demeter:** Minimize coupling

### Dependencies

- **Latest stable:** Use current TYPO3 13.4+ versions
- **Renovate:** Auto-updates enabled
- **Major updates:** Require changelog review + migration notes
- **Composer:** Lock file committed

### API & Versioning

- **SemVer:** Semantic versioning (MAJOR.MINOR.PATCH)
- **TYPO3 compatibility:** Follow TYPO3 versioning
- **Breaking changes:** Increment major version
- **Deprecations:** Add `@deprecated` tag + removal plan

### Testing

- **TYPO3 Testing Framework:** Use `typo3/testing-framework`
- **Functional tests:** For database/integration scenarios
- **Unit tests:** For isolated logic
- **Test location:** `Tests/Functional/`, `Tests/Unit/`

### Licensing

- **License:** AGPL-3.0-or-later
- **SPDX:** Use SPDX identifiers
- **Headers:** Auto-managed by PHP-CS-Fixer
- **Third-party:** Document in CHANGELOG

## 🔗 Related Files

**Root Documentation:**
- **[README.md](README.md)** - Project overview and quick links
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
- **[SECURITY.md](SECURITY.md)** - Security policy
- **[LICENSE](LICENSE)** - GPL-2.0-or-later license

**AI Session Context (gitignored):**
- **[claudedocs/INDEX.md](claudedocs/INDEX.md)** - Navigation hub
- **[claudedocs/PROJECT_OVERVIEW.md](claudedocs/PROJECT_OVERVIEW.md)** - Project summary
- **[claudedocs/ARCHITECTURE.md](claudedocs/ARCHITECTURE.md)** - System design
- **[claudedocs/DEVELOPMENT_GUIDE.md](claudedocs/DEVELOPMENT_GUIDE.md)** - Development workflow
- **[claudedocs/API_REFERENCE.md](claudedocs/API_REFERENCE.md)** - PHP API docs
- **[claudedocs/SECURITY.md](claudedocs/SECURITY.md)** - Security analysis

**Official TYPO3 Documentation:**
- **[Documentation/](Documentation/)** - RST documentation (published)
- **[Documentation/AGENTS.md](Documentation/AGENTS.md)** - TYPO3 docs system guide

**Configuration:**
- **[composer.json](composer.json)** - Dependencies & scripts
- **[Build/](Build/)** - Development tools configuration

## 📚 Additional Resources

- **Repository:** https://github.com/netresearch/t3x-rte_ckeditor_image
- **Packagist:** https://packagist.org/packages/netresearch/rte-ckeditor-image
- **TYPO3 Ext:** https://extensions.typo3.org/extension/rte_ckeditor_image
- **TYPO3 Docs:** https://docs.typo3.org/
- **CKEditor 5:** https://ckeditor.com/docs/ckeditor5/
