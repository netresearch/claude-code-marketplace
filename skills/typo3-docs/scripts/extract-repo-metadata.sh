#!/usr/bin/env bash

#
# Extract Repository Metadata
#
# Extracts metadata from GitHub or GitLab using CLI tools:
# - Repository description, topics, stats
# - Recent releases
# - Contributors
# - Open issues (optionally)
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$(pwd)"
DATA_DIR="${PROJECT_DIR}/.claude/docs-extraction/data"
CACHE_DIR="${PROJECT_DIR}/.claude/docs-extraction/cache"
OUTPUT_FILE="${DATA_DIR}/repo_metadata.json"
CACHE_FILE="${CACHE_DIR}/repo_metadata.json"

mkdir -p "${DATA_DIR}"
mkdir -p "${CACHE_DIR}"

# Check cache (24 hour TTL)
if [ -f "${CACHE_FILE}" ]; then
    cache_age=$(($(date +%s) - $(stat -c %Y "${CACHE_FILE}" 2>/dev/null || stat -f %m "${CACHE_FILE}" 2>/dev/null || echo 0)))
    if [ $cache_age -lt 86400 ]; then
        echo -e "${YELLOW}Using cached repository metadata (${cache_age}s old)${NC}"
        cp "${CACHE_FILE}" "${OUTPUT_FILE}"
        exit 0
    fi
fi

# Detect repository type
if git remote -v 2>/dev/null | grep -q github.com; then
    REPO_TYPE="github"
    REPO_URL=$(git remote -v | grep github.com | head -1 | sed 's/.*github.com[:/]\(.*\)\.git.*/\1/')
elif git remote -v 2>/dev/null | grep -q gitlab.com; then
    REPO_TYPE="gitlab"
    REPO_URL=$(git remote -v | grep gitlab.com | head -1 | sed 's/.*gitlab.com[:/]\(.*\)\.git.*/\1/')
else
    echo -e "${YELLOW}No GitHub/GitLab remote found, skipping repository metadata${NC}"
    echo '{"repository": {"exists": false}}' > "${OUTPUT_FILE}"
    exit 0
fi

echo "Detected ${REPO_TYPE} repository: ${REPO_URL}"

# Extract based on repository type
if [ "$REPO_TYPE" = "github" ]; then
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        echo -e "${YELLOW}gh CLI not found, skipping GitHub metadata${NC}"
        echo '{"repository": {"exists": false, "reason": "gh CLI not installed"}}' > "${OUTPUT_FILE}"
        exit 0
    fi

    echo "Extracting GitHub metadata..."

    # Get repository info
    gh api "repos/${REPO_URL}" --jq '{
        extraction_date: now | todate,
        repository: {
            type: "github",
            name: .name,
            full_name: .full_name,
            description: .description,
            topics: .topics,
            stars: .stargazers_count,
            forks: .forks_count,
            open_issues: .open_issues_count,
            created_at: .created_at,
            updated_at: .updated_at,
            homepage: .homepage
        }
    }' > "${OUTPUT_FILE}"

    # Get releases
    gh api "repos/${REPO_URL}/releases?per_page=5" --jq 'map({
        tag: .tag_name,
        name: .name,
        published_at: .published_at,
        prerelease: .prerelease
    })' > /tmp/releases.json

    # Get contributors
    gh api "repos/${REPO_URL}/contributors?per_page=10" --jq 'map({
        login: .login,
        contributions: .contributions
    })' > /tmp/contributors.json

    # Merge into output file
    jq --slurpfile releases /tmp/releases.json --slurpfile contributors /tmp/contributors.json \
        '. + {releases: $releases[0], contributors: $contributors[0]}' "${OUTPUT_FILE}" > /tmp/merged.json
    mv /tmp/merged.json "${OUTPUT_FILE}"

    # Clean up temp files
    rm -f /tmp/releases.json /tmp/contributors.json

    echo -e "${GREEN}✓ GitHub metadata extracted: ${OUTPUT_FILE}${NC}"

elif [ "$REPO_TYPE" = "gitlab" ]; then
    # Check if glab CLI is available
    if ! command -v glab &> /dev/null; then
        echo -e "${YELLOW}glab CLI not found, skipping GitLab metadata${NC}"
        echo '{"repository": {"exists": false, "reason": "glab CLI not installed"}}' > "${OUTPUT_FILE}"
        exit 0
    fi

    echo "Extracting GitLab metadata..."

    # Get repository info
    glab api "projects/$(echo ${REPO_URL} | sed 's/\//%2F/g')" --jq '{
        extraction_date: now | todate,
        repository: {
            type: "gitlab",
            name: .name,
            full_name: .path_with_namespace,
            description: .description,
            topics: .topics,
            stars: .star_count,
            forks: .forks_count,
            open_issues: .open_issues_count,
            created_at: .created_at,
            updated_at: .last_activity_at
        }
    }' > "${OUTPUT_FILE}"

    echo -e "${GREEN}✓ GitLab metadata extracted: ${OUTPUT_FILE}${NC}"
fi

# Cache the result
cp "${OUTPUT_FILE}" "${CACHE_FILE}"
echo "Cached metadata for 24 hours"
