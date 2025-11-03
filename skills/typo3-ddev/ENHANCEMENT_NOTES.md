# typo3-ddev Skill Enhancement Notes

## Enhancement: Comprehensive Prerequisites Validation (2025-11-03)

### Problem
The original skill had basic prerequisite checks that only verified if Docker was running with `docker ps`. This didn't catch common issues:
- Docker daemon not running (connection errors)
- Outdated Docker versions (< 20.10) causing compatibility issues
- Missing or outdated Docker Compose v2
- No platform-specific guidance for resolving issues

Users would encounter cryptic error messages when running DDEV commands without clear guidance on resolution.

### Solution
Enhanced the **Prerequisites Validation** section (lines 24-264 in SKILL.md) with comprehensive checks:

#### 1. Docker Daemon Status Check
- Uses `docker info` instead of `docker ps` for reliable daemon detection
- Provides platform-specific startup instructions:
  - Linux/WSL2: `sudo service docker start` or `sudo systemctl start docker`
  - macOS: Docker Desktop application
  - Windows: Docker Desktop application

#### 2. Docker CLI Version Validation
- Minimum required version: **20.10**
- Checks with `docker version --format '{{.Client.Version}}'`
- Provides update instructions for each platform:
  - Linux: `curl -fsSL https://get.docker.com | sh`
  - macOS: `brew upgrade --cask docker`
  - Windows: Update Docker Desktop

#### 3. Docker Compose Version Validation
- Minimum required version: **2.0** (Compose v2)
- Checks with `docker compose version --short` (not legacy `docker-compose`)
- Explains that Compose v2 is included with Docker Desktop 3.4+ and Docker CLI 20.10+
- Provides migration path from legacy v1

#### 4. Validation Script
Added comprehensive bash validation script (`validate-prerequisites.sh`) that:
- Runs all 5 prerequisite checks automatically
- Uses color-coded output (✅ green, ❌ red, ⚠️ yellow)
- Provides clear success/failure status
- Exits with appropriate status codes for CI integration

#### 5. Updated Error Handling Section
- Consolidated Docker-related errors into "Prerequisites Not Met"
- References detailed Prerequisites Validation section
- Provides quick fixes for most common issue (Docker daemon not running)
- Maintains DRY principle by not duplicating installation instructions

### Benefits

1. **Early Error Detection**: Catches environment issues before DDEV commands fail
2. **Platform-Specific Guidance**: Clear instructions for Linux/WSL2, macOS, and Windows
3. **Version Compliance**: Ensures modern Docker/Compose versions for compatibility
4. **Better DX**: Users know exactly what's wrong and how to fix it
5. **Session Awareness**: Emphasizes checking prerequisites on FIRST DDEV command
6. **CI-Ready**: Validation script returns proper exit codes

### Files Modified

1. **SKILL.md**:
   - Lines 24-264: Enhanced Prerequisites Validation section
   - Lines 703-738: Updated Error Handling section

2. **validate-prerequisites.sh** (new):
   - Standalone validation script
   - Can be run independently: `~/.claude/plugins/.../typo3-ddev/validate-prerequisites.sh`
   - Executable with proper exit codes

### Testing

Validated the script successfully detects:
- ✅ Docker daemon running (28.5.1)
- ✅ Docker CLI version compliance (>= 20.10)
- ✅ Docker Compose v2 (2.40.3)
- ✅ DDEV installed
- ✅ TYPO3 extension project structure

### Usage

When using the typo3-ddev skill, Claude will now:

1. **Before ANY DDEV command** (especially first in session):
   - Check if Docker daemon is running
   - Validate Docker CLI version >= 20.10
   - Validate Docker Compose version >= 2.0
   - Verify DDEV is installed

2. **On failure**:
   - Provide platform-specific resolution steps
   - Show exact commands to run
   - Reference detailed documentation

3. **Optional standalone validation**:
   ```bash
   ~/.claude/plugins/marketplaces/netresearch-claude-code-marketplace/skills/typo3-ddev/validate-prerequisites.sh
   ```

### Minimum Version Requirements

| Tool | Minimum Version | Reason |
|------|----------------|--------|
| Docker CLI | 20.10 | Includes Compose v2, modern features |
| Docker Compose | 2.0 | Required by DDEV, modern syntax |
| DDEV | Latest stable | Project-specific requirements |

### Future Enhancements

Potential improvements:
- [ ] Add check for available disk space (Docker needs ~10GB)
- [ ] Add check for available memory (recommend 4GB+)
- [ ] Validate Docker daemon permissions (non-root access)
- [ ] Check for port conflicts (80, 443, 3306) before starting
- [ ] Integration with DDEV's own `ddev debug` command
- [ ] Automatic prerequisite installation option (with confirmation)

### Related Documentation

- DDEV Installation: https://ddev.readthedocs.io/en/stable/users/install/
- Docker Installation: https://docs.docker.com/engine/install/
- Docker Compose v2: https://docs.docker.com/compose/cli-command/
