#!/usr/bin/env python3
"""
TYPO3 Commit Message Validator
Validates commit messages against TYPO3 contribution standards
"""

import sys
import re
import argparse
from typing import List, Tuple


VALID_TYPES = ['BUGFIX', 'FEATURE', 'TASK', 'DOCS', 'SECURITY']
BREAKING_PREFIX = '[!!!]'


class CommitMessageValidator:
    def __init__(self, message: str):
        self.message = message
        self.lines = message.split('\n')
        self.errors = []
        self.warnings = []

    def validate(self) -> Tuple[bool, List[str], List[str]]:
        """Run all validation checks"""
        self.check_subject_line()
        self.check_blank_line()
        self.check_footer()
        self.check_change_id()

        return len(self.errors) == 0, self.errors, self.warnings

    def check_subject_line(self):
        """Validate the subject line"""
        if not self.lines:
            self.errors.append("Commit message is empty")
            return

        subject = self.lines[0]

        # Check for commit type
        type_pattern = r'^\[(?:\[!!!\])?(BUGFIX|FEATURE|TASK|DOCS|SECURITY)\]'
        match = re.match(type_pattern, subject)

        if not match:
            self.errors.append(
                f"Subject must start with commit type: {', '.join(f'[{t}]' for t in VALID_TYPES)}"
            )
            return

        commit_type = match.group(1)

        # Check for breaking change prefix
        if subject.startswith('[!!!]'):
            if commit_type == 'BUGFIX':
                self.warnings.append(
                    "Breaking changes are unusual for BUGFIX. Consider using FEATURE or TASK"
                )

        # Extract subject without type prefix
        subject_without_type = re.sub(type_pattern, '', subject).strip()

        # Check length
        if len(subject) > 72:
            self.errors.append(
                f"Subject line is {len(subject)} characters (max 72). Current: {len(subject)}"
            )
        elif len(subject) > 52:
            self.warnings.append(
                f"Subject line is {len(subject)} characters (recommended max 52)"
            )

        # Check capitalization
        if subject_without_type and not subject_without_type[0].isupper():
            self.errors.append("Subject description must start with uppercase letter")

        # Check for period at end
        if subject.endswith('.'):
            self.errors.append("Subject line should not end with a period")

        # Check for imperative mood (heuristic)
        if subject_without_type:
            first_word = subject_without_type.split()[0].lower()
            if first_word.endswith('ed') or first_word.endswith('ing'):
                self.warnings.append(
                    f"Use imperative mood: '{first_word}' may not be imperative. "
                    "Use 'Fix' not 'Fixed' or 'Fixing'"
                )

    def check_blank_line(self):
        """Check for blank line after subject"""
        if len(self.lines) < 2:
            return  # Only subject line, no body

        if len(self.lines) >= 2 and self.lines[1] != '':
            self.errors.append("Second line must be blank (separate subject from body)")

    def check_footer(self):
        """Check footer tags"""
        footer_pattern = r'^(Resolves|Related|Releases|Depends|Reverts):\s*'

        has_resolves = False
        has_releases = False
        has_change_id = False

        for i, line in enumerate(self.lines):
            if re.match(footer_pattern, line):
                # Check format: should have colon followed by space
                if not re.match(r'^[A-Z][a-z]+:\s+', line):
                    self.errors.append(
                        f"Line {i+1}: Footer tag must have colon followed by space: '{line}'"
                    )

                # Check specific tags
                if line.startswith('Resolves:'):
                    has_resolves = True
                    # Validate issue number format
                    if not re.match(r'^Resolves:\s+#\d+', line):
                        self.errors.append(
                            f"Line {i+1}: Resolves must reference issue number: 'Resolves: #12345'"
                        )

                elif line.startswith('Related:'):
                    if not re.match(r'^Related:\s+#\d+', line):
                        self.errors.append(
                            f"Line {i+1}: Related must reference issue number: 'Related: #12345'"
                        )

                elif line.startswith('Releases:'):
                    has_releases = True
                    # Validate releases format
                    releases_value = line.split(':', 1)[1].strip()
                    releases = [r.strip() for r in releases_value.split(',')]
                    for release in releases:
                        if release != 'main' and not re.match(r'^\d+\.\d+$', release):
                            self.errors.append(
                                f"Line {i+1}: Invalid release format '{release}'. "
                                "Use 'main' or version like '13.4'"
                            )

            elif line.startswith('Change-Id:'):
                has_change_id = True

        # Warnings for missing tags
        if not has_resolves:
            self.warnings.append(
                "No 'Resolves: #<issue>' tag found. Required for features and tasks."
            )

        if not has_releases:
            self.warnings.append(
                "No 'Releases:' tag found. Required to specify target versions."
            )

    def check_change_id(self):
        """Check for Change-Id"""
        change_id_pattern = r'^Change-Id:\s+I[a-f0-9]{40}$'
        has_change_id = any(re.match(change_id_pattern, line) for line in self.lines)

        if not has_change_id:
            self.warnings.append(
                "No Change-Id found. It will be added automatically by git commit-msg hook."
            )

    def check_line_length(self):
        """Check body line lengths"""
        for i, line in enumerate(self.lines[2:], start=3):  # Skip subject and blank line
            if line.startswith(('Resolves:', 'Related:', 'Releases:', 'Change-Id:', 'Depends:', 'Reverts:')):
                continue  # Skip footer

            if len(line) > 72:
                # Allow URLs to be longer
                if not re.search(r'https?://', line):
                    self.warnings.append(
                        f"Line {i}: Length {len(line)} exceeds 72 characters"
                    )


def main():
    parser = argparse.ArgumentParser(
        description='Validate TYPO3 commit messages',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument('--file', '-f', help='File containing commit message')
    parser.add_argument('--message', '-m', help='Commit message string')
    parser.add_argument('--strict', action='store_true',
                       help='Treat warnings as errors')

    args = parser.parse_args()

    # Get message
    if args.file:
        try:
            with open(args.file, 'r') as f:
                message = f.read()
        except FileNotFoundError:
            print(f"Error: File not found: {args.file}")
            return 1
    elif args.message:
        message = args.message
    else:
        # Read from last commit
        try:
            import subprocess
            result = subprocess.run(
                ['git', 'log', '-1', '--pretty=%B'],
                capture_output=True,
                text=True,
                check=True
            )
            message = result.stdout
        except subprocess.CalledProcessError:
            print("Error: Could not read last commit message")
            print("Usage: Provide --file or --message, or run in a git repository")
            return 1

    # Validate
    validator = CommitMessageValidator(message)
    is_valid, errors, warnings = validator.validate()

    # Print results
    print("=" * 60)
    print("TYPO3 Commit Message Validation")
    print("=" * 60)
    print()

    if errors:
        print("❌ ERRORS:")
        for error in errors:
            print(f"  • {error}")
        print()

    if warnings:
        print("⚠️  WARNINGS:")
        for warning in warnings:
            print(f"  • {warning}")
        print()

    if not errors and not warnings:
        print("✅ Commit message is valid!")
    elif not errors:
        print("✅ No errors found (warnings can be ignored)")
    else:
        print("❌ Validation failed. Please fix errors above.")

    print("=" * 60)

    # Exit code
    if errors or (args.strict and warnings):
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
