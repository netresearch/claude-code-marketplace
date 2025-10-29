#!/usr/bin/env python3
"""
TYPO3 Core Contribution Commit Message Generator
Creates properly formatted commit messages following TYPO3 standards
"""

import argparse
import sys
import re
from typing import Optional


COMMIT_TYPES = {
    'BUGFIX': 'Bug fixes',
    'FEATURE': 'New features (main branch only)',
    'TASK': 'Refactoring, cleanup, miscellaneous',
    'DOCS': 'Documentation changes',
    'SECURITY': 'Security vulnerability fixes'
}

BREAKING_CHANGE_PREFIX = '[!!!]'


def validate_subject(subject: str, has_breaking: bool) -> tuple[bool, Optional[str]]:
    """Validate subject line against TYPO3 rules"""
    max_length = 52 if not has_breaking else 47  # Account for [!!!] prefix

    if len(subject) > 72:
        return False, "Subject line exceeds 72 characters (absolute limit)"

    if len(subject) > max_length:
        return False, f"Subject line exceeds {max_length} characters (recommended limit)"

    if not subject[0].isupper():
        return False, "Subject must start with uppercase letter"

    if subject.endswith('.'):
        return False, "Subject should not end with a period"

    # Check for imperative mood (simple heuristic)
    past_tense_endings = ['ed', 'ing']
    first_word = subject.split()[0].lower()
    if any(first_word.endswith(end) for end in past_tense_endings):
        return False, f"Use imperative mood ('{first_word}' appears to be past/present continuous tense)"

    return True, None


def wrap_text(text: str, width: int = 72) -> str:
    """Wrap text at specified width"""
    words = text.split()
    lines = []
    current_line = []
    current_length = 0

    for word in words:
        word_length = len(word)
        if current_length + word_length + len(current_line) > width:
            if current_line:
                lines.append(' '.join(current_line))
                current_line = [word]
                current_length = word_length
        else:
            current_line.append(word)
            current_length += word_length

    if current_line:
        lines.append(' '.join(current_line))

    return '\n'.join(lines)


def parse_releases(releases_str: str) -> list[str]:
    """Parse comma-separated release versions"""
    releases = [r.strip() for r in releases_str.split(',')]
    # Validate format
    valid_releases = []
    for release in releases:
        if release == 'main' or re.match(r'^\d+\.\d+$', release):
            valid_releases.append(release)
        else:
            print(f"Warning: Invalid release format '{release}', skipping")
    return valid_releases


def main():
    parser = argparse.ArgumentParser(
        description='Generate TYPO3-compliant commit messages',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s --issue 105737 --type BUGFIX
  %(prog)s --issue 105737 --type FEATURE --breaking
  %(prog)s --type TASK --related 12345,12346
        '''
    )

    parser.add_argument('--issue', type=int, help='Forge issue number')
    parser.add_argument('--related', help='Related issue numbers (comma-separated)')
    parser.add_argument('--type', choices=COMMIT_TYPES.keys(), required=True,
                       help='Commit type')
    parser.add_argument('--breaking', action='store_true',
                       help='Mark as breaking change (adds [!!!] prefix)')
    parser.add_argument('--releases', default='main',
                       help='Target releases (comma-separated, e.g., "main, 13.4, 12.4")')
    parser.add_argument('--output', help='Output file (default: print to stdout)')

    args = parser.parse_args()

    # Interactive mode
    print("=== TYPO3 Commit Message Generator ===\n")

    # Get subject line
    print(f"Commit Type: [{args.type}]")
    if args.breaking:
        print(f"Breaking Change: Yes (will add {BREAKING_CHANGE_PREFIX} prefix)")
    print()

    subject = input("Enter subject line (max 52 chars, imperative mood): ").strip()

    # Validate subject
    valid, error = validate_subject(subject, args.breaking)
    if not valid:
        print(f"\n❌ Error: {error}")
        sys.exit(1)

    # Get description
    print("\nEnter description (explain how and why, not what).")
    print("Press Ctrl+D (Linux/Mac) or Ctrl+Z (Windows) when done:")
    description_lines = []
    try:
        while True:
            line = input()
            description_lines.append(line)
    except EOFError:
        pass

    description = '\n'.join(description_lines).strip()
    if description:
        description = wrap_text(description)

    # Build commit message
    type_prefix = f"{BREAKING_CHANGE_PREFIX}{args.type}" if args.breaking else args.type
    message = f"[{type_prefix}] {subject}\n\n"

    if description:
        message += f"{description}\n\n"

    # Add footer
    if args.issue:
        message += f"Resolves: #{args.issue}\n"

    if args.related:
        related_issues = [f"#{num.strip()}" for num in args.related.split(',')]
        for issue in related_issues:
            message += f"Related: {issue}\n"

    releases = parse_releases(args.releases)
    if releases:
        message += f"Releases: {', '.join(releases)}\n"

    # Output
    print("\n" + "="*60)
    print("Generated Commit Message:")
    print("="*60)
    print(message)
    print("="*60)
    print("\nNote: Change-Id will be added automatically by git hook")
    print("="*60)

    if args.output:
        with open(args.output, 'w') as f:
            f.write(message)
        print(f"\n✓ Commit message saved to: {args.output}")
        print(f"  Use: git commit -F {args.output}")
    else:
        print("\nTo use this message:")
        print("  1. Copy the message above")
        print("  2. Run: git commit")
        print("  3. Paste into your editor")

    return 0


if __name__ == '__main__':
    sys.exit(main())
