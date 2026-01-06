#!/usr/bin/env bash

#
# Analyze Documentation Coverage
#
# Compares extracted data with existing Documentation/ to identify:
# - Missing documentation
# - Outdated documentation
# - Inconsistencies
#
# Generates: Documentation/ANALYSIS.md
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$(pwd)"
DATA_DIR="${PROJECT_DIR}/.claude/docs-extraction/data"
DOC_DIR="${PROJECT_DIR}/Documentation"
ANALYSIS_FILE="${DOC_DIR}/ANALYSIS.md"

# TYPO3 Official Architecture Weights (from typo3-extension-architecture.md)
# BaseWeight for gap priority calculation: Priority = BaseWeight * Severity * UserImpact

# File Type Weights
declare -A BASE_WEIGHTS=(
    ["ext_conf_template"]=10      # User-facing configuration
    ["controller"]=9              # Core application logic
    ["model"]=9                   # Domain entities
    ["tca"]=8                     # Database configuration
    ["ext_emconf"]=8             # Extension metadata
    ["service"]=7                # Business logic
    ["repository"]=6             # Data access
    ["viewhelper"]=5             # Template helpers
    ["utility"]=4                # Helper functions
    ["other"]=3                  # Miscellaneous
)

# Severity Multipliers
SEVERITY_MISSING=3               # Completely undocumented
SEVERITY_OUTDATED=2              # Exists but wrong/incomplete
SEVERITY_INCOMPLETE=1            # Partial documentation

# User Impact Multipliers
IMPACT_USER=3                    # End users, editors
IMPACT_INTEGRATOR=2              # TypoScript, TSconfig
IMPACT_DEVELOPER=1               # API, internal code

# Function to calculate gap priority
# Usage: calculate_priority <base_weight> <severity> <impact>
calculate_priority() {
    local base_weight=$1
    local severity=$2
    local impact=$3
    echo $((base_weight * severity * impact))
}

# Function to determine class type from file path
get_class_type() {
    local file_path=$1
    if [[ "$file_path" == *"Controller"* ]]; then
        echo "controller"
    elif [[ "$file_path" == *"Domain/Model"* ]]; then
        echo "model"
    elif [[ "$file_path" == *"Domain/Repository"* ]]; then
        echo "repository"
    elif [[ "$file_path" == *"Service"* ]]; then
        echo "service"
    elif [[ "$file_path" == *"ViewHelper"* ]]; then
        echo "viewhelper"
    elif [[ "$file_path" == *"Utility"* ]]; then
        echo "utility"
    else
        echo "other"
    fi
}

echo -e "${GREEN}=== Documentation Coverage Analysis ===${NC}"
echo

# Check if Documentation/ exists
if [ ! -d "${DOC_DIR}" ]; then
    echo -e "${YELLOW}No Documentation/ directory found${NC}"
    echo "Run this from a TYPO3 extension root directory"
    exit 1
fi

# Check if extraction data exists
if [ ! -d "${DATA_DIR}" ]; then
    echo -e "${YELLOW}No extraction data found${NC}"
    echo "Run scripts/extract-all.sh first"
    exit 1
fi

echo "Project: ${PROJECT_DIR}"
echo "Documentation: ${DOC_DIR}"
echo "Extraction Data: ${DATA_DIR}"
echo

# Start analysis report
cat > "${ANALYSIS_FILE}" <<'EOF'
# Documentation Analysis Report

**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Summary

This report compares extracted project data with existing documentation to identify gaps and inconsistencies.

EOF

# Replace the date placeholder
sed -i "s/\$(date -u +\"%Y-%m-%d %H:%M:%S UTC\")/$(date -u +"%Y-%m-%d %H:%M:%S UTC")/g" "${ANALYSIS_FILE}"

# Analyze PHP APIs
echo -e "${BLUE}Analyzing PHP APIs...${NC}"

if [ -f "${DATA_DIR}/php_apis.json" ]; then
    total_classes=$(jq '.classes | length' "${DATA_DIR}/php_apis.json" 2>/dev/null || echo 0)

    # Count documented classes (look for .rst files in API/ or Developer/)
    documented_classes=0
    if [ -d "${DOC_DIR}/API" ] || [ -d "${DOC_DIR}/Developer" ]; then
        documented_classes=$(find "${DOC_DIR}" -name "*.rst" -type f -exec grep -l ".. php:class::" {} \; 2>/dev/null | wc -l)
    fi

    missing_classes=$((total_classes - documented_classes))

    cat >> "${ANALYSIS_FILE}" <<EOF

### PHP Classes

- **Total Classes:** ${total_classes}
- **Documented Classes:** ${documented_classes}
- **Missing Documentation:** ${missing_classes}

EOF

    if [ $missing_classes -gt 0 ]; then
        echo "## Missing Class Documentation" >> "${ANALYSIS_FILE}"
        echo >> "${ANALYSIS_FILE}"
        echo "Classes listed by **priority score** (Priority = BaseWeight × Severity × Impact)" >> "${ANALYSIS_FILE}"
        echo >> "${ANALYSIS_FILE}"

        # Create temporary file with priority calculations
        temp_classes=$(mktemp)

        # Extract classes with priority calculations
        jq -r '.classes[] | @json' "${DATA_DIR}/php_apis.json" 2>/dev/null | while IFS= read -r class_json; do
            file_path=$(echo "$class_json" | jq -r '.file')
            class_type=$(get_class_type "$file_path")
            base_weight=${BASE_WEIGHTS[$class_type]}
            priority=$(calculate_priority $base_weight $SEVERITY_MISSING $IMPACT_DEVELOPER)

            echo "$priority|$class_json" >> "$temp_classes"
        done

        # Sort by priority (descending) and output formatted
        sort -t'|' -k1 -rn "$temp_classes" 2>/dev/null | while IFS='|' read -r priority class_json; do
            namespace=$(echo "$class_json" | jq -r '.namespace')
            name=$(echo "$class_json" | jq -r '.name')
            file=$(echo "$class_json" | jq -r '.file')
            desc=$(echo "$class_json" | jq -r '.description')

            cat >> "${ANALYSIS_FILE}" <<CLASSEOF

### ${namespace}\\${name}

- **Priority Score:** ${priority} ⚠️
- **File:** \`${file}\`
- **Type:** ${class_type}
- **Description:** ${desc}
- **Suggested Location:** \`Documentation/API/${name}.rst\`

CLASSEOF
        done

        rm -f "$temp_classes"
    fi

    echo "  Classes: ${documented_classes}/${total_classes} documented"
fi

# Analyze Configuration Options
echo -e "${BLUE}Analyzing Configuration Options...${NC}"

if [ -f "${DATA_DIR}/config_options.json" ]; then
    total_options=$(jq '.config_options | length' "${DATA_DIR}/config_options.json" 2>/dev/null || echo 0)

    # Count documented confval directives
    documented_options=0
    if find "${DOC_DIR}" -name "*.rst" -type f -exec grep -q ".. confval::" {} \; 2>/dev/null; then
        documented_options=$(find "${DOC_DIR}" -name "*.rst" -type f -exec grep ".. confval::" {} \; 2>/dev/null | wc -l)
    fi

    missing_options=$((total_options - documented_options))

    cat >> "${ANALYSIS_FILE}" <<EOF

### Configuration Options

- **Total Options:** ${total_options}
- **Documented Options:** ${documented_options}
- **Missing Documentation:** ${missing_options}

EOF

    if [ $missing_options -gt 0 ]; then
        echo "## Missing Configuration Documentation" >> "${ANALYSIS_FILE}"
        echo >> "${ANALYSIS_FILE}"
        echo "Configuration options listed by **priority score** (Priority = BaseWeight × Severity × Impact)" >> "${ANALYSIS_FILE}"
        echo >> "${ANALYSIS_FILE}"

        # Configuration options are user-facing (HIGH priority)
        base_weight=${BASE_WEIGHTS["ext_conf_template"]}
        priority=$(calculate_priority $base_weight $SEVERITY_MISSING $IMPACT_USER)

        # List undocumented options with priority
        jq -r --arg priority "$priority" '.config_options[] |
               "### " + .key + "\n\n" +
               "- **Priority Score:** " + $priority + " 🚨\n" +
               "- **Type:** " + .type + "\n" +
               "- **Default:** `" + .default + "`\n" +
               "- **Description:** " + .description + "\n" +
               (if .security_warning then "- **⚠️ Security Warning:** " + .security_warning + "\n" else "" end) +
               "- **Suggested Location:** `Documentation/Integration/Configuration.rst`\n\n" +
               "**Template:**\n\n```rst\n" +
               ".. confval:: " + .key + "\n\n" +
               "   :type: " + .type + "\n" +
               "   :Default: " + .default + "\n" +
               "   :Path: $GLOBALS['"'"'TYPO3_CONF_VARS'"'"']['"'"'EXTENSIONS'"'"']['"'"'ext_key'"'"']['"'"'" + .key + "'"'"']\n\n" +
               "   " + .description + "\n" +
               (if .security_warning then "\n   .. warning::\n      " + .security_warning + "\n" else "" end) +
               "```\n"' \
               "${DATA_DIR}/config_options.json" 2>/dev/null >> "${ANALYSIS_FILE}" || true
    fi

    echo "  Options: ${documented_options}/${total_options} documented"
fi

# Check Extension Metadata
echo -e "${BLUE}Analyzing Extension Metadata...${NC}"

if [ -f "${DATA_DIR}/extension_meta.json" ]; then
    ext_version=$(jq -r '.metadata.version // "unknown"' "${DATA_DIR}/extension_meta.json" 2>/dev/null)
    ext_title=$(jq -r '.metadata.title // "unknown"' "${DATA_DIR}/extension_meta.json" 2>/dev/null)

    cat >> "${ANALYSIS_FILE}" <<EOF

### Extension Metadata

- **Title:** ${ext_title}
- **Version:** ${ext_version}
- **Location:** Check `Documentation/Index.rst` and `Documentation/Settings.cfg`

**Recommended Actions:**
- Verify version number in Settings.cfg matches ext_emconf.php
- Ensure extension title is documented in Index.rst
- Check TYPO3/PHP version constraints are in Installation requirements

EOF

    echo "  Extension: ${ext_title} v${ext_version}"
fi

# Priority Score Explanation
cat >> "${ANALYSIS_FILE}" <<'EOF'

## Priority Score System

Documentation gaps are ranked using **TYPO3 Official Architecture Weighting**:

```
Priority = BaseWeight × Severity × UserImpact
```

### Base Weights (by file type)
- **Configuration (ext_conf_template.txt):** 10 - User-facing settings
- **Controllers:** 9 - Core application logic
- **Models:** 9 - Domain entities
- **TCA:** 8 - Database configuration
- **Services:** 7 - Business logic
- **Repositories:** 6 - Data access
- **ViewHelpers:** 5 - Template helpers
- **Utilities:** 4 - Helper functions

### Severity Multipliers
- **Missing (3):** No documentation exists
- **Outdated (2):** Documentation exists but incorrect
- **Incomplete (1):** Partial documentation

### User Impact Multipliers
- **End Users (3):** Editors, content creators
- **Integrators (2):** TypoScript, TSconfig users
- **Developers (1):** PHP API users

### Example Calculations
- Missing config option: `10 × 3 × 3 = 90` 🚨 (HIGHEST)
- Missing controller: `9 × 3 × 1 = 27` ⚠️
- Missing utility: `4 × 3 × 1 = 12`

**Reference:** See `references/typo3-extension-architecture.md`

## Recommendations

Items above are **already sorted by priority score**. Focus on highest scores first.

### Immediate Actions (Priority Score ≥50)

1. **Document configuration options** (Score: 90) - Critical for users
2. **Document controllers and models** (Score: 27) - Essential for developers

### Quality Improvements

1. Run validation: `scripts/validate_docs.sh`
2. Render locally: `scripts/render_docs.sh`
3. Fix any rendering warnings or broken cross-references

### Enhancements

1. Add usage examples for all configuration options
2. Add code examples for all API methods
3. Consider adding screenshots for user-facing features

## Next Steps

1. **Review this analysis** - Focus on highest priority scores first
2. **Manual documentation** - Create missing RST files using provided templates
3. **Validate** - `scripts/validate_docs.sh`
4. **Render** - `scripts/render_docs.sh`
5. **Commit** - Add new documentation to version control

---

**Analysis Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Extraction Data:** See `.claude/docs-extraction/data/`
**Weighting Source:** TYPO3 Official Extension Architecture

EOF

# Replace date placeholder again
sed -i "s/\$(date -u +\"%Y-%m-%d %H:%M:%S UTC\")/$(date -u +"%Y-%m-%d %H:%M:%S UTC")/g" "${ANALYSIS_FILE}"

echo
echo -e "${GREEN}=== Analysis Complete ===${NC}"
echo
echo "Report generated: ${ANALYSIS_FILE}"
echo
echo -e "${YELLOW}Review the analysis report for documentation gaps and recommendations.${NC}"
echo
