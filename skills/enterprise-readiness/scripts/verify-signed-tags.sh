#!/bin/bash
# verify-signed-tags.sh - Verify git tags are cryptographically signed
# Usage: ./verify-signed-tags.sh [tag] [--check-all]
# OpenSSF Badge Criteria: version_tags_signed (Silver)
set -euo pipefail

TAG="${1:-}"
CHECK_ALL=false

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --check-all)
            CHECK_ALL=true
            ;;
    esac
done

echo "=== Git Tag Signature Verification ==="
echo ""

# Check for GPG
if ! command -v gpg >/dev/null 2>&1; then
    echo "Warning: GPG is not installed. Tag verification may be limited."
fi

# Function to verify a single tag
verify_tag() {
    local tag="$1"
    local result

    # Check if tag exists
    if ! git rev-parse "$tag" >/dev/null 2>&1; then
        echo "✗ Tag '$tag' does not exist"
        return 1
    fi

    # Check if it's an annotated tag
    local tag_type
    tag_type=$(git cat-file -t "$tag" 2>/dev/null || echo "unknown")

    if [ "$tag_type" != "tag" ]; then
        echo "✗ $tag: Lightweight tag (not annotated, cannot be signed)"
        return 1
    fi

    # Try to verify signature
    if git tag -v "$tag" >/dev/null 2>&1; then
        echo "✓ $tag: Signed and verified"
        return 0
    else
        # Check if tag has signature but verification failed
        if git cat-file tag "$tag" 2>/dev/null | grep -q "BEGIN PGP SIGNATURE"; then
            echo "⚠ $tag: Has signature but verification failed (missing public key?)"
            return 1
        else
            echo "✗ $tag: Annotated but NOT signed"
            return 1
        fi
    fi
}

if [ -n "$TAG" ] && [ "$TAG" != "--check-all" ]; then
    # Verify specific tag
    echo "Verifying tag: $TAG"
    echo ""
    verify_tag "$TAG"
    exit $?
fi

if [ "$CHECK_ALL" = true ]; then
    # Verify all tags
    echo "Checking all tags..."
    echo ""

    TOTAL=0
    SIGNED=0
    UNSIGNED=0

    for tag in $(git tag -l); do
        TOTAL=$((TOTAL + 1))
        if verify_tag "$tag"; then
            SIGNED=$((SIGNED + 1))
        else
            UNSIGNED=$((UNSIGNED + 1))
        fi
    done

    echo ""
    echo "=== Summary ==="
    echo "Total tags: $TOTAL"
    echo "Signed: $SIGNED"
    echo "Unsigned/Invalid: $UNSIGNED"

    if [ "$TOTAL" -eq 0 ]; then
        echo ""
        echo "No tags found in repository."
        exit 0
    fi

    # Calculate percentage using awk (POSIX-compatible)
    PCT=$(awk -v s="$SIGNED" -v t="$TOTAL" 'BEGIN { printf "%.1f", (s/t)*100 }')
    echo "Signing rate: $PCT%"

    if [ "$UNSIGNED" -gt 0 ]; then
        echo ""
        echo "OpenSSF Badge: version_tags_signed = Unmet"
        echo ""
        echo "To sign future tags:"
        echo "  git tag -s v1.0.0 -m 'Release v1.0.0'"
        echo ""
        echo "To sign existing tags (creates new signed tag):"
        echo "  git tag -s -f v1.0.0 v1.0.0^{} -m 'Release v1.0.0'"
        exit 1
    else
        echo ""
        echo "OpenSSF Badge: version_tags_signed = Met"
        exit 0
    fi
else
    # Check latest release tags
    echo "Checking recent release tags..."
    echo ""

    RELEASE_TAGS=$(git tag -l 'v*' --sort=-version:refname 2>/dev/null | head -5)

    if [ -z "$RELEASE_TAGS" ]; then
        echo "No release tags (v*) found."
        echo ""
        echo "To create a signed release tag:"
        echo "  git tag -s v1.0.0 -m 'Release v1.0.0'"
        exit 0
    fi

    UNSIGNED_COUNT=0
    for tag in $RELEASE_TAGS; do
        if ! verify_tag "$tag"; then
            UNSIGNED_COUNT=$((UNSIGNED_COUNT + 1))
        fi
    done

    echo ""
    if [ "$UNSIGNED_COUNT" -gt 0 ]; then
        echo "OpenSSF Badge: version_tags_signed = Unmet"
        exit 1
    else
        echo "OpenSSF Badge: version_tags_signed = Met"
        exit 0
    fi
fi
