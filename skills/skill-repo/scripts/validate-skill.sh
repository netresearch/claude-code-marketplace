#!/bin/bash
# validate-skill.sh - Validate skill repository structure
# Usage: ./scripts/validate-skill.sh [path]

set -euo pipefail

SKILL_DIR="${1:-.}"
ERRORS=0
WARNINGS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}ERROR:${NC} $1"
    ((ERRORS++))
}

warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
    ((WARNINGS++))
}

success() {
    echo -e "${GREEN}OK:${NC} $1"
}

echo "Validating skill repository: $SKILL_DIR"
echo "========================================"

# Check SKILL.md exists
if [[ -f "$SKILL_DIR/SKILL.md" ]]; then
    success "SKILL.md exists"

    # Check frontmatter
    if head -1 "$SKILL_DIR/SKILL.md" | grep -q "^---$"; then
        success "SKILL.md has frontmatter delimiter"

        # Check name field
        if grep -q "^name:" "$SKILL_DIR/SKILL.md"; then
            NAME=$(grep "^name:" "$SKILL_DIR/SKILL.md" | head -1 | sed 's/name: *//')
            if [[ "$NAME" =~ ^[a-z0-9-]{1,64}$ ]]; then
                success "SKILL.md name is valid: $NAME"
            else
                error "SKILL.md name invalid (must be lowercase, hyphens, max 64 chars): $NAME"
            fi
        else
            error "SKILL.md missing 'name' field in frontmatter"
        fi

        # Check description field
        if grep -q "^description:" "$SKILL_DIR/SKILL.md"; then
            success "SKILL.md has description field"
        else
            error "SKILL.md missing 'description' field in frontmatter"
        fi
    else
        error "SKILL.md missing frontmatter (must start with ---)"
    fi

    # Check line count
    LINES=$(wc -l < "$SKILL_DIR/SKILL.md")
    if [[ $LINES -le 500 ]]; then
        success "SKILL.md is $LINES lines (under 500 limit)"
    else
        warning "SKILL.md is $LINES lines (recommended max 500)"
    fi
else
    error "SKILL.md not found"
fi

# Check README.md exists
if [[ -f "$SKILL_DIR/README.md" ]]; then
    success "README.md exists"

    # Check for Netresearch footer
    if grep -q "Netresearch" "$SKILL_DIR/README.md"; then
        success "README.md contains Netresearch reference"
    else
        warning "README.md should contain Netresearch credits"
    fi

    # Check for installation section
    if grep -qi "## Installation" "$SKILL_DIR/README.md"; then
        success "README.md has Installation section"
    else
        warning "README.md should have Installation section"
    fi
else
    error "README.md not found"
fi

# Check LICENSE exists
if [[ -f "$SKILL_DIR/LICENSE" ]]; then
    success "LICENSE exists"
else
    error "LICENSE not found"
fi

# Check for composer.lock (should NOT exist)
if [[ -f "$SKILL_DIR/composer.lock" ]]; then
    error "composer.lock should not exist in skill repos"
else
    success "No composer.lock (correct)"
fi

# Check composer.json if exists
if [[ -f "$SKILL_DIR/composer.json" ]]; then
    success "composer.json exists"

    # Check type
    if grep -q '"type".*"ai-agent-skill"' "$SKILL_DIR/composer.json"; then
        success "composer.json has correct type"
    else
        error "composer.json type should be 'ai-agent-skill'"
    fi

    # Check for skill plugin dependency
    if grep -q "composer-agent-skill-plugin" "$SKILL_DIR/composer.json"; then
        success "composer.json requires skill plugin"
    else
        warning "composer.json should require netresearch/composer-agent-skill-plugin"
    fi

    # Check for ai-agent-skill extra
    if grep -q '"ai-agent-skill"' "$SKILL_DIR/composer.json"; then
        success "composer.json has ai-agent-skill extra"
    else
        error "composer.json missing 'extra.ai-agent-skill' configuration"
    fi
fi

# Check for common directories
for dir in references scripts assets; do
    if [[ -d "$SKILL_DIR/$dir" ]]; then
        success "$dir/ directory exists"
    fi
done

# Summary
echo ""
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}Skill repository is valid!${NC}"
    exit 0
else
    echo -e "${RED}Skill repository has errors that must be fixed.${NC}"
    exit 1
fi
