---
name: cli-tools
description: "Agent Skill: CLI tool management for coding agents. Use when a command fails with 'command not found', installing/updating CLI tools, setting up project environments, or checking dependencies. Provides auto-installation of 74+ tools via optimal package managers, project environment auditing, and batch update capabilities. By Netresearch."
---

# CLI Tools Skill

Manage CLI tool installation, environment auditing, and updates for coding agents.

## Capabilities

1. **Reactive: Missing Tool Resolution** - Auto-detect and install tools when commands fail
2. **Proactive: Environment Checking** - Audit project dependencies and tool versions
3. **Maintenance: Batch Updates** - Update all managed tools across package managers

## Triggers

### Reactive Mode (Auto-Install Missing Tools)

Activate when observing these error patterns:

```
bash: <tool>: command not found
zsh: command not found: <tool>
'<tool>' is not recognized as an internal or external command
sh: <tool>: not found
/bin/sh: <tool>: not found
Error: Cannot find module '<tool>'
```

### Proactive Mode (Environment Check)

Activate on user requests:
- "check environment", "check my tools", "audit tools"
- "what's missing", "what's outdated", "update tools"
- "fix my environment", "setup environment"
- "install development tools", "install project dependencies"
- Project initialization or `/sc:load` context

### Maintenance Mode (Batch Updates)

Activate on:
- "update all tools", "upgrade everything"
- "update package managers", "refresh tools"

## Workflows

### Workflow 1: Missing Tool Resolution

When a command fails with "command not found":

1. **Extract tool name** from error message
2. **Resolve catalog entry** using `references/binary_to_tool_map.md`:
   - `rg` → `ripgrep`
   - `fd` → `fd`
   - `python3` → `python`
3. **Check if catalog exists**: `catalog/<tool>.json`
4. **Execute installation**:
   ```bash
   scripts/install_tool.sh <tool> install
   ```
5. **Verify installation**: Check command now works
6. **Retry original command**

**Example:**
```
User runs: rg "pattern" src/
Error: bash: rg: command not found

Action sequence:
1. Lookup: rg → ripgrep (from binary_to_tool_map.md)
2. Execute: scripts/install_tool.sh ripgrep install
3. Verify: rg --version
4. Retry: rg "pattern" src/
```

### Workflow 2: Environment Audit

When checking project environment:

1. **Detect project type**:
   ```bash
   scripts/detect_project_type.sh text .
   ```
2. **Run full audit**:
   ```bash
   scripts/check_environment.sh audit .
   ```
3. **Report findings**:
   - Missing required tools
   - Outdated tools
   - PATH issues
   - Duplicate installations
4. **Offer to fix** issues found

**Example:**
```
User: "check my environment"

Action sequence:
1. Detect: Python project (pyproject.toml found)
2. Required: python, uv
3. Recommended: ruff, black, mypy
4. Check each tool...
5. Report: "Missing: ruff. All others OK."
6. Offer: "Install ruff? [Y/n]"
```

### Workflow 3: Batch Updates

When updating all tools:

1. **Dry run first** to preview changes:
   ```bash
   DRY_RUN=1 scripts/auto_update.sh update
   ```
2. **Confirm with user** before proceeding
3. **Execute updates** by scope:
   ```bash
   SCOPE=user scripts/auto_update.sh update
   ```
4. **Report results**: Updated count, failures

## Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `install_tool.sh` | Install/update/uninstall tools | `install_tool.sh <tool> [install\|update\|uninstall]` |
| `auto_update.sh` | Batch update all package managers | `auto_update.sh [detect\|update]` |
| `check_environment.sh` | Audit environment | `check_environment.sh [audit\|path\|project]` |
| `detect_project_type.sh` | Detect project type | `detect_project_type.sh [text\|json] [dir]` |

## Catalog Coverage

74 tools across categories:

- **Core CLI**: ripgrep, fd, fzf, jq, yq, bat, delta, just
- **Languages**: python, node, rust, go, ruby
- **Package Managers**: uv, npm, pnpm, cargo, pip, gem
- **DevOps**: docker, compose, kubectl, terraform, ansible
- **Linters**: eslint, prettier, ruff, black, shellcheck
- **Security**: trivy, gitleaks, bandit, semgrep
- **Git Tools**: gh, glab, git-lfs, delta

## Installation Methods

The skill selects the optimal installation method based on catalog priority:

1. **GitHub Release Binary** - Direct download (fastest, no deps)
2. **Cargo** - Rust tools via cargo install
3. **UV/Pip** - Python tools
4. **NPM** - Node tools
5. **Apt/Brew** - System packages (fallback)

Priority: user-level (`~/.local/bin`, `~/.cargo/bin`) over system-level.

## References

Load these as needed:

- `references/binary_to_tool_map.md` - Binary name to catalog entry mapping
- `references/project_type_requirements.md` - Project type to required tools

## Error Handling

If installation fails:

1. Check error message for root cause
2. Try alternative installation method (catalog has multiple)
3. Check network connectivity
4. Verify package manager is working
5. Report failure with actionable guidance

## Notes

- **jq dependency**: Most scripts require `jq`. Install it first if missing.
- **PATH updates**: After installation, may need to reload shell or update PATH.
- **Permissions**: User-level installs do not need sudo. System installs may.
- **Offline mode**: Cannot install without network, but can audit local tools.
