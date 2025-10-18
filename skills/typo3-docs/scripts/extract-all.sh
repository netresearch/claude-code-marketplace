#!/usr/bin/env bash

#
# Extract All Documentation Data
#
# Orchestrates extraction from all available sources:
# - PHP source code
# - Extension configuration
# - TYPO3 configuration
# - Composer dependencies
# - Project files (README, CHANGELOG)
# - Build configurations (optional)
# - Repository metadata (optional)
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_DIR="$(pwd)"

EXTRACTION_DIR="${PROJECT_DIR}/.claude/docs-extraction"
DATA_DIR="${EXTRACTION_DIR}/data"
CACHE_DIR="${EXTRACTION_DIR}/cache"

echo -e "${GREEN}=== TYPO3 Documentation Extraction ===${NC}"
echo
echo "Project: ${PROJECT_DIR}"
echo "Extraction Directory: ${EXTRACTION_DIR}"
echo

# Create directories
mkdir -p "${DATA_DIR}"
mkdir -p "${CACHE_DIR}"

# Extraction flags
EXTRACT_BUILD=false
EXTRACT_REPO=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            EXTRACT_BUILD=true
            shift
            ;;
        --repo)
            EXTRACT_REPO=true
            shift
            ;;
        --all)
            EXTRACT_BUILD=true
            EXTRACT_REPO=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Options:"
            echo "  --build     Include build configuration extraction (.github, phpunit.xml, etc.)"
            echo "  --repo      Include repository metadata extraction (requires network)"
            echo "  --all       Extract everything (build + repo)"
            echo "  -h, --help  Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Core extractions (always run)
echo -e "${BLUE}Running core extractions...${NC}"
echo

# 1. PHP Code
echo -e "${YELLOW}→ Extracting PHP code...${NC}"
if "${SCRIPT_DIR}/extract-php.sh"; then
    echo -e "${GREEN}✓ PHP extraction complete${NC}"
else
    echo -e "${RED}✗ PHP extraction failed${NC}"
fi
echo

# 2. Extension Configuration
echo -e "${YELLOW}→ Extracting extension configuration...${NC}"
if "${SCRIPT_DIR}/extract-extension-config.sh"; then
    echo -e "${GREEN}✓ Extension config extraction complete${NC}"
else
    echo -e "${RED}✗ Extension config extraction failed${NC}"
fi
echo

# 3. Composer Dependencies
echo -e "${YELLOW}→ Extracting composer dependencies...${NC}"
if "${SCRIPT_DIR}/extract-composer.sh"; then
    echo -e "${GREEN}✓ Composer extraction complete${NC}"
else
    echo -e "${RED}✗ Composer extraction failed${NC}"
fi
echo

# 4. Project Files
echo -e "${YELLOW}→ Extracting project files...${NC}"
if "${SCRIPT_DIR}/extract-project-files.sh"; then
    echo -e "${GREEN}✓ Project files extraction complete${NC}"
else
    echo -e "${RED}✗ Project files extraction failed${NC}"
fi
echo

# Optional extractions
if [ "$EXTRACT_BUILD" = true ]; then
    echo -e "${BLUE}Running build configuration extraction...${NC}"
    echo

    echo -e "${YELLOW}→ Extracting build configs...${NC}"
    if "${SCRIPT_DIR}/extract-build-configs.sh"; then
        echo -e "${GREEN}✓ Build config extraction complete${NC}"
    else
        echo -e "${RED}✗ Build config extraction failed${NC}"
    fi
    echo
fi

if [ "$EXTRACT_REPO" = true ]; then
    echo -e "${BLUE}Running repository metadata extraction...${NC}"
    echo

    echo -e "${YELLOW}→ Extracting repository metadata...${NC}"
    if "${SCRIPT_DIR}/extract-repo-metadata.sh"; then
        echo -e "${GREEN}✓ Repository metadata extraction complete${NC}"
    else
        echo -e "${RED}✗ Repository metadata extraction failed (network or auth issue?)${NC}"
    fi
    echo
fi

# Summary
echo -e "${GREEN}=== Extraction Complete ===${NC}"
echo
echo "Extracted data saved to: ${DATA_DIR}"
echo
echo "Next steps:"
echo "1. Review extracted data: ls -lh ${DATA_DIR}"
echo "2. Run gap analysis: ${SCRIPT_DIR}/analyze-docs.sh"
echo "3. Generate RST templates: ${SCRIPT_DIR}/generate-templates.sh"
echo "4. Review templates: Documentation/GENERATED/"
echo
