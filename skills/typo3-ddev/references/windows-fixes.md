# Windows-Specific DDEV Issues and Fixes

## Critical Issue: Health Check Failures

**Symptom:** `ddev start` hangs at "Waiting for containers to become ready" indefinitely

**Root Cause:** Custom Apache configurations override DDEV's default `/phpstatus` endpoint, causing health checks to fail

**Fix:** Always include PHP-FPM status endpoint in custom Apache configs

```apache
# CRITICAL: PHP-FPM status endpoint (required for DDEV health checks)
# Place this BEFORE any VirtualHost declarations
<Location /phpstatus>
    SetHandler "proxy:unix:/run/php-fpm.sock|fcgi://localhost"
</Location>
```

**Correct Socket Path:** `/run/php-fpm.sock` (NOT `/run/php-fpm-socket/php-fpm.sock`)

**Verification:**
```bash
# After DDEV starts, verify health check passes:
ddev exec /healthcheck.sh
# Should output: /var/www/html:OK mailpit:OK phpstatus:OK
```

## Line Ending Issues

**Symptom:** `Command 'install-v12' contains CRLF, please convert to Linux-style linefeeds`

**Root Cause:** Files created on Windows have CRLF line endings; DDEV requires LF

**Fix:** Convert line endings after file creation **while preserving UTF-8 encoding for emojis**

```powershell
# PowerShell command to convert CRLF to LF (preserving UTF-8 for emojis)
# IMPORTANT: Must use -Raw flag, UTF-8 encoding, and proper replacement
foreach ($file in @('.ddev\commands\web\install-v12', '.ddev\commands\web\install-v13', '.ddev\commands\host\docs')) {
    $content = Get-Content $file -Raw -Encoding UTF8
    $content = $content -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText((Resolve-Path $file).Path, $content, [System.Text.UTF8Encoding]::new($false))
}
```

**Common Mistakes:**
- ❌ Using `(Get-Content $file)` without `-Raw` flag loses all line breaks
- ❌ Using `-Encoding ASCII` corrupts emojis (🚀 → ??)
- ✅ Must use UTF-8 encoding to preserve emoji characters

**Prevention:** Configure Git to handle line endings:
```bash
git config --global core.autocrlf input
```

## Router Not Starting Automatically

**Symptom:** Sites return 404, `docker ps | grep router` shows no router

**Root Cause:** On Windows, DDEV may fail to start the traefik router automatically

**Diagnostic:**
```bash
ddev describe
# If "SERVICE" table is empty, router didn't start
```

**Fix 1:** Restart DDEV after fixing health checks
```bash
ddev restart
# Router should start automatically if health checks pass
```

**Fix 2:** Check router status manually
```bash
docker ps -a | grep router
# If stopped, check logs:
docker logs ddev-router
```

## Mutagen Sync Issues

**Symptom:** `Mutagen Docker volume is not mounted. Please use 'ddev restart'`

**Root Cause:** Mutagen file sync can be problematic on Windows

**Fix:** Disable Mutagen and use direct bind mounts

```bash
ddev config --performance-mode=none
ddev restart
```

**Note:** Direct mounts may be slower but more reliable on Windows

## Docker Volume Permission Issues

**Symptom:** `Permission denied` when writing to `/var/www/html/vXX/composer.json`

**Root Cause:** Docker volumes on Windows are owned by root; web user can't write

**Solution:** Use `sudo chown` at the start of install scripts

```bash
#!/bin/bash
VERSION=v13
INSTALL_DIR=/var/www/html/$VERSION

# Fix permissions before writing (critical for Windows)
sudo rm -rf $INSTALL_DIR/*
sudo mkdir -p $INSTALL_DIR
sudo chown -R $(whoami):$(whoami) $INSTALL_DIR

# Now can write files
cd $INSTALL_DIR
echo "{}" > composer.json  # Works!
```

**Why This Works:**
- Volumes are faster than bind mounts on Windows
- `sudo chown` fixes ownership without performance penalty
- Only needed once at the start of installation

**Bind Mounts Alternative (slower but simpler):**
```yaml
# In .ddev/docker-compose.web.yaml
volumes:
  - type: bind
    source: ./typo3-installations/v12
    target: /var/www/html/v12
```
⚠️ Bind mounts are significantly slower on Windows

## Complete Apache Config Template (Windows-Safe)

```apache
# CRITICAL: PHP-FPM status endpoint (MUST be first)
<Location /phpstatus>
    SetHandler "proxy:unix:/run/php-fpm.sock|fcgi://localhost"
</Location>

# Main project overview
<VirtualHost *:80>
    ServerName {{DDEV_SITENAME}}.ddev.site
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

# Additional VirtualHosts for multi-version setup
<VirtualHost *:80>
    ServerName v12.{{DDEV_SITENAME}}.ddev.site
    DocumentRoot /var/www/html/v12/public
    <Directory /var/www/html/v12/public>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

# Add more VirtualHosts as needed...
```

## Debugging Steps

### 1. Check Container Health
```bash
docker inspect ddev-{{SITENAME}}-web --format='{{.State.Health.Status}}'
# Should be: healthy
```

### 2. Check Health Check Output
```bash
ddev exec /healthcheck.sh
# Should output: /var/www/html:OK mailpit:OK phpstatus:OK
```

### 3. Check PHP-FPM Socket
```bash
ddev exec ls -la /run/php-fpm.sock
# Should exist and be a socket
```

### 4. Test phpstatus Endpoint
```bash
ddev exec curl -f http://localhost/phpstatus
# Should return PHP-FPM status page
```

### 5. Check Router
```bash
docker ps | grep router
# Should show ddev-router container running and healthy
```

### 6. Check Traefik Logs
```bash
docker logs ddev-router --tail 50
# Look for routing errors
```

## Documentation Rendering (Host Commands)

**Symptom:** `ddev docs` command executes but produces no output, or Docker mount fails

**Root Cause:** Windows paths require special handling in DDEV host commands (Git Bash/WSL)

**Fix:** Use double-slash prefix for Docker volume mounts

```bash
#!/bin/bash
# For Windows compatibility - ensure path format works for Docker
if [[ "$OSTYPE" == "msys" ]]; then
    # Git Bash on Windows - use double slash prefix
    DOCKER_MOUNT="//$(pwd)"
else
    DOCKER_MOUNT="$(pwd)"
fi

docker run --rm \
    -v "$DOCKER_MOUNT:/project" \
    ghcr.io/typo3-documentation/render-guides:latest \
    --config=Documentation
```

**Path Transformation:**
- PowerShell: `C:\Users\live\project`
- Git Bash: `/c/Users/live/project`
- Docker (Windows): `//c/Users/live/project` (double slash prefix required)

## TYPO3 12 Database Setup Issue

**Symptom:** `install:setup` tries to create database repeatedly and fails

```
ERROR: Unable to create database
Database with name "v12" could not be created...
➤ Select database
```

**Root Cause:** TYPO3 12's `install:setup` tries to create the database itself

**Solution:** Use `--use-existing-database` flag

```bash
# Create database first
mysql -h db -u root -proot -e "CREATE DATABASE v12;"

# Then use existing database
vendor/bin/typo3 install:setup -n --database-name v12 --use-existing-database
```

**TYPO3 13 Comparison:**
TYPO3 13's `setup` command works differently and doesn't have this issue.

## Prevention Checklist

Before running `ddev start` on Windows:

- [ ] Apache config includes `/phpstatus` endpoint with correct socket path
- [ ] All script files in `.ddev/commands/` use LF line endings (with `-Raw` flag)
- [ ] Host commands use `//$(pwd)` for Docker mounts on Windows
- [ ] Git configured with `core.autocrlf=input`
- [ ] Mutagen disabled if experiencing sync issues
- [ ] Increased timeout: `ddev config --default-container-timeout=600`

## Quick Recovery

If DDEV is stuck or broken:

```bash
# 1. Stop everything
ddev poweroff

# 2. Remove any manual router
docker rm -f ddev-router

# 3. Fix Apache config (add phpstatus endpoint)
# 4. Fix line endings in command scripts
# 5. Disable Mutagen if needed
ddev config --performance-mode=none

# 6. Start with increased timeout
ddev config --default-container-timeout=600
ddev start
```

## Success Criteria

DDEV is properly working when:

1. ✅ `ddev start` completes without hanging
2. ✅ `ddev describe` shows all services with URLs
3. ✅ `ddev exec /healthcheck.sh` returns all OK
4. ✅ Browser can access `https://{{SITENAME}}.ddev.site`
5. ✅ `docker ps | grep router` shows healthy router
