#!/bin/bash
# Create TYPO3 Forge issue via Redmine REST API
#
# Usage:
# 1. Get your API key from https://forge.typo3.org/my/account
# 2. Set environment variable: export FORGE_API_KEY="your-key-here"
# 3. Run: ./scripts/create-forge-issue.sh

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for API key
if [ -z "$FORGE_API_KEY" ]; then
    echo -e "${RED}Error: FORGE_API_KEY environment variable not set${NC}"
    echo ""
    echo "Get your API key from: https://forge.typo3.org/my/account"
    echo "Then set it: export FORGE_API_KEY=\"your-key-here\""
    exit 1
fi

# Check for required tools
for tool in curl jq; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}Error: $tool is required but not installed${NC}"
        exit 1
    fi
done

echo -e "${GREEN}TYPO3 Forge Issue Creator${NC}"
echo ""

# Interactive prompts
read -p "Issue subject (title): " SUBJECT
if [ -z "$SUBJECT" ]; then
    echo -e "${RED}Error: Subject is required${NC}"
    exit 1
fi

echo ""
echo "Issue description (multi-line, press Ctrl+D when done):"
DESCRIPTION=$(cat)
if [ -z "$DESCRIPTION" ]; then
    echo -e "${RED}Error: Description is required${NC}"
    exit 1
fi

echo ""
echo "Select tracker type:"
echo "  1) Bug"
echo "  2) Feature"
echo "  3) Task"
read -p "Choice [1]: " TRACKER_CHOICE
TRACKER_CHOICE=${TRACKER_CHOICE:-1}

case $TRACKER_CHOICE in
    1) TRACKER_ID=1; TRACKER_NAME="Bug" ;;
    2) TRACKER_ID=2; TRACKER_NAME="Feature" ;;
    3) TRACKER_ID=4; TRACKER_NAME="Task" ;;
    *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
esac

echo ""
echo "Select priority:"
echo "  1) Must have"
echo "  2) Should have (recommended)"
echo "  3) Could have"
read -p "Choice [2]: " PRIORITY_CHOICE
PRIORITY_CHOICE=${PRIORITY_CHOICE:-2}

case $PRIORITY_CHOICE in
    1) PRIORITY_ID=3; PRIORITY_NAME="Must have" ;;
    2) PRIORITY_ID=4; PRIORITY_NAME="Should have" ;;
    3) PRIORITY_ID=5; PRIORITY_NAME="Could have" ;;
    *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
esac

echo ""
read -p "TYPO3 version affected (e.g., 13, 14) [13]: " TYPO3_VERSION
TYPO3_VERSION=${TYPO3_VERSION:-13}

echo ""
echo "Select category (common ones, or enter ID manually):"
echo "  1) Miscellaneous (975)"
echo "  2) Backend API (971)"
echo "  3) Backend User Interface (972)"
echo "  4) Frontend (977)"
echo "  5) Database API (974)"
echo "  6) Indexed Search (1000)"
echo "  7) Extension Manager (976)"
echo "  8) Documentation (1004)"
echo "  9) Enter category ID manually"
read -p "Choice [1]: " CATEGORY_CHOICE
CATEGORY_CHOICE=${CATEGORY_CHOICE:-1}

case $CATEGORY_CHOICE in
    1) CATEGORY_ID=975; CATEGORY_NAME="Miscellaneous" ;;
    2) CATEGORY_ID=971; CATEGORY_NAME="Backend API" ;;
    3) CATEGORY_ID=972; CATEGORY_NAME="Backend User Interface" ;;
    4) CATEGORY_ID=977; CATEGORY_NAME="Frontend" ;;
    5) CATEGORY_ID=974; CATEGORY_NAME="Database API" ;;
    6) CATEGORY_ID=1000; CATEGORY_NAME="Indexed Search" ;;
    7) CATEGORY_ID=976; CATEGORY_NAME="Extension Manager" ;;
    8) CATEGORY_ID=1004; CATEGORY_NAME="Documentation" ;;
    9)
        read -p "Enter category ID: " CATEGORY_ID
        CATEGORY_NAME="Custom ($CATEGORY_ID)"
        ;;
    *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
esac

# Optional tags
echo ""
read -p "Tags (comma-separated, optional): " TAGS

# Summary
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  Tracker: $TRACKER_NAME"
echo "  Subject: $SUBJECT"
echo "  Priority: $PRIORITY_NAME"
echo "  Category: $CATEGORY_NAME"
echo "  TYPO3 Version: $TYPO3_VERSION"
[ -n "$TAGS" ] && echo "  Tags: $TAGS"
echo ""

read -p "Create this issue? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-Y}

if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Build JSON payload
JSON_PAYLOAD=$(jq -n \
    --arg subject "$SUBJECT" \
    --arg description "$DESCRIPTION" \
    --argjson tracker "$TRACKER_ID" \
    --argjson category "$CATEGORY_ID" \
    --argjson priority "$PRIORITY_ID" \
    --arg typo3_version "$TYPO3_VERSION" \
    --arg tags "$TAGS" \
    '{
        issue: {
            project_id: "typo3cms-core",
            subject: $subject,
            description: $description,
            tracker_id: $tracker,
            category_id: $category,
            priority_id: $priority,
            custom_fields: [
                {id: 4, value: $typo3_version}
            ] + (if $tags != "" then [{id: 3, value: $tags}] else [] end)
        }
    }')

# Create issue
echo ""
echo -e "${YELLOW}Creating issue...${NC}"

RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "X-Redmine-API-Key: $FORGE_API_KEY" \
    -d "$JSON_PAYLOAD" \
    https://forge.typo3.org/issues.json)

# Check for errors
if echo "$RESPONSE" | jq -e '.errors' > /dev/null 2>&1; then
    echo -e "${RED}Error creating issue:${NC}"
    echo "$RESPONSE" | jq -r '.errors[]'
    exit 1
fi

# Extract issue details
ISSUE_ID=$(echo "$RESPONSE" | jq -r '.issue.id')
ISSUE_URL="https://forge.typo3.org/issues/${ISSUE_ID}"

echo ""
echo -e "${GREEN}Success! Issue created:${NC}"
echo ""
echo "  Issue #: $ISSUE_ID"
echo "  URL: $ISSUE_URL"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Use in commit message: ${GREEN}Resolves: #${ISSUE_ID}${NC}"
echo "  2. Create feature branch: ${GREEN}git checkout -b feature/${ISSUE_ID}-description${NC}"
echo ""
