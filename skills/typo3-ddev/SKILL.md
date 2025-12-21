---
name: typo3-ddev
description: "Automate DDEV environment setup for TYPO3 extension development. Use when setting up local development environment, configuring DDEV for TYPO3 extensions, or creating multi-version TYPO3 testing environments. Covers DDEV configuration generation, TYPO3 11.5/12.4/13.4 LTS installation, custom DDEV commands, Apache vhost setup, Docker volume management, and .gitignore best practices. By Netresearch."
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
```bash
# In .ddev/web-build/Dockerfile
RUN pecl install pcov && docker-php-ext-enable pcov
```
PCOV is faster than Xdebug for code coverage collection.

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

## Security Best Practices

### MySQL Credential Handling

**Always use `MYSQL_PWD` environment variable** instead of `-p"$PASSWORD"` to avoid exposing passwords in process lists:

```bash
# Bad: Password visible in `ps aux` output
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "DROP DATABASE IF EXISTS v13"

# Good: Password hidden via environment variable
export MYSQL_PWD="${MYSQL_PASSWORD:-root}"
mysql -h "$DB_HOST" -u "$DB_USER" -e "DROP DATABASE IF EXISTS v13"
```

**Why:**
- Command-line arguments are visible to all users via `ps aux`
- `MYSQL_PWD` is read by MySQL client but not exposed in process list
- Use defaults for DDEV environment: `${MYSQL_PASSWORD:-root}`

### Safe YAML Manipulation

**Use PHP `yaml_parse()`/`yaml_emit()` instead of fragile `sed` commands** for modifying YAML config files:

```bash
# Bad: Fragile sed-based YAML editing
sed -i '/^dependencies:/d' config/sites/main/config.yaml
sed -i '/^  - /d' config/sites/main/config.yaml
echo "dependencies:" >> config/sites/main/config.yaml
echo "  - bootstrap-package/full" >> config/sites/main/config.yaml

# Good: Safe PHP-based YAML manipulation
php -r "
    \$file = 'config/sites/main/config.yaml';
    \$yaml = yaml_parse_file(\$file);
    \$yaml['dependencies'] = ['bootstrap-package/full'];
    file_put_contents(\$file, yaml_emit(\$yaml, YAML_UTF8_ENCODING));
" 2>/dev/null || {
    # Fallback: append if PHP yaml extension not available
    if ! grep -q '^dependencies:' config/sites/main/config.yaml; then
        echo "dependencies:" >> config/sites/main/config.yaml
        echo "  - bootstrap-package/full" >> config/sites/main/config.yaml
    fi
}
```

**Why:**
- `sed` can break YAML structure (indentation, multiline values)
- PHP yaml functions properly parse and emit valid YAML
- Fallback ensures compatibility when yaml extension unavailable

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
