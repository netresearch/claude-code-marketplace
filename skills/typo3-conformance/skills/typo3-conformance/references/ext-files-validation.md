# Extension Files Validation Standards (TYPO3 v13)

**Sources:** TYPO3 Core API Reference v13.4
**Purpose:** Validation rules for ext_localconf.php, ext_tables.php, ext_tables.sql, ext_tables_static+adt.sql, ext_conf_template.txt

## ext_localconf.php

### Purpose
Global configuration file loaded during TYPO3 bootstrap in frontend, backend, and CLI contexts.

### Required Structure
```php
<?php
declare(strict_types=1);
defined('TYPO3') or die();

// Configuration code here
```

### What SHOULD Be Included
✅ Registering hooks, XCLASSes, array assignments to `$GLOBALS['TYPO3_CONF_VARS']`
✅ Registering Request Handlers
✅ Adding default TypoScript via ExtensionManagementUtility APIs
✅ Registering Scheduler Tasks
✅ Adding reports to reports module
✅ Registering Services via Service API

### What Should NOT Be Included
❌ Function and class definitions (use services/utility classes)
❌ Class loader or package manager configuration
❌ Cache/config manager settings
❌ Log manager configuration
❌ Time zone, memory limit, locale settings
❌ Icon registration (use `Icons.php` instead)

### TYPO3 v13 Deprecations

**❌ DEPRECATED:** `\TYPO3\CMS\Core\Utility\ExtensionManagementUtility::addUserTSConfig()`
- **Removal:** TYPO3 v14.0
- **Alternative:** Use `Configuration/user.tsconfig` file instead

**❌ DEPRECATED (since v12):** Page TSconfig in ext_localconf.php
- **Alternative:** Use `Configuration/page.tsconfig` file instead

### Validation Commands
```bash
# Check required structure
head -5 ext_localconf.php | grep "declare(strict_types=1)" && echo "✅ Has strict_types"
head -5 ext_localconf.php | grep "defined('TYPO3')" && echo "✅ Has TYPO3 guard"

# Check for deprecated addUserTSConfig
grep "addUserTSConfig" ext_localconf.php && echo "⚠️  DEPRECATED: Use Configuration/user.tsconfig"
```

---

## ext_tables.php

### Deprecation Status
**PHASING OUT:** Increasingly replaced by modern configuration approaches.

### What Should NOT Be in ext_tables.php (v13)

❌ **TCA configurations** → Use `Configuration/TCA/tablename.php`
❌ **TCA overrides** → Use `Configuration/TCA/Overrides/somefile.php`
❌ **Insert records** → Move to TCA Overrides files
❌ **Static files** → Move to `Configuration/TCA/Overrides/sys_template.php`
❌ **Backend modules** → Moved to `Configuration/Backend/` in v13.0

### Appropriate Uses (Remaining)
✅ Registering scheduler tasks with localization labels
✅ Registering custom page types
✅ Extending backend user settings

### v13 Migration

**Backend Module Registration:**
```php
❌ OLD (ext_tables.php):
ExtensionUtility::registerModule(...);

✅ NEW (Configuration/Backend/Modules.php):
return [
    'web_myext' => [
        'parent' => 'web',
        'position' => ['after' => 'web_list'],
        // ...
    ],
];
```

### Validation Commands
```bash
# Check for TCA modifications (should be in TCA/Overrides/)
grep -E "addTCAcolumns|addToAllTCAtypes" ext_tables.php && echo "⚠️  WARNING: Move to TCA/Overrides/"

# Check for backend module registration (should be in Configuration/Backend/)
grep "registerModule" ext_tables.php && echo "⚠️  WARNING: Move to Configuration/Backend/Modules.php"
```

---

## ext_tables.sql

### Purpose
Defines database tables and columns for extensions. Parsed when extensions are enabled.

### SQL Syntax Requirements

**Format:** Follow `mysqldump` utility output style
- TYPO3 parses and converts to target DBMS (MySQL, MariaDB, PostgreSQL, SQLite)
- Partial definitions allowed when extending existing tables

### Table Naming Conventions
```sql
-- Extension tables with prefix
CREATE TABLE tx_myextension_domain_model_table (
    field_name varchar(255) DEFAULT '' NOT NULL,
);

-- Extending core tables
CREATE TABLE pages (
    tx_myextension_field int(11) DEFAULT '0' NOT NULL,
);
```

### Auto-Generated Columns
If TCA exists, TYPO3 automatically creates:
- `uid` with PRIMARY KEY
- `pid` (unsigned) with default index `parent`
- System fields based on TCA `ctrl` properties

### New in v13: Empty Table Definitions
```sql
-- Valid when TCA enriches fields
CREATE TABLE tx_myextension_table (
);
```

### v13.4 CHAR/BINARY Handling

**WARNING:** Fixed-length types now properly flagged
- Use only with ensured fixed-length values (hash identifiers)
- **Avoid with Extbase ORM** (cannot ensure fixed-length in queries)
- Test extensively across database platforms

**Best Practice:**
```sql
✅ VARCHAR(255)  -- Variable length (preferred)
⚠️  CHAR(32)      -- Fixed length (use cautiously)
✅ VARBINARY(255) -- Variable binary (preferred)
⚠️  BINARY(16)    -- Fixed binary (use cautiously)
```

### Validation Commands
```bash
# Check table naming
grep "CREATE TABLE" ext_tables.sql | grep -E "tx_[a-z_]+" && echo "✅ Proper naming"

# Check for CHAR usage (potential issue)
grep -E "CHAR\([0-9]+\)" ext_tables.sql && echo "⚠️  WARNING: CHAR type found - verify fixed-length"

# Validate syntax
php -r "file_get_contents('ext_tables.sql');" && echo "✅ File readable"
```

---

## ext_tables_static+adt.sql

### Purpose
Stores static SQL INSERT statements for pre-populated data.

### Critical Restrictions

**❌ ONLY INSERT statements allowed**
- No CREATE TABLE
- No ALTER TABLE
- No UPDATE/DELETE

**⚠️  Warning:** "Static data is not meant to be extended by other extensions. On re-import all extended fields and data is lost."

### When to Use
- Initial data required during installation
- Lookup tables, predefined categories
- Default configuration data

### Re-import Behavior
- Data truncated and reimported when file contents change
- Executed via:
  - `bin/typo3 extension:setup`
  - Admin Tools > Extensions reload

### Generation Command
```bash
mysqldump --user=[user] --password [database] [tablename] > ./ext_tables_static+adt.sql
```

### Validation Commands
```bash
# Check file exists
[ -f "ext_tables_static+adt.sql" ] && echo "✅ Static data file present"

# Verify only INSERT statements
grep -v "^INSERT" ext_tables_static+adt.sql | grep -E "^(CREATE|ALTER|UPDATE|DELETE)" && echo "❌ CRITICAL: Only INSERT allowed"

# Check corresponding table definition exists
grep "CREATE TABLE" ext_tables.sql && echo "✅ Table definitions present"
```

---

## ext_conf_template.txt

### Purpose
Defines extension configuration options in Admin Tools > Settings module.

### Syntax Format
```
# cat=Category; type=fieldtype; label=LLL:EXT:key/path.xlf:label
optionName = defaultValue
```

### Field Types

| Type | Purpose | Example |
|------|---------|---------
| `boolean` | Checkbox | `type=boolean` |
| `string` | Text field | `type=string` |
| `int` / `integer` | Whole number | `type=int` |
| `int+` | Positive integers | `type=int+` |
| `color` | Color picker | `type=color` |
| `options` | Select dropdown | `type=options[Val1=1,Val2=2]` |
| `user` | Custom function | `type=user[Vendor\Class->method]` |
| `small` | Compact text field | `type=small` |
| `wrap` | Wrapper field | `type=wrap` |
| `offset` | Offset value | `type=offset` |

### Options Syntax
```
# cat=basic; type=options[Option 1=value1,Option 2=value2]; label=Select Option
variable = value1
```

### User Function Syntax
```
# cat=advanced; type=user[Vendor\Extension\Class->methodName]; label=Custom Field
variable = 1
```

### Nested Structure
```
directories {
   # cat=paths; type=string; label=Temp directory
   tmp = /tmp

   # cat=paths; type=string; label=Upload directory
   uploads = /uploads
}
```

**Access:** `$config['directories']['tmp']`

### Localization
```
# Use LLL references for multi-language support
# cat=basic; type=string; label=LLL:EXT:my_ext/Resources/Private/Language/locallang.xlf:config.title
title = Default Title
```

### Validation Commands
```bash
# Check file exists
[ -f "ext_conf_template.txt" ] && echo "✅ Configuration template present"

# Check syntax format
grep -E "^#.*cat=.*type=.*label=" ext_conf_template.txt && echo "✅ Valid syntax found"

# Check for localization
grep "LLL:EXT:" ext_conf_template.txt && echo "✅ Uses localized labels"

# Validate field types
grep -E "type=(boolean|string|int|int\+|color|options|user|small|wrap|offset)" ext_conf_template.txt && echo "✅ Valid field types"
```

### Accessing Configuration in Code
```php
use TYPO3\CMS\Core\Configuration\ExtensionConfiguration;

public function __construct(
    private readonly ExtensionConfiguration $extensionConfiguration
) {}

// Get all configuration
$config = $this->extensionConfiguration->get('extension_key');

// Get specific value
$value = $this->extensionConfiguration->get('extension_key', 'optionName');
```

---

## Validation Checklist

### ext_localconf.php
- [ ] Has `declare(strict_types=1)` at top
- [ ] Has `defined('TYPO3') or die();` guard
- [ ] No function/class definitions
- [ ] **NOT** using deprecated `addUserTSConfig()`
- [ ] **NOT** adding page TSconfig (use Configuration/page.tsconfig)

### ext_tables.php
- [ ] No TCA definitions (use Configuration/TCA/)
- [ ] No TCA overrides (use Configuration/TCA/Overrides/)
- [ ] No backend module registration (use Configuration/Backend/)
- [ ] Only contains appropriate v13 use cases

### ext_tables.sql
- [ ] Follows mysqldump syntax
- [ ] Tables prefixed with `tx_<extensionkey>_`
- [ ] Uses VARCHAR/VARBINARY (not CHAR/BINARY unless necessary)
- [ ] Empty table definitions if TCA provides fields

### ext_tables_static+adt.sql (if present)
- [ ] **ONLY** INSERT statements (no CREATE/ALTER)
- [ ] Corresponding table structure in ext_tables.sql
- [ ] Static data is truly static (not extended by other extensions)

### ext_conf_template.txt (if present)
- [ ] Syntax: `# cat=; type=; label=`
- [ ] Valid field types used
- [ ] Localized labels with LLL: references
- [ ] Proper categorization
- [ ] Sensible default values

---

## Common Violations and Fixes

### ext_localconf.php: Using Deprecated addUserTSConfig

❌ Before:
```php
\TYPO3\CMS\Core\Utility\ExtensionManagementUtility::addUserTSConfig('
    options.pageTree.showPageIdWithTitle = 1
');
```

✅ After:
```
// Create Configuration/user.tsconfig
options.pageTree.showPageIdWithTitle = 1
```

### ext_tables.php: Backend Module in ext_tables.php

❌ Before (ext_tables.php):
```php
ExtensionUtility::registerModule('MyExt', 'web', 'mymodule', ...);
```

✅ After (Configuration/Backend/Modules.php):
```php
return [
    'web_myext_mymodule' => [
        'parent' => 'web',
        'position' => ['after' => 'web_list'],
        'access' => 'user',
        'path' => '/module/web/myext',
        'labels' => 'LLL:EXT:my_ext/Resources/Private/Language/locallang_mod.xlf',
        'extensionName' => 'MyExt',
        'controllerActions' => [
            \Vendor\MyExt\Controller\ModuleController::class => ['list', 'detail'],
        ],
    ],
];
```

### ext_tables.sql: Using CHAR Inappropriately

❌ Before:
```sql
CREATE TABLE tx_myext_table (
    name CHAR(255) DEFAULT '' NOT NULL,  -- Variable content!
);
```

✅ After:
```sql
CREATE TABLE tx_myext_table (
    name VARCHAR(255) DEFAULT '' NOT NULL,  -- Use VARCHAR
);
```

### ext_tables_static+adt.sql: Including CREATE Statements

❌ Before:
```sql
CREATE TABLE tx_myext_categories (
    uid int(11) NOT NULL auto_increment,
    title varchar(255) DEFAULT '' NOT NULL,
    PRIMARY KEY (uid)
);
INSERT INTO tx_myext_categories VALUES (1, 'Category 1');
```

✅ After:
```sql
-- Move CREATE to ext_tables.sql
-- Only INSERT in ext_tables_static+adt.sql
INSERT INTO tx_myext_categories (uid, title) VALUES (1, 'Category 1');
INSERT INTO tx_myext_categories (uid, title) VALUES (2, 'Category 2');
```
