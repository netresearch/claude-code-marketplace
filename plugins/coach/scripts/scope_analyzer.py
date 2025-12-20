#!/usr/bin/env python3
"""
Analyze candidate scope: project vs global.
Uses heuristics to determine optimal placement.
"""

import os
import sys
import re
import json
import sqlite3
from pathlib import Path
from typing import Dict, List, Optional, Tuple

COACH_DIR = Path.home() / ".claude-coach"
LEDGER_DB = COACH_DIR / "ledger.sqlite"
CONFIG_FILE = COACH_DIR / "config.json"

# Indicator patterns for scope detection
PROJECT_INDICATORS = [
    # Path patterns unique to repos
    (r'apps/', 3),
    (r'packages/', 2),
    (r'src/components/', 2),
    (r'\.platform\.', 3),
    (r'docker-compose\.', 2),
    (r'\.env\.', 2),
    (r'Makefile', 1),

    # Domain-specific terms (likely project-specific)
    (r'\b(client|customer|vendor)\s+name', 2),
    (r'\b(internal|proprietary)\b', 2),
    (r'\bapi\.example\.com\b', 3),  # Specific URLs

    # Project tooling
    (r'pnpm\s+-C\s+packages/', 3),
    (r'nx\s+', 2),
    (r'turbo\b', 2),
]

GLOBAL_INDICATORS = [
    # Universal engineering behaviors
    (r'\brun\s+tests?\b', 3),
    (r'\bsmall\s+(pr|commit)', 2),
    (r'\bcommit\s+message', 2),
    (r'\bcode\s+review', 2),
    (r'\bdiff\s+summary', 2),
    (r'\bverify\s+before', 2),
    (r'\bbackup\s+first', 2),

    # Cross-repo tooling
    (r'\bgit\b', 2),
    (r'\bdocker\b', 2),
    (r'\bnpm\b', 1),
    (r'\bpnpm\b', 1),
    (r'\byarn\b', 1),
    (r'\bpython\b', 1),
    (r'\bpytest\b', 1),
    (r'\bjest\b', 1),

    # Universal warnings
    (r'\bdon\'t\s+edit\s+generated', 3),
    (r'\bnever\s+commit\s+secrets', 3),
    (r'\balways\s+backup', 2),
    (r'\bcommand\s+not\s+found', 2),
]


class ScopeAnalyzer:
    """Analyzes and decides candidate scope."""

    def __init__(self):
        self.config = self._load_config()
        self.promotion_threshold = self.config.get("promotion_threshold_repos", 2)

    def _load_config(self) -> Dict:
        if CONFIG_FILE.exists():
            return json.loads(CONFIG_FILE.read_text())
        return {}

    def calculate_scores(self, candidate: Dict) -> Tuple[float, float]:
        """Calculate project and global scores for a candidate."""
        text = f"{candidate.get('trigger', '')} {candidate.get('action', '')} {candidate.get('title', '')}"
        text_lower = text.lower()

        project_score = 0.0
        global_score = 0.0

        # Check project indicators
        for pattern, weight in PROJECT_INDICATORS:
            if re.search(pattern, text_lower):
                project_score += weight

        # Check global indicators
        for pattern, weight in GLOBAL_INDICATORS:
            if re.search(pattern, text_lower):
                global_score += weight

        return project_score, global_score

    def check_existing_rules(self, candidate: Dict) -> Dict:
        """Check if similar rules exist in global or project scope."""
        from fingerprint import Fingerprinter

        fp = Fingerprinter()
        candidate_fp = candidate.get('fingerprint', '')

        result = {
            "exists_global": False,
            "exists_project": False,
            "similar_global": [],
            "similar_project": []
        }

        # Check global rules
        global_claude_md = Path.home() / ".claude" / "CLAUDE.md"
        if global_claude_md.exists():
            content = global_claude_md.read_text()
            # Simple similarity check
            candidate_text = f"{candidate.get('trigger', '')} {candidate.get('action', '')}"
            if fp.similarity(candidate_text, content) > 0.4:
                result["exists_global"] = True

        # Check project rules
        project_claude_md = Path.cwd() / ".claude" / "CLAUDE.md"
        if project_claude_md.exists():
            content = project_claude_md.read_text()
            candidate_text = f"{candidate.get('trigger', '')} {candidate.get('action', '')}"
            if fp.similarity(candidate_text, content) > 0.4:
                result["exists_project"] = True

        return result

    def check_cross_repo_presence(self, fingerprint: str) -> Dict:
        """Check how many repos have seen this candidate."""
        if not LEDGER_DB.exists():
            return {"repo_count": 0, "repos": []}

        conn = sqlite3.connect(LEDGER_DB)
        cursor = conn.execute(
            "SELECT repo_ids, count, status FROM candidates WHERE fingerprint = ?",
            (fingerprint,)
        )
        row = cursor.fetchone()
        conn.close()

        if not row:
            return {"repo_count": 0, "repos": []}

        repo_ids = json.loads(row[0]) if row[0] else []
        return {
            "repo_count": len(repo_ids),
            "repos": repo_ids,
            "total_count": row[1],
            "status": row[2]
        }

    def analyze(self, candidate: Dict) -> Dict:
        """Full scope analysis for a candidate."""
        project_score, global_score = self.calculate_scores(candidate)
        existing = self.check_existing_rules(candidate)
        cross_repo = self.check_cross_repo_presence(candidate.get('fingerprint', ''))

        # Decision logic
        recommended_scope = "project"  # Default
        recommendation_reason = []

        # Rule 1: If exists globally, prefer global (dedupe)
        if existing["exists_global"]:
            recommended_scope = "global"
            recommendation_reason.append("Similar rule exists globally - update instead of duplicate")

        # Rule 2: If only exists in project, keep in project (consistency)
        elif existing["exists_project"]:
            recommended_scope = "project"
            recommendation_reason.append("Similar rule exists in project - maintain consistency")

        # Rule 3: Cross-repo threshold
        elif cross_repo["repo_count"] >= self.promotion_threshold:
            recommended_scope = "global"
            recommendation_reason.append(f"Seen in {cross_repo['repo_count']} repos - promote to global")

        # Rule 4: Score-based decision
        elif global_score > project_score * 1.5:
            recommended_scope = "global"
            recommendation_reason.append(f"Global indicators strong ({global_score:.1f} vs {project_score:.1f})")

        elif project_score > global_score * 1.5:
            recommended_scope = "project"
            recommendation_reason.append(f"Project indicators strong ({project_score:.1f} vs {global_score:.1f})")

        else:
            # Ambiguous - default to project
            recommended_scope = "project"
            recommendation_reason.append("Scores ambiguous - defaulting to project scope")

        # Promotion eligibility
        eligible_for_promotion = (
            recommended_scope == "project" and
            cross_repo["repo_count"] >= 1 and
            global_score >= project_score * 0.8
        )

        return {
            "recommended_scope": recommended_scope,
            "recommendation_reasons": recommendation_reason,
            "project_score": project_score,
            "global_score": global_score,
            "existing_rules": existing,
            "cross_repo": cross_repo,
            "eligible_for_promotion": eligible_for_promotion,
            "promotion_threshold": self.promotion_threshold
        }

    def should_propose_promotion(self, candidate: Dict) -> bool:
        """Check if candidate should be proposed for promotion."""
        analysis = self.analyze(candidate)
        cross_repo = analysis["cross_repo"]

        # Promote if seen in 2+ repos and not already global
        return (
            cross_repo["repo_count"] >= self.promotion_threshold and
            analysis["recommended_scope"] == "project" and
            cross_repo.get("status") != "promoted"
        )


def analyze_candidate(candidate: Dict) -> Dict:
    """Convenience function to analyze a single candidate."""
    analyzer = ScopeAnalyzer()
    return analyzer.analyze(candidate)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Analyze candidate scope")
    parser.add_argument("--trigger", required=True, help="Trigger condition")
    parser.add_argument("--action", required=True, help="Action to take")
    parser.add_argument("--type", default="rule", help="Candidate type")
    parser.add_argument("--fingerprint", help="Candidate fingerprint")
    parser.add_argument("--json", action="store_true", help="Output as JSON")

    args = parser.parse_args()

    candidate = {
        "trigger": args.trigger,
        "action": args.action,
        "candidate_type": args.type,
        "fingerprint": args.fingerprint or ""
    }

    analyzer = ScopeAnalyzer()
    result = analyzer.analyze(candidate)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"Recommended scope: {result['recommended_scope']}")
        print(f"Reasons: {', '.join(result['recommendation_reasons'])}")
        print(f"Scores: project={result['project_score']:.1f}, global={result['global_score']:.1f}")
        if result['eligible_for_promotion']:
            print("Eligible for promotion to global")


if __name__ == "__main__":
    sys.exit(main())
