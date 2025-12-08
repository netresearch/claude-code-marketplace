# TYPO3 12 CLI Setup Command Changes

> **Source**: Real-world experience from netresearch/contexts extension upgrade (2024-12)

## Breaking Changes in TYPO3 12 Setup Command

### 1. Admin Password Option Renamed

**TYPO3 11.x**:
```bash
./vendor/bin/typo3 setup --admin-password='Password:joh316'
```

**TYPO3 12.x+**:
```bash
./vendor/bin/typo3 setup --admin-user-password='Password:joh316'
```

**Error if using old option**:
```
The "--admin-password" option does not exist.
```

### 2. Server Type Now Required

**TYPO3 11.x**: `--server-type` was optional
**TYPO3 12.x+**: `--server-type` must be explicitly provided

```bash
# Error without --server-type
Argument #1 ($serverType) must be of type string, bool given

# Fix: Add explicit server type
./vendor/bin/typo3 setup --server-type=apache ...
```

Valid server types: `apache`, `nginx`, `other`

### 3. Extension Activation Command Removed

**TYPO3 11.x**:
```bash
./vendor/bin/typo3 extension:activate contexts
```

**TYPO3 12.x+**: Command does not exist
```
The command "extension:activate" does not exist.
```

**Reason**: Extensions installed via Composer are automatically loaded. No manual activation needed.

**Alternative** (if needed for legacy flow):
```bash
# Just verify the extension is in PackageStates
./vendor/bin/typo3 extension:list | grep contexts
```

### 4. Config Directory Structure

**TYPO3 12.x** requires `config/system/` directory for `additional.php`:
```bash
mkdir -p config/system
# Then create config/system/additional.php
```

### 5. Composer Platform PHP Version

When extension requires higher PHP than TYPO3 base distribution default:

```bash
# TYPO3 base sets platform.php to 8.1.1
# Extension requires ^8.2
# Fix: Override platform version
composer config platform.php 8.2
```

## Complete TYPO3 12 Setup Command

```bash
./vendor/bin/typo3 setup \
  --driver=mysqli \
  --host=db \
  --port=3306 \
  --dbname=db_v12 \
  --username=db \
  --password=db \
  --admin-username=admin \
  --admin-user-password='Password:joh316' \
  --admin-email=admin@example.com \
  --project-name="Extension v12" \
  --server-type=apache \
  --no-interaction \
  --force
```

## Install Script Template for TYPO3 12

See `templates/commands/install-v12` for a complete working install script that handles all these changes.

## Version Detection

To make scripts work across TYPO3 versions:

```bash
TYPO3_VERSION=$(./vendor/bin/typo3 --version 2>/dev/null | grep -oP '\d+\.\d+')

if [[ "$TYPO3_VERSION" == "12."* ]] || [[ "$TYPO3_VERSION" == "13."* ]]; then
    # Use --admin-user-password and --server-type
    ADMIN_PASS_OPT="--admin-user-password"
    SERVER_TYPE_OPT="--server-type=apache"
else
    # TYPO3 11 and earlier
    ADMIN_PASS_OPT="--admin-password"
    SERVER_TYPE_OPT=""
fi
```
