# TYPO3 v13 Deprecations and Modern Alternatives

**Sources:** TYPO3 Core API Reference v13.4
**Purpose:** Track v13 deprecations, migration paths, and modern configuration approaches

## Deprecated Files (v13.1+)

### ext_typoscript_constants.typoscript
**Status:** DEPRECATED since TYPO3 v13.1

**Purpose:** Provided global TypoScript constants

**Migration Paths:**

**1. Preferred: Site Settings Definitions**
```yaml
# Configuration/Sets/MySet/settings.definitions.yaml
settings:
  myext:
    itemsPerPage:
      type: int
      default: 10
      label: 'Items per page'
```

**2. For Global Constants:**
```php
// ext_localconf.php
\TYPO3\CMS\Core\Utility\ExtensionManagementUtility::addTypoScript(
    'my_extension',
    'constants',
    '@import "EXT:my_extension/Configuration/TypoScript/constants.typoscript"'
);
```

**Detection:**
```bash
[ -f "ext_typoscript_constants.typoscript" ] && echo "⚠️  DEPRECATED: Migrate to Site sets"
```

**Impact:** "This file takes no effect in sites that use Site sets."

---

### ext_typoscript_setup.typoscript
**Status:** DEPRECATED since TYPO3 v13.1

**Purpose:** Provided global TypoScript setup

**Migration Paths:**

**1. Preferred: Site Sets**
```yaml
# Configuration/Sets/MySet/config.yaml
name: my-vendor/my-set
label: 'My Extension Set'

imports:
  - { resource: 'EXT:fluid_styled_content/Configuration/Sets/FluidStyledContent/config.yaml' }
```

```typoscript
# Configuration/Sets/MySet/setup.typoscript
plugin.tx_myextension {
    settings {
        itemsPerPage = 10
    }
}
```

**2. For Global Loading:**
```php
// ext_localconf.php
\TYPO3\CMS\Core\Utility\ExtensionManagementUtility::addTypoScript(
    'my_extension',
    'setup',
    '@import "EXT:my_extension/Configuration/TypoScript/setup.typoscript"'
);
```

**Detection:**
```bash
[ -f "ext_typoscript_setup.typoscript" ] && echo "⚠️  DEPRECATED: Migrate to Site sets"
```

**Impact:** "This file takes no effect in sites that use Site sets. This file works for backward compatibility reasons only in installations that depend on TypoScript records only."

---

## Deprecated Methods (Removal in v14)

### ExtensionManagementUtility::addUserTSConfig()
**Status:** DEPRECATED, will be removed with TYPO3 v14.0

**Old Approach:**
```php
// ext_localconf.php - DEPRECATED
\TYPO3\CMS\Core\Utility\ExtensionManagementUtility::addUserTSConfig('
    options.pageTree.showPageIdWithTitle = 1
    options.defaultUploadFolder = 1:/user_uploads/
');
```

**Modern Approach:**
```
# Configuration/user.tsconfig
options.pageTree.showPageIdWithTitle = 1
options.defaultUploadFolder = 1:/user_uploads/
```

**Detection:**
```bash
grep "addUserTSConfig" ext_localconf.php && echo "❌ DEPRECATED: Use Configuration/user.tsconfig"
```

---

## Modern Configuration Files (v12+)

### Configuration/user.tsconfig
**Since:** TYPO3 v12
**Purpose:** User TSconfig loaded for all backend users

**Location:** `Configuration/user.tsconfig`

**Example:**
```
# Default user settings
options.pageTree.showPageIdWithTitle = 1
options.defaultUploadFolder = 1:/user_uploads/

# Hide modules
options.hideModules = web_layout, web_info
```

**Validation:**
```bash
[ -f "Configuration/user.tsconfig" ] && echo "✅ Modern user TSconfig" || echo "⚠️  Consider adding user TSconfig"
```

---

### Configuration/page.tsconfig
**Since:** TYPO3 v12
**Purpose:** Page TSconfig loaded globally

**Location:** `Configuration/page.tsconfig`

**Example:**
```
# Default page configuration
TCEFORM.pages.layout.disabled = 1
TCEMAIN.table.pages.disablePrependAtCopy = 1

# Backend layout
mod.web_layout.BackendLayouts {
    standard {
        title = Standard Layout
        icon = EXT:my_ext/Resources/Public/Icons/layout.svg
        config {
            backend_layout {
                colCount = 2
                rowCount = 1
                rows {
                    1 {
                        columns {
                            1 {
                                name = Main
                                colPos = 0
                            }
                            2 {
                                name = Sidebar
                                colPos = 1
                            }
                        }
                    }
                }
            }
        }
    }
}
```

**Validation:**
```bash
[ -f "Configuration/page.tsconfig" ] && echo "✅ Modern page TSconfig" || echo "⚠️  Consider adding page TSconfig"
```

---

## Modern Backend Configuration (v13)

### Configuration/Backend/Modules.php
**Since:** TYPO3 v13.0
**Purpose:** Backend module registration (replaces ext_tables.php)

**Location:** `Configuration/Backend/Modules.php`

**Example:**
```php
<?php

return [
    'web_myext' => [
        'parent' => 'web',
        'position' => ['after' => 'web_list'],
        'access' => 'user',
        'workspaces' => 'live',
        'path' => '/module/web/myext',
        'labels' => 'LLL:EXT:my_ext/Resources/Private/Language/locallang_mod.xlf',
        'extensionName' => 'MyExt',
        'controllerActions' => [
            \Vendor\MyExt\Controller\BackendController::class => [
                'list',
                'detail',
                'update',
            ],
        ],
    ],
];
```

**Old Approach (DEPRECATED):**
```php
// ext_tables.php - DEPRECATED
\TYPO3\CMS\Extbase\Utility\ExtensionUtility::registerModule(
    'MyExt',
    'web',
    'mymodule',
    'after:list',
    [
        \Vendor\MyExt\Controller\BackendController::class => 'list,detail,update',
    ],
    [
        'access' => 'user,group',
        'labels' => 'LLL:EXT:my_ext/Resources/Private/Language/locallang_mod.xlf',
    ]
);
```

**Migration Script:** TYPO3 provides "Check TCA in ext_tables.php" upgrade tool

**Validation:**
```bash
[ -f "Configuration/Backend/Modules.php" ] && echo "✅ Modern backend modules" || echo "⚠️  Check for modules in ext_tables.php"
```

---

## Site Sets (v13 Recommended Approach)

### Configuration/Sets Structure

```
Configuration/Sets/
└── MySet/
    ├── config.yaml (REQUIRED)
    ├── settings.definitions.yaml
    ├── setup.typoscript
    ├── constants.typoscript (optional)
    ├── page.tsconfig
    └── user.tsconfig
```

### config.yaml (Required)
```yaml
name: my-vendor/my-set
label: 'My Extension Configuration Set'

# Dependencies
imports:
  - { resource: 'EXT:fluid_styled_content/Configuration/Sets/FluidStyledContent/config.yaml' }

# Settings with defaults
settings:
  myext:
    itemsPerPage: 10
    showImages: true
```

### settings.definitions.yaml
```yaml
settings:
  myext:
    itemsPerPage:
      type: int
      default: 10
      label: 'Items per page'
      description: 'Number of items displayed per page in list view'

    showImages:
      type: bool
      default: true
      label: 'Show images'
      description: 'Display images in list view'

    templateLayout:
      type: string
      default: 'default'
      label: 'Template layout'
      enum:
        default: 'Default Layout'
        grid: 'Grid Layout'
        list: 'List Layout'
```

### setup.typoscript
```typoscript
plugin.tx_myextension {
    view {
        templateRootPaths.0 = EXT:my_extension/Resources/Private/Templates/
        partialRootPaths.0 = EXT:my_extension/Resources/Private/Partials/
        layoutRootPaths.0 = EXT:my_extension/Resources/Private/Layouts/
    }

    settings {
        itemsPerPage = {$settings.myext.itemsPerPage}
        showImages = {$settings.myext.showImages}
    }
}
```

### Activation in Site Configuration
```yaml
# config/sites/mysite/config.yaml
base: 'https://example.com/'
rootPageId: 1
sets:
  - my-vendor/my-set  # Activates the set
```

---

## Migration Checklist

### For v12 → v13 Migration
- [ ] Move backend module registration from ext_tables.php to Configuration/Backend/Modules.php
- [ ] Replace `addUserTSConfig()` with Configuration/user.tsconfig
- [ ] Move page TSconfig from ext_localconf.php to Configuration/page.tsconfig
- [ ] Deprecate ext_typoscript_constants.typoscript (use Site sets)
- [ ] Deprecate ext_typoscript_setup.typoscript (use Site sets)

### For Modern v13 Extensions
- [ ] Use Configuration/Sets/ for TypoScript configuration
- [ ] Use settings.definitions.yaml for extension settings
- [ ] Use Configuration/Backend/Modules.php for backend modules
- [ ] Use Configuration/user.tsconfig for user TSconfig
- [ ] Use Configuration/page.tsconfig for page TSconfig
- [ ] Use Configuration/Icons.php for icon registration

---

## Validation Commands

```bash
#!/bin/bash
# check-v13-deprecations.sh

echo "=== Checking for TYPO3 v13 Deprecations ==="
echo ""

# Check deprecated files
if [ -f "ext_typoscript_constants.typoscript" ]; then
    echo "⚠️  DEPRECATED: ext_typoscript_constants.typoscript (v13.1)"
    echo "   → Migrate to Configuration/Sets/ with settings.definitions.yaml"
fi

if [ -f "ext_typoscript_setup.typoscript" ]; then
    echo "⚠️  DEPRECATED: ext_typoscript_setup.typoscript (v13.1)"
    echo "   → Migrate to Configuration/Sets/ with setup.typoscript"
fi

# Check deprecated methods
if grep -q "addUserTSConfig" ext_localconf.php 2>/dev/null; then
    echo "❌ DEPRECATED: addUserTSConfig() - Removal in v14"
    echo "   → Use Configuration/user.tsconfig"
fi

# Check for backend modules in ext_tables.php
if grep -q "registerModule" ext_tables.php 2>/dev/null; then
    echo "⚠️  DEPRECATED: Backend modules in ext_tables.php"
    echo "   → Migrate to Configuration/Backend/Modules.php"
fi

# Check modern files presence
echo ""
echo "=== Modern Configuration Files ===" [ -d "Configuration/Sets" ] && echo "✅ Configuration/Sets/ present" || echo "⚠️  Consider adding Site sets"
[ -f "Configuration/user.tsconfig" ] && echo "✅ Configuration/user.tsconfig present"
[ -f "Configuration/page.tsconfig" ] && echo "✅ Configuration/page.tsconfig present"
[ -f "Configuration/Backend/Modules.php" ] && echo "✅ Configuration/Backend/Modules.php present"

echo ""
echo "Deprecation check complete"
```

---

## Quick Reference Matrix

| Old Approach | Modern Approach (v13) | Status |
|--------------|----------------------|--------|
| ext_typoscript_constants.typoscript | Configuration/Sets/*/settings.definitions.yaml | Deprecated v13.1 |
| ext_typoscript_setup.typoscript | Configuration/Sets/*/setup.typoscript | Deprecated v13.1 |
| addUserTSConfig() in ext_localconf.php | Configuration/user.tsconfig | Removal in v14 |
| Page TSconfig in ext_localconf.php | Configuration/page.tsconfig | Modern v12+ |
| registerModule() in ext_tables.php | Configuration/Backend/Modules.php | Modern v13+ |
| Static files in ext_tables.php | Configuration/TCA/Overrides/sys_template.php | Modern |
| TCA in ext_tables.php | Configuration/TCA/*.php | Modern |
