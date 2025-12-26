---
name: agents
description: "Agent Skill: Generate and maintain AGENTS.md files following the public agents.md convention. Use when creating AI agent documentation, onboarding guides, or standardizing agent patterns. By Netresearch."
---

# AGENTS.md Generator Skill

Generate and maintain AGENTS.md files following the public agents.md convention.

## What This Skill Does

- **Thin root files** (~30 lines) with precedence rules and global defaults
- **Scoped files** for subsystems (backend/, frontend/, internal/, cmd/)
- **Auto-extracted commands** from Makefile, package.json, composer.json, go.mod
- **Language-specific templates** for Go, PHP, TypeScript, Python, hybrid projects

## When to Use

- New projects: Establish baseline AGENTS.md structure
- Existing projects: Standardize agent documentation
- Multi-repo consistency: Apply same standards across repositories

## Commands

```bash
# Generate for current project
scripts/generate-agents.sh . [--dry-run] [--verbose]

# Template styles
scripts/generate-agents.sh . --style=thin    # Default, ~30 lines
scripts/generate-agents.sh . --style=verbose # ~100-200 lines

# Update existing / Validate
scripts/generate-agents.sh . --update
scripts/validate-structure.sh .
```

## Supported Projects

- **Go**: Libraries, web apps (Fiber/Echo/Gin), CLI (Cobra/urfave)
- **PHP**: Composer packages, TYPO3, Laravel/Symfony
- **TypeScript/JavaScript**: React, Next.js, Vue, Node.js
- **Python**: pip, poetry, Django, Flask, FastAPI
- **Hybrid**: Multi-language (auto-creates scoped files per stack)

## Output Structure

**Root** (thin, ~30 lines): Precedence statement, global rules, pre-commit checks, scope index

**Scoped files** (9 sections): Overview, Setup, Build/tests, Code style, Security, PR checklist, Examples, When stuck, House Rules

## References

- `references/analysis.md` - Analysis of 21 real AGENTS.md files
- `references/examples/` - Real-world AGENTS.md files
- `references/best-practices.md` - Writing guide

---

> **Contributing:** https://github.com/netresearch/agents-skill
