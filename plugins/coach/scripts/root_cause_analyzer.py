#!/usr/bin/env python3
"""
Root Cause Analyzer for Coach System.

Instead of just counting failures, this module:
1. Tracks command sequences to understand the progression
2. Identifies what changed when commands eventually succeed
3. Extracts specific patterns (wrong syntax, wrong params, missing prereqs)
4. Creates actionable proposals based on actual resolutions

v1.0 - Initial implementation
"""

import re
import json
from typing import Dict, List, Optional, Tuple, Any
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class CommandVariation:
    """Represents a single command execution and its result."""
    command: str
    exit_code: int
    stderr: str
    timestamp: str

    @property
    def succeeded(self) -> bool:
        return self.exit_code == 0

    @property
    def base_command(self) -> str:
        """Extract base command (first 1-2 words)."""
        parts = self.command.strip().split()
        if len(parts) >= 2:
            return ' '.join(parts[:2]).lower()
        return parts[0].lower() if parts else ''


@dataclass
class CommandSequence:
    """Represents a sequence of related command attempts."""
    base_command: str
    variations: List[CommandVariation] = field(default_factory=list)

    @property
    def eventually_succeeded(self) -> bool:
        """Check if any variation succeeded."""
        return any(v.succeeded for v in self.variations)

    @property
    def success_variation(self) -> Optional[CommandVariation]:
        """Get the first successful variation."""
        for v in self.variations:
            if v.succeeded:
                return v
        return None

    @property
    def failure_variations(self) -> List[CommandVariation]:
        """Get all failed variations."""
        return [v for v in self.variations if not v.succeeded]

    @property
    def last_failure_before_success(self) -> Optional[CommandVariation]:
        """Get the failure that came right before success."""
        success_idx = None
        for i, v in enumerate(self.variations):
            if v.succeeded:
                success_idx = i
                break

        if success_idx and success_idx > 0:
            return self.variations[success_idx - 1]
        return None


class RootCauseAnalyzer:
    """Analyzes command sequences to identify root causes and resolutions."""

    # Pattern categories for analysis
    PARAM_PATTERNS = [
        (r'--\w+', 'flag'),
        (r'-\w\s', 'short_flag'),
        (r'=\S+', 'value'),
    ]

    # Known command patterns and their common issues
    COMMAND_KNOWLEDGE = {
        'gh pr': {
            'flags': ['--squash', '--merge', '--rebase', '--auto', '--delete-branch'],
            'common_issues': {
                'merge queue': 'Use --auto flag or GraphQL enqueuePullRequest mutation',
                'not allowed': 'Check repo settings for allowed merge methods',
                'required status': 'Wait for CI checks to pass first',
            }
        },
        'gh api': {
            'common_issues': {
                '404': 'Check endpoint path and resource existence',
                '422': 'Validate request body JSON structure',
                'graphql': 'Use proper GraphQL query format with variables',
            }
        },
        'git push': {
            'flags': ['--force', '--force-with-lease', '-u', '--set-upstream'],
            'common_issues': {
                'protected': 'Create PR instead of direct push',
                'non-fast-forward': 'Pull/rebase first or use --force-with-lease',
            }
        },
        'composer': {
            'flags': ['--ignore-platform-req', '--no-scripts', '-W'],
            'common_issues': {
                'ext-': 'Install PHP extension or use --ignore-platform-req=ext-*',
                'platform': 'Check PHP version or configure platform in composer.json',
                'conflict': 'Use -W flag for root package updates',
            }
        },
        'npm': {
            'flags': ['--legacy-peer-deps', '--force', '--save-exact'],
            'common_issues': {
                'peer dep': 'Use --legacy-peer-deps flag',
                'ERESOLVE': 'Check version conflicts or use --force',
            }
        },
    }

    def __init__(self):
        self.sequences: Dict[str, CommandSequence] = {}

    def add_command(self, command: str, exit_code: int, stderr: str, timestamp: str = None):
        """Add a command execution to the analysis."""
        variation = CommandVariation(
            command=command,
            exit_code=exit_code,
            stderr=stderr or '',
            timestamp=timestamp or datetime.now().isoformat()
        )

        base = variation.base_command
        if base not in self.sequences:
            self.sequences[base] = CommandSequence(base_command=base)

        self.sequences[base].variations.append(variation)

    def load_from_context(self, context: Dict):
        """Load commands from coach's recent_context format."""
        tool_calls = context.get('recent_tool_calls', [])
        for call in tool_calls:
            self.add_command(
                command=call.get('command', ''),
                exit_code=call.get('exit_code', 0),
                stderr=call.get('stderr', ''),
                timestamp=call.get('timestamp', '')
            )

    def load_from_events(self, events: List[Dict]):
        """Load commands from coach events database format."""
        for event in events:
            if event.get('signal_type') != 'COMMAND_FAILURE':
                continue

            try:
                content = json.loads(event.get('content', '{}'))
            except:
                continue

            self.add_command(
                command=content.get('command', ''),
                exit_code=content.get('exit_code', 1),
                stderr=content.get('stderr_preview', ''),
                timestamp=event.get('timestamp', '')
            )

    def analyze_sequence(self, sequence: CommandSequence) -> Dict[str, Any]:
        """Analyze a command sequence for root cause patterns."""
        analysis = {
            'base_command': sequence.base_command,
            'total_attempts': len(sequence.variations),
            'failed_attempts': len(sequence.failure_variations),
            'resolved': sequence.eventually_succeeded,
            'patterns': [],
            'root_cause': None,
            'resolution': None,
            'actionable_insight': None,
        }

        if len(sequence.variations) < 2:
            return analysis

        # Compare variations to find what changed
        analysis['patterns'] = self._detect_variation_patterns(sequence)

        # If resolved, extract what worked
        if sequence.eventually_succeeded:
            analysis['resolution'] = self._extract_resolution(sequence)
            analysis['actionable_insight'] = self._generate_actionable_insight(sequence, analysis)
        else:
            # Still failing - analyze common error patterns
            analysis['root_cause'] = self._identify_root_cause(sequence)
            analysis['actionable_insight'] = self._generate_failure_insight(sequence, analysis)

        return analysis

    def _detect_variation_patterns(self, sequence: CommandSequence) -> List[Dict]:
        """Detect patterns in how commands varied."""
        patterns = []
        variations = sequence.variations

        for i in range(1, len(variations)):
            prev = variations[i-1]
            curr = variations[i]

            diff = self._diff_commands(prev.command, curr.command)
            if diff:
                patterns.append({
                    'from_index': i-1,
                    'to_index': i,
                    'change_type': diff['type'],
                    'details': diff['details'],
                    'succeeded_after': curr.succeeded,
                })

        return patterns

    def _diff_commands(self, cmd1: str, cmd2: str) -> Optional[Dict]:
        """Diff two commands to identify what changed."""
        parts1 = cmd1.split()
        parts2 = cmd2.split()

        if parts1 == parts2:
            return None

        # Detect flag changes
        flags1 = set(p for p in parts1 if p.startswith('-'))
        flags2 = set(p for p in parts2 if p.startswith('-'))

        added_flags = flags2 - flags1
        removed_flags = flags1 - flags2

        if added_flags or removed_flags:
            return {
                'type': 'flag_change',
                'details': {
                    'added': list(added_flags),
                    'removed': list(removed_flags),
                }
            }

        # Detect subcommand changes
        if len(parts1) >= 2 and len(parts2) >= 2:
            if parts1[0] == parts2[0] and parts1[1] != parts2[1]:
                return {
                    'type': 'subcommand_change',
                    'details': {
                        'from': parts1[1],
                        'to': parts2[1],
                    }
                }

        # Detect argument changes
        args1 = [p for p in parts1 if not p.startswith('-')]
        args2 = [p for p in parts2 if not p.startswith('-')]

        if args1 != args2:
            return {
                'type': 'argument_change',
                'details': {
                    'from': args1,
                    'to': args2,
                }
            }

        return {
            'type': 'unknown_change',
            'details': {'from': cmd1, 'to': cmd2}
        }

    def _extract_resolution(self, sequence: CommandSequence) -> Dict:
        """Extract what made the command eventually succeed."""
        success = sequence.success_variation
        last_failure = sequence.last_failure_before_success

        if not success or not last_failure:
            return {'type': 'unknown', 'details': 'Could not determine resolution'}

        diff = self._diff_commands(last_failure.command, success.command)

        if not diff:
            return {
                'type': 'retry_succeeded',
                'details': 'Same command succeeded on retry (transient failure)'
            }

        return {
            'type': f'fixed_by_{diff["type"]}',
            'details': diff['details'],
            'working_command': success.command,
        }

    def _identify_root_cause(self, sequence: CommandSequence) -> Dict:
        """Identify root cause from failed command sequence."""
        # Analyze error messages for patterns
        errors = [v.stderr for v in sequence.failure_variations if v.stderr]

        base_cmd = sequence.base_command

        # Check against known command issues
        for cmd_pattern, knowledge in self.COMMAND_KNOWLEDGE.items():
            if cmd_pattern in base_cmd:
                for error_pattern, solution in knowledge.get('common_issues', {}).items():
                    for err in errors:
                        if error_pattern.lower() in err.lower():
                            return {
                                'type': 'known_issue',
                                'pattern': error_pattern,
                                'suggested_fix': solution,
                            }

        # Look for common error categories
        error_categories = {
            'authentication': ['401', '403', 'unauthorized', 'forbidden', 'token', 'credential'],
            'not_found': ['404', 'not found', 'does not exist', 'no such'],
            'permission': ['permission denied', 'access denied', 'EPERM'],
            'syntax': ['syntax error', 'unexpected', 'invalid', 'malformed'],
            'dependency': ['not found', 'missing', 'required', 'dependency'],
        }

        for category, patterns in error_categories.items():
            for err in errors:
                if any(p.lower() in err.lower() for p in patterns):
                    return {
                        'type': category,
                        'evidence': err[:200],
                    }

        return {
            'type': 'unknown',
            'evidence': errors[0][:200] if errors else 'No error message captured'
        }

    def _generate_actionable_insight(self, sequence: CommandSequence, analysis: Dict) -> Dict:
        """Generate a specific actionable insight from successful resolution."""
        resolution = analysis.get('resolution', {})
        res_type = resolution.get('type', 'unknown')

        if res_type == 'fixed_by_flag_change':
            details = resolution.get('details', {})
            added = details.get('added', [])
            removed = details.get('removed', [])

            if added:
                return {
                    'title': f"Use {', '.join(added)} flags with {sequence.base_command}",
                    'trigger': f"when running {sequence.base_command}",
                    'action': f"include flags {', '.join(added)} to avoid failures",
                    'confidence': 0.85,
                    'evidence_type': 'resolved_failure',
                }

        elif res_type == 'fixed_by_subcommand_change':
            details = resolution.get('details', {})
            return {
                'title': f"Use '{details.get('to')}' instead of '{details.get('from')}'",
                'trigger': f"when running {sequence.base_command}",
                'action': f"use subcommand '{details.get('to')}' instead of '{details.get('from')}'",
                'confidence': 0.80,
                'evidence_type': 'resolved_failure',
            }

        elif res_type == 'retry_succeeded':
            return {
                'title': f"Retry {sequence.base_command} on transient failure",
                'trigger': f"when {sequence.base_command} fails with transient error",
                'action': "implement retry logic - this command can fail transiently",
                'confidence': 0.65,
                'evidence_type': 'transient_failure',
            }

        # Fallback to working command
        working = resolution.get('working_command')
        if working:
            return {
                'title': f"Correct syntax for {sequence.base_command}",
                'trigger': f"when running {sequence.base_command}",
                'action': f"use: {working[:100]}",
                'confidence': 0.75,
                'evidence_type': 'working_example',
            }

        return None

    def _generate_failure_insight(self, sequence: CommandSequence, analysis: Dict) -> Dict:
        """Generate insight for still-failing commands."""
        root_cause = analysis.get('root_cause', {})
        cause_type = root_cause.get('type', 'unknown')

        if cause_type == 'known_issue':
            return {
                'title': f"Fix {root_cause.get('pattern')} issue with {sequence.base_command}",
                'trigger': f"when {sequence.base_command} fails with {root_cause.get('pattern')}",
                'action': root_cause.get('suggested_fix', 'investigate further'),
                'confidence': 0.80,
                'evidence_type': 'known_pattern',
            }

        elif cause_type == 'authentication':
            return {
                'title': f"Check credentials before {sequence.base_command}",
                'trigger': f"before running {sequence.base_command}",
                'action': "verify authentication tokens/credentials are valid and have required permissions",
                'confidence': 0.75,
                'evidence_type': 'error_pattern',
            }

        elif cause_type == 'permission':
            return {
                'title': f"Fix permissions for {sequence.base_command}",
                'trigger': f"when {sequence.base_command} fails with permission error",
                'action': "check file/directory permissions or use elevated privileges if appropriate",
                'confidence': 0.70,
                'evidence_type': 'error_pattern',
            }

        # For unknown causes, try to extract something useful
        evidence = root_cause.get('evidence', '')
        if evidence:
            # Try to find specific error message
            error_match = re.search(r'error[:\s]+(.{10,60})', evidence, re.IGNORECASE)
            if error_match:
                return {
                    'title': f"Handle '{error_match.group(1)[:30]}...' in {sequence.base_command}",
                    'trigger': f"when {sequence.base_command} shows this error",
                    'action': f"investigate: {evidence[:100]}",
                    'confidence': 0.50,
                    'evidence_type': 'error_message',
                }

        return None

    def analyze_all(self) -> List[Dict]:
        """Analyze all command sequences and return actionable insights."""
        insights = []

        for base_cmd, sequence in self.sequences.items():
            # Skip sequences with only 1 attempt (no pattern to analyze)
            if len(sequence.variations) < 2:
                continue

            analysis = self.analyze_sequence(sequence)

            if analysis.get('actionable_insight'):
                insight = analysis['actionable_insight']
                insight['analysis'] = {
                    'base_command': analysis['base_command'],
                    'total_attempts': analysis['total_attempts'],
                    'resolved': analysis['resolved'],
                    'patterns': analysis['patterns'][:3],  # Limit for storage
                }
                insights.append(insight)

        return insights

    def generate_candidates(self) -> List[Dict]:
        """Generate learning candidates from analysis."""
        from fingerprint import fingerprint_candidate
        import uuid

        insights = self.analyze_all()
        candidates = []

        for insight in insights:
            if not insight.get('title') or not insight.get('action'):
                continue

            candidate = {
                "id": str(uuid.uuid4())[:8],
                "title": insight['title'],
                "candidate_type": "rule",
                "trigger": insight['trigger'],
                "action": insight['action'],
                "evidence": [{
                    "source": "root_cause_analysis",
                    "evidence_type": insight.get('evidence_type', 'analysis'),
                    "analysis": insight.get('analysis', {}),
                }],
                "confidence": insight.get('confidence', 0.70),
                "status": "pending",
                "created_at": datetime.now().isoformat(),
                "from_root_cause_analysis": True,
            }

            candidate["fingerprint"] = fingerprint_candidate(candidate)
            candidates.append(candidate)

        return candidates


def main():
    """Test the analyzer with sample data."""
    import argparse
    parser = argparse.ArgumentParser(description="Analyze command sequences for root causes")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--context-file", help="Load from recent_context.json")

    args = parser.parse_args()

    analyzer = RootCauseAnalyzer()

    # Example: simulate a gh api failure sequence
    if args.context_file:
        from pathlib import Path
        context = json.loads(Path(args.context_file).read_text())
        analyzer.load_from_context(context)
    else:
        # Demo data
        analyzer.add_command(
            "gh api graphql -f query='mutation { mergePullRequest }'",
            exit_code=1,
            stderr="merge queue is required"
        )
        analyzer.add_command(
            "gh pr merge 123 --squash --delete-branch",
            exit_code=1,
            stderr="merge queue is required"
        )
        analyzer.add_command(
            "gh pr merge 123 --auto",
            exit_code=0,
            stderr=""
        )

    # Analyze
    candidates = analyzer.generate_candidates()

    if args.verbose:
        print(f"Generated {len(candidates)} candidates from root cause analysis:\n")
        for c in candidates:
            print(f"[{c['candidate_type']}] {c['title']}")
            print(f"  Trigger: {c['trigger']}")
            print(f"  Action: {c['action']}")
            print(f"  Confidence: {c['confidence']:.2f}")
            print(f"  Evidence: {c['evidence'][0].get('evidence_type')}")
            print()
    else:
        print(json.dumps(candidates, indent=2))

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
