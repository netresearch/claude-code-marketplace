---
name: typo3-ddev
description: "Agent Skill: Automate DDEV environment setup for TYPO3 extension development. Use when setting up local development environment, configuring DDEV for TYPO3 extensions, or creating multi-version TYPO3 testing environments. Covers DDEV configuration generation, TYPO3 11.5/12.4/13.4 LTS installation, custom DDEV commands, Apache vhost setup, Docker volume management, and .gitignore best practices. By Netresearch."
---

# TYPO3 DDEV Setup Skill

Automates DDEV environment setup for TYPO3 extension development projects with multi-version testing support.

## When to Use This Skill

Use when:
- Setting up DDEV for a TYPO3 extension project
- Project contains `ext_emconf.php` or is a TYPO3 extension in `composer.json`
- Testing extension across multiple TYPO3 versions (11.5, 12.4, 13.4 LTS)
- Quick development environment spin-up is needed

## Quick Start

```bash
# 1. Validate prerequisites
scripts/validate-prerequisites.sh

# 2. Generate DDEV configuration (in extension root)
# Extracts: extension key, package name, vendor namespace

# 3. Start DDEV
ddev start

# 4. Install TYPO3 versions
ddev install-all      # All versions
ddev install-v13      # Single version
```

## Core Workflow

### Step 1: Validate Prerequisites

Run `scripts/validate-prerequisites.sh` to check:
- Docker daemon running (>= 20.10)
- Docker Compose (>= 2.0)
- DDEV installation
- Valid TYPO3 extension structure

If validation fails: `references/prerequisites-validation.md`

### Step 2: Extract Extension Metadata

Automatically detect from project files:
- **Extension Key**: From `ext_emconf.php` or `composer.json` (`extra.typo3/cms.extension-key`)
- **Package Name**: From `composer.json` `name` field
- **Vendor Namespace**: From `composer.json` `autoload.psr-4`

### Step 3: Generate DDEV Configuration

Creates:
```
.ddev/
├── config.yaml
├── docker-compose.web.yaml
├── apache/apache-site.conf
├── web-build/Dockerfile
└── commands/web/
    ├── install-v11
    ├── install-v12
    ├── install-v13
    └── install-all
.envrc (direnv integration)
```

### Step 4: Start and Install

```bash
ddev start
ddev install-all    # Installs TYPO3 + extension + Introduction Package
```

### Step 5: Access Environment

| Environment | URL Pattern |
|-------------|-------------|
| Overview | `https://{sitename}.ddev.site/` |
| TYPO3 v11 | `https://v11.{sitename}.ddev.site/typo3/` |
| TYPO3 v12 | `https://v12.{sitename}.ddev.site/typo3/` |
| TYPO3 v13 | `https://v13.{sitename}.ddev.site/typo3/` |
| Docs | `https://docs.{sitename}.ddev.site/` |

**Credentials**: admin / Joh316!

## Generated Files Reference

### config.yaml Variables
- `{{DDEV_SITENAME}}`: DDEV project name (from extension key)

### docker-compose.web.yaml Variables
- `{{EXTENSION_KEY}}`: Extension key with underscores
- `{{PACKAGE_NAME}}`: Composer package name
- `{{DDEV_SITENAME}}`: For volume naming

### Volume Architecture
- Extension source: Bind-mounted from project root
- TYPO3 installations: Docker volumes (`v11-data`, `v12-data`, `v13-data`)

### .envrc Variables
- `{{EXTENSION_KEY}}`: Extension key for display
- `{{DDEV_SITENAME}}`: DDEV project name (URLs)
- `{{GENERATED_DATE}}`: Auto-populated generation date

## Optional Enhancements

### Generate Makefile
```bash
ddev generate-makefile
```
Provides `make up`, `make test`, `make lint`, `make ci` commands.

### Generate Index Page
```bash
ddev generate-index
```
Creates overview dashboard at main domain.

### Render Documentation
```bash
ddev docs
```
Renders `Documentation/*.rst` to `Documentation-GENERATED-temp/`.

**Important**: Always use `Documentation-GENERATED-temp/` (TYPO3 convention), never `docs/`.

See `references/documentation-rendering.md` for detailed setup.

### Install PCOV for Code Coverage

PCOV is faster than Xdebug for code coverage collection.

```bash
# In .ddev/web-build/Dockerfile
RUN apt-get update && apt-get install -y php${PHP_VERSION}-pcov
```

**Note**: DDEV containers don't include `pecl`. Use `apt-get` for PHP extensions instead.

### Upgrade PHP Packages

To get the latest PHP patch version (e.g., PHP 8.5.1 when DDEV ships 8.5.0):

```bash
# Create .ddev/web-build/Dockerfile.apt
RUN apt-get update
RUN apt-get install --only-upgrade -y php${PHP_VERSION}-*
```

This is useful when a new PHP patch release fixes bugs but DDEV hasn't updated yet.

### Custom PHP Configuration

Place custom PHP settings in `.ddev/php/custom.ini`:

```ini
# .ddev/php/custom.ini
memory_limit = 512M
max_execution_time = 300
```

**Note**: Do NOT place `.ini` files in `/usr/local/etc/php/conf.d/` directly - DDEV manages that path internally.

## What Gets Installed

Each TYPO3 version includes:
- TYPO3 Core (specified version)
- Your extension (activated)
- TYPO3 Backend Styleguide (with generated demo content)
- Introduction Package (86+ pages demo content)

### Security Configuration (Development Mode)

The install scripts automatically configure:
```php
$GLOBALS["TYPO3_CONF_VARS"]["SYS"]["trustedHostsPattern"] = ".*";
$GLOBALS["TYPO3_CONF_VARS"]["SYS"]["features"]["security.backend.enforceReferrer"] = false;
```

This prevents "Invalid Referrer" and "Trusted Host" errors in the multi-subdomain DDEV environment.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Database exists error | `ddev mysql -e "DROP DATABASE v13; CREATE DATABASE v13;"` |
| Extension not appearing | `ddev exec -d /var/www/html/v13 vendor/bin/typo3 cache:flush` |
| Services not loading | `ddev restart` or check `docker logs` |
| Invalid Referrer error | Already fixed - reinstall with `ddev install-v13` |
| Windows issues | See `references/windows-fixes.md` |

## .gitignore Best Practices

**Critical**: Avoid the double-ignore anti-pattern where `.ddev/.gitignore` ignores itself.

**Commit** (share with team):
- `.ddev/config.yaml`, `.ddev/docker-compose.*.yaml`
- `.ddev/apache/`, `.ddev/commands/`, `.ddev/web-build/`

**Ignore** (personal/generated):
- `.ddev/.homeadditions`, `.ddev/.ddev-docker-compose-full.yaml`
- `.ddev/db_snapshots/`

## TYPO3 v13 Site Sets

For TYPO3 v13+, site sets are **automatically configured** during installation:

```yaml
# config/sites/main/config.yaml (auto-generated)
dependencies:
  - bootstrap-package/full
```

The install script adds Bootstrap Package as a site set dependency, enabling proper frontend rendering out of the box.

To add your extension as a site set dependency:
```yaml
dependencies:
  - bootstrap-package/full
  - vendor/extension-name
```

See `references/advanced-options.md` for site set configuration details.

## References

| Topic | File |
|-------|------|
| Prerequisite validation | `references/prerequisites-validation.md` |
| Quick start guide | `references/quickstart.md` |
| Advanced options (PHP, DB, services) | `references/advanced-options.md` |
| Index page generation | `references/index-page-generation.md` |
| Documentation rendering | `references/documentation-rendering.md` |
| Troubleshooting | `references/troubleshooting.md` |
| Windows-specific fixes | `references/windows-fixes.md` |
| Windows optimizations | `references/windows-optimizations.md` |
| Database alternatives | `references/0002-mariadb-default-with-database-alternatives.md` |
| Cache alternatives | `references/0001-valkey-default-with-redis-alternative.md` |
| TYPO3 12 CLI changes | `references/typo3-12-cli-changes.md` |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/validate-prerequisites.sh` | Check Docker, DDEV, project structure |
