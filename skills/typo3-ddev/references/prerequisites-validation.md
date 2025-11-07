## Prerequisites Validation

Before proceeding with ANY DDEV commands, especially on first DDEV command during a session, perform comprehensive validation:

### 1. Docker Daemon Status

**Check if Docker daemon is running:**
```bash
docker info >/dev/null 2>&1
```

**If Docker daemon is NOT running:**

```
❌ Docker daemon is not running.

Start Docker daemon based on your platform:

🐧 Linux/WSL2:
   sudo service docker start
   # or
   sudo systemctl start docker
   # Verify:
   sudo systemctl status docker

🍎 macOS:
   - Open Docker Desktop application
   - Wait for whale icon to show "Docker Desktop is running"
   # Verify from terminal:
   docker info

🪟 Windows:
   - Open Docker Desktop application
   - Wait for notification "Docker Desktop is running"
   # Verify from PowerShell/CMD:
   docker info

After starting Docker, please retry the command.
```

### 2. Docker CLI Version

**Check Docker version (minimum: 20.10):**
```bash
docker version --format '{{.Client.Version}}'
```

**Expected output:** Version >= 20.10 (e.g., `24.0.7`, `25.0.0`)

**If version is too old or missing:**

```
❌ Docker CLI is outdated or missing.

Minimum required version: 20.10
Current version: [detected or "not found"]

Update Docker:

🐧 Linux:
   # Ubuntu/Debian
   curl -fsSL https://get.docker.com | sh

   # Or follow: https://docs.docker.com/engine/install/

🍎 macOS:
   brew upgrade --cask docker
   # Or download from: https://www.docker.com/products/docker-desktop/

🪟 Windows:
   # Update via Docker Desktop app or download from:
   https://www.docker.com/products/docker-desktop/
```

### 3. Docker Compose Version

**Check Docker Compose version (minimum: 2.0):**
```bash
docker compose version --short
```

**Expected output:** Version >= 2.0 (e.g., `2.23.3`, `2.24.0`)

**Note:** Modern Docker includes Compose v2 as `docker compose` (not `docker-compose`)

**If version is too old or missing:**

```
❌ Docker Compose is outdated or using legacy v1.

Minimum required version: 2.0
Current version: [detected or "not found"]

Docker Compose v2 is included with Docker Desktop 3.4+ and Docker CLI 20.10+

Solutions:

🐧 Linux:
   # If using legacy docker-compose v1:
   sudo apt remove docker-compose

   # Compose v2 is included with Docker 20.10+
   # Verify installation:
   docker compose version

   # If missing, install Docker CLI with Compose plugin:
   sudo apt-get install docker-compose-plugin

🍎 macOS / 🪟 Windows:
   # Included in Docker Desktop - update to latest:
   brew upgrade --cask docker  # macOS

   # Or download latest Docker Desktop
```

### 4. DDEV Installation

**Check if DDEV is installed:**
```bash
ddev version
```

**If DDEV is not installed:**

```
❌ DDEV is not installed.

Install DDEV based on your platform:

🍎 macOS:
   brew install ddev/ddev/ddev

🐧 Linux:
   # Ubuntu/Debian
   curl -fsSL https://raw.githubusercontent.com/ddev/ddev/master/scripts/install_ddev.sh | bash

   # Or see: https://ddev.readthedocs.io/en/stable/users/install/ddev-installation/

🪟 Windows:
   choco install ddev
   # Or see: https://ddev.readthedocs.io/en/stable/users/install/ddev-installation/
```

### 5. TYPO3 Extension Project Validation

**Confirm current directory is a TYPO3 extension:**
- Check for `ext_emconf.php` file
- OR check `composer.json` has `type: "typo3-cms-extension"`
- Check for typical TYPO3 extension structure (Classes/, Configuration/, Resources/)

**If not a TYPO3 extension:**

```
❌ This doesn't appear to be a TYPO3 extension project.

Requirements:
  - ext_emconf.php file present
  OR
  - composer.json with "type": "typo3-cms-extension"

Current directory: [show path]
```

### 6. Existing DDEV Setup Check

**Check if `.ddev/` directory already exists:**

```bash
test -d .ddev && echo "DDEV config exists" || echo "No DDEV config"
```

**If `.ddev/` exists:**

```
⚠️  DDEV configuration already exists.

Do you want to:
  1. Keep existing configuration (skip setup)
  2. Overwrite with new configuration
  3. Backup existing and create new

Please choose: [1/2/3]
```

### Prerequisites Validation Summary

**Run ALL checks before proceeding:**

```bash
# Quick validation script
echo "🔍 Validating prerequisites..."

# 1. Docker daemon
if docker info >/dev/null 2>&1; then
    echo "✅ Docker daemon: Running"
else
    echo "❌ Docker daemon: Not running"
    exit 1
fi

# 2. Docker version
DOCKER_VERSION=$(docker version --format '{{.Client.Version}}' 2>/dev/null | cut -d. -f1,2)
if [ -n "$DOCKER_VERSION" ] && [ "$(printf '%s\n' "20.10" "$DOCKER_VERSION" | sort -V | head -n1)" = "20.10" ]; then
    echo "✅ Docker CLI: $DOCKER_VERSION (>= 20.10)"
else
    echo "❌ Docker CLI: Version check failed (need >= 20.10)"
    exit 1
fi

# 3. Docker Compose version
COMPOSE_VERSION=$(docker compose version --short 2>/dev/null | cut -d. -f1)
if [ -n "$COMPOSE_VERSION" ] && [ "$COMPOSE_VERSION" -ge 2 ]; then
    echo "✅ Docker Compose: $(docker compose version --short) (>= 2.0)"
else
    echo "❌ Docker Compose: Version check failed (need >= 2.0)"
    exit 1
fi

# 4. DDEV
if command -v ddev >/dev/null 2>&1; then
    echo "✅ DDEV: $(ddev version | head -n1)"
else
    echo "❌ DDEV: Not installed"
    exit 1
fi

# 5. TYPO3 Extension
if [ -f "ext_emconf.php" ] || grep -q '"type".*"typo3-cms-extension"' composer.json 2>/dev/null; then
    echo "✅ TYPO3 Extension: Detected"
else
    echo "❌ TYPO3 Extension: Not detected"
    exit 1
fi

echo ""
echo "✅ All prerequisites validated successfully!"
```

**Critical:** Always run these checks on the FIRST DDEV command in a session to catch environment issues early.

If any prerequisite fails, provide clear instructions on how to resolve it before proceeding.

