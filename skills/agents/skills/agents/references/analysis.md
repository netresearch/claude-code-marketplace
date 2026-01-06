# AGENTS.md Analysis Across 6 Netresearch Projects

## Executive Summary

**Total AGENTS.md Files Found**: 21 files across 6 projects

**Patterns Observed**:
1. **Root files are thin** (26-348 lines) with precedence rules and global defaults
2. **Scoped files are focused** on specific subsystems (backend, frontend, CLI, etc.)
3. **Managed header** present in newer files: `<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: YYYY-MM-DD -->`
4. **Consistent structure** following the 9-section schema from your prompt

## File Distribution

| Project | Root | Scoped Files | Total Lines (root) |
|---------|------|--------------|-------------------|
| t3x-rte_ckeditor_image | ✅ | Classes/, Documentation/, Resources/, Tests/ | 348 |
| coding_agent_cli_toolset | ✅ | scripts/ | 308 |
| ldap-selfservice-password-changer | ✅ | internal/, internal/web/ | 282 |
| ldap-manager | ✅ | cmd/, internal/, internal/web/, scripts/ | 228 |
| raybeam | ✅ | cmd/, internal/ | 209 |
| simple-ldap-go | ✅ | docs/, examples/, testutil/ | 26 ⭐ **Perfect thin root** |

## Key Findings

### 1. **simple-ldap-go** is the Best Example ⭐

**Root file** (26 lines):
- Minimal global rules
- Clear precedence statement
- Index of scoped files
- No duplication with scoped content

```markdown
## Global rules
- Keep diffs small; add tests for new code paths
- Ask first before: adding heavy deps, running full e2e suites, or repo-wide rewrites

## Minimal pre-commit checks
- Typecheck (all packages): `go build -v ./...`
- Lint/format (file scope): `gofmt -w <file.go>`
- Unit tests (fast): `go test -v -race -short -timeout=10s ./...`

## Index of scoped AGENTS.md
- `./examples/AGENTS.md` — Example applications
- `./testutil/AGENTS.md` — Testing utilities
- `./docs/AGENTS.md` — Documentation
```

### 2. Scoped Files Follow 9-Section Schema

**Example: simple-ldap-go/examples/AGENTS.md**:
1. ✅ Overview
2. ✅ Setup & environment  
3. ✅ Build & tests (file-scoped)
4. ✅ Code style & conventions
5. ✅ Security & safety
6. ✅ PR/commit checklist
7. ✅ Good vs. bad examples
8. ✅ When stuck
9. ⚠️  House Rules (rarely used, only when overriding)

### 3. Managed Header Usage

**Present in** (newer projects):
- simple-ldap-go (all files)
- ldap-selfservice-password-changer (all files)
- raybeam (some files)

**Missing in** (older projects):
- t3x-rte_ckeditor_image
- coding_agent_cli_toolset

**Format**:
```html
<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: 2025-10-09 -->
```

### 4. Precedence Rules - Consistent Pattern

All root files establish precedence clearly:

**Pattern 1** (verbose):
> "This file explains repo-wide conventions and where to find scoped rules. **Precedence:** the **closest `AGENTS.md`** to the files you're changing wins. Root holds global defaults only."

**Pattern 2** (concise):
> "**Precedence**: Nearest AGENTS.md wins. This is the root file with global defaults."

**Pattern 3** (index-focused):
> "## Precedence & Scoped Files  
> Nearest AGENTS.md wins. Use this root for defaults only."

### 5. Docker-First vs Native-First

**Docker-first projects** (ldap-selfservice-password-changer, ldap-manager):
```markdown
### Setup
**Prerequisites**: Docker + Docker Compose (required), Go 1.25+, Node.js 24+, pnpm 10.18+ (for native dev)

# Docker (recommended)
docker compose --profile dev up

# Native development
pnpm install
```

**Native-first projects** (simple-ldap-go, t3x-rte_ckeditor_image):
```markdown
### Setup
**Prerequisites**: Go 1.24, golangci-lint

# Install
go mod download
```

### 6. Language-Specific Patterns

**Go Projects** (simple-ldap-go, ldap-manager, raybeam):
- Minimal pre-commit: `go build -v ./...`, `gofmt -w`, `go test -short`
- Go version in global rules (1.24, 1.25)
- golangci-lint for comprehensive checks

**PHP Project** (t3x-rte_ckeditor_image):
- Composer scripts for CI pipeline
- PHPStan + PHP-CS-Fixer + Rector
- Make targets preferred over composer commands

**Hybrid Projects** (ldap-selfservice-password-changer):
- Separate sections for Go backend vs TypeScript frontend
- Scoped AGENTS.md for `internal/` (Go) and `internal/web/` (TS)
- pnpm for package management (strict version)

### 7. Quick Start Patterns

**Best practice** (ldap-selfservice-password-changer):
```markdown
## Quick Navigation
- [internal/AGENTS.md](internal/AGENTS.md) - Go backend services
- [internal/web/AGENTS.md](internal/web/AGENTS.md) - TypeScript frontend
```

**Alternative** (simple-ldap-go):
```markdown
## Index of scoped AGENTS.md
- `./examples/AGENTS.md` — Example applications and usage patterns
- `./testutil/AGENTS.md` — Testing utilities and container management
```

### 8. House Rules Implementation

**Global defaults** typically include:
- Commits: Conventional Commits, small PRs (~≤300 LOC)
- Type-safety: Strict types when supported
- SOLID, KISS, DRY, YAGNI principles
- SemVer for versioning
- No secrets in VCS
- Structured logging
- WCAG AA for UI projects

**Scoped overrides** (rare):
- Different test coverage targets per module
- Module-specific commit conventions
- Technology-specific style guides

### 9. Common Gaps Across Projects

❌ **Missing .envrc** in most projects (your prompt requires it)
❌ **Missing .editorconfig** in some projects
❌ **Husky + commitlint** not universally adopted
❌ **lint-staged** not implemented in older projects
❌ **CI parity section** often missing (should reference GitHub Actions)

## Recommendations for Your Skill

### Essential Features

1. **Template Selection**:
   - Thin root (simple-ldap-go style) ⭐
   - Verbose root (ldap-selfservice-password-changer style)
   - Auto-detect based on project size

2. **Project Type Detection**:
   - Go: Look for `go.mod`, detect version from `go.mod` directive
   - PHP: Look for `composer.json`, detect TYPO3 from dependencies
   - TypeScript: Look for `tsconfig.json`, detect strict mode
   - Hybrid: Detect multiple languages, recommend scoped files

3. **Scoped File Generation**:
   - **Required scopes**: backend/, frontend/, internal/
   - **Optional scopes**: cmd/, scripts/, examples/, docs/, testutil/
   - **Auto-create** if directory exists and has ≥5 files

4. **Content Extraction**:
   - **Makefile**: Extract targets with `##` comments → Build & Test Commands
   - **package.json scripts**: Extract npm/pnpm commands
   - **go.mod**: Extract Go version → Prerequisites
   - **composer.json scripts**: Extract PHP quality commands
   - **GitHub Actions**: Extract CI checks → PR/commit checklist

5. **Managed Header**:
   - Always add to new files
   - Preserve in existing files
   - Update timestamp on regeneration

6. **Precedence Rules**:
   - Auto-add "Nearest AGENTS.md wins" statement
   - Generate index of scoped files in root
   - Link from root to scoped files

### Skill Structure Recommendation

```
agents-skill/
├── SKILL.md
├── README.md
├── templates/
│   ├── root-thin.md          # simple-ldap-go style (recommended)
│   ├── root-verbose.md       # ldap-selfservice style
│   ├── scoped-backend.md     # Go/PHP backend
│   ├── scoped-frontend.md    # TypeScript/JS frontend
│   ├── scoped-cli.md         # CLI tools
│   ├── scoped-docs.md        # Documentation
│   ├── scoped-tests.md       # Testing utilities
│   └── sections/             # Modular sections
│       ├── header.md         # Managed header template
│       ├── precedence.md     # Precedence statement
│       ├── setup.md          # Setup section
│       ├── build-commands.md # Build & test commands
│       ├── code-style.md     # Code style guidelines
│       ├── security.md       # Security practices
│       ├── pr-checklist.md   # PR/commit checklist
│       ├── examples.md       # Good vs bad examples
│       └── when-stuck.md     # When stuck guidance
├── scripts/
│   ├── generate-agents.sh    # Main generator
│   ├── detect-project.sh     # Auto-detect project type
│   ├── extract-commands.sh   # Extract from Makefile/package.json
│   └── validate-structure.sh # Validate generated files
└── references/
    ├── examples/             # Real-world examples
    │   ├── go-library.md     # simple-ldap-go
    │   ├── go-web-app.md     # ldap-manager
    │   ├── php-typo3.md      # t3x-rte_ckeditor_image
    │   └── hybrid-app.md     # ldap-selfservice-password-changer
    └── best-practices.md     # AGENTS.md writing guide
```

### Key Differentiators

✅ **Thin root by default** (not verbose like some projects)
✅ **Auto-scope detection** (create scoped files when needed)
✅ **Command extraction** (don't make user write commands manually)
✅ **Managed header** (mark files as agent-maintained)
✅ **Language-agnostic** (works with Go, PHP, TypeScript, Python, etc.)
✅ **Idempotent** (can be re-run without breaking existing structure)

## Sample Output Comparison

### Your Prompt's Expected Output

**Root AGENTS.md** (following simple-ldap-go pattern):
```markdown
<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: 2025-10-18 -->

# AGENTS.md (root)

**Precedence:** The **closest AGENTS.md** to changed files wins. Root holds global defaults only.

## Global rules
- Keep PRs small (~≤300 net LOC)
- Conventional Commits: type(scope): subject
- Ask before: heavy deps, full e2e, repo rewrites
- Never commit secrets or PII

## Minimal pre-commit checks
- Typecheck: [auto-detected command]
- Lint: [auto-detected command]
- Format: [auto-detected command]
- Tests: [auto-detected command]

## Index of scoped AGENTS.md
- `./internal/AGENTS.md` — Go backend services
- `./internal/web/AGENTS.md` — TypeScript frontend

## When instructions conflict
Nearest AGENTS.md wins. User prompts override files.
```

**Scoped AGENTS.md** (e.g., internal/AGENTS.md):
```markdown
<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: 2025-10-18 -->

# AGENTS.md — Backend Services

## Overview
[Auto-generated description of internal/ directory purpose]

## Setup & environment
[Auto-detected from go.mod, .env.example]

## Build & tests (prefer file-scoped)
[Auto-extracted from Makefile, go commands]

## Code style & conventions
[Auto-detected from golangci-lint config, gofmt]

## Security & safety
[Standard Go security practices + project-specific]

## PR/commit checklist
[Auto-extracted from GitHub Actions, Makefile]

## Good vs. bad examples
[Template with placeholders to fill]

## When stuck
- Check root AGENTS.md for global rules
- Review sibling modules for patterns
```

