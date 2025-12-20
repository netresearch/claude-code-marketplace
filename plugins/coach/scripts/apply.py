#!/usr/bin/env python3
"""
Apply approved proposals to rules/skills files.
Handles the approval workflow for /coach commands.
"""

import os
import sys
import json
import subprocess
import shutil
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple

sys.path.insert(0, str(Path(__file__).parent))
from propose import ProposalGenerator

COACH_DIR = Path.home() / ".claude-coach"
CANDIDATES_FILE = COACH_DIR / "candidates.json"
LEDGER_DB = COACH_DIR / "ledger.sqlite"


class ProposalApplier:
    """Handles applying, editing, and rejecting proposals."""

    def __init__(self):
        self.generator = ProposalGenerator()

    def load_candidates(self) -> Dict:
        """Load candidates from file."""
        if not CANDIDATES_FILE.exists():
            return {"pending": [], "approved": [], "rejected": []}

        data = json.loads(CANDIDATES_FILE.read_text())
        # Ensure all lists exist
        data.setdefault("pending", [])
        data.setdefault("approved", [])
        data.setdefault("rejected", [])
        return data

    def save_candidates(self, data: Dict):
        """Save candidates to file."""
        CANDIDATES_FILE.write_text(json.dumps(data, indent=2))

    def find_candidate(self, candidate_id: str, data: Dict) -> Optional[Tuple[Dict, str]]:
        """Find a candidate by ID prefix."""
        for status in ["pending", "approved", "rejected"]:
            for c in data.get(status, []):
                if c.get('id', '').startswith(candidate_id):
                    return c, status
        return None, None

    def approve(self, candidate_id: str, create_branch: bool = True) -> Dict:
        """Approve and apply a candidate."""
        data = self.load_candidates()
        candidate, status = self.find_candidate(candidate_id, data)

        if not candidate:
            return {"success": False, "error": f"Candidate {candidate_id} not found"}

        if status != "pending":
            return {"success": False, "error": f"Candidate {candidate_id} is already {status}"}

        # Generate proposal
        proposal = self.generator.generate_diff(candidate)

        result = {
            "success": True,
            "candidate_id": candidate.get('id'),
            "title": candidate.get('title'),
            "scope": proposal.get('scope'),
            "target_file": proposal.get('target_file'),
            "branch": None,
            "commit": None
        }

        # Create branch if requested and in git repo
        if create_branch:
            success, branch_or_error = self.generator.create_branch(candidate)
            if success:
                result["branch"] = branch_or_error
            else:
                # Non-fatal - continue without branch
                result["branch_error"] = branch_or_error

        # Apply the diff
        success, message = self.generator.apply_diff(proposal)
        if not success:
            return {"success": False, "error": f"Failed to apply: {message}"}

        result["applied"] = message

        # Create commit if we created a branch
        if result.get("branch"):
            success, commit_msg = self.generator.create_commit(candidate, proposal)
            if success:
                result["commit"] = commit_msg

        # Update candidate status
        data["pending"] = [c for c in data["pending"] if c.get('id') != candidate.get('id')]
        candidate["status"] = "approved"
        candidate["approved_at"] = datetime.utcnow().isoformat()
        candidate["applied_to"] = proposal.get('target_file')
        data["approved"].append(candidate)

        self.save_candidates(data)
        self._update_ledger_status(candidate.get('fingerprint'), "approved")

        return result

    def reject(self, candidate_id: str, reason: str = "") -> Dict:
        """Reject a candidate with optional reason."""
        data = self.load_candidates()
        candidate, status = self.find_candidate(candidate_id, data)

        if not candidate:
            return {"success": False, "error": f"Candidate {candidate_id} not found"}

        if status != "pending":
            return {"success": False, "error": f"Candidate {candidate_id} is already {status}"}

        # Update status
        data["pending"] = [c for c in data["pending"] if c.get('id') != candidate.get('id')]
        candidate["status"] = "rejected"
        candidate["rejected_at"] = datetime.utcnow().isoformat()
        candidate["rejection_reason"] = reason
        data["rejected"].append(candidate)

        self.save_candidates(data)
        self._update_ledger_status(candidate.get('fingerprint'), "rejected")

        return {
            "success": True,
            "candidate_id": candidate.get('id'),
            "title": candidate.get('title'),
            "reason": reason
        }

    def edit(self, candidate_id: str, updates: Dict) -> Dict:
        """Edit a candidate before approval."""
        data = self.load_candidates()
        candidate, status = self.find_candidate(candidate_id, data)

        if not candidate:
            return {"success": False, "error": f"Candidate {candidate_id} not found"}

        if status != "pending":
            return {"success": False, "error": f"Candidate {candidate_id} is already {status}"}

        # Apply updates
        allowed_fields = {"title", "trigger", "action", "candidate_type"}
        for field, value in updates.items():
            if field in allowed_fields:
                candidate[field] = value

        # Regenerate fingerprint if content changed
        if any(f in updates for f in ["trigger", "action", "candidate_type"]):
            from fingerprint import fingerprint_candidate
            candidate["fingerprint"] = fingerprint_candidate(candidate)

        candidate["edited_at"] = datetime.utcnow().isoformat()
        self.save_candidates(data)

        return {
            "success": True,
            "candidate_id": candidate.get('id'),
            "updated_fields": list(updates.keys()),
            "new_fingerprint": candidate.get('fingerprint')
        }

    def promote(self, candidate_id: str) -> Dict:
        """Promote a candidate from project to global scope."""
        data = self.load_candidates()
        candidate, status = self.find_candidate(candidate_id, data)

        if not candidate:
            return {"success": False, "error": f"Candidate {candidate_id} not found"}

        # Check if already global
        if candidate.get('scope') == 'global':
            return {"success": False, "error": "Candidate is already global scope"}

        # Generate global proposal
        proposal = self.generator.generate_diff(candidate, scope="global")

        # Apply to global location
        success, message = self.generator.apply_diff(proposal)
        if not success:
            return {"success": False, "error": f"Failed to promote: {message}"}

        # Update candidate
        candidate["scope"] = "global"
        candidate["promoted_at"] = datetime.utcnow().isoformat()
        candidate["global_file"] = proposal.get('target_file')

        self.save_candidates(data)
        self._update_ledger_status(candidate.get('fingerprint'), "promoted")

        return {
            "success": True,
            "candidate_id": candidate.get('id'),
            "title": candidate.get('title'),
            "promoted_to": proposal.get('target_file')
        }

    def review(self, show_all: bool = False) -> List[Dict]:
        """Get candidates for review."""
        data = self.load_candidates()
        pending = data.get("pending", [])

        if show_all:
            return {
                "pending": pending,
                "approved": data.get("approved", [])[-10:],  # Last 10
                "rejected": data.get("rejected", [])[-10:]   # Last 10
            }

        return pending

    def status(self) -> Dict:
        """Get overall coach status."""
        data = self.load_candidates()

        # Get ledger stats
        ledger_stats = self._get_ledger_stats()

        return {
            "pending_count": len(data.get("pending", [])),
            "approved_count": len(data.get("approved", [])),
            "rejected_count": len(data.get("rejected", [])),
            "last_proposal": data.get("last_proposal"),
            "ledger_stats": ledger_stats
        }

    def _update_ledger_status(self, fingerprint: str, status: str):
        """Update ledger status for a candidate."""
        if not fingerprint or not LEDGER_DB.exists():
            return

        import sqlite3
        conn = sqlite3.connect(LEDGER_DB)
        conn.execute(
            "UPDATE candidates SET status = ?, updated_at = ? WHERE fingerprint = ?",
            (status, datetime.utcnow().isoformat(), fingerprint)
        )
        conn.commit()
        conn.close()

    def _get_ledger_stats(self) -> Dict:
        """Get statistics from the ledger."""
        if not LEDGER_DB.exists():
            return {}

        import sqlite3
        conn = sqlite3.connect(LEDGER_DB)

        stats = {}

        # Total candidates
        cursor = conn.execute("SELECT COUNT(*) FROM candidates")
        stats["total_candidates"] = cursor.fetchone()[0]

        # By status
        cursor = conn.execute(
            "SELECT status, COUNT(*) FROM candidates GROUP BY status"
        )
        stats["by_status"] = dict(cursor.fetchall())

        # Multi-repo candidates
        cursor = conn.execute("""
            SELECT COUNT(*) FROM candidates
            WHERE json_array_length(repo_ids) >= 2
        """)
        stats["multi_repo_candidates"] = cursor.fetchone()[0]

        conn.close()
        return stats


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Apply coach proposals")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # Approve command
    approve_parser = subparsers.add_parser("approve", help="Approve a candidate")
    approve_parser.add_argument("candidate_id", help="Candidate ID to approve")
    approve_parser.add_argument("--no-branch", action="store_true", help="Don't create git branch")

    # Reject command
    reject_parser = subparsers.add_parser("reject", help="Reject a candidate")
    reject_parser.add_argument("candidate_id", help="Candidate ID to reject")
    reject_parser.add_argument("--reason", "-r", default="", help="Rejection reason")

    # Edit command
    edit_parser = subparsers.add_parser("edit", help="Edit a candidate")
    edit_parser.add_argument("candidate_id", help="Candidate ID to edit")
    edit_parser.add_argument("--title", help="New title")
    edit_parser.add_argument("--trigger", help="New trigger")
    edit_parser.add_argument("--action", help="New action")
    edit_parser.add_argument("--type", dest="candidate_type", help="New type")

    # Promote command
    promote_parser = subparsers.add_parser("promote", help="Promote to global scope")
    promote_parser.add_argument("candidate_id", help="Candidate ID to promote")

    # Review command
    review_parser = subparsers.add_parser("review", help="Review pending candidates")
    review_parser.add_argument("--all", action="store_true", help="Show all candidates")

    # Status command
    subparsers.add_parser("status", help="Show coach status")

    args = parser.parse_args()
    applier = ProposalApplier()

    if args.command == "approve":
        result = applier.approve(args.candidate_id, create_branch=not args.no_branch)
        print(json.dumps(result, indent=2))

    elif args.command == "reject":
        result = applier.reject(args.candidate_id, args.reason)
        print(json.dumps(result, indent=2))

    elif args.command == "edit":
        updates = {}
        if args.title:
            updates["title"] = args.title
        if args.trigger:
            updates["trigger"] = args.trigger
        if args.action:
            updates["action"] = args.action
        if args.candidate_type:
            updates["candidate_type"] = args.candidate_type

        if not updates:
            print("No updates specified", file=sys.stderr)
            return 1

        result = applier.edit(args.candidate_id, updates)
        print(json.dumps(result, indent=2))

    elif args.command == "promote":
        result = applier.promote(args.candidate_id)
        print(json.dumps(result, indent=2))

    elif args.command == "review":
        candidates = applier.review(show_all=args.all)
        if isinstance(candidates, dict):
            print(json.dumps(candidates, indent=2))
        else:
            generator = ProposalGenerator()
            for c in candidates:
                proposal = generator.generate_diff(c)
                print(generator.format_proposal_display(c, proposal))

    elif args.command == "status":
        status = applier.status()
        print(json.dumps(status, indent=2))

    else:
        parser.print_help()
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
