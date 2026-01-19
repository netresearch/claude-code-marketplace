#!/usr/bin/env python3
"""
Detect friction signals from user messages, assistant responses, and tool results.
Stores detected signals in the events database for later aggregation.

v2.1 - Improved with:
- Proper stdin handling for hooks
- Expanded failure patterns
- Context capture from preceding messages
- Better error pattern matching
- Skill supplement detection (suggests skill updates)
- Outdated tool/version detection
"""

import os
import sys
import re
import json
import sqlite3
import hashlib
import argparse
from pathlib import Path
from datetime import datetime, UTC
from typing import Optional, Dict, Any, List
import uuid

COACH_DIR = Path.home() / ".claude-coach"
EVENTS_DB = COACH_DIR / "events.sqlite"
CONFIG_FILE = COACH_DIR / "config.json"
CONTEXT_FILE = COACH_DIR / "recent_context.json"


class SignalDetector:
    """Detects friction signals from various inputs."""

    SIGNAL_TYPES = {
        "COMMAND_FAILURE": 100,  # Priority weight
        "USER_CORRECTION": 80,
        "SKILL_SUPPLEMENT": 75,  # User supplementing a skill with additional info
        "VERIFICATION_QUESTION": 72,  # User asking if something was done (implicit expectation)
        "VERSION_ISSUE": 70,     # Outdated tool/dependency detected
        "REPETITION": 60,
        "TONE_ESCALATION": 40
    }

    def __init__(self):
        self.config = self._load_config()
        self.patterns = self._compile_patterns()
        self.recent_context = self._load_recent_context()

    def _load_config(self) -> Dict:
        """Load configuration from file."""
        if CONFIG_FILE.exists():
            try:
                return json.loads(CONFIG_FILE.read_text())
            except:
                pass
        return self._default_config()

    def _default_config(self) -> Dict:
        return {
            "signal_patterns": {
                "correction": [
                    r"\bno\b", r"\bstop\b", r"\bdon'?t\b", r"i said",
                    r"you didn'?t", r"why did you", r"that's wrong",
                    r"not what i", r"i meant", r"should have"
                ],
                "escalation": [
                    r"[A-Z]{3,}", r"!{2,}", r"\bagain\b", r"for the last time",
                    r"how many times", r"already told you", r"LITERALLY"
                ],
                "failure_stderr": [
                    # System errors
                    r"ENOENT", r"ECONNREFUSED", r"ETIMEDOUT", r"EPERM",
                    r"command not found", r"permission denied", r"no such file",
                    # Git/GitHub errors
                    r"merge queue", r"not allowed", r"Cannot use",
                    r"merge strategy", r"is not mergeable", r"blocked",
                    r"required status", r"protected branch", r"not fast-forward",
                    # Auth/API errors
                    r"401", r"403", r"404", r"422", r"500", r"502", r"503",
                    r"unauthorized", r"forbidden", r"rate limit",
                    # Build/test errors
                    r"failed to", r"error:", r"Error:", r"FAILED",
                    r"compilation failed", r"build failed", r"test failed",
                    # Package manager errors
                    r"npm ERR", r"yarn error", r"pip error", r"go: ",
                    r"composer.*(?:error|failed)", r"--ignore-platform-req",
                    r"ext-\w+", r"php.*(?:fatal|error|warning)",
                    r"require.*php", r"platform.*requirement",
                    # Generic failure indicators
                    r"fatal:", r"panic:", r"exception", r"traceback"
                ],
                "failure_commands": [
                    # Commands that commonly fail in specific ways
                    r"gh pr merge",
                    r"git push",
                    r"git rebase",
                    r"npm install",
                    r"docker build",
                    r"composer (?:install|update|require|remove)",
                    r"phpunit",
                    r"phpstan"
                ],
                "skill_supplement": [
                    # Patterns indicating user is supplementing a skill
                    r"also\s+(?:need|remember|make\s+sure)",
                    r"but\s+(?:also|don'?t\s+forget)",
                    r"(?:the\s+)?skill\s+(?:doesn'?t|does\s+not|didn'?t)",
                    r"(?:it|skill)\s+(?:missed|forgot|should\s+also)",
                    r"add\s+(?:this\s+)?to\s+(?:the\s+)?skill",
                    r"update\s+(?:the\s+)?skill",
                    r"skill\s+(?:is\s+)?(?:wrong|outdated|incomplete)"
                ],
                "verification_question": [
                    # User asking if something was done (implies expectation)
                    r"did you\s+(?:also\s+)?(?:run|test|check|update|add|fix|commit|push|build)",
                    r"have you\s+(?:also\s+)?(?:run|tested|checked|updated|added|fixed)",
                    r"was\s+(?:the|this|that)\s+(?:test|build|check)",
                    r"(?:were|are)\s+(?:the\s+)?tests?\s+(?:run|passed|executed)",
                    r"what about\s+(?:the\s+)?(?:tests?|build|commit)",
                    r"you\s+(?:didn'?t|did\s+not)\s+(?:run|test|check|commit|push)",
                ],
                "version_issues": [
                    # Patterns indicating version/outdated issues
                    r"(?:requires|needs|minimum)\s+(?:version\s+)?(\d+\.[\d.]+)",
                    r"(?:deprecated|obsolete|outdated)",
                    r"upgrade\s+(?:to\s+)?(?:version\s+)?",
                    r"(?:npm|yarn|pnpm)\s+(?:WARN|warn).*(?:deprecated|outdated)",
                    r"pip.*(?:WARNING|warning).*(?:deprecated|outdated)",
                    r"version\s+(\d+\.[\d.]+).*(?:is\s+)?(?:old|outdated|unsupported)"
                ]
            }
        }

    def _compile_patterns(self) -> Dict[str, List[re.Pattern]]:
        """Compile regex patterns for signal detection."""
        patterns = {}
        for category, pattern_list in self.config.get("signal_patterns", {}).items():
            patterns[category] = [re.compile(p, re.IGNORECASE) for p in pattern_list]
        return patterns

    def _load_recent_context(self) -> Dict:
        """Load recent context (last few tool calls, messages)."""
        if CONTEXT_FILE.exists():
            try:
                return json.loads(CONTEXT_FILE.read_text())
            except:
                pass
        return {"tool_calls": [], "messages": [], "assistant_actions": []}

    def _save_recent_context(self):
        """Save recent context for cross-call learning."""
        # Keep only last 20 items in each list
        for key in self.recent_context:
            if isinstance(self.recent_context[key], list):
                self.recent_context[key] = self.recent_context[key][-20:]

        COACH_DIR.mkdir(parents=True, exist_ok=True)
        CONTEXT_FILE.write_text(json.dumps(self.recent_context, indent=2))

    def add_tool_call_context(self, command: str, exit_code: int, stderr: str):
        """Add a tool call to recent context for pattern detection."""
        self.recent_context["tool_calls"].append({
            "command": command[:500],
            "exit_code": exit_code,
            "stderr": stderr[:500] if stderr else "",
            "timestamp": datetime.now(UTC).isoformat()
        })
        self._save_recent_context()

    def add_assistant_action(self, action: str):
        """Track what the assistant did (for correction context)."""
        self.recent_context["assistant_actions"].append({
            "action": action[:500],
            "timestamp": datetime.now(UTC).isoformat()
        })
        self._save_recent_context()

    def get_preceding_context(self) -> Dict:
        """Get context from recent activity for better signal interpretation."""
        return {
            "recent_tool_calls": self.recent_context.get("tool_calls", [])[-5:],
            "recent_messages": self.recent_context.get("messages", [])[-5:],
            "recent_actions": self.recent_context.get("assistant_actions", [])[-5:]
        }

    def detect_correction(self, content: str) -> Optional[Dict]:
        """Detect user correction patterns."""
        matches = []
        for pattern in self.patterns.get("correction", []):
            if pattern.search(content):
                matches.append(pattern.pattern)

        if matches:
            return {
                "signal_type": "USER_CORRECTION",
                "matches": matches,
                "confidence": min(0.3 + (len(matches) * 0.2), 1.0),
                "preceding_context": self.get_preceding_context()
            }
        return None

    def detect_escalation(self, content: str) -> Optional[Dict]:
        """Detect tone escalation patterns."""
        matches = []
        for pattern in self.patterns.get("escalation", []):
            if pattern.search(content):
                matches.append(pattern.pattern)

        # Count ALL CAPS words
        caps_words = len(re.findall(r'\b[A-Z]{3,}\b', content))
        exclamation_count = content.count('!')

        if matches or caps_words >= 2 or exclamation_count >= 3:
            return {
                "signal_type": "TONE_ESCALATION",
                "matches": matches,
                "caps_words": caps_words,
                "exclamation_count": exclamation_count,
                "confidence": min(0.2 + (caps_words * 0.1) + (exclamation_count * 0.05), 0.8),
                "preceding_context": self.get_preceding_context()
            }
        return None

    def detect_repetition(self, content: str) -> Optional[Dict]:
        """Detect repeated instructions using simple similarity."""
        history = self.recent_context.get("messages", [])
        if not history:
            return None

        # Simple word-based similarity
        content_words = set(content.lower().split())

        similar_count = 0
        similar_messages = []

        for prev in history[-10:]:
            prev_text = prev.get("text", prev) if isinstance(prev, dict) else prev
            prev_words = set(prev_text.lower().split())
            if not prev_words:
                continue

            # Jaccard similarity
            intersection = len(content_words & prev_words)
            union = len(content_words | prev_words)
            similarity = intersection / union if union > 0 else 0

            if similarity > 0.5:
                similar_count += 1
                similar_messages.append(prev_text[:100])

        if similar_count >= 2:
            return {
                "signal_type": "REPETITION",
                "similar_count": similar_count,
                "similar_messages": similar_messages[:3],
                "confidence": min(0.4 + (similar_count * 0.15), 0.95)
            }
        return None

    def detect_command_failure(self, exit_code: int, stderr: str, command: str) -> Optional[Dict]:
        """Detect command/tool failures with expanded patterns."""
        # Check for repeated similar failures
        recent_failures = [
            tc for tc in self.recent_context.get("tool_calls", [])[-10:]
            if tc.get("exit_code", 0) != 0
        ]

        similar_failures = []
        for f in recent_failures:
            # Check if same command pattern failed before
            if self._commands_similar(f.get("command", ""), command):
                similar_failures.append(f)

        if exit_code == 0 and not stderr:
            # Track successful call for context
            self.add_tool_call_context(command, exit_code, stderr)
            return None

        matches = []
        for pattern in self.patterns.get("failure_stderr", []):
            if stderr and pattern.search(stderr):
                matches.append(pattern.pattern)

        # Check if this is a known problematic command
        command_matches = []
        for pattern in self.patterns.get("failure_commands", []):
            if pattern.search(command):
                command_matches.append(pattern.pattern)

        if exit_code != 0 or matches:
            # Track this failure
            self.add_tool_call_context(command, exit_code, stderr)

            return {
                "signal_type": "COMMAND_FAILURE",
                "exit_code": exit_code,
                "stderr_preview": stderr[:1000] if stderr else None,
                "command": command[:500] if command else None,
                "stderr_matches": matches,
                "command_matches": command_matches,
                "similar_recent_failures": len(similar_failures),
                "confidence": min(0.7 + (0.1 * len(similar_failures)), 0.99),
                "preceding_context": self.get_preceding_context()
            }
        return None

    def _commands_similar(self, cmd1: str, cmd2: str) -> bool:
        """Check if two commands are similar (same base command)."""
        # Extract base command (first word or first two words)
        def base(cmd):
            parts = cmd.strip().split()[:2]
            return " ".join(parts).lower()

        return base(cmd1) == base(cmd2)

    def detect_skill_supplement(self, content: str) -> Optional[Dict]:
        """Detect when user is supplementing a skill with additional info."""
        matches = []
        for pattern in self.patterns.get("skill_supplement", []):
            if pattern.search(content):
                matches.append(pattern.pattern)

        if matches:
            # Try to extract which skill is being referenced
            skill_name = self._extract_skill_reference(content)

            return {
                "signal_type": "SKILL_SUPPLEMENT",
                "matches": matches,
                "skill_name": skill_name,
                "supplement_text": content[:500],
                "confidence": min(0.5 + (len(matches) * 0.15), 0.90),
                "preceding_context": self.get_preceding_context()
            }
        return None

    def detect_verification_question(self, content: str) -> Optional[Dict]:
        """Detect when user asks if something was done (implies missed expectation)."""
        matches = []
        for pattern in self.patterns.get("verification_question", []):
            match = pattern.search(content)
            if match:
                matches.append({
                    "pattern": pattern.pattern,
                    "matched_text": match.group(0)
                })

        if matches:
            # Extract what action was being verified
            action = self._extract_verified_action(content)

            return {
                "signal_type": "VERIFICATION_QUESTION",
                "matches": matches,
                "verified_action": action,
                "question_text": content[:500],
                "confidence": min(0.6 + (len(matches) * 0.1), 0.85),
                "preceding_context": self.get_preceding_context()
            }
        return None

    def _extract_verified_action(self, content: str) -> Optional[str]:
        """Extract what action was being verified from the question."""
        content_lower = content.lower()

        # Common actions being verified
        actions = {
            'run': ['run', 'execute', 'ran'],
            'test': ['test', 'tested', 'tests'],
            'check': ['check', 'checked', 'verify'],
            'commit': ['commit', 'committed'],
            'push': ['push', 'pushed'],
            'build': ['build', 'built', 'compile'],
            'update': ['update', 'updated'],
            'fix': ['fix', 'fixed'],
        }

        for action, keywords in actions.items():
            for kw in keywords:
                if kw in content_lower:
                    return action

        return None

    def _extract_skill_reference(self, content: str) -> Optional[str]:
        """Extract skill name from message."""
        # Pattern to find skill names
        skill_patterns = [
            r'(?:the\s+)?(\w+[-_]?\w*)\s+skill',
            r'skill\s+(?:for\s+)?(\w+[-_]?\w*)',
        ]

        for pattern in skill_patterns:
            match = re.search(pattern, content, re.IGNORECASE)
            if match:
                return match.group(1)

        return None

    def detect_version_issue(self, stderr: str, command: str) -> Optional[Dict]:
        """Detect version/outdated tool issues from command output."""
        matches = []
        for pattern in self.patterns.get("version_issues", []):
            match = pattern.search(stderr)
            if match:
                matches.append({
                    "pattern": pattern.pattern,
                    "match": match.group(0)
                })

        if matches:
            # Extract tool name from command
            tool = command.split()[0] if command else "unknown"

            return {
                "signal_type": "VERSION_ISSUE",
                "tool": tool,
                "command": command[:200],
                "matches": matches,
                "stderr_preview": stderr[:500],
                "confidence": min(0.6 + (len(matches) * 0.1), 0.85),
                "preceding_context": self.get_preceding_context()
            }
        return None

    def process_user_message(self, content: str, context: Dict = None) -> List[Dict]:
        """Process a user message for friction signals."""
        signals = []

        # Add to message history
        self.recent_context.setdefault("messages", []).append({
            "text": content[:500],
            "timestamp": datetime.now(UTC).isoformat()
        })
        self._save_recent_context()

        # Check for corrections
        correction = self.detect_correction(content)
        if correction:
            signals.append({
                **correction,
                "content": content[:500],
                "context": context
            })

        # Check for escalation
        escalation = self.detect_escalation(content)
        if escalation:
            signals.append({
                **escalation,
                "content": content[:500],
                "context": context
            })

        # Check for repetition
        repetition = self.detect_repetition(content)
        if repetition:
            signals.append({
                **repetition,
                "content": content[:500],
                "context": context
            })

        # Check for skill supplementation
        skill_supplement = self.detect_skill_supplement(content)
        if skill_supplement:
            signals.append({
                **skill_supplement,
                "content": content[:500],
                "context": context
            })

        # Check for verification questions (user asking if something was done)
        verification = self.detect_verification_question(content)
        if verification:
            signals.append({
                **verification,
                "content": content[:500],
                "context": context
            })

        return signals

    def process_tool_result(self, exit_code: int, stderr: str,
                           command: str, context: Dict = None) -> List[Dict]:
        """Process a tool result for failure signals."""
        signals = []

        failure = self.detect_command_failure(exit_code, stderr, command)
        if failure:
            signals.append({
                **failure,
                "context": context
            })

        # Check for version/outdated issues in stderr
        if stderr:
            version_issue = self.detect_version_issue(stderr, command)
            if version_issue:
                signals.append({
                    **version_issue,
                    "context": context
                })

        return signals


def get_repo_id() -> str:
    """Get a stable hash of the current repository."""
    try:
        import subprocess
        result = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0 and result.stdout.strip():
            return hashlib.sha256(result.stdout.strip().encode()).hexdigest()[:16]
    except:
        pass
    return hashlib.sha256(os.getcwd().encode()).hexdigest()[:16]


def store_signal(signal: Dict, event_type: str) -> str:
    """Store a detected signal in the events database."""
    if not EVENTS_DB.exists():
        print("Coach not initialized. Run: python init_coach.py", file=sys.stderr)
        return None

    event_id = str(uuid.uuid4())[:8]
    timestamp = datetime.now(UTC).isoformat()
    repo_id = get_repo_id()

    conn = sqlite3.connect(EVENTS_DB)
    conn.execute("""
        INSERT INTO events (id, timestamp, event_type, signal_type, repo_id, content, context)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (
        event_id,
        timestamp,
        event_type,
        signal.get("signal_type"),
        repo_id,
        json.dumps(signal),  # Store full signal as content
        json.dumps(signal.get("preceding_context", {}))
    ))
    conn.commit()
    conn.close()

    return event_id


def main():
    # Auto-heal hook paths on first run
    try:
        from hook_healer import ensure_stable_hooks
        ensure_stable_hooks()
    except Exception:
        pass  # Don't fail if healing fails

    parser = argparse.ArgumentParser(description="Detect friction signals")
    parser.add_argument("--phase", choices=["pre", "post", "tool"], required=True,
                       help="Processing phase")
    parser.add_argument("--content", type=str, help="Message content (or read from stdin)")
    parser.add_argument("--exit-code", type=int, default=None, help="Tool exit code")
    parser.add_argument("--stderr", type=str, default="", help="Tool stderr")
    parser.add_argument("--command", type=str, default="", help="Tool command")
    parser.add_argument("--from-stdin", action="store_true", help="Read JSON data from stdin")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")

    args = parser.parse_args()

    detector = SignalDetector()
    signals = []

    # Handle stdin input for hooks
    if args.from_stdin or (args.phase == "tool" and args.exit_code is None):
        try:
            stdin_data = sys.stdin.read()
            if stdin_data.strip():
                data = json.loads(stdin_data)

                if args.phase == "tool":
                    # Extract from Claude Code hook format
                    tool_result = data.get("tool_result", {})
                    tool_input = data.get("tool_input", {})

                    exit_code = tool_result.get("exit_code", 0)
                    stderr = tool_result.get("stderr", "") or tool_result.get("output", "")
                    command = tool_input.get("command", "")

                    # Handle case where output contains error info
                    if not stderr and tool_result.get("output"):
                        output = tool_result.get("output", "")
                        if "error" in output.lower() or "Error" in output:
                            stderr = output

                    signals = detector.process_tool_result(exit_code, stderr, command)

                elif args.phase == "pre":
                    content = data.get("content", "") or data.get("message", "")
                    if content:
                        signals = detector.process_user_message(content)
        except json.JSONDecodeError:
            # Not JSON, treat as plain text
            if args.phase == "pre":
                signals = detector.process_user_message(stdin_data)
        except Exception as e:
            if args.verbose:
                print(f"Error processing stdin: {e}", file=sys.stderr)

    # Handle explicit arguments
    elif args.phase == "pre" and args.content:
        signals = detector.process_user_message(args.content)
    elif args.phase == "tool" and args.exit_code is not None:
        signals = detector.process_tool_result(
            args.exit_code, args.stderr, args.command
        )

    # Store detected signals
    for signal in signals:
        event_id = store_signal(signal, args.phase)
        if args.verbose and event_id:
            print(f"Stored signal {event_id}: {signal['signal_type']} (confidence: {signal.get('confidence', 0):.2f})")

    if args.verbose:
        print(f"Detected {len(signals)} signals")

    return 0


if __name__ == "__main__":
    sys.exit(main())
