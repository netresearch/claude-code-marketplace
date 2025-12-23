# TYPO3 DDEV Skill

> An Agent Skill for automating DDEV environment setup in TYPO3 extension projects

[![TYPO3](https://img.shields.io/badge/TYPO3-11%20%7C%2012%20%7C%2013-orange.svg)](https://typo3.org/)
[![DDEV](https://img.shields.io/badge/DDEV-Local%20Development-blue.svg)](https://ddev.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Agent Skill](https://img.shields.io/badge/Agent%20Skill-Compatible-blueviolet.svg)](https://agentskills.io)

## 🔌 Compatibility

This is an **Agent Skill** following the [open standard](https://agentskills.io) originally developed by Anthropic and released for cross-platform use.

**Supported Platforms:**
- ✅ Claude Code (Anthropic)
- ✅ Cursor
- ✅ Windsurf
- ✅ GitHub Copilot
- ✅ Other skills-compatible AI agents

> Skills are portable packages of procedural knowledge that work across any AI agent supporting the Agent Skills specification.


## Overview

This skill helps TYPO3 extension developers quickly set up a complete DDEV development environment with multiple TYPO3 versions. Instead of manually configuring DDEV, this skill automates the entire process - from detecting your extension metadata to generating all configuration files and installing TYPO3.

### What It Does

- ✅ Detects TYPO3 extension projects automatically
- ✅ Extracts extension metadata (key, package name, namespace)
- ✅ Generates complete DDEV configuration
- ✅ Creates multi-version TYPO3 testing environment (11.5, 12.4, 13.4 LTS)
- ✅ Provides backend and frontend access with preconfigured credentials
- ✅ Includes custom DDEV commands for easy TYPO3 installation

### Who It's For

- TYPO3 extension developers
- Teams working on TYPO3 extensions
- Developers needing to test extensions across multiple TYPO3 versions
- Anyone wanting a quick, reproducible TYPO3 development environment

## Prerequisites

Before using this skill, ensure you have:

- [DDEV](https://ddev.readthedocs.io/en/stable/users/install/ddev-installation/) installed
- [Docker](https://www.docker.com/get-started) running
- A TYPO3 extension project (with `ext_emconf.php` or `composer.json`)
- A skills-compatible AI agent (Claude Code, Cursor, Windsurf, GitHub Copilot, etc.)

## Installation

### Option 1: Download Release (Recommended)

Download the [latest release](https://github.com/netresearch/typo3-ddev-skill/releases/latest) and extract to your agent's skills directory.

**Common skills directories:**
- **Claude Code**: `~/.claude/skills/typo3-ddev/`
- **Cursor**: `.cursor/skills/typo3-ddev/` (project) or `~/.cursor/skills/typo3-ddev/` (global)
- **Windsurf**: `.windsurf/skills/typo3-ddev/` (project) or `~/.windsurf/skills/typo3-ddev/` (global)

### Option 2: Manual Installation

```bash
# Clone to your agent's skills directory (example: Claude Code)
cd ~/.claude/skills/
git clone https://github.com/netresearch/typo3-ddev-skill.git typo3-ddev

# The skill is now available in your AI agent
```

## Usage

### Invoking the Skill

Once installed, invoke the skill in your TYPO3 extension project directory:

**Via slash command:**
```
/typo3-ddev
```

**Via natural language:**
```
Set up DDEV for my TYPO3 extension
```

The skill will:

1. Validate prerequisites (DDEV, Docker, TYPO3 extension structure)
2. Extract your extension metadata
3. Confirm configuration with you
4. Generate all `.ddev/` files with proper values
5. Guide you through starting DDEV and installing TYPO3

### What You'll Get

After setup, you'll have:

```
project-root/
├── .ddev/
│   ├── config.yaml
│   ├── docker-compose.web.yaml
│   ├── apache/
│   │   └── apache-site.conf
│   ├── web-build/
│   │   └── Dockerfile
│   └── commands/
│       └── web/
│           ├── install-v11
│           ├── install-v12
│           ├── install-v13
│           └── install-all
├── Classes/
├── Configuration/
├── ext_emconf.php
└── composer.json
```

### Accessing Your Environment

Once installed, access TYPO3 at:

**Overview Dashboard:**
```
https://your-ext.ddev.site/
```

**TYPO3 11.5 LTS:**
- Frontend: `https://v11.your-ext.ddev.site/`
- Backend: `https://v11.your-ext.ddev.site/typo3/`

**TYPO3 12.4 LTS:**
- Frontend: `https://v12.your-ext.ddev.site/`
- Backend: `https://v12.your-ext.ddev.site/typo3/`

**TYPO3 13.4 LTS:**
- Frontend: `https://v13.your-ext.ddev.site/`
- Backend: `https://v13.your-ext.ddev.site/typo3/`

### Backend Credentials

```
Username: admin
Password: Joh316!
```

## Custom DDEV Commands

The skill creates these custom commands:

```bash
# Install specific TYPO3 version
ddev install-v11  # TYPO3 11.5 LTS
ddev install-v12  # TYPO3 12.4 LTS
ddev install-v13  # TYPO3 13.4 LTS

# Install all versions at once
ddev install-all

# Install Introduction Package (demo content)
ddev install-introduction v13
```

## Adding Demo Content

Test your extension with realistic content using the TYPO3 Introduction Package:

```bash
# Install Introduction Package
ddev install-introduction v13
```

**Includes:**
- 86+ pages with example content
- 226+ content elements (text, images, forms, tables)
- Multi-language support (EN, DE, DA)
- Bootstrap Package responsive theme
- Perfect for testing RTE features

## Extension Auto-Configuration

For extensions needing additional setup (RTE config, TSconfig, TypoScript), create a custom configuration command:

```bash
# Copy template
cp .ddev/templates/commands/web/configure-extension.optional \
   .ddev/commands/web/configure-myext

# Customize for your extension's needs
# Add: RTE YAML, Page TSConfig, TypoScript, site package setup

# Run after TYPO3 installation
ddev configure-myext v13
```

**Use Cases:**
- **RTE/CKEditor plugins** - Configure toolbar, import plugin YAML
- **Backend modules** - Set up TSconfig, permissions
- **Frontend plugins** - TypoScript configuration, example content

**Pattern Benefits:**
- One-command post-install setup
- Consistent team configuration
- Includes demo content automatically
- Reduces manual configuration errors

See `SKILL.md` for detailed examples and template structure.

## Troubleshooting

### Database Already Exists

If reinstalling TYPO3:

```bash
ddev mysql -e "DROP DATABASE IF EXISTS v13; CREATE DATABASE v13;"
ddev install-v13
```

### Services Not Starting

Check and restart services:

```bash
docker ps --filter "name=ddev-your-ext"
ddev restart
```

### Extension Not Visible

Flush caches:

```bash
ddev exec -d /var/www/html/v13 vendor/bin/typo3 cache:flush
```

## Architecture

The setup creates a unique multi-version environment:

- **Extension Source**: Mounted at `/var/www/{{EXTENSION_KEY}}` (your project root)
- **TYPO3 Installations**: Separate directories for each version (`/var/www/html/v11`, `v12`, `v13`)
- **Extension Installation**: Installed via Composer path repository in each TYPO3 version
- **Persistent Data**: Docker volumes for each TYPO3 version database and files

This architecture allows you to:
- Develop extension code in your project root
- Test immediately across all TYPO3 versions
- Keep TYPO3 installations separate and clean
- Avoid committing TYPO3 core files to your extension repository

## Configuration

### Supported TYPO3 Versions

By default, the skill supports:
- TYPO3 11.5 LTS (PHP 8.0+)
- TYPO3 12.4 LTS (PHP 8.1+)
- TYPO3 13.4 LTS (PHP 8.2+)

PHP version is set to 8.2 for maximum compatibility.

### Customization

After generation, you can customize:

**PHP Version** (`.ddev/config.yaml`):
```yaml
php_version: "8.3"  # Change to 8.1, 8.3, or 8.5 if needed
```

**PHP Patch Upgrades** (`.ddev/web-build/Dockerfile.apt`):

When DDEV ships an older PHP patch (e.g., 8.5.0RC3) and you need a newer one (e.g., 8.5.1):
```dockerfile
# .ddev/web-build/Dockerfile.apt
RUN apt-get update
RUN apt-get install --only-upgrade -y php${PHP_VERSION}-*
```
Then run `ddev restart`.

**PHP Extensions** (`.ddev/web-build/Dockerfile`):
```dockerfile
# Use apt-get, NOT pecl (pecl not available in DDEV)
RUN apt-get update && apt-get install -y php${PHP_VERSION}-pcov
RUN apt-get update && apt-get install -y php${PHP_VERSION}-redis
```

**Custom PHP Settings** (`.ddev/php/custom.ini`):
```ini
memory_limit = 512M
max_execution_time = 300
```

**XDebug** (enable/disable):
```bash
ddev xdebug on   # Enable
ddev xdebug off  # Disable
```

**Database** (Tiered Selection: SQLite/MariaDB/PostgreSQL/MySQL):

The skill uses **intelligent tiered database selection** based on extension complexity:

**🎯 Tier 1: SQLite (Simple Extensions - Development Optimized)**

For extensions using only TYPO3 Core APIs (no custom tables, no raw SQL):

```yaml
# No .ddev/config.yaml database config needed
# TYPO3 installation automatically uses SQLite
```

**Benefits:**
- ⚡ Startup: 5-10 seconds faster per ddev start
- 💾 RAM: 900 MB saved (no container)
- 💿 Disk: 744 MB saved
- 🔒 Perfect v11/v12/v13 isolation

**⚠️ Development ONLY** - Never use SQLite in production. Switch to MariaDB for final testing.

**🔧 Tier 2: MariaDB 10.11 (Complex Extensions - Production Parity)**

For extensions with custom tables, raw SQL, or unknown complexity:

```yaml
# Default for complex extensions (.ddev/config.yaml)
database:
  type: mariadb
  version: "10.11"
```

**Why MariaDB 10.11?** Production standard (95% hosting), extension compatibility, 13-36% faster than MySQL 8.

**🌐 Tier 3 & 4: Specialized Databases**

```yaml
# PostgreSQL 16 (for GIS, analytics, full-text search)
database:
  type: postgres
  version: "16"

# MariaDB 11 (forward-looking performance)
database:
  type: mariadb
  version: "11.4"

# MySQL 8.0 (corporate/Oracle ecosystem)
database:
  type: mysql
  version: "8.0"
```

**For detailed rationale**, see `docs/adr/0002-mariadb-default-with-database-alternatives.md`.

**Caching Service** (Valkey or Redis):

The skill provides Valkey 8 as the default caching service (open source, future-proof):

```bash
# Default: Valkey 8
cp .ddev/templates/docker-compose.services.yaml.optional .ddev/docker-compose.services.yaml

# Alternative: Redis 7 (for legacy production parity)
cp .ddev/templates/docker-compose.services-redis.yaml.optional .ddev/docker-compose.services.yaml

# Restart DDEV
ddev restart
```

**Why Valkey?** True open source (BSD-3), AWS/Google/Oracle backing, 30% smaller than Redis 8, cost-effective. See `docs/adr/0001-valkey-default-with-redis-alternative.md` for details.

**Additional Services** (add to `.ddev/docker-compose.services.yaml`):
```yaml
# The services template includes: Valkey/Redis, MailPit, Ofelia
# See SKILL.md for complete documentation
```

## Troubleshooting

### DDEV Won't Start

**Port Conflicts:**
```bash
# Check what's using ports 80/443
sudo lsof -i :80
sudo lsof -i :443

# Option 1: Stop conflicting services
# Option 2: Change ports in .ddev/config.yaml
router_http_port: "8080"
router_https_port: "8443"
```

### PHP Version Outdated

If DDEV ships with an older PHP patch version:
```bash
# Create .ddev/web-build/Dockerfile.apt
echo 'RUN apt-get update' > .ddev/web-build/Dockerfile.apt
echo 'RUN apt-get install --only-upgrade -y php${PHP_VERSION}-*' >> .ddev/web-build/Dockerfile.apt
ddev restart
```

### PCOV/Extension Installation Fails

DDEV doesn't include `pecl`. Use `apt-get` instead:
```dockerfile
# In .ddev/web-build/Dockerfile
RUN apt-get update && apt-get install -y php${PHP_VERSION}-pcov
```

### PHP Settings Not Applied

Place settings in `.ddev/php/custom.ini`, NOT in `/usr/local/etc/php/conf.d/`:
```ini
# .ddev/php/custom.ini (correct location)
memory_limit = 512M
```

### Installation Fails

**Check Composer Issues:**
```bash
ddev ssh
composer diagnose
```

**View Installation Logs:**
```bash
ddev logs
```

**Retry Installation:**
```bash
# For specific version
ddev ssh
rm -rf /var/www/html/v13/*
exit
ddev install-v13
```

### Extension Not Appearing

**Verify Extension Key:**
```bash
ddev ssh
echo $EXTENSION_KEY  # Should match your ext_emconf.php
```

**Check Composer Repository:**
```bash
ddev ssh
cd /var/www/html/v13
composer config repositories
```

For complete troubleshooting guide, see `references/troubleshooting.md`.

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Credits

This skill is based on the excellent work by [Armin Vieweg](https://github.com/a-r-m-i-n) in [ddev-for-typo3-extensions](https://github.com/a-r-m-i-n/ddev-for-typo3-extensions).

### Additional Resources

- [DDEV Documentation](https://ddev.readthedocs.io/)
- [TYPO3 Extension Development](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ExtensionArchitecture/Index.html)
- [TYPO3 DDEV Setup Guide](https://docs.typo3.org/m/typo3/tutorial-getting-started/main/en-us/Installation/UsingDdev.html)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/netresearch/typo3-ddev-skill/issues)
- **Discussions**: [GitHub Discussions](https://github.com/netresearch/typo3-ddev-skill/discussions)
- **TYPO3 Slack**: #ddev channel

---

**Made with ❤️ for the TYPO3 Community by [Netresearch DTT GmbH](https://www.netresearch.de/)**
