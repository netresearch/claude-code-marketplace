# Database Schema Reference

SQLite schemas for Coach system databases.

## Events Database (`~/.claude-coach/events.sqlite`)

Stores raw friction signals before aggregation.

### events table

```sql
CREATE TABLE events (
    id TEXT PRIMARY KEY,           -- UUID (8 chars)
    timestamp TEXT NOT NULL,       -- ISO 8601 timestamp
    event_type TEXT NOT NULL,      -- pre|post|tool
    signal_type TEXT,              -- COMMAND_FAILURE|USER_CORRECTION|REPETITION|TONE_ESCALATION
    repo_id TEXT,                  -- SHA256[:16] of repo URL
    content TEXT,                  -- Message/error content (truncated)
    context TEXT,                  -- JSON blob with additional data
    processed INTEGER DEFAULT 0,   -- 0=pending, 1=processed
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_events_timestamp ON events(timestamp);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_signal ON events(signal_type);
CREATE INDEX idx_events_processed ON events(processed);
```

### Event Context Schema (JSON)

```json
{
  "signal_type": "USER_CORRECTION",
  "matches": ["\\bno\\b", "\\bstop\\b"],
  "confidence": 0.7,
  "file": "path/to/file.ts",
  "action": "edit",
  "exit_code": 1,
  "stderr_preview": "error message...",
  "command": "npm test",
  "similar_count": 3,
  "similar_messages": ["...", "..."]
}
```

## Ledger Database (`~/.claude-coach/ledger.sqlite`)

Tracks candidates across repos for cross-repo learning.

### candidates table

```sql
CREATE TABLE candidates (
    fingerprint TEXT PRIMARY KEY,  -- SHA256 of normalized candidate
    normalized_text TEXT,          -- Normalized trigger + action
    title TEXT,                    -- Human-readable title
    candidate_type TEXT,           -- rule|checklist|snippet|skill|antipattern
    trigger_condition TEXT,        -- "When X happens"
    action TEXT,                   -- "Do Y"
    current_scope TEXT DEFAULT 'project',  -- project|global
    repo_ids TEXT DEFAULT '[]',    -- JSON array of repo hashes
    evidence TEXT DEFAULT '[]',    -- JSON array of evidence
    confidence REAL DEFAULT 0.0,   -- 0.0-1.0
    count INTEGER DEFAULT 1,       -- Times seen
    status TEXT DEFAULT 'pending', -- pending|approved|rejected|promoted
    first_seen TEXT,               -- ISO 8601
    last_seen TEXT,                -- ISO 8601
    promoted_at TEXT,              -- ISO 8601 (if promoted)
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_candidates_type ON candidates(candidate_type);
CREATE INDEX idx_candidates_scope ON candidates(current_scope);
CREATE INDEX idx_candidates_status ON candidates(status);
```

### promotions table

```sql
CREATE TABLE promotions (
    id TEXT PRIMARY KEY,           -- UUID (8 chars)
    fingerprint TEXT NOT NULL,     -- FK to candidates
    from_scope TEXT,               -- Original scope
    to_scope TEXT,                 -- New scope
    reason TEXT,                   -- Promotion reason
    promoted_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fingerprint) REFERENCES candidates(fingerprint)
);
```

## Candidates File (`~/.claude-coach/candidates.json`)

Working file for pending proposals.

```json
{
  "pending": [
    {
      "id": "a1b2c3d4",
      "fingerprint": "sha256...",
      "title": "Avoid editing generated files",
      "candidate_type": "rule",
      "trigger": "when editing files in generated/ directories",
      "action": "regenerate from source instead",
      "evidence": [
        {
          "event_id": "e1f2g3h4",
          "quote": "don't edit generated files",
          "timestamp": "2024-01-15T10:30:00Z"
        }
      ],
      "confidence": 0.85,
      "scope_guess": "project",
      "status": "pending",
      "created_at": "2024-01-15T10:35:00Z"
    }
  ],
  "approved": [],
  "rejected": [],
  "last_proposal": "2024-01-15T10:35:00Z"
}
```

## Config File (`~/.claude-coach/config.json`)

System configuration.

```json
{
  "version": "1.0.0",
  "batch_interval_minutes": 15,
  "min_evidence_count": 2,
  "promotion_threshold_repos": 2,
  "signal_patterns": {
    "correction": ["\\bno\\b", "\\bstop\\b", "\\bdon'?t\\b"],
    "escalation": ["[A-Z]{3,}", "!{2,}", "\\bagain\\b"],
    "failure_stderr": ["ENOENT", "ECONNREFUSED", "command not found"]
  },
  "scope_indicators": {
    "project": ["apps/", "packages/", ".platform."],
    "global": ["run tests", "git", "docker"]
  },
  "created_at": "2024-01-15T10:00:00Z"
}
```

## Fingerprint Schema

Stable identifier for candidate deduplication.

### Generation Algorithm
```
1. Input: candidate_type, trigger, action
2. Normalize:
   - Lowercase all text
   - Replace paths with <PATH>
   - Replace tool names with buckets
   - Strip punctuation
   - Collapse whitespace
3. Combine: "{type}|{normalized_trigger}|{normalized_action}"
4. Hash: SHA256(combined)
```

### Tool Buckets
```json
{
  "pytest|jest|mocha|vitest": "<TEST_RUNNER>",
  "npm|pnpm|yarn|pip|cargo": "<PKG_MANAGER>",
  "webpack|vite|esbuild": "<BUILD_TOOL>",
  "eslint|prettier|pylint": "<LINTER>"
}
```

## Query Examples

### Find multi-repo candidates
```sql
SELECT * FROM candidates
WHERE json_array_length(repo_ids) >= 2
AND status != 'promoted';
```

### Get promotion eligible
```sql
SELECT fingerprint, title, repo_ids, count
FROM candidates
WHERE status = 'pending'
AND json_array_length(repo_ids) >= 2
ORDER BY count DESC;
```

### Recent activity
```sql
SELECT * FROM events
WHERE date(timestamp) >= date('now', '-7 days')
ORDER BY timestamp DESC
LIMIT 100;
```

### Cleanup old rejected
```sql
DELETE FROM candidates
WHERE status = 'rejected'
AND date(last_seen) < date('now', '-90 days');
```
