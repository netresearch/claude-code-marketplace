# ADR 0003: PHP Version Management in DDEV

**Status:** Accepted

**Date:** 2025-12-31

**Decision Makers:** TYPO3 DDEV Skill Maintainers

**Tags:** #php #ddev #version-management #development-environment

---

## Context

### The PHP Version Lag Problem

DDEV base images are periodically updated but often lag behind the latest PHP patch releases. This creates situations where:

- DDEV ships PHP 8.5.0RC3 (release candidate)
- PHP 8.5.1 (stable) is already released
- Developers need the latest stable version for:
  - Bug fixes affecting their code
  - Security patches
  - CI/CD parity (GitHub Actions uses latest stable)
  - Testing with production-equivalent versions

### Example Scenario (December 2025)

- **PHP 8.5.1 Released:** December 18, 2025
- **DDEV Base Image:** Still ships PHP 8.5.0RC3
- **Impact:** Tests passing locally may fail in CI due to version differences

### TYPO3 Constraints

TYPO3 v14 requires PHP 8.5+. Extension developers need:

- Latest PHP 8.5.x patch version
- Consistent version across dev/CI/production
- Quick upgrade path when new patches release

---

## Decision

**Use `apt-get dist-upgrade` in DDEV web container Dockerfile to upgrade PHP to the latest available patch version.**

### Implementation

Create or update `.ddev/web-build/Dockerfile`:

```dockerfile
# .ddev/web-build/Dockerfile

# Upgrade PHP to latest patch version
# This runs after DDEV's base image is built, getting newer packages
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    rm -rf /var/lib/apt/lists/*
```

### Activation

After creating/modifying the Dockerfile:

```bash
ddev restart
```

Verify the upgrade:

```bash
ddev exec php -v
# Should show: PHP 8.5.1 (cli) ...
```

---

## Consequences

### Positive

**Immediate Version Access**
- Get new PHP patches within hours of release
- No waiting for DDEV image rebuilds
- Matches CI/CD environments using latest stable

**Development-Production Parity**
- Production servers typically run latest patch versions
- Reduces "works on my machine" issues
- More accurate local testing

**Security**
- Security patches applied immediately
- No vulnerable PHP versions in development
- Follows security best practices

**Simplicity**
- Single line in Dockerfile
- No manual package pinning required
- Automatic discovery of available versions

### Negative

**Build Time Increase**
- `ddev restart` takes slightly longer (~10-30 seconds)
- Package download on each container rebuild

**Mitigation:** Only significant on initial rebuild; subsequent restarts use Docker layer cache if Dockerfile unchanged.

**Potential Instability**
- Very new patches could introduce regressions
- No testing period before adoption

**Mitigation:**
- PHP patch releases are typically conservative
- Easy rollback by removing the Dockerfile addition
- Pin specific version if issues arise (see alternatives)

**Version Drift Between Developers**
- Different developers may get different patch versions
- Depends on when they last rebuilt containers

**Mitigation:**
- Document expected version in README
- Use CI as source of truth
- Pin specific version for strict reproducibility

---

## Alternatives Considered

### Alternative 1: Pin Specific PHP Version

```dockerfile
# Pin exact version
RUN apt-get update && \
    apt-get install -y php8.5=8.5.1-1+deb.sury.org~bookworm+1 && \
    rm -rf /var/lib/apt/lists/*
```

**Pros:**
- Exact reproducibility
- All developers on same version

**Cons:**
- Manual updates required for each patch
- Version string varies by repository
- More maintenance burden

**When to Use:** When strict version control is required (e.g., debugging version-specific issues).

### Alternative 2: Wait for DDEV Updates

Do nothing; wait for DDEV to update their base image.

**Pros:**
- Zero configuration
- Tested by DDEV team

**Cons:**
- Lag of days to weeks behind PHP releases
- No control over timing
- May miss critical security patches

**Rejected:** Unacceptable delay for security-conscious development.

### Alternative 3: Custom PHP Build

Build PHP from source with exact version.

**Pros:**
- Complete control
- Can include custom extensions

**Cons:**
- Significant complexity
- Long build times
- Maintenance nightmare

**Rejected:** Overkill for patch version management.

---

## Additional Configurations

### Combining with Other Customizations

The `dist-upgrade` approach works alongside other Dockerfile customizations:

```dockerfile
# .ddev/web-build/Dockerfile

# 1. Upgrade all packages including PHP
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# 2. Install additional PHP extensions (if needed)
# RUN apt-get update && \
#     apt-get install -y php8.5-bcmath && \
#     rm -rf /var/lib/apt/lists/*

# 3. Custom PHP configuration
# COPY php-custom.ini /etc/php/8.5/cli/conf.d/99-custom.ini
```

### Version Verification Script

Add to project for CI/local consistency checking:

```bash
#!/bin/bash
# scripts/check-php-version.sh

REQUIRED_VERSION="8.5"
CURRENT_VERSION=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')

if [[ "$CURRENT_VERSION" != "$REQUIRED_VERSION" ]]; then
    echo "ERROR: PHP $REQUIRED_VERSION required, found $CURRENT_VERSION"
    exit 1
fi

echo "PHP version: $(php -v | head -n1)"
```

### composer.json Platform Constraint

Ensure Composer respects the PHP version:

```json
{
    "config": {
        "platform": {
            "php": "8.5.1"
        }
    }
}
```

---

## Troubleshooting

### Package Not Found

If `dist-upgrade` doesn't find the new PHP version:

```bash
# Check available versions
ddev exec apt-cache policy php8.5

# Force repository refresh
ddev exec apt-get update
ddev restart
```

### Rollback to Previous Version

Remove or comment out the Dockerfile addition:

```dockerfile
# Temporarily disabled
# RUN apt-get update && apt-get dist-upgrade -y && rm -rf /var/lib/apt/lists/*
```

Then restart:

```bash
ddev restart
```

### Extension Compatibility

If a PHP extension breaks after upgrade:

```bash
# Check extension status
ddev exec php -m | grep <extension>

# Reinstall extension
ddev exec apt-get install --reinstall php8.5-<extension>
```

---

## Review and Updates

**Next Review Date:** When PHP 8.6 becomes TYPO3 v15 requirement

**Trigger for Re-evaluation:**
- DDEV changes their PHP version management approach
- PHP adopts different release cadence
- Debian/Ubuntu PHP packages change structure

---

**Approved By:** TYPO3 DDEV Skill Project

**Implementation:** Immediate (add to skill templates)
