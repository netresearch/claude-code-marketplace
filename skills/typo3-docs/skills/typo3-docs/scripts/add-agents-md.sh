#!/usr/bin/env bash

#
# Add AGENTS.md to Documentation/ folder
#
# This script creates an AGENTS.md file in the Documentation/ directory
# to provide context for AI assistants working with TYPO3 documentation.
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_DIR="$(pwd)"

DOC_DIR="${PROJECT_DIR}/Documentation"
AGENTS_FILE="${DOC_DIR}/AGENTS.md"

echo -e "${GREEN}=== Add AGENTS.md to Documentation/ ===${NC}"
echo

# Check if Documentation directory exists
if [ ! -d "${DOC_DIR}" ]; then
    echo -e "${RED}Error: Documentation/ directory not found${NC}"
    echo "Current directory: ${PROJECT_DIR}"
    echo "Please run this script from your TYPO3 extension root directory"
    exit 1
fi

# Check if AGENTS.md already exists
if [ -f "${AGENTS_FILE}" ]; then
    echo -e "${YELLOW}⚠ AGENTS.md already exists in Documentation/${NC}"
    echo
    read -p "Do you want to overwrite it? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Copy AGENTS.md template
echo -e "${YELLOW}Creating AGENTS.md from template...${NC}"
cp "${SKILL_DIR}/assets/AGENTS.md" "${AGENTS_FILE}"

echo -e "${GREEN}✓ Created ${AGENTS_FILE}${NC}"
echo
echo "Next steps:"
echo "1. Edit Documentation/AGENTS.md to customize:"
echo "   - Documentation Strategy section"
echo "   - Target Audience"
echo "   - Main Topics"
echo
echo "2. The AGENTS.md file provides context for AI assistants:"
echo "   - TYPO3 RST syntax and directives"
echo "   - Documentation structure patterns"
echo "   - Rendering and validation procedures"
echo "   - Cross-reference patterns"
echo
echo "3. This file helps AI assistants:"
echo "   - Understand documentation purpose and audience"
echo "   - Apply correct RST syntax and TYPO3 directives"
echo "   - Follow documentation best practices"
echo "   - Navigate the documentation structure"
