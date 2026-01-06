#!/usr/bin/env bash

#
# Extract Extension Configuration
#
# Extracts metadata and configuration from:
# - ext_emconf.php (extension metadata)
# - ext_conf_template.txt (configuration options)
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$(pwd)"
DATA_DIR="${PROJECT_DIR}/.claude/docs-extraction/data"

EXT_EMCONF="${PROJECT_DIR}/ext_emconf.php"
EXT_CONF_TEMPLATE="${PROJECT_DIR}/ext_conf_template.txt"

mkdir -p "${DATA_DIR}"

# Extract ext_emconf.php
if [ -f "${EXT_EMCONF}" ]; then
    echo "Extracting ext_emconf.php..."

    OUTPUT_FILE="${DATA_DIR}/extension_meta.json"

    # Use PHP to parse ext_emconf.php properly
    php -r "
    \$_EXTKEY = 'temp';
    include '${EXT_EMCONF}';
    echo json_encode([
        'extraction_date' => date('c'),
        'metadata' => \$EM_CONF[\$_EXTKEY] ?? []
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    " > "${OUTPUT_FILE}"

    echo -e "${GREEN}✓ ext_emconf.php extracted: ${OUTPUT_FILE}${NC}"
else
    echo -e "${YELLOW}No ext_emconf.php found, skipping${NC}"
fi

# Extract ext_conf_template.txt
if [ -f "${EXT_CONF_TEMPLATE}" ]; then
    echo "Extracting ext_conf_template.txt..."

    OUTPUT_FILE="${DATA_DIR}/config_options.json"

    # Parse ext_conf_template.txt format:
    # # cat=category/subcategory; type=type; label=Label: Description
    # settingName = defaultValue

    echo '{' > "${OUTPUT_FILE}"
    echo '  "extraction_date": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",' >> "${OUTPUT_FILE}"
    echo '  "config_options": [' >> "${OUTPUT_FILE}"

    first=true

    while IFS= read -r line; do
        # Check if comment line with metadata
        if [[ $line =~ ^#\ cat= ]]; then
            # Extract metadata from comment
            category=$(echo "$line" | sed -n 's/.*cat=\([^/;]*\).*/\1/p')
            subcategory=$(echo "$line" | sed -n 's/.*cat=[^/]*\/\([^;]*\).*/\1/p')
            type=$(echo "$line" | sed -n 's/.*type=\([^;]*\).*/\1/p')
            label_and_desc=$(echo "$line" | sed -n 's/.*label=\(.*\)/\1/p')
            label=$(echo "$label_and_desc" | cut -d':' -f1)
            description=$(echo "$label_and_desc" | cut -d':' -f2- | sed 's/^ *//')

            # Check for WARNING in description
            security_warning=""
            if echo "$description" | grep -qi "WARNING:"; then
                security_warning=$(echo "$description" | sed -n 's/.*WARNING: \(.*\)/\1/p')
                description=$(echo "$description" | sed 's/WARNING:.*//' | sed 's/ *$//')
            fi

            # Read next line for setting name and default
            read -r next_line
            if [[ $next_line =~ ^([^=]+)\ =\ (.+)$ ]]; then
                setting_name="${BASH_REMATCH[1]}"
                setting_name=$(echo "$setting_name" | sed 's/ *$//')
                default_value="${BASH_REMATCH[2]}"
                default_value=$(echo "$default_value" | sed 's/^ *//;s/ *$//')

                # Add comma for non-first entries
                if [ "$first" = false ]; then
                    echo '    ,' >> "${OUTPUT_FILE}"
                fi
                first=false

                # Write JSON entry
                echo '    {' >> "${OUTPUT_FILE}"
                echo '      "key": "'${setting_name}'",' >> "${OUTPUT_FILE}"
                echo '      "category": "'${category}'",' >> "${OUTPUT_FILE}"
                echo '      "subcategory": "'${subcategory}'",' >> "${OUTPUT_FILE}"
                echo '      "type": "'${type}'",' >> "${OUTPUT_FILE}"
                echo '      "label": "'"${label}"'",' >> "${OUTPUT_FILE}"
                echo '      "description": "'"${description}"'",' >> "${OUTPUT_FILE}"
                echo '      "default": "'"${default_value}"'"' >> "${OUTPUT_FILE}"
                if [ -n "$security_warning" ]; then
                    echo '      ,' >> "${OUTPUT_FILE}"
                    echo '      "security_warning": "'"${security_warning}"'"' >> "${OUTPUT_FILE}"
                fi
                echo -n '    }' >> "${OUTPUT_FILE}"
            fi
        fi
    done < "${EXT_CONF_TEMPLATE}"

    # Close JSON
    echo >> "${OUTPUT_FILE}"
    echo '  ]' >> "${OUTPUT_FILE}"
    echo '}' >> "${OUTPUT_FILE}"

    echo -e "${GREEN}✓ ext_conf_template.txt extracted: ${OUTPUT_FILE}${NC}"
else
    echo -e "${YELLOW}No ext_conf_template.txt found, skipping${NC}"
fi
