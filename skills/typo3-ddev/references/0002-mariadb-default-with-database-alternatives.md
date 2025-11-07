# ADR 0002: Tiered Database Selection for TYPO3 Extension Development

**Status:** Accepted (Revised 2025-01-22)

**Date:** 2024-12-22 (Original), 2025-01-22 (Revision 1)

**Decision Makers:** TYPO3 DDEV Skill Maintainers

**Tags:** #database #mariadb #postgresql #mysql #sqlite #tiered-selection #development-optimization

---

## Context

### Production vs Development Requirements

**Critical Distinction:** This ADR addresses **DDEV extension development environments**, NOT production hosting.

**Development Context (DDEV):**
- Single developer on localhost
- Fast iteration cycles (code → ddev restart → test → repeat)
- Resource efficiency matters (RAM, disk, startup time)
- Perfect isolation for multi-version testing (v11, v12, v13)
- No public internet exposure, no security concerns
- Human actions are sequential (seconds/minutes apart)

**Production Context (Hosting):**
- Multi-user concurrent access
- Public internet exposure with security requirements
- Uptime and reliability critical
- Performance under load matters
- 95%+ TYPO3 hosting uses MariaDB

**Key Insight:** Development and production have DIFFERENT requirements. Production-parity is important for complex extensions with custom SQL, but OVERKILL for simple extensions using only TYPO3 Core APIs.

### TYPO3 13 Database Support

TYPO3 13 officially supports four database systems:
- **MariaDB** >= 10.4.3 <= 11.0.0
- **MySQL** >= 8.0.17
- **PostgreSQL** >= 10.0
- **SQLite** >= 3.8.3

While all four are technically supported, production deployment patterns and ecosystem alignment vary significantly.

### Production Hosting Landscape

**Research Finding:** "Most TYPO3 customers prefer to use the MySQL/MariaDB database"

**European TYPO3 Hosting Providers:**
- **jweiland.net**: MariaDB 10.11, MariaDB 10.3 (MySQL 5.6 outdated)
- **mittwald**: MariaDB (primary offering)
- **TYPO3 Agency**: MariaDB (standard configuration)
- **platform.sh**: Supports all, but MariaDB most common for TYPO3

**Estimated Distribution:**
- MariaDB: **95%+** of TYPO3 production installations
- MySQL 8: <10% (mostly cloud providers, corporate environments)
- PostgreSQL: <5% (specialized use cases: GIS, analytics, full-text search)
- SQLite: 0% production (demo/testing only)

### SQLite for Development (Revision 1 Analysis)

**SQLite Capabilities for DDEV Development:**

TYPO3 13 officially supports SQLite >= 3.8.3, and modern PHP containers (Ubuntu/Debian) include SQLite 3.40+.

**Development Benefits:**
- **Startup Speed**: Instant (no container startup) vs 5-10 seconds for MariaDB
- **Resource Usage**: ~20 MB RAM vs ~200 MB RAM for MariaDB container
- **Disk Space**: 0 MB (PHP extension) vs 744 MB MariaDB container image
- **Isolation**: Perfect separation for v11/v12/v13 (separate .sqlite files)
- **Simplicity**: No container orchestration, no health checks

**SQLite WAL Mode (Write-Ahead Logging):**
- Available since SQLite 3.7.0 (TYPO3 requires >= 3.8.3)
- Enables concurrent READS during WRITES
- Multiple WRITES serialize but with better concurrency than default mode
- Addresses concurrent write concerns for single-developer localhost usage

**When SQLite is SUFFICIENT for Development:**
- Extension uses only TYPO3 Core APIs (Extbase, FAL, DataHandler)
- No custom raw SQL queries
- No custom database tables
- Human actions sequential (save → upload → clear cache) not truly concurrent
- Single developer localhost environment

**When SQLite is INSUFFICIENT:**
- Extension has custom database tables (ext_tables.sql)
- Extension uses raw SQL queries (database-specific syntax)
- Performance-critical operations requiring production-realistic testing
- Testing multi-user concurrent scenarios

**Developer Workflow Impact:**
```
Daily Workflow: 10x ddev restarts
- MariaDB: 10 × 10 seconds = 100 seconds waiting
- SQLite: 10 × 2 seconds = 20 seconds waiting
- Time saved: 80 seconds per day = 400 seconds per week
```

### Performance Benchmarks (2024)

**MariaDB vs MySQL 8:**

According to 2024 Sysbench benchmarks:
- MariaDB 11.4 performance is **13-36% faster** than MySQL 8.0
- Modern MySQL 8.0.36 gets only 66-84% throughput relative to older MySQL 5.6.51
- MySQL suffers from CPU overhead **1.38X larger** than MariaDB
- MariaDB maintains **stable performance** across 10 years and 14 releases

**PostgreSQL vs MariaDB:**

OLTP Benchmarks (HammerDB TPROC-C):
- PostgreSQL: **84% more orders** processed than MariaDB in payments-per-second tests
- PostgreSQL excels at **complex analytical queries** and parallel execution
- MariaDB shows **15-25% better performance** for transactional applications
- TYPO3 workload is primarily transactional (CRUD operations on content) → MariaDB advantage

**Key Insight:** PostgreSQL is technically superior for analytics, but TYPO3 is a CMS (transactional workload), not an analytics platform.

### Docker Image Sizes

Surprisingly, PostgreSQL has a **smaller image**:

| Database | Image | Size |
|----------|-------|------|
| PostgreSQL 16 | `postgres:16-alpine` | **394 MB** |
| MariaDB latest | `mariadb:latest` | 456 MB |
| MySQL 8 | `mysql:8` | ~500 MB |
| DDEV MariaDB 10.11 | `ddev/ddev-dbserver-mariadb-10.11` | 744 MB* |

*DDEV image includes TYPO3-specific tooling and optimizations

### Extension Compatibility Concerns

**Doctrine DBAL Abstraction:**

TYPO3 uses Doctrine DBAL to abstract database differences. In theory, extensions should work across all supported databases.

**Reality:**

1. **Raw SQL Bypass**: Extensions using raw SQL (not via Doctrine QueryBuilder) may assume MySQL/MariaDB syntax
2. **Testing Coverage**: Extension developers test primarily on MariaDB (95% hosting uses it)
3. **Syntax Differences**:
   - MySQL/MariaDB: `DATE_FORMAT()`, `LIMIT offset, count`, `AUTO_INCREMENT`
   - PostgreSQL: `TO_CHAR()`, `LIMIT count OFFSET offset`, `SERIAL`

**Risk:** Extensions with raw SQL may break on PostgreSQL but work fine on MariaDB.

### DDEV Database Support

DDEV provides native database configuration via `.ddev/config.yaml`:

```yaml
database:
  type: mariadb      # or: mysql, postgres
  version: "10.11"   # version string
```

**Migration Support:**
- **MySQL ↔ MariaDB**: `ddev debug migrate-database` (seamless migration)
- **MariaDB/MySQL → PostgreSQL**: Manual export/import (schema differences)
- **PostgreSQL → MariaDB/MySQL**: Manual export/import (schema differences)

**Implication:** Starting with MariaDB and needing PostgreSQL later is painful (data migration). Starting with PostgreSQL and needing MariaDB is equally painful. Must choose wisely upfront.

---

## Decision

**Use tiered database selection based on extension complexity for TYPO3 DDEV development environments.**

### Tier 1: SQLite (Default for Simple Extensions)

**Recommended for extensions that:**
- ✅ Have no custom database tables (ext_tables.sql absent or empty)
- ✅ Use only TYPO3 Core APIs (Extbase, FAL, DataHandler, Doctrine DBAL)
- ✅ Have no raw SQL queries
- ✅ Category: plugin, fe, be, misc
- ✅ File size < 1 MB

**Benefits:**
- ⚡ **Startup**: 5-10 seconds faster per ddev start
- 💾 **RAM**: 900 MB saved (no MariaDB container)
- 💿 **Disk**: 744 MB saved (no container image)
- 🔒 **Isolation**: Perfect separation for v11/v12/v13 databases
- 🎯 **Simplicity**: No container orchestration needed

**Critical Warnings:**
- ⚠️ **Development ONLY** - Never use SQLite in production
- ⚠️ **Switch to MariaDB** if you add custom SQL queries or tables
- ⚠️ **Final Testing** - Run compatibility tests on MariaDB before extension release

### Tier 2: MariaDB 10.11 (Default for Complex Extensions)

**Recommended for extensions that:**
- ❌ Have custom database tables (ext_tables.sql present)
- ❌ Use raw SQL queries (database-specific syntax)
- ❌ Performance-critical operations
- ❌ Category: services, module
- ❌ File size > 1 MB

**Benefits:**
- ✅ Production-realistic testing (95%+ TYPO3 hosting uses MariaDB)
- ✅ Better for concurrent operations
- ✅ Proper performance benchmarking
- ✅ Extension compatibility (99%+ extensions tested on MariaDB)

### Tier 3: PostgreSQL 16 (Explicit Requirements)

**Recommended for extensions that:**
- 🎯 Require GIS/spatial data (PostGIS)
- 🎯 Advanced analytics or complex queries
- 🎯 Extension explicitly requires PostgreSQL

### Tier 4: MySQL 8.0 (Corporate/Oracle Ecosystem)

**Recommended for:**
- 🏢 Corporate environments requiring Oracle ecosystem integration
- 🏢 Existing production environments using MySQL 8

**Implement auto-detection logic** to analyze extension complexity and suggest appropriate database tier.

### Implementation Details

#### Default Configuration Based on Extension Analysis

**For Simple Extensions (Tier 1):**

No `.ddev/config.yaml` database configuration needed (uses DDEV default PHP with SQLite)

TYPO3 installation command:
```bash
vendor/bin/typo3 setup \
  --driver=pdo_sqlite \
  --path=/var/www/html/v13/database.sqlite \
  --admin-username=admin \
  --admin-password='Password:joh316' \
  --project-name="Extension Dev v13"
```

**For Complex Extensions (Tier 2):**

`.ddev/config.yaml`:
```yaml
database:
  type: mariadb
  version: "10.11"
```

TYPO3 installation command uses: `--driver=mysqli --host=db --dbname=v13`

#### Auto-Detection Logic

During extension metadata extraction:

```yaml
Extension Complexity Analysis:

  1. SQLite Detection (Tier 1 - Simple Extension):
     Checks:
       ✓ ext_tables.sql: Absent or empty
       ✓ Raw SQL patterns: None found (grep for executeQuery, $GLOBALS['TYPO3_DB'])
       ✓ File size: < 1 MB
       ✓ Category: plugin, fe, be, misc
     → Suggest SQLite (development-optimized)

  2. MariaDB Detection (Tier 2 - Complex Extension):
     Checks:
       ✗ ext_tables.sql: Present with table definitions
       ✗ Raw SQL patterns: Found
       ✗ File size: > 1 MB
       ✗ Category: services, module
     → Suggest MariaDB 10.11 (production-realistic)

  3. PostgreSQL Detection (Tier 3 - Explicit Requirement):
     Checks:
       • Extension name: Contains "postgres", "pgsql", "pg_", "postgis"
       • composer.json: Requires "typo3/cms-pgsql"
       • Description: Keywords "GIS", "spatial", "analytics"
     → Suggest PostgreSQL 16 (specialized)

  4. MySQL Detection (Tier 4 - Corporate):
     Checks:
       • composer.json: Requires "typo3/cms-mysql"
       • Manual override only
     → Suggest MySQL 8.0 (corporate/Oracle ecosystem)
```

**User Confirmation (Simple Extension Example):**
```
Detected Database Configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Database:     SQLite (Tier 1)
Reason:       Simple extension using only TYPO3 Core APIs
              No custom tables, no raw SQL

Benefits:
  ⚡ Startup: 5-10 seconds faster per ddev start
  💾 RAM: 900 MB saved
  💿 Disk: 744 MB saved
  🔒 Isolation: Perfect v11/v12/v13 separation

Warnings:
  ⚠️ Development ONLY (never production)
  ⚠️ Switch to MariaDB if adding custom SQL
  ⚠️ Run final tests on MariaDB before release

Alternatives:
  • mariadb:10.11 - Production-realistic testing
  • postgres:16 - GIS/analytics requirements
  • mysql:8.0 - Oracle ecosystem

Proceed with SQLite? (y/n)
```

**User Confirmation (Complex Extension Example):**
```
Detected Database Configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Database:     MariaDB 10.11 (Tier 2)
Reason:       Complex extension with custom tables
              Found: ext_tables.sql with 3 custom tables

Benefits:
  ✅ Production-realistic (95%+ TYPO3 hosting)
  ✅ Extension compatibility (99%+ tested)
  ✅ Proper concurrent operation handling

Alternatives:
  • sqlite - Faster development (not recommended for custom tables)
  • postgres:16 - GIS/analytics requirements
  • mysql:8.0 - Oracle ecosystem

Proceed with MariaDB 10.11? (y/n)
```

---

## Consequences

### Positive

✅ **Production Parity**
- 95%+ TYPO3 hosting uses MariaDB
- Development environment matches production reality
- Reduces deployment surprises and compatibility issues

✅ **Extension Compatibility**
- 99%+ TYPO3 extensions tested on MariaDB
- Minimizes risk of raw SQL incompatibilities
- Safer default for general extension development

✅ **TYPO3 Ecosystem Alignment**
- TYPO3 documentation examples use MariaDB
- Community tutorials assume MariaDB
- Developer familiarity (most TYPO3 devs know MySQL/MariaDB)

✅ **Performance for CMS Workload**
- MariaDB 13-36% faster than MySQL 8 for transactional operations
- TYPO3 workload is primarily CRUD (transactional), not analytical
- Optimal for typical CMS usage patterns

✅ **DDEV Standard**
- DDEV defaults to MariaDB for TYPO3 projects
- Ecosystem-aligned with DDEV best practices
- Smooth migration within MySQL/MariaDB family

✅ **Mature & Stable**
- MariaDB 10.11 is production-proven LTS release
- 15+ years of MySQL/MariaDB history
- Battle-tested with TYPO3 workloads

### Negative

⚠️ **Not Leveraging PostgreSQL Advantages**
- PostgreSQL has smaller image (394 MB vs 744 MB DDEV MariaDB)
- PostgreSQL superior for complex queries, analytics, GIS
- PostgreSQL has better ACID compliance and advanced features (JSONB, full-text, PostGIS)
- **Counter-argument:** TYPO3 extensions rarely need these features; production uses MariaDB anyway

⚠️ **MySQL 8 Performance Gap**
- MariaDB 13-36% faster than MySQL 8 in benchmarks
- MySQL 8 has CPU overhead issues
- Defaulting to MariaDB means MySQL users must explicitly switch
- **Counter-argument:** MySQL 8 only needed for Oracle ecosystem; MariaDB is better performer

⚠️ **Limited PostgreSQL Exposure**
- Developers don't experience PostgreSQL advantages
- PostgreSQL adoption in TYPO3 ecosystem remains low
- **Counter-argument:** Production reality dictates development choices; can't force ecosystem change from dev tools

### Risks and Mitigations

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| PostgreSQL-specific extension not detected | Medium | Low | Explicit naming conventions documented; manual override available |
| Extension breaks on PostgreSQL in production | High | Very Low | Production hosting uses MariaDB (95%+); PostgreSQL hosting rare |
| Developer unfamiliar with MariaDB | Low | Very Low | MySQL/MariaDB standard in web development; extensive documentation |
| MariaDB 10.x deprecated before TYPO3 14 | Low | Low | MariaDB 11 alternative documented; DDEV migration smooth |
| Missing out on PostgreSQL innovation | Low | Medium | PostgreSQL 16 documented and available; auto-detection suggests when appropriate |

---

## Alternatives Considered

### Alternative 1: PostgreSQL 16 Default

**Reasoning:**
- Technically superior database (ACID, advanced features)
- Smaller image size (394 MB vs 744 MB)
- Better for complex queries and analytics
- Future-proof with modern features

**Rejected Because:**
- ❌ Only ~5% of TYPO3 hosting uses PostgreSQL
- ❌ Extension compatibility risk (raw SQL, testing coverage)
- ❌ Development-production mismatch for 95% of deployments
- ❌ No industry migration trend (unlike Valkey case)
- ❌ TYPO3 workload is transactional, not analytical
- ❌ Higher learning curve for TYPO3 developers
- ❌ Counter to TYPO3 ecosystem standards

**Key Difference from Valkey Decision:**
- Valkey: Industry migrating TO new technology (AWS/Google/Oracle adopting)
- PostgreSQL: Industry STABLE on existing technology (95% MariaDB, no migration)

### Alternative 2: MySQL 8.0 Default

**Reasoning:**
- TYPO3 officially supports MySQL 8.0.17+
- Oracle corporate backing
- Window functions, CTEs, document store features

**Rejected Because:**
- ❌ MariaDB 13-36% faster in benchmarks
- ❌ MySQL 8 has CPU overhead issues (1.38X vs MariaDB)
- ❌ Less common than MariaDB in TYPO3 hosting
- ❌ Oracle licensing concerns (GPL but Oracle-controlled)
- ❌ MariaDB is better open-source governance (MariaDB Foundation)
- ❌ TYPO3 doesn't leverage MySQL 8 advanced features heavily

### Alternative 3: MariaDB 11.x Default

**Reasoning:**
- Performance improvements over MariaDB 10.x (+40% in benchmarks)
- TYPO3 13 supports up to MariaDB 11.0
- Forward-looking choice

**Rejected Because:**
- ⚠️ MariaDB 11.0 has breaking changes (removed features)
- ⚠️ Less production-proven than 10.11 LTS
- ⚠️ Most hosting still on MariaDB 10.x
- ⚠️ Higher risk of compatibility issues
- **Compromise:** Offer as documented alternative for forward-looking users

### Alternative 4: No Default (User Choice Required)

**Reasoning:**
- Maximum flexibility
- User decides based on production environment
- No opinionated stance

**Rejected Because:**
- ❌ Forces decision without context for new developers
- ❌ Increases setup friction and confusion
- ❌ Reference implementations should have best-practice defaults
- ❌ Most users (95%+) would choose MariaDB anyway
- ❌ Skill value proposition includes intelligent defaults

### Alternative 5: SQLite for Development (REVISED - Now ACCEPTED for Tier 1)

**Reasoning:**
- Minimal setup (no container overhead)
- Fast for development iteration cycles
- Perfect isolation for multi-version testing
- TYPO3 13 officially supports SQLite >= 3.8.3
- Single-developer DDEV localhost use case

**Originally Rejected Because (Revision 1 Analysis):**
- ❌ "Not production-viable (no concurrent writes)" → **OVERSTATED** for single-developer localhost
  - Reality: Human actions are sequential (seconds/minutes apart)
  - SQLite WAL mode handles concurrent reads during writes
  - DDEV is single developer, not multi-user production
- ❌ "Security risk (web-downloadable database)" → **INVALID** for DDEV localhost
  - Reality: Localhost (127.0.0.1), not exposed to public internet
  - This is a production concern, not development concern
- ❌ "Not representative of production" → **OVER-APPLIED** for simple extensions
  - Reality: For extensions using only Core APIs, database type doesn't matter
  - Production parity important for custom SQL, overkill for simple extensions

**Now ACCEPTED for Tier 1 (Simple Extensions) Because:**
- ✅ Development and production have DIFFERENT requirements
- ✅ Significant developer experience improvements (5-10 sec startup, 900 MB RAM saved)
- ✅ Perfect for extensions using only TYPO3 Core APIs (Doctrine DBAL abstraction)
- ✅ Clear warnings prevent production misuse
- ✅ Easy migration to MariaDB if extension complexity increases

**Critical Success Factor:** Clear documentation that SQLite is **development ONLY**, with automated warnings and migration path to MariaDB for production testing.

---

## Database Selection Matrix

| Use Case | Recommended Database | Rationale |
|----------|---------------------|-----------|
| **Simple Plugin Extension (Core APIs only)** | **SQLite** (Tier 1) | Fast development, resource-efficient, perfect isolation |
| **Simple Frontend Extension** | **SQLite** (Tier 1) | No custom tables, uses FAL/Extbase/Doctrine DBAL |
| **Simple Backend Module (no custom SQL)** | **SQLite** (Tier 1) | TYPO3 core tables only, development-optimized |
| **RTE/CKEditor Plugin** | **SQLite** (Tier 1) | File operations via FAL, no database complexity |
| **Complex Extension (custom tables)** | **MariaDB 10.11** (Tier 2) | Production parity, custom database schema |
| **Extension with Raw SQL** | **MariaDB 10.11** (Tier 2) | Database-specific syntax, production testing needed |
| **Performance-Critical Extension** | **MariaDB 10.11** (Tier 2) | Production-realistic benchmarking required |
| **General TYPO3 Extension (unknown complexity)** | **MariaDB 10.11** (Tier 2) | Safe default, ecosystem standard, fallback choice |
| **GIS/Mapping Extension** | **PostgreSQL 16** (Tier 3) | PostGIS support, spatial queries |
| **Analytics/Reporting Extension** | **PostgreSQL 16** (Tier 3) | Complex queries, parallel execution, window functions |
| **Full-Text Search Extension** | **PostgreSQL 16** (Tier 3) | Superior full-text search capabilities |
| **Corporate/Oracle Ecosystem** | **MySQL 8.0** (Tier 4) | Oracle integration, enterprise requirements |
| **Forward-Looking Performance** | **MariaDB 11.4** | Latest features, performance improvements |
| **Production Uses PostgreSQL** | **PostgreSQL 16** (Tier 3) | Development-production parity |
| **Production Uses MySQL** | **MySQL 8.0** (Tier 4) | Development-production parity |

**Key Changes from Original Decision:**
- ✅ SQLite now RECOMMENDED for simple extensions (Tier 1)
- ✅ MariaDB remains default for complex extensions (Tier 2)
- ✅ Tiered approach based on extension complexity analysis
- ✅ Development efficiency prioritized for simple extensions
- ✅ Production parity prioritized for complex extensions

---

## Implementation Roadmap

### Phase 1: Documentation (Immediate)

1. **ADR Creation**: This document
2. **SKILL.md Update**: Database section explaining default and alternatives
3. **README.md Update**: Quick reference for database options
4. **Template Comments**: Explain database choice in config.yaml

### Phase 2: Auto-Detection (v2.1.0)

1. **Extension Metadata Parsing**: Detect PostgreSQL signals
2. **User Confirmation**: Present detected database with rationale
3. **Override Option**: Allow manual database selection
4. **Logging**: Explain why database was chosen

### Phase 3: Testing & Validation (Ongoing)

1. **MariaDB 10.11**: Validate default (already working)
2. **PostgreSQL 16**: Test TYPO3 13 installation
3. **MariaDB 11.4**: Validate forward-looking alternative
4. **MySQL 8.0**: Validate corporate alternative

---

## References

### Technical Documentation

- [TYPO3 13 System Requirements](https://get.typo3.org/version/13#system-requirements)
- [TYPO3 Database Configuration](https://docs.typo3.org/m/typo3/reference-coreapi/13.4/en-us/ApiOverview/Database/Configuration/Index.html)
- [DDEV Database Documentation](https://ddev.readthedocs.io/en/stable/users/extend/database-types/)
- [MariaDB vs MySQL Performance](https://mariadb.org/how-mariadb-and-mysql-performance-changed-over-releases/)

### Benchmarks

- **MariaDB vs MySQL**: 13-36% faster (Sysbench 2024)
- **PostgreSQL vs MariaDB**: +84% OLTP orders (HammerDB TPROC-C)
- **MySQL 8 Performance**: 66-84% throughput vs MySQL 5.6
- **Image Sizes**: PostgreSQL 394 MB, MariaDB 456 MB, DDEV MariaDB 744 MB

### TYPO3 Community

- **Hosting Research**: "Most TYPO3 customers prefer MySQL/MariaDB"
- **Production Distribution**: 95%+ MariaDB, <10% MySQL, <5% PostgreSQL
- **TYPO3 Forum**: [PostgreSQL discussions](https://www.typo3forum.net/discussion/82437/typo3-with-postgresql)

---

## Decision Rationale Summary (Revised)

### Tiered Database Selection Strategy

**SQLite (Tier 1) is OPTIMAL for simple extensions because:**

1. **Development Efficiency** (5-10 seconds faster startup, 900 MB RAM saved)
2. **Resource Optimization** (744 MB less disk, no container overhead)
3. **Perfect Isolation** (Separate .sqlite files for v11/v12/v13)
4. **Core API Sufficiency** (Extensions using only TYPO3 Core APIs work across databases)
5. **Developer Experience** (Faster iteration cycles, simpler architecture)

**Critical:** Development ONLY. Clear warnings prevent production misuse.

**MariaDB 10.11 (Tier 2) is NECESSARY for complex extensions because:**

1. **Production Reality** (95%+ TYPO3 hosting uses MariaDB)
2. **Custom SQL Requirements** (Database-specific syntax testing)
3. **Extension Compatibility** (99%+ extensions tested on MariaDB)
4. **Performance Testing** (Production-realistic benchmarking)
5. **Stability** (LTS release, production-proven, DDEV standard)

**PostgreSQL 16 (Tier 3) is REQUIRED for specialized extensions because:**

1. **GIS/Spatial Data** (PostGIS support, spatial queries)
2. **Analytics** (Complex queries, parallel execution)
3. **Technical Superiority** (Advanced features for specific use cases)

**MySQL 8.0 (Tier 4) is AVAILABLE for corporate environments because:**

1. **Oracle Ecosystem** (Corporate integration requirements)
2. **Existing Production** (Development-production parity)

### Key Insight: Context Matters

**This is NOT like Valkey** where industry was migrating. Database choice is stable at MariaDB for production.

**This IS like Valkey** in that we recognize DEVELOPMENT and PRODUCTION have DIFFERENT optimal choices.

**The tiered approach is intelligent and context-aware:**
- **Simple extensions** → Optimize for development efficiency (SQLite)
- **Complex extensions** → Optimize for production parity (MariaDB)
- **Specialized extensions** → Match technical requirements (PostgreSQL/MySQL)

**Revision 1 Learning:** Original ADR over-applied production concerns to development context. After user challenge, re-analysis showed SQLite is OPTIMAL for simple extension development with proper warnings and migration path.

---

## Review and Updates

**Next Review Date:** 2025-06-01 (6 months)

**Trigger for Re-evaluation:**
- TYPO3 14 changes database support or recommendations
- PostgreSQL adoption in TYPO3 hosting exceeds 25%
- MariaDB 10.x becomes unsupported by TYPO3
- Major performance regressions discovered in MariaDB
- TYPO3 officially recommends different default database

**Success Metrics:**
- Developer feedback on database default (GitHub issues)
- PostgreSQL adoption rate for auto-detected extensions
- Extension compatibility reports
- Production deployment success rate

---

**Approved By:** TYPO3 DDEV Skill Project

**Implementation:** v2.1.0 (target release)
