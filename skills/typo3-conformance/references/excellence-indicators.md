# Excellence Indicators Reference

**Purpose:** Document optional features that indicate exceptional TYPO3 extension quality beyond basic conformance

## Overview

Excellence Indicators are **optional** features that demonstrate exceptional project quality, community engagement, and professional development practices. Extensions are **not penalized** for missing these features, but **earn bonus points** when present.

**Key Principle:** Base conformance (0-100 points) measures adherence to TYPO3 standards. Excellence indicators (0-20 bonus points) reward exceptional quality.

---

## Scoring System

**Total Excellence Points: 0-20 (bonus)**

| Category | Max Points | Purpose |
|----------|-----------|---------|
| Community & Internationalization | 6 | Engagement, accessibility, distribution |
| Advanced Quality Tooling | 7 | Automation, code quality, maintenance |
| Documentation Excellence | 4 | Comprehensive docs, modern tooling |
| Extension Configuration | 3 | Professional setup, flexibility |

---

## Category 1: Community & Internationalization (0-6 points)

### 1.1 Crowdin Integration (+2 points)

**File:** `crowdin.yml`

**Purpose:** Community-driven translation management platform integration

**Example (georgringer/news):**
```yaml
files:
  - source: /Resources/Private/Language/locallang*.xlf
    translation: /Resources/Private/Language/%two_letters_code%.%original_file_name%
```

**Benefits:**
- Enables community translators to contribute
- Automated translation synchronization
- Professional multilingual support
- Reduces maintenance burden for translations

**Validation:**
```bash
[ -f "crowdin.yml" ] && echo "✅ Crowdin integration (+2)"
```

**Reference:** [Crowdin TYPO3 Integration](https://crowdin.com/)

---

### 1.2 GitHub Issue Templates (+1 point)

**Files:** `.github/ISSUE_TEMPLATE/`
- `Bug_report.md`
- `Feature_request.md`
- `Support_question.md`

**Purpose:** Structured community contribution and issue reporting

**Example (georgringer/news):**
```markdown
---
name: Bug report
about: Create a report to help us improve
title: ''
labels: 'bug'
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
...
```

**Benefits:**
- Ensures complete bug reports
- Reduces back-and-forth communication
- Categorizes issues automatically
- Professional project impression

**Validation:**
```bash
ls -1 .github/ISSUE_TEMPLATE/*.md 2>/dev/null | wc -l
# 3 files = +1 point
```

---

### 1.3 .gitattributes Export Optimization (+1 point)

**File:** `.gitattributes`

**Purpose:** Reduce TER (TYPO3 Extension Repository) package size by excluding development files

**Example (georgringer/news):**
```gitattributes
/.github/ export-ignore
/Build/ export-ignore
/Tests/ export-ignore
/.editorconfig export-ignore
/.gitattributes export-ignore
/.gitignore export-ignore
/.styleci.yml export-ignore
/Makefile export-ignore
```

**Benefits:**
- Smaller download size for production installations
- Faster `composer install` in production
- Professional package distribution
- Security (doesn't ship development files)

**Validation:**
```bash
grep -q "export-ignore" .gitattributes && echo "✅ Export optimization (+1)"
```

**Impact Example:**
- Repository size: 15 MB (with tests, CI configs)
- TER package size: 2 MB (production files only)
- **Reduction:** ~87%

---

### 1.4 Professional README with Badges (+2 points)

**File:** `README.md`

**Purpose:** Comprehensive project overview with status indicators

**Required Elements (all 4 required for points):**
1. Stability badge (Packagist or TER)
2. CI/Build status badge (GitHub Actions, GitLab CI)
3. Download stats (Packagist downloads)
4. Compatibility matrix table

**Example (georgringer/news):**
```markdown
[![Latest Stable Version](https://poser.pugx.org/georgringer/news/v/stable)](https://extensions.typo3.org/extension/news/)
[![TYPO3 12](https://img.shields.io/badge/TYPO3-12-orange.svg)](https://get.typo3.org/version/12)
[![TYPO3 13](https://img.shields.io/badge/TYPO3-13-orange.svg)](https://get.typo3.org/version/13)
[![Total Downloads](https://poser.pugx.org/georgringer/news/d/total)](https://packagist.org/packages/georgringer/news)
![Build v12](https://github.com/georgringer/news/actions/workflows/core12.yml/badge.svg)
[![Crowdin](https://badges.crowdin.net/typo3-extension-news/localized.svg)](https://crowdin.com/project/typo3-extension-news)

## Compatibility

| News | TYPO3     | PHP       | Support / Development                |
|------|-----------|-----------|--------------------------------------|
| 12   | 12 - 13   | 8.1 - 8.3 | features, bugfixes, security updates |
| 11   | 11 - 12   | 7.4 - 8.3 | security updates                     |
```

**Validation:**
```bash
# Check for at least 3 badges and a compatibility table
grep -c "!\[" README.md  # Badge count
grep -c "^|" README.md   # Table rows
```

---

## Category 2: Advanced Quality Tooling (0-7 points)

### 2.1 Fractor Configuration (+2 points)

**File:** `Build/fractor/fractor.php`

**Purpose:** Automated refactoring for TypoScript and XML configuration files

**What is Fractor?**
- Rector handles PHP code refactoring
- **Fractor handles TypoScript and XML** file refactoring
- Automates TYPO3 configuration migrations

**Example (georgringer/news):**
```php
<?php

declare(strict_types=1);

use a9f\Fractor\Configuration\FractorConfiguration;
use a9f\FractorTypoScript\Configuration\TypoScriptProcessorOption;
use a9f\FractorXml\Configuration\XmlProcessorOption;
use a9f\Typo3Fractor\Set\Typo3LevelSetList;

return FractorConfiguration::configure()
    ->withPaths([
        __DIR__ . '/../../Classes',
        __DIR__ . '/../../Configuration/',
        __DIR__ . '/../../Resources',
    ])
    ->withSets([
        Typo3LevelSetList::UP_TO_TYPO3_12,
    ])
    ->withOptions([
        TypoScriptProcessorOption::INDENT_CHARACTER => 'auto',
        XmlProcessorOption::INDENT_CHARACTER => Indent::STYLE_TAB,
    ]);
```

**Benefits:**
- Automates TypoScript configuration migrations
- Modernizes FlexForm XML structures
- Reduces manual refactoring effort
- Catches TYPO3 API changes in configuration

**Required Packages:**
```json
{
  "require-dev": {
    "a9f/fractor": "^1.0",
    "a9f/typo3-fractor": "^1.0"
  }
}
```

**Validation:**
```bash
[ -f "Build/fractor/fractor.php" ] && echo "✅ Fractor configuration (+2)"
```

---

### 2.2 TYPO3 CodingStandards Package (+1 point)

**File:** `Build/php-cs-fixer/php-cs-fixer.php`

**Purpose:** Official TYPO3 community coding standards package (not custom config)

**Example (georgringer/news):**
```php
<?php

use PhpCsFixer\Finder;
use TYPO3\CodingStandards\CsFixerConfig;

$config = CsFixerConfig::create();
$config->setHeader(
    'This file is part of the "news" Extension for TYPO3 CMS.

For the full copyright and license information, please read the
LICENSE.txt file that was distributed with this source code.',
    true
);
```

**Benefits:**
- Official TYPO3 community standards
- Automatic copyright header injection
- PER Coding Style (PSR-12 successor)
- Consistent with TYPO3 core

**Required Package:**
```json
{
  "require-dev": {
    "typo3/coding-standards": "^0.5"
  }
}
```

**Validation:**
```bash
grep -q "TYPO3\\\\CodingStandards" Build/php-cs-fixer/php-cs-fixer.php && echo "✅ TYPO3 CodingStandards (+1)"
```

**Alternative (no points):** Custom php-cs-fixer config (still good, but not official package)

---

### 2.3 StyleCI Integration (+1 point)

**File:** `.styleci.yml`

**Purpose:** Cloud-based automatic code style checking on pull requests

**Example (georgringer/news):**
```yaml
preset: psr12

enabled:
    - no_unused_imports
    - ordered_imports
    - single_quote
    - short_array_syntax
    - hash_to_slash_comment
    - native_function_casing

finder:
  name:
    - "*.php"
  not-path:
    - ".Build"
    - "Build/php-cs-fixer"
    - "Documentation"
```

**Benefits:**
- Automatic PR code style checks (no local setup needed)
- Visual code review integration
- Reduces reviewer burden
- Enforces consistency across contributors

**Validation:**
```bash
[ -f ".styleci.yml" ] && echo "✅ StyleCI integration (+1)"
```

**Note:** Alternative to local php-cs-fixer CI checks, not replacement

---

### 2.4 Makefile Task Automation (+1 point)

**File:** `Makefile`

**Purpose:** Self-documenting task automation and workflow management

**Example (georgringer/news):**
```makefile
.PHONY: help
help: ## Displays this list of targets with descriptions
	@echo "The following commands are available:\n"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: docs
docs: ## Generate projects docs (from "Documentation" directory)
	mkdir -p Documentation-GENERATED-temp
	docker run --rm --pull always -v "$(shell pwd)":/project -t ghcr.io/typo3-documentation/render-guides:latest --config=Documentation
```

**Benefits:**
- Discoverable commands (`make help`)
- Consistent workflow across contributors
- Reduces documentation for common tasks
- Docker-based documentation rendering

**Validation:**
```bash
[ -f "Makefile" ] && grep -q "^help:.*##" Makefile && echo "✅ Makefile automation (+1)"
```

---

### 2.5 Comprehensive CI Matrix (+2 points)

**Files:** `.github/workflows/*.yml` or `.gitlab-ci.yml`

**Purpose:** Test across multiple PHP versions and dependency scenarios

**Required for +2 points:**
- At least 3 PHP versions tested
- Both `composerInstallLowest` and `composerInstallHighest` strategies
- Multiple TYPO3 versions if extension supports multiple

**Example (georgringer/news):**
```yaml
name: core 12
on: [ push, pull_request ]

jobs:
  tests:
    runs-on: ubuntu-22.04
    strategy:
      fail-fast: false
      matrix:
        php: [ '8.1', '8.2', '8.3', '8.4' ]  # 4 PHP versions
        composerInstall: [ 'composerInstallLowest', 'composerInstallHighest' ]
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Install testing system
        run: Build/Scripts/runTests.sh -t 12 -p ${{ matrix.php }} -s ${{ matrix.composerInstall }}
      - name: Lint PHP
        run: Build/Scripts/runTests.sh -t 12 -p ${{ matrix.php }} -s lint
```

**Benefits:**
- Catches dependency conflicts early
- Ensures compatibility across PHP versions
- Tests minimum and maximum dependency versions
- Professional CI/CD setup

**Validation:**
```bash
# Check for matrix with multiple PHP versions and composerInstall strategies
grep -A 5 "matrix:" .github/workflows/*.yml | grep -c "composerInstall"
```

---

## Category 3: Documentation Excellence (0-4 points)

### 3.1 Extensive RST Documentation (100+ files) (+3 points)

**Directory:** `Documentation/`

**Purpose:** Comprehensive, structured documentation covering all aspects

**Example (georgringer/news: 183 RST files):**
```
Documentation/
├── Addons/          # Extension integrations
├── Administration/  # Backend administration
├── Introduction/    # Getting started
├── QuickStart/      # Fast setup guide
├── Reference/       # API reference
├── Tutorials/       # Step-by-step guides
├── UsersManual/     # End-user documentation
└── Images/          # Visual assets
```

**Scoring:**
- 50-99 RST files: +1 point
- 100-149 RST files: +2 points
- 150+ RST files: +3 points

**Validation:**
```bash
RST_COUNT=$(find Documentation -name "*.rst" | wc -l)
if [ $RST_COUNT -ge 150 ]; then
    echo "✅ Extensive documentation 150+ RST (+3)"
elif [ $RST_COUNT -ge 100 ]; then
    echo "✅ Comprehensive documentation 100+ RST (+2)"
elif [ $RST_COUNT -ge 50 ]; then
    echo "✅ Good documentation 50+ RST (+1)"
fi
```

**Benefits:**
- Reduces support burden
- Improves onboarding
- Professional project impression
- Better community adoption

---

### 3.2 Modern Documentation Tooling (+1 point)

**Files:**
- `Documentation/guides.xml`
- `Documentation/screenshots.json`

**Purpose:** Modern TYPO3 documentation rendering and screenshot management

**Example (georgringer/news):**
```xml
<!-- guides.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<guides xmlns="https://guides.typo3.org/ns/1.0">
    <project>
        <title>News System</title>
        <release>12.0</release>
        <vendor>georgringer</vendor>
    </project>
</guides>
```

```json
// screenshots.json
{
  "screenshots": [
    {
      "file": "Images/Administration/BackendModule.png",
      "caption": "News administration module"
    }
  ]
}
```

**Benefits:**
- Automated documentation rendering
- Screenshot management and regeneration
- Consistent with TYPO3 documentation standards
- Future-proof documentation setup

**Validation:**
```bash
[ -f "Documentation/guides.xml" ] && echo "✅ Modern documentation tooling (+1)"
```

---

## Category 4: Extension Configuration (0-3 points)

### 4.1 Extension Configuration Template (+1 point)

**File:** `ext_conf_template.txt`

**Purpose:** Backend extension configuration interface with categorized settings

**Example (georgringer/news):**
```
# Records
###########################
# cat=records/enable/103; type=boolean; label=LLL:EXT:news/Resources/Private/Language/locallang_be.xlf:extmng.prependAtCopy
prependAtCopy = 1

# cat=records/enable/101; type=string; label=LLL:EXT:news/Resources/Private/Language/locallang_be.xlf:extmng.tagPid
tagPid = 1

# cat=records/enable/26; type=boolean; label=LLL:EXT:news/Resources/Private/Language/locallang_be.xlf:extmng.rteForTeaser
rteForTeaser = 0

# Backend module
# cat=backend module/enable/10; type=boolean; label=LLL:EXT:news/Resources/Private/Language/locallang_be.xlf:extmng.showAdministrationModule
showAdministrationModule = 1
```

**Benefits:**
- User-friendly backend configuration
- Categorized settings for clarity
- Localized labels
- No PHP knowledge required for configuration

**Validation:**
```bash
[ -f "ext_conf_template.txt" ] && echo "✅ Extension configuration template (+1)"
```

**Note:** Not required for modern TYPO3 extensions using Site Sets, but still valuable for global extension settings

---

### 4.2 Composer Documentation Scripts (+1 point)

**File:** `composer.json`

**Purpose:** Automated documentation rendering and watching

**Required Scripts (at least 2 of 3):**
- `doc-init` - Initialize documentation rendering
- `doc-make` - Render documentation
- `doc-watch` - Watch and auto-render documentation

**Example (georgringer/news):**
```json
{
    "scripts": {
        "doc-init": "docker run --rm --pull always -v $(pwd):/project -it ghcr.io/typo3-documentation/render-guides:latest --config=Documentation",
        "doc-make": "make docs",
        "doc-watch": "docker run --rm -it --pull always -v \"./Documentation:/project/Documentation\" -v \"./Documentation-GENERATED-temp:/project/Documentation-GENERATED-temp\" -p 5173:5173 ghcr.io/garvinhicking/typo3-documentation-browsersync:latest"
    },
    "scripts-descriptions": {
      "doc-init": "Initialize documentation rendering",
      "doc-make": "Render documentation",
      "doc-watch": "Render documentation including a watcher"
    }
}
```

**Benefits:**
- Easy documentation development
- Live preview during writing
- Docker-based (no local dependencies)
- Consistent with TYPO3 documentation workflow

**Validation:**
```bash
grep -q "doc-init.*doc-make" composer.json && echo "✅ Composer doc scripts (+1)"
```

---

### 4.3 Multiple Configuration Sets (TYPO3 13) (+1 point)

**Directory:** `Configuration/Sets/`

**Purpose:** Multiple configuration presets for different use cases

**Required:** At least 2 different Sets (not just one default)

**Example (georgringer/news has 5 Sets):**
```
Configuration/Sets/
├── News/          # Base news functionality
├── RecordLinks/   # Record link handling
├── Sitemap/       # Sitemap generation
├── Twb4/          # Twitter Bootstrap 4 templates
└── Twb5/          # Twitter Bootstrap 5 templates
```

**Benefits:**
- Quick setup for different scenarios
- Reusable configuration patterns
- Modern TYPO3 13 architecture
- Flexible deployment

**Validation:**
```bash
SET_COUNT=$(find Configuration/Sets -mindepth 1 -maxdepth 1 -type d | wc -l)
[ $SET_COUNT -ge 2 ] && echo "✅ Multiple configuration Sets (+1)"
```

---

## Excellence Indicators Conformance Report Format

### Example Report Section

```markdown
## Excellence Indicators (Bonus Score: 12/20)

### ✅ Community & Internationalization (4/6)
- ✅ Crowdin integration (crowdin.yml): +2 points
- ✅ GitHub issue templates (3 templates): +1 point
- ❌ .gitattributes export optimization: 0 points
- ✅ Professional README with badges: +2 points
  - Stability badge: ✅
  - CI status badge: ✅
  - Download stats: ✅
  - Compatibility matrix: ✅

### ✅ Advanced Quality Tooling (5/7)
- ✅ Fractor configuration (Build/fractor/fractor.php): +2 points
- ❌ TYPO3 CodingStandards package: 0 points (uses custom config)
- ✅ StyleCI integration (.styleci.yml): +1 point
- ❌ Makefile automation: 0 points
- ✅ Comprehensive CI matrix (4 PHP versions, composerInstallLowest/Highest): +2 points

### ✅ Documentation Excellence (3/4)
- ✅ Extensive documentation (183 RST files): +3 points
- ❌ Modern documentation tooling (guides.xml): 0 points

### ❌ Extension Configuration (0/3)
- ❌ ext_conf_template.txt: 0 points
- ❌ Composer documentation scripts: 0 points
- ❌ Multiple Configuration Sets: 0 points (only 1 Set present)

### Summary
This extension demonstrates exceptional quality in documentation and CI/CD practices. Consider adding:
- .gitattributes with export-ignore for smaller TER packages
- TYPO3 CodingStandards package for official community standards
- Makefile for task automation
- Modern documentation tooling (guides.xml, screenshots.json)
- Extension configuration template for backend settings
```

---

## Quick Reference Validation Checklist

**When evaluating excellence indicators:**

```
Community & Internationalization (0-6):
□ crowdin.yml present (+2)
□ 3 GitHub issue templates (+1)
□ .gitattributes with export-ignore (+1)
□ README with 4+ badges + compatibility table (+2)

Advanced Quality Tooling (0-7):
□ Build/fractor/fractor.php present (+2)
□ TYPO3\CodingStandards in php-cs-fixer config (+1)
□ .styleci.yml present (+1)
□ Makefile with help target (+1)
□ CI matrix: 3+ PHP versions + composerInstall variants (+2)

Documentation Excellence (0-4):
□ 50-99 RST files (+1) / 100-149 (+2) / 150+ (+3)
□ guides.xml + screenshots.json (+1)

Extension Configuration (0-3):
□ ext_conf_template.txt present (+1)
□ Composer doc scripts (doc-init, doc-make, doc-watch) (+1)
□ 2+ Configuration Sets in Configuration/Sets/ (+1)
```

---

## Implementation Notes

**For Conformance Skill:**

1. **Never penalize** missing excellence indicators
2. **Always report** excellence indicators separately from base conformance
3. **Score format:** `Base: 94/100 | Excellence: 12/20 | Total: 106/120`
4. **Optional evaluation:** Can be disabled with flag if user only wants base conformance

**Example CLI:**
```bash
# Full evaluation (base + excellence)
check-conformance --with-excellence

# Base conformance only
check-conformance

# Excellence only (for established extensions)
check-conformance --excellence-only
```

---

## Resources

- **georgringer/news:** https://github.com/georgringer/news (primary reference for excellence patterns)
- **TYPO3 Best Practices (Tea):** https://github.com/TYPO3BestPractices/tea (primary reference for base conformance)
- **Fractor:** https://github.com/andreaswolf/fractor
- **TYPO3 CodingStandards:** https://github.com/TYPO3/coding-standards
- **StyleCI:** https://styleci.io/
- **Crowdin:** https://crowdin.com/
