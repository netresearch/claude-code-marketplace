# CLI Tools Skill

A Claude Code skill for automatic CLI tool management. Detects missing tools, installs them via optimal package managers, and audits project environments.

## Features

- **Reactive Mode**: Auto-detect "command not found" errors and install missing tools
- **Proactive Mode**: Audit project environments and report missing/outdated tools
- **Maintenance Mode**: Batch update all managed tools across package managers

## Supported Tools

74+ tools across categories:

| Category | Tools |
|----------|-------|
| **Core CLI** | ripgrep, fd, fzf, jq, yq, bat, delta, just |
| **Languages** | python, node, rust, go, ruby, php |
| **Package Managers** | uv, npm, pnpm, cargo, pip, gem, composer |
| **DevOps** | docker, compose, kubectl, terraform, ansible |
| **Linters** | eslint, prettier, ruff, black, shellcheck, phpstan |
| **Security** | trivy, gitleaks, bandit, semgrep |
| **Git Tools** | gh, glab, git-lfs, delta |

## Project Type Detection

Automatically detects project types and their requirements:

| Project Type | Detection Files | Required Tools |
|--------------|-----------------|----------------|
| Python | `pyproject.toml`, `requirements.txt` | python, uv |
| Node.js | `package.json` | node, npm |
| Rust | `Cargo.toml` | rust |
| Go | `go.mod` | go |
| PHP | `composer.json`, `*.php` | php, composer |
| Ruby | `Gemfile` | ruby |
| Docker | `Dockerfile`, `docker-compose.yml` | docker, compose |
| Terraform | `*.tf` | terraform |

## Installation

### As a Claude Code Skill

```bash
# Copy to your skills directory
cp -r cli-tools ~/.claude/skills/
```

### Manual Usage

```bash
# Install a specific tool
./scripts/install_tool.sh ripgrep install

# Detect project type
./scripts/detect_project_type.sh json .

# Audit environment
./scripts/check_environment.sh audit .

# Update all tools
./scripts/auto_update.sh update
```

## Triggers

The skill activates automatically on:

### Error Patterns
```
bash: <tool>: command not found
zsh: command not found: <tool>
'<tool>' is not recognized as an internal or external command
```

### User Requests
- "check environment", "audit tools"
- "what's missing", "what's outdated"
- "install development tools"
- "update all tools"

## Installation Methods

The skill selects the optimal installation method based on catalog priority:

1. **GitHub Release Binary** - Direct download (fastest, no deps)
2. **Cargo** - Rust tools via cargo install
3. **UV/Pip** - Python tools
4. **NPM** - Node tools
5. **Apt/Brew** - System packages (fallback)

Priority: user-level (`~/.local/bin`, `~/.cargo/bin`) over system-level.

## Directory Structure

```
cli-tools/
├── SKILL.md              # Skill definition and workflows
├── catalog/              # Tool definitions (74+ JSON files)
│   ├── ripgrep.json
│   ├── php.json
│   └── ...
├── scripts/
│   ├── install_tool.sh   # Main installer
│   ├── auto_update.sh    # Batch updater
│   ├── check_environment.sh
│   ├── detect_project_type.sh
│   ├── lib/              # Shared libraries
│   └── installers/       # Method-specific installers
└── references/
    ├── binary_to_tool_map.md
    └── project_type_requirements.md
```

## Requirements

- **jq**: Required for JSON parsing (auto-installed if missing)
- **Bash 4+**: Required for associative arrays
- **Internet**: Required for tool downloads

## License

MIT License - See [LICENSE](LICENSE) for details.

## Contributing

1. Add tool definition to `catalog/<tool>.json`
2. Update `references/binary_to_tool_map.md` if binary differs from tool name
3. Test with `scripts/install_tool.sh <tool> install`
4. Submit PR

## Credits

Created for use with [Claude Code](https://claude.ai/code) by Anthropic.
