#!/usr/bin/env python3
"""
Ledger operations for cross-repo learning tracking.
Manages the global fingerprint database for promotion detection.
"""

import os
import sys
import json
import sqlite3
import hashlib
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple

COACH_DIR = Path.home() / ".claude-coach"
LEDGER_DB = COACH_DIR / "ledger.sqlite"


class Ledger:
    """Manages the global learning ledger."""

    def __init__(self):
        self.db_path = LEDGER_DB

    def _connect(self) -> sqlite3.Connection:
        """Get database connection."""
        if not self.db_path.exists():
            raise FileNotFoundError(f"Ledger not initialized. Run: python init_coach.py")

        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def get_current_repo_id(self) -> str:
        """Get stable hash of current repository."""
        try:
            result = subprocess.run(
                ["git", "remote", "get-url", "origin"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0 and result.stdout.strip():
                return hashlib.sha256(result.stdout.strip().encode()).hexdigest()[:16]
        except:
            pass
        return hashlib.sha256(os.getcwd().encode()).hexdigest()[:16]

    def get_candidate(self, fingerprint: str) -> Optional[Dict]:
        """Get a candidate by fingerprint."""
        conn = self._connect()
        cursor = conn.execute(
            "SELECT * FROM candidates WHERE fingerprint = ?",
            (fingerprint,)
        )
        row = cursor.fetchone()
        conn.close()

        if row:
            return dict(row)
        return None

    def get_repos_for_fingerprint(self, fingerprint: str) -> List[str]:
        """Get list of repos that have seen this candidate."""
        candidate = self.get_candidate(fingerprint)
        if not candidate:
            return []

        repo_ids = candidate.get('repo_ids')
        if repo_ids:
            return json.loads(repo_ids)
        return []

    def add_repo_to_candidate(self, fingerprint: str, repo_id: str = None):
        """Add current repo to candidate's repo list."""
        if repo_id is None:
            repo_id = self.get_current_repo_id()

        conn = self._connect()
        cursor = conn.execute(
            "SELECT repo_ids, count FROM candidates WHERE fingerprint = ?",
            (fingerprint,)
        )
        row = cursor.fetchone()

        now = datetime.utcnow().isoformat()

        if row:
            repo_ids = json.loads(row['repo_ids']) if row['repo_ids'] else []
            if repo_id not in repo_ids:
                repo_ids.append(repo_id)

            conn.execute("""
                UPDATE candidates
                SET repo_ids = ?, count = ?, last_seen = ?, updated_at = ?
                WHERE fingerprint = ?
            """, (json.dumps(repo_ids), row['count'] + 1, now, now, fingerprint))
        else:
            # Create new entry
            conn.execute("""
                INSERT INTO candidates
                (fingerprint, repo_ids, count, first_seen, last_seen, status)
                VALUES (?, ?, 1, ?, ?, 'pending')
            """, (fingerprint, json.dumps([repo_id]), now, now))

        conn.commit()
        conn.close()

    def check_promotion_eligibility(self, fingerprint: str, threshold: int = 2) -> Dict:
        """Check if a candidate is eligible for promotion."""
        repos = self.get_repos_for_fingerprint(fingerprint)
        candidate = self.get_candidate(fingerprint)

        eligible = len(repos) >= threshold
        already_promoted = candidate and candidate.get('status') == 'promoted'

        return {
            "fingerprint": fingerprint,
            "repo_count": len(repos),
            "repos": repos,
            "threshold": threshold,
            "eligible": eligible and not already_promoted,
            "already_promoted": already_promoted,
            "current_status": candidate.get('status') if candidate else None
        }

    def get_promotion_candidates(self, threshold: int = 2) -> List[Dict]:
        """Get all candidates eligible for promotion."""
        conn = self._connect()
        cursor = conn.execute("""
            SELECT * FROM candidates
            WHERE status != 'promoted'
            AND json_array_length(repo_ids) >= ?
        """, (threshold,))

        candidates = [dict(row) for row in cursor.fetchall()]
        conn.close()

        return candidates

    def mark_promoted(self, fingerprint: str):
        """Mark a candidate as promoted to global."""
        conn = self._connect()
        now = datetime.utcnow().isoformat()

        conn.execute("""
            UPDATE candidates
            SET status = 'promoted', promoted_at = ?, updated_at = ?
            WHERE fingerprint = ?
        """, (now, now, fingerprint))

        # Also record in promotions table
        conn.execute("""
            INSERT INTO promotions (id, fingerprint, from_scope, to_scope, reason)
            VALUES (?, ?, 'project', 'global', 'Multi-repo threshold reached')
        """, (hashlib.md5(f"{fingerprint}{now}".encode()).hexdigest()[:8], fingerprint))

        conn.commit()
        conn.close()

    def get_stats(self) -> Dict:
        """Get ledger statistics."""
        conn = self._connect()

        stats = {}

        # Total candidates
        cursor = conn.execute("SELECT COUNT(*) FROM candidates")
        stats["total_candidates"] = cursor.fetchone()[0]

        # By status
        cursor = conn.execute("""
            SELECT status, COUNT(*) as count
            FROM candidates
            GROUP BY status
        """)
        stats["by_status"] = {row['status'] or 'unknown': row['count'] for row in cursor.fetchall()}

        # Multi-repo candidates
        cursor = conn.execute("""
            SELECT COUNT(*) FROM candidates
            WHERE json_array_length(repo_ids) >= 2
        """)
        stats["multi_repo"] = cursor.fetchone()[0]

        # Promotion eligible
        cursor = conn.execute("""
            SELECT COUNT(*) FROM candidates
            WHERE status != 'promoted'
            AND json_array_length(repo_ids) >= 2
        """)
        stats["promotion_eligible"] = cursor.fetchone()[0]

        # Recent activity
        cursor = conn.execute("""
            SELECT COUNT(*) FROM candidates
            WHERE date(last_seen) >= date('now', '-7 days')
        """)
        stats["active_last_7_days"] = cursor.fetchone()[0]

        # Total promotions
        cursor = conn.execute("SELECT COUNT(*) FROM promotions")
        stats["total_promotions"] = cursor.fetchone()[0]

        conn.close()
        return stats

    def search(self, query: str, limit: int = 20) -> List[Dict]:
        """Search candidates by text."""
        conn = self._connect()
        cursor = conn.execute("""
            SELECT * FROM candidates
            WHERE normalized_text LIKE ? OR title LIKE ?
            ORDER BY last_seen DESC
            LIMIT ?
        """, (f"%{query}%", f"%{query}%", limit))

        results = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return results

    def get_history(self, limit: int = 50) -> List[Dict]:
        """Get recent ledger activity."""
        conn = self._connect()
        cursor = conn.execute("""
            SELECT fingerprint, title, candidate_type, status, last_seen,
                   json_array_length(repo_ids) as repo_count
            FROM candidates
            ORDER BY last_seen DESC
            LIMIT ?
        """, (limit,))

        results = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return results

    def cleanup_old(self, days: int = 90):
        """Remove old rejected candidates."""
        conn = self._connect()
        conn.execute("""
            DELETE FROM candidates
            WHERE status = 'rejected'
            AND date(last_seen) < date('now', ?)
        """, (f"-{days} days",))

        deleted = conn.total_changes
        conn.commit()
        conn.close()
        return deleted


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Ledger operations")
    subparsers = parser.add_subparsers(dest="command", help="Command")

    # Stats command
    subparsers.add_parser("stats", help="Show ledger statistics")

    # Search command
    search_parser = subparsers.add_parser("search", help="Search candidates")
    search_parser.add_argument("query", help="Search query")
    search_parser.add_argument("--limit", type=int, default=20, help="Result limit")

    # History command
    history_parser = subparsers.add_parser("history", help="Show recent activity")
    history_parser.add_argument("--limit", type=int, default=50, help="Result limit")

    # Promotions command
    promo_parser = subparsers.add_parser("promotions", help="Show promotion candidates")
    promo_parser.add_argument("--threshold", type=int, default=2, help="Repo threshold")

    # Check command
    check_parser = subparsers.add_parser("check", help="Check promotion eligibility")
    check_parser.add_argument("fingerprint", help="Candidate fingerprint")

    # Cleanup command
    cleanup_parser = subparsers.add_parser("cleanup", help="Clean old rejected candidates")
    cleanup_parser.add_argument("--days", type=int, default=90, help="Age threshold in days")

    args = parser.parse_args()

    try:
        ledger = Ledger()

        if args.command == "stats":
            stats = ledger.get_stats()
            print(json.dumps(stats, indent=2))

        elif args.command == "search":
            results = ledger.search(args.query, args.limit)
            print(json.dumps(results, indent=2))

        elif args.command == "history":
            history = ledger.get_history(args.limit)
            print(json.dumps(history, indent=2))

        elif args.command == "promotions":
            candidates = ledger.get_promotion_candidates(args.threshold)
            print(f"Found {len(candidates)} candidates eligible for promotion:")
            print(json.dumps(candidates, indent=2))

        elif args.command == "check":
            result = ledger.check_promotion_eligibility(args.fingerprint)
            print(json.dumps(result, indent=2))

        elif args.command == "cleanup":
            deleted = ledger.cleanup_old(args.days)
            print(f"Deleted {deleted} old rejected candidates")

        else:
            parser.print_help()
            return 1

    except FileNotFoundError as e:
        print(str(e), file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
