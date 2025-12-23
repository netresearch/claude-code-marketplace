---
name: typo3-conformance
description: "Agent Skill: Evaluate TYPO3 extensions for conformance to TYPO3 12/13 LTS standards, coding guidelines (PSR-12), and architecture patterns. Use when assessing extension quality, generating conformance reports, identifying technical debt, or planning modernization. Validates extension architecture, composer.json, ext_emconf.php, backend module v13 compliance, dependency injection, testing, and Extbase patterns. Provides dual scoring (0-100 base + 0-22 excellence). Delegates to typo3-tests and typo3-docs skills for deep analysis. By Netresearch."
file_triggers:
  # TYPO3-only extension root files
  - "ext_emconf.php"
  - "ext_localconf.php"
  - "ext_tables.php"
  - "ext_tables.sql"
  - "ext_conf_template.txt"
  # TYPO3-specific configuration directories
  - "**/Configuration/TCA/**/*"
  - "**/Configuration/TsConfig/**/*"
  - "**/Configuration/TSconfig/**/*"
  - "**/Configuration/TypoScript/**/*"
  - "**/Configuration/FlexForms/**/*"
  - "**/Configuration/Backend/Modules.php"
  - "**/Configuration/Backend/AjaxRoutes.php"
  - "**/Configuration/Backend/Routes.php"
  - "**/Configuration/Sets/**/*"
  - "**/Configuration/page.tsconfig"
  - "**/Configuration/user.tsconfig"
  # TYPO3-specific file extensions
  - "**/*.typoscript"
  - "**/*.tsconfig"
---

# TYPO3 Extension Conformance Checker

**Purpose:** Evaluate TYPO3 extensions for conformance to official TYPO3 coding standards, architecture patterns, and best practices.

**Activation:** This skill activates when analyzing TYPO3 extensions for standards compliance, code quality, or conformance checking.

## Skill Ecosystem Integration

Delegate to specialized skills for deep domain analysis:

| Skill | Use For |
|-------|---------|
| **typo3-tests** | PHPUnit config, test patterns, coverage calculation, anti-patterns |
| **typo3-docs** | RST validation, documentation rendering, cross-references |

**Strategy:** Surface-level checks use this skill. Deep analysis delegates to specialized skills. Basic validation serves as fallback.

## Evaluation Workflow

### Step 1: Initial Assessment

Identify extension context: key, location, TYPO3 version, type (Extbase, backend module, etc.)

**Reference:** `references/version-requirements.md` for PHP/TYPO3 compatibility matrix

### Step 2: File Structure Analysis

**Reference:** `references/extension-architecture.md`

Verify required files:
- `composer.json` with PSR-4 autoloading
- `ext_emconf.php` with proper metadata
- `Classes/`, `Configuration/`, `Resources/` directories
- `Documentation/Index.rst` + `Settings.cfg`

**Validation:** `references/composer-validation.md`, `references/ext-emconf-validation.md`, `references/ext-files-validation.md`

### Step 3: Coding Standards

**Reference:** `references/coding-guidelines.md`

Verify:
- `declare(strict_types=1)` in all PHP files (except ext_emconf.php)
- Type declarations on properties, parameters, returns
- PHPDoc on public methods/classes
- PSR-12 compliance, short array syntax `[]`
- Inclusive language (no master/slave, blacklist/whitelist)

### Step 4: Backend Module v13 (If Applicable)

**Reference:** `references/backend-module-v13.md`

Critical checks:
- Extension key consistency across templates/JS
- ES6 modules (no inline JavaScript)
- Modal/Notification API usage
- DocHeader integration, Module.html layout
- CSRF protection, ARIA accessibility

### Step 5: PHP Architecture

**References:** `references/php-architecture.md`, `references/hooks-and-events.md`

Verify:
- `Configuration/Services.yaml` present
- Constructor injection (not GeneralUtility::makeInstance)
- PSR-14 events where applicable
- No `$GLOBALS` access

### Step 6: Testing Infrastructure

**Reference:** `references/testing-standards.md`

**Delegate:** Use typo3-tests skill for deep analysis when available.

PHP Tests (PHPUnit):
- `Tests/Unit/` mirrors `Classes/` structure
- `Tests/Functional/` with fixtures
- PHPUnit configuration files present
- Coverage target: >70%

E2E Tests (Playwright):
- `Build/playwright.config.ts` configured
- `Build/tests/playwright/e2e/` test files
- `Build/tests/playwright/accessibility/` with axe-core
- Node.js >=22.18

### Step 7: Best Practices

**References:** `references/best-practices.md`, `references/runtests-validation.md`, `references/development-environment.md`, `references/directory-structure.md`

Verify:
- DDEV/Docker configuration
- Build/Scripts/runTests.sh
- Quality tools (phpstan, php-cs-fixer, rector)
- CI/CD pipeline, README.md + LICENSE

## Scoring System

**Base Conformance (0-100 points):**

| Category | Points |
|----------|--------|
| Extension Architecture | 20 |
| Coding Guidelines | 20 |
| PHP Architecture | 20 |
| Testing Standards | 20 |
| Best Practices | 20 |

**Excellence Indicators (0-22 bonus):** Optional features for exceptional quality.

**Reference:** `references/excellence-indicators.md` for detailed scoring criteria.

**Severity Levels:** Critical (security/broken), High (deprecated patterns), Medium (missing tests), Low (style issues)

## Bundled Resources

### Validation Scripts (`scripts/`)

Execute automated conformance checks:

| Script | Purpose |
|--------|---------|
| `check-conformance.sh` | Main orchestration script |
| `check-file-structure.sh` | File structure validation |
| `check-coding-standards.sh` | PSR-12 and code style |
| `check-architecture.sh` | DI and architecture patterns |
| `check-testing.sh` | Testing infrastructure |
| `check-phpstan-baseline.sh` | PHPStan baseline validation |
| `generate-report.sh` | Report generation |

**Usage:** `scripts/check-conformance.sh /path/to/extension`

### Configuration Templates (`templates/`)

Production-ready configurations based on TYPO3 Best Practices (Tea Extension):

| Template | Purpose |
|----------|---------|
| `Build/phpstan/` | PHPStan Level 10 configuration |
| `Build/rector/` | Rector TYPO3 migrations |
| `Build/php-cs-fixer/` | TYPO3 coding standards |
| `Build/playwright/` | E2E and accessibility testing |
| `Build/eslint/` | JavaScript linting |
| `Build/stylelint/` | CSS quality checks |
| `Build/typoscript-lint/` | TypoScript validation |
| `Build/composer-unused/` | Dependency health |
| `.github/workflows/` | TER publishing workflow |

Copy templates to extension: `cp -r templates/Build/* /path/to/extension/Build/`

### Reference Documentation (`references/`)

| File | Purpose |
|------|---------|
| `extension-architecture.md` | Directory structure, required files |
| `coding-guidelines.md` | PSR-12, naming conventions |
| `backend-module-v13.md` | Backend module modernization |
| `php-architecture.md` | DI, events, services |
| `hooks-and-events.md` | SC_OPTIONS hooks, PSR-14 events |
| `testing-standards.md` | PHPUnit, Playwright E2E |
| `best-practices.md` | Infrastructure, quality |
| `composer-validation.md` | composer.json requirements |
| `ext-emconf-validation.md` | ext_emconf.php requirements |
| `ext-files-validation.md` | ext_* file validation |
| `v13-deprecations.md` | TYPO3 v13 deprecations |
| `excellence-indicators.md` | Bonus scoring criteria |
| `crowdin-integration.md` | Translation workflow |
| `ter-publishing.md` | TER upload workflow |
| `version-requirements.md` | PHP/TYPO3 version matrix |
| `directory-structure.md` | Build directory organization |
| `development-environment.md` | DDEV, Docker setup |
| `runtests-validation.md` | runTests.sh patterns |
| `report-template.md` | Full report format |
| `dual-version-compatibility.md` | v12+v13 dual support patterns |

## Report Generation

**Template:** `references/report-template.md`

Generate conformance reports with dual scoring: Base (0-100) + Excellence (0-22 bonus).

---

*For detailed validation rules, consult the reference files in `references/`.*
