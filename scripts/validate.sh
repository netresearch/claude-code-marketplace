#!/bin/sh
# Validate marketplace.json structure and content.
# Used by: pre-commit hook, CI workflow.
# Mechanical guard for the rules in AGENTS.md.

set -e

MARKETPLACE=".claude-plugin/marketplace.json"

echo "Validating $MARKETPLACE..."

# Check JSON syntax
if ! jq empty "$MARKETPLACE" 2>/dev/null; then
    echo "✗ Invalid JSON syntax"
    exit 1
fi
echo "✓ Valid JSON syntax"

# Check required structure
if ! jq -e '
    has("name") and has("owner") and has("plugins") and
    (.owner | has("name")) and
    (.plugins | type == "array") and
    (.plugins | all(has("name") and has("source") and has("category"))) and
    (.plugins | all(
        .source.source == "github" and .source.repo != null or
        .source.source == "url" and .source.url != null
    ))
' "$MARKETPLACE" > /dev/null; then
    echo "✗ Missing or invalid required fields"
    exit 1
fi
echo "✓ Valid structure"

# Check for duplicate slugs
DUPES=$(jq -r '.plugins[].name' "$MARKETPLACE" | sort | uniq -d)
if [ -n "$DUPES" ]; then
    echo "✗ Duplicate plugin names: $DUPES"
    exit 1
fi
echo "✓ No duplicate plugins"

# Canonical categories — keep in sync with AGENTS.md.
ALLOWED_CATEGORIES='development devops security design workflow productivity document'
BAD_CATEGORIES=$(jq -r --arg allowed "$ALLOWED_CATEGORIES" '
    [.plugins[] | select((.category // "") as $c | ($allowed | split(" ")) | index($c) | not)
                | "\(.name)=\(.category // "<missing>")"]
    | join("\n")
' "$MARKETPLACE")
if [ -n "$BAD_CATEGORIES" ]; then
    echo "✗ Non-canonical categories (allowed: $ALLOWED_CATEGORIES):"
    printf '%s\n' "$BAD_CATEGORIES" | sed 's/^/    /'
    exit 1
fi
echo "✓ Categories within canonical set"

# Slugs must be lowercase / hyphens / ≤ 64 chars.
BAD_SLUGS=$(jq -r '
    [.plugins[].name | select(test("^[a-z0-9][a-z0-9-]{0,63}$") | not)]
    | join("\n")
' "$MARKETPLACE")
if [ -n "$BAD_SLUGS" ]; then
    echo "✗ Invalid slugs (must match ^[a-z0-9][a-z0-9-]{0,63}\$):"
    printf '%s\n' "$BAD_SLUGS" | sed 's/^/    /'
    exit 1
fi
echo "✓ Slugs well-formed"

# Description rules: present, hard cap 500, target ≤ 300 (warning), unique.
DESC_HARD=$(jq -r '
    [.plugins[]
        | . as $p
        | (.description // "") as $d
        | if ($d | length) == 0 then
            "\($p.name): missing description"
          elif ($d | length) > 500 then
            "\($p.name): description \($d | length) chars (> 500 hard cap)"
          else empty end]
    | join("\n")
' "$MARKETPLACE")
if [ -n "$DESC_HARD" ]; then
    echo "✗ Description rules violated:"
    printf '%s\n' "$DESC_HARD" | sed 's/^/    /'
    exit 1
fi
DESC_WARN=$(jq -r '
    [.plugins[]
        | . as $p
        | (.description // "") as $d
        | if ($d | length) > 300 then
            "\($p.name): description \($d | length) chars (> 300 target)"
          else empty end]
    | join("\n")
' "$MARKETPLACE")
if [ -n "$DESC_WARN" ]; then
    echo "⚠ Descriptions over snippet-friendly target (≤ 300):"
    printf '%s\n' "$DESC_WARN" | sed 's/^/    /'
fi
DUPE_DESC=$(jq -r '[.plugins[].description] | group_by(.) | map(select(length>1) | .[0]) | join("\n")' "$MARKETPLACE")
if [ -n "$DUPE_DESC" ]; then
    echo "✗ Duplicate descriptions across plugins (must be unique):"
    printf '%s\n' "$DUPE_DESC" | sed 's/^/    /'
    exit 1
fi
echo "✓ Descriptions present, unique, within hard cap"

# README catalog row must exist for every plugin (anchor reachability).
if [ -f README.md ]; then
    MISSING_README=$(jq -r '.plugins[].name' "$MARKETPLACE" | while read -r slug; do
        if ! grep -q "$slug" README.md; then
            echo "$slug"
        fi
    done)
    if [ -n "$MISSING_README" ]; then
        echo "✗ Plugins missing from README catalog:"
        printf '%s\n' "$MISSING_README" | sed 's/^/    /'
        exit 1
    fi
    echo "✓ Every plugin referenced in README"
fi

# Summary
COUNT=$(jq '.plugins | length' "$MARKETPLACE")
echo ""
echo "Marketplace valid: $COUNT plugins"
