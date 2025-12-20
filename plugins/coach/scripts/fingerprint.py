#!/usr/bin/env python3
"""
Generate stable fingerprints for learning candidates.
Enables cross-repo deduplication and promotion detection.
"""

import re
import hashlib
import json
from typing import Dict, List, Optional, Set

# Normalization patterns for generic replacement
NORMALIZATION_RULES = [
    # Paths
    (r'/[a-zA-Z0-9_\-./]+', '<PATH>'),
    # URLs
    (r'https?://[^\s]+', '<URL>'),
    # Numbers
    (r'\b\d+\b', '<NUM>'),
    # UUIDs
    (r'[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}', '<UUID>'),
    # Hashes
    (r'[a-f0-9]{32,}', '<HASH>'),
]

# Tool name buckets for generalization
TOOL_BUCKETS = {
    # Test runners
    'pytest': '<TEST_RUNNER>',
    'jest': '<TEST_RUNNER>',
    'mocha': '<TEST_RUNNER>',
    'vitest': '<TEST_RUNNER>',
    'phpunit': '<TEST_RUNNER>',
    'rspec': '<TEST_RUNNER>',
    'go test': '<TEST_RUNNER>',

    # Package managers
    'npm': '<PKG_MANAGER>',
    'pnpm': '<PKG_MANAGER>',
    'yarn': '<PKG_MANAGER>',
    'pip': '<PKG_MANAGER>',
    'poetry': '<PKG_MANAGER>',
    'composer': '<PKG_MANAGER>',
    'cargo': '<PKG_MANAGER>',
    'go mod': '<PKG_MANAGER>',

    # Build tools
    'webpack': '<BUILD_TOOL>',
    'vite': '<BUILD_TOOL>',
    'esbuild': '<BUILD_TOOL>',
    'rollup': '<BUILD_TOOL>',
    'tsc': '<BUILD_TOOL>',
    'make': '<BUILD_TOOL>',

    # Linters
    'eslint': '<LINTER>',
    'prettier': '<LINTER>',
    'pylint': '<LINTER>',
    'flake8': '<LINTER>',
    'rubocop': '<LINTER>',
    'phpcs': '<LINTER>',
}


class Fingerprinter:
    """Generate stable fingerprints for candidate deduplication."""

    def __init__(self, custom_rules: List[tuple] = None, custom_buckets: Dict[str, str] = None):
        self.rules = NORMALIZATION_RULES + (custom_rules or [])
        self.buckets = {**TOOL_BUCKETS, **(custom_buckets or {})}

    def normalize(self, text: str) -> str:
        """Normalize text for stable fingerprinting."""
        if not text:
            return ""

        # Lowercase
        result = text.lower()

        # Apply tool bucket replacements
        for tool, bucket in self.buckets.items():
            result = re.sub(rf'\b{re.escape(tool)}\b', bucket, result, flags=re.IGNORECASE)

        # Apply normalization rules
        for pattern, replacement in self.rules:
            result = re.sub(pattern, replacement, result)

        # Strip punctuation except underscores
        result = re.sub(r'[^\w\s<>]', '', result)

        # Collapse whitespace
        result = ' '.join(result.split())

        return result.strip()

    def extract_keywords(self, text: str) -> Set[str]:
        """Extract significant keywords for similarity matching."""
        normalized = self.normalize(text)
        words = set(normalized.split())

        # Filter out very short words and placeholders
        keywords = {w for w in words if len(w) > 2 and not w.startswith('<')}

        return keywords

    def fingerprint(self, candidate_type: str, trigger: str, action: str) -> str:
        """Generate SHA-256 fingerprint for a candidate."""
        # Combine and normalize components
        combined = f"{candidate_type}|{self.normalize(trigger)}|{self.normalize(action)}"

        # Generate hash
        return hashlib.sha256(combined.encode()).hexdigest()

    def fingerprint_candidate(self, candidate: Dict) -> str:
        """Generate fingerprint for a candidate dictionary."""
        return self.fingerprint(
            candidate.get('candidate_type', candidate.get('type', 'rule')),
            candidate.get('trigger', candidate.get('trigger_condition', '')),
            candidate.get('action', '')
        )

    def similarity(self, text1: str, text2: str) -> float:
        """Calculate Jaccard similarity between two texts."""
        kw1 = self.extract_keywords(text1)
        kw2 = self.extract_keywords(text2)

        if not kw1 or not kw2:
            return 0.0

        intersection = len(kw1 & kw2)
        union = len(kw1 | kw2)

        return intersection / union if union > 0 else 0.0

    def is_similar(self, candidate1: Dict, candidate2: Dict, threshold: float = 0.6) -> bool:
        """Check if two candidates are similar enough to be considered duplicates."""
        # Same fingerprint = identical
        if self.fingerprint_candidate(candidate1) == self.fingerprint_candidate(candidate2):
            return True

        # Check type match first
        type1 = candidate1.get('candidate_type', candidate1.get('type'))
        type2 = candidate2.get('candidate_type', candidate2.get('type'))
        if type1 != type2:
            return False

        # Check text similarity
        text1 = f"{candidate1.get('trigger', '')} {candidate1.get('action', '')}"
        text2 = f"{candidate2.get('trigger', '')} {candidate2.get('action', '')}"

        return self.similarity(text1, text2) >= threshold


def fingerprint_candidate(candidate: Dict) -> str:
    """Convenience function to fingerprint a candidate."""
    fp = Fingerprinter()
    return fp.fingerprint_candidate(candidate)


def are_similar(candidate1: Dict, candidate2: Dict, threshold: float = 0.6) -> bool:
    """Convenience function to check candidate similarity."""
    fp = Fingerprinter()
    return fp.is_similar(candidate1, candidate2, threshold)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate fingerprints for candidates")
    parser.add_argument("--type", required=True, help="Candidate type")
    parser.add_argument("--trigger", required=True, help="Trigger condition")
    parser.add_argument("--action", required=True, help="Action to take")
    parser.add_argument("--show-normalized", action="store_true", help="Show normalized text")

    args = parser.parse_args()

    fp = Fingerprinter()
    fingerprint = fp.fingerprint(args.type, args.trigger, args.action)

    print(f"Fingerprint: {fingerprint}")

    if args.show_normalized:
        print(f"Normalized trigger: {fp.normalize(args.trigger)}")
        print(f"Normalized action: {fp.normalize(args.action)}")
        print(f"Keywords: {fp.extract_keywords(args.trigger + ' ' + args.action)}")


if __name__ == "__main__":
    main()
