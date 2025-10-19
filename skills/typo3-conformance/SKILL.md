---
name: TYPO3 Conformance
description: "Evaluate TYPO3 extensions for conformance to official TYPO3 12/13 LTS standards, coding guidelines (PSR-12, TYPO3 CGL), and architecture patterns. Use when assessing extension quality, generating conformance reports, identifying technical debt, or planning modernization efforts. Evaluates: extension architecture, dependency injection, services configuration, testing coverage, Extbase patterns, and best practices alignment. Supports PHP 8.1-8.4 and provides actionable improvement recommendations with scoring."
license: Complete terms in LICENSE.txt
---

# TYPO3 Extension Conformance Checker

**Purpose:** Evaluate TYPO3 extensions for conformance to official TYPO3 coding standards, architecture patterns, and best practices.

**Activation:** This skill activates when analyzing TYPO3 extensions for standards compliance, code quality, or conformance checking.

## Overview

This skill provides systematic evaluation of TYPO3 extensions against official TYPO3 standards:

1. **Extension Architecture** - File structure, naming conventions, required files
2. **Coding Guidelines** - PSR-12 compliance, TYPO3-specific code style
3. **PHP Architecture** - Dependency injection, services, events, Extbase patterns
4. **Testing Standards** - Unit, functional, and acceptance testing requirements
5. **Best Practices** - Real-world patterns from Tea extension and core standards

## Version Compatibility

**Target Standards:**
- **TYPO3:** 12.4 LTS / 13.x
- **PHP:** 8.1 / 8.2 / 8.3 / 8.4
- **TYPO3 12 LTS:** Supports PHP 8.1 - 8.4
- **TYPO3 13 LTS:** Requires PHP 8.2 - 8.4

**Reference:** See `references/version-requirements.md` for complete version compatibility matrix and migration paths.

## Evaluation Workflow

### Step 1: Initial Assessment

**Identify Extension Context:**
- Extension key and location
- TYPO3 version compatibility (check composer.json)
- Extension type (Extbase plugin, backend module, content element, etc.)
- Scope of evaluation (full extension vs specific components)

**Quick Directory Scan:**
```bash
# Check for presence of key directories
ls -la | grep -E "Classes|Configuration|Resources|Tests|Documentation"

# Verify required files
ls -1 | grep -E "composer.json|ext_emconf.php"

# Check documentation
ls -1 Documentation/ | grep -E "Index.rst|Settings.cfg"
```

### Step 2: File Structure Analysis

**Reference:** `references/extension-architecture.md`

**Check Required Files:**
- [ ] `composer.json` - Complete with PSR-4 autoloading
- [ ] `ext_emconf.php` - Proper metadata structure
- [ ] `Documentation/Index.rst` - Main documentation entry
- [ ] `Documentation/Settings.cfg` - Documentation settings
- [ ] `Classes/` directory exists
- [ ] `Configuration/` directory exists
- [ ] `Resources/` directory exists

**Validate Directory Structure:**

```bash
# Check Classes/ organization
find Classes/ -type d | head -20

# Verify Configuration/ structure
ls -R Configuration/

# Check Resources/ separation
ls -R Resources/Private/ Resources/Public/
```

**Common Issues to Flag:**
- ❌ PHP files in extension root (except ext_* files)
- ❌ Mixed directory naming (Controllers/ vs Controller/)
- ❌ Tests not mirroring Classes/ structure
- ❌ Missing required documentation files
- ❌ Non-standard directory names

**Output Format:**
```markdown
## File Structure Conformance

### ✅ Passed
- composer.json present with PSR-4 autoloading
- Classes/ directory properly organized
- Documentation/ complete with Index.rst and Settings.cfg

### ❌ Failed
- Missing Tests/ directory
- Configuration/Backend/ not found (backend modules using deprecated ext_tables.php)
- Resources/Private/Language/ missing XLIFF files

### ⚠️  Warnings
- Unusual directory: Classes/Helpers/ (should use Utility/)
- ext_tables.php present (consider migrating to Configuration/Backend/)
```

### Step 3: Coding Standards Analysis

**Reference:** `references/coding-guidelines.md`

**PHP Code Style Checks:**

```bash
# Find all PHP files
find Classes/ Tests/ Configuration/ -name "*.php"

# Check for PSR-12 violations (sample)
grep -r "array(" Classes/  # Should use []
grep -r "<?php$" Classes/ | wc -l  # Missing declare(strict_types=1)
```

**Manual Inspection Points:**

**Naming Conventions:**
- Variables/methods: camelCase
- Classes: UpperCamelCase
- Constants: SCREAMING_SNAKE_CASE
- Namespaces: match directory structure

**Code Sample Analysis:**
```php
// Read sample files
cat Classes/Controller/ProductController.php
cat Classes/Domain/Model/Product.php
cat Classes/Domain/Repository/ProductRepository.php
```

**Check for:**
- [ ] `declare(strict_types=1)` at top of all PHP files
- [ ] Proper PHPDoc comments on classes and public methods
- [ ] Type declarations on all properties and parameters
- [ ] Short array syntax `[]` (not `array()`)
- [ ] Proper namespace structure
- [ ] Correct use statements (sorted and grouped)
- [ ] Descriptive method names with verbs
- [ ] Proper indentation (4 spaces, no tabs)

**Output Format:**
```markdown
## Coding Standards Conformance

### ✅ Strengths
- All classes use UpperCamelCase naming
- Proper type declarations on methods
- PHPDoc comments present and complete

### ❌ Violations
- 15 files missing `declare(strict_types=1)`
  - Classes/Controller/ProductController.php:1
  - Classes/Service/CalculationService.php:1
- 8 instances of old array syntax `array()`
  - Classes/Utility/ArrayHelper.php:45
  - Classes/Domain/Model/Product.php:78
- 3 methods missing PHPDoc comments
  - Classes/Service/EmailService.php:calculate()

### ⚠️  Style Issues
- Inconsistent spacing around concatenation operators (12 instances)
- Some variables using snake_case (5 instances)
```

### Step 4: PHP Architecture Evaluation

**Reference:** `references/php-architecture.md`

**Dependency Injection Analysis:**

```bash
# Check for Services.yaml
cat Configuration/Services.yaml

# Find constructors in Controllers/Services
grep -A 10 "public function __construct" Classes/Controller/*.php
grep -A 10 "public function __construct" Classes/Service/*.php
```

**Check for:**
- [ ] `Configuration/Services.yaml` present and properly configured
- [ ] Constructor injection used (not GeneralUtility::makeInstance)
- [ ] PSR-14 event listeners instead of hooks
- [ ] Event classes properly structured (immutable with getters/setters)
- [ ] PSR-15 middlewares if applicable
- [ ] Extbase patterns (models, repositories, controllers)
- [ ] No global state access ($GLOBALS)

**Anti-Pattern Detection:**
```bash
# Find deprecated patterns
grep -r "GeneralUtility::makeInstance" Classes/
grep -r "\$GLOBALS\[" Classes/
grep -r "inject[A-Z]" Classes/  # Method injection (check if justified)
```

**Output Format:**
```markdown
## PHP Architecture Conformance

### ✅ Modern Patterns
- Dependency injection via constructor in all controllers
- PSR-14 events used for extensibility
- Configuration/Services.yaml properly configured
- Extbase repositories extend base Repository class

### ❌ Architecture Issues
- 12 instances of GeneralUtility::makeInstance()
  - Classes/Service/LegacyService.php:45
  - Classes/Utility/DatabaseHelper.php:89
- 5 instances of $GLOBALS access
  - Classes/Controller/ProductController.php:123
- No event listeners found (using deprecated hooks)

### 💡 Recommendations
- Migrate hook implementations to PSR-14 events
- Refactor GeneralUtility::makeInstance() to constructor injection
- Remove global state dependencies
```

### Step 5: Testing Infrastructure Assessment

**Reference:** `references/testing-standards.md`

**Test Coverage Analysis:**

```bash
# Check test structure
ls -R Tests/

# Verify PHPUnit configuration
cat Build/phpunit/UnitTests.xml
cat Build/phpunit/FunctionalTests.xml

# Count test files
find Tests/Unit/ -name "*Test.php" | wc -l
find Tests/Functional/ -name "*Test.php" | wc -l
```

**Evaluate:**
- [ ] Tests/Unit/ mirrors Classes/ structure
- [ ] Tests/Functional/ present with fixtures
- [ ] PHPUnit configuration files present
- [ ] Unit tests extend UnitTestCase
- [ ] Functional tests extend FunctionalTestCase
- [ ] Acceptance tests configured (Codeception)
- [ ] Test coverage >70% for new code

**Sample Test Inspection:**
```php
# Read sample test files
cat Tests/Unit/Service/CalculationServiceTest.php
cat Tests/Functional/Domain/Repository/ProductRepositoryTest.php
```

**Output Format:**
```markdown
## Testing Standards Conformance

### ✅ Test Infrastructure
- PHPUnit configuration files present
- Tests/ directory mirrors Classes/ structure
- Unit tests properly extend UnitTestCase
- Functional tests use fixtures correctly

### ❌ Testing Gaps
- No Tests/Functional/ directory found
- Missing PHPUnit configuration for functional tests
- 15 classes without corresponding unit tests:
  - Classes/Service/EmailService.php
  - Classes/Utility/StringHelper.php
  - Classes/Domain/Repository/CategoryRepository.php

### 📊 Coverage Estimate
- Unit test files: 12
- Classes without tests: 15
- Estimated coverage: ~45% (below 70% recommendation)
```

### Step 6: Best Practices Review

**Reference:** `references/best-practices.md`

**Project Infrastructure:**
- [ ] .editorconfig present
- [ ] .gitignore properly configured
- [ ] CI/CD pipeline (.github/workflows/ or .gitlab-ci.yml)
- [ ] Code quality tools configured (php-cs-fixer, phpstan)
- [ ] README.md with clear instructions
- [ ] LICENSE file present

**Security Practices:**
```bash
# Check for security issues
grep -r "->exec(" Classes/  # SQL injection risk
grep -r "htmlspecialchars" Resources/Private/Templates/  # XSS prevention
grep -r "GeneralUtility::validEmail" Classes/  # Email validation
```

**Documentation Quality:**
```bash
# Check documentation completeness
ls -1 Documentation/ | wc -l
cat Documentation/Index.rst | head -50
```

**Output Format:**
```markdown
## Best Practices Conformance

### ✅ Project Infrastructure
- .editorconfig present
- .gitignore configured properly
- README.md with installation instructions
- GitHub Actions CI/CD pipeline configured

### ❌ Missing Components
- No phpstan.neon configuration
- No .php-cs-fixer configuration
- LICENSE file missing
- Documentation/ incomplete (missing Developer/ section)

### 🔒 Security Review
- ✅ Query parameters properly escaped
- ⚠️  3 instances of direct SQL queries (check for injection risks)
- ✅ Email validation using GeneralUtility::validEmail
- ❌ Missing CSRF tokens in 2 forms
```

## Comprehensive Report Generation

### Final Conformance Report Template

```markdown
# TYPO3 Extension Conformance Report

**Extension:** {extension_name} (v{version})
**Evaluation Date:** {date}
**TYPO3 Compatibility:** {typo3_versions}

---

## Executive Summary

**Overall Conformance Score:** {score}/100

- Extension Architecture: {score}/20
- Coding Guidelines: {score}/20
- PHP Architecture: {score}/20
- Testing Standards: {score}/20
- Best Practices: {score}/20

**Priority Issues:** {count_critical}
**Recommendations:** {count_recommendations}

---

## 1. Extension Architecture ({score}/20)

### ✅ Strengths
- {list strengths}

### ❌ Critical Issues
- {list critical issues with file:line references}

### ⚠️  Warnings
- {list warnings}

### 💡 Recommendations
1. {specific actionable recommendations}

---

## 2. Coding Guidelines ({score}/20)

{repeat same structure}

---

## 3. PHP Architecture ({score}/20)

{repeat same structure}

---

## 4. Testing Standards ({score}/20)

{repeat same structure}

---

## 5. Best Practices ({score}/20)

{repeat same structure}

---

## Priority Action Items

### High Priority (Fix Immediately)
1. {critical issues that break functionality or security}

### Medium Priority (Fix Soon)
1. {important conformance issues}

### Low Priority (Improve When Possible)
1. {minor style and optimization issues}

---

## Detailed Issue List

| Category | Severity | File | Line | Issue | Recommendation |
|----------|----------|------|------|-------|----------------|
| Architecture | Critical | ext_tables.php | - | Using deprecated ext_tables.php | Migrate to Configuration/Backend/Modules.php |
| Coding | High | Classes/Controller/ProductController.php | 12 | Missing declare(strict_types=1) | Add at top of file |
| Architecture | High | Classes/Service/EmailService.php | 45 | Using GeneralUtility::makeInstance() | Switch to constructor injection |
| Testing | Medium | Tests/ | - | No functional tests | Create Tests/Functional/ with fixtures |

---

## Migration Guide

### Migrating from ext_tables.php to Configuration/Backend/

```php
// Before (ext_tables.php) - DEPRECATED
ExtensionUtility::registerModule(...);

// After (Configuration/Backend/Modules.php) - MODERN
return [
    'web_myext' => [
        'parent' => 'web',
        ...
    ],
];
```

### Converting to Constructor Injection

```php
// Before - DEPRECATED
use TYPO3\CMS\Core\Utility\GeneralUtility;
$repository = GeneralUtility::makeInstance(ProductRepository::class);

// After - MODERN
public function __construct(
    private readonly ProductRepository $repository
) {}
```

---

## Conformance Checklist

Use this checklist to track conformance improvements:

**File Structure**
- [ ] composer.json with PSR-4 autoloading
- [ ] Classes/ directory properly organized
- [ ] Configuration/ using modern structure
- [ ] Resources/ separated Private/Public
- [ ] Tests/ mirroring Classes/
- [ ] Documentation/ complete

**Coding Standards**
- [ ] declare(strict_types=1) in all PHP files
- [ ] Type declarations everywhere
- [ ] PHPDoc on all public methods
- [ ] PSR-12 compliant formatting
- [ ] Proper naming conventions

**PHP Architecture**
- [ ] Constructor injection used
- [ ] Configuration/Services.yaml configured
- [ ] PSR-14 events instead of hooks
- [ ] No GeneralUtility::makeInstance()
- [ ] No $GLOBALS access

**Testing**
- [ ] Unit tests present and passing
- [ ] Functional tests with fixtures
- [ ] Test coverage >70%
- [ ] PHPUnit configuration files
- [ ] Acceptance tests (if applicable)

**Best Practices**
- [ ] Code quality tools configured
- [ ] CI/CD pipeline setup
- [ ] Security best practices followed
- [ ] Complete documentation
- [ ] README and LICENSE present

---

## Resources

- **TYPO3 Core API:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/
- **Extension Architecture:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ExtensionArchitecture/
- **Coding Guidelines:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/CodingGuidelines/
- **Testing Documentation:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/
- **Tea Extension (Best Practice):** https://github.com/TYPO3BestPractices/tea
```

## Scoring System

### Overall Score Calculation

Each category (Architecture, Coding, PHP Architecture, Testing, Best Practices) is scored out of 20 points:

**Extension Architecture (20 points)**
- Required files present: 8 points
- Directory structure conformant: 6 points
- Naming conventions followed: 4 points
- No critical violations: 2 points

**Coding Guidelines (20 points)**
- PSR-12 compliance: 8 points
- Type declarations: 4 points
- PHPDoc completeness: 4 points
- Naming conventions: 4 points

**PHP Architecture (20 points)**
- Dependency injection: 8 points
- No deprecated patterns: 6 points
- Modern event system: 4 points
- Service configuration: 2 points

**Testing Standards (20 points)**
- Test coverage >70%: 10 points
- Proper test structure: 6 points
- Configuration files present: 4 points

**Best Practices (20 points)**
- Quality tools configured: 6 points
- CI/CD pipeline: 6 points
- Security practices: 4 points
- Documentation complete: 4 points

### Severity Levels

**Critical (Blocker):**
- Security vulnerabilities
- Broken functionality
- Major architecture violations

**High (Must Fix):**
- Deprecated pattern usage
- Missing required files
- Significant PSR-12 violations

**Medium (Should Fix):**
- Missing tests
- Incomplete documentation
- Minor architecture issues

**Low (Nice to Have):**
- Code style inconsistencies
- Optional quality improvements

## Usage Examples

### Example 1: Quick Conformance Check

```
User: "Check if my TYPO3 extension follows current standards"