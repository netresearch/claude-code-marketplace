#!/usr/bin/env python3
"""
Initialize the Coach self-learning system.
Creates necessary directories and SQLite databases.
Installs stable hook launchers to avoid version path issues.
"""

import os
import sys
import sqlite3
import json
import shutil
from pathlib import Path
from datetime import datetime, UTC

COACH_DIR = Path.home() / ".claude-coach"
COACH_BIN_DIR = COACH_DIR / "bin"
EVENTS_DB = COACH_DIR / "events.sqlite"
LEDGER_DB = COACH_DIR / "ledger.sqlite"
CANDIDATES_FILE = COACH_DIR / "candidates.json"
CONFIG_FILE = COACH_DIR / "config.json"
CLAUDE_SETTINGS = Path.home() / ".claude" / "settings.json"
INSTALLED_PLUGINS = Path.home() / ".claude" / "plugins" / "installed_plugins.json"

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
    "created_at": datetime.now(UTC).isoformat()
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


def get_plugin_root() -> Path | None:
    """Get the current coach plugin install path from installed_plugins.json."""
    if not INSTALLED_PLUGINS.exists():
        return None
    try:
        data = json.loads(INSTALLED_PLUGINS.read_text())
        plugins = data.get("plugins", {})
        coach_entry = plugins.get("coach@netresearch-claude-code-marketplace", [{}])[0]
        install_path = coach_entry.get("installPath")
        if install_path:
            return Path(install_path)
    except Exception:
        pass
    return None


def install_launcher() -> bool:
    """Install the coach-run launcher to a stable path."""
    plugin_root = get_plugin_root()
    if not plugin_root:
        # Fallback: use script's location to find plugin root
        plugin_root = Path(__file__).parent.parent

    source_launcher = plugin_root / "bin" / "coach-run"
    if not source_launcher.exists():
        print(f"  Warning: Launcher not found at {source_launcher}", file=sys.stderr)
        return False

    COACH_BIN_DIR.mkdir(parents=True, exist_ok=True)
    dest_launcher = COACH_BIN_DIR / "coach-run"

    try:
        shutil.copy2(source_launcher, dest_launcher)
        dest_launcher.chmod(0o755)
        print(f"  Installed launcher: {dest_launcher}")
        return True
    except Exception as e:
        print(f"  Error installing launcher: {e}", file=sys.stderr)
        return False


def update_settings_hooks() -> bool:
    """Update ~/.claude/settings.json hooks to use stable paths."""
    if not CLAUDE_SETTINGS.exists():
        print("  Settings file not found, skipping hook update")
        return True

    try:
        settings = json.loads(CLAUDE_SETTINGS.read_text())
    except Exception as e:
        print(f"  Error reading settings: {e}", file=sys.stderr)
        return False

    hooks = settings.get("hooks", {})
    if not hooks:
        print("  No hooks configured, skipping")
        return True

    stable_launcher = str(COACH_BIN_DIR / "coach-run")
    updated = False

    # Pattern to match versioned coach plugin paths
    import re
    version_pattern = re.compile(
        r"python3\s+[^\s]*plugins/cache/[^/]+/coach/[^/]+/scripts/(\w+\.py)"
    )

    def update_command(cmd: str) -> str:
        """Replace versioned path with stable launcher using async mode."""
        match = version_pattern.search(cmd)
        if match:
            script_name = match.group(1)
            # Extract args after the script path
            script_pos = cmd.find(script_name)
            args_part = cmd[script_pos + len(script_name):]
            # Use --async for non-blocking hook execution
            return f"{stable_launcher} --async {script_name}{args_part}"
        return cmd

    for hook_type, hook_list in hooks.items():
        if not isinstance(hook_list, list):
            continue
        for entry in hook_list:
            if not isinstance(entry, dict):
                continue
            inner_hooks = entry.get("hooks", [])
            for hook in inner_hooks:
                if hook.get("type") == "command" and "coach" in hook.get("command", ""):
                    old_cmd = hook["command"]
                    new_cmd = update_command(old_cmd)
                    if new_cmd != old_cmd:
                        hook["command"] = new_cmd
                        updated = True

    if updated:
        try:
            CLAUDE_SETTINGS.write_text(json.dumps(settings, indent=2))
            print("  Updated hooks in settings.json to use stable paths")
        except Exception as e:
            print(f"  Error writing settings: {e}", file=sys.stderr)
            return False
    else:
        print("  Hooks already use stable paths or no coach hooks found")

    return True


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

    # Install stable hook launcher
    print("\nSetting up stable hook paths...")
    if install_launcher():
        update_settings_hooks()
    else:
        print("  Warning: Could not install launcher, hooks may break on version updates")

    print("\nCoach system initialized successfully!")
    print("\nNext steps:")
    print("  1. Use /coach status to check system health")
    print("  2. Coach will automatically detect learning opportunities")
    print("\nNote: Hooks now use stable paths that survive plugin version updates.")

    return 0


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Initialize Coach self-learning system")
    parser.add_argument("--force", "-f", action="store_true", help="Reinitialize even if files exist")
    args = parser.parse_args()

    sys.exit(init_coach(force=args.force))


if __name__ == "__main__":
    main()
