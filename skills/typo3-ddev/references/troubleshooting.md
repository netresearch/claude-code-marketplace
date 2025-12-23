## Error Handling

### Common Issues and Solutions

**1. Prerequisites Not Met**
```
❌ Prerequisites validation failed.

One or more requirements are not met:
  - Docker daemon not running
  - Docker CLI outdated (need >= 20.10)
  - Docker Compose outdated (need >= 2.0)
  - DDEV not installed

See "Prerequisites Validation" section above for detailed:
  - Platform-specific installation instructions
  - Version requirement details
  - Validation script you can run

Run the validation script to identify which prerequisite is failing.
```

**2. Docker Daemon Not Running (Most Common)**
```
❌ Docker daemon is not running.

Quick fix for your platform:

🐧 Linux/WSL2:
   sudo service docker start

🍎 macOS:
   Open Docker Desktop application

🪟 Windows:
   Open Docker Desktop application

For detailed instructions, see Prerequisites Validation section.
After starting Docker, run: docker info
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

**5a. Admin Password Security Requirements**
```
❌ Password does not match the requirements.
   Password must have at least 8 characters,
   contain at least one uppercase letter,
   one digit, and one special character.

The TYPO3_SETUP_ADMIN_PASSWORD environment variable must meet TYPO3's
password policy requirements introduced in TYPO3 12.4:

Required:
  - Minimum 8 characters
  - At least one uppercase letter (A-Z)
  - At least one digit (0-9)
  - At least one special character (!@#$%^&*...)

Examples:
  ✅ Joh316!  (default, meets all requirements)
  ✅ Password123!
  ✅ MySecure#Pass1
  ❌ password         (no uppercase, no digit, no special char)
  ❌ Password123      (no special char)
  ❌ password!        (no uppercase, no digit)

Fix in docker-compose.web.yaml:
  environment:
    - TYPO3_SETUP_ADMIN_PASSWORD=Password123!
```

**5b. Database Already Exists**
```
❌ Database "v12" or "v13" already exists

This occurs when reinstalling without cleanup. Solutions:

1. Let the install script handle it (recommended):
   The install-v12 and install-v13 commands automatically
   DROP and recreate the database before setup.

2. Manual cleanup if needed:
   ddev mysql -uroot -proot -e "DROP DATABASE v12;"
   ddev mysql -uroot -proot -e "DROP DATABASE v13;"
```

**6. Documentation Site Issues**
```
❌ docs.{sitename}.ddev.site shows directory listing or 404

Causes and solutions:
  - Apache not finding Index.html (capital I)
    Add to VirtualHost: DirectoryIndex Index.html index.html

  - Wrong output directory
    Use: Documentation-GENERATED-temp (TYPO3 standard)
    NOT: docs/, Documentation-rendered/, etc.

  - Docker volume not syncing
    Don't use Docker volumes for docs
    Use project bind mount instead

  - Root-owned files from Docker
    Clean with: sudo rm -rf Documentation-GENERATED-temp/*
```

**7. Root-Owned Docker Files**
```
❌ Permission denied when deleting files

Docker creates files as root. Solutions:
  1. Use sudo: sudo rm -rf Documentation-GENERATED-temp/
  2. Fix ownership: sudo chown -R $(id -u):$(id -g) Documentation-GENERATED-temp/
  3. Prevent in future: Run Docker with --user "$(id -u):$(id -g)"
```

**8. PCOV Installation Fails**
```
❌ pecl: command not found
   OR
❌ pecl install pcov fails

DDEV containers don't include pecl. Use apt-get instead:

# In .ddev/web-build/Dockerfile
RUN apt-get update && apt-get install -y php${PHP_VERSION}-pcov

NOT:
RUN pecl install pcov && docker-php-ext-enable pcov  # ❌ Won't work
```

**9. PHP Version Outdated**
```
❌ PHP 8.5.0RC3 instead of PHP 8.5.1 (or similar)

DDEV ships with specific PHP versions. When a new patch release is
available but DDEV hasn't updated yet, use Dockerfile.apt:

# Create .ddev/web-build/Dockerfile.apt
RUN apt-get update
RUN apt-get install --only-upgrade -y php${PHP_VERSION}-*

Then run: ddev restart

Note: This upgrades all PHP packages to latest available in DDEV's
apt repository. The new version takes effect after restart.
```

**10. PHP Configuration Path Confusion**
```
❌ Custom PHP settings not applied

Wrong location:
  /usr/local/etc/php/conf.d/custom.ini  ❌ (DDEV-managed path)

Correct location:
  .ddev/php/custom.ini                   ✅

Example .ddev/php/custom.ini:
  memory_limit = 512M
  max_execution_time = 300
  upload_max_filesize = 50M

After creating/modifying, run: ddev restart
```

**11. Extension Naming Confusion**
```
❌ Inconsistent extension naming (underscores vs hyphens)

TYPO3 uses different naming conventions in different contexts:

Extension key (internal, underscores):
  nr_llm                          ← ext_emconf.php, ext_tables.php

Composer package name (hyphens):
  netresearch/nr-llm              ← composer.json "name" field

Display name (human readable):
  NR LLM                          ← Title case, spaces

For landing pages and documentation, use the composer package
name format (hyphens) as the authoritative display name:
  ✅ nr-llm
  ✅ t3x-nr-llm
  ❌ nr_llm (only for internal TYPO3 references)
```

**12. Landing Page Missing Branding**
```
❌ Landing page has generic styling instead of Netresearch branding

Symptoms:
  - Generic blue/grey colors instead of turquoise (#2F99A4)
  - Missing Netresearch logo
  - System fonts instead of Raleway/Open Sans
  - Extension name shows underscores instead of hyphens

Causes:
  1. Branding skill not consulted before generating page
  2. Logo SVG not embedded (relying on external URL)
  3. Extension name taken from ext_emconf instead of composer.json

Solutions:
  1. For Netresearch projects, ALWAYS check composer.json vendor:
     grep '"netresearch/' composer.json

  2. Apply Netresearch branding if detected:
     - Primary color: #2F99A4 (turquoise)
     - Accent color: #FF4D00 (orange)
     - Text color: #585961 (anthracite)
     - Headlines: Raleway font
     - Body: Open Sans font

  3. Embed logo SVG directly (don't use external URLs):
     <svg viewBox="0 0 100 100" width="40" height="40">
       <rect x="5" y="5" width="90" height="90" rx="8"
             fill="none" stroke="#2999A4" stroke-width="6"/>
       <text x="50" y="72" text-anchor="middle"
             font-family="Arial" font-size="60" font-weight="bold"
             fill="#595A62">n</text>
     </svg>

  4. Get extension name from composer.json "name" field:
     jq -r '.name' composer.json  # Returns: netresearch/nr-llm

See: references/index-page-generation.md for complete branding guide
```

