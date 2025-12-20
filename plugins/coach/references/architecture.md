# Coach Architecture

## Signal Collection Layer

Hooks capture friction signals without MCP dependency:

```
Signal Sources:
├── UserPromptSubmit    → Detect corrections, repetition, tone
├── PostToolUse (Bash)  → Capture exit codes, stderr patterns
└── Stop                → Session-end aggregation & transcript analysis
```

## Signal Processing Pipeline

### 1. Signal Detection (detect_signals.py)

When friction signal detected:

```python
signal = {
    "type": "USER_CORRECTION",
    "content": "I said don't edit generated files",
    "timestamp": "2024-01-15T10:30:00Z",
    "context": {"file": "generated/api.ts", "action": "edit"},
    "preceding_context": {
        "recent_tool_calls": [...],
        "recent_messages": [...],
        "recent_actions": [...]
    }
}
# Stored in ~/.claude-coach/events.sqlite
```

### 2. Candidate Generation (aggregate.py)

Aggregate signals into learning candidates:

```python
candidate = {
    "id": "uuid",
    "fingerprint": "sha256_hash",
    "title": "Avoid editing generated files",
    "candidate_type": "rule",
    "trigger": "when editing files in generated/ directories",
    "action": "regenerate from source instead; patch source if needed",
    "evidence": [{"event_id": "...", "quote": "don't edit generated"}],
    "confidence": 0.85,
    "status": "pending"
}
```

### 3. Scope Decision (scope_analyzer.py)

**Project-Specific Indicators** (+project score):
- Paths unique to repo (`apps/storefront`, `.platform.app.yaml`)
- Domain language (client names, business terms)
- Repo-pinned tooling (`pnpm -C packages/foo`)

**Global Indicators** (+global score):
- Universal behaviors ("run tests", "small PRs")
- Cross-repo tooling (git, docker, node)
- Matches existing global patterns

**Decision Rules**:
1. If similar rule exists globally → update global (dedupe)
2. If similar rule exists only in project → update project
3. If new and ambiguous → default to project
4. If same candidate in 2+ repos → propose promotion

### 4. Proposal Application (apply.py)

Target locations:
- Project: `<repo>/.claude/CLAUDE.md`
- Global: `~/.claude/CLAUDE.md`

## Cross-Repo Learning

### Fingerprinting (fingerprint.py)

Generate stable fingerprints for deduplication:

1. Extract: candidate_type + trigger + action
2. Normalize: lowercase, strip punctuation, replace paths with `<PATH>`
3. Hash: sha256(normalized_string)

### Ledger (ledger.py)

Track fingerprints across repos:

```sql
CREATE TABLE candidates (
    fingerprint TEXT PRIMARY KEY,
    normalized_text TEXT,
    candidate_type TEXT,
    current_scope TEXT,
    repo_ids TEXT,  -- JSON array
    count INTEGER,
    status TEXT
);
```

## Guardrails

| Rule | Rationale |
|------|-----------|
| Batch proposals (max 1 interrupt/15min) | Avoid spam |
| Require evidence >= 2 (except hard failures) | Reduce noise |
| Never rule from tone alone | Tone → review only |
| Rules must have triggers ("when X, do Y") | Actionable only |
| Auto-dedupe before proposing | No duplicates |
| All proposals require approval | User control |

## LLM-Assisted Generation

When `ANTHROPIC_API_KEY` is available, uses Claude Haiku to:
- Generate specific candidates from failure context
- Understand what was being corrected
- Filter vague/unhelpful candidates

## Transcript Analysis

At session end, analyzes the full transcript for:
- Correction sequences with intensity scoring
- Repeated concerning commands (gh pr, git push, etc.)
- Implicit corrections (user providing solutions)
