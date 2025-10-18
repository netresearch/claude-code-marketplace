#!/usr/bin/env bash

#
# Extract Composer Dependencies
#
# Extracts dependency information from composer.json
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$(pwd)"
DATA_DIR="${PROJECT_DIR}/.claude/docs-extraction/data"
COMPOSER_FILE="${PROJECT_DIR}/composer.json"
OUTPUT_FILE="${DATA_DIR}/dependencies.json"

mkdir -p "${DATA_DIR}"

if [ ! -f "${COMPOSER_FILE}" ]; then
    echo -e "${YELLOW}No composer.json found, skipping${NC}"
    echo '{"dependencies": {}}' > "${OUTPUT_FILE}"
    exit 0
fi

echo "Extracting composer.json..."

# Extract relevant sections using jq if available, otherwise use PHP
if command -v jq &> /dev/null; then
    jq '{
        extraction_date: now | todate,
        name: .name,
        description: .description,
        type: .type,
        require: .require,
        "require-dev": (."require-dev" // {}),
        autoload: .autoload,
        scripts: (.scripts // {})
    }' "${COMPOSER_FILE}" > "${OUTPUT_FILE}"
else
    # Fallback to PHP
    php -r "
    \$data = json_decode(file_get_contents('${COMPOSER_FILE}'), true);
    echo json_encode([
        'extraction_date' => date('c'),
        'name' => \$data['name'] ?? '',
        'description' => \$data['description'] ?? '',
        'type' => \$data['type'] ?? '',
        'require' => \$data['require'] ?? [],
        'require-dev' => \$data['require-dev'] ?? [],
        'autoload' => \$data['autoload'] ?? [],
        'scripts' => \$data['scripts'] ?? []
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    " > "${OUTPUT_FILE}"
fi

echo -e "${GREEN}✓ composer.json extracted: ${OUTPUT_FILE}${NC}"
