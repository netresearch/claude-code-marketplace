#!/usr/bin/env bash

#
# Extract Project Files
#
# Extracts content from:
# - README.md
# - CHANGELOG.md
# - CONTRIBUTING.md (if exists)
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$(pwd)"
DATA_DIR="${PROJECT_DIR}/.claude/docs-extraction/data"
OUTPUT_FILE="${DATA_DIR}/project_files.json"

mkdir -p "${DATA_DIR}"

echo "Extracting project files..."

# Start JSON
echo '{' > "${OUTPUT_FILE}"
echo '  "extraction_date": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",' >> "${OUTPUT_FILE}"

# Extract README.md
if [ -f "${PROJECT_DIR}/README.md" ]; then
    echo '  "readme": {' >> "${OUTPUT_FILE}"
    echo '    "exists": true,' >> "${OUTPUT_FILE}"
    echo '    "path": "README.md",' >> "${OUTPUT_FILE}"
    # Get first 100 lines as preview
    readme_content=$(head -100 "${PROJECT_DIR}/README.md" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    echo '    "content_preview": "'${readme_content}'"' >> "${OUTPUT_FILE}"
    echo '  },' >> "${OUTPUT_FILE}"
else
    echo '  "readme": { "exists": false },' >> "${OUTPUT_FILE}"
fi

# Extract CHANGELOG.md
if [ -f "${PROJECT_DIR}/CHANGELOG.md" ]; then
    echo '  "changelog": {' >> "${OUTPUT_FILE}"
    echo '    "exists": true,' >> "${OUTPUT_FILE}"
    echo '    "path": "CHANGELOG.md",' >> "${OUTPUT_FILE}"
    # Get first 50 lines as preview
    changelog_content=$(head -50 "${PROJECT_DIR}/CHANGELOG.md" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    echo '    "content_preview": "'${changelog_content}'"' >> "${OUTPUT_FILE}"
    echo '  },' >> "${OUTPUT_FILE}"
else
    echo '  "changelog": { "exists": false },' >> "${OUTPUT_FILE}"
fi

# Extract CONTRIBUTING.md
if [ -f "${PROJECT_DIR}/CONTRIBUTING.md" ]; then
    echo '  "contributing": {' >> "${OUTPUT_FILE}"
    echo '    "exists": true,' >> "${OUTPUT_FILE}"
    echo '    "path": "CONTRIBUTING.md"' >> "${OUTPUT_FILE}"
    echo '  }' >> "${OUTPUT_FILE}"
else
    echo '  "contributing": { "exists": false }' >> "${OUTPUT_FILE}"
fi

# Close JSON
echo '}' >> "${OUTPUT_FILE}"

echo -e "${GREEN}✓ Project files extracted: ${OUTPUT_FILE}${NC}"
