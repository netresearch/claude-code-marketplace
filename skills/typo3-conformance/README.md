# TYPO3 Extension Conformance Checker

A comprehensive Claude Code skill for evaluating TYPO3 extensions against official TYPO3 coding standards, architecture patterns, and best practices.

## Overview

This skill enables systematic evaluation of TYPO3 extensions for conformance to official TYPO3 standards.

### Skill Ecosystem Integration

This conformance checker acts as an **orchestrator** that delegates to specialized skills for deep domain analysis:

**🔧 Testing Analysis: typo3-tests**
- Repository: https://github.com/netresearch/typo3-testing-skill
- Expertise: Deep PHPUnit configuration analysis, test quality patterns, TYPO3 Testing Framework validation
- Integration: Delegated for Testing Standards category (20 points)

**📚 Documentation Analysis: typo3-docs**
- Repository: https://github.com/netresearch/typo3-docs-skill
- Expertise: RST validation, TYPO3 documentation standards, rendering validation with Docker
- Integration: Delegated for Documentation Excellence (bonus category)

**Delegation Benefits:**
- **Depth:** Each skill provides domain expertise beyond surface-level checks
- **Accuracy:** Specialized validation reduces false positives/negatives
- **Modularity:** Skills can be used independently or together
- **Maintainability:** Each skill focuses on single responsibility

**Fallback Strategy:**
- Surface-level checks performed if specialized skills unavailable
- Basic validation ensures conformance reports always generate
- Full accuracy requires all ecosystem skills installed

### Standards Checked

| Standard | Version/Specification |
|----------|----------------------|
| **TYPO3 Core** | 12.4 LTS / 13.x |
| **PHP** | 8.1 / 8.2 / 8.3 / 8.4 |
| **Coding Style** | PSR-12 (Extended Coding Style) |
| **Architecture** | Dependency Injection (PSR-11), PSR-14 Events, PSR-15 Middleware |
| **Testing** | PHPUnit 10+, TYPO3 Testing Framework |
| **Documentation** | reStructuredText (RST), TYPO3 Documentation Standards |

### Conformance Areas

- **Extension Architecture** - File structure, naming conventions, required files
- **Coding Guidelines** - PSR-12 compliance, TYPO3-specific code style
- **PHP Architecture** - Dependency injection, services, events, Extbase patterns
- **Testing Standards** - Unit, functional, and acceptance testing requirements
- **Best Practices** - Real-world patterns from Tea extension and core standards

## Features

### Automated Validation Scripts

- ✅ **check-conformance.sh** - Main orchestration script
- 📁 **check-file-structure.sh** - File structure and directory validation
- 📝 **check-coding-standards.sh** - PSR-12 and TYPO3 code style checks
- 🏗️  **check-architecture.sh** - Dependency injection and architecture patterns
- 🧪 **check-testing.sh** - Testing infrastructure and coverage analysis
- 📊 **generate-report.sh** - Comprehensive conformance report generation

### Reference Documentation

**Core Standards:**
- **version-requirements.md** - Official TYPO3 and PHP version compatibility matrix
- **extension-architecture.md** - TYPO3 file structure standards
- **coding-guidelines.md** - PSR-12 and TYPO3 code style guide
- **php-architecture.md** - Dependency injection and architectural patterns
- **testing-standards.md** - Unit, functional, and acceptance testing
- **best-practices.md** - Real-world patterns and project infrastructure

**Advanced Validation Guides:**
- **runtests-validation.md** - Validate Build/Scripts/runTests.sh against Tea extension reference
- **development-environment.md** - Validate DDEV/Docker development environment setup
- **directory-structure.md** - Validate .Build/ vs Build/ directory separation and organization

**Excellence Indicators:**
- **excellence-indicators.md** - Optional quality features for exceptional extensions (0-20 bonus points)
  - Community & Internationalization: Crowdin, issue templates, .gitattributes, README badges
  - Advanced Quality Tooling: Fractor, TYPO3 CodingStandards, StyleCI, Makefile, CI matrix
  - Documentation Excellence: 100+ RST files, modern tooling (guides.xml, screenshots.json)
  - Extension Configuration: ext_conf_template.txt, composer doc scripts, multiple Sets

**Secondary References:**
- **georgringer/news** - Community reference extension demonstrating excellence patterns

### Quality Tool Configuration Templates

Production-ready configuration templates based on [TYPO3 Best Practices (Tea Extension)](https://github.com/TYPO3BestPractices/tea):

- **Build/phpstan/phpstan.neon** - PHPStan Level 10 with advanced security and type safety
- **Build/rector/rector.php** - Automated TYPO3 migrations and refactoring
- **Build/php-cs-fixer/php-cs-fixer.php** - TYPO3 coding standards with parallel execution
- **Build/composer-unused/composer-unused.php** - Dependency health monitoring
- **Build/typoscript-lint/TypoScriptLint.yml** - TypoScript quality enforcement
- **Build/eslint/.eslintrc.json** - JavaScript/TypeScript linting
- **Build/stylelint/.stylelintrc.json** - CSS/SCSS quality checks

All templates are available in [`templates/Build/`](templates/Build/) and ready for direct use.

## Advanced Code Quality Tools

### PHPStan Advanced Configuration

PHPStan Level 10 represents the highest level of static analysis available, providing comprehensive type safety, security enforcement, and code quality checks. Level 10 enables bleeding-edge rules for maximum strictness and early adoption of future PHPStan features.

#### Key Features

**Type Coverage Enforcement**

The configuration enforces 100% type coverage for parameters and return types, with 95% coverage for properties. This eliminates ambiguity and enables better IDE support:

```yaml
type_coverage:
  return_type: 100  # Every function must declare return type
  param_type: 100   # Every parameter must have type hint
  property_type: 95 # 95% of class properties must be typed
```

**Cognitive Complexity Limits**

Complexity limits prevent unmaintainable code by enforcing function and class complexity boundaries:

```yaml
cognitive_complexity:
  class: 10      # Maximum complexity score per class
  function: 5    # Maximum complexity score per function
```

Functions exceeding complexity limits should be refactored into smaller, focused methods. This improves testability and reduces bug density.

**Type Perfection Mode**

Advanced type safety features eliminate common type-related issues:

```yaml
type_perfect:
  no_mixed_property: true  # Prevents mixed type pollution
  no_mixed_caller: true    # Enforces concrete types in method calls
  null_over_false: true    # Prefers nullable types over boolean returns
  narrow_param: true       # Uses most specific parameter types
  narrow_return: true      # Uses most specific return types
```

**Security-Focused Disallowed Patterns**

The configuration integrates `spaze/phpstan-disallowed-calls` to prevent security vulnerabilities:

1. **PSR-7 Enforcement**: Disallows superglobals ($_GET, $_POST, $_SERVER, etc.), enforcing PSR-7 ServerRequestInterface usage
2. **Debug Function Prevention**: Blocks var_dump(), debug(), dd() to prevent information disclosure
3. **Legacy API Prevention**: Disallows deprecated functions like header() in favor of PSR-7 responses

Example violation and fix:

```php
// ❌ PHPStan Error: Use PSR-7 ServerRequestInterface instead
public function processForm(): void
{
    $username = $_POST['username'];
}

// ✅ Correct PSR-7 Implementation
public function processForm(ServerRequestInterface $request): void
{
    $parsedBody = $request->getParsedBody();
    $username = $parsedBody['username'] ?? '';
}
```

#### Setup Instructions

1. **Install Dependencies**

```bash
composer require --dev phpstan/phpstan:^1.12
composer require --dev phpstan/extension-installer:^1.4
composer require --dev saschaegerer/phpstan-typo3:^1.10
composer require --dev spaze/phpstan-disallowed-calls:^3.4
```

2. **Copy Configuration Template**

```bash
mkdir -p Build/phpstan
cp ~/.claude/skills/typo3-conformance/templates/Build/phpstan/phpstan.neon Build/phpstan/
cp ~/.claude/skills/typo3-conformance/templates/Build/phpstan/phpstan-baseline.neon Build/phpstan/
```

3. **Customize for Your Extension**

Edit `Build/phpstan/phpstan.neon`:
- Adjust `phpVersion` to match your ext_emconf.php constraint
- Modify `paths` if you have non-standard directories
- Update `type_coverage.property_type` if 95% is too strict initially

4. **Generate Baseline** (for existing projects)

```bash
vendor/bin/phpstan analyze --generate-baseline Build/phpstan/phpstan-baseline.neon
```

This captures existing violations, allowing gradual improvement without blocking development.

5. **Add Composer Script**

```json
{
  "scripts": {
    "ci:php:stan": "phpstan analyze --configuration Build/phpstan/phpstan.neon --no-progress"
  }
}
```

6. **Integrate with CI**

```yaml
# .github/workflows/ci.yml
- name: PHPStan Analysis
  run: composer ci:php:stan
```

#### Baseline Management

The baseline file captures known violations to prevent regression. As code improves, regenerate the baseline:

```bash
# Remove baseline to see all current violations
rm Build/phpstan/phpstan-baseline.neon
vendor/bin/phpstan analyze --configuration Build/phpstan/phpstan.neon

# Fix violations, then regenerate baseline for remaining issues
vendor/bin/phpstan analyze --generate-baseline Build/phpstan/phpstan-baseline.neon
```

**Best Practice**: Treat baseline regeneration as a quality gate. Each sprint, dedicate time to reducing baseline entries rather than expanding it.

#### Progressive Adoption

For extensions not yet at Level 10, adopt progressively:

1. Start at Level 6, establish baseline
2. Increase to Level 7, fix new violations
3. Add type_coverage with 80% thresholds
4. Increase to Level 8, fix violations
5. Add cognitive_complexity limits
6. Reach Level 9, add type_perfect rules
7. Increase to Level 10 for bleeding-edge rules
8. Gradually increase type_coverage to 100%

### Rector Integration

Rector provides automated refactoring and TYPO3 version migration capabilities, significantly reducing manual upgrade effort. The tea extension demonstrates comprehensive Rector integration for both PHP and TYPO3 modernization.

#### Core Capabilities

**TYPO3 Version Migration**

Rector automates the majority of breaking changes between TYPO3 versions:

```php
->withSets([
    Typo3LevelSetList::UP_TO_TYPO3_12,  // Applies all migrations up to TYPO3 12
])
```

Available migration sets:
- `UP_TO_TYPO3_11` - Migrates from TYPO3 v10 to v11
- `UP_TO_TYPO3_12` - Migrates from TYPO3 v10/11 to v12
- `UP_TO_TYPO3_13` - Migrates from TYPO3 v10/11/12 to v13

Each set includes dozens of automated transformations handling:
- Namespace changes and class renames
- Method signature updates
- Deprecated API replacements
- Configuration file format updates

**ExtEmConfRector - Automatic Constraint Maintenance**

The `ExtEmConfRector` automatically updates `ext_emconf.php` version constraints based on your configuration:

```php
->withConfiguredRule(ExtEmConfRector::class, [
    ExtEmConfRector::PHP_VERSION_CONSTRAINT => '8.2.0-8.5.99',
    ExtEmConfRector::TYPO3_VERSION_CONSTRAINT => '12.4.0-12.4.99',
])
```

When you migrate to TYPO3 v13, simply update the configuration:

```php
ExtEmConfRector::TYPO3_VERSION_CONSTRAINT => '13.0.0-13.99.99',
```

Rector will automatically update your `ext_emconf.php` during the next run, ensuring version constraints remain synchronized with code changes.

**PHPUnit Modernization**

The PHPUnit set modernizes test code to current best practices:

```php
->withSets([
    PHPUnitSetList::PHPUNIT_100,  // PHPUnit 10+ syntax
])
```

Transformations include:
- `@expectedException` annotations → `$this->expectException()`
- `assertContains()` for strings → `assertStringContainsString()`
- Namespace updates for PHPUnit 10+ compatibility
- Test method visibility updates

**Code Quality Improvements**

TYPO3-specific code quality rules enforce best practices:

```php
->withSets([
    Typo3SetList::CODE_QUALITY,
    Typo3SetList::GENERAL,
])
```

Example transformations:

```php
// ❌ Before: Implicit global variable access
function myFunction() {
    global $TYPO3_CONF_VARS;
    return $TYPO3_CONF_VARS['SYS']['sitename'];
}

// ✅ After: Explicit global declaration
function myFunction() {
    return $GLOBALS['TYPO3_CONF_VARS']['SYS']['sitename'];
}
```

#### Migration Workflow

**1. Check Mode (Dry Run)**

Always start with a dry run to preview changes:

```bash
composer ci:rector -- --dry-run
```

This shows what Rector would change without modifying files, allowing review before application.

**2. Apply Changes**

After reviewing, apply transformations:

```bash
composer ci:rector
```

**3. Validate Results**

After Rector runs, validate the changes:

```bash
# Check for syntax errors
composer ci:php:lint

# Run static analysis
composer ci:php:stan

# Run tests to ensure behavior unchanged
composer ci:tests:unit
composer ci:tests:functional
```

**4. Iterative Refinement**

For large migrations, use Rector's `--skip` option to exclude problematic rules temporarily:

```php
->withSkip([
    SomeProblematicRector::class => [
        __DIR__ . '/../../Classes/Legacy/',
    ],
])
```

Fix high-value issues first, then progressively enable more rules.

#### Setup Instructions

1. **Install Dependencies**

```bash
composer require --dev rector/rector:^1.2
composer require --dev ssch/typo3-rector:^2.9
```

For testing framework support:
```bash
composer require --dev ssch/typo3-rector-testing-framework:^2.0
```

2. **Copy Configuration Template**

```bash
mkdir -p Build/rector
cp ~/.claude/skills/typo3-conformance/templates/Build/rector/rector.php Build/rector/
```

3. **Customize Configuration**

Edit `Build/rector/rector.php`:

```php
return RectorConfig::configure()
    ->withPhpVersion(PhpVersion::PHP_82)  // Match your minimum PHP version
    ->withSets([
        Typo3LevelSetList::UP_TO_TYPO3_12,  // Your target TYPO3 version
    ])
    ->withConfiguredRule(ExtEmConfRector::class, [
        ExtEmConfRector::PHP_VERSION_CONSTRAINT => '8.2.0-8.5.99',
        ExtEmConfRector::TYPO3_VERSION_CONSTRAINT => '12.4.0-12.4.99',
    ]);
```

4. **Add Composer Scripts**

```json
{
  "scripts": {
    "ci:rector": "rector process --config Build/rector/rector.php --no-progress",
    "fix:rector": "rector process --config Build/rector/rector.php"
  }
}
```

5. **Integrate with CI**

```yaml
# .github/workflows/ci.yml
- name: Rector Check
  run: composer ci:rector -- --dry-run
```

#### TYPO3 Version Upgrade Strategy

When upgrading between major TYPO3 versions:

1. **Prepare**: Review TYPO3 changelog for breaking changes
2. **Update Rector**: Ensure ssch/typo3-rector supports target version
3. **Configure**: Update `Typo3LevelSetList` to target version
4. **Dry Run**: `composer ci:rector -- --dry-run` to preview changes
5. **Backup**: Commit current state or create backup
6. **Apply**: `composer ci:rector` to apply transformations
7. **Manual Review**: Not all changes can be automated - review diff carefully
8. **Test**: Run full test suite, manual testing for critical functionality
9. **Update Constraints**: Verify ext_emconf.php constraints updated correctly
10. **Document**: Note any manual changes required in upgrade documentation

#### Common Rector Patterns

**Namespace Changes**

```php
// TYPO3 v12: Namespace consolidation
// Old: TYPO3\CMS\Core\Utility\ExtensionManagementUtility
// New: TYPO3\CMS\Core\Utility\ExtensionManagementUtility (no change in v12, but automated in future versions)
```

**API Replacements**

```php
// ❌ Before: Deprecated GeneralUtility method
GeneralUtility::getIndpEnv('TYPO3_REQUEST_HOST');

// ✅ After: Modern API usage
$normalizedParams = $request->getAttribute('normalizedParams');
$host = $normalizedParams->getRequestHost();
```

**Configuration File Updates**

Rector can update TCA, TypoScript, and other configuration formats to current standards automatically.

### Frontend Code Quality

Modern TYPO3 extensions increasingly include JavaScript and CSS for backend modules and frontend functionality. The tea extension demonstrates parity between PHP and frontend quality tools, ensuring consistent code standards across all languages.

#### ESLint for JavaScript/TypeScript

ESLint enforces JavaScript code quality and catches common errors before runtime.

**Configuration Highlights** (`.eslintrc.json`):

```json
{
  "extends": ["eslint:recommended"],
  "env": {
    "browser": true,
    "es2021": true
  },
  "rules": {
    "no-console": "warn",        // Prevent console.log in production
    "no-debugger": "error",      // Block debugger statements
    "no-alert": "warn",          // Discourage alert() usage
    "prefer-const": "error",     // Enforce const for immutable variables
    "no-var": "error"            // Enforce let/const over var
  }
}
```

**Key Benefits**:
- **Error Prevention**: Catches undefined variables, unreachable code, syntax errors
- **Modern JavaScript**: Enforces ES2021+ features (const/let, arrow functions, template literals)
- **Security**: Prevents debugger statements and console output in production builds
- **Consistency**: Standardizes code style across team members

**Setup**:

```bash
# Install ESLint
npm install --save-dev eslint

# Copy configuration
mkdir -p Build/eslint
cp ~/.claude/skills/typo3-conformance/templates/Build/eslint/.eslintrc.json Build/eslint/

# Add script to package.json
{
  "scripts": {
    "lint:js": "eslint Resources/Public/JavaScript --config Build/eslint/.eslintrc.json"
  }
}

# Run linting
npm run lint:js
```

**CI Integration**:

```yaml
# .github/workflows/ci.yml
- name: JavaScript Linting
  run: npm run lint:js
```

#### Stylelint for CSS/SCSS

Stylelint enforces CSS and SCSS quality, preventing errors and maintaining consistent styling conventions.

**Configuration Highlights** (`.stylelintrc.json`):

```json
{
  "extends": "stylelint-config-standard",
  "rules": {
    "indentation": 2,
    "string-quotes": "single",
    "no-descending-specificity": null,
    "selector-class-pattern": null
  }
}
```

**Key Benefits**:
- **Error Prevention**: Catches invalid CSS, duplicate properties, unknown properties
- **Best Practices**: Enforces selector specificity limits, property order conventions
- **Consistency**: Standardizes indentation, quotes, and formatting
- **Framework Support**: Works with CSS, SCSS, Less, and CSS-in-JS

**Setup**:

```bash
# Install Stylelint
npm install --save-dev stylelint stylelint-config-standard

# Copy configuration
mkdir -p Build/stylelint
cp ~/.claude/skills/typo3-conformance/templates/Build/stylelint/.stylelintrc.json Build/stylelint/

# Add script to package.json
{
  "scripts": {
    "lint:css": "stylelint Resources/Public/Css --config Build/stylelint/.stylelintrc.json"
  }
}

# Run linting
npm run lint:css
```

**CI Integration**:

```yaml
# .github/workflows/ci.yml
- name: CSS Linting
  run: npm run lint:css
```

#### Package.json Structure

Comprehensive frontend tooling requires proper package.json configuration:

```json
{
  "name": "typo3-extension-yourextension",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "lint:js": "eslint Resources/Public/JavaScript --config Build/eslint/.eslintrc.json",
    "lint:css": "stylelint Resources/Public/Css --config Build/stylelint/.stylelintrc.json",
    "lint": "npm run lint:js && npm run lint:css",
    "fix:js": "eslint Resources/Public/JavaScript --config Build/eslint/.eslintrc.json --fix",
    "fix:css": "stylelint Resources/Public/Css --config Build/stylelint/.stylelintrc.json --fix",
    "fix": "npm run fix:js && npm run fix:css"
  },
  "devDependencies": {
    "eslint": "^8.57.0",
    "stylelint": "^16.8.0",
    "stylelint-config-standard": "^36.0.0"
  }
}
```

#### Local-CI Parity

The tea extension demonstrates critical architectural principle: **identical tooling locally and in CI**. This prevents "works on my machine" issues.

**Local Execution**:
```bash
npm run lint        # Same command developers run locally
```

**CI Execution**:
```yaml
- name: Frontend Linting
  run: npm run lint  # Identical command in CI
```

Benefits:
- **Predictability**: CI failures reproducible locally
- **Fast Feedback**: Catch issues before pushing
- **Developer Experience**: Same commands across environments

### Supplementary Linting Tools

Beyond core PHP and frontend linting, the tea extension demonstrates additional specialized tools for comprehensive quality coverage.

#### TypoScript Linting

TypoScript configuration errors can cause runtime issues difficult to diagnose. TypoScriptLint provides static analysis for TypoScript files.

**Configuration** (`TypoScriptLint.yml`):

```yaml
sniffs:
  - class: Indentation
    parameters:
      indentPerLevel: 2
      useSpaces: true
  - class: DeadCode         # Detects unused TypoScript
  - class: OperatorWhitespace
  - class: DuplicateAssignment
  - class: NestingConsistency
```

**Setup**:

```bash
composer require --dev helmich/typo3-typoscript-lint:^3.2

mkdir -p Build/typoscript-lint
cp ~/.claude/skills/typo3-conformance/templates/Build/typoscript-lint/TypoScriptLint.yml Build/typoscript-lint/

# Add composer script
{
  "scripts": {
    "ci:typoscript:lint": "typoscript-lint --config Build/typoscript-lint/TypoScriptLint.yml Configuration/TypoScript"
  }
}
```

**Common Violations**:

```typoscript
# ❌ Inconsistent indentation
page = PAGE
page {
10 = TEXT
  10.value = Hello
}

# ✅ Consistent 2-space indentation
page = PAGE
page {
  10 = TEXT
  10.value = Hello
}
```

#### Composer Dependency Health

**composer-unused**: Identifies unused dependencies, reducing package bloat and security surface.

```bash
composer require --dev icanhazstring/composer-unused:^0.8

# Copy configuration
mkdir -p Build/composer-unused
cp ~/.claude/skills/typo3-conformance/templates/Build/composer-unused/composer-unused.php Build/composer-unused/

# Run analysis
vendor/bin/composer-unused --configuration Build/composer-unused/composer-unused.php
```

**composer-normalize**: Enforces consistent composer.json formatting.

```bash
composer require --dev ergebnis/composer-normalize:^2.43

# Add composer script
{
  "scripts": {
    "ci:composer:normalize": "composer-normalize --dry-run",
    "fix:composer:normalize": "composer-normalize"
  }
}
```

#### JSON and XLIFF Validation

**JSON Linting**: Prevents malformed JSON in extension configuration.

```json
{
  "scripts": {
    "ci:json:lint": "find . -name '*.json' -not -path './.Build/*' -exec php -l {} \\;"
  }
}
```

**XLIFF Validation**: Ensures translation files are well-formed XML.

```bash
composer require --dev symfony/translation:^6.4

# Add validation script
{
  "scripts": {
    "ci:xliff:lint": "php Build/Scripts/validateXliff.php"
  }
}
```

### Architectural Patterns and Best Practices

#### Progressive Quality Adoption

The tea extension demonstrates **progressive enhancement** philosophy for quality tools. Extensions at different maturity levels can adopt incrementally:

**Phase 1 - Foundation** (MVP Extensions):
- PHPStan Level 6
- Basic PSR-12 via php-cs-fixer
- Unit tests with >50% coverage

**Phase 2 - Intermediate** (Production Extensions):
- PHPStan Level 8 with type_coverage at 80%
- Rector for TYPO3 migrations
- Functional tests with >60% coverage
- CI integration for all tools

**Phase 3 - Advanced** (Reference Extensions):
- PHPStan Level 10 with 100% type_coverage
- Cognitive complexity limits
- Security-focused disallowed patterns
- Frontend linting (ESLint, Stylelint)
- >70% test coverage with mutation testing

**Phase 4 - Excellence** (Showcase Extensions like Tea):
- Type perfection mode
- Comprehensive CI matrix (multiple PHP/TYPO3 versions)
- Multi-database testing
- Accessibility compliance
- Performance budgets

#### Local-CI Parity Architecture

**Core Principle**: Every quality check runnable locally must use identical configuration and tooling in CI.

**Implementation**:

1. **Centralized Configuration**: All tool configs in `Build/` directory
2. **Composer Scripts**: Define all commands in composer.json scripts section
3. **CI Uses Scripts**: GitHub Actions/GitLab CI calls composer scripts, not direct tool invocation

Example:

```json
{
  "scripts": {
    "ci:php:lint": "find *.php Classes Configuration Tests -name '*.php' -print0 | xargs -0 -n1 -P4 php -dxdebug.mode=off -l",
    "ci:php:stan": "phpstan analyze --configuration Build/phpstan/phpstan.neon",
    "ci:rector": "rector process --config Build/rector/rector.php --dry-run",
    "ci:tests:unit": "phpunit --configuration Build/phpunit/UnitTests.xml",
    "ci": [
      "@ci:php:lint",
      "@ci:php:stan",
      "@ci:rector",
      "@ci:tests:unit"
    ]
  }
}
```

**Benefits**:
- Developers run `composer ci` locally before pushing
- CI runs `composer ci` with identical behavior
- Configuration changes automatically apply to both environments
- Tool version consistency via composer.lock

#### Tool Responsibility Separation

Each tool has distinct responsibilities to prevent overlap and confusion:

| Tool | Responsibility | When to Run |
|------|----------------|-------------|
| **PHP Lint** | Syntax errors | Pre-commit, CI |
| **php-cs-fixer** | Code formatting, PSR-12 compliance | Pre-commit (auto-fix), CI |
| **PHPStan** | Type safety, static analysis, security | Pre-push, CI |
| **Rector** | Automated refactoring, migrations | Manual, CI (dry-run) |
| **PHPUnit** | Runtime correctness, behavior validation | Pre-push, CI |
| **ESLint** | JavaScript quality, errors | Pre-commit (auto-fix), CI |
| **Stylelint** | CSS quality, formatting | Pre-commit (auto-fix), CI |

**Anti-Pattern**: Don't use PHPStan to check formatting (use php-cs-fixer). Don't use php-cs-fixer for type checking (use PHPStan). Each tool excels at its purpose.

#### Parallel Execution Optimization

The tea extension demonstrates performance optimization for quality tools:

**php-cs-fixer Parallelization**:

```php
$config->setParallelConfig(ParallelConfigFactory::detect());
```

Automatically detects CPU cores and parallelizes analysis, reducing execution time by 60-80% on multi-core systems.

**PHPStan Parallelization**:

```yaml
parallel:
  maximumNumberOfProcesses: 5
```

Limits parallel processes to prevent resource exhaustion while maintaining speed.

**CI Matrix Parallelization**:

```yaml
strategy:
  matrix:
    php: ['8.2', '8.3', '8.4']
    typo3: ['12.4', '13.0']
```

Tests run concurrently across combinations, providing fast feedback on compatibility.

## Installation

### Download the Skill

```bash
# Using curl
curl -L https://github.com/netresearch/typo3-conformance-skill/archive/refs/heads/main.zip -o typo3-conformance.zip
unzip typo3-conformance.zip -d ~/.claude/skills/
mv ~/.claude/skills/typo3-conformance-skill-main ~/.claude/skills/typo3-conformance

# Or using git
git clone https://github.com/netresearch/typo3-conformance-skill.git ~/.claude/skills/typo3-conformance
```

### Install Ecosystem Skills (Recommended)

For comprehensive conformance analysis, install specialized skills:

```bash
# Install typo3-tests for deep testing analysis
git clone https://github.com/netresearch/typo3-testing-skill.git ~/.claude/skills/typo3-tests

# Install typo3-docs for comprehensive documentation validation
git clone https://github.com/netresearch/typo3-docs-skill.git ~/.claude/skills/typo3-docs
```

**Skill Dependencies:**
- **Standalone:** typo3-conformance works independently with basic validation
- **Enhanced:** Install typo3-tests and typo3-docs for production-ready conformance reports
- **Automatic Delegation:** Conformance skill auto-detects and uses ecosystem skills when available

### Verify Installation

The skill automatically activates when analyzing TYPO3 extensions for standards compliance.

## Usage

### Automated Conformance Checking

```bash
# Check current directory
cd /path/to/your-extension
~/.claude/skills/typo3-conformance/scripts/check-conformance.sh

# Check specific directory
~/.claude/skills/typo3-conformance/scripts/check-conformance.sh /path/to/your-extension
```

### Individual Checks

```bash
# File structure only
scripts/check-file-structure.sh /path/to/extension

# Coding standards only
scripts/check-coding-standards.sh /path/to/extension

# Architecture only
scripts/check-architecture.sh /path/to/extension

# Testing only
scripts/check-testing.sh /path/to/extension
```

### Claude Code Integration

#### Manual Invocation
```
/skill typo3-conformance
```

#### Automatic Activation

The skill activates automatically when:
- Analyzing TYPO3 extensions
- Checking code quality
- Reviewing standards compliance
- Evaluating extension architecture

### Example Workflows

**Quick Conformance Check:**
```
User: "Check if my TYPO3 extension follows current standards"

Claude: [Activates typo3-conformance skill]
- Analyzes file structure
- Checks coding standards
- Evaluates architecture patterns
- Reviews testing infrastructure
- Generates comprehensive conformance report
```

**Detailed Architecture Review:**
```
User: "Review the PHP architecture of my extension for TYPO3 best practices"

Claude: [Activates typo3-conformance skill]
- Focuses on dependency injection patterns
- Checks for deprecated patterns (GeneralUtility::makeInstance, $GLOBALS)
- Evaluates PSR-14 event system usage
- Reviews Extbase architecture if applicable
- Provides specific migration recommendations
```

**Pre-TER Publication Check:**
```
User: "My extension is ready for TER publication, please verify it meets all requirements"

Claude: [Activates typo3-conformance skill]
- Verifies all required files present (composer.json, ext_emconf.php, Documentation/)
- Checks file structure compliance
- Validates coding standards
- Reviews architecture patterns
- Assesses testing coverage
- Generates publication readiness report
```

## Conformance Report

The skill generates comprehensive markdown reports with dual scoring system:

### Dual Scoring System (0-120 Total)

**Base Conformance (0-100 points) - MANDATORY**
- Extension Architecture: 0-20 points
- Coding Guidelines: 0-20 points
- PHP Architecture: 0-20 points
- Testing Standards: 0-20 points
- Best Practices: 0-20 points

**Excellence Indicators (0-20 points) - OPTIONAL BONUS**
- Community & Internationalization: 0-6 points
- Advanced Quality Tooling: 0-7 points
- Documentation Excellence: 0-4 points
- Extension Configuration: 0-3 points

**Interpretation:**
- Base conformance (0-100): Core TYPO3 standards compliance (pass/fail criteria)
- Excellence indicators (0-20): Bonus points for exceptional quality (NEVER penalized if missing)
- Extensions scoring 100/100 base are fully conformant, regardless of excellence score
- Excellence indicators identify community reference-level extensions

### Detailed Analysis
- ✅ Strengths and passed checks
- ❌ Critical issues requiring immediate action
- ⚠️  Warnings and recommendations
- 📊 Test coverage estimates
- 💡 Migration guides and examples
- 🌟 Excellence features detected (bonus category)

### Priority Action Items
- **High Priority** - Critical issues blocking functionality or security
- **Medium Priority** - Important conformance issues
- **Low Priority** - Minor style and optimization improvements
- **Excellence Opportunities** - Optional advanced features for reference-level quality

## Example Report Output

```markdown
# TYPO3 Extension Conformance Report

**Extension:** my_extension (v1.0.0)

---

## Score Summary

**Base Conformance:** 75/100
**Excellence Indicators:** 8/20 (Bonus)
**Total Score:** 83/120

### Base Conformance Breakdown
| Category | Score | Status |
|----------|-------|--------|
| Extension Architecture | 18/20 | ✅ Passed |
| Coding Guidelines | 15/20 | ⚠️  Issues |
| PHP Architecture | 16/20 | ✅ Passed |
| Testing Standards | 14/20 | ⚠️  Issues |
| Best Practices | 12/20 | ⚠️  Issues |

### Excellence Indicators (Bonus)
| Category | Score | Status |
|----------|-------|--------|
| Community & Internationalization | 4/6 | 🌟 Good |
| Advanced Quality Tooling | 2/7 | ⚡ Basic |
| Documentation Excellence | 1/4 | 📝 Standard |
| Extension Configuration | 1/3 | ⚙️  Minimal |

**Excellence Highlights:**
- ✅ Crowdin integration (+2)
- ✅ Professional README badges (+2)
- ✅ Fractor configuration (+2)
- ✅ 65 RST files (+1)
- ✅ Composer doc scripts (+1)

## Critical Issues
- ❌ 15 files missing declare(strict_types=1)
- ❌ 12 instances of GeneralUtility::makeInstance()
- ❌ Low test coverage (45% < 70% recommended)

## Recommendations
1. Add declare(strict_types=1) to all PHP files
2. Migrate to constructor injection
3. Increase unit test coverage

## Excellence Opportunities
- 🌟 Add TYPO3 CodingStandards package (+2 points)
- 🌟 Implement CI testing matrix (+1 point)
- 🌟 Add modern documentation tooling (+1 point)
- 🌟 Create multiple Configuration/Sets/ presets (+1 point)
```

## Reference Standards

This skill is based on official TYPO3 documentation:

- [Extension Architecture](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ExtensionArchitecture/)
- [Coding Guidelines](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/CodingGuidelines/)
- [PHP Architecture](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/PhpArchitecture/)
- [Testing](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/)
- [Tea Extension (Best Practice)](https://github.com/TYPO3BestPractices/tea)

## Scoring System

### Base Conformance (0-100 points)

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
- Build scripts (runTests.sh): 6 points
- Directory structure (.Build/ vs Build/): 4 points
- Quality tools configured: 2 points
- Documentation complete: 2 points

### Excellence Indicators (0-20 bonus points)

**Community & Internationalization (0-6 points)**
- Crowdin integration: +2 points
- GitHub issue templates: +1 point
- .gitattributes export-ignore: +1 point
- Professional README badges: +2 points

**Advanced Quality Tooling (0-7 points)**
- Fractor configuration: +2 points
- TYPO3 CodingStandards package: +2 points
- StyleCI integration: +1 point
- Makefile with self-documenting help: +1 point
- CI testing matrix: +1 point

**Documentation Excellence (0-4 points)**
- 50-99 RST files: +1 point
- 100-149 RST files: +2 points
- 150+ RST files: +3 points
- Modern tooling (guides.xml, screenshots.json): +1 point

**Extension Configuration (0-3 points)**
- ext_conf_template.txt: +1 point
- Composer documentation scripts: +1 point
- Multiple Configuration/Sets/ presets: +1 point

**Excellence Interpretation:**
- 0-5 points: Standard extension (meets requirements)
- 6-10 points: Good practices (actively maintained)
- 11-15 points: Excellent quality (community reference level)
- 16-20 points: Outstanding (georgringer/news level)

## Common Issues Detected

### Critical (Must Fix)
- Missing composer.json or ext_emconf.php
- PHP files in extension root
- Missing Configuration/Services.yaml
- Using GeneralUtility::makeInstance() instead of DI
- Accessing $GLOBALS instead of DI
- No unit tests

### High Priority
- Missing declare(strict_types=1)
- Old array() syntax instead of []
- Missing PHPDoc comments
- ext_tables.php usage (deprecated)
- Missing test coverage

### Medium Priority
- Incomplete documentation
- Missing quality tools configuration
- No CI/CD pipeline
- Inconsistent code formatting

## Migration Guides

### From GeneralUtility::makeInstance to Constructor Injection

```php
// ❌ Before (Deprecated)
use TYPO3\CMS\Core\Utility\GeneralUtility;

class MyService
{
    public function doSomething(): void
    {
        $repository = GeneralUtility::makeInstance(ProductRepository::class);
    }
}

// ✅ After (Modern)
class MyService
{
    public function __construct(
        private readonly ProductRepository $repository
    ) {}

    public function doSomething(): void
    {
        // Use $this->repository
    }
}
```

### From ext_tables.php to Configuration/Backend/Modules.php

```php
// ❌ Before (ext_tables.php - Deprecated)
ExtensionUtility::registerModule(
    'MyExtension',
    'web',
    'mymodule',
    '',
    [
        \Vendor\MyExtension\Controller\BackendController::class => 'list,show',
    ]
);

// ✅ After (Configuration/Backend/Modules.php - Modern)
return [
    'web_myext' => [
        'parent' => 'web',
        'position' => ['after' => 'web_info'],
        'access' => 'user',
        'path' => '/module/web/myext',
        'labels' => 'LLL:EXT:my_extension/Resources/Private/Language/locallang_mod.xlf',
        'extensionName' => 'MyExtension',
        'controllerActions' => [
            \Vendor\MyExtension\Controller\BackendController::class => [
                'list',
                'show',
            ],
        ],
    ],
];
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes
4. Test thoroughly
5. Commit your changes (`git commit -m 'Add improvement'`)
6. Push to the branch (`git push origin feature/improvement`)
7. Create a Pull Request

## License

This skill is licensed under GPL-2.0-or-later, matching the TYPO3 project license.

## Support

**Issues and Questions:**
- GitHub Issues: [Report issues](https://github.com/netresearch/typo3-conformance-skill/issues)
- TYPO3 Slack: [#typo3-cms](https://typo3.slack.com/archives/typo3-cms)

## Credits

Created by Netresearch DTT GmbH for the TYPO3 community.

Based on:
- [TYPO3 Official Documentation Standards](https://docs.typo3.org/)
- [TYPO3 Extension Architecture](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ExtensionArchitecture/)
- [TYPO3 Coding Guidelines](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/CodingGuidelines/)
- [TYPO3 Best Practices Tea Extension](https://github.com/TYPO3BestPractices/tea)

---

**Version:** 1.0.0
**Maintained By:** Netresearch DTT GmbH
**Last Updated:** 2025-10-18
