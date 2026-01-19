#!/bin/sh
# Validate marketplace.json structure and content
# Used by: pre-commit hook, CI workflow

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

# Check for duplicates
DUPES=$(jq -r '.plugins[].name' "$MARKETPLACE" | sort | uniq -d)
if [ -n "$DUPES" ]; then
    echo "✗ Duplicate plugin names: $DUPES"
    exit 1
fi
echo "✓ No duplicate plugins"

# Summary
COUNT=$(jq '.plugins | length' "$MARKETPLACE")
echo ""
echo "Marketplace valid: $COUNT plugins"
