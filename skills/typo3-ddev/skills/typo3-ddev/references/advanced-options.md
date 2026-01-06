## Advanced Options

### Custom PHP Version

If extension requires different PHP version:
```yaml
# In .ddev/config.yaml
php_version: "8.1"  # or "8.3", "8.4", "8.5"
```

### Upgrade PHP Packages

To get the latest PHP patch version (e.g., PHP 8.5.1 when DDEV ships 8.5.0):

```dockerfile
# .ddev/web-build/Dockerfile
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    rm -rf /var/lib/apt/lists/*
```

This is useful when a new PHP patch release fixes bugs but DDEV hasn't updated yet.

**Example: PHP 8.5.1 with PCOV for code coverage:**

```dockerfile
# .ddev/web-build/Dockerfile

# Install PCOV for fast code coverage using apt-get (pecl not available in DDEV)
RUN apt-get update && apt-get install -y php${PHP_VERSION}-pcov && rm -rf /var/lib/apt/lists/*

# Upgrade PHP to latest patch version (get fixes before DDEV updates)
# Use dist-upgrade to handle dependency changes between versions
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    rm -rf /var/lib/apt/lists/*
```

**Note**: DDEV containers don't include `pecl`. Use `apt-get` for PHP extensions instead.

### Custom PHP Configuration

Place custom PHP settings in `.ddev/php/custom.ini`:

```ini
# .ddev/php/custom.ini
memory_limit = 512M
max_execution_time = 300
upload_max_filesize = 50M
post_max_size = 50M

# PCOV for code coverage
pcov.enabled = 1
pcov.directory = /var/www/extension
```

**Important:** Do NOT place files directly in `/usr/local/etc/php/conf.d/` - DDEV manages that path internally. Use `.ddev/php/` instead.

### Installing PHP Extensions

Use `apt-get` in `.ddev/web-build/Dockerfile` (not pecl):

```dockerfile
# .ddev/web-build/Dockerfile
RUN apt-get update && apt-get install -y php${PHP_VERSION}-pcov && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y php${PHP_VERSION}-redis && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y php${PHP_VERSION}-imagick && rm -rf /var/lib/apt/lists/*
```

**Why apt-get instead of pecl?**
- DDEV containers don't include pecl
- apt packages are pre-compiled and faster to install
- Better compatibility with DDEV's PHP setup

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

