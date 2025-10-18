#!/usr/bin/env bash

#
# Extract Build Configuration
#
# Extracts configuration from:
# - .github/workflows/*.yml (GitHub Actions)
# - .gitlab-ci.yml (GitLab CI)
# - phpunit.xml (PHPUnit config)
# - phpstan.neon (PHPStan config)
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$(pwd)"
DATA_DIR="${PROJECT_DIR}/.claude/docs-extraction/data"
OUTPUT_FILE="${DATA_DIR}/build_configs.json"

mkdir -p "${DATA_DIR}"

echo "Extracting build configurations..."

# Start JSON
echo '{' > "${OUTPUT_FILE}"
echo '  "extraction_date": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",' >> "${OUTPUT_FILE}"

# GitHub Actions
if [ -d "${PROJECT_DIR}/.github/workflows" ]; then
    workflow_files=$(find "${PROJECT_DIR}/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null || true)
    if [ -n "$workflow_files" ]; then
        echo '  "github_actions": {' >> "${OUTPUT_FILE}"
        echo '    "exists": true,' >> "${OUTPUT_FILE}"
        echo '    "files": [' >> "${OUTPUT_FILE}"
        first=true
        for wf in $workflow_files; do
            if [ "$first" = false ]; then echo '      ,' >> "${OUTPUT_FILE}"; fi
            first=false
            rel_path="${wf#$PROJECT_DIR/}"
            echo '      "'${rel_path}'"' >> "${OUTPUT_FILE}"
        done
        echo '    ]' >> "${OUTPUT_FILE}"
        echo '  },' >> "${OUTPUT_FILE}"
    else
        echo '  "github_actions": { "exists": false },' >> "${OUTPUT_FILE}"
    fi
else
    echo '  "github_actions": { "exists": false },' >> "${OUTPUT_FILE}"
fi

# GitLab CI
if [ -f "${PROJECT_DIR}/.gitlab-ci.yml" ]; then
    echo '  "gitlab_ci": { "exists": true, "file": ".gitlab-ci.yml" },' >> "${OUTPUT_FILE}"
else
    echo '  "gitlab_ci": { "exists": false },' >> "${OUTPUT_FILE}"
fi

# PHPUnit
phpunit_files=$(find "${PROJECT_DIR}" -maxdepth 2 -name "phpunit.xml*" 2>/dev/null || true)
if [ -n "$phpunit_files" ]; then
    echo '  "phpunit": { "exists": true, "files": [' >> "${OUTPUT_FILE}"
    first=true
    for pf in $phpunit_files; do
        if [ "$first" = false ]; then echo '      ,' >> "${OUTPUT_FILE}"; fi
        first=false
        rel_path="${pf#$PROJECT_DIR/}"
        echo '      "'${rel_path}'"' >> "${OUTPUT_FILE}"
    done
    echo '    ] },' >> "${OUTPUT_FILE}"
else
    echo '  "phpunit": { "exists": false },' >> "${OUTPUT_FILE}"
fi

# PHPStan
if [ -f "${PROJECT_DIR}/phpstan.neon" ] || [ -f "${PROJECT_DIR}/phpstan.neon.dist" ]; then
    echo '  "phpstan": { "exists": true }' >> "${OUTPUT_FILE}"
else
    echo '  "phpstan": { "exists": false }' >> "${OUTPUT_FILE}"
fi

# Close JSON
echo '}' >> "${OUTPUT_FILE}"

echo -e "${GREEN}✓ Build configs extracted: ${OUTPUT_FILE}${NC}"
