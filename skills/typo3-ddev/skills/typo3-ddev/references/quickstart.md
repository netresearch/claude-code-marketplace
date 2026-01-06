# Quick Start Guide

This guide walks you through setting up DDEV for your TYPO3 extension using this skill.

## Prerequisites Check

Before starting, verify:

```bash
# Check DDEV
ddev version
# Expected: DDEV version v1.22+

# Check Docker
docker ps
# Expected: List of containers or empty (no error)

# Check you're in a TYPO3 extension directory
ls ext_emconf.php
# Expected: ext_emconf.php file exists
```

## Step 1: Install the Skill

```bash
cd ~/.claude/skills/
git clone https://github.com/netresearch/typo3-ddev-skill.git
```

## Step 2: Navigate to Your Extension

```bash
cd ~/projects/my-typo3-extension
```

## Step 3: Invoke the Skill in Claude Code

Open Claude Code and type:

```
Set up DDEV for this TYPO3 extension
```

Or use the slash command (if configured):

```
/typo3-ddev
```

## Step 4: Follow the Prompts

The skill will:

1. **Detect** your extension:
   ```
   ✅ Found TYPO3 extension: my_ext
   ```

2. **Extract** metadata:
   ```
   Extension Key:     my_ext
   Package Name:      vendor/my-ext
   DDEV Sitename:     my-ext
   Vendor Namespace:  Vendor\MyExt
   ```

3. **Confirm** with you:
   ```
   Is this correct? (y/n)
   ```

4. **Generate** .ddev configuration files

5. **Start** DDEV (if you approve)

## Step 5: Install TYPO3

Once DDEV is running:

```bash
# Install all versions (recommended for first time)
ddev install-all

# Or install specific version
ddev install-v13
```

Wait 2-5 minutes per version for installation.

## Step 6: Access Your Environment

Open in your browser:

- **Overview**: https://my-ext.ddev.site/
- **TYPO3 13 Backend**: https://v13.my-ext.ddev.site/typo3/
  - Username: `admin`
  - Password: `Joh316!`

## Step 7: Start Developing

Your extension source code is in the project root. Any changes you make will immediately reflect in all TYPO3 versions because the code is bind-mounted.

### Typical Development Workflow

```bash
# 1. Make changes to your extension code
vim Classes/Controller/MyController.php

# 2. Clear TYPO3 cache
ddev exec -d /var/www/html/v13 vendor/bin/typo3 cache:flush

# 3. Test in browser
# Open https://v13.my-ext.ddev.site/

# 4. Check logs if needed
ddev logs
```

## Next Steps

### Enable XDebug

```bash
ddev xdebug on
# Configure your IDE to connect to localhost:9003
```

### Add Database Fixtures

```bash
# Import database
ddev import-db --file=fixtures/database.sql

# Export database
ddev export-db > backup.sql.gz
```

### Run Tests

```bash
# Unit tests
ddev exec vendor/bin/phpunit Tests/Unit/

# Functional tests
ddev exec vendor/bin/phpunit Tests/Functional/
```

### Access Database

```bash
# MySQL CLI
ddev mysql

# Or use a GUI tool:
# Host: 127.0.0.1
# Port: (run `ddev describe` to get the port)
# User: root
# Password: root
```

## Common Tasks

### Restart DDEV

```bash
ddev restart
```

### Stop DDEV

```bash
ddev stop
```

### Remove Environment (keeps volumes)

```bash
ddev delete
```

### Complete Cleanup (removes everything)

```bash
ddev delete --omit-snapshot --yes
docker volume rm my-ext-v11-data my-ext-v12-data my-ext-v13-data
```

### SSH into Container

```bash
ddev ssh
# You're now inside the container
cd /var/www/html/v13
# Do stuff
exit
```

## Troubleshooting

### Port Already in Use

```bash
# Edit .ddev/config.yaml
router_http_port: "8080"
router_https_port: "8443"

ddev restart
```

### Installation Hangs or Fails

```bash
# Check logs
ddev logs

# Retry installation
ddev ssh
rm -rf /var/www/html/v13/*
exit
ddev install-v13
```

### Extension Not Found

```bash
# Verify environment variables
ddev ssh
echo $EXTENSION_KEY
echo $PACKAGE_NAME

# Check Composer setup
cd /var/www/html/v13
composer show $PACKAGE_NAME
```

### Clear Everything and Start Over

```bash
ddev delete --omit-snapshot --yes
rm -rf .ddev/
# Then re-run the skill setup
```

## Example Project Structure

After setup, your project should look like:

```
my-typo3-extension/
├── .ddev/                      # DDEV configuration (generated)
│   ├── config.yaml
│   ├── docker-compose.web.yaml
│   ├── apache/
│   ├── web-build/
│   └── commands/
├── Classes/                    # Your extension PHP classes
├── Configuration/              # Your extension configuration
├── Resources/                  # Your extension resources
├── Tests/                      # Your extension tests
├── composer.json               # Your extension composer config
├── ext_emconf.php             # TYPO3 extension declaration
└── README.md                   # Your extension documentation
```

## Tips for Extension Development

1. **Use Multiple Terminals**:
   - Terminal 1: Code editing
   - Terminal 2: `ddev logs -f` (follow logs)
   - Terminal 3: `ddev ssh` (run commands)

2. **Cache Management**:
   - Development: Clear cache frequently
   - Use `ddev exec -d /var/www/html/v13 vendor/bin/typo3 cache:flush`

3. **Version Testing**:
   - Test critical changes across all versions
   - Use `ddev install-all` to have all versions ready

4. **Backup Important Data**:
   - Export databases before major changes
   - Use `ddev export-db --gzip=false > backup.sql`

5. **Keep DDEV Updated**:
   ```bash
   ddev version  # Check current version
   # Update via your package manager (brew, apt, etc.)
   ```

---

**Happy TYPO3 Extension Development! 🚀**
