# AGENTS.md Skill Improvement Roadmap

> **Status:** Draft v1.0
> **Created:** 2026-01-14
> **Reference:** [agents.md Specification](https://agents.md/)

## Executive Summary

This roadmap outlines improvements to make the agents-skill fully compliant with the [agents.md specification](https://agents.md/) and incorporate best practices from the [GitHub analysis of 2,500+ repositories](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/).

---

## Current State Analysis

### What the Skill Currently Scans

| Category | Files Scanned | Data Extracted |
|----------|--------------|----------------|
| **Language Detection** | `go.mod`, `composer.json`, `package.json`, `pyproject.toml` | Language, version, framework |
| **Build Tools** | Makefile, package.json scripts, composer.json scripts | lint, test, build, format, dev commands |
| **Quality Tools** | `.golangci.yml`, `phpstan.neon`, etc. | Tool presence (boolean only) |
| **CI/CD** | `.github/workflows/`, `.gitlab-ci.yml`, `.circleci/` | CI system name only |
| **Docker** | `Dockerfile`, `docker-compose.yml` | Boolean presence only |
| **Directory Structure** | `src/`, `internal/`, `cmd/`, `Classes/`, etc. | File counts for scoping |

### Critical Gaps

| Gap | Impact | agents.md Best Practice |
|-----|--------|------------------------|
| No README/docs parsing | Misses project description, purpose, architecture | "Project overview and context" |
| No git history analysis | Misses commit conventions, PR patterns | "Git workflow guidelines" |
| No .github/.gitlab content parsing | Misses PR templates, CODEOWNERS, issue templates | "Boundaries - clear constraints" |
| No security file detection | Misses SECURITY.md, .snyk, dependabot.yml | "Security considerations" |
| No CONTRIBUTING.md parsing | Misses existing contribution rules | "Code style guidelines" |
| No IDE settings scanning | Misses shared team configurations | "Development environment" |
| No AI agent config scanning | Misses existing agent instructions | "Agent-specific context" |
| No tool config deep parsing | Only checks presence, not actual settings | Specific rules extraction |
| No extraction summary output | User doesn't know what was found/why | Transparency/debugging |
| No agents.md spec reference | Missing official standard link | Standard compliance |
| Old Docker Compose naming | Only checks `docker-compose.yml`, not `compose.yml` | Modern conventions |

---

## agents.md Specification Requirements

### Six Core Areas (from GitHub Blog Analysis)

1. **Commands** - Executable tools with full flags and options
2. **Testing** - Framework-specific approaches and patterns
3. **Project structure** - Exact file locations and purposes
4. **Code style** - Real examples showing good output
5. **Git workflow** - Commit and collaboration guidelines
6. **Boundaries** - Clear constraints using three-tier system

### Three-Tier Boundaries Pattern

```markdown
## Boundaries

### Always Do
- Run tests before committing
- Use conventional commit format
- Add type annotations to new code

### Ask First
- Adding new dependencies
- Modifying CI/CD configuration
- Changing public API signatures

### Never Do
- Commit secrets or credentials
- Modify vendor/ or node_modules/
- Push directly to main branch
- Delete migration files
```

---

## Improvement Plan

### Phase 0: Immediate Fixes (P0)

#### 0.1 Add agents.md Specification Link
- **File:** `README.md`
- **Change:** Add reference to https://agents.md/
- **Effort:** 5 minutes

#### 0.2 Fix Docker Compose Detection
- **File:** `scripts/detect-project.sh`
- **Change:** Check both `docker-compose.yml` AND `compose.yml`
- **Effort:** 5 minutes

#### 0.3 Add Extraction Summary Output
- **File:** `scripts/generate-agents.sh`
- **Change:** Print summary of what was detected and sources
- **Format:**
  ```
  === Extraction Summary ===
  Language: python (from pyproject.toml)
  Version: >=3.14 (from pyproject.toml:requires-python)
  Framework: none
  Build tool: pip

  Commands extracted:
  - lint: ruff check . (from pyproject.toml:[tool.ruff])
  - test: pytest (from pyproject.toml:dependencies)
  - format: black . (from pyproject.toml:[tool.black])

  Scopes detected:
  - cli_audit/ (20 Python files)
  - tests/ (12 test files)
  - docs/ (31 documentation files)

  Files scanned: 15
  Rules extracted: 23
  ```
- **Effort:** 2 hours

---

### Phase 1: Documentation Parsing (P1)

#### 1.1 Create `extract-documentation.sh`
Parse existing documentation for context:

| File | Extract |
|------|---------|
| `README.md` | Project description, badges, architecture section |
| `CONTRIBUTING.md` | Contribution rules, PR process, code style |
| `SECURITY.md` | Security reporting, vulnerability policy |
| `CHANGELOG.md` | Version history pattern, release notes format |
| `CODE_OF_CONDUCT.md` | Community guidelines |

#### 1.2 Create `extract-platform-files.sh`
Parse platform-specific configurations:

| Directory/File | Extract |
|----------------|---------|
| `.github/PULL_REQUEST_TEMPLATE.md` | PR checklist items |
| `.github/ISSUE_TEMPLATE/*.md` | Issue patterns, required fields |
| `.github/CODEOWNERS` | Ownership boundaries, review requirements |
| `.github/dependabot.yml` | Dependency update policy |
| `.github/FUNDING.yml` | Sponsorship info |
| `.gitlab/merge_request_templates/` | MR templates |
| `.gitlab/issue_templates/` | Issue templates |

#### 1.3 Create `extract-ide-settings.sh`
Parse IDE and editor configurations:

| Directory/File | Extract |
|----------------|---------|
| `.editorconfig` | Indent style, line endings, charset, line length |
| `.vscode/settings.json` | Workspace settings, formatters |
| `.vscode/extensions.json` | Recommended extensions |
| `.vscode/launch.json` | Debug configurations |
| `.idea/` or `.phpstorm/` | JetBrains settings |
| `.idea/codeStyles/` | Code style settings |
| `.idea/inspectionProfiles/` | Inspection settings |

#### 1.4 Create `extract-agent-configs.sh`
Parse existing AI agent configurations:

| Directory/File | Extract |
|----------------|---------|
| `.cursor/rules` | Cursor AI rules |
| `.cursor/settings.json` | Cursor settings |
| `.claude/settings.json` | Claude Code settings |
| `.claude/CLAUDE.md` | Claude instructions |
| `CLAUDE.md` (root) | Claude instructions |
| `.windsurf/` | Windsurf AI config |
| `.aider/` | Aider config |
| `.continue/` | Continue config |
| `copilot-instructions.md` | GitHub Copilot instructions |
| `.github/copilot-instructions.md` | GitHub Copilot instructions |

---

### Phase 2: Deep Config Parsing (P2)

#### 2.1 Enhance `extract-commands.sh`
Extract actual settings, not just presence:

| Config File | Extract |
|-------------|---------|
| `.golangci.yml` | Enabled linters, disabled rules, line length |
| `phpstan.neon` | Level, paths, ignored errors |
| `phpcs.xml` | Coding standard, excluded paths |
| `.php-cs-fixer.php` | Rules, risky settings |
| `eslint.config.js` / `.eslintrc.*` | Rules, extends, plugins |
| `prettier.config.*` / `.prettierrc` | Print width, tabs vs spaces |
| `tsconfig.json` | Strict mode, target, paths |
| `ruff.toml` / `pyproject.toml[tool.ruff]` | Line length, select/ignore rules |
| `mypy.ini` / `pyproject.toml[tool.mypy]` | Strict mode, plugins |
| `.flake8` / `setup.cfg` | Max line length, ignored codes |

#### 2.2 Create `extract-ci-commands.sh`
Parse CI workflow files for actual commands:

| File Pattern | Extract |
|--------------|---------|
| `.github/workflows/*.yml` | Run commands, matrix, required checks |
| `.gitlab-ci.yml` | Script commands, stages, rules |
| `.circleci/config.yml` | Run steps, orbs |
| `Jenkinsfile` | Stage commands |
| `.travis.yml` | Script commands |
| `azure-pipelines.yml` | Script steps |
| `bitbucket-pipelines.yml` | Script commands |

---

### Phase 3: Git History Analysis (P3)

#### 3.1 Create `analyze-git-history.sh`
Analyze repository history for patterns:

| Analysis | Method |
|----------|--------|
| Commit message convention | Sample last 100 commits, detect patterns |
| Common prefixes | `feat:`, `fix:`, `chore:`, `[TAG]`, etc. |
| PR title patterns | Via `gh` CLI if available |
| Branch naming | Sample recent branches |
| Merge strategy | Detect squash vs merge commits |
| Release tagging | Analyze tag patterns (semver, etc.) |

#### 3.2 Commit Convention Detection
```bash
# Detect conventional commits
git log --oneline -100 | grep -E '^[a-f0-9]+ (feat|fix|docs|style|refactor|test|chore)(\(.+\))?:'

# Detect [TAG] style
git log --oneline -100 | grep -E '^\[.+\]'

# Detect ticket references
git log --oneline -100 | grep -Ei '(JIRA|ISSUE|#[0-9]+)'
```

---

### Phase 4: Template Enhancements (P4)

#### 4.1 Add Boundaries Section to Templates
All templates should include the three-tier boundaries pattern:

```markdown
## Boundaries

### Always Do
{{ALWAYS_DO}}

### Ask First
{{ASK_FIRST}}

### Never Do
{{NEVER_DO}}
```

#### 4.2 Add Code Examples Section
Templates should include before/after examples:

```markdown
## Code Examples

### Good Pattern
{{GOOD_EXAMPLE}}

### Avoid
{{BAD_EXAMPLE}}
```

#### 4.3 Language-Specific Defaults

| Language | Always Do | Ask First | Never Do |
|----------|-----------|-----------|----------|
| **Go** | Run `go fmt`, use `golangci-lint` | Add dependencies to go.mod | Commit vendor/ |
| **PHP** | Run php-cs-fixer, use PSR-12 | Modify composer.lock | Commit vendor/ |
| **TypeScript** | Run eslint/prettier, use strict mode | Add npm dependencies | Commit node_modules/ |
| **Python** | Run ruff/black, use type hints | Add to requirements | Commit .venv/ |

---

## Implementation Priority Matrix

| ID | Feature | Effort | Value | Priority | Status |
|----|---------|--------|-------|----------|--------|
| 0.1 | Add agents.md spec link | Very Low | Medium | **P0** | ✅ DONE |
| 0.2 | Fix Docker Compose detection | Very Low | Low | **P0** | ✅ DONE |
| 0.3 | Add extraction summary | Low | High | **P0** | ✅ DONE |
| 1.1 | Parse README/CONTRIBUTING | Medium | High | **P1** | ✅ DONE |
| 1.2 | Parse .github/ templates | Medium | High | **P1** | ✅ DONE |
| 1.3 | Parse IDE settings | Medium | Medium | **P1** | ✅ DONE |
| 1.4 | Parse AI agent configs | Medium | High | **P1** | ✅ DONE |
| 2.1 | Deep config parsing | High | High | **P2** | ✅ DONE |
| 2.2 | CI workflow extraction | Medium | Medium | **P2** | ✅ DONE |
| 3.1 | Git history analysis | High | Medium | **P3** | ✅ DONE |
| 3.2 | Commit convention detection | Medium | Medium | **P3** | ✅ DONE (part of 3.1) |
| 4.1 | Boundaries in templates | Low | High | **P4** | ✅ DONE |
| 4.2 | Code examples in templates | Medium | High | **P4** | ✅ DONE |

---

## New Script Structure

```
scripts/
├── generate-agents.sh          # Main generator (enhanced with summary)
├── validate-structure.sh       # Structure validation (enhanced with freshness)
├── check-freshness.sh          # Freshness check (NEW)
├── detect-project.sh           # Project detection (enhanced: IDE + agent configs)
├── detect-scopes.sh            # Scope detection (existing)
├── extract-commands.sh         # Command extraction (existing)
├── extract-documentation.sh    # Parse README, CONTRIBUTING, etc. (NEW)
├── extract-platform-files.sh   # Parse .github/, .gitlab/, etc. (NEW)
├── extract-ide-settings.sh     # Parse .vscode/, .idea/, .editorconfig (NEW)
├── extract-agent-configs.sh    # Parse .cursor/, .claude/, .windsurf/ (NEW)
├── extract-quality-configs.sh  # Deep parse linter/formatter configs (NEW)
├── extract-ci-commands.sh      # Parse CI workflow files (NEW)
├── analyze-git-history.sh      # Analyze commit patterns (NEW)
└── lib/
    ├── template.sh             # Template rendering (existing)
    └── summary.sh              # Summary output formatting (NEW)
```

---

## Success Metrics

| Metric | Before | After P1 | Target |
|--------|--------|----------|--------|
| Config files scanned | 8 | 20+ | 30+ |
| Data points extracted | ~15 | 40+ | 50+ |
| Documentation files parsed | 0 | 5 (README, CONTRIBUTING, SECURITY, CHANGELOG, CODE_OF_CONDUCT) | 5+ |
| Platform files parsed | 0 | 8 (PR templates, issue templates, CODEOWNERS, dependabot, renovate, FUNDING) | 10+ |
| IDE configs parsed | 0 | 7 (editorconfig, vscode, idea, phpstorm, fleet, vim, neovim) | 10+ |
| Agent configs parsed | 0 | 9 (cursor, claude, copilot, windsurf, aider, continue, codeium, tabnine, cody) | 10+ |
| Extraction summary | None | Full report with verbose mode | Full report |
| agents.md spec compliance | Partial | Improved | Full |

---

## References

- [agents.md Official Specification](https://agents.md/)
- [How to write a great agents.md - GitHub Blog](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
- [agentsmd/agents.md Repository](https://github.com/agentsmd/agents.md)
- [GitHub spec-kit AGENTS.md Example](https://github.com/github/spec-kit/blob/main/AGENTS.md)
- [Agentic AI Foundation](https://agents.md/) (Linux Foundation)

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-14 | 1.0 | Initial roadmap created |
| 2026-01-14 | 1.1 | Completed P0 and P1: Added extraction summary, documentation/platform/IDE/agent extractors |
| 2026-01-14 | 1.2 | Completed P2-P4: Deep config parsing, CI extraction, git history analysis, boundaries, code examples |
