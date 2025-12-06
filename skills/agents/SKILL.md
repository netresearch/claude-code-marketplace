---
name: agents
description: "Generate and maintain AGENTS.md files following the public agents.md convention. Use when creating documentation for AI agent workflows, onboarding guides, or standardizing agent interaction patterns across projects. By Netresearch."
---

# AGENTS.md Generator Skill

Generate and maintain AGENTS.md files following the public agents.md convention.

## What This Skill Does

Creates hierarchical AGENTS.md documentation for software projects:

- **Thin root files** (~30 lines) with precedence rules and global defaults
- **Scoped files** for subsystems (backend/, frontend/, internal/, cmd/, etc.)
- **Auto-extracted commands** from Makefile, package.json, composer.json, go.mod
- **Managed headers** marking files as agent-maintained with timestamps
- **Language-specific templates** for Go, PHP, TypeScript, Python, and hybrid projects
- **Idempotent updates** that preserve existing structure

Based on analysis of 21 real AGENTS.md files across Netresearch projects.

## When to Use This Skill

- **New projects**: Establish baseline AGENTS.md structure
- **Existing projects**: Standardize agent documentation
- **Team onboarding**: Provide AI assistants with project context
- **Multi-repo consistency**: Apply same standards across repositories
- **Documentation updates**: Refresh after major changes

## Usage

### Generate for Current Project

```bash
# Basic generation (thin root + auto-detected scopes)
/tmp/agents-skill/scripts/generate-agents.sh .

# Dry-run to preview what will be created
/tmp/agents-skill/scripts/generate-agents.sh . --dry-run

# Verbose output with detection details
/tmp/agents-skill/scripts/generate-agents.sh . --verbose
```

### Template Styles

```bash
# Thin root (default, ~30 lines, simple-ldap-go style)
/tmp/agents-skill/scripts/generate-agents.sh . --style=thin

# Verbose root (~100-200 lines, ldap-selfservice style)
/tmp/agents-skill/scripts/generate-agents.sh . --style=verbose
```

### Update Existing Files

```bash
# Update timestamps and refresh auto-extracted content
/tmp/agents-skill/scripts/generate-agents.sh . --update

# Force regeneration (overwrites existing, keeps structure)
/tmp/agents-skill/scripts/generate-agents.sh . --force
```

### Validation

```bash
# Validate existing AGENTS.md structure
/tmp/agents-skill/scripts/validate-structure.sh .

# Check for missing scoped files
/tmp/agents-skill/scripts/detect-scopes.sh .
```

## Supported Project Types

### Languages & Frameworks

- **Go**: Libraries, web apps (Fiber/Echo/Gin), CLI tools (Cobra/urfave/cli)
- **PHP**: Composer packages, TYPO3 extensions, Laravel/Symfony apps
- **TypeScript/JavaScript**: React, Next.js, Vue, Node.js, Express
- **Python**: pip, poetry, pipenv, Django, Flask, FastAPI
- **Hybrid**: Multi-language projects (auto-creates scoped files per stack)

### Detection Signals

| Signal | Detection |
|--------|-----------|
| `go.mod` | Go project, extracts version |
| `composer.json` | PHP project, detects TYPO3/Laravel |
| `package.json` | Node.js project, detects framework |
| `pyproject.toml` | Python project, detects poetry/ruff |
| `Makefile` | Extracts targets with `##` comments |
| `.github/workflows/` | Extracts CI checks |
| `docker-compose.yml` | Docker-first setup |

## Output Structure

### Thin Root (Default)

**~30 lines** following `simple-ldap-go` pattern:

```markdown
<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: YYYY-MM-DD -->

# AGENTS.md (root)

**Precedence:** The **closest AGENTS.md** to changed files wins. Root holds global defaults only.

## Global rules
- Keep PRs small (~≤300 net LOC)
- Conventional Commits: type(scope): subject
- Ask before: heavy deps, full e2e, repo rewrites
- Never commit secrets or PII

## Minimal pre-commit checks
- Typecheck: [auto-detected from build tools]
- Lint: [auto-detected from linters]
- Format: [auto-detected from formatters]
- Tests: [auto-detected from test runners]

## Index of scoped AGENTS.md
- `./backend/AGENTS.md` — Backend services
- `./frontend/AGENTS.md` — Frontend application

## When instructions conflict
Nearest AGENTS.md wins. User prompts override files.
```

### Scoped Files (9-Section Schema)

Each scoped file follows this structure:

1. **Overview**: Purpose of this subsystem
2. **Setup & environment**: Prerequisites, installation
3. **Build & tests**: File-scoped commands (preferred)
4. **Code style & conventions**: Language-specific standards
5. **Security & safety**: Security practices
6. **PR/commit checklist**: Pre-commit requirements
7. **Good vs. bad examples**: Concrete code samples
8. **When stuck**: Where to find help
9. **House Rules** (optional): Overrides of global rules

### Managed Header

All generated files include:

```html
<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: 2025-10-18 -->
```

This marks files as agent-maintained and provides update tracking.

## Auto-Detection Features

### Project Type Detection

```bash
$ /tmp/agents-skill/scripts/detect-project.sh .
{
  "type": "go-web-app",
  "language": "go",
  "version": "1.24",
  "build_tool": "make",
  "has_docker": true,
  "quality_tools": ["golangci-lint", "gofmt"],
  "test_framework": "testing",
  "ci": "github-actions"
}
```

### Scope Detection

Automatically creates scoped AGENTS.md for directories with ≥5 source files:

```bash
$ /tmp/agents-skill/scripts/detect-scopes.sh .
{
  "scopes": [
    {"path": "internal", "type": "backend-go", "files": 15},
    {"path": "cmd", "type": "cli", "files": 3},
    {"path": "examples", "type": "examples", "files": 8}
  ]
}
```

### Command Extraction

Extracts actual commands from build tools:

```bash
$ /tmp/agents-skill/scripts/extract-commands.sh .
{
  "typecheck": "go build -v ./...",
  "lint": "golangci-lint run ./...",
  "format": "gofmt -w .",
  "test": "go test -v -race -short ./...",
  "build": "go build -o bin/app ./cmd/app"
}
```

## Examples

Real-world examples from Netresearch projects in `references/examples/`:

### Go Library (simple-ldap-go)

**Perfect thin root** (26 lines):
- Minimal global rules
- File-scoped commands
- Clear scope index
- No duplication

### Hybrid App (ldap-selfservice-password-changer)

**Go backend + TypeScript frontend**:
- Root with quick navigation
- Scoped: `internal/AGENTS.md` (Go)
- Scoped: `internal/web/AGENTS.md` (TypeScript + Tailwind)

### PHP TYPO3 Extension (t3x-rte_ckeditor_image)

**Composer-based with Make targets**:
- Root with emoji headers
- Scoped: `Classes/AGENTS.md` (PHP backend)
- Scoped: `Documentation/AGENTS.md` (RST docs)
- Scoped: `Tests/AGENTS.md` (PHPUnit tests)

### Python CLI (coding_agent_cli_toolset)

**Script-heavy toolset**:
- Root with precedence focus
- Scoped: `scripts/AGENTS.md`

## Customization

### Override Templates

Copy templates to project and modify:

```bash
cp /tmp/agents-skill/templates/root-thin.md ./.agents-templates/root.md
# Edit ./.agents-templates/root.md
/tmp/agents-skill/scripts/generate-agents.sh . --template-dir=./.agents-templates
```

### Add Custom Sections

Templates support placeholders:
- `{{PROJECT_NAME}}` - From package.json/composer.json/go.mod
- `{{PROJECT_TYPE}}` - Auto-detected type
- `{{LANGUAGE}}` - Primary language
- `{{BUILD_COMMANDS}}` - Extracted commands
- `{{QUALITY_TOOLS}}` - Detected linters/formatters
- `{{TIMESTAMP}}` - Current date (YYYY-MM-DD)

## Idempotent Updates

Safe to run multiple times:

1. Checks existing files
2. Preserves custom content in sections
3. Updates only auto-extracted parts (commands, versions)
4. Refreshes timestamps
5. Adds missing sections
6. No changes if nothing updated

## Validation

```bash
# Check structure compliance
/tmp/agents-skill/scripts/validate-structure.sh .

# Validates:
# ✅ Root is thin (≤50 lines or has index)
# ✅ All scoped files have 9 sections
# ✅ Managed headers present
# ✅ Precedence statement in root
# ✅ Links from root to scoped files work
# ✅ No duplicate content between root and scoped
```

## Integration with Claude Code

### As Marketplace Skill

Add to `claude-code-marketplace`:

```json
{
  "name": "agents",
  "description": "Generate AGENTS.md files following public convention",
  "version": "1.0.0",
  "source": "./skills/agents"
}
```

### Direct Usage

```bash
# Clone skill
git clone https://github.com/netresearch/agents-skill.git /tmp/agents-skill

# Generate for current project
/tmp/agents-skill/scripts/generate-agents.sh .
```

## Structure Standards Application

**When creating root AGENTS.md files**, keep them thin (~30 lines):
- Include clear precedence statement at top
- Define minimal global rules only (PR size, commit format, safety)
- List pre-commit checks (typecheck, lint, format, test)
- Provide scope index linking to scoped files
- Move detailed setup to scoped files (not in root)
- Move language-specific patterns to scoped files (not in root)
- Move extensive examples to scoped files (not in root)

**When determining scope boundaries**, create scoped files for:
- Different technology stacks: `backend/`, `frontend/`, `api/`
- Package visibility: `internal/`, `pkg/` (Go projects)
- CLI tools: `cmd/`, `cli/`
- Utility scripts: `scripts/`
- Documentation and examples: `docs/`, `examples/`
- Testing infrastructure: `tests/`, `testutil/`

**When extracting commands**, automate extraction from:
- Makefile targets with `##` comments
- package.json scripts section
- composer.json scripts section
- CI workflow files (.github/workflows/, .gitlab-ci.yml)
- Never manually duplicate commands that exist in build tools

## Troubleshooting

### No Commands Detected

```bash
# Check what was detected
/tmp/agents-skill/scripts/extract-commands.sh . --verbose

# Fallback: Specify commands manually
/tmp/agents-skill/scripts/generate-agents.sh . --commands='{"lint":"make lint","test":"make test"}'
```

### Wrong Project Type

```bash
# Override auto-detection
/tmp/agents-skill/scripts/generate-agents.sh . --type=go-library

# Supported types:
# go-library, go-web-app, go-cli
# php-library, php-typo3, php-laravel
# typescript-react, typescript-node
# python-library, python-cli
# hybrid
```

### Scoped File Not Created

```bash
# Check scope detection
/tmp/agents-skill/scripts/detect-scopes.sh .

# Manually specify scopes
/tmp/agents-skill/scripts/generate-agents.sh . --scopes=internal,cmd,examples
```

## Contributing

Improvements welcome! Common additions:
- New language templates
- Better command extraction
- Additional validation rules
- More real-world examples

## License

GPL-2.0-or-later (matching other Netresearch skills)

## References

- **Analysis**: `references/analysis.md` - Analysis of 21 real AGENTS.md files
- **Prompt**: `references/prompt.md` - Original generation prompt/rule
- **Examples**: `references/examples/` - Real-world AGENTS.md files
- **Best Practices**: `references/best-practices.md` - Writing guide
