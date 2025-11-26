# Composer.json Validation Standards (TYPO3 v13)

**Source:** TYPO3 Core API Reference v13.4 - FileStructure/ComposerJson.html
**Purpose:** Complete validation rules for composer.json in TYPO3 extensions

## Mandatory Fields

### name
**Format:** `<vendor>/<dashed-extension-key>`

**Examples:**
```json
"name": "vendor-name/my-extension"
"name": "johndoe/some-extension"
```

**Validation:**
```bash
jq -r '.name' composer.json | grep -E '^[a-z0-9-]+/[a-z0-9-]+$' && echo "✅ Valid" || echo "❌ Invalid format"
```

### type
**Required Value:** `typo3-cms-extension` (for third-party extensions)

**Validation:**
```bash
jq -r '.type' composer.json | grep -q "typo3-cms-extension" && echo "✅ Correct type" || echo "❌ Wrong type"
```

### description
**Format:** Single-line summary describing what the extension does

**Requirements:**
- Clear, concise description of extension functionality
- Should identify the vendor/company for professional extensions
- Avoid vague descriptions like "An extension" or "Utility tools"

**Good Examples:**
```json
"description": "Adds image support to CKEditor5 RTE - by Netresearch"
"description": "TYPO3 extension for advanced content management by Vendor GmbH"
"description": "Provides custom form elements for newsletter subscription"
```

**Bad Examples:**
```json
"description": "Extension"  // Too vague
"description": "Some tools"  // Meaningless
"description": ""  // Empty
```

**Validation:**
```bash
# Check description exists and is not empty
jq -r '.description' composer.json | grep -q . && echo "✅ Has description" || echo "❌ Missing description"

# Check description length (should be meaningful, >20 chars)
DESC_LEN=$(jq -r '.description | length' composer.json)
[[ $DESC_LEN -gt 20 ]] && echo "✅ Description is meaningful" || echo "⚠️  Description too short"
```

### license
**Recommended:** `GPL-2.0-only` or `GPL-2.0-or-later`

**Validation:**
```bash
jq -r '.license' composer.json | grep -qE "GPL-2.0-(only|or-later)" && echo "✅ GPL license" || echo "⚠️  Check license"
```

### require
**Minimum:** Must specify `typo3/cms-core` with version constraints

**Version Constraint Format:**
- `^12.4 || ^13.4` - Multiple major versions (recommended for v12/v13 compat)
- `^12.4` - Single major version
- `>=12.4` ❌ - NO upper bound (not recommended)

**Validation:**
```bash
# Check typo3/cms-core present
jq -r '.require["typo3/cms-core"]' composer.json | grep -q . && echo "✅ TYPO3 core required" || echo "❌ Missing typo3/cms-core"

# Check for upper bound (^ or specific upper version)
jq -r '.require["typo3/cms-core"]' composer.json | grep -qE '(\^|[0-9]+\.[0-9]+\.[0-9]+-[0-9]+\.[0-9]+\.[0-9]+)' && echo "✅ Has upper bound" || echo "⚠️  Missing upper bound"
```

### autoload
**Format:** PSR-4 mapping to Classes/ directory

**Example:**
```json
"autoload": {
    "psr-4": {
        "Vendor\\ExtensionName\\": "Classes/"
    }
}
```

**Validation:**
```bash
jq -r '.autoload["psr-4"]' composer.json | grep -q "Classes" && echo "✅ PSR-4 autoload configured" || echo "❌ Missing autoload"
```

### extra.typo3/cms.extension-key
**Required:** Maps to underscored extension key

**Example:**
```json
"extra": {
    "typo3/cms": {
        "extension-key": "my_extension"
    }
}
```

**Validation:**
```bash
jq -r '.extra."typo3/cms"."extension-key"' composer.json | grep -q . && echo "✅ Extension key defined" || echo "❌ Missing extension-key"
```

---

## Recommended Fields (Professional Extensions)

### authors
**Format:** Array of author objects with name, email, role, homepage

**Example:**
```json
"authors": [
    {
        "name": "Developer Name",
        "email": "developer@company.com",
        "role": "Developer",
        "homepage": "https://www.company.com/"
    }
]
```

**Required Sub-Fields:**
| Field | Format | Purpose |
|-------|--------|---------|
| `name` | String | Developer's full name |
| `email` | Email address | Contact email |
| `role` | String | `Developer`, `Maintainer`, `Lead Developer` |
| `homepage` | URL | Company or personal website |

**Validation:**
```bash
# Check authors array exists
jq -r '.authors' composer.json | grep -q "name" && echo "✅ Has authors" || echo "⚠️  Missing authors"

# Check authors have email
jq -r '.authors[].email' composer.json | grep -q "@" && echo "✅ Has author emails" || echo "⚠️  Missing author emails"

# Check authors have homepage
jq -r '.authors[].homepage' composer.json | grep -q "http" && echo "✅ Has author homepage" || echo "⚠️  Missing author homepage"
```

### homepage
**Format:** URL to project repository or documentation

**Example:**
```json
"homepage": "https://github.com/vendor/extension-name"
```

**Validation:**
```bash
jq -r '.homepage' composer.json | grep -qE "^https?://" && echo "✅ Has homepage" || echo "⚠️  Missing homepage"
```

### support
**Format:** Object with support channels

**Example:**
```json
"support": {
    "issues": "https://github.com/vendor/extension/issues",
    "source": "https://github.com/vendor/extension"
}
```

**Validation:**
```bash
jq -r '.support.issues' composer.json | grep -q "http" && echo "✅ Has issues URL" || echo "⚠️  Missing issues URL"
```

### keywords
**Format:** Array of relevant keywords for discoverability

**Example:**
```json
"keywords": [
    "TYPO3",
    "extension",
    "content",
    "management"
]
```

**Validation:**
```bash
jq -r '.keywords | length' composer.json | grep -qE '^[1-9]' && echo "✅ Has keywords" || echo "⚠️  Missing keywords"
```

---

## Complete Required Fields Checklist

**Mandatory (MUST have):**
- [ ] `name` - vendor/package format
- [ ] `type` - must be `typo3-cms-extension`
- [ ] `description` - clear, concise description
- [ ] `license` - SPDX identifier (GPL-2.0-or-later, AGPL-3.0-or-later)
- [ ] `require.typo3/cms-core` - with upper bound constraint
- [ ] `require.php` - PHP version constraint
- [ ] `autoload.psr-4` - mapping to Classes/
- [ ] `extra.typo3/cms.extension-key` - underscored extension key

**Recommended (SHOULD have):**
- [ ] `authors` - with name, email, role, homepage
- [ ] `homepage` - project repository URL
- [ ] `support.issues` - issue tracker URL
- [ ] `keywords` - for discoverability

---

## Deprecated Properties

### replace with typo3-ter vendor
**Status:** DEPRECATED - Legacy TER integration approach

**Detection:**
```bash
jq -r '.replace' composer.json | grep -q "typo3-ter" && echo "⚠️  Deprecated: typo3-ter in replace" || echo "✅ No deprecated replace"
```

### replace with "ext_key": "self.version"
**Status:** DEPRECATED - Legacy dependency specification

**Detection:**
```bash
jq -r '.replace' composer.json | grep -qE '"[a-z_]+": "self.version"' && echo "⚠️  Deprecated: self.version replace" || echo "✅ No self.version"
```

---

## TYPO3 v12-v13 Version Constraints

### Recommended Format
```json
"require": {
    "typo3/cms-core": "^12.4 || ^13.4",
    "php": "^8.1"
}
```

### PHP Version Constraints
```json
"require": {
    "php": "^8.1"  // TYPO3 v12: PHP 8.1-8.4
}
```

**Validation:**
```bash
# Check PHP constraint
jq -r '.require.php' composer.json | grep -qE '\^8\.[1-4]' && echo "✅ Valid PHP constraint" || echo "⚠️  Check PHP version"
```

---

## Synchronization with ext_emconf.php

**Critical:** `composer.json` and `ext_emconf.php` must have matching dependency constraints.

**Mapping:**

| composer.json | ext_emconf.php |
|--------------|----------------|
| `require.typo3/cms-core` | `constraints.depends.typo3` |
| `require.php` | `constraints.depends.php` |
| `require.*` | `constraints.depends.*` |

**Example Synchronization:**

composer.json:
```json
"require": {
    "typo3/cms-core": "^12.4 || ^13.4",
    "php": "^8.1",
    "typo3/cms-fluid": "^12.4 || ^13.4"
}
```

ext_emconf.php:
```php
'constraints' => [
    'depends' => [
        'typo3' => '12.4.0-13.4.99',
        'php' => '8.1.0-8.4.99',
        'fluid' => '12.4.0-13.4.99',
    ],
],
```

---

## Complete Validation Script

```bash
#!/bin/bash
# validate-composer.sh

ERRORS=0

echo "=== Composer.json Validation ===="

# Check mandatory fields
jq -r '.name' composer.json > /dev/null 2>&1 || { echo "❌ Missing 'name'"; ((ERRORS++)); }
jq -r '.type' composer.json | grep -q "typo3-cms-extension" || { echo "❌ Wrong or missing 'type'"; ((ERRORS++)); }
jq -r '.description' composer.json | grep -q . || { echo "❌ Missing 'description'"; ((ERRORS++)); }

# Check description is meaningful (>20 chars)
DESC_LEN=$(jq -r '.description | length' composer.json 2>/dev/null)
[[ $DESC_LEN -lt 20 ]] && { echo "⚠️  Description too short (should be >20 chars)"; ((WARNINGS++)); }

# Check typo3/cms-core
jq -r '.require["typo3/cms-core"]' composer.json | grep -q . || { echo "❌ Missing typo3/cms-core"; ((ERRORS++)); }

# Check version constraints have upper bounds
jq -r '.require["typo3/cms-core"]' composer.json | grep -qE '(\^|[0-9]+\.[0-9]+\.[0-9]+-[0-9]+\.[0-9]+\.[0-9]+)' || { echo "⚠️  TYPO3 constraint missing upper bound"; ((ERRORS++)); }

# Check autoload
jq -r '.autoload["psr-4"]' composer.json | grep -q "Classes" || { echo "❌ Missing PSR-4 autoload"; ((ERRORS++)); }

# Check extension-key
jq -r '.extra."typo3/cms"."extension-key"' composer.json | grep -q . || { echo "❌ Missing extension-key"; ((ERRORS++)); }

# Check for deprecated replace
jq -r '.replace' composer.json 2>/dev/null | grep -q "typo3-ter\|self.version" && echo "⚠️  Deprecated replace property found"

echo ""
echo "Validation complete: $ERRORS critical errors"
exit $ERRORS
```

---

## Optional but Recommended Fields

### require-dev
**Purpose:** Development dependencies not needed in production

**Example:**
```json
"require-dev": {
    "typo3/coding-standards": "^0.7",
    "phpstan/phpstan": "^1.10",
    "phpunit/phpunit": "^10.0"
}
```

### suggest
**Purpose:** Optional packages that enhance functionality

**Example:**
```json
"suggest": {
    "typo3/cms-filelist": "For file browser functionality",
    "typo3/cms-reactions": "For webhook support"
}
```

---

## Best Practices

1. **Packagist Publication:** Publishing to Packagist makes extensions available in TYPO3 Extension Repository automatically
2. **Documentation Rendering:** `composer.json` is **REQUIRED** for extensions with documentation on docs.typo3.org
3. **Version Constraint Strategy:**
   - Use `^` for flexible upper bounds
   - Specify both major version ranges for v12/v13 compatibility
   - Always include upper bounds (avoid `>=` without upper limit)
4. **Namespace Alignment:** PSR-4 namespace should match vendor/extension structure
5. **Composer Priority:** Composer-based installations prioritize `composer.json` over `ext_emconf.php` for dependency resolution

---

## Common Violations and Fixes

### Missing extra.typo3/cms.extension-key

❌ **Before:**
```json
{
    "name": "vendor/my-extension",
    "type": "typo3-cms-extension"
}
```

✅ **After:**
```json
{
    "name": "vendor/my-extension",
    "type": "typo3-cms-extension",
    "extra": {
        "typo3/cms": {
            "extension-key": "my_extension"
        }
    }
}
```

### Version Constraint Without Upper Bound

❌ **Before:**
```json
"require": {
    "typo3/cms-core": ">=12.4"
}
```

✅ **After:**
```json
"require": {
    "typo3/cms-core": "^12.4 || ^13.4"
}
```

### Deprecated replace Property

❌ **Before:**
```json
"replace": {
    "typo3-ter/my-extension": "self.version"
}
```

✅ **After:**
```json
// Remove replace property entirely
```

---

## Additional Validation Commands

### Check all required dependencies have upper bounds
```bash
jq -r '.require | to_entries[] | select(.value | test(">=") and (test("\\^") | not)) | .key' composer.json
```

### Verify package type
```bash
jq -r '.type' composer.json | grep -q "typo3-cms-extension" && echo "✅" || echo "❌ Wrong package type"
```

### Check PSR-4 namespace format
```bash
jq -r '.autoload["psr-4"] | keys[]' composer.json | grep -E '^[A-Z][a-zA-Z0-9]*\\\\[A-Z][a-zA-Z0-9]*\\\\$' && echo "✅ Valid namespace" || echo "⚠️  Check namespace format"
```

### Validate JSON syntax
```bash
jq . composer.json > /dev/null && echo "✅ Valid JSON" || echo "❌ JSON syntax error"
```
