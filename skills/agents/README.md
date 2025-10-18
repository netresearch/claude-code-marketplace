# AGENTS.md Generator Skill

Generate and maintain AGENTS.md files following the [public agents.md convention](https://github.com/anthropics/anthropic-sdk-python/blob/main/AGENTS.md).

## Quick Start

```bash
# Generate AGENTS.md files for current project (thin root + auto-detected scopes)
/tmp/agents-skill/scripts/generate-agents.sh .

# Preview what will be created
/tmp/agents-skill/scripts/generate-agents.sh . --dry-run

# Use verbose root template
/tmp/agents-skill/scripts/generate-agents.sh . --style=verbose

# Validate existing structure
/tmp/agents-skill/scripts/validate-structure.sh .
```

## What It Does

Creates hierarchical AGENTS.md documentation for software projects:

- **Thin root files** (~30 lines) with precedence rules and global defaults
- **Scoped files** for subsystems (backend/, frontend/, internal/, cmd/, etc.)
- **Auto-extracted commands** from Makefile, package.json, composer.json, go.mod
- **Managed headers** marking files as agent-maintained with timestamps
- **Language-specific templates** for Go, PHP, TypeScript, Python
- **Idempotent updates** that preserve existing structure

## Supported Project Types

### Languages & Frameworks

- **Go**: Libraries, web apps (Fiber/Echo/Gin), CLI tools (Cobra/urfave/cli)
- **PHP**: Composer packages, TYPO3 extensions, Laravel/Symfony apps
- **TypeScript/JavaScript**: React, Next.js, Vue, Node.js, Express
- **Python**: pip, poetry, pipenv, Django, Flask, FastAPI
- **Hybrid**: Multi-language projects (auto-creates scoped files per stack)

### Auto-Detection

The skill automatically detects:
- Project language and version
- Build tools (make, npm, composer, poetry)
- Quality tools (linters, formatters, type checkers)
- Test frameworks
- Framework type (React, TYPO3, Django, etc.)
- Directories needing scoped AGENTS.md files

## Usage

### Basic Generation

```bash
# Generate for current project
/tmp/agents-skill/scripts/generate-agents.sh .

# Generate for specific project
/tmp/agents-skill/scripts/generate-agents.sh /path/to/project
```

**Output**:
```
✅ Created: ./AGENTS.md
✅ Created: ./internal/AGENTS.md
✅ Created: ./cmd/AGENTS.md
✅ Generated: 1 root + 2 scoped files
```

### Template Styles

#### Thin Root (Default)

Perfect thin root following simple-ldap-go pattern (~30 lines):

```bash
/tmp/agents-skill/scripts/generate-agents.sh . --style=thin
```

Contains:
- Precedence statement
- Minimal global rules
- Pre-commit checks
- Scope index
- Conflict resolution

#### Verbose Root

Comprehensive root with detailed sections (~100-200 lines):

```bash
/tmp/agents-skill/scripts/generate-agents.sh . --style=verbose
```

Additional sections:
- Project overview
- Development workflow
- Code quality standards
- Security guidelines
- Testing requirements
- Documentation links

### Options

```bash
--style=thin|verbose    Template style (default: thin)
--dry-run               Preview what will be created without writing files
--update                Update existing files only (preserve custom content)
--force                 Force regeneration of all files
--verbose, -v           Verbose output with detection details
--help, -h              Show help message
```

### Examples

```bash
# Preview changes before applying
/tmp/agents-skill/scripts/generate-agents.sh . --dry-run

# Generate verbose root with detailed guidelines
/tmp/agents-skill/scripts/generate-agents.sh . --style=verbose

# Update existing files with refreshed commands and timestamps
/tmp/agents-skill/scripts/generate-agents.sh . --update

# Force regeneration of all files
/tmp/agents-skill/scripts/generate-agents.sh . --force

# Verbose output to see detection process
/tmp/agents-skill/scripts/generate-agents.sh . --verbose
```

## Output Structure

### Thin Root Example

```markdown
<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: 2025-10-18 -->

# AGENTS.md (root)

This file explains repo-wide conventions and where to find scoped rules.
**Precedence:** the **closest `AGENTS.md`** to the files you're changing wins. Root holds global defaults only.

## Global rules
- Keep diffs small; add tests for new code paths
- Ask first before: adding heavy deps, running full e2e suites, or repo-wide rewrites
- Never commit secrets or sensitive data to the repository
- Follow Go 1.24 conventions and idioms

## Minimal pre-commit checks
- Typecheck (all packages): `go build -v ./...`
- Lint/format (file scope): `gofmt -w <file.go>` and `golangci-lint run ./...`
- Unit tests (fast): `go test -v -race -short -timeout=10s ./...`

## Index of scoped AGENTS.md
- `./internal/AGENTS.md` — Backend services (Go)
- `./cmd/AGENTS.md` — Command-line interface tools

## When instructions conflict
- The nearest `AGENTS.md` wins. Explicit user prompts override files.
- For Go-specific patterns, defer to language idioms and standard library conventions
```

### Scoped File (9-Section Schema)

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

## Detection Scripts

### Project Detection

```bash
/tmp/agents-skill/scripts/detect-project.sh .
```

Returns JSON with detected information:

```json
{
  "type": "go-web-app",
  "language": "go",
  "version": "1.24",
  "build_tool": "make",
  "framework": "fiber",
  "has_docker": true,
  "quality_tools": ["golangci-lint", "gofmt"],
  "test_framework": "testing",
  "ci": "github-actions"
}
```

### Scope Detection

```bash
/tmp/agents-skill/scripts/detect-scopes.sh .
```

Returns directories needing scoped AGENTS.md:

```json
{
  "scopes": [
    {"path": "internal", "type": "backend-go", "files": 15},
    {"path": "cmd", "type": "cli", "files": 3}
  ]
}
```

### Command Extraction

```bash
/tmp/agents-skill/scripts/extract-commands.sh .
```

Returns auto-extracted build commands:

```json
{
  "typecheck": "go build -v ./...",
  "lint": "golangci-lint run ./...",
  "format": "gofmt -w .",
  "test": "go test -v -race -short ./...",
  "build": "go build -v ./...",
  "dev": ""
}
```

## Validation

```bash
/tmp/agents-skill/scripts/validate-structure.sh .
```

Validates:
- ✅ Root is thin (≤50 lines or has index)
- ✅ All scoped files have 9 sections
- ✅ Managed headers present
- ✅ Precedence statement in root
- ✅ Links from root to scoped files work

**Example output**:

```
Validating AGENTS.md structure in: .

=== Root AGENTS.md ===
✅ Managed header present: ./AGENTS.md
✅ Root is thin: 27 lines
✅ Precedence statement present
✅ All scope index links work

=== Scoped AGENTS.md Files ===
Checking: internal/AGENTS.md
✅ Managed header present: internal/AGENTS.md
✅ All required sections present: internal/AGENTS.md

=== Validation Summary ===
✅ All checks passed!
```

## Real-World Examples

The skill includes real examples from Netresearch projects in `references/examples/`:

### simple-ldap-go (Perfect Thin Root)

**26-line root** demonstrating minimal best practice:
- Clear precedence statement
- File-scoped commands
- Scope index with descriptions
- No duplication

See: `references/examples/simple-ldap-go/AGENTS.md`

### ldap-selfservice (Hybrid Go + TypeScript)

**Multi-stack project**:
- Thin root with navigation
- `internal/AGENTS.md` for Go backend
- `internal/web/AGENTS.md` for TypeScript + Tailwind frontend

### t3x-rte_ckeditor_image (TYPO3 Extension)

**PHP TYPO3 extension**:
- Composer-based with Make targets
- Scoped for Classes/, Documentation/, Tests/
- TYPO3-specific conventions (DI, CGL, PHPStan Level 10)

### coding_agent_cli (Python CLI)

**Script-heavy toolset**:
- Precedence-focused root
- Scoped for scripts/ directory
- Python-specific tooling (ruff, mypy, pytest)

## Managed Headers

All generated files include a managed header:

```html
<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: 2025-10-18 -->
```

This indicates:
- File is agent-maintained
- Section structure should not be changed
- Content within sections can be edited
- Timestamp tracks last update

## Idempotent Updates

Safe to run multiple times:

1. Checks existing files
2. Preserves custom content in sections
3. Updates only auto-extracted parts (commands, versions)
4. Refreshes timestamps
5. Adds missing sections
6. No changes if nothing updated

```bash
# Update existing files with refreshed data
/tmp/agents-skill/scripts/generate-agents.sh . --update
```

## Best Practices

### Keep Root Thin

✅ **Good** (simple-ldap-go, 26 lines):
- Precedence statement
- Minimal global rules
- Pre-commit checks
- Scope index

❌ **Bloated** (some projects, 300+ lines):
- Detailed setup instructions (→ move to scoped files)
- Language-specific patterns (→ move to scoped files)
- Extensive examples (→ move to scoped files)

### Scope Appropriately

Create scoped files for:
- Different technology stacks (backend/, frontend/, api/)
- Public vs private packages (internal/, pkg/)
- CLI tools (cmd/, cli/)
- Utility scripts (scripts/)
- Documentation (docs/, examples/)
- Testing infrastructure (tests/, testutil/)

### Auto-Extract Commands

Don't manually write commands if they exist in:
- Makefile targets
- package.json scripts
- composer.json scripts
- CI workflows

Let the generator extract them automatically.

## Installation

### Claude Code Marketplace

Add to `.claude/marketplace.json`:

```json
{
  "name": "agents",
  "description": "Generate AGENTS.md files following public convention",
  "version": "1.0.0",
  "path": "/tmp/agents-skill"
}
```

### Direct Usage

```bash
# Clone skill
git clone https://github.com/netresearch/agents-skill.git /tmp/agents-skill

# Generate for current project
/tmp/agents-skill/scripts/generate-agents.sh .
```

## Troubleshooting

### No Commands Detected

```bash
# Check what was detected
/tmp/agents-skill/scripts/extract-commands.sh . --verbose

# Fallback: Check Makefile or package.json manually
cat Makefile
cat package.json
```

### Wrong Project Type

```bash
# Check detection
/tmp/agents-skill/scripts/detect-project.sh .

# Verify files that should be detected
ls -la go.mod package.json composer.json pyproject.toml
```

### Scoped File Not Created

```bash
# Check scope detection
/tmp/agents-skill/scripts/detect-scopes.sh .

# Minimum 5 source files needed for scopes (except cmd/, tests/)
find internal -name "*.go" | wc -l
```

## License

GPL-2.0-or-later (matching other Netresearch skills)

## References

- **Analysis**: `references/analysis.md` - Analysis of 21 real AGENTS.md files
- **Examples**: `references/examples/` - Real-world AGENTS.md files from Netresearch projects
- **Public Convention**: https://github.com/anthropics/anthropic-sdk-python/blob/main/AGENTS.md
