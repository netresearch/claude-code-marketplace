# Windows Performance Optimizations

## Key Learnings

### 1. Use Docker Volumes (Not Bind Mounts)

**Performance Impact:** 3-5x faster installations

```yaml
# ✅ FAST: Docker volumes
volumes:
    v12-data:/var/www/html/v12
    v13-data:/var/www/html/v13

# ❌ SLOW: Bind mounts
volumes:
    - type: bind
      source: ./typo3-installations/v12
      target: /var/www/html/v12
```

**Why:** Docker Desktop on Windows translates filesystem calls between Windows and Linux, making bind mounts significantly slower.

### 2. Fix Volume Permissions with sudo chown

```bash
# At start of install scripts
INSTALL_DIR=/var/www/html/v13
sudo rm -rf $INSTALL_DIR/*
sudo mkdir -p $INSTALL_DIR
sudo chown -R $(whoami):$(whoami) $INSTALL_DIR
```

This is the **critical Windows fix** that makes volumes work.

### 3. Preserve UTF-8 When Converting Line Endings

```powershell
# ✅ CORRECT: Preserves emojis
$content = Get-Content $file -Raw -Encoding UTF8
$content = $content -replace "`r`n", "`n"
[System.IO.File]::WriteAllText((Resolve-Path $file).Path, $content, [System.Text.UTF8Encoding]::new($false))

# ❌ WRONG: Corrupts emojis (🚀 → ??)
(Get-Content $file -Raw) -replace "`r`n", "`n" | Set-Content -NoNewline -Encoding ASCII $file
```

### 4. Install Commands: Use Shared Base Script

**DRY Principle:** Don't repeat 70+ lines of installation logic

```bash
# .ddev/commands/web/install-base (80 lines, shared)
install_typo3() {
    # All common installation logic
}

# .ddev/commands/web/install-v13 (16 lines)
source /mnt/ddev_config/commands/web/install-base
SETUP_CMD="vendor/bin/typo3 setup -n ..."
install_typo3 "v13" "^13" "$SETUP_CMD"

# .ddev/commands/web/install-v12 (16 lines)  
source /mnt/ddev_config/commands/web/install-base
SETUP_CMD="vendor/bin/typo3 install:setup -n --use-existing-database ..."
install_typo3 "v12" "^12" "$SETUP_CMD"
```

### 5. TYPO3 Version Differences

| Version | Setup Command | Database Creation | Extension Activation |
|---------|--------------|-------------------|---------------------|
| TYPO3 13 | `setup` | External (mysql) | `extension:setup` |
| TYPO3 12 | `install:setup --use-existing-database` | External (mysql) | Automatic |

## Installation Speed Comparison

| Method | v13 Install Time | Notes |
|--------|-----------------|-------|
| Bind mounts | ~10-15 min | ❌ Very slow on Windows |
| Volumes + sudo chown | ~3-5 min | ✅ Fast and working |
| Volumes (no chown) | N/A | ❌ Permission denied errors |

## Common Pitfalls

### ❌ Pitfall 1: Using Bind Mounts for Speed
```yaml
# Don't do this on Windows!
volumes:
  - ./typo3-installations/v12:/var/www/html/v12
```
**Impact:** 3x slower installations

### ❌ Pitfall 2: Forgetting sudo chown
```bash
# This fails on Windows with volumes
echo "{}" > /var/www/html/v13/composer.json
# Permission denied!
```

### ❌ Pitfall 3: ASCII Encoding Corrupts Emojis
```powershell
# This breaks emojis in bash scripts
Set-Content -Encoding ASCII $file
```

### ❌ Pitfall 4: TYPO3 12 Database Creation
```bash
# This hangs/fails
vendor/bin/typo3 install:setup -n --database-name v12
# Missing: --use-existing-database
```

## Recommended Workflow

1. **Use skill templates** - They have the correct volume setup
2. **Add sudo chown** - Fix volume permissions (Windows-specific)
3. **Use UTF-8 encoding** - Preserve emojis when converting line endings
4. **Share install logic** - Use install-base for DRY principle
5. **Test both versions** - TYPO3 12 and 13 have different setup commands

## Windows-Specific .gitignore

```gitignore
# Don't commit these (Windows creates them)
.ddev/typo3-installations/
Thumbs.db
desktop.ini
```

## Quick Reference Commands

```powershell
# Convert to LF with UTF-8 (correct)
$file = '.ddev/commands/web/install-v13'
$content = Get-Content $file -Raw -Encoding UTF8
$content = $content -replace "`r`n", "`n"
[System.IO.File]::WriteAllText((Resolve-Path $file).Path, $content, [System.Text.UTF8Encoding]::new($false))

# Restart DDEV after config changes
ddev restart

# Check volume ownership
ddev exec ls -la /var/www/html/v13

# Fix permissions manually if needed
ddev exec sudo chown -R $(whoami):$(whoami) /var/www/html/v13
```
