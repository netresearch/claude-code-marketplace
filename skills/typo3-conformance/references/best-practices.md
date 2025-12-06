# TYPO3 Extension Best Practices

**Source:** TYPO3 Best Practices (Tea Extension) and Core API Standards
**Purpose:** Real-world patterns and organizational best practices for TYPO3 extensions

## Project Structure

### Complete Extension Layout

```
my_extension/
├── .ddev/                          # DDEV configuration
│   └── config.yaml
├── .github/                        # GitHub Actions CI/CD
│   └── workflows/
│       └── tests.yml
├── Build/                          # Build tools and configs
│   ├── phpunit/
│   │   ├── UnitTests.xml
│   │   └── FunctionalTests.xml
│   └── Scripts/
│       └── runTests.sh
├── Classes/                        # PHP source code
│   ├── Controller/
│   ├── Domain/
│   │   ├── Model/
│   │   └── Repository/
│   ├── Service/
│   ├── Utility/
│   ├── EventListener/
│   └── ViewHelper/
├── Configuration/                  # TYPO3 configuration
│   ├── Backend/
│   │   └── Modules.php
│   ├── Services.yaml
│   ├── TCA/
│   ├── TypoScript/
│   │   ├── setup.typoscript
│   │   └── constants.typoscript
│   └── Sets/                       # TYPO3 v13+
│       └── MySet/
│           └── config.yaml
├── Documentation/                  # RST documentation
│   ├── Index.rst
│   ├── Settings.cfg
│   ├── Introduction/
│   ├── Installation/
│   ├── Configuration/
│   ├── Developer/
│   └── Editor/
├── Resources/
│   ├── Private/
│   │   ├── Language/
│   │   │   ├── locallang.xlf
│   │   │   └── de.locallang.xlf
│   │   ├── Layouts/
│   │   ├── Partials/
│   │   └── Templates/
│   └── Public/
│       ├── Css/
│       ├── Icons/
│       ├── Images/
│       └── JavaScript/
├── Tests/
│   ├── Unit/
│   └── Functional/
│       └── Fixtures/
├── Build/
│   ├── playwright.config.ts      # Playwright E2E configuration
│   ├── package.json              # Node dependencies
│   ├── .nvmrc                    # Node version (>=22.18)
│   ├── phpunit/
│   │   ├── UnitTests.xml
│   │   └── FunctionalTests.xml
│   ├── Scripts/
│   │   └── runTests.sh
│   └── tests/
│       └── playwright/           # Playwright E2E tests
│           ├── config.ts
│           ├── e2e/
│           ├── accessibility/
│           ├── fixtures/
│           └── helper/
├── .editorconfig                   # Editor configuration
├── .gitattributes                  # Git attributes
├── .gitignore                      # Git ignore rules
├── .php-cs-fixer.dist.php          # PHP CS Fixer config
├── composer.json                   # Composer configuration
├── composer.lock                   # Locked dependencies
├── ext_emconf.php                  # Extension metadata
├── ext_localconf.php               # Global configuration
├── LICENSE                         # License file
├── phpstan.neon                    # PHPStan configuration
└── README.md                       # Project README
```

## Best Practices by Category

### 1. Dependency Management

**composer.json Best Practices:**

```json
{
    "name": "vendor/my-extension",
    "type": "typo3-cms-extension",
    "description": "Clear, concise extension description",
    "license": "GPL-2.0-or-later",
    "authors": [
        {
            "name": "Author Name",
            "email": "author@example.com",
            "role": "Developer"
        }
    ],
    "require": {
        "php": "^8.1",
        "typo3/cms-core": "^12.4 || ^13.0",
        "typo3/cms-backend": "^12.4 || ^13.0",
        "typo3/cms-extbase": "^12.4 || ^13.0",
        "typo3/cms-fluid": "^12.4 || ^13.0"
    },
    "require-dev": {
        "typo3/coding-standards": "^0.7",
        "typo3/testing-framework": "^8.0",
        "phpunit/phpunit": "^10.5",
        "phpstan/phpstan": "^1.10",
        "friendsofphp/php-cs-fixer": "^3.0"
    },
    "autoload": {
        "psr-4": {
            "Vendor\\MyExtension\\": "Classes/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Vendor\\MyExtension\\Tests\\": "Tests/"
        }
    },
    "config": {
        "vendor-dir": ".Build/vendor",
        "bin-dir": ".Build/bin",
        "sort-packages": true,
        "allow-plugins": {
            "typo3/class-alias-loader": true,
            "typo3/cms-composer-installers": true
        }
    },
    "extra": {
        "typo3/cms": {
            "extension-key": "my_extension",
            "web-dir": ".Build/Web"
        }
    }
}
```

### 2. Code Quality Tools

**.php-cs-fixer.dist.php:**

```php
<?php
declare(strict_types=1);

$config = \TYPO3\CodingStandards\CsFixerConfig::create();
$config->getFinder()
    ->in(__DIR__ . '/Classes')
    ->in(__DIR__ . '/Configuration')
    ->in(__DIR__ . '/Tests');

return $config;
```

**phpstan.neon:**

```neon
includes:
    - .Build/vendor/phpstan/phpstan/conf/bleedingEdge.neon

parameters:
    level: 9
    paths:
        - Classes
        - Configuration
        - Tests
    excludePaths:
        - .Build
        - vendor
```

#### PHPStan Level 10 Best Practices for TYPO3

**Handling $GLOBALS['TCA'] in Tests:**

PHPStan cannot infer types for runtime-configured `$GLOBALS` arrays. Use ignore annotations:

```php
// ✅ Right: Suppress offsetAccess warnings for $GLOBALS['TCA']
/** @var array<string, mixed> $tcaConfig */
$tcaConfig = [
    'type'           => 'text',
    'enableRichtext' => true,
];
// @phpstan-ignore-next-line offsetAccess.nonOffsetAccessible
$GLOBALS['TCA']['tt_content']['columns']['bodytext']['config'] = $tcaConfig;

// ❌ Wrong: No type annotation or suppression
$GLOBALS['TCA']['tt_content']['columns']['bodytext']['config'] = [
    'type' => 'text',
]; // PHPStan error: offsetAccess.nonOffsetAccessible
```

**Factory Methods vs Property Initialization:**

Avoid uninitialized property errors in test classes:

```php
// ❌ Wrong: PHPStan warns about uninitialized property
final class MyServiceTest extends UnitTestCase
{
    private MyService $subject; // Uninitialized property

    protected function setUp(): void
    {
        parent::setUp();
        $this->subject = new MyService();
    }
}

// ✅ Right: Use factory method
final class MyServiceTest extends UnitTestCase
{
    private function createSubject(): MyService
    {
        return new MyService();
    }

    #[Test]
    public function testSomething(): void
    {
        $subject = $this->createSubject();
        // Use $subject
    }
}
```

**Type Assertions for Dynamic Arrays:**

When testing arrays modified by reference:

```php
// ❌ Wrong: PHPStan cannot verify type after modification
public function testFieldProcessing(): void
{
    $fieldArray = ['bodytext' => '<p>Test</p>'];
    $this->subject->processFields($fieldArray);

    // PHPStan error: Cannot access offset on mixed
    self::assertStringContainsString('Test', $fieldArray['bodytext']);
}

// ✅ Right: Add type assertions
public function testFieldProcessing(): void
{
    $fieldArray = ['bodytext' => '<p>Test</p>'];
    $this->subject->processFields($fieldArray);

    self::assertArrayHasKey('bodytext', $fieldArray);
    self::assertIsString($fieldArray['bodytext']);
    self::assertStringContainsString('Test', $fieldArray['bodytext']);
}
```

**Intersection Types for Mocks:**

Use intersection types for proper PHPStan analysis of mocks:

```php
// ✅ Right: Intersection type for mock
/** @var ResourceFactory&MockObject $resourceFactoryMock */
$resourceFactoryMock = $this->createMock(ResourceFactory::class);

// Alternative: @phpstan-var annotation
$resourceFactoryMock = $this->createMock(ResourceFactory::class);
/** @phpstan-var ResourceFactory&MockObject $resourceFactoryMock */
```

**Common PHPStan Suppressions for TYPO3:**

```php
// Suppress $GLOBALS['TCA'] access
// @phpstan-ignore-next-line offsetAccess.nonOffsetAccessible
$GLOBALS['TCA']['table']['columns']['field'] = $config;

// Suppress $GLOBALS['TYPO3_CONF_VARS'] access
// @phpstan-ignore-next-line offsetAccess.nonOffsetAccessible
$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['key'] = MyClass::class;

// Suppress mixed type from legacy code
// @phpstan-ignore-next-line argument.type
$this->view->assign('data', $legacyArray);
```

**Type Hints for Service Container Retrieval:**

```php
// ✅ Right: Type hint service retrieval
/** @var DataHandler $dataHandler */
$dataHandler = $this->get(DataHandler::class);

/** @var ResourceFactory $resourceFactory */
$resourceFactory = $this->get(ResourceFactory::class);
```

### 3. Service Configuration

**Configuration/Services.yaml:**

```yaml
services:
  _defaults:
    autowire: true
    autoconfigure: true
    public: false

  # Auto-register all classes
  Vendor\MyExtension\:
    resource: '../Classes/*'

  # Exclude specific directories
  Vendor\MyExtension\Domain\Model\:
    resource: '../Classes/Domain/Model/*'
    autoconfigure: false

  # Explicit service configuration example
  Vendor\MyExtension\Service\EmailService:
    arguments:
      $fromEmail: '%env(DEFAULT_FROM_EMAIL)%'
      $fromName: 'TYPO3 Extension'

  # Tag configuration example
  Vendor\MyExtension\Command\ImportCommand:
    tags:
      - name: 'console.command'
        command: 'myext:import'
        description: 'Import data from external source'
```

### 4. Backend Module Configuration

**Configuration/Backend/Modules.php:**

```php
<?php
return [
    'web_myext' => [
        'parent' => 'web',
        'position' => ['after' => 'web_info'],
        'access' => 'user',
        'workspaces' => 'live',
        'path' => '/module/web/myext',
        'labels' => 'LLL:EXT:my_extension/Resources/Private/Language/locallang_mod.xlf',
        'extensionName' => 'MyExtension',
        'controllerActions' => [
            \Vendor\MyExtension\Controller\BackendController::class => [
                'list',
                'show',
                'edit',
                'update',
            ],
        ],
    ],
];
```

### 5. Testing Infrastructure

**Build/Scripts/runTests.sh:**

```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Run unit tests
if [ "$1" = "unit" ]; then
    php vendor/bin/phpunit -c Build/phpunit/UnitTests.xml
fi

# Run functional tests
if [ "$1" = "functional" ]; then
    typo3DatabaseDriver=pdo_sqlite \
    php vendor/bin/phpunit -c Build/phpunit/FunctionalTests.xml
fi

# Run all tests
if [ "$1" = "all" ]; then
    php vendor/bin/phpunit -c Build/phpunit/UnitTests.xml
    typo3DatabaseDriver=pdo_sqlite \
    php vendor/bin/phpunit -c Build/phpunit/FunctionalTests.xml
fi
```

### 6. CI/CD Configuration

**.github/workflows/tests.yml:**

```yaml
name: Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  tests:
    name: Tests (PHP ${{ matrix.php }}, TYPO3 ${{ matrix.typo3 }})
    runs-on: ubuntu-latest

    strategy:
      fail-fast: false
      matrix:
        php: ['8.1', '8.2', '8.3']
        typo3: ['12.4', '13.0']

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}
          extensions: mbstring, xml, json, zip, curl
          coverage: none

      - name: Get Composer Cache Directory
        id: composer-cache
        run: echo "dir=$(composer config cache-files-dir)" >> $GITHUB_OUTPUT

      - name: Cache Composer dependencies
        uses: actions/cache@v3
        with:
          path: ${{ steps.composer-cache.outputs.dir }}
          key: ${{ runner.os }}-composer-${{ hashFiles('**/composer.lock') }}
          restore-keys: ${{ runner.os }}-composer-

      - name: Install dependencies
        run: composer install --prefer-dist --no-progress

      - name: Lint PHP
        run: find . -name \*.php ! -path "./vendor/*" ! -path "./.Build/*" -exec php -l {} \;

      - name: PHP CS Fixer
        run: .Build/bin/php-cs-fixer fix --dry-run --diff

      - name: PHPStan
        run: .Build/bin/phpstan analyze

      - name: Unit Tests
        run: .Build/bin/phpunit -c Build/phpunit/UnitTests.xml

      - name: Functional Tests
        run: |
          typo3DatabaseDriver=pdo_sqlite \
          .Build/bin/phpunit -c Build/phpunit/FunctionalTests.xml
```

### 7. Documentation Standards

**Documentation/Index.rst:**

```rst
.. include:: /Includes.rst.txt

==============
My Extension
==============

:Extension key:
   my_extension

:Package name:
   vendor/my-extension

:Version:
   |release|

:Language:
   en

:Author:
   Author Name

:License:
   This document is published under the
   `Creative Commons BY 4.0 <https://creativecommons.org/licenses/by/4.0/>`__
   license.

:Rendered:
   |today|

----

Clear and concise extension description explaining the purpose and main features.

----

**Table of Contents:**

.. toctree::
   :maxdepth: 2
   :titlesonly:

   Introduction/Index
   Installation/Index
   Configuration/Index
   Editor/Index
   Developer/Index
   Sitemap
```

**Page Size Guidelines:**

Follow TYPO3 documentation best practices for page organization and sizing:

**Index.rst (Landing Page):**
- **Target:** 80-150 lines
- **Maximum:** 200 lines
- **Purpose:** Entry point with metadata, brief description, and navigation only
- **Contains:** Extension metadata, brief description, card-grid (optional), toctree, license
- **Anti-pattern:** ❌ Embedding all content (introduction, requirements, contributing, credits, etc.)

**Content Pages:**
- **Target:** 100-300 lines per file
- **Optimal:** 150-200 lines
- **Maximum:** 400 lines (split if larger)
- **Structure:** Focused on single topic or logically related concepts
- **Split Strategy:** Create subdirectories for complex topics with multiple aspects

**Red Flags:**
- ❌ Index.rst >200 lines → Extract content to Introduction/, Contributing/, etc.
- ❌ Single file >400 lines → Split into multiple focused pages
- ❌ All content in Index.rst → Create proper section directories
- ❌ Navigation by scrolling → Use card-grid + toctree structure

**Proper Structure Example:**
```
Documentation/
├── Index.rst              # Landing page (80-150 lines)
├── Introduction/          # Getting started
│   └── Index.rst         # Features, requirements, quick start
├── Installation/          # Setup instructions
│   └── Index.rst
├── Configuration/         # Configuration guides
│   ├── Index.rst
│   ├── Basic.rst
│   └── Advanced.rst
├── Contributing/          # Contribution guidelines
│   └── Index.rst         # Code, translations, credits, resources
├── Examples/              # Usage examples
├── Troubleshooting/       # Problem solving
└── API/                   # Developer reference
```

**Benefits:**
- ✅ Better user experience (focused, scannable pages)
- ✅ Easier maintenance (smaller, manageable files)
- ✅ Improved search results (specific pages rank better)
- ✅ Clear information architecture
- ✅ Follows TYPO3 documentation standards
- ✅ Mobile-friendly navigation

**Reference:** [TYPO3 tea extension](https://github.com/TYPO3BestPractices/tea) - exemplary documentation structure

### 8. Version Control Best Practices

#### Default Branch Naming

**✅ Use `main` as the default branch instead of `master`**

**Rationale:**
- **Industry Standard**: GitHub, GitLab, and Bitbucket all default to `main` for new repositories
- **Modern Convention**: Aligns with current version control ecosystem standards
- **Inclusive Language**: Part of broader industry shift toward inclusive terminology
- **Consistency**: Matches TYPO3 Core and most modern TYPO3 extensions

**Migration from `master` to `main`:**

If your extension currently uses `master`, migrate to `main`:

```bash
# 1. Create main branch from master
git checkout master
git pull origin master
git checkout -b main
git push -u origin main

# 2. Change default branch on GitHub
gh repo edit --default-branch main

# 3. Update all branch references in codebase
# - CI/CD workflows (.github/workflows/*.yml)
# - Documentation (guides.xml, *.rst files)
# - URLs in CONTRIBUTING.md, README.md

# 4. Delete old master branch
git branch -d master
git push origin --delete master
```

**Example CI/CD workflow update:**

```yaml
# .github/workflows/tests.yml
on:
  push:
    branches: [main, develop]  # Changed from: master
  pull_request:
    branches: [main]           # Changed from: master
```

**Example documentation update:**

```xml
<!-- Documentation/guides.xml -->
<extension edit-on-github-branch="main" />  <!-- Changed from: master -->
```

#### Branch Protection Enforcement

**Prevent accidental `master` branch recreation** and **protect `main` branch** using GitHub Repository Rulesets.

**Block master branch - prevents creation and pushes:**

Create `ruleset-block-master.json`:

```json
{
  "name": "Block master branch",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/master"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "creation"
    },
    {
      "type": "update"
    },
    {
      "type": "deletion"
    }
  ],
  "bypass_actors": []
}
```

Apply the ruleset:

```bash
gh api -X POST repos/OWNER/REPO/rulesets \
  --input ruleset-block-master.json
```

**Protect main branch - requires CI and prevents force pushes:**

Create `ruleset-protect-main.json`:

```json
{
  "name": "Protect main branch",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": [
          {
            "context": "build"
          }
        ],
        "strict_required_status_checks_policy": false
      }
    },
    {
      "type": "non_fast_forward"
    }
  ],
  "bypass_actors": [
    {
      "actor_id": 5,
      "actor_type": "RepositoryRole",
      "bypass_mode": "always"
    }
  ]
}
```

Apply the ruleset:

```bash
gh api -X POST repos/OWNER/REPO/rulesets \
  --input ruleset-protect-main.json
```

**Verify rulesets are active:**

```bash
# List all rulesets
gh api repos/OWNER/REPO/rulesets

# Test master branch is blocked (should fail)
git push origin test-branch:master
# Expected: remote: error: GH013: Repository rule violations found
```

**Benefits of Repository Rulesets:**
- ✅ Prevents accidental `master` branch recreation
- ✅ Enforces CI status checks before merging to `main`
- ✅ Prevents force pushes to protected branches
- ✅ Allows admin bypass for emergency situations
- ✅ More flexible than legacy branch protection rules
- ✅ Supports complex conditions and multiple rule types

#### .gitignore Best Practices

**Standard .gitignore for TYPO3 Extensions:**

```gitignore
# Composer
composer.lock
vendor/

# Build artifacts and caches
.Build/
.php-cs-fixer.cache
.phpunit.result.cache

# IDE and editors
.idea/
.vscode/
*.sublime-*

# OS files
.DS_Store
Thumbs.db

# Testing artifacts
var/
.phpunit.cache/

# Node.js (if using Playwright/frontend tools)
node_modules/
Build/node_modules/

# Do not ignore public icons (example)
public/*
!public/Icons/
!public/Icons/**
```

**Key Patterns Explained:**

| Pattern | Purpose |
|---------|---------|
| `.Build/` | Composer's vendor-dir and build artifacts when using `"vendor-dir": ".Build/vendor"` |
| `.php-cs-fixer.cache` | PHP-CS-Fixer cache file (regenerated on each run) |
| `.phpunit.result.cache` | PHPUnit result cache |
| `composer.lock` | Often gitignored for libraries/extensions (include for projects) |
| `vendor/` | Composer dependencies |
| `var/` | TYPO3 testing framework temporary files |

**Anti-pattern: Double-ignore**

❌ **Wrong:** Adding patterns already covered by parent ignore
```gitignore
.Build/
.Build/vendor/      # Redundant - already ignored by .Build/
.Build/bin/         # Redundant - already ignored by .Build/
```

✅ **Right:** Single parent pattern covers all subdirectories
```gitignore
.Build/
```

**Tracking vs Ignoring:**

If a file was previously tracked and you add it to `.gitignore`, you must also remove it from git:

```bash
# Stop tracking a file that's now gitignored
git rm --cached .php-cs-fixer.cache
git commit -m "chore: stop tracking php-cs-fixer cache"

# Stop tracking a directory
git rm -r --cached .Build/
git commit -m "chore: stop tracking build artifacts"
```

**DDEV-specific ignores (optional):**

If using DDEV, consider also ignoring:

```gitignore
# DDEV (optional - some teams commit .ddev/)
.ddev/.gitignore
.ddev/db_snapshots/
.ddev/import-db/
```

### 9. Language File Organization

**Resources/Private/Language/locallang.xlf:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xliff version="1.2" xmlns="urn:oasis:names:tc:xliff:document:1.2">
    <file source-language="en" datatype="plaintext"
          original="EXT:my_extension/Resources/Private/Language/locallang.xlf"
          date="2024-01-01T12:00:00Z"
          product-name="my_extension">
        <header/>
        <body>
            <trans-unit id="plugin.title" resname="plugin.title">
                <source>My Extension Plugin</source>
            </trans-unit>
            <trans-unit id="plugin.description" resname="plugin.description">
                <source>Displays product list with filters</source>
            </trans-unit>
        </body>
    </file>
</xliff>
```

### 10. TCA Best Practices

**Configuration/TCA/tx_myext_domain_model_product.php:**

```php
<?php
return [
    'ctrl' => [
        'title' => 'LLL:EXT:my_extension/Resources/Private/Language/locallang_db.xlf:tx_myext_domain_model_product',
        'label' => 'title',
        'tstamp' => 'tstamp',
        'crdate' => 'crdate',
        'delete' => 'deleted',
        'sortby' => 'sorting',
        'versioningWS' => true,
        'origUid' => 't3_origuid',
        'languageField' => 'sys_language_uid',
        'transOrigPointerField' => 'l10n_parent',
        'transOrigDiffSourceField' => 'l10n_diffsource',
        'translationSource' => 'l10n_source',
        'enablecolumns' => [
            'disabled' => 'hidden',
            'starttime' => 'starttime',
            'endtime' => 'endtime',
        ],
        'searchFields' => 'title,description',
        'iconfile' => 'EXT:my_extension/Resources/Public/Icons/product.svg',
    ],
    'types' => [
        '1' => [
            'showitem' => '
                --div--;LLL:EXT:core/Resources/Private/Language/Form/locallang_tabs.xlf:general,
                    title, description,
                --div--;LLL:EXT:core/Resources/Private/Language/Form/locallang_tabs.xlf:access,
                    hidden, starttime, endtime
            ',
        ],
    ],
    'columns' => [
        'title' => [
            'label' => 'LLL:EXT:my_extension/Resources/Private/Language/locallang_db.xlf:tx_myext_domain_model_product.title',
            'config' => [
                'type' => 'input',
                'size' => 30,
                'eval' => 'trim,required',
                'max' => 255,
            ],
        ],
        'description' => [
            'label' => 'LLL:EXT:my_extension/Resources/Private/Language/locallang_db.xlf:tx_myext_domain_model_product.description',
            'config' => [
                'type' => 'text',
                'enableRichtext' => true,
                'richtextConfiguration' => 'default',
            ],
        ],
    ],
];
```

### 11. Security Best Practices

**✅ Input Validation:**
```php
use TYPO3\CMS\Core\Utility\GeneralUtility;
use TYPO3\CMS\Core\Utility\MathUtility;

// Validate integer input
if (!MathUtility::canBeInterpretedAsInteger($input)) {
    throw new \InvalidArgumentException('Invalid integer value');
}

// Sanitize email
$email = GeneralUtility::validEmail($input) ? $input : '';

// Escape output in templates
{product.title -> f:format.htmlspecialchars()}
```

**✅ SQL Injection Prevention:**
```php
// Use QueryBuilder with bound parameters
$queryBuilder = GeneralUtility::makeInstance(ConnectionPool::class)
    ->getQueryBuilderForTable('tx_myext_domain_model_product');

$products = $queryBuilder
    ->select('*')
    ->from('tx_myext_domain_model_product')
    ->where(
        $queryBuilder->expr()->eq(
            'uid',
            $queryBuilder->createNamedParameter($uid, Connection::PARAM_INT)
        )
    )
    ->executeQuery()
    ->fetchAllAssociative();
```

**✅ CSRF Protection:**
```html
<!-- Always include form protection token -->
<f:form.hidden property="__trustedProperties" value="{formProtection}" />
```

## Common Anti-Patterns to Avoid

### ❌ Don't: Use GeneralUtility::makeInstance() for Services
```php
// Old way (deprecated)
$repository = GeneralUtility::makeInstance(ProductRepository::class);
```

### ✅ Do: Use Dependency Injection
```php
// Modern way
public function __construct(
    private readonly ProductRepository $repository
) {}
```

### ❌ Don't: Access $GLOBALS directly
```php
// Avoid global state
$user = $GLOBALS['BE_USER'];
$tsfe = $GLOBALS['TSFE'];
```

### ✅ Do: Inject Context and Services
```php
public function __construct(
    private readonly Context $context,
    private readonly TypoScriptService $typoScriptService
) {}
```

### ❌ Don't: Use ext_tables.php for configuration
```php
// ext_tables.php (deprecated for most uses)
```

### ✅ Do: Use dedicated configuration files
```php
// Configuration/Backend/Modules.php
// Configuration/TCA/
// Configuration/Services.yaml
```

## Conformance Checklist

- [ ] Complete directory structure following best practices
- [ ] composer.json with proper PSR-4 autoloading
- [ ] Quality tools configured (php-cs-fixer, phpstan)
- [ ] CI/CD pipeline (GitHub Actions or GitLab CI)
- [ ] Comprehensive test coverage (unit, functional, acceptance)
- [ ] Complete documentation in RST format
- [ ] Service configuration in Services.yaml
- [ ] Backend modules in Configuration/Backend/
- [ ] TCA files in Configuration/TCA/
- [ ] Language files in XLIFF format
- [ ] Dependency injection throughout
- [ ] No global state access
- [ ] Security best practices followed
- [ ] .editorconfig for consistent formatting
- [ ] .gitignore with standard patterns (caches, build artifacts, vendor)
- [ ] README.md with clear instructions
- [ ] LICENSE file present
