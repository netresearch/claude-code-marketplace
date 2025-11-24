---
name: typo3-ddev
description: "Automate DDEV environment setup for TYPO3 extension development. Use when setting up local development environment, configuring DDEV for TYPO3 extensions, or creating multi-version TYPO3 testing environments. Covers: DDEV configuration generation, TYPO3 11.5/12.4/13.4 LTS installation, custom DDEV commands, Apache vhost setup, Docker volume management, and .gitignore best practices (avoid double-ignore anti-pattern). Provides complete automation from metadata detection to ready-to-use TYPO3 backend access."
license: MIT License - see LICENSE file
metadata:
  author: Netresearch
  repository: https://github.com/netresearch/typo3-ddev-skill
  version: 1.6.0
  tags:
    - typo3
    - ddev
    - docker
    - development
    - testing
    - devops
  platforms:
    - linux
    - macos
    - windows
  typo3-versions:
    - 11.5-lts
    - 12.4-lts
    - 13.4-lts
---
# TYPO3 DDEV Setup Skill

This skill automates DDEV environment setup for TYPO3 extension development projects. It creates a complete TYPO3 development environment for testing and developing extensions across multiple TYPO3 versions.

## Purpose

This skill automates the setup of DDEV for TYPO3 extension development projects. It creates a multi-version TYPO3 testing environment where the extension can be developed and tested across TYPO3 11.5 LTS, 12.4 LTS, and 13.4 LTS simultaneously.

## When to Use This Skill

Use this skill when:
- Developer has a TYPO3 extension project and wants to set up DDEV
- Project contains `ext_emconf.php` or is identified as a TYPO3 extension in `composer.json`
- Developer needs to test extension across multiple TYPO3 versions
- Quick development environment spin-up is needed

## Prerequisites Validation

Before executing ANY DDEV commands, perform comprehensive prerequisite validation:

1. **Run validation script**: Execute `scripts/validate-prerequisites.sh` to check:
   - Docker daemon status (must be running)
   - Docker CLI version (requires >= 20.10)
   - Docker Compose version (requires >= 2.0)
   - DDEV installation (must be present)
   - TYPO3 extension project structure (must be valid)

2. **If validation fails**: Consult `references/prerequisites-validation.md` for platform-specific installation instructions (Linux/WSL2, macOS, Windows), version requirements, manual validation steps, and troubleshooting

3. **Report results**: Display validation status to user with specific instructions for any missing prerequisites

Always validate on the FIRST DDEV command in a session to catch environment issues early.

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

**What gets installed automatically:**
- ✅ TYPO3 Core (specified version)
- ✅ Your extension (activated and ready to use)
- ✅ TYPO3 Backend Styleguide (for UI pattern reference)
- ✅ Extension Manager
- ✅ Introduction Package (86+ pages with demo content for testing)

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

**For advanced branding and customization details including:**
- Automatic branding detection (Netresearch/TYPO3/generic)
- Brand-specific color schemes and typography
- Design specifications

See: `references/index-page-generation.md`

## Error Handling

When encountering errors during setup or installation:

1. **Check error category**: Identify if the error relates to prerequisites, database setup, extension detection, or service configuration
2. **Consult troubleshooting guide**: Read `references/troubleshooting.md` and locate the relevant error category
3. **Apply recommended solution**: Follow the step-by-step resolution guide for the specific error
4. **For Windows/WSL2 environments**: If error persists on Windows, consult `references/windows-fixes.md` for platform-specific solutions (CRLF issues, health check failures, Apache config problems)
5. **Performance issues on Windows**: Consult `references/windows-optimizations.md` for performance tuning

Report the error to the user with the specific solution being applied, then re-attempt the failed operation.

## Advanced Configuration

When user requests customizations beyond the standard setup:

1. **Identify customization type**: Determine if request involves PHP version, database engine, debugging tools, TYPO3 versions, or additional services
2. **Consult advanced options guide**: Read `references/advanced-options.md` for the relevant configuration section
3. **Present options to user**: Show available choices (e.g., PHP 8.1/8.2/8.3, database engines with tiered selection logic)
4. **Apply configuration**: Follow the templates and instructions in `references/advanced-options.md` to implement the requested customization
5. **Configure optional services**: If user needs Valkey/Redis caching, MailPit, Ofelia scheduler, or other services, follow the service configuration templates in the advanced guide

Offer customization options proactively when user mentions performance requirements, specific PHP versions, or debugging needs.

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

When discussing testing capabilities with users, inform them that the Introduction Package is automatically installed with every TYPO3 version during setup, providing:

- 86+ pages with full page tree structure for testing navigation
- 226+ content elements (text, images, forms, tables) for testing rendering
- Multi-language support (English, German, Danish) for testing translations
- Bootstrap Package responsive theme for testing frontend integration
- RTE feature examples for testing rich text functionality

Direct users to test their extension against this demo content at:
- Frontend: `https://v11.{{DDEV_SITENAME}}.ddev.site/` (or v12, v13)
- Backend: `https://v11.{{DDEV_SITENAME}}.ddev.site/typo3/` (or v12, v13)

No manual installation required—the package installs automatically during `ddev install-all` or individual version commands.

## Extension Auto-Configuration

When user's extension requires additional setup beyond standard installation (RTE configuration, Page TSConfig, TypoScript), guide them through creating a custom configuration command:

```bash
# Copy the configure-extension template
cp .ddev/templates/commands/web/configure-extension.optional .ddev/commands/web/configure-{{EXTENSION_KEY}}
chmod +x .ddev/commands/web/configure-{{EXTENSION_KEY}}

# Edit to add your extension-specific configuration
# Examples: RTE YAML, Page TSConfig, site package setup

# Run after TYPO3installation
ddev configure-{{EXTENSION_KEY}} v13
```

### Identify Configuration Needs by Extension Type

**For RTE/CKEditor Extensions**, configure:
- RTE YAML configuration importing the plugin
- Toolbar buttons and editor config
- Page TSConfig for RTE presets
- Example reference: `rte_ckeditor_image` with custom image handling

**For Backend Module Extensions**, configure:
- Page TSConfig for module access
- User permissions setup
- Initial database records

**For Frontend Plugin Extensions**, configure:
- TypoScript configuration
- Example content elements
- Plugin settings

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

### TYPO3 v13 Site Sets Approach

**Important:** TYPO3 v13 introduces site sets as the modern approach for TypoScript and configuration loading, replacing static templates.

**Site Sets vs Static Templates:**

| Feature | Site Sets (TYPO3 v13+) | Static Templates (Legacy) |
|---------|------------------------|---------------------------|
| Configuration | `config.yaml` in site config | `sys_template` database records |
| Loading Order | Dependency-based | Include order in template |
| Type Safety | Schema-validated | No validation |
| Maintenance | Version-controlled files | Database-stored |
| Best Practice | ✅ Use for TYPO3 v13+ | ⚠️ Legacy approach |

**How Extensions Should Provide Configuration:**

1. **Create a Site Set** in your extension:
   ```
   Configuration/Sets/YourExtensionName/
   ├── config.yaml          # Site set metadata
   ├── setup.typoscript     # TypoScript configuration
   └── page.tsconfig        # Page TSConfig (optional)
   ```

2. **Define Site Set** in `config.yaml`:
   ```yaml
   name: vendor/extension-name
   label: 'Your Extension Name'
   # Optional dependencies load BEFORE your set
   optionalDependencies:
     - typo3/fluid-styled-content
     - bk2k/bootstrap-package
   ```

3. **Import TypoScript** in `setup.typoscript`:
   ```typoscript
   @import 'EXT:your_extension/Configuration/TypoScript/*.typoscript'
   ```

4. **Users Add to Site Configuration** (`config/sites/main/config.yaml`):
   ```yaml
   dependencies:
     - bootstrap-package/full      # Frontend rendering
     - vendor/extension-name        # Your extension
   ```

**Benefits:**
- ✅ No sys_template database records needed
- ✅ Proper dependency ordering
- ✅ Version-controlled configuration
- ✅ No static template conflicts
- ✅ Type-safe settings with schema

**Common Pitfall:** Avoid loading TypoScript via BOTH site sets AND static templates - this causes double-loading and configuration conflicts (e.g., duplicate `lib.parseFunc_RTE.tags.img` processors causing unexpected behavior).

**Debugging Site Sets:**
```bash
# Check active site sets for a site
ddev exec vendor/bin/typo3 site:show <siteIdentifier>

# View resolved TypoScript (TYPO3 v13)
Backend → Site Management → Sites → [Your Site] → Dependencies
```

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

### Step 9: Verify Installation

After installation completes, perform these verification steps in order:

1. **Confirm prerequisites passed**: Review output from Step 1 prerequisite validation
2. **Verify extension metadata**: Check that extracted values match project configuration
3. **Test DDEV status**: Run `ddev describe` to confirm containers are running
4. **Validate TYPO3 installations**: Confirm at least one version installed without errors
5. **Test URL accessibility**: Open each TYPO3 version URL in browser to verify routing
6. **Verify backend access**: Log in to TYPO3 backend with credentials (admin / Password:joh316)

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

### .gitignore Configuration Best Practices

**CRITICAL:** Ensure `.ddev/.gitignore` is committed to version control, NOT ignored!

**The Double-Ignore Anti-Pattern:**

DDEV often generates `.ddev/.gitignore` with this problematic structure:

```
#ddev-generated: Automatically generated ddev .gitignore.
# You can remove the above line if you want to edit and maintain this file yourself.
/.gitignore    ← File ignores ITSELF!
```

**The Problem:**

1. `.ddev/.gitignore` ignores itself (`/.gitignore`)
2. Root `.gitignore` also ignores it (`.ddev/.gitignore`)
3. Result: DDEV ignore rules NOT shared with team
4. Each developer must generate their own DDEV config
5. Inconsistent git behavior across team members

**The Fix:**

1. **Remove from root `.gitignore`:**
   ```diff
   # .gitignore (ROOT)
   .ddev/.homeadditions
   .ddev/.ddev-docker-compose-full.yaml
   - .ddev/.gitignore    ← REMOVE THIS LINE
   ```

2. **Fix `.ddev/.gitignore` to not self-ignore:**
   ```diff
   # .ddev/.gitignore (UPDATED)
   - #ddev-generated: Automatically generated ddev .gitignore.
   - # You can remove the above line if you want to edit and maintain this file yourself.
   - /.gitignore
   + # DDEV gitignore rules
   + # Manually maintained to ensure consistency across team

   /**/*.example
   /.dbimageBuild
   /.ddev-docker-*.yaml
   ```

3. **Commit DDEV configuration to share with team:**
   ```bash
   git add .ddev/.gitignore .ddev/config.yaml .ddev/docker-compose.*.yaml
   git add .ddev/apache/ .ddev/commands/ .ddev/web-build/
   git commit -m "[TASK] Add DDEV configuration for development environment"
   ```

**What to Commit vs. Ignore:**

✅ **Commit (share with team):**
- `.ddev/.gitignore` (ignore rules)
- `.ddev/config.yaml` (main config)
- `.ddev/docker-compose.*.yaml` (custom services)
- `.ddev/apache/` (custom Apache config)
- `.ddev/commands/` (custom DDEV commands)
- `.ddev/web-build/` (custom Dockerfile)

❌ **Ignore (personal/generated):**
- `.ddev/.homeadditions` (personal shell config)
- `.ddev/.ddev-docker-compose-full.yaml` (auto-generated)
- `.ddev/db_snapshots/` (database snapshots)
- `.ddev/.sshimageBuild` (build artifacts)
- `.ddev/.webimageBuild` (build artifacts)

**Validation:**

After fixing, verify:
```bash
# Should show .ddev/.gitignore as tracked
git ls-files .ddev/.gitignore

# Should list DDEV files to be committed
git status .ddev/
```

**Benefits:**

- ✅ Consistent environment across all developers
- ✅ Shared DDEV ignore rules
- ✅ Quick onboarding: `git clone && ddev start`
- ✅ No manual DDEV configuration needed
- ✅ Team follows same git patterns

## Validation Checklist

Before completing, verify:

1. **Confirm prerequisites passed**: Review output from Step 1 prerequisite validation
2. **Verify extension metadata**: Check that extracted values match project configuration
3. **Test DDEV status**: Run `ddev describe` to confirm containers are running
4. **Validate TYPO3 installations**: Confirm at least one version installed without errors
5. **Test URL accessibility**: Open each TYPO3 version URL in browser to verify routing
6. **Verify backend access**: Log in to TYPO3 backend with credentials (admin / Password:joh316)
7. **Confirm extension activation**: Check Extension Manager to ensure extension is loaded

If any verification fails, consult the Troubleshooting section above for resolution steps.

## Output Formatting Guidelines

Throughout all steps, format output for clarity:
- Use emojis for visual indicators: ✅ (success), ❌ (error), 🔧 (configuration), 📦 (installation), 🌐 (URLs), 🔑 (credentials)
- Display progress indicators during operations taking >5 seconds
- Provide copy-pasteable command blocks with explanations
- Present configuration values in formatted tables or code blocks
- Explain what each command does before executing it