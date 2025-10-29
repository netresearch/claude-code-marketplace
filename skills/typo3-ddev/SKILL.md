---
name: typo3-ddev
version: 1.0.0
description: "Automate DDEV environment setup for TYPO3 extension development. Use when setting up local development environment, configuring DDEV for TYPO3 extensions, or creating multi-version TYPO3 testing environments. Covers: DDEV configuration generation, TYPO3 11.5/12.4/13.4 LTS installation, custom DDEV commands, Apache vhost setup, and Docker volume management. Provides complete automation from metadata detection to ready-to-use TYPO3 backend access."
license: MIT License - see LICENSE file
---

# TYPO3 DDEV Setup Skill

You are an expert TYPO3 extension development assistant specialized in setting up DDEV environments for TYPO3 extension projects. Your goal is to help developers quickly spin up a complete TYPO3 development environment to test and develop their extensions.

## Purpose

This skill automates the setup of DDEV for TYPO3 extension development projects. It creates a multi-version TYPO3 testing environment where the extension can be developed and tested across TYPO3 11.5 LTS, 12.4 LTS, and 13.4 LTS simultaneously.

## When to Use This Skill

Use this skill when:
- Developer has a TYPO3 extension project and wants to set up DDEV
- Project contains `ext_emconf.php` or is identified as a TYPO3 extension in `composer.json`
- Developer needs to test extension across multiple TYPO3 versions
- Quick development environment spin-up is needed

## Prerequisites Validation

Before proceeding, verify:

1. **DDEV Installation**: Check if DDEV is installed
   ```bash
   ddev version
   ```

2. **Docker Running**: Verify Docker is running
   ```bash
   docker ps
   ```

3. **TYPO3 Extension Project**: Confirm current directory is a TYPO3 extension:
   - Check for `ext_emconf.php` file
   - OR check `composer.json` has `type: "typo3-cms-extension"`
   - Check for typical TYPO3 extension structure (Classes/, Configuration/, Resources/)

4. **No Existing DDEV Setup**: Check if `.ddev/` directory already exists
   - If exists, ask user if they want to overwrite

If any prerequisite fails, provide clear instructions on how to resolve it.

## Step-by-Step Workflow

### Step 1: Extract Extension Metadata

Scan the project to extract:

1. **Extension Key** (e.g., `my_ext`):
   - From `ext_emconf.php`: Look for the array key or filename pattern
   - From `composer.json`: Look for `extra.typo3/cms.extension-key`
   - Fallback: Ask user to provide

2. **Composer Package Name** (e.g., `vendor/my-ext`):
   - From `composer.json`: Look for `name` field
   - Fallback: Construct from extension key or ask user

3. **Vendor Namespace** (e.g., `Vendor\MyExt`):
   - From `composer.json`: Look for `autoload.psr-4` keys
   - Fallback: Ask user to provide

4. **Extension Name** (PascalCase, e.g., `MyExt`):
   - Convert extension key to PascalCase
   - Or extract from namespace

### Step 2: Confirm Configuration

Present extracted values to user and confirm:

```
Detected TYPO3 Extension Configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Extension Key:     my_ext
Package Name:      vendor/my-ext
DDEV Sitename:     my-ext
Vendor Namespace:  Vendor\MyExt
TYPO3 Versions:    11.5, 12.4, 13.4
PHP Version:       8.2

Is this correct? (y/n)
```

Allow user to adjust any values if needed.

### Step 3: Generate DDEV Configuration

Create the following directory structure and files:

```
.ddev/
├── config.yaml
├── docker-compose.web.yaml
├── apache/
│   └── apache-site.conf
├── web-build/
│   └── Dockerfile
└── commands/
    └── web/
        ├── install-v11
        ├── install-v12
        ├── install-v13
        └── install-all
.envrc
```

#### 3.1: .ddev/config.yaml

Replace these variables:
- `{{DDEV_SITENAME}}` → DDEV sitename (e.g., `my-ext`)

```yaml
name: {{DDEV_SITENAME}}
type: php
docroot: ""
no_project_mount: true
php_version: "8.2"
composer_version: "2"
webserver_type: apache-fpm
router_http_port: "80"
router_https_port: "443"
xdebug_enabled: false
additional_hostnames:
    - docs.{{DDEV_SITENAME}}
    - v11.{{DDEV_SITENAME}}
    - v12.{{DDEV_SITENAME}}
    - v13.{{DDEV_SITENAME}}
additional_fqdns: []
use_dns_when_possible: true
```

#### 3.2: .ddev/docker-compose.web.yaml

Replace these variables:
- `{{EXTENSION_KEY}}` → Extension key with underscores (e.g., `my_ext`)
- `{{PACKAGE_NAME}}` → Composer package name (e.g., `vendor/my-ext`)
- `{{DDEV_SITENAME}}` → DDEV sitename for volumes

```yaml
services:
    web:
        environment:
            - EXTENSION_KEY={{EXTENSION_KEY}}
            - PACKAGE_NAME={{PACKAGE_NAME}}

            # TYPO3 v11 and v12 config
            - TYPO3_INSTALL_DB_DRIVER=mysqli
            - TYPO3_INSTALL_DB_USER=root
            - TYPO3_INSTALL_DB_PASSWORD=root
            - TYPO3_INSTALL_DB_HOST=db
            - TYPO3_INSTALL_DB_UNIX_SOCKET=
            - TYPO3_INSTALL_DB_USE_EXISTING=0
            - TYPO3_INSTALL_ADMIN_USER=admin
            - TYPO3_INSTALL_ADMIN_PASSWORD=Password:joh316
            - TYPO3_INSTALL_SITE_NAME=EXT:{{EXTENSION_KEY}} Dev Environment
            - TYPO3_INSTALL_SITE_SETUP_TYPE=site
            - TYPO3_INSTALL_WEB_SERVER_CONFIG=apache

            # TYPO3 v13 config
            - TYPO3_DB_DRIVER=mysqli
            - TYPO3_DB_USERNAME=root
            - TYPO3_DB_PASSWORD=root
            - TYPO3_DB_HOST=db
            - TYPO3_SETUP_ADMIN_EMAIL=admin@example.com
            - TYPO3_SETUP_ADMIN_USERNAME=admin
            - TYPO3_SETUP_ADMIN_PASSWORD=Password:joh316
            - TYPO3_PROJECT_NAME=EXT:{{EXTENSION_KEY}} Dev Environment
            - TYPO3_SERVER_TYPE=apache
        volumes:
            - type: bind
              source: ../
              target: /var/www/{{EXTENSION_KEY}}
              consistency: cached
            - v11-data:/var/www/html/v11
            - v12-data:/var/www/html/v12
            - v13-data:/var/www/html/v13
volumes:
    v11-data:
        name: "${DDEV_SITENAME}-v11-data"
    v12-data:
        name: "${DDEV_SITENAME}-v12-data"
    v13-data:
        name: "${DDEV_SITENAME}-v13-data"
```

#### 3.3-3.7: Additional Configuration Files

Generate the following files using the templates from this skill repository:
- `.ddev/apache/apache-site.conf` (replace `{{EXTENSION_KEY}}` and `{{DDEV_SITENAME}}`)
- `.ddev/web-build/Dockerfile` (replace `{{EXTENSION_KEY}}` and `{{DDEV_SITENAME}}`)
- `.ddev/commands/web/install-v11` (make executable)
- `.ddev/commands/web/install-v12` (make executable)
- `.ddev/commands/web/install-v13` (make executable)
- `.ddev/commands/web/install-all` (make executable)
- `.ddev/commands/host/docs` (make executable) - for rendering documentation

#### 3.8: .envrc (direnv Configuration)

Generate `.envrc` in the project root for direnv integration:

Replace these variables:
- `{{EXTENSION_KEY}}` → Extension key with underscores (e.g., `my_ext`)
- `{{DDEV_SITENAME}}` → DDEV sitename (e.g., `my-ext`)

```bash
# direnv configuration for {{EXTENSION_KEY}}
# Auto-generated by typo3-ddev-skill

# Add composer bin directory to PATH
PATH_add vendor/bin

# Composer configuration
export COMPOSER_PROCESS_TIMEOUT=600

# DDEV environment variables
export DDEV_PROJECT={{DDEV_SITENAME}}
export DDEV_PRIMARY_URL=https://{{DDEV_SITENAME}}.ddev.site
export DDEV_DOCROOT_URL=https://docs.{{DDEV_SITENAME}}.ddev.site

# Load local environment overrides if present
dotenv_if_exists .env.local

# Display activation message
echo "✅ {{EXTENSION_KEY}} development environment activated"
echo ""
echo "🌐 DDEV Environment:"
echo "   Primary:   https://{{DDEV_SITENAME}}.ddev.site"
echo "   Docs:      https://docs.{{DDEV_SITENAME}}.ddev.site"
echo "   TYPO3 v11: https://v11.{{DDEV_SITENAME}}.ddev.site"
echo "   TYPO3 v12: https://v12.{{DDEV_SITENAME}}.ddev.site"
echo "   TYPO3 v13: https://v13.{{DDEV_SITENAME}}.ddev.site"
echo ""
echo "🚀 DDEV Commands:"
echo "   ddev start           Start DDEV environment"
echo "   ddev stop            Stop DDEV environment"
echo "   ddev restart         Restart DDEV environment"
echo "   ddev install-v11     Install TYPO3 11.5 LTS"
echo "   ddev install-v12     Install TYPO3 12.4 LTS"
echo "   ddev install-v13     Install TYPO3 13.4 LTS"
echo "   ddev install-all     Install all TYPO3 versions"
```

**What it does:**
- Adds `vendor/bin` to PATH for Composer tools
- Exports DDEV environment variables for easy access
- Displays helpful information when entering the project directory
- Lists available DDEV URLs and commands

**User action required:** Run `direnv allow` to activate the configuration.

**Optional:** If direnv is not installed, the file can be safely ignored.

### Step 4: Initialize DDEV

After generating all files, guide the user through starting DDEV:

```bash
# Start DDEV containers
ddev start
```

Wait for DDEV to start successfully.

### Step 5: Install TYPO3 Environments

Provide options to user:

**Option A: Install All Versions** (Recommended for compatibility testing)
```bash
ddev install-all
```

**Option B: Install Specific Version** (Faster for targeted development)
```bash
ddev install-v11    # TYPO3 11.5 LTS
ddev install-v12    # TYPO3 12.4 LTS
ddev install-v13    # TYPO3 13.4 LTS
```

Installation time: ~2-5 minutes per version (depending on network speed)

### Step 6: Provide Access Information

After successful installation, display:

```
✅ DDEV Environment Ready!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Overview Dashboard:
   https://{{DDEV_SITENAME}}.ddev.site/

🌐 TYPO3 Installations:

   TYPO3 11.5 LTS
   Frontend: https://v11.{{DDEV_SITENAME}}.ddev.site/
   Backend:  https://v11.{{DDEV_SITENAME}}.ddev.site/typo3/

   TYPO3 12.4 LTS
   Frontend: https://v12.{{DDEV_SITENAME}}.ddev.site/
   Backend:  https://v12.{{DDEV_SITENAME}}.ddev.site/typo3/

   TYPO3 13.4 LTS
   Frontend: https://v13.{{DDEV_SITENAME}}.ddev.site/
   Backend:  https://v13.{{DDEV_SITENAME}}.ddev.site/typo3/

🔑 Backend Credentials:
   Username: admin
   Password: Password:joh316

📦 Your Extension:
   Installed in all TYPO3 versions
   Source: /var/www/{{EXTENSION_KEY}}/ (bind-mounted from project root)

⚙️  Useful Commands:
   ddev restart          # Restart containers
   ddev ssh              # SSH into web container
   ddev logs             # View container logs
   ddev describe         # Show project details
   ddev stop             # Stop containers
   ddev delete           # Remove containers (keeps volumes)
```

### Step 7: Generate Makefile (Optional but Recommended)

After DDEV setup, generate a standardized Makefile following Netresearch's pattern for convenient command access:

```bash
ddev generate-makefile
```

#### Makefile Features

The generated Makefile provides a unified interface with 30+ targets:

**DDEV Management:**
```bash
make up              # Complete startup (start DDEV + install all TYPO3 versions)
make start           # Start DDEV environment
make stop            # Stop DDEV environment
make install-v11     # Install TYPO3 11.5 LTS
make install-v12     # Install TYPO3 12.4 LTS
make install-v13     # Install TYPO3 13.4 LTS
make install-all     # Install all TYPO3 versions
make urls            # Show all access URLs
```

**Testing & Quality:**
```bash
make test            # Run all tests (unit + functional)
make test-unit       # Run unit tests only
make test-functional # Run functional tests
make lint            # Run all linters (PHP syntax + PHPStan + code style)
make format          # Auto-fix code style issues
make typecheck       # Run PHPStan static analysis
make ci              # Complete CI pipeline (pre-commit checks)
```

**Developer Convenience:**
```bash
make help            # Show all available commands (default target)
make ssh             # SSH into DDEV web container
make clean           # Clean temporary files and caches
```

**Extension-Specific Commands:**

The Makefile includes a customizable section for extension-specific commands. Developers can add their own targets following the pattern:

```makefile
.PHONY: my-command
my-command: ## Description of my command
	ddev ssh -d v12 "vendor/bin/typo3 extension:command"
```

#### Why Use the Makefile?

1. **Consistency** - Follows Netresearch's established pattern across TYPO3 extensions
2. **Single Command Setup** - `make up` does everything (DDEV start + install all versions)
3. **Discoverability** - `make help` shows all available commands with descriptions
4. **CI Integration** - Standardized `make ci`, `make test`, `make lint` for pipelines
5. **Developer Experience** - Familiar interface, shorter commands than `ddev` equivalents
6. **Documentation** - Self-documenting with auto-generated help

#### Example Workflow

```bash
# Initial setup
make up              # Start DDEV + install all TYPO3 versions

# Development
make lint            # Check code quality
make test            # Run tests
make format          # Fix code style

# Check URLs
make urls            # Show all access URLs

# Complete CI check before commit
make ci              # Run full quality pipeline
```

#### Customization

After generation, edit the Makefile to add project-specific commands while keeping core targets (up, start, test, lint, ci) unchanged for consistency across projects.

The Makefile is optional but highly recommended for improved developer experience.

### Step 8: Generate Project Index Page (Optional but Recommended)

After DDEV setup, generate a beautiful overview page for easy access to all TYPO3 versions and development tools:

```bash
ddev generate-index
```

#### Index Page Features

The generated `index.html` provides a centralized dashboard with:

**Visual Overview:**
- Modern, responsive design with gradient background
- Card-based layout for each TYPO3 version
- Clear visual hierarchy and hover effects
- Mobile-friendly responsive grid

**Quick Access Links:**
```
TYPO3 v12 LTS:
  - Frontend: https://v12.{project}.ddev.site/
  - Backend:  https://v12.{project}.ddev.site/typo3/

TYPO3 v13 LTS:
  - Frontend: https://v13.{project}.ddev.site/
  - Backend:  https://v13.{project}.ddev.site/typo3/
```

**Development Tools:**
- Backend credentials display (admin / Password:joh316)
- Mailpit access link
- Documentation link (if available)

#### Why Use the Index Page?

1. **Single Entry Point** - Access all TYPO3 versions from one beautiful page
2. **Eliminates URL Guessing** - No need to remember subdomain patterns
3. **Professional Presentation** - Polished interface for the development environment
4. **Credential Reference** - Backend login info always visible
5. **Tool Discovery** - Links to Mailpit and other development tools
6. **Multi-Version Testing** - Easy switching between TYPO3 12 and 13

#### Example Usage

```bash
# After DDEV setup
ddev generate-index

# Access the overview page
open https://{project}.ddev.site/
# or
open http://{project}.ddev.site/
```

The index page is accessible at both the main domain (e.g., `temporal-cache.ddev.site`) and serves as the landing page for the entire development environment.

#### Customization

After generation, you can edit `index.html` to:
- Add extension-specific documentation links
- Include CI/CD status badges
- Add custom tool links (PHPMyAdmin, Redis Commander, etc.)
- Customize colors, branding, or layout
- Add project-specific information or notes

The index page is optional but highly recommended for improved developer experience, especially in multi-version testing environments.

## Error Handling

### Common Issues and Solutions

**1. DDEV Not Installed**
```
❌ DDEV is not installed.

Install DDEV:
  - macOS: brew install ddev/ddev/ddev
  - Linux: https://ddev.readthedocs.io/en/stable/users/install/ddev-installation/
  - Windows: choco install ddev
```

**2. Docker Not Running**
```
❌ Docker is not running.

Start Docker Desktop or Docker service:
  - macOS/Windows: Open Docker Desktop
  - Linux: sudo systemctl start docker
```

**3. Not a TYPO3 Extension**
```
❌ This doesn't appear to be a TYPO3 extension project.

Requirements:
  - ext_emconf.php file present
  OR
  - composer.json with "type": "typo3-cms-extension"

Current directory: /path/to/project
```

**4. Port Conflicts**
```
❌ DDEV failed to start (port 80/443 conflict)

Solutions:
  - Stop other local web servers (Apache, Nginx, MAMP)
  - Or use different ports in .ddev/config.yaml:
    router_http_port: "8080"
    router_https_port: "8443"
```

**5. Installation Failures**
```
❌ TYPO3 installation failed

Troubleshooting:
  1. Check logs: ddev logs
  2. SSH into container: ddev ssh
  3. Check Composer: ddev composer diagnose
  4. Try reinstalling: rm -rf /var/www/html/v13/* && ddev install-v13
```

## Advanced Options

### Custom PHP Version

If extension requires different PHP version:
```yaml
# In .ddev/config.yaml
php_version: "8.1"  # or "8.3"
```

### Database Selection (Tiered Approach)

The skill uses **intelligent database selection** based on extension complexity.

**🎯 Tier 1: SQLite (Simple Extensions - Development Optimized)**

**Recommended for:**
- ✅ Extensions using only TYPO3 Core APIs (Extbase, FAL, DataHandler)
- ✅ No custom database tables (ext_tables.sql absent/empty)
- ✅ No raw SQL queries
- ✅ Category: plugin, fe, be, misc
- ✅ Example: rte_ckeditor_image, simple content elements, frontend plugins

**Benefits:**
- ⚡ **Startup**: 5-10 seconds faster per ddev start
- 💾 **RAM**: 900 MB saved (no MariaDB container)
- 💿 **Disk**: 744 MB saved (no container image)
- 🔒 **Isolation**: Perfect v11/v12/v13 separation (separate .sqlite files)

**Configuration:**
```yaml
# No .ddev/config.yaml database config needed
# TYPO3 installation uses SQLite automatically
```

**Critical Warnings:**
- ⚠️ **Development ONLY** - Never use SQLite in production
- ⚠️ **Switch to MariaDB** if you add custom SQL queries or tables
- ⚠️ **Final Testing** - Run compatibility tests on MariaDB before release

**🔧 Tier 2: MariaDB 10.11 (Complex Extensions - Production Parity)**

**Recommended for:**
- ❌ Extensions with custom database tables (ext_tables.sql present)
- ❌ Extensions using raw SQL queries
- ❌ Performance-critical operations
- ❌ Category: services, module
- ❌ Unknown complexity (safe default)

**Benefits:**
- ✅ **Production Standard**: 95%+ TYPO3 hosting uses MariaDB
- ✅ **Extension Compatibility**: 99%+ TYPO3 extensions tested on MariaDB
- ✅ **Performance**: 13-36% faster than MySQL 8 for transactional workloads
- ✅ **TYPO3 Ecosystem**: Documentation, tutorials, community standard

**Configuration:**
```yaml
# In .ddev/config.yaml
database:
  type: mariadb
  version: "10.11"
```

**🌐 Tier 3: PostgreSQL 16 (Specialized Requirements)**

**Recommended for:**
- 🎯 GIS/spatial data (PostGIS)
- 🎯 Advanced analytics or complex queries
- 🎯 Explicit PostgreSQL requirement

**Configuration:**
```yaml
# In .ddev/config.yaml
database:
  type: postgres
  version: "16"
```

**🏢 Tier 4: MySQL 8.0 (Corporate/Oracle Ecosystem)**

**Recommended for:**
- 🏢 Corporate environments requiring Oracle integration
- 🏢 Production specifically uses MySQL 8

**Configuration:**
```yaml
# In .ddev/config.yaml
database:
  type: mysql
  version: "8.0"
```

**Auto-Detection Logic:**

The skill will analyze your extension and suggest the appropriate tier:

```yaml
SQLite Detection (Tier 1):
  ✓ ext_tables.sql: Absent or empty
  ✓ Raw SQL patterns: None found
  ✓ File size: < 1 MB
  ✓ Category: plugin, fe, be, misc
  → Suggests: SQLite (development-optimized)

MariaDB Detection (Tier 2):
  ✗ ext_tables.sql: Present with custom tables
  ✗ Raw SQL patterns: Found
  ✗ File size: > 1 MB
  ✗ Category: services, module
  → Suggests: MariaDB 10.11 (production-realistic)

PostgreSQL Detection (Tier 3):
  • Extension name: Contains "postgres", "pgsql", "postgis"
  • composer.json: Requires "typo3/cms-pgsql"
  • Keywords: "GIS", "spatial", "analytics"
  → Suggests: PostgreSQL 16 (specialized)
```

**Alternative Options:**

**MariaDB 11** - Forward-looking performance:
```yaml
database:
  type: mariadb
  version: "11.4"
```
- Latest features (+40% performance vs 10.11)
- Forward compatibility testing

**For detailed rationale**, see: `docs/adr/0002-mariadb-default-with-database-alternatives.md`

### XDebug Setup

Enable XDebug for debugging:
```bash
ddev xdebug on
```

### Customize TYPO3 Versions

Edit `.ddev/docker-compose.web.yaml` and installation scripts to add/remove versions.

### Database Access

```bash
# Direct database access
ddev mysql

# Export database
ddev export-db > backup.sql.gz

# Import database
ddev import-db --file=backup.sql.gz
```

### Optional Services

The skill includes optional service templates for enhanced TYPO3 development:

#### Valkey / Redis (Caching)

Add high-performance caching to TYPO3 using **Valkey** (default) or **Redis** (alternative).

**Default: Valkey 8** (Open Source, Future-Proof)

```bash
# Copy Valkey template (default)
cp .ddev/templates/docker-compose.services.yaml.optional .ddev/docker-compose.services.yaml
cp .ddev/templates/config.redis.php.example .ddev/config.redis.php.example

# Restart DDEV
ddev restart

# Test Valkey (wire-compatible with Redis)
ddev ssh
redis-cli -h valkey ping  # Should return: PONG
```

**Alternative: Redis 7** (For Legacy Production Parity)

```bash
# Use Redis 7 alternative template
cp .ddev/templates/docker-compose.services-redis.yaml.optional .ddev/docker-compose.services.yaml

# Restart DDEV
ddev restart

# Test Redis
ddev ssh
redis-cli -h redis ping  # Should return: PONG
```

**Why Valkey Default?**

Valkey is wire-protocol compatible with Redis but offers:
- ✅ **True Open Source**: BSD-3-Clause license (Redis 7.4+ is proprietary)
- ✅ **Industry Adoption**: AWS, Google Cloud, Oracle backing (Linux Foundation project)
- ✅ **Smaller Image**: 69.7 MB (vs 100 MB Redis 8, 60.6 MB Redis 7)
- ✅ **Cost-Effective**: 20-33% cheaper on AWS ElastiCache
- ✅ **Future-Proof**: Strategic direction for cloud/managed hosting

**When to Use Redis 7 Instead:**
- Your production environment explicitly uses Redis 7.x
- Corporate policy requires battle-tested technology only (Redis has 15 years vs Valkey 1 year)
- Exact production-development parity needed with existing infrastructure

**Technical Details:**

**Valkey**: `valkey/valkey:8-alpine` (69.7 MB)
**Redis**: `redis:7-alpine` (60.6 MB)
**Memory**: 256MB with LRU eviction policy
**Port**: 6379 (same for both)

**Configuration**: Both use identical TYPO3 configuration. Add cache backend to `AdditionalConfiguration.php` (see `.ddev/config.redis.php.example`)

**For detailed rationale**, see: `docs/adr/0001-valkey-default-with-redis-alternative.md`

#### MailPit (Email Testing)

Catch all emails sent by TYPO3 for testing:

```bash
# Already included in docker-compose.services.yaml.optional
# Access Web UI after ddev restart:
# http://{{DDEV_SITENAME}}.ddev.site:8025
```

**Image**: `axllent/mailpit:latest`
**SMTP**: `mailpit:1025` (automatically configured in docker-compose.web.yaml)

#### Ofelia (TYPO3 Scheduler Automation)

Automate TYPO3 scheduler tasks with **ghcr.io/netresearch/ofelia**:

```bash
# Copy Ofelia configuration
cp .ddev/templates/docker-compose.ofelia.yaml.optional .ddev/docker-compose.ofelia.yaml

# Restart DDEV
ddev restart

# View scheduler logs
docker logs -f ddev-{{DDEV_SITENAME}}-ofelia
```

**Image**: `ghcr.io/netresearch/ofelia:latest` (GitHub Container Registry - TYPO3-optimized fork)
**Default Schedule**: TYPO3 scheduler runs every 1 minute for all versions
**Cache Warmup**: Every 1 hour for v13

**DDEV Naming**: Uses `docker-compose.*.yaml` naming (DDEV v1.24.8 requirement, not Compose v2 standard)
**No Version Field**: All service files omit `version:` declaration per Compose v2 spec

#### Shell Aliases

Add convenient shortcuts:

```bash
# Copy bash additions
cp .ddev/templates/homeadditions/.bashrc_additions.optional .ddev/homeadditions/.bashrc_additions

# Restart DDEV to load aliases
ddev restart

# Available aliases:
ddev ssh
t3-scheduler-v11    # Run TYPO3 11 scheduler
t3-scheduler-v12    # Run TYPO3 12 scheduler
t3-scheduler-v13    # Run TYPO3 13 scheduler
t3-scheduler-all    # Run scheduler on all versions
redis               # Access Redis CLI
t3-cache-flush-v13  # Flush TYPO3 13 cache
```

#### Complete Services Documentation

For detailed service configuration, troubleshooting, and performance tuning:

```bash
# Copy services README
cp .ddev/templates/README-SERVICES.md.optional .ddev/README-SERVICES.md
```

**Important Notes**:
- DDEV v1.24.8 requires `docker-compose.*.yaml` naming (auto-loads from `.ddev/`)
- Ofelia image: `ghcr.io/netresearch/ofelia:latest` (not Docker Hub)
- Ofelia command: `daemon --docker-events` (not `--docker`)
- Redis config must NOT be `.yaml` (DDEV tries to parse it as config)

## Documentation Rendering

### Rendering Extension Documentation

If the extension has a `Documentation/` directory with reStructuredText (.rst) files:

```bash
ddev docs
```

**What it does:**
- Renders `.rst` documentation files to HTML using TYPO3's official render-guides Docker image
- Outputs to `Documentation-GENERATED-temp/`
- Makes documentation accessible at `https://docs.{{DDEV_SITENAME}}.ddev.site/`

**Requirements:**
- `Documentation/Index.rst` must exist
- Docker must be running on the host

**Output:**
```
📚 Rendering TYPO3 Extension Documentation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📖 Source:  Documentation/
📦 Output:  Documentation-GENERATED-temp/

🔨 Rendering documentation with TYPO3 render-guides...

✅ Documentation rendered successfully!

🌐 View at: https://docs.{{DDEV_SITENAME}}.ddev.site/
```

**Note:** The docs subdomain is automatically configured in `.ddev/apache/apache-site.conf` and accessible after running `ddev docs`.

## Demo Content (Introduction Package)

For testing your extension with realistic content:

```bash
# Copy the install-introduction command
cp .ddev/templates/commands/web/install-introduction.optional .ddev/commands/web/install-introduction
chmod +x .ddev/commands/web/install-introduction

# Install Introduction Package
ddev install-introduction v13
```

**What's Included:**
- 86+ pages with full page tree structure
- 226+ content elements (text, images, forms, tables)
- Multi-language support (English, German, Danish)
- Bootstrap Package responsive theme
- Example content for testing RTE features

**Access:**
- Frontend: `https://{{DDEV_SITENAME}}.ddev.site/`
- Backend: `https://{{DDEV_SITENAME}}.ddev.site/typo3/`

## Extension Auto-Configuration

For extensions requiring additional setup (RTE configuration, Page TSConfig, TypoScript), create a custom configuration command:

```bash
# Copy the configure-extension template
cp .ddev/templates/commands/web/configure-extension.optional .ddev/commands/web/configure-{{EXTENSION_KEY}}
chmod +x .ddev/commands/web/configure-{{EXTENSION_KEY}}

# Edit to add your extension-specific configuration
# Examples: RTE YAML, Page TSConfig, site package setup

# Run after TYPO3installation
ddev configure-{{EXTENSION_KEY}} v13
```

### Use Cases for Auto-Configuration

**RTE/CKEditor Extensions:**
- Create RTE YAML configuration importing your plugin
- Set up toolbar buttons and editor config
- Configure Page TSConfig for RTE presets
- Example: `rte_ckeditor_image` with custom image handling

**Backend Module Extensions:**
- Set up Page TSConfig for module access
- Configure user permissions
- Create initial database records

**Frontend Plugin Extensions:**
- Set up TypoScript configuration
- Create example content elements
- Configure plugin settings

### Template Structure

The `configure-extension.optional` template includes:

1. **Introduction Package Installation** - Demo content for testing
2. **Site Package Creation** - Programmatic extension setup with:
   - `ext_emconf.php` - Extension metadata
   - `ext_localconf.php` - Global configuration
   - `ext_tables.php` - Table definitions and TSConfig loading
3. **Configuration Files** - RTE YAML, Page TSConfig, TypoScript
4. **Cache Flushing** - Ensure changes take effect
5. **Success Message** - Clear next steps for developer

### Example: RTE Configuration Command

For a CKEditor plugin extension:

```bash
#!/bin/bash
VERSION=${1:-v13}
INSTALL_DIR=/var/www/html/$VERSION

# Install demo content
composer require typo3/cms-introduction -d $INSTALL_DIR
vendor/bin/typo3 extension:setup --extension=introduction

# Create site package
mkdir -p $INSTALL_DIR/public/typo3conf/ext/site_rte/Configuration/RTE

# Create RTE YAML importing your plugin
cat > .../Configuration/RTE/Default.yaml << 'EOF'
imports:
  - { resource: "EXT:rte_ckeditor/Configuration/RTE/Default.yaml" }
  - { resource: "EXT:your_extension/Configuration/RTE/Plugin.yaml" }

editor:
  config:
    toolbar:
      items:
        - your_custom_button
        - ...
EOF

# Flush caches
vendor/bin/typo3 cache:flush
```

**Benefits:**
- One-command setup after TYPO3 installation
- Consistent configuration across team
- Demo content ready for testing
- Reduces manual configuration errors

## Troubleshooting

### Database Already Exists Error

If reinstalling TYPO3 and you get "database already exists" errors:

```bash
# Clean up and recreate database
ddev mysql -e "DROP DATABASE IF EXISTS v13; CREATE DATABASE v13;"

# Now retry installation
ddev install-v13
```

### TYPO3 Setup Shows "Database contains tables" Error

```bash
# Option 1: Clean database
ddev mysql v13 -e "DROP DATABASE v13; CREATE DATABASE v13;"

# Option 2: Use different database name
# Edit install-v* script to use different DB name
```

### Services Not Loading

If Redis, MailPit, or Ofelia containers don't start:

```bash
# Check container status
docker ps --filter "name=ddev-{{DDEV_SITENAME}}"

# View logs
docker logs ddev-{{DDEV_SITENAME}}-redis
docker logs ddev-{{DDEV_SITENAME}}-mailpit
docker logs ddev-{{DDEV_SITENAME}}-ofelia

# Restart DDEV
ddev restart
```

### Extension Not Appearing in Backend

```bash
# Flush all caches
ddev exec -d /var/www/html/v13 vendor/bin/typo3 cache:flush

# Check extension is symlinked
ddev exec ls -la /var/www/html/v13/vendor/{{VENDOR}}/{{EXTENSION_KEY}}
```

## Validation Checklist

Before completing, verify:

- [ ] All prerequisite checks passed
- [ ] Extension metadata extracted correctly
- [ ] User confirmed configuration values
- [ ] All .ddev files generated with correct variable replacements
- [ ] DDEV started successfully (`ddev describe` works)
- [ ] At least one TYPO3 version installed successfully
- [ ] URLs are accessible in browser
- [ ] Backend login works with provided credentials
- [ ] Extension appears in TYPO3 Extension Manager

## Communication Style

- Use clear, concise language
- Show progress indicators during long operations
- Use emojis for visual clarity (✅ ❌ 🔧 📦 🌐 🔑)
- Provide copy-pasteable commands
- Explain what each step does and why
- Offer both automated and manual options
- Be encouraging and supportive

## Example Interaction

```
User: Set up DDEV for my TYPO3 extension