#!/usr/bin/env python3
"""
Aggregate friction signals into learning candidates.
Runs after turns or at session end to batch process signals.

v2.1 - Improved with:
- Better context extraction from signals
- LLM-assisted candidate generation (when available)
- Smarter failure pattern recognition
- Repeated failure detection
- Session-end transcript analysis
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

COACH_DIR = Path.home() / ".claude-coach"
EVENTS_DB = COACH_DIR / "events.sqlite"
LEDGER_DB = COACH_DIR / "ledger.sqlite"
CANDIDATES_FILE = COACH_DIR / "candidates.json"
CONFIG_FILE = COACH_DIR / "config.json"
CONTEXT_FILE = COACH_DIR / "recent_context.json"


class LLMCandidateGenerator:
    """Generate high-quality candidates using LLM when available."""

    def __init__(self):
        self.available = self._check_availability()

    def _check_availability(self) -> bool:
        """Check if LLM generation is available."""
        try:
            import anthropic
            return bool(os.environ.get("ANTHROPIC_API_KEY"))
        except ImportError:
            return False

    def generate_candidate_from_failure(self, command: str, stderr: str, exit_code: int,
                                        context: Dict) -> Optional[Dict]:
        """Use LLM to generate a better candidate from failure context."""
        if not self.available:
            return None

        try:
            import anthropic
            client = anthropic.Anthropic()

            prompt = f"""Analyze this command failure and generate a learning rule.

Command: {command}
Exit code: {exit_code}
Error: {stderr[:500]}

Recent context:
{json.dumps(context.get('recent_tool_calls', [])[-3:], indent=2)}

Generate a JSON object with:
- title: Short descriptive title (5-10 words)
- trigger: When this situation occurs (be specific)
- action: What should be done instead (be specific and actionable)
- candidate_type: "rule" or "snippet"

Focus on the ROOT CAUSE and provide a specific, actionable solution.
Return ONLY valid JSON, no explanation."""

            response = client.messages.create(
                model="claude-3-haiku-20240307",  # Fast and cheap for this
                max_tokens=300,
                messages=[{"role": "user", "content": prompt}]
            )

            result = json.loads(response.content[0].text)
            return result

        except Exception as e:
            return None

    def generate_candidate_from_correction(self, user_message: str, context: Dict) -> Optional[Dict]:
        """Use LLM to understand what was being corrected."""
        if not self.available:
            return None

        try:
            import anthropic
            client = anthropic.Anthropic()

            recent_actions = context.get('recent_actions', [])
            recent_tools = context.get('recent_tool_calls', [])

            prompt = f"""Analyze this user correction and generate a learning rule.

User said: {user_message}

Recent assistant actions:
{json.dumps(recent_actions[-3:], indent=2)}

Recent tool calls:
{json.dumps(recent_tools[-3:], indent=2)}

Generate a JSON object with:
- title: Short descriptive title (5-10 words)
- trigger: When this situation occurs (be specific about what action triggered the correction)
- action: What should be done instead (be specific and actionable)
- candidate_type: "rule"

Focus on understanding WHAT the assistant did wrong and HOW to do it correctly.
Return ONLY valid JSON, no explanation."""

            response = client.messages.create(
                model="claude-3-haiku-20240307",
                max_tokens=300,
                messages=[{"role": "user", "content": prompt}]
            )

            result = json.loads(response.content[0].text)
            return result

        except Exception as e:
            return None


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

    def __init__(self, llm_generator: Optional[LLMCandidateGenerator] = None):
        self.llm_generator = llm_generator
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
        """Extract user messages, assistant messages, and tool calls from transcript."""
        user_messages = []
        assistant_messages = []
        tool_calls = []

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
        """Detect repeated concerning tool calls in transcript."""
        command_counts = defaultdict(list)

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

                command_counts[base].append({
                    'command': command,
                    'tool': tool_name
                })

        # Return only concerning commands that ran many times
        repeated = []
        for base, calls in command_counts.items():
            # Only flag if it ran 3+ times (suggests retry loop)
            if len(calls) >= 3:
                # Prioritize known concerning commands
                is_concerning = any(concern in base for concern in self.CONCERNING_COMMANDS)
                if is_concerning or len(calls) >= 5:
                    repeated.append({
                        'base_command': base,
                        'occurrences': len(calls),
                        'commands': calls[:5],  # Limit to 5 examples
                        'is_concerning': is_concerning
                    })

        # Sort by concern level and occurrence count
        repeated.sort(key=lambda x: (not x.get('is_concerning', False), -x['occurrences']))
        return repeated

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

    def generate_candidates_from_analysis(self, analysis: Dict) -> List[Dict]:
        """Generate learning candidates from session analysis."""
        candidates = []
        patterns = analysis.get('patterns', {})

        # Generate from high-intensity corrections
        for correction in patterns.get('corrections', []):
            if correction.get('intensity', 0) >= 2:
                # Try LLM-assisted generation
                if self.llm_generator and self.llm_generator.available:
                    context = {
                        'preceding_messages': correction.get('context_before', []),
                        'patterns_matched': correction.get('patterns_matched', [])
                    }
                    llm_result = self.llm_generator.generate_candidate_from_correction(
                        correction['message'], context
                    )
                    if llm_result:
                        candidate = {
                            "id": str(uuid.uuid4())[:8],
                            "title": llm_result.get('title', 'Learn from correction'),
                            "candidate_type": llm_result.get('candidate_type', 'rule'),
                            "trigger": llm_result.get('trigger', ''),
                            "action": llm_result.get('action', ''),
                            "evidence": [{"source": "transcript_analysis", "quote": correction['message'][:100]}],
                            "confidence": 0.85,
                            "status": "pending",
                            "created_at": datetime.now(timezone.utc).isoformat(),
                            "llm_generated": True,
                            "from_transcript": True
                        }
                        candidate["fingerprint"] = fingerprint_candidate(candidate)
                        candidates.append(candidate)

        # Generate from repeated failures
        for failure in patterns.get('repeated_failures', []):
            if failure.get('occurrences', 0) >= 2:
                base_cmd = failure.get('base_command', 'command')
                candidate = {
                    "id": str(uuid.uuid4())[:8],
                    "title": f"Investigate repeated {base_cmd} failures",
                    "candidate_type": "rule",
                    "trigger": f"when {base_cmd} fails multiple times",
                    "action": f"stop and investigate root cause before retrying - {failure['occurrences']}x failures detected",
                    "evidence": [{"source": "transcript_analysis", "commands": failure.get('commands', [])[:2]}],
                    "confidence": 0.80,
                    "status": "pending",
                    "created_at": datetime.now(timezone.utc).isoformat(),
                    "from_transcript": True
                }
                candidate["fingerprint"] = fingerprint_candidate(candidate)
                candidates.append(candidate)

        return candidates


class CandidateAggregator:
    """Aggregates signals into learning candidates."""

    def __init__(self, use_llm: bool = True, analyze_transcript: bool = True):
        self.fingerprinter = Fingerprinter()
        self.config = self._load_config()
        self.min_evidence = self.config.get("min_evidence_count", 1)  # Lowered for failures
        self.llm_generator = LLMCandidateGenerator() if use_llm else None
        self.transcript_analyzer = TranscriptAnalyzer(self.llm_generator) if analyze_transcript else None

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

            # Try LLM-assisted generation first
            if self.llm_generator and self.llm_generator.available:
                llm_result = self.llm_generator.generate_candidate_from_failure(
                    command, stderr, exit_code, context
                )
                if llm_result:
                    candidate = {
                        "id": str(uuid.uuid4())[:8],
                        "title": llm_result.get('title', f"Handle {base_cmd} failures"),
                        "candidate_type": llm_result.get('candidate_type', 'rule'),
                        "trigger": llm_result.get('trigger', f"when running {base_cmd}"),
                        "action": llm_result.get('action', 'handle error appropriately'),
                        "evidence": [{"event_id": e['id'], "stderr": json.loads(e.get('content', '{}')).get('stderr_preview', '')[:100]}
                                    for e in cmd_events[:3]],
                        "confidence": 0.90,
                        "status": "pending",
                        "created_at": datetime.now(timezone.utc).isoformat(),
                        "llm_generated": True
                    }
                    candidate["fingerprint"] = fingerprint_candidate(candidate)
                    candidates.append(candidate)
                    continue

            # Fall back to pattern-based extraction
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

        # Try LLM-assisted generation
        if self.llm_generator and self.llm_generator.available:
            llm_result = self.llm_generator.generate_candidate_from_correction(
                user_message, context
            )
            if llm_result:
                candidate = {
                    "id": str(uuid.uuid4())[:8],
                    "title": llm_result.get('title', 'Follow correct procedure'),
                    "candidate_type": llm_result.get('candidate_type', 'rule'),
                    "trigger": llm_result.get('trigger', 'when performing this action'),
                    "action": llm_result.get('action', 'follow the correct procedure'),
                    "evidence": [{"event_id": e['id'], "quote": e.get('content', '')[:100]} for e in events[:3]],
                    "confidence": 0.85,
                    "status": "pending",
                    "created_at": datetime.now(timezone.utc).isoformat(),
                    "llm_generated": True
                }
                candidate["fingerprint"] = fingerprint_candidate(candidate)
                return candidate

        # Fall back to pattern matching
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
    parser.add_argument("--no-llm", action="store_true", help="Disable LLM-assisted generation")
    parser.add_argument("--no-transcript", action="store_true", help="Skip transcript analysis")
    parser.add_argument("--transcript-only", action="store_true", help="Only analyze transcript")

    args = parser.parse_args()

    aggregator = CandidateAggregator(
        use_llm=not args.no_llm,
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
