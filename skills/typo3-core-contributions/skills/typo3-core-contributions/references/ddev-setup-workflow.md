# TYPO3 Core Development - Complete DDEV Setup Workflow

Production-tested workflow for setting up a complete TYPO3 Core development environment with DDEV.

## Overview

This workflow creates a fully functional TYPO3 Core development environment with:
- TYPO3 Core v14 (main branch)
- PHP 8.4 on Apache with FPM
- MariaDB 10.6
- Test data and styleguide extensions
- Git configured for Gerrit submissions
- Ready for Core development and testing

## Prerequisites

**Required**:
- Git installed and configured
- DDEV installed (https://ddev.readthedocs.io/)
- SSH keys configured for GitHub and Gerrit

**Verify DDEV**:
```bash
ddev version
# Should show DDEV version >= 1.21
```

## Complete Setup Workflow

### Step 1: Create Project Directory

```bash
# Option A: Using 'take' (zsh/oh-my-zsh)
take t3coredev-14-php8-4

# Option B: Standard bash
mkdir -p t3coredev-14-php8-4 && cd t3coredev-14-php8-4
```

**Note**: Use descriptive directory names indicating TYPO3 version and PHP version.

### Step 2: Clone TYPO3 Core Repository

```bash
# Clone from GitHub (faster than Gerrit for initial clone)
git clone git@github.com:typo3/typo3 .

# Note: The dot (.) clones into current directory
```

### Step 3: Configure Git for TYPO3 Contributions

```bash
# Set your identity
git config user.name "YOUR NAME"
git config user.email "YOUR@EMAIL"

# Enable automatic rebase (required for TYPO3)
git config branch.autosetuprebase remote
```

### Step 4: Install Git Hooks

```bash
# Copy commit-msg hook (adds Change-Id)
cp Build/git-hooks/commit-msg .git/hooks/commit-msg

# Alternative: Use composer command
# composer gerrit:setup
```

### Step 5: Configure Gerrit Remote

```bash
# Set Gerrit as push destination
git config remote.origin.pushurl ssh://YOURT3OUSERNAME@review.typo3.org:29418/Packages/TYPO3.CMS.git

# Configure push refspec for Gerrit review
git config remote.origin.push +refs/heads/main:refs/for/main
```

**Important**: Replace `YOURT3OUSERNAME` with your actual Gerrit username!

### Step 6: Configure DDEV Project

```bash
# Set project type to TYPO3
ddev config --project-type typo3 -y

# Configure timezone (adjust to your location)
ddev config --timezone "Europe/Vienna"

# Set PHP version for v14 development
ddev config --php-version=8.4

# Use Apache with FPM (recommended for Core dev)
ddev config --webserver-type=apache-fpm

# Set MariaDB version
ddev config --database=mariadb:10.6
```

**PHP Version Notes**:
- TYPO3 v14: PHP 8.2, 8.3, 8.4
- TYPO3 v13: PHP 8.1, 8.2, 8.3
- Check `composer.json` for exact requirements

### Step 7: Configure DDEV Environment Variables

```bash
# Set TYPO3 context to Development/Ddev
ddev config --web-environment-add="TYPO3_CONTEXT=Development/Ddev"

# Set Composer root version for dev branch
ddev config --web-environment-add="COMPOSER_ROOT_VERSION=14.0.x-dev"
```

**Context Meanings**:
- `Development/Ddev`: Enables debugging, disables caching
- `Production`: Live site configuration
- `Testing`: For automated test environments

### Step 8: Start DDEV

```bash
ddev start
```

**What happens**:
1. Creates Docker containers (web, db, phpmyadmin)
2. Configures networking
3. Sets up SSL certificates
4. Mounts project directory

**Expected output**:
```
Starting t3coredev-14-php8-4...
Successfully started t3coredev-14-php8-4
Project can be reached at https://t3coredev-14-php8-4.ddev.site
```

### Step 9: Install Dependencies

```bash
# Use TYPO3's runTests.sh script (preferred for Core dev)
./Build/Scripts/runTests.sh -s composerInstall

# Alternative: Direct composer command
# ddev composer install
```

**Why runTests.sh?**
- Ensures correct Composer flags
- Consistent with CI environment
- Handles Core-specific requirements

### Step 10: Prepare TYPO3 Installation

```bash
# Create installation trigger file
ddev exec 'touch /var/www/html/FIRST_INSTALL'

# Enable Install Tool
ddev exec 'touch /var/www/html/typo3conf/ENABLE_INSTALL_TOOL'
ddev exec 'echo "KEEP_FILE" > /var/www/html/typo3conf/ENABLE_INSTALL_TOOL'
```

**File purposes**:
- `FIRST_INSTALL`: Triggers installation wizard
- `ENABLE_INSTALL_TOOL`: Enables Install Tool access (with KEEP_FILE prevents auto-deletion)

### Step 11: Run TYPO3 Setup

```bash
ddev typo3 setup \
    --driver=mysqli \
    --host=db \
    --port=3306 \
    --dbname=db \
    --username=db \
    --password=db \
    --admin-username=backenduser \
    --admin-user-password='YOUR_SECURE_PASSWORD' \
    --admin-email='YOUR@EMAIL' \
    --project-name='TYPO3 Core Dev v14 PHP 8.4' \
    --no-interaction \
    --server-type=apache \
    --force
```

**Important**:
- Replace `YOUR_SECURE_PASSWORD` with your preferred admin password
- Replace `YOUR@EMAIL` with your email
- Database credentials (db/db/db) are DDEV defaults

**What this creates**:
- Database tables and schema
- Backend admin user account
- Basic TYPO3 configuration
- AdditionalConfiguration.php

### Step 12: Activate Core Extensions

```bash
# Set up extensions first
ddev typo3 extension:setup

# Activate indexed_search (relevant for testing search functionality)
ddev typo3 extension:activate indexed_search

# Activate styleguide (provides test data and UI components)
ddev typo3 extension:activate styleguide

# Activate scheduler (for scheduled tasks)
ddev typo3 extension:activate scheduler
```

**Extension purposes**:
- `indexed_search`: Full-text search (relevant to bug #105737!)
- `styleguide`: Test data generator, UI component showcase
- `scheduler`: Cron-like task scheduling

### Step 13: Configure Backend User Groups

```bash
ddev typo3 setup:begroups:default --groups=Both
```

**Creates**:
- Editor group (content management)
- Advanced Editor group (extended permissions)
- Assigns both groups to admin user

### Step 14: Generate Test Data

```bash
# Generate TCA (Table Configuration Array) examples
ddev typo3 styleguide:generate --create -- tca

# Generate frontend system template
ddev typo3 styleguide:generate --create -- frontend-systemplate
```

**Test data includes**:
- All TCA field types with examples
- Content elements with various configurations
- Pages with different properties
- Frontend templates and TypoScript

### Step 15: Launch TYPO3 Backend

```bash
ddev launch /typo3
```

Opens TYPO3 backend in your default browser.

**Login credentials**:
- Username: `backenduser`
- Password: Whatever you set in Step 11

## Post-Setup Verification

### Verify Installation

**Check TYPO3 is running**:
```bash
ddev launch
```

**Access Install Tool**:
```bash
ddev launch /typo3/install.php
```

**View site info**:
```bash
ddev describe
```

### Verify Git Configuration

```bash
# Check user config
git config user.name
git config user.email

# Check Gerrit config
git config remote.origin.pushurl
git config remote.origin.push

# Verify hooks
ls -la .git/hooks/commit-msg
```

### Verify DDEV Configuration

```bash
# View DDEV config
cat .ddev/config.yaml

# Should show:
# - project_type: typo3
# - php_version: "8.4"
# - webserver_type: apache-fpm
# - database: mariadb:10.6
# - web_environment:
#   - TYPO3_CONTEXT=Development/Ddev
#   - COMPOSER_ROOT_VERSION=14.0.x-dev
```

### Test Core Functionality

**Access frontend**:
```bash
ddev launch
```

**Run tests**:
```bash
# Unit tests
./Build/Scripts/runTests.sh -s unit

# Functional tests
./Build/Scripts/runTests.sh -s functional

# Check available test suites
./Build/Scripts/runTests.sh -h
```

## Development Workflow

### Creating a Feature Branch

```bash
# Ensure main is up-to-date
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/105737-fix-indexed-search-crash
```

### Making Changes

```bash
# Make code changes
vim typo3/sysext/indexed_search/Classes/Indexer.php

# Stage changes
git add .

# Commit with proper message
git commit
# (Use commit message template)
```

### Testing Changes

```bash
# Run relevant tests
./Build/Scripts/runTests.sh -s unit -- \
    typo3/sysext/indexed_search/Tests/Unit/

# Check code style
./Build/Scripts/runTests.sh -s cgl -n
```

### Submitting to Gerrit

```bash
# Push to Gerrit for review
git push origin HEAD:refs/for/main
```

## Useful DDEV Commands

### Project Management

```bash
# Start project
ddev start

# Stop project
ddev stop

# Restart project
ddev restart

# Delete project (keeps files)
ddev delete

# Power off all DDEV projects
ddev poweroff
```

### Database Management

```bash
# Export database
ddev export-db --file=backup.sql.gz

# Import database
ddev import-db --file=backup.sql.gz

# Access database CLI
ddev mysql

# Launch phpMyAdmin
ddev launch -p
```

### TYPO3 Commands

```bash
# Clear all caches
ddev typo3 cache:flush

# Clear specific cache
ddev typo3 cache:flush --group=system

# Run scheduler tasks
ddev typo3 scheduler:run

# List available commands
ddev typo3 list
```

### Debugging

```bash
# View logs
ddev logs

# Follow logs (like tail -f)
ddev logs -f

# SSH into container
ddev ssh

# Execute command in container
ddev exec 'command'
```

### Performance

```bash
# View resource usage
docker stats

# Restart services if slow
ddev restart
```

## Customization Options

### Different PHP Versions

```bash
# Switch to PHP 8.2
ddev config --php-version=8.2
ddev restart
```

### Different Database Versions

```bash
# Use MySQL instead of MariaDB
ddev config --database=mysql:8.0
ddev restart
```

### Additional Services

```bash
# Add Redis
ddev get ddev/ddev-redis

# Add Elasticsearch
ddev get ddev/ddev-elasticsearch

# Add Mailhog (email testing)
ddev config --mailhog-port=8026
```

### Custom Domain

```bash
# Add additional hostname
ddev config --additional-hostnames=t3dev.local
ddev restart
```

## Troubleshooting

### "Port already allocated"

**Problem**: DDEV can't start because ports are in use

**Solution**:
```bash
# Stop other DDEV projects
ddev poweroff

# Or change port
ddev config --router-http-port=8080 --router-https-port=8443
```

### "Composer timeout"

**Problem**: Composer operations timeout

**Solution**:
```bash
# Increase timeout
ddev composer config --global process-timeout 2000

# Or use runTests.sh
./Build/Scripts/runTests.sh -s composerInstall
```

### "Cannot write to directory"

**Problem**: Permission issues in container

**Solution**:
```bash
# Fix permissions
ddev exec 'chmod -R 777 var/ typo3temp/ typo3conf/'

# Or restart DDEV
ddev restart
```

### "Database connection failed"

**Problem**: TYPO3 can't connect to database

**Solution**:
```bash
# Check database is running
ddev describe

# Verify credentials in LocalConfiguration.php
ddev exec 'cat typo3conf/LocalConfiguration.php | grep -A5 DB'

# Should show: host=db, username=db, password=db, database=db
```

## Best Practices

### Directory Naming

Use descriptive names indicating:
- TYPO3 version: `t3coredev-14`
- PHP version: `php8-4`
- Purpose: `coredev`, `testing`, `feature-name`

Examples:
- `t3coredev-14-php8-4`
- `t3-bugfix-105737`
- `t3-testing-indexed-search`

### Git Workflow

1. **Always start from main**:
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Use feature branches**:
   ```bash
   git checkout -b feature/issue-description
   ```

3. **Keep single commit per patch**:
   ```bash
   git commit --amend  # Update existing commit
   ```

4. **Rebase regularly**:
   ```bash
   git fetch origin
   git rebase origin/main
   ```

### DDEV Management

1. **Stop unused projects**:
   ```bash
   ddev list
   ddev stop <project>
   ```

2. **Clean up old projects**:
   ```bash
   ddev delete <project>
   # Then manually delete directory
   ```

3. **Monitor resources**:
   ```bash
   docker stats
   ```

### Testing Workflow

1. **Test before committing**:
   ```bash
   ./Build/Scripts/runTests.sh -s unit
   ./Build/Scripts/runTests.sh -s functional
   ```

2. **Check code style**:
   ```bash
   ./Build/Scripts/runTests.sh -s cgl -n
   ```

3. **Fix code style automatically**:
   ```bash
   ./Build/Scripts/runTests.sh -s cgl
   ```

## Quick Reference

### Essential Commands

| Task | Command |
|------|---------|
| Start DDEV | `ddev start` |
| Stop DDEV | `ddev stop` |
| Open backend | `ddev launch /typo3` |
| Clear cache | `ddev typo3 cache:flush` |
| Run unit tests | `./Build/Scripts/runTests.sh -s unit` |
| Install composer | `./Build/Scripts/runTests.sh -s composerInstall` |
| View logs | `ddev logs -f` |
| SSH into container | `ddev ssh` |
| Export database | `ddev export-db --file=backup.sql.gz` |
| Git push to Gerrit | `git push origin HEAD:refs/for/main` |

### TYPO3 Versions & PHP Compatibility

| TYPO3 Version | PHP Versions | Branch | Status |
|---------------|--------------|--------|--------|
| v14 (main) | 8.2, 8.3, 8.4 | main | Development |
| v13 (LTS) | 8.1, 8.2, 8.3 | 13.4 | Active |
| v12 (ELTS) | 8.1, 8.2 | 12.4 | Security only |

### Default Credentials

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| Backend | `https://[project].ddev.site/typo3` | backenduser | (your choice) |
| Database | `db:3306` | db | db |
| phpMyAdmin | `https://[project].ddev.site:8037` | db | db |

## Integration with typo3-ddev-skill

This workflow complements the `typo3-ddev-skill`:
- Use `typo3-ddev-skill` for quick setup automation
- Use this workflow for manual step-by-step understanding
- Both produce equivalent development environments

## Additional Resources

- **DDEV Documentation**: https://ddev.readthedocs.io/
- **TYPO3 Development**: https://docs.typo3.org/m/typo3/reference-coreapi/
- **runTests.sh Guide**: https://docs.typo3.org/m/typo3/guide-contributionworkflow/main/en-us/Testing/
- **TYPO3 Slack**: https://typo3.slack.com (#typo3-cms-coredev)

---

**Note**: This workflow is based on proven production usage and is continuously updated for current TYPO3 versions. Always check official documentation for the latest recommendations.
