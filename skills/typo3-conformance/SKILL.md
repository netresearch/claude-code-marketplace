---
name: typo3-conformance
description: "Evaluate TYPO3 extensions for conformance to TYPO3 12/13 LTS standards, coding guidelines (PSR-12), and architecture patterns. Use when assessing extension quality, generating conformance reports, identifying technical debt, or planning modernization. Validates: extension architecture, composer.json, ext_emconf.php, ext_* files, v13 deprecations, backend module v13 compliance (ES6 modules, DocHeader, Modal/Notification APIs, Module.html layout, ARIA, extension key consistency, CSRF, icons), dependency injection, services, testing, Extbase patterns, Crowdin, GitHub workflows. Dual scoring (0-100 base + 0-22 excellence). Delegates to typo3-tests and typo3-docs skills for deep analysis. PHP 8.1-8.4 support."
license: Complete terms in LICENSE.txt
---

# TYPO3 Extension Conformance Checker

**Purpose:** Evaluate TYPO3 extensions for conformance to official TYPO3 coding standards, architecture patterns, and best practices.

**Activation:** This skill activates when analyzing TYPO3 extensions for standards compliance, code quality, or conformance checking.

## Skill Ecosystem Integration

Delegate to specialized skills for deep domain analysis:

**🔧 typo3-tests** (https://github.com/netresearch/typo3-testing-skill)
- Deep PHPUnit configuration analysis
- Test quality patterns (AAA, mocking, fixtures)
- TYPO3 Testing Framework validation
- Accurate coverage calculation
- Test anti-pattern detection

**📚 typo3-docs** (https://github.com/netresearch/typo3-docs-skill)
- RST syntax and TYPO3 directive validation
- Documentation rendering with Docker
- Modern tooling detection (guides.xml, screenshots.json)
- Cross-reference integrity checks
- Official TYPO3 documentation standards

**Delegation Strategy:**
- **Surface-level checks:** Perform directly with this skill
- **Deep analysis:** Delegate to specialized skills when available
- **Fallback:** Apply basic validation if specialized skills unavailable
- **Integration:** Incorporate results into conformance scoring

## Version Compatibility

**Target Standards:**
- **TYPO3:** 12.4 LTS / 13.x
- **PHP:** 8.1 / 8.2 / 8.3 / 8.4
- **TYPO3 12 LTS:** Supports PHP 8.1 - 8.4
- **TYPO3 13 LTS:** Requires PHP 8.2 - 8.4

**Reference:** See `references/version-requirements.md` for complete version compatibility matrix and migration paths.

## Critical Validation References

**New Advanced Validation Guides:**
- **`references/runtests-validation.md`** - Validate Build/Scripts/runTests.sh against Tea extension reference
- **`references/development-environment.md`** - Validate DDEV/Docker development environment setup
- **`references/directory-structure.md`** - Validate .Build/ vs Build/ directory separation

These guides provide line-by-line validation strategies, automated validation scripts, and scoring methodologies to ensure comprehensive conformance checks.

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
- [ ] **Inclusive language** - no problematic terminology

**Inclusive Language Check:**

```bash
# Check for non-inclusive terminology
grep -ri "master\|slave\|blacklist\|whitelist\|sanity" Classes/ Documentation/ --include="*.php" --include="*.rst" --include="*.md"
```

**Problematic Terms to Avoid:**
- ❌ "master/slave" → ✅ "primary/replica", "leader/follower", "main/secondary"
- ❌ "blacklist/whitelist" → ✅ "blocklist/allowlist", "denylist/permitlist", "exclusion list/inclusion list"
- ❌ "sanity check" → ✅ "confidence check", "validation check", "coherence check"
- ❌ "dummy" → ✅ "placeholder", "sample", "test"
- ❌ "grandfathered" → ✅ "legacy status", "existing entitlement"

**TYPO3 Community Values:**
The TYPO3 community is committed to inclusive language that welcomes all contributors. Code, comments, and documentation should use terminology that is respectful and professional.

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
- **5 instances of non-inclusive terminology**
  - Classes/Service/FilterService.php:12 - "whitelist" → use "inclusion list" or "allowlist"
  - Classes/Service/FilterService.php:45 - "blacklist" → use "exclusion list" or "blocklist"
  - Documentation/Configuration/Index.rst:78 - "master configuration" → use "primary configuration" or "main configuration"

### ⚠️  Style Issues
- Inconsistent spacing around concatenation operators (12 instances)
- Some variables using snake_case (5 instances)
```

### Step 3.5: Backend Module v13 Compliance (If Applicable)

**Reference:** `references/backend-module-v13.md`

**Trigger:** Extension contains backend modules (Configuration/Backend/Modules.php or ext_tables.php with registerModule)

**Critical Checks:**

**Extension Key Consistency:**
```bash
# Check for mixed extension keys
grep -rn "EXT:.*/" Resources/Private/Templates/ | grep -v "EXT:${EXTENSION_KEY}/"

# Verify JavaScript uses correct name
grep -rn "alert\|console" Resources/Public/JavaScript/
```

**JavaScript Modernization:**
```bash
# Check for inline JavaScript (VIOLATION)
grep -rn "FooterAssets" Resources/Private/Templates/
grep -rn "<script" Resources/Private/Templates/

# Verify ES6 module exists
ls Resources/Public/JavaScript/BackendModule.js

# Check Modal/Notification API usage
grep -E "Modal\.confirm|Notification\.(success|error)" Resources/Public/JavaScript/*.js
```

**Layout Pattern:**
```bash
# Verify Module.html layout
ls Resources/Private/Layouts/Module.html

# Check all templates use Module layout
grep -n "f:layout name=" Resources/Private/Templates/Backend/**/*.html
```

**DocHeader Integration:**
```bash
# Check IconFactory injection
grep "IconFactory" Classes/Controller/Backend/*.php

# Verify DocHeader buttons
grep "addDocHeaderButtons\|makeLinkButton\|makeShortcutButton" Classes/Controller/Backend/*.php
```

**CSRF Protection:**
```bash
# Check for hardcoded URLs (VIOLATION)
grep -rn '"/typo3/' Resources/

# Verify uriBuilder usage
grep "uriFor(" Classes/Controller/Backend/*.php
```

**Accessibility:**
```bash
# Check ARIA labels
grep -rn "aria-label\|role=" Resources/Private/Templates/
```

**Icon Registration:**
```bash
# Verify modern icon registration
ls Configuration/Icons.php

# Check for deprecated IconRegistry (VIOLATION)
grep -rn "IconRegistry" ext_localconf.php
```

**Scoring Impact:**
- Extension key consistency: -5 points if violations found
- Inline JavaScript: -8 points (non-CSP-compliant)
- Missing DocHeader: -4 points (poor UX)
- Hardcoded URLs: -6 points (security risk)
- No accessibility: -3 points (WCAG non-compliant)
- Deprecated icon registration: -2 points

**Read `references/backend-module-v13.md` for:**
- Complete before/after code examples
- ES6 module architecture patterns
- Modal/Notification API usage
- WCAG 2.1 accessibility requirements
- 10-phase modernization checklist
- Real-world modernization case study (45/100 → 95/100)

---

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

**DELEGATION STRATEGY: For Deep Testing Analysis**

When Testing Standards category needs comprehensive validation, use skill delegation:

```
🔧 Use /skill typo3-tests (if available) for deep analysis:
  - PHPUnit configuration quality and best practices
  - Test code patterns (AAA, proper mocking, fixtures)
  - TYPO3 Testing Framework usage validation
  - Functional test database handling
  - Accurate test coverage calculation
  - Test quality metrics and anti-patterns
  - Integration with TYPO3 core testing infrastructure

  Return: Detailed testing conformance report with specific issues
```

**Fallback: If typo3-tests skill unavailable, perform basic validation:**

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

**Basic Evaluation Checklist:**
- [ ] Tests/Unit/ mirrors Classes/ structure
- [ ] Tests/Functional/ present with fixtures
- [ ] PHPUnit configuration files present
- [ ] Unit tests extend UnitTestCase
- [ ] Functional tests extend FunctionalTestCase
- [ ] Acceptance tests configured (Codeception)
- [ ] Test coverage >70% for new code

**Note:** Basic validation provides surface-level checks. For production-ready conformance reports, delegate to typo3-tests skill for comprehensive analysis

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

### Step 6: Standards Application

**Reference:** `references/best-practices.md`

**When evaluating build scripts** (see `references/runtests-validation.md`):
1. Verify Build/Scripts/runTests.sh exists and matches Tea extension reference
2. Confirm PHP_VERSION default matches composer.json minimum requirement
3. Validate TYPO3_VERSION default matches composer.json target version
4. Check PHP version regex includes only supported versions (8.1-8.4)
5. Ensure database version lists are current (no EOL versions)
6. Verify network name is customized (not "friendsoftypo3-tea")
7. Validate test suite paths match actual directory structure

**When evaluating development environment** (see `references/development-environment.md`):
1. Locate DDEV configuration (.ddev/config.yaml) or Docker Compose alternative
2. When DDEV present, verify type set to 'typo3'
3. Confirm DDEV PHP version matches composer.json minimum
4. Validate DDEV docroot matches composer.json web-dir
5. Check database is MariaDB 10.11+ or MySQL 8.0+
6. Flag missing DevContainer configuration as optional improvement

**When evaluating directory structure** (see `references/directory-structure.md`):
1. Verify Build/ directory exists with committed configuration
2. Confirm .Build/ is fully gitignored (entire directory)
3. Flag any .Build/ files committed to git as critical violation
4. Check cache files are in .Build/, not Build/
5. Validate Composer paths reference .Build/ (bin-dir, vendor-dir, web-dir)
6. Verify quality tool configs reference .Build/ for cache

**When evaluating project infrastructure**:
1. Check .editorconfig presence for consistent code formatting
2. Verify .gitignore properly configured with standard exclusions
3. Locate CI/CD pipeline (.github/workflows/ or .gitlab-ci.yml)
4. Confirm code quality tools configured (php-cs-fixer, phpstan)
5. Validate README.md provides clear setup instructions
6. Ensure LICENSE file present with appropriate open-source license
7. Check GitHub issue templates (.github/ISSUE_TEMPLATE/config.yml)
8. Verify TER publishing workflow (.github/workflows/publish-to-ter.yml)

**Security Practices:**
```bash
# Check for security issues
grep -r "->exec(" Classes/  # SQL injection risk
grep -r "htmlspecialchars" Resources/Private/Templates/  # XSS prevention
grep -r "GeneralUtility::validEmail" Classes/  # Email validation
```

**Documentation Quality:**

**DELEGATION STRATEGY: For Deep Documentation Analysis**

When Documentation Excellence validation is needed, use skill delegation:

```
📚 Use /skill typo3-docs (if available) for deep analysis:
  - RST syntax validation and TYPO3 directive compliance
  - Documentation structure conformance (Index.rst, Settings.cfg)
  - TYPO3 documentation standards (guides.xml, screenshots.json)
  - Rendering validation with Docker (official TYPO3 render-guides)
  - Intersphinx references validation
  - Code example syntax validation
  - Cross-reference integrity
  - Modern documentation tooling detection

  Return: Comprehensive documentation conformance report
```

**Fallback: If typo3-docs skill unavailable, perform basic validation:**

```bash
# Check documentation completeness
ls -1 Documentation/ | wc -l
cat Documentation/Index.rst | head -50

# Check for required files
ls Documentation/Settings.cfg Documentation/guides.xml 2>/dev/null

# Count RST files for excellence scoring
find Documentation/ -name "*.rst" | wc -l
```

**Note:** Basic validation only checks file existence. For production-ready documentation conformance, delegate to typo3-docs skill for comprehensive RST validation and rendering checks

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

**Base Conformance Score:** {score}/100
**Excellence Indicators:** {excellence_score}/20 (Bonus)
**Total Score:** {total_score}/120

### Base Conformance Breakdown (0-100 points)
- Extension Architecture: {score}/20
- Coding Guidelines: {score}/20
- PHP Architecture: {score}/20
- Testing Standards: {score}/20
- Best Practices: {score}/20

### Excellence Indicators (0-20 bonus points)
- Community & Internationalization: {score}/6
- Advanced Quality Tooling: {score}/7
- Documentation Excellence: {score}/4
- Extension Configuration: {score}/3

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

## Pre-Evaluation Validation Procedures

Execute these validation steps systematically during conformance evaluation:

**File Structure Validation**
1. Verify composer.json exists with PSR-4 autoloading configuration
2. Confirm Classes/ directory follows namespace hierarchy
3. Check Configuration/ uses modern structure (no ext_tables.php dependencies)
4. Validate Resources/ separates Private/ and Public/ correctly
5. Ensure Tests/ mirrors Classes/ structure exactly
6. Confirm Documentation/ contains Index.rst and Settings.cfg

**Coding Standards Validation**
1. Scan all PHP files for declare(strict_types=1) at file start
2. Verify type declarations on all properties, parameters, and return types
3. Check PHPDoc blocks on all public methods and classes
4. Run PSR-12 compliance validation via PHPCS
5. Validate naming conventions (classes, methods, variables)

**PHP Architecture Validation**
1. Verify constructor injection used throughout codebase
2. Check Configuration/Services.yaml exists and configures services
3. Confirm PSR-14 events replace deprecated hooks
4. Search for GeneralUtility::makeInstance() usage (flag as violation)
5. Search for $GLOBALS access (flag as violation)

**Testing Validation**
1. Verify unit tests exist and execute successfully
2. Check functional tests include proper fixtures
3. Calculate test coverage (target >70%)
4. Confirm PHPUnit configuration files present (UnitTests.xml, FunctionalTests.xml)
5. Check acceptance tests if web interface present

**Standards Application Validation**
1. Verify development environment configured (DDEV or Docker Compose)
2. Check Build/Scripts/runTests.sh exists with accurate configuration
3. Validate directory structure (.Build/ vs Build/) separation
4. Confirm code quality tools configured (phpstan, php-cs-fixer)
5. Verify CI/CD pipeline setup (.github/workflows/ or .gitlab-ci.yml)
6. Review security practices implementation
7. Validate documentation completeness
8. Confirm README.md and LICENSE files present

---

## Reference Material Usage

**When checking extension architecture patterns**, read `references/extension-architecture.md` for:
- Standard directory structures and naming conventions
- Required files and their purposes
- PSR-4 autoloading configuration examples

**When validating coding guidelines**, read `references/coding-guidelines.md` for:
- PSR-12 compliance requirements
- TYPO3-specific code style rules
- Type declaration standards

**When evaluating backend modules**, read `references/backend-module-v13.md` for:
- Extension key consistency validation
- JavaScript modernization (ES6 modules, no inline scripts)
- TYPO3 Modal and Notification API patterns
- DocHeader integration (ButtonBar, IconFactory)
- Module.html layout requirements
- ARIA accessibility standards
- Icon registration (Configuration/Icons.php)
- CSRF protection via uriBuilder
- 10-phase modernization checklist
- Real-world case study (45/100 → 95/100 compliance)

**When evaluating PHP architecture**, read `references/php-architecture.md` for:
- Dependency injection patterns
- Service configuration examples
- PSR-14 event system usage

**When analyzing testing standards**, read `references/testing-standards.md` for:
- PHPUnit configuration patterns
- Test structure requirements
- Coverage calculation methods

**When applying best practices**, read `references/best-practices.md` for:
- Development environment setup patterns
- Build script validation criteria
- Directory structure standards

**For build script validation**, read `references/runtests-validation.md` for:
- Line-by-line runTests.sh validation
- Tea extension reference comparison
- Common configuration errors

**For development environment checks**, read `references/development-environment.md` for:
- DDEV configuration standards
- Docker Compose alternatives
- PHP and database version requirements

**For directory structure evaluation**, read `references/directory-structure.md` for:
- .Build/ vs Build/ separation rules
- Composer path configuration
- Gitignore patterns

**For excellence indicators**, read `references/excellence-indicators.md` for:
- Crowdin integration validation
- Advanced quality tooling detection
- Documentation excellence criteria

**For Crowdin integration**, read `references/crowdin-integration.md` for:
- TYPO3-compliant crowdin.yml patterns
- Translation workflow validation
- Common misconfigurations

**For hooks and events migration**, read `references/hooks-and-events.md` for:
- PSR-14 event patterns
- Deprecated hook identification
- Migration strategies

**When encountering official documentation**, visit:
- TYPO3 Core API: https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/
- Extension Architecture: https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ExtensionArchitecture/
- Coding Guidelines: https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/CodingGuidelines/
- Testing Documentation: https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/
- Tea Extension (Best Practice): https://github.com/TYPO3BestPractices/tea
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
- Development environment (DDEV/Docker): 6 points
  - DDEV configuration present: 4 points
  - Configuration matches extension requirements: 2 points
  - OR Docker Compose alternative: 3 points
- Build scripts (runTests.sh): 6 points
  - Script present and executable: 2 points
  - PHP/TYPO3 versions match extension: 3 points
  - Database versions current: 1 point
- Directory structure (.Build/ vs Build/): 4 points
  - .Build/ properly gitignored: 2 points
  - Cache files in correct location: 1 point
  - Composer paths aligned: 1 point
- Quality tools configured: 2 points
- Documentation complete: 2 points

**Note:** Previously this category scored only quality tools (6) and documentation (4). The new comprehensive approach validates development environment setup, build script accuracy, and directory structure standards, providing more thorough conformance assessment.

### Excellence Indicators (Bonus 0-20 points)

**Reference:** `references/excellence-indicators.md`

Excellence indicators are **optional features** that demonstrate exceptional quality and community engagement. Extensions are NOT penalized for missing these features - they provide bonus points only.

**Total Possible Score: 122 points** (100 base conformance + 22 excellence bonus)

**Category 1: Community & Internationalization (0-6 points)**
- Crowdin integration: 0-2 points
  - Basic (crowdin.yml exists): +1 point
  - TYPO3-compliant (preserve_hierarchy, wildcards, proper patterns, no download job): +2 points
  - See `references/crowdin-integration.md` for comprehensive validation
- GitHub issue templates (.github/ISSUE_TEMPLATE/): +1 point
- .gitattributes with export-ignore: +1 point
- Professional README badges (stability, versions, downloads, CI): +2 points

**Category 2: Advanced Quality Tooling (0-9 points)**
- Fractor configuration (Build/fractor/fractor.php): +2 points
- TYPO3 CodingStandards package (typo3/coding-standards in composer.json): +2 points
- StyleCI integration (.styleci.yml): +1 point
- Makefile with self-documenting help: +1 point
- CI testing matrix (multiple PHP/TYPO3 versions): +1 point
- TER publishing workflow (.github/workflows/publish-to-ter.yml): +2 points

**Category 3: Documentation Excellence (0-4 points)**
- 50-99 RST files in Documentation/: +1 point
- 100-149 RST files: +2 points
- 150+ RST files: +3 points
- Modern documentation tooling (guides.xml, screenshots.json): +1 point

**Category 4: Extension Configuration (0-3 points)**
- ext_conf_template.txt with proper categorization: +1 point
- Composer documentation scripts (doc-init, doc-make, doc-watch): +1 point
- Multiple Configuration/Sets/ presets (for different use cases): +1 point

**Excellence Score Interpretation:**
- **0-5 points:** Standard extension (meets requirements)
- **6-11 points:** Good practices (actively maintained)
- **12-16 points:** Excellent quality (community reference level)
- **17-22 points:** Outstanding (georgringer/news level)

**Example Report Format:**

```markdown
## TYPO3 Extension Conformance Report

**Extension:** my_extension (v2.0.0)

---

### Score Summary

**Base Conformance:** 94/100
- Extension Architecture: 18/20
- Coding Guidelines: 20/20
- PHP Architecture: 18/20
- Testing Standards: 18/20
- Best Practices: 20/20

**Excellence Indicators:** 14/22 (Bonus)
- Community & Internationalization: 5/6
  - ✅ Crowdin integration (+2)
  - ✅ Professional README badges (+2)
  - ✅ GitHub issue templates (+1)
  - ❌ No .gitattributes export-ignore

- Advanced Quality Tooling: 7/9
  - ✅ Fractor configuration (+2)
  - ✅ TYPO3 CodingStandards (+2)
  - ✅ Makefile with help (+1)
  - ✅ TER publishing workflow (+2)
  - ❌ No StyleCI
  - ❌ No CI testing matrix

- Documentation Excellence: 2/4
  - ✅ 75 RST files (+1)
  - ✅ Modern tooling (guides.xml) (+1)

- Extension Configuration: 1/3
  - ✅ Composer doc scripts (+1)
  - ❌ No ext_conf_template.txt
  - ❌ Only one Configuration/Sets/ preset

**Total Score:** 108/122

**Rating:** Excellent - This extension demonstrates strong conformance and excellent quality practices.
```

**Important Notes:**
- Base conformance (0-100) is MANDATORY - this is pass/fail criteria
- Excellence indicators (0-22) are OPTIONAL - bonus points for exceptional quality
- Extensions scoring 100/100 base are fully conformant, regardless of excellence score
- Excellence indicators identify community reference extensions

**📚 When Documentation/ is Missing or Incomplete:**

If conformance check reveals missing or incomplete documentation (0-1 points in Documentation Excellence):

**Recommended Next Step:**
```
📚 Use typo3-docs skill to create comprehensive documentation:
   - Creates complete Documentation/ structure (8 sections)
   - Follows modern TYPO3 13.x standards
   - Uses card-grid navigation (not plain toctree)
   - Applies confval directives for configuration
   - Includes Settings.cfg and proper RST structure
   - Ready for docs.typo3.org deployment

   After creation: Re-run conformance check to verify improvement
```

**Documentation is the most common conformance gap** - extensions often score 90-95/100 with 0/4 documentation. Creating proper documentation typically improves score to 94-99/100 base + 1-2/20 excellence.

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