---
name: agents
description: "Agent Skill: Generate and maintain AGENTS.md files following the public agents.md convention. Use when creating AI agent documentation, onboarding guides, or standardizing agent patterns. By Netresearch."
---

# AGENTS.md Generator Skill

Generate and maintain AGENTS.md files following the public agents.md convention.

## When to Use This Skill

When creating new projects, use this skill to establish baseline AGENTS.md structure.

When standardizing existing projects, use this skill to generate consistent agent documentation.

When ensuring multi-repo consistency, use this skill to apply the same standards across repositories.

## Capabilities

- **Thin root files** (~30 lines) with precedence rules and global defaults
- **Scoped files** for subsystems (backend/, frontend/, internal/, cmd/)
- **Auto-extracted commands** from Makefile, package.json, composer.json, go.mod
- **Language-specific templates** for Go, PHP, TypeScript, Python, hybrid projects

## Running Scripts

### Generating AGENTS.md Files

To generate AGENTS.md files for a project:

```bash
scripts/generate-agents.sh /path/to/project
```

Options:
- `--dry-run` - Preview changes without writing files
- `--verbose` - Show detailed output
- `--style=thin` - Use thin root template (~30 lines, default)
- `--style=verbose` - Use verbose root template (~100-200 lines)
- `--update` - Update existing files only

### Validating Structure

To validate AGENTS.md structure compliance:

```bash
scripts/validate-structure.sh /path/to/project
```

### Detecting Project Type

To detect project language, version, and build tools:

```bash
scripts/detect-project.sh /path/to/project
```

### Detecting Scopes

To identify directories that should have scoped AGENTS.md files:

```bash
scripts/detect-scopes.sh /path/to/project
```

### Extracting Commands

To extract build commands from Makefile, package.json, composer.json, or go.mod:

```bash
scripts/extract-commands.sh /path/to/project
```

## Using Reference Documentation

### AGENTS.md Analysis

When understanding best practices and patterns, consult `references/analysis.md` for analysis of 21 real-world AGENTS.md files.

### Directory Coverage

When determining which directories need AGENTS.md files, consult `references/directory-coverage.md` for guidance on PHP/TYPO3, Go, and TypeScript project structures.

### Real-World Examples

When needing concrete examples of AGENTS.md files, consult `references/examples/`:

| Project | Files | Description |
|---------|-------|-------------|
| `coding-agent-cli/` | Root + scripts scope | CLI tool example |
| `ldap-selfservice/` | Root + internal scopes | Go web app with multiple scopes |
| `simple-ldap-go/` | Root + examples scope | Go library example |
| `t3x-rte-ckeditor-image/` | Root + Classes scope | TYPO3 extension example |

## Using Asset Templates

### Root Templates

When generating root AGENTS.md files, the scripts use these templates:

- `assets/root-thin.md` - Minimal root template (~30 lines) with precedence rules and scope index
- `assets/root-verbose.md` - Detailed root template (~100 lines) with architecture overview and examples

### Scoped Templates

When generating scoped AGENTS.md files, the scripts use language-specific templates:

- `assets/scoped/backend-go.md` - Go backend patterns (packages, error handling, testing)
- `assets/scoped/backend-php.md` - PHP backend patterns (PSR, DI, security)
- `assets/scoped/cli.md` - CLI patterns (flags, output, error codes)
- `assets/scoped/frontend-typescript.md` - TypeScript frontend patterns (components, state, testing)

## Supported Project Types

| Language | Project Types |
|----------|---------------|
| Go | Libraries, web apps (Fiber/Echo/Gin), CLI (Cobra/urfave) |
| PHP | Composer packages, TYPO3, Laravel/Symfony |
| TypeScript | React, Next.js, Vue, Node.js |
| Python | pip, poetry, Django, Flask, FastAPI |
| Hybrid | Multi-language projects (auto-creates scoped files per stack) |

## Output Structure

### Root File

Root AGENTS.md (~30 lines) contains:
- Precedence statement
- Global rules
- Pre-commit checks
- Scope index

### Scoped Files

Scoped AGENTS.md files contain 9 sections:
1. Overview
2. Setup
3. Build/tests
4. Code style
5. Security
6. PR checklist
7. Examples
8. When stuck
9. House Rules

## Directory Coverage

When creating AGENTS.md files, create them in ALL key directories:

| Directory | Purpose |
|-----------|---------|
| Root | Precedence, architecture overview |
| `Classes/` or `src/` | Source code patterns |
| `Configuration/` or `config/` | Framework config |
| `Documentation/` or `docs/` | Doc standards |
| `Resources/` or `assets/` | Templates, assets |
| `Tests/` | Testing patterns |

---

> **Contributing:** https://github.com/netresearch/agents-skill
