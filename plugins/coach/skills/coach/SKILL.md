---
name: coach
description: Self-improving learning system that detects friction signals and proposes rule updates. This skill should be used when Claude needs to learn from mistakes, when users repeatedly correct behavior, when tool failures indicate missing knowledge, or when reviewing learning candidates via /coach commands.
---

# Coach - Self-Improving Learning System

Coach enables Claude to learn from friction and improve over time. It detects learning opportunities (user corrections, repeated instructions, tool failures, tone escalation), extracts actionable improvement candidates, and proposes changes requiring explicit user approval.

**Core Principle**: No silent writes. All improvements require user approval via `/coach approve`.

## Activation Triggers

Activate this skill when:
- User corrects Claude's behavior ("no", "stop", "don't", "I said", "you didn't")
- Same instruction is repeated within recent turns
- Tool/command failures occur (non-zero exit, stderr patterns)
- Tone escalation detected (ALL CAPS, "!!!", "for the last time")
- User explicitly requests `/coach` commands
- Session end triggers batch review of accumulated signals

## Signal Categories (Priority Order)

1. **COMMAND_FAILURE** (Highest) - Non-zero exit codes, stderr error patterns
2. **USER_CORRECTION** (High) - Explicit correction language
3. **REPETITION** (Medium) - Semantically similar instruction repeated
4. **TONE_ESCALATION** (Low) - Frustration indicators (triggers review, not rule)

## Candidate Types

| Type | Description | Example |
|------|-------------|---------|
| `rule` | Stable constraint | "Never edit generated files" |
| `checklist` | Workflow step | "Run tests after code change" |
| `snippet` | Repeatable command | "Preflight check script" |
| `antipattern` | Things to never do | "Never assume tool exists" |

## Workflow Summary

1. **Signal Detection** - Hooks capture friction events → stored in `~/.claude-coach/events.sqlite`
2. **Candidate Generation** - Aggregate signals into proposals with fingerprints for deduplication
3. **Scope Decision** - Determine project vs global scope based on path/language patterns
4. **Proposal Review** - User reviews via `/coach review`, approves/rejects/edits
5. **Application** - Approved rules added to CLAUDE.md (project or global)

## File Locations

```
~/.claude-coach/
├── events.sqlite      # Raw friction events
├── candidates.json    # Pending proposals
└── ledger.sqlite      # Cross-repo fingerprints

~/.claude/ or <repo>/.claude/
├── CLAUDE.md          # Rules destination
├── checklists/        # Workflow checklists
└── snippets/          # Reusable commands
```

## Scripts

Execute from `${CLAUDE_PLUGIN_ROOT}/scripts/`:

| Script | Purpose |
|--------|---------|
| `init_coach.py` | Initialize coach system |
| `detect_signals.py` | Pattern detection for friction |
| `aggregate.py` | Turn signals into candidates |
| `apply.py` | Apply approved proposals |

For detailed architecture, schemas, and patterns, see `references/` directory.
