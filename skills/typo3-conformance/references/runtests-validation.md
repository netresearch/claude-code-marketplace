# runTests.sh Validation Guide

**Purpose:** Validate Build/Scripts/runTests.sh against TYPO3 Best Practices (Tea extension reference)

## Why Validate runTests.sh?

The `runTests.sh` script is the **central orchestration tool** for TYPO3 extension quality workflows. An outdated or misconfigured script can lead to:

- ❌ Testing with wrong PHP/TYPO3 versions (false positives/negatives)
- ❌ Missing database compatibility issues
- ❌ Inconsistent local vs CI environments
- ❌ Developer confusion with incorrect defaults

## Reference Implementation

**Source of Truth:** https://github.com/TYPO3BestPractices/tea/blob/main/Build/Scripts/runTests.sh

The Tea extension maintains the canonical runTests.sh implementation, updated for latest TYPO3 standards.

## Critical Validation Points

### 1. PHP Version Configuration

**Check Lines ~318 and ~365:**

```bash
# Default PHP version
PHP_VERSION="X.X"

# PHP version validation regex
if ! [[ ${PHP_VERSION} =~ ^(X.X|X.X|X.X)$ ]]; then
```

**Validation:**
1. Read extension's composer.json `require.php` constraint
2. Extract minimum PHP version (e.g., `^8.2` → minimum 8.2)
3. Verify runTests.sh default matches minimum
4. Verify version regex includes all supported versions

**Example Check:**

```bash
# Extension composer.json
"require": {
    "php": "^8.2 || ^8.3 || ^8.4"
}

# runTests.sh SHOULD have:
PHP_VERSION="8.2"  # ✅ Matches minimum
if ! [[ ${PHP_VERSION} =~ ^(8.2|8.3|8.4)$ ]]; then  # ✅ All supported

# runTests.sh SHOULD NOT have:
PHP_VERSION="7.4"  # ❌ Below minimum
if ! [[ ${PHP_VERSION} =~ ^(7.4|8.0|8.1|8.2|8.3)$ ]]; then  # ❌ Includes unsupported
```

**Severity:** 🔴 **High** - Testing with wrong PHP version invalidates results

### 2. TYPO3 Version Configuration

**Check Lines ~315 and ~374:**

```bash
# Default TYPO3 version
TYPO3_VERSION="XX"

# TYPO3 version validation
if ! [[ ${TYPO3_VERSION} =~ ^(11|12|13)$ ]]; then
```

**Validation:**
1. Read extension's composer.json TYPO3 core dependency
2. Extract target TYPO3 version (e.g., `^13.4` → TYPO3 13)
3. Verify runTests.sh default matches target
4. Check composerInstallHighest/Lowest version constraints

**Example Check:**

```bash
# Extension composer.json
"require": {
    "typo3/cms-core": "^13.4"
}

# runTests.sh SHOULD have:
TYPO3_VERSION="13"  # ✅ Matches target

# In composerInstallHighest (line ~530):
if [ ${TYPO3_VERSION} -eq 13 ]; then
    composer require --no-ansi --no-interaction --no-progress --no-install \
        typo3/cms-core:^13.4  # ✅ Matches composer.json

# runTests.sh SHOULD NOT have:
TYPO3_VERSION="11"  # ❌ Below target
```

**Severity:** 🔴 **High** - Testing against wrong TYPO3 version

### 3. Database Version Support

**Check Lines ~48-107 (handleDbmsOptions function):**

```bash
mariadb)
    [ -z "${DBMS_VERSION}" ] && DBMS_VERSION="X.X"
    if ! [[ ${DBMS_VERSION} =~ ^(10.2|10.3|...|11.1)$ ]]; then
```

**Validation:**
1. Check MariaDB, MySQL, PostgreSQL version lists are current
2. Verify default versions are maintained (not EOL)
3. Cross-reference with TYPO3 core database support matrix

**Current Database Support (TYPO3 13):**

| DBMS | Supported Versions | Default | EOL Status |
|------|-------------------|---------|------------|
| MariaDB | 10.4-10.11, 11.0-11.4 | 10.11 | 10.4+ maintained |
| MySQL | 8.0, 8.1, 8.2, 8.3, 8.4 | 8.0 | 8.0 maintained until 2026 |
| PostgreSQL | 10-16 | 16 | 10-11 EOL, 12+ maintained |
| SQLite | 3.x | 3.x | Always latest |

**Example Check:**

```bash
# runTests.sh MariaDB (line ~48)
[ -z "${DBMS_VERSION}" ] && DBMS_VERSION="10.11"  # ✅ LTS version
if ! [[ ${DBMS_VERSION} =~ ^(10.4|10.5|10.6|10.11|11.0|11.1|11.2|11.3|11.4)$ ]]; then

# ❌ BAD - EOL version as default:
[ -z "${DBMS_VERSION}" ] && DBMS_VERSION="10.2"  # EOL 2023

# runTests.sh PostgreSQL (line ~79)
[ -z "${DBMS_VERSION}" ] && DBMS_VERSION="16"  # ✅ Latest stable
if ! [[ ${DBMS_VERSION} =~ ^(10|11|12|13|14|15|16)$ ]]; then
```

**Severity:** 🟡 **Medium** - May miss database-specific compatibility issues

### 4. Network Name Configuration

**Check Line ~331:**

```bash
NETWORK="extension-name-${SUFFIX}"
```

**Validation:**
1. Should match extension key or composer package name
2. Should NOT be hardcoded to "friendsoftypo3-tea" (copy-paste artifact)

**Example Check:**

```bash
# Extension key: rte_ckeditor_image
# Composer package: netresearch/rte-ckeditor-image

# ✅ Good options:
NETWORK="rte-ckeditor-image-${SUFFIX}"
NETWORK="netresearch-rte-ckeditor-image-${SUFFIX}"

# ❌ Bad (copy-paste from Tea):
NETWORK="friendsoftypo3-tea-${SUFFIX}"
```

**Severity:** 🟢 **Low** - Cosmetic, but indicates lack of customization

### 5. Test Suite Commands

**Check Lines ~580, ~620 (functional and unit test commands):**

```bash
functional)
    COMMAND=(.Build/bin/phpunit -c Build/phpunit/FunctionalTests.xml ...)

unit)
    COMMAND=(.Build/bin/phpunit -c Build/phpunit/UnitTests.xml ...)
```

**Validation:**
1. Paths match actual PHPUnit config locations
2. Config files exist and are properly named
3. Exclude groups match available database types

**Example Check:**

```bash
# Verify config files exist:
ls -la Build/phpunit/UnitTests.xml       # Must exist
ls -la Build/phpunit/FunctionalTests.xml # Must exist

# Check command paths:
COMMAND=(.Build/bin/phpunit -c Build/phpunit/FunctionalTests.xml ...)
         └─────┬─────┘        └──────────┬───────────┘
               ✅ Matches        ✅ Matches actual
           .Build/bin/          Build/phpunit/
           from composer.json   directory structure
```

**Severity:** 🔴 **High** - Tests won't run if paths are wrong

### 6. Container Image Versions

**Check Lines ~446-451:**

```bash
IMAGE_PHP="ghcr.io/typo3/core-testing-$(echo "php${PHP_VERSION}" | sed -e 's/\.//'):latest"
IMAGE_ALPINE="docker.io/alpine:3.8"
IMAGE_DOCS="ghcr.io/typo3-documentation/render-guides:latest"
IMAGE_MARIADB="docker.io/mariadb:${DBMS_VERSION}"
IMAGE_MYSQL="docker.io/mysql:${DBMS_VERSION}"
IMAGE_POSTGRES="docker.io/postgres:${DBMS_VERSION}-alpine"
```

**Validation:**
1. PHP testing image uses official TYPO3 images
2. Alpine version is reasonably current (not ancient)
3. Documentation renderer is latest official TYPO3 image

**Severity:** 🟢 **Low** - Usually works, but outdated Alpine may have issues

## Conformance Evaluation Workflow

### Step 1: Extract Extension Requirements

```bash
# Read composer.json
cat composer.json | jq -r '.require.php'           # e.g., "^8.2 || ^8.3 || ^8.4"
cat composer.json | jq -r '.require."typo3/cms-core"'  # e.g., "^13.4"

# Parse minimum versions
MIN_PHP=$(echo "^8.2 || ^8.3" | grep -oE '[0-9]+\.[0-9]+' | head -1)  # 8.2
TARGET_TYPO3=$(echo "^13.4" | grep -oE '[0-9]+')  # 13
```

### Step 2: Validate runTests.sh Defaults

```bash
# Check PHP version default (line ~318)
grep '^PHP_VERSION=' Build/Scripts/runTests.sh
# Expected: PHP_VERSION="8.2" (matches MIN_PHP)

# Check TYPO3 version default (line ~315)
grep '^TYPO3_VERSION=' Build/Scripts/runTests.sh
# Expected: TYPO3_VERSION="13" (matches TARGET_TYPO3)
```

### Step 3: Validate PHP Version Regex

```bash
# Extract PHP version regex (line ~365)
grep -A 2 'if ! \[\[ \${PHP_VERSION}' Build/Scripts/runTests.sh

# Expected pattern for "^8.2 || ^8.3 || ^8.4":
# ^(8.2|8.3|8.4)$

# ❌ Outdated pattern:
# ^(7.4|8.0|8.1|8.2|8.3)$
```

### Step 4: Validate TYPO3 Version Constraints in Composer Install

```bash
# Check composerInstallHighest TYPO3 13 block (line ~530)
sed -n '/if \[ \${TYPO3_VERSION} -eq 13 \];/,/fi/p' Build/Scripts/runTests.sh

# Should match composer.json requirements:
# typo3/cms-core:^13.4
# typo3/cms-backend:^13.4
# etc.
```

### Step 5: Validate Network Name

```bash
# Check network name (line ~331)
grep '^NETWORK=' Build/Scripts/runTests.sh

# Extract extension key from composer.json or ext_emconf.php
EXT_KEY=$(jq -r '.extra.typo3.cms."extension-key"' composer.json)

# Expected: NETWORK="${EXT_KEY}-${SUFFIX}" or similar
# ❌ Wrong: NETWORK="friendsoftypo3-tea-${SUFFIX}"
```

## Automated Validation Script

Create `scripts/validate-runtests.sh`:

```bash
#!/bin/bash

set -e

echo "🔍 Validating Build/Scripts/runTests.sh against extension requirements..."

# Extract requirements
MIN_PHP=$(jq -r '.require.php' composer.json | grep -oE '[0-9]+\.[0-9]+' | head -1)
TARGET_TYPO3=$(jq -r '.require."typo3/cms-core"' composer.json | grep -oE '^[0-9]+' | head -1)
EXT_KEY=$(jq -r '.extra.typo3.cms."extension-key"' composer.json)

echo "📋 Extension Requirements:"
echo "  PHP: ${MIN_PHP}+"
echo "  TYPO3: ${TARGET_TYPO3}"
echo "  Extension Key: ${EXT_KEY}"
echo ""

# Validate PHP version default
RUNTESTS_PHP=$(grep '^PHP_VERSION=' Build/Scripts/runTests.sh | cut -d'"' -f2)
if [ "${RUNTESTS_PHP}" != "${MIN_PHP}" ]; then
    echo "❌ PHP version mismatch: runTests.sh uses ${RUNTESTS_PHP}, should be ${MIN_PHP}"
    exit 1
else
    echo "✅ PHP version default: ${RUNTESTS_PHP}"
fi

# Validate TYPO3 version default
RUNTESTS_TYPO3=$(grep '^TYPO3_VERSION=' Build/Scripts/runTests.sh | cut -d'"' -f2)
if [ "${RUNTESTS_TYPO3}" != "${TARGET_TYPO3}" ]; then
    echo "❌ TYPO3 version mismatch: runTests.sh uses ${RUNTESTS_TYPO3}, should be ${TARGET_TYPO3}"
    exit 1
else
    echo "✅ TYPO3 version default: ${RUNTESTS_TYPO3}"
fi

# Validate network name
NETWORK_NAME=$(grep '^NETWORK=' Build/Scripts/runTests.sh | cut -d'"' -f2 | sed 's/-${SUFFIX}$//')
if [[ "${NETWORK_NAME}" == "friendsoftypo3-tea" ]]; then
    echo "⚠️  Network name is copy-paste from Tea extension: ${NETWORK_NAME}"
    echo "   Should be: ${EXT_KEY}-\${SUFFIX}"
else
    echo "✅ Network name: ${NETWORK_NAME}-\${SUFFIX}"
fi

echo ""
echo "✅ runTests.sh validation complete"
```

## Conformance Report Integration

### When evaluating runTests.sh:

**In "Best Practices" Section:**

```markdown
### Build Scripts

**runTests.sh Analysis:**

- ✅ Script present and executable
- ✅ PHP version default matches composer.json minimum (8.2)
- ✅ TYPO3 version default matches target (13)
- ✅ PHP version regex includes all supported versions (8.2, 8.3, 8.4)
- ⚠️  Network name uses Tea extension default (cosmetic issue)
- ✅ Test suite commands match actual file structure
- ✅ Database version support is current

**Or with issues:**

- ❌ PHP version default (7.4) below extension minimum (8.2)
  - File: Build/Scripts/runTests.sh:318
  - Severity: High
  - Fix: Change `PHP_VERSION="7.4"` to `PHP_VERSION="8.2"`

- ❌ TYPO3 version default (11) below extension target (13)
  - File: Build/Scripts/runTests.sh:315
  - Severity: High
  - Fix: Change `TYPO3_VERSION="11"` to `TYPO3_VERSION="13"`

- ❌ PHP version regex includes unsupported versions
  - File: Build/Scripts/runTests.sh:365
  - Current: `^(7.4|8.0|8.1|8.2|8.3)$`
  - Expected: `^(8.2|8.3|8.4)$`
  - Severity: Medium
  - Fix: Remove unsupported versions from regex
```

## Scoring Impact

**Best Practices Score Deductions:**

| Issue | Severity | Score Impact |
|-------|----------|--------------|
| PHP version default outdated | High | -3 points |
| TYPO3 version default outdated | High | -3 points |
| PHP version regex includes unsupported | Medium | -2 points |
| Database versions EOL | Medium | -2 points |
| Network name copy-paste | Low | -1 point |
| Missing runTests.sh | Critical | -10 points |

**Maximum deduction for runTests.sh issues:** -6 points (out of 20 for Best Practices)

## Quick Reference Checklist

**When evaluating Build/Scripts/runTests.sh:**

```
□ File exists and is executable
□ PHP_VERSION default matches composer.json minimum
□ TYPO3_VERSION default matches composer.json target
□ PHP version regex matches composer.json constraint exactly
□ TYPO3_VERSION regex includes supported versions only
□ Database version lists are current (not EOL)
□ Database version defaults are maintained LTS versions
□ Network name is customized (not "friendsoftypo3-tea")
□ Test suite paths match actual directory structure
□ Container images use official TYPO3 testing images
```

**Comparison Strategy:**

1. Download latest Tea runTests.sh as reference
2. Compare line-by-line for structural differences
3. Validate version-specific values against extension requirements
4. Flag any outdated patterns or hardcoded Tea-specific values

## Resources

- **Tea Extension runTests.sh:** https://github.com/TYPO3BestPractices/tea/blob/main/Build/Scripts/runTests.sh
- **TYPO3 Testing Documentation:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/
- **Database Compatibility:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/Database/
