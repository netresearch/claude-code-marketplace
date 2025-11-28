---
name: typo3-conformance
description: "Evaluate TYPO3 extensions for conformance to TYPO3 12/13 LTS standards, coding guidelines (PSR-12), and architecture patterns. Use when assessing extension quality, generating conformance reports, identifying technical debt, or planning modernization. Validates: extension architecture, composer.json, ext_emconf.php, ext_* files, v13 deprecations, backend module v13 compliance (ES6 modules, DocHeader, Modal/Notification APIs, Module.html layout, ARIA, extension key consistency, CSRF, icons), dependency injection, services, testing, Extbase patterns, Crowdin, GitHub workflows. Dual scoring (0-100 base + 0-22 excellence). Delegates to typo3-tests and typo3-docs skills for deep analysis. PHP 8.1-8.4 support."
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

**Strategy:** Surface-level → this skill. Deep analysis → delegate. Fallback → basic validation.

## Version Compatibility

| TYPO3 | PHP Support |
|-------|-------------|
| 12.4 LTS | 8.1 - 8.4 |
| 13.x | 8.2 - 8.4 |

**Reference:** `references/version-requirements.md`

## Evaluation Workflow

### Step 1: Initial Assessment

Identify extension context: key, location, TYPO3 version, type (Extbase, backend module, etc.)

```bash
ls -la | grep -E "Classes|Configuration|Resources|Tests|Documentation"
ls -1 | grep -E "composer.json|ext_emconf.php"
```

### Step 2: File Structure Analysis

**Reference:** `references/extension-architecture.md`

**Required Files:**
- [ ] `composer.json` with PSR-4 autoloading
- [ ] `ext_emconf.php` with proper metadata
- [ ] `Classes/`, `Configuration/`, `Resources/` directories
- [ ] `Documentation/Index.rst` + `Settings.cfg`

**Validation:** `references/composer-validation.md`, `references/ext-emconf-validation.md`, `references/ext-files-validation.md`

### Step 3: Coding Standards

**Reference:** `references/coding-guidelines.md`

**Check:**
- [ ] `declare(strict_types=1)` in all PHP files (except ext_emconf.php)
- [ ] Type declarations on properties, parameters, returns
- [ ] PHPDoc on public methods/classes
- [ ] PSR-12 compliance, short array syntax `[]`
- [ ] Inclusive language (no master/slave, blacklist/whitelist)

### Step 3.5: Backend Module v13 (If Applicable)

**Reference:** `references/backend-module-v13.md`

**Critical Checks:**
- Extension key consistency across templates/JS
- ES6 modules (no inline JavaScript)
- Modal/Notification API usage
- DocHeader integration
- Module.html layout
- CSRF protection via uriBuilder
- ARIA accessibility

### Step 4: PHP Architecture

**Reference:** `references/php-architecture.md`

**Check:**
- [ ] `Configuration/Services.yaml` present
- [ ] Constructor injection (not GeneralUtility::makeInstance)
- [ ] PSR-14 events (not deprecated hooks)
- [ ] No `$GLOBALS` access

### Step 5: Testing Infrastructure

**Reference:** `references/testing-standards.md`

**Delegate:** Use typo3-tests skill for deep analysis when available.

**Basic Check:**
- [ ] `Tests/Unit/` mirrors `Classes/` structure
- [ ] `Tests/Functional/` with fixtures
- [ ] PHPUnit configuration files present
- [ ] Coverage target: >70%

### Step 6: Best Practices

**References:**
- `references/best-practices.md`
- `references/runtests-validation.md`
- `references/development-environment.md`
- `references/directory-structure.md`

**Check:**
- [ ] DDEV/Docker configuration
- [ ] Build/Scripts/runTests.sh
- [ ] .Build/ vs Build/ separation
- [ ] Quality tools (phpstan, php-cs-fixer)
- [ ] CI/CD pipeline
- [ ] README.md + LICENSE

## Scoring System

### Base Conformance (0-100 points)

| Category | Points | Key Criteria |
|----------|--------|--------------|
| Extension Architecture | 20 | Required files, directory structure, naming |
| Coding Guidelines | 20 | PSR-12, type declarations, PHPDoc |
| PHP Architecture | 20 | DI, no deprecated patterns, events |
| Testing Standards | 20 | Coverage >70%, proper structure |
| Best Practices | 20 | Dev env, build scripts, quality tools |

### Excellence Indicators (0-22 bonus)

**Reference:** `references/excellence-indicators.md`

| Category | Points | Examples |
|----------|--------|----------|
| Community & i18n | 6 | Crowdin, issue templates, badges |
| Quality Tooling | 9 | Fractor, CodingStandards, TER workflow |
| Documentation | 4 | RST file count, modern tooling |
| Configuration | 3 | ext_conf_template, doc scripts |

**Total Possible:** 122 points (100 base + 22 excellence)

### Severity Levels

- **Critical:** Security vulnerabilities, broken functionality
- **High:** Deprecated patterns, missing required files
- **Medium:** Missing tests, incomplete documentation
- **Low:** Style inconsistencies, optional improvements

## Report Generation

**Template:** `references/report-template.md`

```markdown
# TYPO3 Extension Conformance Report

**Extension:** {name} (v{version})
**Base Score:** {score}/100
**Excellence:** {bonus}/22
**Total:** {total}/122

## Summary by Category
- Extension Architecture: {x}/20
- Coding Guidelines: {x}/20
- PHP Architecture: {x}/20
- Testing Standards: {x}/20
- Best Practices: {x}/20

## Priority Issues
{critical and high severity items}

## Recommendations
{actionable improvements}
```

## Quick Validation Commands

```bash
# File structure
ls -la | grep -E "Classes|Configuration|Resources|Tests"

# Strict types check
grep -rL "declare(strict_types=1)" Classes/ --include="*.php"

# Deprecated patterns
grep -r "GeneralUtility::makeInstance" Classes/
grep -r "\$GLOBALS\[" Classes/

# Inclusive language
grep -ri "master\|slave\|blacklist\|whitelist" Classes/ Documentation/

# Backend module checks
ls Configuration/Backend/Modules.php 2>/dev/null || echo "Using deprecated ext_tables.php"
```

## Reference Index

| File | Purpose |
|------|---------|
| `extension-architecture.md` | Directory structure, required files |
| `coding-guidelines.md` | PSR-12, naming conventions |
| `backend-module-v13.md` | Backend module modernization |
| `php-architecture.md` | DI, events, services |
| `testing-standards.md` | PHPUnit, coverage |
| `best-practices.md` | Infrastructure, quality |
| `composer-validation.md` | composer.json requirements |
| `ext-emconf-validation.md` | ext_emconf.php requirements |
| `ext-files-validation.md` | ext_* file validation |
| `v13-deprecations.md` | TYPO3 v13 deprecations |
| `excellence-indicators.md` | Bonus scoring criteria |
| `crowdin-integration.md` | Translation workflow |
| `ter-publishing.md` | TER upload workflow, comment format |
| `report-template.md` | Full report format |

---

*For detailed validation rules, see the reference files in `references/`.*
