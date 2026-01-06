# Development Environment Standards

**Purpose:** Validate development environment setup for consistent, reproducible TYPO3 extension development

## Why Development Environment Matters

A properly configured development environment ensures:

- ✅ **Consistency** - All developers work with identical PHP/TYPO3/database versions
- ✅ **Onboarding** - New contributors can start immediately without complex setup
- ✅ **CI/CD Parity** - Local environment matches production/staging
- ✅ **Reproducibility** - Bugs are reproducible across all environments
- ✅ **Cross-Platform** - Works on macOS, Linux, Windows (WSL)

Without standardized dev environment:
- ❌ "Works on my machine" syndrome
- ❌ Inconsistent PHP/database versions causing bugs
- ❌ Complex setup discourages contributions
- ❌ CI failures that don't reproduce locally

## TYPO3 Community Standards

### DDEV - Primary Recommendation

**DDEV** is the **de facto standard** for TYPO3 development:

- ✅ Official TYPO3 core development uses DDEV
- ✅ TYPO3 Best Practices (Tea extension) uses DDEV
- ✅ TYPO3 documentation recommends DDEV
- ✅ Cross-platform support (Docker-based)
- ✅ Preconfigured for TYPO3 (`ddev config --project-type=typo3`)

**Alternative:** Docker Compose (acceptable, more manual configuration)

## Validation Checklist

### 1. DDEV Configuration

**Check for `.ddev/` directory:**

```bash
ls -la .ddev/
```

**Required files:**
- `.ddev/config.yaml` - Core DDEV configuration
- `.ddev/.gitignore` - Excludes dynamic files (import-db, .ddev-docker-compose-*.yaml)

**Optional but recommended:**
- `.ddev/config.typo3.yaml` - TYPO3-specific settings
- `.ddev/commands/` - Custom DDEV commands
- `.ddev/docker-compose.*.yaml` - Additional services

**Severity if missing:** 🟡 **Medium** - Indicates no standardized dev environment

### 2. DDEV config.yaml Structure

**Minimum DDEV Configuration:**

```yaml
name: extension-name
type: typo3
docroot: .Build/public
php_version: "8.2"  # Match composer.json minimum
webserver_type: nginx-fpm
router_http_port: "80"
router_https_port: "443"
xdebug_enabled: false
additional_hostnames: []
additional_fqdns: []
database:
  type: mariadb
  version: "10.11"
omit_containers: [ddev-ssh-agent]
```

**Validation Rules:**

| Field | Validation | Example | Severity |
|-------|-----------|---------|----------|
| `name` | Should match extension key or composer name | `rte-ckeditor-image` | Low |
| `type` | Must be `typo3` | `typo3` | High |
| `docroot` | Should match composer.json web-dir | `.Build/public` | High |
| `php_version` | Should match composer.json minimum PHP | `"8.2"` | High |
| `database.type` | Should be `mariadb` (TYPO3 standard) | `mariadb` | Medium |
| `database.version` | Should be LTS version (10.11 or 11.x) | `"10.11"` | Medium |

**Example Check:**

```bash
# Extension composer.json
"require": {
    "php": "^8.2 || ^8.3 || ^8.4",
    "typo3/cms-core": "^13.4"
}
"extra": {
    "typo3/cms": {
        "web-dir": ".Build/public"
    }
}

# DDEV config.yaml SHOULD have:
php_version: "8.2"          # ✅ Matches minimum
docroot: .Build/public      # ✅ Matches web-dir
type: typo3                 # ✅ Correct type

# DDEV config.yaml SHOULD NOT have:
php_version: "7.4"          # ❌ Below minimum
docroot: public             # ❌ Doesn't match web-dir
type: php                   # ❌ Wrong type
```

### 3. Docker Compose (Alternative)

If DDEV not present, check for `docker-compose.yml`:

**Minimum Docker Compose Configuration:**

```yaml
version: '3.8'

services:
  web:
    image: ghcr.io/typo3/core-testing-php82:latest
    volumes:
      - .:/var/www/html
    working_dir: /var/www/html
    ports:
      - "8000:80"
    environment:
      TYPO3_CONTEXT: Development

  db:
    image: mariadb:10.11
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: typo3
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

**Validation Rules:**

| Service | Validation | Severity |
|---------|-----------|----------|
| `web` service exists | Required | High |
| PHP version matches composer.json | Required | High |
| `db` service exists | Required | Medium |
| Database type is MariaDB/MySQL | Recommended | Low |
| Volumes preserve database data | Required | High |

**Severity if missing:** 🟡 **Medium** - Harder to onboard, but not critical

### 4. DevContainer (VS Code Remote Containers)

Check for `.devcontainer/devcontainer.json`:

**Example DevContainer Configuration:**

```json
{
  "name": "TYPO3 Extension Development",
  "dockerComposeFile": ["../docker-compose.yml"],
  "service": "web",
  "workspaceFolder": "/var/www/html",
  "customizations": {
    "vscode": {
      "extensions": [
        "bmewburn.vscode-intelephense-client",
        "xdebug.php-debug",
        "EditorConfig.EditorConfig"
      ],
      "settings": {
        "php.validate.executablePath": "/usr/local/bin/php"
      }
    }
  },
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/devcontainers/features/node:1": {}
  }
}
```

**Validation:**
- File exists: ✅ Good (VS Code support)
- References docker-compose.yml or DDEV: ✅ Integrated approach
- Empty directory: ⚠️ Incomplete setup

**Severity if missing:** 🟢 **Low** - Nice to have, not required

## DDEV-Specific Best Practices

### TYPO3-Optimized Settings

**`.ddev/config.typo3.yaml`:**

```yaml
# TYPO3-specific DDEV configuration
override_config: false
web_extra_daemons:
  - name: "typo3-backend-lock-handler"
    command: "/var/www/html/.Build/bin/typo3 scheduler:run"
    directory: /var/www/html

hooks:
  post-start:
    - exec: composer install
    - exec: .Build/bin/typo3 cache:flush

# Additional PHP settings for TYPO3
php_ini:
  memory_limit: 512M
  max_execution_time: 240
  upload_max_filesize: 32M
  post_max_size: 32M
```

### Custom DDEV Commands

**`.ddev/commands/web/typo3`:**

```bash
#!/bin/bash
## Description: Run TYPO3 CLI commands
## Usage: typo3 [args]
## Example: "ddev typo3 cache:flush"

.Build/bin/typo3 "$@"
```

**`.ddev/commands/web/test-unit`:**

```bash
#!/bin/bash
## Description: Run unit tests
## Usage: test-unit [args]

.Build/bin/phpunit -c Build/phpunit/UnitTests.xml "$@"
```

**`.ddev/commands/web/test-functional`:**

```bash
#!/bin/bash
## Description: Run functional tests
## Usage: test-functional [args]

.Build/bin/phpunit -c Build/phpunit/FunctionalTests.xml "$@"
```

## Conformance Evaluation Workflow

### Step 1: Detect Development Environment Type

```bash
# Check for DDEV
if [ -f ".ddev/config.yaml" ]; then
    DEV_ENV="ddev"
    SCORE=20  # Full points for DDEV

# Check for Docker Compose
elif [ -f "docker-compose.yml" ]; then
    DEV_ENV="docker-compose"
    SCORE=15  # Good, but manual

# Check for DevContainer only
elif [ -f ".devcontainer/devcontainer.json" ]; then
    DEV_ENV="devcontainer"
    SCORE=10  # VS Code specific

# No dev environment
else
    DEV_ENV="none"
    SCORE=0
fi
```

### Step 2: Validate Configuration Against Extension

**For DDEV:**

```bash
# Extract extension requirements
MIN_PHP=$(jq -r '.require.php' composer.json | grep -oE '[0-9]+\.[0-9]+' | head -1)
WEB_DIR=$(jq -r '.extra.typo3.cms."web-dir"' composer.json)

# Validate DDEV config
DDEV_PHP=$(grep 'php_version:' .ddev/config.yaml | awk '{print $2}' | tr -d '"')
DDEV_DOCROOT=$(grep 'docroot:' .ddev/config.yaml | awk '{print $2}')
DDEV_TYPE=$(grep 'type:' .ddev/config.yaml | awk '{print $2}')

# Compare
if [ "${DDEV_PHP}" != "${MIN_PHP}" ]; then
    echo "⚠️  PHP version mismatch: DDEV ${DDEV_PHP} vs required ${MIN_PHP}"
fi

if [ "${DDEV_DOCROOT}" != "${WEB_DIR}" ]; then
    echo "⚠️  Docroot mismatch: DDEV ${DDEV_DOCROOT} vs composer ${WEB_DIR}"
fi

if [ "${DDEV_TYPE}" != "typo3" ]; then
    echo "❌ DDEV type should be 'typo3', found '${DDEV_TYPE}'"
fi
```

### Step 3: Check for Recommended Enhancements

```bash
# DDEV commands
if [ -d ".ddev/commands/web" ]; then
    COMMANDS=$(ls .ddev/commands/web/ 2>/dev/null | wc -l)
    echo "✅ DDEV has ${COMMANDS} custom commands"
else
    echo "ℹ️  No custom DDEV commands (consider adding typo3, test-unit, test-functional)"
fi

# TYPO3-specific config
if [ -f ".ddev/config.typo3.yaml" ]; then
    echo "✅ TYPO3-specific DDEV configuration present"
else
    echo "ℹ️  No TYPO3-specific config (optional)"
fi
```

## Conformance Report Integration

### When Evaluating Development Environment:

**In "Best Practices" Section:**

```markdown
### Development Environment

**Configuration:**

- ✅ DDEV configured (.ddev/config.yaml present)
- ✅ PHP version matches composer.json minimum (8.2)
- ✅ Docroot matches composer.json web-dir (.Build/public)
- ✅ Type set to 'typo3' for TYPO3-optimized setup
- ✅ MariaDB 10.11 (LTS) configured
- ✅ Custom DDEV commands for testing (test-unit, test-functional)
- ℹ️  Optional: TYPO3-specific config (.ddev/config.typo3.yaml) could enhance setup

**Or with issues:**

- ❌ No development environment configuration
  - Missing: .ddev/config.yaml, docker-compose.yml
  - Impact: Inconsistent development environments, difficult onboarding
  - Severity: Medium
  - Recommendation: Add DDEV configuration from Tea extension pattern
  - Reference: https://github.com/TYPO3BestPractices/tea/tree/main/.ddev

- ⚠️  DDEV PHP version mismatch
  - File: .ddev/config.yaml
  - Current: php_version: "7.4"
  - Expected: php_version: "8.2" (from composer.json)
  - Severity: High
  - Fix: Update php_version to match minimum requirement

- ⚠️  DDEV docroot mismatch
  - File: .ddev/config.yaml
  - Current: docroot: public
  - Expected: docroot: .Build/public (from composer.json extra.typo3.cms.web-dir)
  - Severity: High
  - Fix: Update docroot to match web-dir
```

## Scoring Impact

**Best Practices Score Components (out of 20):**

| Component | Max Points | DDEV | Docker Compose | None |
|-----------|-----------|------|----------------|------|
| **Dev Environment Exists** | 6 | 6 | 4 | 0 |
| **Configuration Correct** | 4 | 4 | 3 | 0 |
| **Version Matching** | 3 | 3 | 2 | 0 |
| **Documentation** | 2 | 2 | 1 | 0 |
| **Custom Commands/Enhancements** | 2 | 2 | 0 | 0 |
| **Other Best Practices** | 3 | 3 | 3 | 3 |
| **Total** | 20 | 20 | 13 | 3 |

**Deductions:**

| Issue | Severity | Score Impact |
|-------|----------|--------------|
| No dev environment at all | High | -6 points |
| PHP version mismatch | High | -3 points |
| Docroot mismatch | High | -3 points |
| Wrong type (not 'typo3') | Medium | -2 points |
| Missing custom commands | Low | -1 point |
| No documentation | Low | -1 point |

## Tea Extension Reference

**Source:** https://github.com/TYPO3BestPractices/tea/tree/main/.ddev

**Tea DDEV Structure:**

```
.ddev/
├── .gitignore
├── config.yaml              # Main configuration
├── config.typo3.yaml        # TYPO3-specific settings
└── commands/
    └── web/
        ├── typo3            # TYPO3 CLI wrapper
        ├── test-unit        # Run unit tests
        └── test-functional  # Run functional tests
```

**Tea config.yaml (simplified):**

```yaml
name: tea
type: typo3
docroot: .Build/public
php_version: "8.2"
webserver_type: nginx-fpm
database:
  type: mariadb
  version: "10.11"
xdebug_enabled: false
```

**Usage Examples:**

```bash
# Start DDEV
ddev start

# Install dependencies
ddev composer install

# Run TYPO3 CLI
ddev typo3 cache:flush

# Run unit tests
ddev test-unit

# Run functional tests
ddev test-functional

# Access database
ddev mysql

# SSH into container
ddev ssh
```

## Quick Reference Checklist

**When evaluating development environment:**

```
□ .ddev/config.yaml exists (preferred)
□ OR docker-compose.yml exists (acceptable)
□ OR .devcontainer/devcontainer.json exists (VS Code only)
□ Configuration type is 'typo3' (DDEV) or uses TYPO3 image (Docker Compose)
□ PHP version matches composer.json minimum
□ Docroot matches composer.json web-dir
□ Database is MariaDB 10.11+ or MySQL 8.0+
□ Custom commands for common tasks (DDEV)
□ Documentation exists (README.md mentions DDEV/Docker setup)
□ .ddev/.gitignore present (excludes dynamic files)
□ Post-start hooks run composer install (optional but nice)
```

## Common Issues

### Issue: Empty .devcontainer/

**Diagnosis:**
```bash
ls -la .devcontainer/
# total 8
# drwxr-sr-x  2 user user 4096 Oct 20 20:05 .
```

**Severity:** 🟢 Low (incomplete setup, doesn't help or hurt)

**Fix:** Either populate with devcontainer.json or remove directory

### Issue: DDEV but no .gitignore

**Diagnosis:**
```bash
ls -la .ddev/.gitignore
# No such file or directory
```

**Problem:** DDEV generates dynamic files that shouldn't be committed

**Fix:** Create `.ddev/.gitignore`:
```
/*.yaml
.ddev-docker-compose-*.yaml
.homeadditions
.sshimagename
commands/web/.ddev-docker-compose-*.yaml
import-db/
```

### Issue: Wrong DDEV project type

**Diagnosis:**
```yaml
# .ddev/config.yaml
type: php  # ❌ Wrong
```

**Problem:** Misses TYPO3-specific optimizations (URL structure, etc.)

**Fix:** Change to `type: typo3`

## Resources

- **DDEV Documentation:** https://ddev.readthedocs.io/
- **DDEV TYPO3 Quickstart:** https://ddev.readthedocs.io/en/stable/users/quickstart/#typo3
- **Tea Extension DDEV Setup:** https://github.com/TYPO3BestPractices/tea/tree/main/.ddev
- **TYPO3 Docker Documentation:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/LocalDevelopment/
