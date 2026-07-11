#!/usr/bin/env python3
"""Advisory pairwise token-overlap similarity report for the marketplace catalog.

Compares each plugin's marketplace.json description (plus, when a local
skill-repo checkout is available, its SKILL.md trigger phrases) against
every other plugin and ranks pairs above a similarity threshold. Intended
as a consolidation-candidate signal for /retro audits, never as a gate:
this script always exits 0.

Pure standard library, no network access, no LLM calls. This repository
does not vendor SKILL.md files, so a CI run compares descriptions only;
pass --skill-md-root to opt into the richer local comparison when skill
repos are checked out as siblings (see --help).

--marketplace and --output must resolve inside this repository (CWE-22
hardening: a script invoked by CI or an agent should not be redirectable
to arbitrary filesystem paths by a crafted argument); --skill-md-root has
no such restriction since it is expected to point at sibling checkouts
outside the repository.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from itertools import combinations
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MARKETPLACE_JSON = REPO_ROOT / ".claude-plugin" / "marketplace.json"
DEFAULT_THRESHOLD = 0.15
DEFAULT_OUTPUT = REPO_ROOT / "overlap-report.md"

# Boilerplate shared by nearly every skill description ("use when ...",
# "triggers on ..."). Excluding it keeps the score sensitive to topical
# overlap rather than shared scaffolding language.
STOPWORDS = frozenset(
    {
        "a",
        "an",
        "and",
        "any",
        "are",
        "as",
        "at",
        "be",
        "but",
        "by",
        "can",
        "for",
        "from",
        "if",
        "in",
        "into",
        "is",
        "it",
        "its",
        "of",
        "on",
        "or",
        "over",
        "than",
        "that",
        "the",
        "their",
        "then",
        "this",
        "to",
        "use",
        "used",
        "using",
        "via",
        "when",
        "where",
        "with",
        "you",
        "your",
        "triggers",
    }
)

TOKEN_RE = re.compile(r"[a-z0-9]+")


def tokenize(text: str) -> frozenset[str]:
    """Lowercase, split on non-alphanumerics, drop stopwords and 1-2 char tokens."""
    tokens = TOKEN_RE.findall(text.lower())
    return frozenset(t for t in tokens if len(t) > 2 and t not in STOPWORDS)


def jaccard(a: frozenset[str], b: frozenset[str]) -> float:
    if not a or not b:
        return 0.0
    union = len(a | b)
    return len(a & b) / union if union else 0.0


def _frontmatter_lines(text: str) -> list[str] | None:
    """Return the lines between the opening and closing `---` markers."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    try:
        end = lines.index("---", 1)
    except ValueError:
        return None
    return lines[1:end]


def _parse_quoted_scalar(rest: str) -> str:
    """Unwrap a single-line double-quoted YAML scalar."""
    quoted = re.match(r'^"(.*)"\s*$', rest)
    return quoted.group(1).replace('\\"', '"') if quoted else rest.strip('"')


def _parse_block_scalar(indicator: str, following_lines: list[str]) -> str:
    """Collect an indented YAML block scalar (`>-`, `>`, `|`, `|-`)."""
    block_lines = []
    for cont in following_lines:
        if cont.strip() == "":
            if indicator.startswith("|"):
                block_lines.append("")
            continue
        if not cont.startswith((" ", "\t")):
            break
        block_lines.append(cont.strip())
    joiner = "\n" if indicator.startswith("|") else " "
    return joiner.join(block_lines).strip()


def extract_skill_md_description(text: str) -> str | None:
    """Best-effort extraction of the frontmatter `description:` field.

    Handles the two forms seen across skill repos: a single-line quoted
    scalar (`description: "..."`) and a block scalar (`description: >-`,
    `>`, `|`, `|-`). This is not a full YAML parser; anything else returns
    None so callers fall back to description-only comparison rather than
    guessing at a malformed extraction.
    """
    frontmatter = _frontmatter_lines(text)
    if frontmatter is None:
        return None

    for i, line in enumerate(frontmatter):
        if not line.startswith("description:"):
            continue
        rest = line[len("description:") :].strip()
        if rest.startswith('"'):
            return _parse_quoted_scalar(rest)
        if rest in (">-", ">", "|", "|-"):
            return _parse_block_scalar(rest, frontmatter[i + 1 :])
        return rest  # plain unquoted scalar
    return None


def find_local_skill_md(skills_root: Path, repo: str) -> Path | None:
    """Locate a locally checked-out SKILL.md for `owner/repo`, if present.

    Looks for `<skills_root>/<repo-basename>/**/skills/*/SKILL.md`, which
    covers both flat checkouts and the git-worktree layout
    (`<repo>/main/skills/<slug>/SKILL.md`). Prefers a `main` worktree when
    several branches are checked out; otherwise picks the lexicographically
    first match for determinism.
    """
    base_dir = skills_root / repo.split("/")[-1]
    if not base_dir.is_dir():
        return None
    candidates = sorted(base_dir.glob("**/skills/*/SKILL.md"))
    if not candidates:
        return None
    for candidate in candidates:
        if "/main/" in candidate.as_posix():
            return candidate
    return candidates[0]


def _resolve_within_repo(path: Path, label: str) -> Path:
    """Resolve `path` and reject it if it falls outside REPO_ROOT.

    `--marketplace` and `--output` are plain CLI arguments with no
    surrounding "trusted base directory" of their own, so this is the
    input-validation step itself (CWE-22): confine both reads and writes
    to the repository, since a script invoked by CI or an agent should
    not be redirectable to arbitrary filesystem paths by a crafted
    argument.
    """
    resolved = path.resolve()
    if not resolved.is_relative_to(REPO_ROOT):
        raise ValueError(f"--{label} must resolve inside {REPO_ROOT}, got {resolved}")
    return resolved


def load_plugins(marketplace_path: Path) -> list[dict]:
    resolved = _resolve_within_repo(marketplace_path, "marketplace")
    if not resolved.is_file():
        raise FileNotFoundError(f"marketplace file not found: {resolved}")
    data = json.loads(resolved.read_text(encoding="utf-8"))
    return data.get("plugins", [])


def build_corpus(plugins: list[dict], skills_root: Path | None) -> dict[str, dict]:
    corpus: dict[str, dict] = {}
    for plugin in plugins:
        name = plugin["name"]
        text_sources = [plugin.get("description", "")]
        skill_md_used = False
        if skills_root is not None:
            repo = plugin.get("source", {}).get("repo")
            if repo:
                skill_md_path = find_local_skill_md(skills_root, repo)
                if skill_md_path is not None:
                    skill_desc = extract_skill_md_description(
                        skill_md_path.read_text(encoding="utf-8")
                    )
                    if skill_desc:
                        text_sources.append(skill_desc)
                        skill_md_used = True
        corpus[name] = {
            "tokens": tokenize(" ".join(text_sources)),
            "category": plugin.get("category", ""),
            "skill_md_used": skill_md_used,
        }
    return corpus


def compute_pairs(
    corpus: dict[str, dict], threshold: float
) -> list[tuple[str, str, float]]:
    pairs = [
        (a, b, jaccard(corpus[a]["tokens"], corpus[b]["tokens"]))
        for a, b in combinations(sorted(corpus), 2)
    ]
    pairs = [p for p in pairs if p[2] >= threshold]
    # Stable, deterministic order: score descending, then name pair ascending.
    pairs.sort(key=lambda p: (-p[2], p[0], p[1]))
    return pairs


def render_report(
    pairs: list[tuple[str, str, float]],
    corpus: dict[str, dict],
    threshold: float,
    skills_root: Path | None,
    total_plugins: int,
) -> str:
    lines = [
        "# Marketplace overlap report",
        "",
        f"Advisory pairwise token-overlap similarity across {total_plugins} "
        f"catalog entries. Threshold: {threshold:.2f}. Not a blocking check "
        "— high-similarity pairs are consolidation candidates for /retro "
        "audit review.",
        "",
    ]
    if skills_root is not None:
        used = sum(1 for v in corpus.values() if v["skill_md_used"])
        lines.append(
            f"SKILL.md trigger phrases included for {used}/{total_plugins} "
            f"plugins found under `{skills_root}`."
        )
    else:
        lines.append(
            "SKILL.md trigger phrases not included (no `--skill-md-root` "
            "given, and this repository does not vendor SKILL.md files) — "
            "description-only comparison."
        )
    lines.append("")

    if not pairs:
        lines.append("No pairs at or above threshold.")
        lines.append("")
        return "\n".join(lines)

    lines.append("| Score | Plugin A | Plugin B | Same category |")
    lines.append("|---|---|---|---|")
    for a, b, score in pairs:
        same_category = (
            "yes" if corpus[a]["category"] == corpus[b]["category"] else "no"
        )
        lines.append(f"| {score:.2f} | {a} | {b} | {same_category} |")
    lines.append("")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--marketplace",
        type=Path,
        default=MARKETPLACE_JSON,
        help=(
            "Path to marketplace.json, must resolve inside the repository "
            "(default: .claude-plugin/marketplace.json)"
        ),
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=DEFAULT_THRESHOLD,
        help=f"Minimum Jaccard score to report a pair (default: {DEFAULT_THRESHOLD})",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=(
            "Report file to write, must resolve inside the repository "
            "(default: overlap-report.md at repo root)"
        ),
    )
    parser.add_argument(
        "--skill-md-root",
        type=Path,
        default=None,
        help=(
            "Directory containing local skill-repo checkouts (subdirectory "
            "basename matches the repo name) to include SKILL.md trigger "
            "phrases. Optional and normally unset in CI, since this "
            "repository does not vendor SKILL.md files."
        ),
    )
    args = parser.parse_args(argv)

    plugins = load_plugins(args.marketplace)
    corpus = build_corpus(plugins, args.skill_md_root)
    pairs = compute_pairs(corpus, args.threshold)
    report = render_report(
        pairs, corpus, args.threshold, args.skill_md_root, len(plugins)
    )

    output_path = _resolve_within_repo(args.output, "output")
    output_path.write_text(report + "\n", encoding="utf-8")
    print(report)
    print(f"Report written to {output_path}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # advisory tool: never fail CI
        print(f"overlap-report.py: non-fatal error: {exc}", file=sys.stderr)
        sys.exit(0)
