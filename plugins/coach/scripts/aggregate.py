#!/usr/bin/env python3
"""
Aggregate friction signals into learning candidates.
Runs after turns or at session end to batch process signals.

v2.2 - Improved with:
- Better context extraction from signals
- LLM-assisted candidate generation (when available)
- Smarter failure pattern recognition
- Repeated failure detection
- Session-end transcript analysis
- Skill update suggestions (from SKILL_SUPPLEMENT signals)
- Outdated tool detection (from VERSION_ISSUE signals)
"""

import os
import sys
import json
import sqlite3
import uuid
import subprocess
import re
import glob as glob_module
from pathlib import Path
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple, Any
from collections import defaultdict

# Import local modules
sys.path.insert(0, str(Path(__file__).parent))
from fingerprint import Fingerprinter, fingerprint_candidate
from root_cause_analyzer import RootCauseAnalyzer

COACH_DIR = Path.home() / ".claude-coach"
EVENTS_DB = COACH_DIR / "events.sqlite"
LEDGER_DB = COACH_DIR / "ledger.sqlite"
CANDIDATES_FILE = COACH_DIR / "candidates.json"
RAW_ANALYSIS_FILE = COACH_DIR / "raw_analysis.json"  # For Claude Code to process at review time
CONFIG_FILE = COACH_DIR / "config.json"
CONTEXT_FILE = COACH_DIR / "recent_context.json"


# NOTE: LLM generation removed from aggregate.py
# Claude Code now does the reasoning at review time via /coach:review skill
# This avoids separate API calls and uses the parent Claude session


class TranscriptAnalyzer:
    """Analyze session transcripts for learning patterns at session end."""

    CLAUDE_DIR = Path.home() / ".claude"
    PROJECTS_DIR = CLAUDE_DIR / "projects"

    # Patterns that indicate corrections in context
    CORRECTION_PATTERNS = [
        r'\bno[,!]?\s+(?:i\s+)?(?:said|meant|want)',
        r'\bstop\b.*\bdon\'?t\b',
        r'\bthat\'?s\s+(?:not|wrong)',
        r'\byou\s+(?:didn\'?t|should(?:n\'?t)?|need\s+to)',
        r'\bwhy\s+did\s+you',
        r'\bi\s+(?:already|just)\s+(?:said|told)',
        r'\bfor\s+the\s+(?:last|third|second)\s+time',
        r'\bliterally\b',
        r'\baargh\b',
        r'[!]{2,}',
    ]

    def __init__(self):
        self.correction_patterns = [re.compile(p, re.IGNORECASE) for p in self.CORRECTION_PATTERNS]

    def find_recent_transcript(self) -> Optional[Path]:
        """Find the most recent session transcript."""
        if not self.PROJECTS_DIR.exists():
            return None

        # Claude Code stores transcripts as .jsonl files in project directories
        # Main session files have UUID names, agent files have "agent-" prefix
        transcripts = []
        for project_dir in self.PROJECTS_DIR.iterdir():
            if not project_dir.is_dir():
                continue

            # Look for main session files (UUID names, not agent-*)
            for transcript in project_dir.glob("*.jsonl"):
                # Skip agent sub-sessions
                if transcript.name.startswith("agent-"):
                    continue
                try:
                    stat = transcript.stat()
                    # Only consider files modified in last 24 hours
                    if (datetime.now().timestamp() - stat.st_mtime) < 86400:
                        transcripts.append((transcript, stat.st_mtime))
                except:
                    pass

        if not transcripts:
            return None

        # Return most recent
        transcripts.sort(key=lambda x: x[1], reverse=True)
        return transcripts[0][0]

    def parse_transcript(self, transcript_path: Path) -> List[Dict[str, Any]]:
        """Parse a Claude Code transcript file (JSONL format)."""
        messages = []
        try:
            with open(transcript_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        entry = json.loads(line)
                        # Claude Code JSONL has different entry types
                        entry_type = entry.get('type', '')

                        if entry_type == 'user':
                            # User message
                            messages.append({
                                'role': 'user',
                                'content': entry.get('message', {}).get('content', '')
                            })
                        elif entry_type == 'assistant':
                            # Assistant response
                            msg = entry.get('message', {})
                            messages.append({
                                'role': 'assistant',
                                'content': msg.get('content', [])
                            })
                        elif entry_type == 'tool_result':
                            # Tool result - store for context
                            messages.append({
                                'role': 'tool_result',
                                'content': entry
                            })
                    except json.JSONDecodeError:
                        continue
            return messages
        except Exception as e:
            return []

    def extract_messages(self, transcript: List[Dict]) -> Tuple[List[str], List[str], List[Dict]]:
        """Extract user messages, assistant messages, and tool calls with results from transcript."""
        user_messages = []
        assistant_messages = []
        tool_calls = []
        tool_results = {}  # Map tool_use_id -> result

        # First pass: collect tool_results from user messages
        for entry in transcript:
            role = entry.get('role', '')
            content = entry.get('content', '')

            if role == 'user' and isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and item.get('type') == 'tool_result':
                        tool_use_id = item.get('tool_use_id', '')
                        result_content = item.get('content', '')
                        # Extract text from content if it's a list
                        if isinstance(result_content, list):
                            texts = [c.get('text', '') for c in result_content if c.get('type') == 'text']
                            result_content = '\n'.join(texts)
                        tool_results[tool_use_id] = {
                            'content': result_content,
                            'is_error': item.get('is_error', False),
                        }

        # Second pass: extract messages and pair tool_use with results
        for entry in transcript:
            role = entry.get('role', '')
            content = entry.get('content', '')

            if role == 'user':
                if isinstance(content, str):
                    user_messages.append(content)
                elif isinstance(content, list):
                    for item in content:
                        if isinstance(item, dict) and item.get('type') == 'text':
                            user_messages.append(item.get('text', ''))

            elif role == 'assistant':
                if isinstance(content, str):
                    assistant_messages.append(content)
                elif isinstance(content, list):
                    for item in content:
                        if isinstance(item, dict):
                            if item.get('type') == 'text':
                                assistant_messages.append(item.get('text', ''))
                            elif item.get('type') == 'tool_use':
                                # Pair with result if available
                                tool_use_id = item.get('id', '')
                                result = tool_results.get(tool_use_id, {})
                                item['result'] = result.get('content', '')
                                item['is_error'] = result.get('is_error', False)
                                # Detect failure from result content
                                result_text = item['result'].lower() if item['result'] else ''
                                item['is_failure'] = (
                                    item['is_error'] or
                                    'error:' in result_text or
                                    'exit code 1' in result_text or
                                    'failed' in result_text[:100] or
                                    'command not found' in result_text
                                )
                                tool_calls.append(item)

        return user_messages, assistant_messages, tool_calls

    def detect_correction_sequences(self, user_messages: List[str]) -> List[Dict]:
        """Detect sequences where user corrected Claude multiple times."""
        corrections = []

        for i, msg in enumerate(user_messages):
            msg_lower = msg.lower()

            # Check for correction patterns
            matched_patterns = []
            for pattern in self.correction_patterns:
                if pattern.search(msg):
                    matched_patterns.append(pattern.pattern)

            if matched_patterns:
                # Get context - what happened before
                context_before = user_messages[max(0, i-2):i] if i > 0 else []

                corrections.append({
                    'message': msg,
                    'index': i,
                    'patterns_matched': matched_patterns,
                    'context_before': context_before,
                    'intensity': len(matched_patterns) + (msg.count('!') // 2)
                })

        return corrections

    # Commands that are expected to run multiple times
    BENIGN_REPEATED_COMMANDS = {
        'git status', 'git diff', 'git log', 'git show', 'git branch',
        'git fetch', 'git add', 'git rm', 'git stash',
        'ls', 'cat', 'head', 'tail', 'grep', 'find', 'pwd', 'echo',
        'sleep', 'wait', 'true', 'false',
        'npm run', 'npm test', 'yarn test', 'pnpm test',
        'go test', 'pytest', 'jest', 'make test',
        'docker ps', 'docker logs', 'docker exec',
        'kubectl get', 'kubectl describe', 'kubectl logs',
    }

    # Commands that are concerning if they fail repeatedly
    CONCERNING_COMMANDS = {
        'gh pr', 'gh issue', 'gh run',
        'git push', 'git pull', 'git rebase', 'git merge', 'git cherry-pick',
        'npm install', 'npm publish', 'yarn install', 'pnpm install',
        'docker build', 'docker push',
        'go build', 'go mod', 'cargo build', 'cargo publish',
        'make build', 'make deploy',
        'terraform apply', 'terraform plan',
        'kubectl apply', 'kubectl delete',
    }

    def detect_repeated_failures(self, tool_calls: List[Dict]) -> List[Dict]:
        """Detect repeated concerning tool calls in transcript with variation analysis."""
        # Track command sequences with more detail - now properly tracking failures vs successes
        command_sequences = defaultdict(lambda: {'attempts': [], 'failures': [], 'successes': []})

        for call in tool_calls:
            tool_name = call.get('name', '')
            tool_input = call.get('input', {})

            # Look for Bash calls
            if 'bash' in tool_name.lower() or tool_name == 'Bash':
                command = tool_input.get('command', '')
                # Extract base command (first 2 words)
                parts = command.split()[:2]
                base = ' '.join(parts).lower()

                # Skip benign commands that are expected to run multiple times
                is_benign = any(benign in base for benign in self.BENIGN_REPEATED_COMMANDS)
                if is_benign:
                    continue

                # Capture more details for root cause analysis
                cmd_info = {
                    'command': command,
                    'tool': tool_name,
                    'flags': [p for p in command.split() if p.startswith('-')],
                    'args': [p for p in command.split() if not p.startswith('-')][2:],  # Skip base cmd
                    'result': call.get('result', ''),
                    'is_failure': call.get('is_failure', False),
                }

                command_sequences[base]['attempts'].append(cmd_info)
                if cmd_info['is_failure']:
                    command_sequences[base]['failures'].append(cmd_info)
                else:
                    command_sequences[base]['successes'].append(cmd_info)

        # Analyze sequences for patterns - now only flagging actual failure sequences
        repeated = []
        for base, seq in command_sequences.items():
            failures = seq['failures']
            successes = seq['successes']
            attempts = seq['attempts']

            # Only flag if there were actual failures (2+ failures)
            if len(failures) >= 2:
                # Prioritize known concerning commands
                is_concerning = any(concern in base for concern in self.CONCERNING_COMMANDS)
                if is_concerning or len(failures) >= 3:
                    # Detect if flags/args changed between attempts
                    variation_analysis = self._analyze_attempt_variations(attempts)

                    # Detect if issue was eventually resolved
                    resolution_found = len(successes) > 0 and len(failures) > 0
                    resolution_command = None
                    if resolution_found and successes:
                        # Find the first success after failures
                        resolution_command = successes[-1].get('command', '')

                    repeated.append({
                        'base_command': base,
                        'occurrences': len(failures),
                        'total_attempts': len(attempts),
                        'commands': failures[:5],  # Limit to 5 examples of failures
                        'is_concerning': is_concerning,
                        'variation_analysis': variation_analysis,
                        'resolution_found': resolution_found,
                        'resolution_command': resolution_command,
                        'error_samples': [f.get('result', '')[:200] for f in failures[:3] if f.get('result')],
                    })

        # Sort by concern level and occurrence count
        repeated.sort(key=lambda x: (not x.get('is_concerning', False), -x['occurrences']))
        return repeated

    def _analyze_attempt_variations(self, attempts: List[Dict]) -> Dict:
        """Analyze how command attempts varied over time."""
        if len(attempts) < 2:
            return {'type': 'single_attempt', 'details': None}

        # Track flag changes
        all_flags = [set(a.get('flags', [])) for a in attempts]
        flag_changes = []
        for i in range(1, len(all_flags)):
            added = all_flags[i] - all_flags[i-1]
            removed = all_flags[i-1] - all_flags[i]
            if added or removed:
                flag_changes.append({'index': i, 'added': list(added), 'removed': list(removed)})

        # Track argument changes
        all_args = [a.get('args', []) for a in attempts]
        arg_changes = sum(1 for i in range(1, len(all_args)) if all_args[i] != all_args[i-1])

        # Determine variation type
        if flag_changes:
            return {
                'type': 'flag_iteration',
                'details': f"Tried different flags: {len(flag_changes)} flag changes across {len(attempts)} attempts",
                'flag_changes': flag_changes[:3],  # Limit stored changes
            }
        elif arg_changes > 0:
            return {
                'type': 'argument_iteration',
                'details': f"Tried different arguments: {arg_changes} changes across {len(attempts)} attempts",
            }
        else:
            return {
                'type': 'simple_retry',
                'details': f"Same command retried {len(attempts)} times (possible transient failure)",
            }

    def detect_implicit_corrections(self, user_messages: List[str], assistant_messages: List[str]) -> List[Dict]:
        """Detect implicit corrections - user doing what Claude should have done."""
        implicit = []

        for i, msg in enumerate(user_messages):
            # Skip short messages
            if len(msg) < 20:
                continue

            # Look for patterns where user provides detailed instructions after vague response
            msg_lower = msg.lower()

            # User providing code/commands that Claude should have generated
            if any(pattern in msg_lower for pattern in ['```', 'like this:', 'try this:', 'use this:']):
                if i > 0:
                    implicit.append({
                        'message': msg[:200],
                        'type': 'provided_solution',
                        'index': i
                    })

            # User asking same thing differently
            if i >= 2:
                prev_messages = [m.lower() for m in user_messages[max(0, i-3):i]]
                current_words = set(msg_lower.split())

                for prev in prev_messages:
                    prev_words = set(prev.split())
                    if len(prev_words) > 5 and len(current_words) > 5:
                        overlap = len(current_words & prev_words) / min(len(current_words), len(prev_words))
                        if overlap > 0.5:
                            implicit.append({
                                'message': msg[:200],
                                'type': 'rephrased_request',
                                'similar_to': prev[:100],
                                'index': i
                            })
                            break

        return implicit

    def analyze_session(self, transcript_path: Optional[Path] = None) -> Dict[str, Any]:
        """Perform full session analysis."""
        if transcript_path is None:
            transcript_path = self.find_recent_transcript()

        if not transcript_path or not transcript_path.exists():
            return {'error': 'No transcript found', 'patterns': []}

        transcript = self.parse_transcript(transcript_path)
        if not transcript:
            return {'error': 'Could not parse transcript', 'patterns': []}

        user_msgs, assistant_msgs, tool_calls = self.extract_messages(transcript)

        # Run all detection methods
        corrections = self.detect_correction_sequences(user_msgs)
        failures = self.detect_repeated_failures(tool_calls)
        implicit = self.detect_implicit_corrections(user_msgs, assistant_msgs)

        return {
            'transcript_path': str(transcript_path),
            'message_counts': {
                'user': len(user_msgs),
                'assistant': len(assistant_msgs),
                'tool_calls': len(tool_calls)
            },
            'patterns': {
                'corrections': corrections,
                'repeated_failures': failures,
                'implicit_corrections': implicit
            },
            'summary': {
                'correction_count': len(corrections),
                'failure_count': len(failures),
                'implicit_count': len(implicit),
                'high_intensity_corrections': [c for c in corrections if c.get('intensity', 0) >= 3]
            }
        }

    def _analyze_command_variations(self, commands: List[Dict], base_cmd: str, occurrences: int) -> str:
        """Analyze command variations to extract specific patterns."""
        if not commands:
            return f"investigate why {base_cmd} fails repeatedly ({occurrences}x)"

        # Extract all flags used across variations
        all_flags = set()
        for cmd_info in commands:
            cmd = cmd_info.get('command', '')
            flags = [p for p in cmd.split() if p.startswith('-')]
            all_flags.update(flags)

        # Look for flag patterns
        if all_flags:
            common_flags = ', '.join(sorted(all_flags)[:5])
            return f"check if flags ({common_flags}) are correct for {base_cmd}"

        # Look for common subcommands
        subcommands = set()
        for cmd_info in commands:
            parts = cmd_info.get('command', '').split()
            if len(parts) >= 2:
                subcommands.add(parts[1])

        if len(subcommands) > 1:
            # Multiple subcommands tried - suggest checking which is correct
            subs = ', '.join(sorted(subcommands))
            return f"determine correct subcommand for {base_cmd} (tried: {subs})"

        # Generic but still more specific than before
        return f"review {base_cmd} syntax and parameters - {occurrences} failures suggest systemic issue"

    def generate_candidates_from_analysis(self, analysis: Dict) -> List[Dict]:
        """Generate learning candidates from session analysis."""
        candidates = []
        patterns = analysis.get('patterns', {})

        # Generate from high-intensity corrections
        # NOTE: Raw data saved for Claude Code to analyze at review time
        for correction in patterns.get('corrections', []):
            if correction.get('intensity', 0) >= 2:
                # Save raw correction data - Claude Code analyzes at /coach:review time
                candidate = {
                    "id": str(uuid.uuid4())[:8],
                    "title": f"Correction detected (intensity {correction.get('intensity', 0)})",
                    "candidate_type": "raw_correction",
                    "trigger": "needs_analysis",
                    "action": "needs_analysis",
                    "raw_data": {
                        "message": correction['message'][:500],
                        "context_before": correction.get('context_before', [])[-3:],
                        "patterns_matched": correction.get('patterns_matched', []),
                        "intensity": correction.get('intensity', 0),
                    },
                    "evidence": [{"source": "transcript_analysis", "quote": correction['message'][:200]}],
                    "confidence": 0.0,  # Will be set by Claude Code at review
                    "status": "pending",
                    "created_at": datetime.now(timezone.utc).isoformat(),
                    "needs_llm_analysis": True,
                    "from_transcript": True
                }
                candidate["fingerprint"] = fingerprint_candidate(candidate)
                candidates.append(candidate)

        # Generate from repeated failures using root cause analysis
        repeated_failures = patterns.get('repeated_failures', [])
        if repeated_failures:
            # Use root cause analyzer for deeper analysis
            root_analyzer = RootCauseAnalyzer()

            for failure in repeated_failures:
                if failure.get('occurrences', 0) >= 2:
                    # Feed failed commands to root cause analyzer with actual error messages
                    error_samples = failure.get('error_samples', [])
                    for i, cmd_info in enumerate(failure.get('commands', [])):
                        stderr = error_samples[i] if i < len(error_samples) else cmd_info.get('result', '')
                        root_analyzer.add_command(
                            command=cmd_info.get('command', ''),
                            exit_code=1,  # These are failures
                            stderr=stderr,
                            timestamp=datetime.now(timezone.utc).isoformat()
                        )

                    # If resolution was found, add the successful command
                    if failure.get('resolution_found') and failure.get('resolution_command'):
                        root_analyzer.add_command(
                            command=failure['resolution_command'],
                            exit_code=0,  # Success
                            stderr='',
                            timestamp=datetime.now(timezone.utc).isoformat()
                        )

            # Generate candidates from root cause analysis
            rca_candidates = root_analyzer.generate_candidates()

            if rca_candidates:
                # Use the analyzed candidates
                for rca_candidate in rca_candidates:
                    rca_candidate["from_transcript"] = True
                    candidates.append(rca_candidate)
            else:
                # Fallback: create candidates based on variation analysis
                for failure in repeated_failures:
                    if failure.get('occurrences', 0) >= 2:
                        base_cmd = failure.get('base_command', 'command')
                        commands = failure.get('commands', [])
                        variation = failure.get('variation_analysis', {})
                        variation_type = variation.get('type', 'unknown')

                        # Generate specific proposal based on variation type
                        if variation_type == 'flag_iteration':
                            flag_changes = variation.get('flag_changes', [])
                            if flag_changes:
                                # Extract the flags that were tried
                                tried_flags = set()
                                for fc in flag_changes:
                                    tried_flags.update(fc.get('added', []))
                                    tried_flags.update(fc.get('removed', []))
                                flags_str = ', '.join(sorted(tried_flags)[:4])
                                title = f"Determine correct flags for {base_cmd}"
                                action = f"verify which flags are appropriate for {base_cmd} - tried: {flags_str}"
                            else:
                                title = f"Fix {base_cmd} flag usage"
                                action = self._analyze_command_variations(commands, base_cmd, failure['occurrences'])
                            confidence = 0.80

                        elif variation_type == 'argument_iteration':
                            title = f"Fix {base_cmd} argument syntax"
                            action = f"check {base_cmd} argument requirements - {failure['occurrences']} attempts with different args"
                            confidence = 0.78

                        elif variation_type == 'simple_retry':
                            title = f"Add retry logic for {base_cmd}"
                            action = f"{base_cmd} may have transient failures - implement exponential backoff"
                            confidence = 0.65

                        else:
                            title = f"Fix repeated {base_cmd} failures"
                            action = self._analyze_command_variations(commands, base_cmd, failure['occurrences'])
                            confidence = 0.70

                        candidate = {
                            "id": str(uuid.uuid4())[:8],
                            "title": title,
                            "candidate_type": "rule",
                            "trigger": f"when using {base_cmd}",
                            "action": action,
                            "evidence": [{
                                "source": "transcript_analysis",
                                "commands": commands[:2],
                                "variation_type": variation_type,
                                "variation_details": variation.get('details'),
                            }],
                            "confidence": confidence,
                            "status": "pending",
                            "created_at": datetime.now(timezone.utc).isoformat(),
                            "from_transcript": True
                        }
                        candidate["fingerprint"] = fingerprint_candidate(candidate)
                        candidates.append(candidate)

        return candidates


class CandidateAggregator:
    """Aggregates signals into learning candidates."""

    def __init__(self, analyze_transcript: bool = True):
        self.fingerprinter = Fingerprinter()
        self.config = self._load_config()
        self.min_evidence = self.config.get("min_evidence_count", 1)  # Lowered for failures
        # LLM analysis now done by Claude Code at /coach:review time
        self.transcript_analyzer = TranscriptAnalyzer() if analyze_transcript else None

    def _load_config(self) -> Dict:
        if CONFIG_FILE.exists():
            return json.loads(CONFIG_FILE.read_text())
        return {}

    def get_unprocessed_events(self, since: datetime = None) -> List[Dict]:
        """Fetch unprocessed events from database."""
        if not EVENTS_DB.exists():
            return []

        conn = sqlite3.connect(EVENTS_DB)
        conn.row_factory = sqlite3.Row

        query = "SELECT * FROM events WHERE processed = 0"
        params = []

        if since:
            query += " AND timestamp >= ?"
            params.append(since.isoformat())

        query += " ORDER BY timestamp ASC"

        cursor = conn.execute(query, params)
        events = [dict(row) for row in cursor.fetchall()]
        conn.close()

        return events

    def mark_events_processed(self, event_ids: List[str]):
        """Mark events as processed."""
        if not event_ids or not EVENTS_DB.exists():
            return

        conn = sqlite3.connect(EVENTS_DB)
        placeholders = ','.join(['?' for _ in event_ids])
        conn.execute(f"UPDATE events SET processed = 1 WHERE id IN ({placeholders})", event_ids)
        conn.commit()
        conn.close()

    def group_events_by_signal(self, events: List[Dict]) -> Dict[str, List[Dict]]:
        """Group events by signal type."""
        groups = defaultdict(list)
        for event in events:
            signal_type = event.get('signal_type', 'UNKNOWN')
            groups[signal_type].append(event)
        return dict(groups)

    def extract_candidate_from_failure(self, events: List[Dict]) -> List[Dict]:
        """Extract rule candidates from command failures with smart pattern detection."""
        candidates = []

        # Group failures by similar command
        command_groups = defaultdict(list)
        for event in events:
            content = json.loads(event.get('content', '{}'))
            command = content.get('command', '')
            # Extract base command (first 2 words)
            base = ' '.join(command.split()[:2]).lower()
            command_groups[base].append(event)

        for base_cmd, cmd_events in command_groups.items():
            # Get the most recent failure details
            event = cmd_events[-1]
            content = json.loads(event.get('content', '{}'))
            context = json.loads(event.get('context', '{}'))

            command = content.get('command', '')
            stderr = content.get('stderr_preview', '')
            exit_code = content.get('exit_code', 1)
            stderr_matches = content.get('stderr_matches', [])

            # Pattern-based extraction (LLM analysis done by Claude Code at review time)
            trigger, action, candidate_type = self._extract_failure_pattern(
                command, stderr, stderr_matches, len(cmd_events)
            )

            candidate = {
                "id": str(uuid.uuid4())[:8],
                "title": self._generate_title(trigger, action),
                "candidate_type": candidate_type,
                "trigger": trigger,
                "action": action,
                "evidence": [{"event_id": e['id'], "command": json.loads(e.get('content', '{}')).get('command', '')[:100]}
                            for e in cmd_events[:3]],
                "confidence": min(0.7 + (len(cmd_events) * 0.05), 0.95),
                "status": "pending",
                "created_at": datetime.now(timezone.utc).isoformat(),
                "failure_count": len(cmd_events)
            }

            candidate["fingerprint"] = fingerprint_candidate(candidate)
            candidates.append(candidate)

        return candidates

    def _extract_failure_pattern(self, command: str, stderr: str, matches: List[str],
                                 failure_count: int) -> Tuple[str, str, str]:
        """Extract specific trigger/action from failure patterns."""
        stderr_lower = stderr.lower()
        cmd_parts = command.split()
        base_cmd = ' '.join(cmd_parts[:2]) if len(cmd_parts) >= 2 else cmd_parts[0] if cmd_parts else 'command'

        # GitHub/Git specific patterns
        if 'gh pr merge' in command:
            if 'merge queue' in stderr_lower:
                return (
                    "when using gh pr merge on a repo with merge queue enabled",
                    "use 'gh pr merge --auto' instead of --squash/--delete-branch flags, or use GraphQL enqueuePullRequest mutation",
                    "rule"
                )
            if 'not allowed' in stderr_lower or 'merge strategy' in stderr_lower:
                return (
                    "when gh pr merge fails with merge strategy error",
                    "check repo settings for allowed merge methods, use --auto flag for auto-merge",
                    "rule"
                )

        if 'git push' in command:
            if 'protected branch' in stderr_lower or 'not fast-forward' in stderr_lower:
                return (
                    "when git push fails on protected branch",
                    "create a PR instead of direct push, or use --force-with-lease if intentional",
                    "rule"
                )

        if 'git rebase' in command:
            if 'conflict' in stderr_lower:
                return (
                    "when git rebase encounters conflicts",
                    "resolve conflicts file by file, use git rebase --continue, or abort with --abort",
                    "rule"
                )

        # Composer/PHP patterns
        if 'composer' in command.lower():
            if 'ext-' in stderr_lower or 'ignore-platform-req' in stderr_lower:
                # Extract missing extensions
                ext_matches = re.findall(r'ext-(\w+)', stderr_lower)
                extensions = ', '.join(ext_matches) if ext_matches else 'required extensions'
                return (
                    f"when composer fails due to missing PHP extensions ({extensions})",
                    f"install missing PHP extensions or use --ignore-platform-req flags for development",
                    "rule"
                )
            if 'platform' in stderr_lower and 'requirement' in stderr_lower:
                return (
                    "when composer fails with platform requirements",
                    "check PHP version compatibility or configure platform in composer.json",
                    "rule"
                )

        # Common tool patterns
        if 'command not found' in stderr_lower:
            tool = cmd_parts[0] if cmd_parts else 'tool'
            return (
                f"when {tool} is not installed or not in PATH",
                f"verify with 'command -v {tool}' before use, install if missing",
                "rule"
            )

        if 'permission denied' in stderr_lower:
            return (
                f"when {base_cmd} fails with permission denied",
                "check file/directory permissions, consider using sudo if appropriate",
                "rule"
            )

        if any(code in stderr_lower for code in ['401', '403', 'unauthorized', 'forbidden']):
            return (
                f"when {base_cmd} fails with authentication error",
                "verify credentials/tokens are valid and have required permissions",
                "rule"
            )

        if any(code in stderr_lower for code in ['rate limit', '429']):
            return (
                f"when {base_cmd} fails with rate limit error",
                "implement backoff/retry logic, or wait before retrying",
                "rule"
            )

        # Generic pattern for repeated failures
        if failure_count >= 2:
            return (
                f"when {base_cmd} fails repeatedly ({failure_count}x)",
                f"investigate root cause before retrying; check prerequisites and error messages",
                "rule"
            )

        # Default
        return (
            f"when {base_cmd} fails",
            "check error message and handle appropriately",
            "snippet"
        )

    def extract_candidate_from_correction(self, events: List[Dict]) -> Optional[Dict]:
        """Extract a rule candidate from correction events with context."""
        if not events:
            return None

        # Get the most impactful correction (most recent with most context)
        event = events[-1]
        content_raw = event.get('content', '')

        # Parse content - could be JSON or plain text
        try:
            content_data = json.loads(content_raw)
            user_message = content_data.get('content', content_raw)
            context = content_data.get('preceding_context', {})
        except:
            user_message = content_raw
            context = json.loads(event.get('context', '{}'))

        # Pattern matching (LLM analysis done by Claude Code at review time)
        trigger = self._infer_trigger_from_context(user_message, context)
        action = self._infer_action(user_message)

        if trigger == "when performing this action" and action == "follow the correct procedure":
            # Too vague, skip
            return None

        candidate = {
            "id": str(uuid.uuid4())[:8],
            "title": self._generate_title(trigger, action),
            "candidate_type": "rule",
            "trigger": trigger,
            "action": action,
            "evidence": [{"event_id": e['id'], "quote": e.get('content', '')[:100]} for e in events[:5]],
            "confidence": min(0.5 + (len(events) * 0.1), 0.95),
            "status": "pending",
            "created_at": datetime.now(timezone.utc).isoformat()
        }

        candidate["fingerprint"] = fingerprint_candidate(candidate)
        return candidate

    def _infer_trigger_from_context(self, user_message: str, context: Dict) -> str:
        """Infer trigger from user message and preceding context."""
        message_lower = user_message.lower()

        # Check recent tool calls for what might have been wrong
        recent_tools = context.get('recent_tool_calls', [])
        if recent_tools:
            last_tool = recent_tools[-1] if recent_tools else {}
            last_command = last_tool.get('command', '')

            # If correction mentions specific action
            if 'resolve' in message_lower and 'review' in message_lower:
                return "when PR review comments are addressed"
            if 'merge' in message_lower:
                return "when attempting to merge PRs"
            if 'push' in message_lower:
                return "when pushing changes to remote"

        # Pattern-based inference
        if 'edit' in message_lower and 'generated' in message_lower:
            return "when editing generated files"

        if 'don\'t' in message_lower or 'stop' in message_lower:
            parts = message_lower.split('don\'t') if 'don\'t' in message_lower else message_lower.split('stop')
            if len(parts) > 1:
                action_part = parts[1].strip()[:50]
                return f"when attempting to {action_part}"

        if 'literally' in message_lower:
            return "when task completion is claimed but not actually done"

        return "when performing this action"

    def _infer_action(self, user_message: str) -> str:
        """Infer action from user message."""
        message_lower = user_message.lower()

        # Look for explicit instructions
        if 'instead' in message_lower:
            parts = message_lower.split('instead')
            if len(parts) > 1:
                return parts[1].strip()[:100]

        if 'should' in message_lower:
            parts = message_lower.split('should')
            if len(parts) > 1:
                return parts[1].strip()[:100]

        if 'need to' in message_lower:
            parts = message_lower.split('need to')
            if len(parts) > 1:
                return parts[1].strip()[:100]

        if 'literally' in message_lower:
            # Extract what needs to be done literally
            parts = message_lower.split('literally')
            if len(parts) > 1:
                action = parts[1].strip()[:100]
                if action:
                    return f"LITERALLY {action}"

        return "follow the correct procedure"

    def _generate_title(self, trigger: str, action: str) -> str:
        """Generate a concise title for a candidate."""
        # Extract key words
        action_words = [w for w in action.split()[:6] if len(w) > 2]
        title = ' '.join(action_words).capitalize()
        return title if len(title) > 5 else "Handle this case correctly"

    def extract_candidate_from_repetition(self, events: List[Dict]) -> Optional[Dict]:
        """Extract a checklist candidate from repetition events."""
        if not events:
            return None

        event = events[0]
        try:
            content_data = json.loads(event.get('content', '{}'))
            similar_messages = content_data.get('similar_messages', [])
        except:
            similar_messages = []

        if not similar_messages:
            return None

        instruction = self._extract_core_instruction(similar_messages + [event.get('content', '')])

        if not instruction or len(instruction) < 10:
            return None

        candidate = {
            "id": str(uuid.uuid4())[:8],
            "title": f"Remember: {instruction[:50]}",
            "candidate_type": "checklist",
            "trigger": "before completing tasks",
            "action": instruction,
            "evidence": [{"event_id": event['id'], "similar_count": len(similar_messages)}],
            "confidence": min(0.5 + (len(similar_messages) * 0.15), 0.9),
            "status": "pending",
            "created_at": datetime.now(timezone.utc).isoformat()
        }

        candidate["fingerprint"] = fingerprint_candidate(candidate)
        return candidate

    def extract_candidate_from_skill_supplement(self, events: List[Dict]) -> List[Dict]:
        """Extract skill update candidates from skill supplement signals."""
        candidates = []

        for event in events:
            try:
                content = json.loads(event.get('content', '{}'))
            except:
                content = {"supplement_text": event.get('content', '')}

            skill_name = content.get('skill_name')
            supplement_text = content.get('supplement_text', '')

            if not supplement_text or len(supplement_text) < 20:
                continue

            # Create skill update candidate (LLM analysis done at review time)
            candidate = {
                "id": str(uuid.uuid4())[:8],
                "title": f"Update {skill_name or 'skill'} with missing guidance",
                "candidate_type": "skill",
                "trigger": f"when using {skill_name or 'this'} skill",
                "action": f"add guidance: {supplement_text[:200]}",
                "evidence": [{"event_id": event['id'], "supplement": supplement_text[:100]}],
                "confidence": 0.65,
                "status": "pending",
                "created_at": datetime.now(timezone.utc).isoformat(),
                "target_skill": skill_name
            }
            candidate["fingerprint"] = fingerprint_candidate(candidate)
            candidates.append(candidate)

        return candidates

    def extract_candidate_from_verification(self, events: List[Dict]) -> List[Dict]:
        """Extract checklist candidates from verification questions.

        When user asks 'did you run the tests?' it implies an expectation
        that wasn't automatically met - this should become a checklist item.
        """
        candidates = []

        # Group by verified action
        action_events = defaultdict(list)
        for event in events:
            try:
                content = json.loads(event.get('content', '{}'))
            except:
                content = {}

            action = content.get('verified_action', 'unknown')
            if action and action != 'unknown':
                action_events[action].append((event, content))

        for action, events_contents in action_events.items():
            # More occurrences = higher confidence this is a real pattern
            occurrence_count = len(events_contents)
            event, content = events_contents[-1]

            question_text = content.get('question_text', '')

            # Generate checklist candidate
            candidate = {
                "id": str(uuid.uuid4())[:8],
                "title": f"Remember to {action} before completing task",
                "candidate_type": "checklist",
                "trigger": f"before marking a task as complete",
                "action": f"always {action} - user had to ask '{question_text[:50]}...'",
                "evidence": [{"event_id": event['id'], "question": question_text[:100], "action": action}],
                "confidence": min(0.5 + (occurrence_count * 0.15), 0.85),
                "status": "pending",
                "created_at": datetime.now(timezone.utc).isoformat(),
                "verified_action": action,
                "occurrence_count": occurrence_count
            }
            candidate["fingerprint"] = fingerprint_candidate(candidate)
            candidates.append(candidate)

        return candidates

    def extract_candidate_from_version_issue(self, events: List[Dict]) -> List[Dict]:
        """Extract tool update candidates from version issue signals."""
        candidates = []

        # Group by tool
        tool_events = defaultdict(list)
        for event in events:
            try:
                content = json.loads(event.get('content', '{}'))
            except:
                content = {}

            tool = content.get('tool', 'unknown')
            tool_events[tool].append((event, content))

        for tool, events_contents in tool_events.items():
            if tool == 'unknown':
                continue

            event, content = events_contents[-1]  # Most recent
            matches = content.get('matches', [])
            stderr = content.get('stderr_preview', '')

            # Determine if deprecated or just outdated
            is_deprecated = any('deprecated' in str(m).lower() for m in matches)

            if is_deprecated:
                title = f"Replace deprecated {tool}"
                action = f"find alternative for {tool} - deprecated warnings detected"
                confidence = 0.80
            else:
                title = f"Update {tool} to latest version"
                action = f"upgrade {tool} - version issues detected in output"
                confidence = 0.70

            candidate = {
                "id": str(uuid.uuid4())[:8],
                "title": title,
                "candidate_type": "snippet",  # Tool updates are snippets
                "trigger": f"when using {tool}",
                "action": action,
                "evidence": [{"event_id": event['id'], "tool": tool, "matches": matches[:3]}],
                "confidence": confidence,
                "status": "pending",
                "created_at": datetime.now(timezone.utc).isoformat(),
                "tool_name": tool,
                "is_deprecated": is_deprecated
            }
            candidate["fingerprint"] = fingerprint_candidate(candidate)
            candidates.append(candidate)

        return candidates

    def _extract_core_instruction(self, messages: List[str]) -> str:
        """Extract the core repeated instruction."""
        if not messages:
            return ""

        # Use longest message as it likely has most context
        valid_messages = [m for m in messages if m and len(m) > 10]
        if valid_messages:
            return max(valid_messages, key=len)[:150]
        return messages[0][:150] if messages else ""

    def aggregate(self) -> List[Dict]:
        """Main aggregation function - process events into candidates."""
        events = self.get_unprocessed_events()

        if not events:
            return []

        groups = self.group_events_by_signal(events)
        candidates = []
        processed_ids = []

        # Process COMMAND_FAILURE first (highest signal)
        if 'COMMAND_FAILURE' in groups:
            failure_candidates = self.extract_candidate_from_failure(groups['COMMAND_FAILURE'])
            candidates.extend(failure_candidates)
            processed_ids.extend([e['id'] for e in groups['COMMAND_FAILURE']])

        # Process USER_CORRECTION
        if 'USER_CORRECTION' in groups:
            candidate = self.extract_candidate_from_correction(groups['USER_CORRECTION'])
            if candidate:
                candidates.append(candidate)
            processed_ids.extend([e['id'] for e in groups['USER_CORRECTION']])

        # Process REPETITION
        if 'REPETITION' in groups:
            candidate = self.extract_candidate_from_repetition(groups['REPETITION'])
            if candidate:
                candidates.append(candidate)
            processed_ids.extend([e['id'] for e in groups['REPETITION']])

        # Process SKILL_SUPPLEMENT (new: detect skill update opportunities)
        if 'SKILL_SUPPLEMENT' in groups:
            skill_candidates = self.extract_candidate_from_skill_supplement(groups['SKILL_SUPPLEMENT'])
            candidates.extend(skill_candidates)
            processed_ids.extend([e['id'] for e in groups['SKILL_SUPPLEMENT']])

        # Process VERSION_ISSUE (new: detect outdated tools)
        if 'VERSION_ISSUE' in groups:
            version_candidates = self.extract_candidate_from_version_issue(groups['VERSION_ISSUE'])
            candidates.extend(version_candidates)
            processed_ids.extend([e['id'] for e in groups['VERSION_ISSUE']])

        # Process VERIFICATION_QUESTION (user asking if something was done)
        if 'VERIFICATION_QUESTION' in groups:
            verification_candidates = self.extract_candidate_from_verification(groups['VERIFICATION_QUESTION'])
            candidates.extend(verification_candidates)
            processed_ids.extend([e['id'] for e in groups['VERIFICATION_QUESTION']])

        # Process TONE_ESCALATION (mark as processed, combine with other signals for context)
        if 'TONE_ESCALATION' in groups:
            processed_ids.extend([e['id'] for e in groups['TONE_ESCALATION']])

        # Mark events as processed
        self.mark_events_processed(processed_ids)

        # Deduplicate candidates
        candidates = self._deduplicate(candidates)

        # Filter out vague candidates
        candidates = [c for c in candidates if self._is_quality_candidate(c)]

        # Save candidates
        if candidates:
            self._save_candidates(candidates)

        return candidates

    def aggregate_with_transcript(self, verbose: bool = False) -> Tuple[List[Dict], Dict]:
        """Aggregate signals AND analyze transcript for comprehensive learning."""
        # First, run normal signal aggregation
        signal_candidates = self.aggregate()

        # Then analyze transcript for patterns we might have missed
        transcript_analysis = {}
        transcript_candidates = []

        if self.transcript_analyzer:
            if verbose:
                print("Analyzing session transcript...")

            transcript_analysis = self.transcript_analyzer.analyze_session()

            if 'error' not in transcript_analysis:
                transcript_candidates = self.transcript_analyzer.generate_candidates_from_analysis(
                    transcript_analysis
                )

                if verbose:
                    summary = transcript_analysis.get('summary', {})
                    print(f"  Found {summary.get('correction_count', 0)} corrections, "
                          f"{summary.get('failure_count', 0)} repeated failures, "
                          f"{summary.get('implicit_count', 0)} implicit corrections")

        # Combine and deduplicate
        all_candidates = signal_candidates + transcript_candidates
        all_candidates = self._deduplicate(all_candidates)
        all_candidates = [c for c in all_candidates if self._is_quality_candidate(c)]

        # Save the new candidates from transcript analysis
        if transcript_candidates:
            self._save_candidates(transcript_candidates)

        return all_candidates, transcript_analysis

    def _is_quality_candidate(self, candidate: Dict) -> bool:
        """Check if a candidate is specific enough to be useful."""
        trigger = candidate.get('trigger', '')
        action = candidate.get('action', '')

        # Reject vague triggers
        vague_triggers = ['when performing this action', 'when doing this']
        if trigger in vague_triggers:
            return False

        # Reject vague actions
        vague_actions = ['follow the correct procedure', 'do it correctly', 'handle appropriately']
        if action in vague_actions:
            return False

        # Require minimum length
        if len(trigger) < 15 or len(action) < 15:
            return False

        return True

    def _deduplicate(self, candidates: List[Dict]) -> List[Dict]:
        """Remove duplicate candidates."""
        seen_fingerprints = set()
        unique = []

        for c in candidates:
            fp = c.get('fingerprint')
            if fp and fp not in seen_fingerprints:
                seen_fingerprints.add(fp)
                unique.append(c)

        return unique

    def _save_candidates(self, new_candidates: List[Dict]):
        """Save candidates to file and ledger."""
        existing = {"pending": [], "approved": [], "rejected": [], "last_proposal": None}
        if CANDIDATES_FILE.exists():
            try:
                existing = json.loads(CANDIDATES_FILE.read_text())
            except:
                pass

        existing_fps = {c.get('fingerprint') for c in existing.get('pending', [])}
        for c in new_candidates:
            if c.get('fingerprint') not in existing_fps:
                existing['pending'].append(c)

        existing['last_proposal'] = datetime.now(timezone.utc).isoformat()

        COACH_DIR.mkdir(parents=True, exist_ok=True)
        CANDIDATES_FILE.write_text(json.dumps(existing, indent=2))
        self._update_ledger(new_candidates)

    def _update_ledger(self, candidates: List[Dict]):
        """Update the global ledger with new candidates."""
        if not LEDGER_DB.exists():
            return

        conn = sqlite3.connect(LEDGER_DB)

        try:
            result = subprocess.run(["git", "remote", "get-url", "origin"],
                                  capture_output=True, text=True, timeout=5)
            import hashlib
            repo_id = hashlib.sha256(result.stdout.strip().encode()).hexdigest()[:16] if result.returncode == 0 else hashlib.sha256(os.getcwd().encode()).hexdigest()[:16]
        except:
            import hashlib
            repo_id = hashlib.sha256(os.getcwd().encode()).hexdigest()[:16]

        for c in candidates:
            fp = c.get('fingerprint')
            if not fp:
                continue

            cursor = conn.execute("SELECT repo_ids, count FROM candidates WHERE fingerprint = ?", (fp,))
            row = cursor.fetchone()

            now = datetime.now(timezone.utc).isoformat()

            if row:
                repo_ids = json.loads(row[0]) if row[0] else []
                if repo_id not in repo_ids:
                    repo_ids.append(repo_id)

                conn.execute("""
                    UPDATE candidates
                    SET repo_ids = ?, count = ?, last_seen = ?, updated_at = ?
                    WHERE fingerprint = ?
                """, (json.dumps(repo_ids), row[1] + 1, now, now, fp))
            else:
                conn.execute("""
                    INSERT INTO candidates
                    (fingerprint, normalized_text, title, candidate_type, trigger_condition,
                     action, repo_ids, evidence, confidence, first_seen, last_seen)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    fp,
                    f"{c.get('trigger', '')} {c.get('action', '')}",
                    c.get('title', ''),
                    c.get('candidate_type', 'rule'),
                    c.get('trigger', ''),
                    c.get('action', ''),
                    json.dumps([repo_id]),
                    json.dumps(c.get('evidence', [])),
                    c.get('confidence', 0.5),
                    now, now
                ))

        conn.commit()
        conn.close()


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Aggregate signals into candidates")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--dry-run", action="store_true", help="Don't save candidates")
    parser.add_argument("--no-transcript", action="store_true", help="Skip transcript analysis")
    parser.add_argument("--transcript-only", action="store_true", help="Only analyze transcript")
    # Note: --no-llm removed - LLM analysis now done by Claude Code at /coach:review time

    args = parser.parse_args()

    aggregator = CandidateAggregator(
        analyze_transcript=not args.no_transcript
    )

    if args.transcript_only:
        # Only do transcript analysis
        if aggregator.transcript_analyzer:
            analysis = aggregator.transcript_analyzer.analyze_session()
            if 'error' in analysis:
                print(f"Error: {analysis['error']}")
                return 1

            if args.verbose:
                print(f"Transcript: {analysis.get('transcript_path', 'unknown')}")
                counts = analysis.get('message_counts', {})
                print(f"Messages: {counts.get('user', 0)} user, {counts.get('assistant', 0)} assistant, {counts.get('tool_calls', 0)} tool calls")

                summary = analysis.get('summary', {})
                print(f"\nPatterns detected:")
                print(f"  Corrections: {summary.get('correction_count', 0)}")
                print(f"  Repeated failures: {summary.get('failure_count', 0)}")
                print(f"  Implicit corrections: {summary.get('implicit_count', 0)}")

                high_intensity = summary.get('high_intensity_corrections', [])
                if high_intensity:
                    print(f"\n  High-intensity corrections ({len(high_intensity)}):")
                    for c in high_intensity[:3]:
                        print(f"    - {c.get('message', '')[:80]}...")

            candidates = aggregator.transcript_analyzer.generate_candidates_from_analysis(analysis)
            if candidates:
                print(f"\nGenerated {len(candidates)} candidates from transcript")
                for c in candidates:
                    print(f"  [{c['candidate_type']}] {c['title']}")
        return 0

    # Full aggregation with transcript analysis
    candidates, transcript_analysis = aggregator.aggregate_with_transcript(verbose=args.verbose)

    if args.verbose:
        print(f"\nGenerated {len(candidates)} total candidates:")
        for c in candidates:
            llm_tag = " [LLM]" if c.get('llm_generated') else ""
            transcript_tag = " [transcript]" if c.get('from_transcript') else ""
            print(f"  [{c['candidate_type']}] {c['title']} (confidence: {c['confidence']:.2f}){llm_tag}{transcript_tag}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
