# Directory Coverage for AGENTS.md

Comprehensive AGENTS.md coverage means creating files in ALL key directories, not just root.

## Why Full Coverage Matters

- Each directory has unique patterns and conventions
- AI agents working in subdirectories benefit from local context
- Reduces need to navigate up to root AGENTS.md

## Standard Directory Structure

### PHP/TYPO3 Projects

| Directory | AGENTS.md Content |
|-----------|-------------------|
| Root | Project overview, precedence list, architecture diagram |
| `Classes/` | DI patterns, service layer, security rules |
| `Configuration/` | TCA, Services.yaml, module registration |
| `Documentation/` | RST standards, directives, rendering |
| `Resources/` | Templates, XLIFF, assets |
| `Tests/` | Unit/functional patterns, fixtures |
| `Tests/E2E/` | E2E-specific patterns (if exists) |

### Go Projects

| Directory | AGENTS.md Content |
|-----------|-------------------|
| Root | Module overview, build commands |
| `cmd/` | CLI entry points, flags |
| `internal/` | Private packages, no export |
| `pkg/` | Public API patterns |

### TypeScript/Node Projects

| Directory | AGENTS.md Content |
|-----------|-------------------|
| Root | Package overview, scripts |
| `src/` | Source patterns, imports |
| `components/` | UI component patterns |
| `tests/` or `__tests__/` | Testing patterns |

## Precedence Rules

Root AGENTS.md should list all child files:

```markdown
## Precedence

1. This file (root)
2. Directory-specific files:
   - `Classes/AGENTS.md`
   - `Configuration/AGENTS.md`
   - `Tests/AGENTS.md`
3. Framework standards
```

## Anti-pattern

**Wrong**: Only creating root AGENTS.md and Tests/AGENTS.md

**Right**: Create AGENTS.md in EVERY directory with unique patterns
