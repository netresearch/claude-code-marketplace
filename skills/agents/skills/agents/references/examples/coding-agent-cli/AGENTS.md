<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: 2025-10-09 -->

# AI CLI Preparation - Agent Guide (Root)

**Thin root file**: See scoped AGENTS.md files for specific areas.

## Precedence & Scoped Files

This root AGENTS.md provides global defaults. **Nearest AGENTS.md wins** for specific rules.

**Scoped files:**
- [scripts/AGENTS.md](scripts/AGENTS.md) - Shell installation scripts

## Overview

AI CLI Preparation is an environment audit tool ensuring AI coding agents (like Claude Code) have access to necessary developer tools. It detects 50+ tools, reports versions, and provides installation guidance.

**Architecture:**
- **Phase 1 (Complete)**: Tool detection, version auditing, offline-first caching
- **Phase 2 (Planned)**: Context-aware installation/upgrade management (see [docs/PRD.md](docs/PRD.md))

**Tech Stack:**
- Python 3.10+ (standard library only, no external deps for core)
- Make for task automation
- Shell scripts (Bash) for installation
- JSON for caching (latest_versions.json, tools_snapshot.json)

**Key Files:**
- `cli_audit.py` (2,375 lines): Main audit engine, 50+ tool definitions
- `smart_column.py`: ANSI/emoji-aware table formatting
- `scripts/`: 13+ installation scripts (install/update/uninstall/reconcile)
- `docs/`: Comprehensive technical documentation (12 files, 189KB)

## Setup

**Requirements:**
- Python 3.10+ (Python 3.14.0rc2 tested)
- Standard library only (no pip install needed for core)
- Optional: pyflakes for linting

**First-time setup:**
```bash
# Allow direnv (if using)
direnv allow

# Show available commands
make help

# Update snapshot (requires network)
make update

# Run audit from snapshot (fast, offline-capable)
make audit
```

**Environment variables:**
```bash
# See .env.default for all options
CLI_AUDIT_COLLECT=1      # Collect-only mode (write snapshot)
CLI_AUDIT_RENDER=1       # Render-only mode (read snapshot)
CLI_AUDIT_OFFLINE=1      # Offline mode (manual cache only)
CLI_AUDIT_DEBUG=1        # Debug output
CLI_AUDIT_JSON=1         # JSON output
```

## Build & Tests

**Primary commands:**
```bash
make audit               # Render from snapshot (no network, <100ms)
make update              # Collect fresh data, write snapshot (~10s)
make audit-offline       # Offline audit with hints
make lint                # Run pyflakes (if installed)
make upgrade             # Interactive upgrade guide
```

**Single tool audit:**
```bash
make audit-ripgrep       # Audit specific tool
make audit-offline-python-core  # Role-based preset
```

**Installation scripts:**
```bash
make install-python      # Install Python toolchain (uv)
make install-node        # Install Node.js (nvm)
make install-core        # Install core tools (fd, fzf, ripgrep, jq, etc.)
```

**Testing:**
```bash
# Smoke test (verifies table output and JSON format)
./scripts/test_smoke.sh

# Test single tool detection
CLI_AUDIT_DEBUG=1 python3 cli_audit.py --only ripgrep

# Validate snapshot
jq '.__meta__' tools_snapshot.json
```

**No formal test suite yet** - README acknowledges: "currently ships without tests"
- Smoke tests exist (test_smoke.sh)
- Manual validation workflows documented

## Code Style

**Python:**
- PEP 8 style (4-space indent, snake_case)
- Type hints used (`from __future__ import annotations`)
- Frozen dataclasses for immutability (`@dataclass(frozen=True)`)
- Docstrings minimal (focus on inline comments)

**Formatting:**
- EditorConfig enforced: LF, UTF-8, 4 spaces, trim trailing whitespace
- No auto-formatter configured (manual formatting)
- Lint via pyflakes: `make lint`

**Shell scripts:**
- Bash with `set -euo pipefail`
- Shellcheck-compliant (best effort)
- Consistent error handling (see scripts/lib/)

**Conventions:**
- File paths: Absolute paths, no auto-commit
- Functions: Snake_case, descriptive names
- Constants: UPPER_CASE (e.g., MANUAL_LOCK, HINTS_LOCK)
- Lock ordering: MANUAL_LOCK → HINTS_LOCK (enforced for safety)

## Security

**Secrets:**
- No secrets in VCS
- GITHUB_TOKEN optional (for GitHub API rate limit increase)
- Set via environment: `export GITHUB_TOKEN=ghp_...`

**Network:**
- HTTPS-only for upstream queries
- Retry logic with exponential backoff
- Per-origin rate limits (GitHub: 5/min, PyPI: 10/min, crates.io: 5/min)
- Timeout enforcement (default: 3s, configurable)

**Input validation:**
- Tool names validated against TOOLS registry
- Version strings sanitized (extract_version_number)
- Subprocess calls use lists, not shell=True (where possible)

**Caching:**
- Atomic file writes prevent corruption
- Offline-first design (committed latest_versions.json)
- No arbitrary code execution (package manager commands only)

## PR/Commit Checklist

**Before commit:**
- [ ] Run `make lint` (pyflakes clean)
- [ ] Run `make audit` (verify snapshot renders)
- [ ] Test affected tool: `make audit-<tool>`
- [ ] Update docs if behavior changed (README.md, docs/, scripts/README.md)
- [ ] Add/update smoke test if new output format

**Commit messages:**
- Conventional Commits format: `type(scope): description`
- Examples:
  - `feat(audit): add snapshot-based collect/render modes`
  - `fix(locks): enforce MANUAL_LOCK→HINTS_LOCK ordering`
  - `docs(prd): add Phase 2 specifications and ADRs`
  - `chore(cache): update latest_versions.json`

**Pull requests:**
- Keep PRs small (~≤300 net LOC changed)
- Link to issue/ticket if exists
- Update CHANGELOG section in PR description
- Ensure CI passes (when added)

## Good vs Bad Examples

**Good: Atomic dataclass with type safety**
```python
@dataclass(frozen=True)
class Tool:
    name: str
    candidates: tuple[str, ...]
    source_kind: str  # gh|pypi|crates|npm|gnu|skip
    source_args: tuple[str, ...]
```

**Bad: Mutable dict with unclear types**
```python
# Don't do this
tool = {
    'name': 'ripgrep',
    'candidates': ['rg'],  # List instead of tuple
    'source': 'github',     # Unclear allowed values
}
```

**Good: Lock ordering enforcement**
```python
def update_manual_cache(tool: str, version: str) -> None:
    with MANUAL_LOCK:  # Acquire first
        with HINTS_LOCK:  # Then hints
            # Safe: consistent ordering prevents deadlock
```

**Bad: Lock ordering violation**
```python
def update_cache(tool: str) -> None:
    with HINTS_LOCK:    # Wrong order!
        with MANUAL_LOCK:
            # Deadlock risk
```

**Good: Parallel execution with isolation**
```python
with ThreadPoolExecutor(max_workers=16) as executor:
    futures = [executor.submit(audit_tool, tool) for tool in TOOLS]
    for future in as_completed(futures):
        result = future.result()  # Failures isolated
```

**Bad: Sequential execution**
```python
results = []
for tool in TOOLS:  # Slow: 50 tools * 3s = 150s
    results.append(audit_tool(tool))
```

## When Stuck

**Tool detection failing:**
1. Check PATH: `echo $PATH | tr ':' '\n'`
2. Debug single tool: `CLI_AUDIT_DEBUG=1 python3 cli_audit.py --only <tool>`
3. Check version flag: `<tool> --version` or `<tool> -v`
4. See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md#version-detection-failures)

**Network issues:**
1. Increase timeout: `CLI_AUDIT_TIMEOUT_SECONDS=10 make update`
2. More retries: `CLI_AUDIT_HTTP_RETRIES=5 make update`
3. Use offline mode: `make audit-offline`
4. See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md#network-timeout-issues)

**Cache corruption:**
1. Remove caches: `rm latest_versions.json tools_snapshot.json`
2. Regenerate: `make update`

**Installation script fails:**
1. Check permissions: `make scripts-perms`
2. Debug script: `bash -x ./scripts/install_<tool>.sh`
3. See [scripts/README.md](scripts/README.md) for per-script troubleshooting

**Documentation:**
- Start with [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) for one-liners
- See [docs/INDEX.md](docs/INDEX.md) for navigation by role/task
- Architecture details: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- API reference: [docs/API_REFERENCE.md](docs/API_REFERENCE.md)

## House Rules

**Defaults** (override in scoped AGENTS.md if needed):

**Commits:**
- Atomic commits (single logical change)
- Conventional Commits: `type(scope): description`
- Keep PRs small (~≤300 net LOC changed)
- Ticket IDs in commits/PRs if exists

**Type-safety:**
- Use type hints (`from __future__ import annotations`)
- Frozen dataclasses for immutability
- No `Any` unless truly dynamic

**Design principles:**
- SOLID, KISS, DRY, YAGNI
- Composition > Inheritance
- Law of Demeter (minimal coupling)

**Dependencies:**
- Standard library preferred (no external Python deps for core)
- Latest stable versions when external deps needed
- Document why in Decision Log (ADRs for Phase 2)

**Security:**
- No secrets in VCS
- HTTPS-only for network calls
- No arbitrary code execution
- Input validation on external data

**Documentation currency:**
- Update docs in same PR as behavior changes
- No drift between code and docs
- Document non-obvious decisions in ADRs (see docs/adr/)

**Testing:**
- Aim for ≥80% coverage on changed code (when test suite added)
- Bugfixes use TDD: failing test first, then fix
- New code paths need tests (future requirement)

**Current status:**
- Phase 1: Production-ready detection/audit
- Phase 2: Planned installation/upgrade (see [docs/PRD.md](docs/PRD.md))
- No unit tests yet (acknowledged in README)

---

**Quick Start:** New to the project? Start with [README.md](README.md) → [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) → [docs/INDEX.md](docs/INDEX.md)

**Contributing:** See [docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md) for detailed contribution guide
