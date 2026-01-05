#!/usr/bin/env python3
"""
Analyze skills and tools for improvement opportunities.

Detects:
- Skills that need updates (missing patterns, outdated info)
- Outdated CLI tools and dependencies
- Skill gaps (user supplementing with manual instructions)

v1.0 - Initial implementation
"""

import os
import sys
import json
import re
import subprocess
from pathlib import Path
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple, Any
from collections import defaultdict

sys.path.insert(0, str(Path(__file__).parent))
from fingerprint import fingerprint_candidate

COACH_DIR = Path.home() / ".claude-coach"
CLAUDE_DIR = Path.home() / ".claude"
SKILLS_DIR = CLAUDE_DIR / "skills"


class SkillAnalyzer:
    """Analyze skills for improvement opportunities."""

    # Patterns that indicate skill supplementation
    SKILL_SUPPLEMENT_PATTERNS = [
        r'also\s+(?:need|remember|make\s+sure)',
        r'but\s+(?:also|don\'t\s+forget)',
        r'(?:the\s+)?skill\s+(?:doesn\'t|does\s+not|didn\'t)',
        r'(?:it|skill)\s+(?:missed|forgot|should\s+also)',
        r'add\s+(?:this\s+)?to\s+(?:the\s+)?skill',
        r'update\s+(?:the\s+)?skill',
        r'skill\s+(?:is\s+)?(?:wrong|outdated|incomplete)',
    ]

    # Patterns in corrections that reference skills
    SKILL_REFERENCE_PATTERNS = [
        r'(?:the\s+)?(\w+[-_]?\w*)\s+skill',
        r'in\s+(?:the\s+)?skill\s+(\w+[-_]?\w*)',
        r'skill\s+(?:for\s+)?(\w+[-_]?\w*)',
    ]

    def __init__(self):
        self.supplement_patterns = [re.compile(p, re.IGNORECASE) for p in self.SKILL_SUPPLEMENT_PATTERNS]
        self.reference_patterns = [re.compile(p, re.IGNORECASE) for p in self.SKILL_REFERENCE_PATTERNS]

    def get_installed_skills(self) -> Dict[str, Path]:
        """Get list of installed skills."""
        skills = {}

        # Check user skills directory
        if SKILLS_DIR.exists():
            for skill_dir in SKILLS_DIR.iterdir():
                if skill_dir.is_dir():
                    skill_md = skill_dir / "SKILL.md"
                    if skill_md.exists():
                        skills[skill_dir.name] = skill_dir

        # Check project skills
        cwd = Path.cwd()
        project_skills = cwd / ".claude" / "skills"
        if project_skills.exists():
            for skill_dir in project_skills.iterdir():
                if skill_dir.is_dir():
                    skill_md = skill_dir / "SKILL.md"
                    if skill_md.exists():
                        skills[f"project:{skill_dir.name}"] = skill_dir

        return skills

    def detect_skill_supplement(self, user_message: str, context: Dict) -> Optional[Dict]:
        """Detect if user is supplementing a skill with additional instructions."""
        message_lower = user_message.lower()

        # Check for skill supplementation patterns
        for pattern in self.supplement_patterns:
            if pattern.search(message_lower):
                # Try to identify which skill is being referenced
                skill_name = self._extract_skill_reference(user_message)

                return {
                    'type': 'skill_supplement',
                    'skill_name': skill_name,
                    'user_instruction': user_message,
                    'context': context
                }

        return None

    def detect_skill_reference(self, user_message: str) -> Optional[str]:
        """Extract skill name from user message."""
        return self._extract_skill_reference(user_message)

    def _extract_skill_reference(self, message: str) -> Optional[str]:
        """Extract skill name from a message."""
        for pattern in self.reference_patterns:
            match = pattern.search(message)
            if match:
                return match.group(1)

        # Check against installed skill names
        installed = self.get_installed_skills()
        message_lower = message.lower()
        for skill_name in installed:
            clean_name = skill_name.replace('project:', '')
            if clean_name.lower() in message_lower:
                return skill_name

        return None

    def analyze_skill_for_updates(self, skill_path: Path, failure_patterns: List[Dict]) -> List[Dict]:
        """Analyze a skill for potential updates based on failure patterns."""
        candidates = []

        skill_md = skill_path / "SKILL.md"
        if not skill_md.exists():
            return candidates

        skill_content = skill_md.read_text()
        skill_name = skill_path.name

        # Check if any failure patterns should be added to the skill
        for pattern in failure_patterns:
            trigger = pattern.get('trigger', '')
            action = pattern.get('action', '')

            # Check if this pattern is already in the skill
            if trigger.lower() not in skill_content.lower():
                candidate = {
                    "id": f"skill-{skill_name[:4]}-{hash(trigger) % 10000:04d}",
                    "title": f"Update {skill_name} skill with new pattern",
                    "candidate_type": "skill",
                    "trigger": f"when using {skill_name} skill",
                    "action": f"add guidance for: {trigger} → {action}",
                    "evidence": [{"pattern": pattern, "skill": skill_name}],
                    "confidence": 0.75,
                    "status": "pending",
                    "created_at": datetime.now(timezone.utc).isoformat(),
                    "target_skill": skill_name,
                    "target_path": str(skill_path)
                }
                candidate["fingerprint"] = fingerprint_candidate(candidate)
                candidates.append(candidate)

        return candidates

    def generate_skill_update_candidate(self, skill_name: str, supplement: str,
                                        context: Dict) -> Optional[Dict]:
        """Generate a candidate to update a skill based on user supplement."""
        if not skill_name:
            return None

        installed = self.get_installed_skills()
        skill_path = installed.get(skill_name)

        candidate = {
            "id": f"skill-upd-{hash(supplement) % 100000:05d}",
            "title": f"Update {skill_name} skill",
            "candidate_type": "skill",
            "trigger": f"when {skill_name} skill is activated",
            "action": f"include guidance: {supplement[:200]}",
            "evidence": [{"user_supplement": supplement[:100], "context": context}],
            "confidence": 0.70,
            "status": "pending",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "target_skill": skill_name,
            "target_path": str(skill_path) if skill_path else None
        }
        candidate["fingerprint"] = fingerprint_candidate(candidate)
        return candidate


class OutdatedToolAnalyzer:
    """Detect outdated tools and dependencies."""

    # Patterns that indicate version/outdated issues
    VERSION_ISSUE_PATTERNS = [
        (r'(?:requires|needs|minimum)\s+(?:version\s+)?(\d+\.[\d.]+)', 'version_requirement'),
        (r'(?:deprecated|obsolete|outdated)', 'deprecation'),
        (r'upgrade\s+(?:to\s+)?(?:version\s+)?(\d+\.[\d.]+)', 'upgrade_suggested'),
        (r'(?:npm|yarn|pnpm)\s+(?:WARN|warn).*(?:deprecated|outdated)', 'npm_deprecated'),
        (r'pip.*(?:WARNING|warning).*(?:deprecated|outdated)', 'pip_deprecated'),
        (r'(?:go|golang).*(?:deprecated|outdated)', 'go_deprecated'),
        (r'(?:ENOENT|command not found).*(\w+)', 'missing_tool'),
        (r'version\s+(\d+\.[\d.]+).*(?:is\s+)?(?:old|outdated|unsupported)', 'old_version'),
    ]

    # Known tool version check commands
    TOOL_VERSION_CHECKS = {
        'node': ('node --version', r'v(\d+)\.'),
        'npm': ('npm --version', r'(\d+)\.'),
        'python': ('python3 --version', r'Python\s+(\d+\.\d+)'),
        'go': ('go version', r'go(\d+\.\d+)'),
        'docker': ('docker --version', r'Docker version (\d+\.\d+)'),
        'gh': ('gh --version', r'gh version (\d+\.\d+)'),
    }

    # Minimum recommended versions (can be extended)
    MIN_VERSIONS = {
        'node': 18,
        'npm': 9,
        'python': 3.10,
        'go': 1.21,
        'docker': 24,
        'gh': 2.40,
    }

    def __init__(self):
        self.version_patterns = [(re.compile(p, re.IGNORECASE), t) for p, t in self.VERSION_ISSUE_PATTERNS]

    def detect_version_issue(self, stderr: str, command: str) -> Optional[Dict]:
        """Detect version-related issues from stderr output."""
        for pattern, issue_type in self.version_patterns:
            match = pattern.search(stderr)
            if match:
                return {
                    'type': issue_type,
                    'command': command,
                    'stderr': stderr[:500],
                    'match': match.group(0),
                    'version': match.group(1) if match.lastindex else None
                }
        return None

    def check_tool_version(self, tool: str) -> Optional[Dict]:
        """Check if a tool is outdated."""
        if tool not in self.TOOL_VERSION_CHECKS:
            return None

        cmd, version_pattern = self.TOOL_VERSION_CHECKS[tool]
        min_version = self.MIN_VERSIONS.get(tool)

        try:
            result = subprocess.run(
                cmd.split(),
                capture_output=True,
                text=True,
                timeout=5
            )
            output = result.stdout + result.stderr
            match = re.search(version_pattern, output)

            if match:
                current_version = float(match.group(1))
                if min_version and current_version < min_version:
                    return {
                        'tool': tool,
                        'current_version': current_version,
                        'min_recommended': min_version,
                        'status': 'outdated'
                    }
                return {
                    'tool': tool,
                    'current_version': current_version,
                    'min_recommended': min_version,
                    'status': 'ok'
                }
        except Exception:
            return {
                'tool': tool,
                'status': 'not_installed'
            }

        return None

    def check_npm_outdated(self, project_path: Path = None) -> List[Dict]:
        """Check for outdated npm packages."""
        cwd = project_path or Path.cwd()
        package_json = cwd / "package.json"

        if not package_json.exists():
            return []

        try:
            result = subprocess.run(
                ["npm", "outdated", "--json"],
                capture_output=True,
                text=True,
                cwd=cwd,
                timeout=30
            )

            if result.stdout:
                outdated = json.loads(result.stdout)
                return [
                    {
                        'package': name,
                        'current': info.get('current'),
                        'wanted': info.get('wanted'),
                        'latest': info.get('latest'),
                        'type': 'npm'
                    }
                    for name, info in outdated.items()
                ]
        except Exception:
            pass

        return []

    def check_pip_outdated(self, project_path: Path = None) -> List[Dict]:
        """Check for outdated pip packages."""
        try:
            result = subprocess.run(
                ["pip", "list", "--outdated", "--format=json"],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.stdout:
                outdated = json.loads(result.stdout)
                return [
                    {
                        'package': pkg.get('name'),
                        'current': pkg.get('version'),
                        'latest': pkg.get('latest_version'),
                        'type': 'pip'
                    }
                    for pkg in outdated
                ]
        except Exception:
            pass

        return []

    def generate_tool_update_candidate(self, tool_info: Dict) -> Optional[Dict]:
        """Generate a candidate for updating an outdated tool."""
        tool = tool_info.get('tool', tool_info.get('package', 'unknown'))
        status = tool_info.get('status', 'outdated')

        if status == 'ok':
            return None

        if status == 'not_installed':
            trigger = f"when {tool} command fails with 'not found'"
            action = f"install {tool} using appropriate package manager"
        else:
            current = tool_info.get('current', tool_info.get('current_version', '?'))
            latest = tool_info.get('latest', tool_info.get('min_recommended', '?'))
            trigger = f"when using {tool} (currently v{current})"
            action = f"consider upgrading to v{latest} for latest features and security fixes"

        candidate = {
            "id": f"tool-{tool[:6]}-{hash(str(tool_info)) % 10000:04d}",
            "title": f"Update {tool}" if status != 'not_installed' else f"Install {tool}",
            "candidate_type": "snippet",
            "trigger": trigger,
            "action": action,
            "evidence": [tool_info],
            "confidence": 0.80 if status == 'outdated' else 0.60,
            "status": "pending",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "tool_status": status
        }
        candidate["fingerprint"] = fingerprint_candidate(candidate)
        return candidate

    def scan_project_dependencies(self, project_path: Path = None) -> Tuple[List[Dict], List[Dict]]:
        """Scan project for outdated dependencies."""
        cwd = project_path or Path.cwd()
        candidates = []
        findings = []

        # Check npm packages
        npm_outdated = self.check_npm_outdated(cwd)
        for pkg in npm_outdated[:5]:  # Limit to top 5
            findings.append(pkg)
            candidate = self.generate_tool_update_candidate(pkg)
            if candidate:
                candidates.append(candidate)

        # Check pip packages (if requirements.txt exists)
        if (cwd / "requirements.txt").exists() or (cwd / "pyproject.toml").exists():
            pip_outdated = self.check_pip_outdated(cwd)
            for pkg in pip_outdated[:5]:
                findings.append(pkg)
                candidate = self.generate_tool_update_candidate(pkg)
                if candidate:
                    candidates.append(candidate)

        # Check core CLI tools
        for tool in ['node', 'npm', 'python', 'go', 'docker', 'gh']:
            tool_info = self.check_tool_version(tool)
            if tool_info and tool_info.get('status') in ('outdated', 'not_installed'):
                findings.append(tool_info)
                candidate = self.generate_tool_update_candidate(tool_info)
                if candidate:
                    candidates.append(candidate)

        return candidates, findings


class CombinedAnalyzer:
    """Combined analyzer for skills and tools."""

    def __init__(self):
        self.skill_analyzer = SkillAnalyzer()
        self.tool_analyzer = OutdatedToolAnalyzer()

    def analyze_stderr_for_issues(self, command: str, stderr: str,
                                  exit_code: int) -> List[Dict]:
        """Analyze command stderr for skill/tool issues."""
        candidates = []

        # Check for version issues
        version_issue = self.tool_analyzer.detect_version_issue(stderr, command)
        if version_issue:
            # Generate candidate for the version issue
            candidate = self.tool_analyzer.generate_tool_update_candidate({
                'tool': command.split()[0] if command else 'unknown',
                'status': 'outdated',
                'issue': version_issue
            })
            if candidate:
                candidates.append(candidate)

        return candidates

    def analyze_user_message_for_skills(self, user_message: str,
                                        context: Dict) -> List[Dict]:
        """Analyze user message for skill improvement opportunities."""
        candidates = []

        # Check for skill supplementation
        supplement = self.skill_analyzer.detect_skill_supplement(user_message, context)
        if supplement:
            skill_name = supplement.get('skill_name')
            candidate = self.skill_analyzer.generate_skill_update_candidate(
                skill_name, user_message, context
            )
            if candidate:
                candidates.append(candidate)

        return candidates

    def run_full_scan(self, verbose: bool = False) -> Dict[str, Any]:
        """Run a full scan for outdated tools and skill issues."""
        results = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'tool_candidates': [],
            'tool_findings': [],
            'skill_findings': [],
            'installed_skills': []
        }

        # Scan dependencies
        if verbose:
            print("Scanning project dependencies...")

        tool_candidates, tool_findings = self.tool_analyzer.scan_project_dependencies()
        results['tool_candidates'] = tool_candidates
        results['tool_findings'] = tool_findings

        # List installed skills
        if verbose:
            print("Checking installed skills...")

        installed = self.skill_analyzer.get_installed_skills()
        results['installed_skills'] = list(installed.keys())

        if verbose:
            print(f"\nFindings:")
            print(f"  Outdated tools/packages: {len(tool_findings)}")
            print(f"  Installed skills: {len(installed)}")
            print(f"  Generated candidates: {len(tool_candidates)}")

            if tool_findings:
                print("\n  Tool/Package Issues:")
                for f in tool_findings[:5]:
                    name = f.get('tool', f.get('package', '?'))
                    current = f.get('current', f.get('current_version', '?'))
                    latest = f.get('latest', f.get('min_recommended', '?'))
                    print(f"    - {name}: {current} → {latest}")

        return results


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Analyze skills and tools")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--scan", action="store_true", help="Run full dependency scan")
    parser.add_argument("--check-tool", type=str, help="Check specific tool version")
    parser.add_argument("--list-skills", action="store_true", help="List installed skills")

    args = parser.parse_args()

    analyzer = CombinedAnalyzer()

    if args.list_skills:
        skills = analyzer.skill_analyzer.get_installed_skills()
        print(f"Installed skills ({len(skills)}):")
        for name, path in skills.items():
            print(f"  - {name}: {path}")
        return 0

    if args.check_tool:
        result = analyzer.tool_analyzer.check_tool_version(args.check_tool)
        if result:
            print(json.dumps(result, indent=2))
        else:
            print(f"Unknown tool: {args.check_tool}")
        return 0

    if args.scan:
        results = analyzer.run_full_scan(verbose=args.verbose)

        if not args.verbose:
            print(json.dumps(results, indent=2, default=str))

        return 0

    # Default: show help
    parser.print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())
