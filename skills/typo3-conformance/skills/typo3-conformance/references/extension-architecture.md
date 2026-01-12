# TYPO3 Extension Architecture Standards

**Source:** TYPO3 Core API Reference - Extension Architecture
**Purpose:** File structure, directory hierarchy, and required files for TYPO3 extensions

## Required Files

### Essential Files

**composer.json**
- REQUIRED for all extensions
- Defines package metadata, dependencies, PSR-4 autoloading
- Example:
```json
{
    "name": "vendor/extension-key",
    "type": "typo3-cms-extension",
    "require": {
        "typo3/cms-core": "^12.4 || ^13.0"
    },
    "autoload": {
        "psr-4": {
            "Vendor\\ExtensionKey\\": "Classes/"
        }
    }
}
```

**ext_emconf.php**
- REQUIRED for TER (TYPO3 Extension Repository) publication
- Contains extension metadata
- Example:
```php
<?php
$EM_CONF[$_EXTKEY] = [
    'title' => 'Extension Title',
    'description' => 'Extension description',
    'category' => 'fe',
    'author' => 'Author Name',
    'author_email' => 'author@example.com',
    'state' => 'stable',
    'version' => '1.0.0',
    'constraints' => [
        'depends' => [
            'typo3' => '12.4.0-13.9.99',
        ],
    ],
];
```

**Documentation/Index.rst**
- REQUIRED for docs.typo3.org publication
- Main documentation entry point
- Must follow reStructuredText format

**Documentation/guides.xml**
- REQUIRED for docs.typo3.org publication (modern PHP-based rendering)
- Contains documentation project settings
- Example:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<guides xmlns="https://www.phpdoc.org/guides"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="https://www.phpdoc.org/guides vendor/phpdocumentor/guides-cli/resources/schema/guides.xsd"
    theme="typo3docs">
    <project title="Extension Name" version="1.0" release="1.0.0" copyright="since 2024"/>
    <extension class="\T3Docs\Typo3DocsTheme\DependencyInjection\Typo3DocsThemeExtension"
        project-home="https://github.com/vendor/extension"
        project-repository="https://github.com/vendor/extension"/>
</guides>
```

> **Note:** `Settings.cfg` is legacy (Sphinx-based) and should be migrated to `guides.xml`.

## Directory Structure

### Core Directories

**Classes/**
- Contains all PHP classes
- MUST follow PSR-4 autoloading structure
- Namespace: `\VendorName\ExtensionKey\`
- Common subdirectories:
  - `Classes/Controller/` - Extbase/backend controllers
  - `Classes/Domain/Model/` - Domain models
  - `Classes/Domain/Repository/` - Repositories
  - `Classes/Service/` - Service classes
  - `Classes/Utility/` - Utility classes
  - `Classes/ViewHelper/` - Fluid ViewHelpers
  - `Classes/EventListener/` - PSR-14 event listeners

**Configuration/**
- Contains all configuration files
- Required subdirectories:
  - `Configuration/TCA/` - Table Configuration Array definitions
  - `Configuration/Backend/` - Backend module configuration
  - `Configuration/TypoScript/` - TypoScript configuration
  - `Configuration/Sets/` - Configuration sets (TYPO3 v13+)
- Optional files:
  - `Configuration/Services.yaml` - Dependency injection configuration
  - `Configuration/TsConfig/` - Page/User TSconfig
  - `Configuration/RequestMiddlewares.php` - PSR-15 middlewares

**Resources/**
- Contains all frontend/backend resources
- Structure:
  - `Resources/Private/` - Non-public files
    - `Resources/Private/Templates/` - Fluid templates
    - `Resources/Private/Partials/` - Fluid partials
    - `Resources/Private/Layouts/` - Fluid layouts
    - `Resources/Private/Language/` - Translation files (XLIFF)
  - `Resources/Public/` - Publicly accessible files
    - `Resources/Public/Css/` - Stylesheets
    - `Resources/Public/JavaScript/` - JavaScript files
    - `Resources/Public/Icons/` - Extension icons
    - `Resources/Public/Images/` - Images

**Tests/**
- Contains PHP test files
- Structure:
  - `Tests/Unit/` - PHPUnit unit tests
  - `Tests/Functional/` - PHPUnit functional tests
- MUST mirror `Classes/` structure

**Build/tests/playwright/** (E2E Testing)
- Contains Playwright E2E and accessibility tests
- Structure:
  - `e2e/` - End-to-end tests (`.spec.ts`)
  - `accessibility/` - Accessibility tests with axe-core
  - `fixtures/` - Page Object Models
  - `helper/` - Authentication setup
- Requires Node.js ≥22.18, `@playwright/test`, `@axe-core/playwright`

**Documentation/**
- Contains RST documentation
- MUST include `Index.rst` and `guides.xml`
- Common structure:
  - `Documentation/Introduction/`
  - `Documentation/Installation/`
  - `Documentation/Configuration/`
  - `Documentation/Developer/`
  - `Documentation/Editor/`

## Reserved File Prefixes

Files with the `ext_*` prefix are reserved for special purposes:

**ext_emconf.php**
- Extension metadata (REQUIRED for TER)

**ext_localconf.php**
- Global configuration executed in both frontend and backend
- Register hooks, event listeners, XCLASSes
- Add plugins, content elements
- Register services

**ext_tables.php**
- Backend-specific configuration
- Register backend modules
- Add TCA modifications
- DEPRECATED in favor of dedicated configuration files

**ext_tables.sql**
- Database table definitions
- Executed during extension installation
- Contains CREATE TABLE and ALTER TABLE statements

**ext_conf_template.txt**
- Extension configuration template
- Defines settings available in Extension Configuration
- TypoScript-like syntax

## File Naming Conventions

### PHP Classes
- File name MUST match class name exactly
- PSR-4 compliant
- Example: `Classes/Controller/MyController.php` → `class MyController`

### Database Tables
- Pattern: `tx_<extensionkeyprefix>_<tablename>`
- Example: `tx_myext_domain_model_product`
- Extension key must be converted to lowercase, underscores allowed

### TCA Files
- Pattern: `Configuration/TCA/<tablename>.php`
- Returns TCA array
- Example: `Configuration/TCA/tx_myext_domain_model_product.php`

### Language Files
- Pattern: `Resources/Private/Language/<context>.xlf`
- XLIFF 1.2 format
- Example: `Resources/Private/Language/locallang.xlf`

## Architecture Best Practices

### PSR-4 Autoloading
- All classes in `Classes/` directory
- Namespace structure MUST match directory structure
- Example:
  - Class: `Vendor\ExtensionKey\Domain\Model\Product`
  - File: `Classes/Domain/Model/Product.php`

### Dependency Injection
- Use constructor injection for dependencies
- Register services in `Configuration/Services.yaml`
- Example:
```yaml
services:
  _defaults:
    autowire: true
    autoconfigure: true
    public: false

  Vendor\ExtensionKey\:
    resource: '../Classes/*'
```

### Configuration Files
- Separate concerns into dedicated configuration files
- Use `Configuration/Backend/` for backend modules (not ext_tables.php)
- Use `Configuration/TCA/` for table definitions
- Use `Configuration/TypoScript/` for TypoScript

### Testing Structure
- Mirror `Classes/` structure in `Tests/Unit/` and `Tests/Functional/`
- Example:
  - Class: `Classes/Service/CalculationService.php`
  - Unit Test: `Tests/Unit/Service/CalculationServiceTest.php`
  - Functional Test: `Tests/Functional/Service/CalculationServiceTest.php`

## Common Issues

### ❌ Wrong: Mixed file types in root
```
my_extension/
├── MyController.php          # WRONG: PHP in root
├── config.yaml               # WRONG: Config in root
└── styles.css                # WRONG: CSS in root
```

### ✅ Right: Proper directory structure
```
my_extension/
├── Classes/Controller/MyController.php
├── Configuration/Services.yaml
└── Resources/Public/Css/styles.css
```

### ❌ Wrong: Non-standard directory names
```
Classes/
├── Controllers/              # WRONG: Plural
├── Services/                 # WRONG: Should be Service
└── Helpers/                  # WRONG: Use Utility
```

### ✅ Right: Standard TYPO3 directory names
```
Classes/
├── Controller/               # Singular
├── Service/                  # Singular
└── Utility/                  # Standard naming
```

## Extension Key Naming

- Lowercase letters and underscores only
- Must start with a letter
- 3-30 characters
- Cannot start with `tx_`, `user_`, `pages`, `tt_`, `sys_`
- Example: `my_extension`, `blog_example`, `news`

## Conformance Checklist

- [ ] composer.json present with correct structure
- [ ] ext_emconf.php present with complete metadata
- [ ] Documentation/Index.rst and Documentation/guides.xml present
- [ ] Classes/ directory follows PSR-4 structure
- [ ] Configuration/ subdirectories properly organized
- [ ] Resources/ separated into Private/ and Public/
- [ ] Tests/ mirror Classes/ structure
- [ ] No PHP files in extension root (except ext_* files)
- [ ] File naming follows conventions
- [ ] Database table names use tx_<extensionkey>_ prefix
- [ ] Extension key follows naming rules
