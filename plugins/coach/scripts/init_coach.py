#!/usr/bin/env python3
"""
Initialize the Coach self-learning system.
Creates necessary directories and SQLite databases.
"""

import os
import sys
import sqlite3
import json
from pathlib import Path
from datetime import datetime

COACH_DIR = Path.home() / ".claude-coach"
EVENTS_DB = COACH_DIR / "events.sqlite"
LEDGER_DB = COACH_DIR / "ledger.sqlite"
CANDIDATES_FILE = COACH_DIR / "candidates.json"
CONFIG_FILE = COACH_DIR / "config.json"

EVENTS_SCHEMA = """
CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY,
    timestamp TEXT NOT NULL,
    event_type TEXT NOT NULL,
    signal_type TEXT,
    repo_id TEXT,
    content TEXT,
    context TEXT,
    processed INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_signal ON events(signal_type);
CREATE INDEX IF NOT EXISTS idx_events_processed ON events(processed);
"""

LEDGER_SCHEMA = """
CREATE TABLE IF NOT EXISTS candidates (
    fingerprint TEXT PRIMARY KEY,
    normalized_text TEXT,
    title TEXT,
    candidate_type TEXT,
    trigger_condition TEXT,
    action TEXT,
    current_scope TEXT DEFAULT 'project',
    repo_ids TEXT DEFAULT '[]',
    evidence TEXT DEFAULT '[]',
    confidence REAL DEFAULT 0.0,
    count INTEGER DEFAULT 1,
    status TEXT DEFAULT 'pending',
    first_seen TEXT,
    last_seen TEXT,
    promoted_at TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_candidates_type ON candidates(candidate_type);
CREATE INDEX IF NOT EXISTS idx_candidates_scope ON candidates(current_scope);
CREATE INDEX IF NOT EXISTS idx_candidates_status ON candidates(status);

CREATE TABLE IF NOT EXISTS promotions (
    id TEXT PRIMARY KEY,
    fingerprint TEXT NOT NULL,
    from_scope TEXT,
    to_scope TEXT,
    reason TEXT,
    promoted_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fingerprint) REFERENCES candidates(fingerprint)
);
"""

DEFAULT_CONFIG = {
    "version": "1.0.0",
    "batch_interval_minutes": 15,
    "min_evidence_count": 2,
    "promotion_threshold_repos": 2,
    "signal_patterns": {
        "correction": [
            r"\bno\b",
            r"\bstop\b",
            r"\bdon'?t\b",
            r"i said",
            r"you didn'?t",
            r"why did you",
            r"that'?s wrong",
            r"that'?s not",
            r"incorrect"
        ],
        "escalation": [
            r"[A-Z]{3,}",
            r"!{2,}",
            r"\bagain\b",
            r"for the last time",
            r"how many times"
        ],
        "failure_stderr": [
            r"ENOENT",
            r"ECONNREFUSED",
            r"ETIMEDOUT",
            r"permission denied",
            r"command not found",
            r"401",
            r"403",
            r"404",
            r"500",
            r"timeout"
        ]
    },
    "scope_indicators": {
        "project": [
            r"apps/",
            r"packages/",
            r"\.platform\.",
            r"\.env\.",
            r"docker-compose",
            r"Makefile"
        ],
        "global": [
            r"\bgit\b",
            r"\bdocker\b",
            r"\bnpm\b",
            r"\bpnpm\b",
            r"\byarn\b",
            r"\bpython\b",
            r"\bpytest\b",
            r"\bjest\b",
            r"run tests",
            r"small pr",
            r"commit"
        ]
    },
    "created_at": datetime.utcnow().isoformat()
}


def init_database(db_path: Path, schema: str) -> bool:
    """Initialize SQLite database with schema."""
    try:
        conn = sqlite3.connect(db_path)
        conn.executescript(schema)
        conn.commit()
        conn.close()
        return True
    except Exception as e:
        print(f"Error initializing {db_path}: {e}", file=sys.stderr)
        return False


def init_coach(force: bool = False) -> int:
    """Initialize the Coach system."""
    print("Initializing Coach self-learning system...")

    # Create main directory
    COACH_DIR.mkdir(parents=True, exist_ok=True)
    print(f"  Created directory: {COACH_DIR}")

    # Initialize events database
    if not EVENTS_DB.exists() or force:
        if init_database(EVENTS_DB, EVENTS_SCHEMA):
            print(f"  Initialized events database: {EVENTS_DB}")
        else:
            return 1
    else:
        print(f"  Events database exists: {EVENTS_DB}")

    # Initialize ledger database
    if not LEDGER_DB.exists() or force:
        if init_database(LEDGER_DB, LEDGER_SCHEMA):
            print(f"  Initialized ledger database: {LEDGER_DB}")
        else:
            return 1
    else:
        print(f"  Ledger database exists: {LEDGER_DB}")

    # Initialize candidates file
    if not CANDIDATES_FILE.exists() or force:
        CANDIDATES_FILE.write_text(json.dumps({"pending": [], "last_proposal": None}, indent=2))
        print(f"  Created candidates file: {CANDIDATES_FILE}")
    else:
        print(f"  Candidates file exists: {CANDIDATES_FILE}")

    # Initialize config
    if not CONFIG_FILE.exists() or force:
        CONFIG_FILE.write_text(json.dumps(DEFAULT_CONFIG, indent=2))
        print(f"  Created config file: {CONFIG_FILE}")
    else:
        print(f"  Config file exists: {CONFIG_FILE}")

    # Create global directories if they don't exist
    global_dirs = [
        Path.home() / ".claude" / "checklists",
        Path.home() / ".claude" / "snippets",
        Path.home() / ".claude" / "skills"
    ]
    for d in global_dirs:
        d.mkdir(parents=True, exist_ok=True)
    print(f"  Ensured global directories exist")

    print("\nCoach system initialized successfully!")
    print("\nNext steps:")
    print("  1. Configure hooks in .claude/settings.json")
    print("  2. Use /coach status to check system health")
    print("  3. Coach will automatically detect learning opportunities")

    return 0


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Initialize Coach self-learning system")
    parser.add_argument("--force", "-f", action="store_true", help="Reinitialize even if files exist")
    args = parser.parse_args()

    sys.exit(init_coach(force=args.force))


if __name__ == "__main__":
    main()
