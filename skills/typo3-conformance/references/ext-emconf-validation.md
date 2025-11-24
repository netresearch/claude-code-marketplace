# ext_emconf.php Validation Standards (TYPO3 v13)

**Source:** TYPO3 Core API Reference v13.4 - FileStructure/ExtEmconf.html
**Purpose:** Complete validation rules for ext_emconf.php including critical TER restrictions

## CRITICAL RESTRICTIONS

### ❌ MUST NOT use declare(strict_types=1)

**CRITICAL:** The TYPO3 Extension Repository (TER) upload **WILL FAIL** if `declare(strict_types=1)` is present in ext_emconf.php.

❌ **WRONG:**
```php
<?php
declare(strict_types=1);
$EM_CONF[$_EXTKEY] = [
    // configuration
];
```

✅ **CORRECT:**
```php
<?php
$EM_CONF[$_EXTKEY] = [
    // configuration
];
```

**Detection:**
```bash
grep "declare(strict_types" ext_emconf.php && echo "❌ CRITICAL: TER upload will FAIL" || echo "✅ No strict_types"
```

### ✅ MUST use $_EXTKEY variable

Extensions must reference the global `$_EXTKEY` variable, not hardcode the extension key.

❌ **WRONG:**
```php
$EM_CONF['my_extension'] = [
    // configuration
];
```

✅ **CORRECT:**
```php
$EM_CONF[$_EXTKEY] = [
    // configuration
];
```

**Detection:**
```bash
grep '\$EM_CONF\[$_EXTKEY\]' ext_emconf.php && echo "✅ Uses $_EXTKEY" || echo "❌ Hardcoded key"
```

---

## Mandatory Fields

### title
**Format:** English extension name

**Example:**
```php
'title' => 'My Extension',
```

**Validation:**
```bash
grep "'title' =>" ext_emconf.php && echo "✅ Has title" || echo "❌ Missing title"
```

### description
**Format:** Short, precise English description

**Example:**
```php
'description' => 'Provides advanced content management features',
```

**Validation:**
```bash
grep "'description' =>" ext_emconf.php && echo "✅ Has description" || echo "❌ Missing description"
```

### version
**Format:** `[int].[int].[int]` (semantic versioning)

**Examples:**
- `1.0.0` ✅
- `2.5.12` ✅
- `v1.0.0` ❌ (no 'v' prefix)
- `1.0` ❌ (must have three parts)

**Validation:**
```bash
grep -oP "'version' => '\K[0-9]+\.[0-9]+\.[0-9]+" ext_emconf.php && echo "✅ Valid version format" || echo "❌ Invalid version"
```

---

## Category Options

**Valid categories:**

| Category | Purpose |
|----------|---------|
| `be` | Backend-oriented functionality |
| `module` | Backend modules |
| `fe` | Frontend-oriented functionality |
| `plugin` | Frontend plugins |
| `misc` | Miscellaneous utilities |
| `services` | TYPO3 services |
| `templates` | Website templates |
| `example` | Example/demonstration extensions |
| `doc` | Documentation |
| `distribution` | Full site distributions/kickstarters |

**Example:**
```php
'category' => 'fe',
```

**Validation:**
```bash
grep -oP "'category' => '\K[a-z]+(?=')" ext_emconf.php | grep -qE '^(be|module|fe|plugin|misc|services|templates|example|doc|distribution)$' && echo "✅ Valid category" || echo "❌ Invalid category"
```

---

## State Values

**Valid states:**

| State | Meaning |
|-------|---------|
| `alpha` | Initial development phase, unstable |
| `beta` | Functional but incomplete or under active development |
| `stable` | Production-ready (author commits to maintenance) |
| `experimental` | Exploratory work, may be abandoned |
| `test` | Demonstration or testing purposes only |
| `obsolete` | Deprecated or unmaintained |
| `excludeFromUpdates` | Prevents Extension Manager from updating |

**Example:**
```php
'state' => 'stable',
```

**Validation:**
```bash
grep -oP "'state' => '\K[a-z]+(?=')" ext_emconf.php | grep -qE '^(alpha|beta|stable|experimental|test|obsolete|excludeFromUpdates)$' && echo "✅ Valid state" || echo "❌ Invalid state"
```

---

## Constraints Structure

### Format
```php
'constraints' => [
    'depends' => [
        'typo3' => '13.4.0-13.4.99',
        'php' => '8.2.0-8.4.99',
    ],
    'conflicts' => [
        'incompatible_ext' => '',
    ],
    'suggests' => [
        'recommended_ext' => '1.0.0-2.99.99',
    ],
],
```

### depends
**Purpose:** Required dependencies loaded before this extension

**Mandatory entries:**
- `typo3` - TYPO3 version range
- `php` - PHP version range

**Example:**
```php
'depends' => [
    'typo3' => '12.4.0-13.4.99',
    'php' => '8.1.0-8.4.99',
    'fluid' => '12.4.0-13.4.99',
],
```

**Validation:**
```bash
grep -A 5 "'depends' =>" ext_emconf.php | grep -q "'typo3'" && echo "✅ TYPO3 dependency" || echo "❌ Missing TYPO3 dep"
grep -A 5 "'depends' =>" ext_emconf.php | grep -q "'php'" && echo "✅ PHP dependency" || echo "❌ Missing PHP dep"
```

### conflicts
**Purpose:** Extensions incompatible with this one

**Example:**
```php
'conflicts' => [
    'old_extension' => '',
],
```

### suggests
**Purpose:** Recommended companion extensions (loaded before current extension)

**Example:**
```php
'suggests' => [
    'news' => '12.1.0-12.99.99',
],
```

---

## Version Constraint Format

### TYPO3 Version
**Format:** `major.minor.patch-major.minor.patch`

**Examples:**
- `12.4.0-12.4.99` - TYPO3 12 LTS only
- `13.4.0-13.4.99` - TYPO3 13 LTS only
- `12.4.0-13.4.99` - Both v12 and v13 (recommended for compatibility)

### PHP Version
**Format:** `major.minor.patch-major.minor.patch`

**TYPO3 Compatibility:**
- TYPO3 12 LTS: PHP 8.1-8.4
- TYPO3 13 LTS: PHP 8.2-8.4

**Example:**
```php
'php' => '8.1.0-8.4.99',  // For v12/v13 compatibility
'php' => '8.2.0-8.4.99',  // For v13 only
```

---

## Synchronization with composer.json

**Critical:** ext_emconf.php and composer.json must have matching constraints.

### Mapping Table

| composer.json | ext_emconf.php | Example |
|--------------|----------------|---------|
| `"typo3/cms-core": "^12.4 \|\| ^13.4"` | `'typo3' => '12.4.0-13.4.99'` | TYPO3 version |
| `"php": "^8.1"` | `'php' => '8.1.0-8.4.99'` | PHP version |
| `"typo3/cms-fluid": "^12.4"` | `'fluid' => '12.4.0-12.4.99'` | Extension dependency |

### Validation Strategy
```bash
# Compare TYPO3 versions
COMPOSER_TYPO3=$(jq -r '.require."typo3/cms-core"' composer.json)
EMCONF_TYPO3=$(grep -oP "'typo3' => '\K[0-9.-]+" ext_emconf.php)
echo "Composer: $COMPOSER_TYPO3"
echo "ext_emconf: $EMCONF_TYPO3"
# Manual comparison required for ^x.y vs x.y.z-x.y.z format
```

---

## Complete Validation Script

```bash
#!/bin/bash
# validate-ext-emconf.sh

ERRORS=0
WARNINGS=0

echo "=== ext_emconf.php Validation ===="
echo ""

# CRITICAL: Check for strict_types
if grep -q "declare(strict_types" ext_emconf.php 2>/dev/null; then
    echo "❌ CRITICAL: ext_emconf.php has declare(strict_types=1)"
    echo "   TER upload will FAIL!"
    ((ERRORS++))
fi

# CRITICAL: Check for $_EXTKEY usage
if ! grep -q '\$EM_CONF\[$_EXTKEY\]' ext_emconf.php 2>/dev/null; then
    echo "❌ CRITICAL: Must use \$EM_CONF[\$_EXTKEY], not hardcoded key"
    ((ERRORS++))
fi

# Check mandatory fields
grep -q "'title' =>" ext_emconf.php || { echo "❌ Missing title"; ((ERRORS++)); }
grep -q "'description' =>" ext_emconf.php || { echo "❌ Missing description"; ((ERRORS++)); }
grep -qP "'version' => '[0-9]+\.[0-9]+\.[0-9]+" ext_emconf.php || { echo "❌ Missing or invalid version"; ((ERRORS++)); }

# Check category
CATEGORY=$(grep -oP "'category' => '\K[a-z]+(?=')" ext_emconf.php)
if [[ ! "$CATEGORY" =~ ^(be|module|fe|plugin|misc|services|templates|example|doc|distribution)$ ]]; then
    echo "❌ Invalid category: $CATEGORY"
    ((ERRORS++))
fi

# Check state
STATE=$(grep -oP "'state' => '\K[a-z]+(?=')" ext_emconf.php)
if [[ ! "$STATE" =~ ^(alpha|beta|stable|experimental|test|obsolete|excludeFromUpdates)$ ]]; then
    echo "❌ Invalid state: $STATE"
    ((ERRORS++))
fi

# Check constraints
grep -A 5 "'depends' =>" ext_emconf.php | grep -q "'typo3'" || { echo "❌ Missing TYPO3 dependency"; ((ERRORS++)); }
grep -A 5 "'depends' =>" ext_emconf.php | grep -q "'php'" || { echo "❌ Missing PHP dependency"; ((ERRORS++)); }

echo ""
echo "Validation complete: $ERRORS errors, $WARNINGS warnings"
exit $ERRORS
```

---

## Common Violations and Fixes

### 1. Using declare(strict_types=1)

❌ **WRONG - TER upload FAILS:**
```php
<?php
declare(strict_types=1);
$EM_CONF[$_EXTKEY] = [
    'title' => 'My Extension',
];
```

✅ **CORRECT:**
```php
<?php
$EM_CONF[$_EXTKEY] = [
    'title' => 'My Extension',
];
```

### 2. Hardcoded Extension Key

❌ **WRONG:**
```php
$EM_CONF['my_extension'] = [
    'title' => 'My Extension',
];
```

✅ **CORRECT:**
```php
$EM_CONF[$_EXTKEY] = [
    'title' => 'My Extension',
];
```

### 3. Invalid Category

❌ **WRONG:**
```php
'category' => 'utility',  // Not a valid category
```

✅ **CORRECT:**
```php
'category' => 'misc',  // Use 'misc' for utilities
```

### 4. Invalid Version Format

❌ **WRONG:**
```php
'version' => 'v1.0.0',  // No 'v' prefix
'version' => '1.0',     // Must have 3 parts
```

✅ **CORRECT:**
```php
'version' => '1.0.0',
```

### 5. Missing PHP/TYPO3 Constraints

❌ **WRONG:**
```php
'constraints' => [
    'depends' => [
        'extbase' => '12.4.0-12.4.99',
    ],
],
```

✅ **CORRECT:**
```php
'constraints' => [
    'depends' => [
        'typo3' => '12.4.0-13.4.99',
        'php' => '8.1.0-8.4.99',
        'extbase' => '12.4.0-12.4.99',
    ],
],
```

### 6. Mismatched composer.json Constraints

❌ **WRONG:**

composer.json:
```json
"require": {
    "typo3/cms-core": "^13.4"
}
```

ext_emconf.php:
```php
'typo3' => '12.4.0-12.4.99',  // Mismatch!
```

✅ **CORRECT:**

composer.json:
```json
"require": {
    "typo3/cms-core": "^13.4"
}
```

ext_emconf.php:
```php
'typo3' => '13.4.0-13.4.99',  // Matches!
```

---

## Quick Reference

### Critical Checks
```bash
# Will TER upload fail?
grep "declare(strict_types" ext_emconf.php && echo "❌ TER FAIL"

# Uses $_EXTKEY?
grep '\$EM_CONF\[$_EXTKEY\]' ext_emconf.php && echo "✅ OK"

# Valid category?
grep -oP "'category' => '\K[a-z]+(?=')" ext_emconf.php | grep -qE '^(be|module|fe|plugin|misc|services|templates|example|doc|distribution)$' && echo "✅ OK"

# Valid state?
grep -oP "'state' => '\K[a-z]+(?=')" ext_emconf.php | grep -qE '^(alpha|beta|stable|experimental|test|obsolete|excludeFromUpdates)$' && echo "✅ OK"
```
