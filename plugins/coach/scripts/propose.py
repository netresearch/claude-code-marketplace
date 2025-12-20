#!/usr/bin/env python3
"""
Generate git diff proposals for learning candidates.
Creates branches and commits for approval workflow.
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple

sys.path.insert(0, str(Path(__file__).parent))
from scope_analyzer import ScopeAnalyzer

COACH_DIR = Path.home() / ".claude-coach"
CANDIDATES_FILE = COACH_DIR / "candidates.json"


class ProposalGenerator:
    """Generates git-based proposals for candidates."""

    def __init__(self):
        self.scope_analyzer = ScopeAnalyzer()

    def get_target_file(self, candidate: Dict, scope: str) -> Path:
        """Determine target file based on candidate type and scope."""
        candidate_type = candidate.get('candidate_type', 'rule')

        if scope == "global":
            base = Path.home() / ".claude"
        else:
            base = Path.cwd() / ".claude"

        # Ensure base exists
        base.mkdir(parents=True, exist_ok=True)

        if candidate_type == "rule":
            return base / "CLAUDE.md"
        elif candidate_type == "checklist":
            (base / "checklists").mkdir(exist_ok=True)
            safe_title = self._safe_filename(candidate.get('title', 'checklist'))
            return base / "checklists" / f"{safe_title}.md"
        elif candidate_type == "snippet":
            (base / "snippets").mkdir(exist_ok=True)
            safe_title = self._safe_filename(candidate.get('title', 'snippet'))
            return base / "snippets" / f"{safe_title}.md"
        elif candidate_type == "antipattern":
            return base / "CLAUDE.md"  # Anti-patterns go in main rules
        else:
            return base / "CLAUDE.md"

    def _safe_filename(self, title: str) -> str:
        """Convert title to safe filename."""
        safe = title.lower()
        safe = ''.join(c if c.isalnum() or c in '-_' else '-' for c in safe)
        safe = '-'.join(filter(None, safe.split('-')))  # Remove consecutive dashes
        return safe[:50]  # Limit length

    def generate_content(self, candidate: Dict) -> str:
        """Generate markdown content for the candidate."""
        candidate_type = candidate.get('candidate_type', 'rule')
        trigger = candidate.get('trigger', '')
        action = candidate.get('action', '')
        title = candidate.get('title', '')

        if candidate_type == "rule":
            return f"""
## {title}

**Trigger**: {trigger}

**Action**: {action}
"""

        elif candidate_type == "checklist":
            return f"""# {title}

## When to use
{trigger}

## Checklist
- [ ] {action}
"""

        elif candidate_type == "snippet":
            return f"""# {title}

## When to use
{trigger}

## Command/Script
```bash
# {action}
```
"""

        elif candidate_type == "antipattern":
            return f"""
## Anti-pattern: {title}

**Never**: {trigger}

**Instead**: {action}
"""

        return f"## {title}\n\n{trigger}\n\n{action}\n"

    def generate_diff(self, candidate: Dict, scope: str = None) -> Dict:
        """Generate a unified diff for the candidate."""
        if scope is None:
            analysis = self.scope_analyzer.analyze(candidate)
            scope = analysis['recommended_scope']

        target_file = self.get_target_file(candidate, scope)
        new_content = self.generate_content(candidate)

        # Read existing content
        if target_file.exists():
            old_content = target_file.read_text()
        else:
            old_content = ""

        # For CLAUDE.md, append to existing content
        if target_file.name == "CLAUDE.md":
            # Find appropriate section or append
            if old_content:
                combined = old_content.rstrip() + "\n\n" + new_content.strip() + "\n"
            else:
                combined = f"# Claude Code Instructions\n\n{new_content.strip()}\n"
        else:
            # For standalone files, use new content
            combined = new_content.strip() + "\n"

        # Generate unified diff
        diff_lines = self._generate_unified_diff(
            str(target_file),
            old_content,
            combined
        )

        return {
            "candidate_id": candidate.get('id', ''),
            "fingerprint": candidate.get('fingerprint', ''),
            "scope": scope,
            "target_file": str(target_file),
            "diff": '\n'.join(diff_lines),
            "old_content": old_content,
            "new_content": combined,
            "generated_at": datetime.utcnow().isoformat()
        }

    def _generate_unified_diff(self, filename: str, old: str, new: str) -> List[str]:
        """Generate unified diff format."""
        import difflib

        old_lines = old.splitlines(keepends=True)
        new_lines = new.splitlines(keepends=True)

        diff = list(difflib.unified_diff(
            old_lines,
            new_lines,
            fromfile=f"a/{Path(filename).name}",
            tofile=f"b/{Path(filename).name}",
            lineterm=''
        ))

        return diff

    def create_branch(self, candidate: Dict) -> Tuple[bool, str]:
        """Create a git branch for the proposal."""
        timestamp = datetime.utcnow().strftime("%Y%m%d-%H%M")
        candidate_id = candidate.get('id', 'unknown')[:8]
        branch_name = f"coach/learn-{timestamp}-{candidate_id}"

        try:
            # Check if we're in a git repo
            result = subprocess.run(
                ["git", "rev-parse", "--is-inside-work-tree"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode != 0:
                return False, "Not in a git repository"

            # Create and checkout branch
            result = subprocess.run(
                ["git", "checkout", "-b", branch_name],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode != 0:
                return False, f"Failed to create branch: {result.stderr}"

            return True, branch_name

        except subprocess.TimeoutExpired:
            return False, "Git command timed out"
        except Exception as e:
            return False, str(e)

    def apply_diff(self, proposal: Dict) -> Tuple[bool, str]:
        """Apply the diff to create actual file changes."""
        target_file = Path(proposal['target_file'])

        try:
            # Ensure directory exists
            target_file.parent.mkdir(parents=True, exist_ok=True)

            # Write new content
            target_file.write_text(proposal['new_content'])

            return True, f"Applied changes to {target_file}"

        except Exception as e:
            return False, str(e)

    def create_commit(self, candidate: Dict, proposal: Dict) -> Tuple[bool, str]:
        """Create a git commit for the proposal."""
        title = candidate.get('title', 'learning')[:50]
        candidate_type = candidate.get('candidate_type', 'rule')

        commit_message = f"coach: add {candidate_type} '{title}'"

        try:
            # Stage the file
            subprocess.run(
                ["git", "add", proposal['target_file']],
                capture_output=True, text=True, timeout=10
            )

            # Create commit
            result = subprocess.run(
                ["git", "commit", "-m", commit_message],
                capture_output=True, text=True, timeout=10
            )

            if result.returncode != 0:
                return False, f"Commit failed: {result.stderr}"

            return True, commit_message

        except Exception as e:
            return False, str(e)

    def format_proposal_display(self, candidate: Dict, proposal: Dict) -> str:
        """Format proposal for display to user."""
        analysis = self.scope_analyzer.analyze(candidate)

        display = f"""
┌─────────────────────────────────────────────────┐
│ PENDING PROPOSAL #{candidate.get('id', '?')[:8]}                        │
│ Type: {candidate.get('candidate_type', 'rule'):<8} │ Scope: {proposal.get('scope', '?'):<8} │ Confidence: {candidate.get('confidence', 0):.2f}  │
├─────────────────────────────────────────────────┤
│ Title: {candidate.get('title', '')[:40]:<40} │
│                                                 │
│ Trigger: {candidate.get('trigger', '')[:38]:<38} │
│ Action: {candidate.get('action', '')[:39]:<39} │
│                                                 │
│ Evidence:                                       │
"""
        for ev in candidate.get('evidence', [])[:3]:
            quote = ev.get('quote', ev.get('stderr', ''))[:45]
            display += f"│ - {quote:<45} │\n"

        display += f"""│                                                 │
│ Reasons: {', '.join(analysis.get('recommendation_reasons', []))[:38]:<38} │
├─────────────────────────────────────────────────┤
│ Proposed Diff:                                  │
"""
        # Add diff preview (first 10 lines)
        diff_lines = proposal.get('diff', '').split('\n')[:10]
        for line in diff_lines:
            display += f"│ {line[:47]:<47} │\n"

        if len(proposal.get('diff', '').split('\n')) > 10:
            display += f"│ ... ({len(proposal.get('diff', '').split(chr(10))) - 10} more lines)                           │\n"

        display += """└─────────────────────────────────────────────────┘

Commands: /coach approve {id} | edit | reject
"""
        return display.format(id=candidate.get('id', '?')[:8])


def generate_proposal(candidate: Dict) -> Dict:
    """Convenience function to generate a proposal."""
    generator = ProposalGenerator()
    return generator.generate_diff(candidate)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate proposal for candidate")
    parser.add_argument("--candidate-id", help="Specific candidate ID to process")
    parser.add_argument("--scope", choices=["project", "global"], help="Override scope")
    parser.add_argument("--display", action="store_true", help="Display formatted proposal")
    parser.add_argument("--json", action="store_true", help="Output as JSON")

    args = parser.parse_args()

    # Load candidates
    if not CANDIDATES_FILE.exists():
        print("No candidates file found. Run aggregate.py first.", file=sys.stderr)
        return 1

    candidates_data = json.loads(CANDIDATES_FILE.read_text())
    pending = candidates_data.get('pending', [])

    if not pending:
        print("No pending candidates.")
        return 0

    generator = ProposalGenerator()

    for candidate in pending:
        if args.candidate_id and candidate.get('id') != args.candidate_id:
            continue

        proposal = generator.generate_diff(candidate, args.scope)

        if args.display:
            print(generator.format_proposal_display(candidate, proposal))
        elif args.json:
            print(json.dumps(proposal, indent=2))
        else:
            print(f"Proposal for {candidate.get('id')}: {proposal.get('target_file')}")
            print(proposal.get('diff'))

    return 0


if __name__ == "__main__":
    sys.exit(main())
