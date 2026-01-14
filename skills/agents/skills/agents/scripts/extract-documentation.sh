#!/usr/bin/env bash
# Extract information from documentation files (README, CONTRIBUTING, SECURITY, etc.)
set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# Initialize outputs
PROJECT_DESCRIPTION=""
PROJECT_BADGES=()
ARCHITECTURE_SECTION=""
CONTRIBUTING_RULES=()
PR_PROCESS=""
CODE_STYLE_RULES=()
SECURITY_POLICY=""
VULNERABILITY_REPORTING=""
CHANGELOG_FORMAT=""
CODE_OF_CONDUCT=""

# Helper to extract section from markdown
# Usage: extract_section "file" "heading" [max_lines]
extract_section() {
    local file="$1"
    local heading="$2"
    local max_lines="${3:-20}"

    if [ ! -f "$file" ]; then
        echo ""
        return
    fi

    # Find section and extract content until next heading
    awk -v heading="$heading" -v max="$max_lines" '
        BEGIN { found=0; count=0 }
        /^##?#?[[:space:]]/ {
            if (found) exit
            if (tolower($0) ~ tolower(heading)) { found=1; next }
        }
        found && count < max { print; count++ }
    ' "$file"
}

# Extract first paragraph after title (project description)
extract_description() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo ""
        return
    fi

    # Skip title and badges, get first paragraph
    awk '
        BEGIN { started=0; in_para=0 }
        /^#[^#]/ { started=1; next }
        started && /^\[!\[/ { next }  # Skip badges
        started && /^[![]/ { next }   # Skip images
        started && /^>/ { next }      # Skip blockquotes initially
        started && !in_para && /^[A-Za-z]/ { in_para=1 }
        in_para && /^$/ { exit }
        in_para { print }
    ' "$file" | head -5
}

# Extract badges from README
extract_badges() {
    local file="$1"
    local badges=()

    if [ ! -f "$file" ]; then
        echo "[]"
        return
    fi

    # Find badge patterns: [![text](url)](link) or ![text](url)
    while IFS= read -r line; do
        if [[ "$line" =~ \[!\[([^\]]+)\] ]]; then
            badges+=("${BASH_REMATCH[1]}")
        elif [[ "$line" =~ !\[([^\]]+)\] ]]; then
            badges+=("${BASH_REMATCH[1]}")
        fi
    done < <(grep -E '^\[?!\[' "$file" 2>/dev/null || true)

    if [ ${#badges[@]} -eq 0 ]; then
        echo "[]"
    else
        printf '%s\n' "${badges[@]}" | jq -R . | jq -s .
    fi
}

# Extract key rules from CONTRIBUTING.md
extract_contributing_rules() {
    local file="$1"
    local rules=()

    if [ ! -f "$file" ]; then
        echo "[]"
        return
    fi

    # Extract bullet points from key sections
    while IFS= read -r line; do
        # Clean up the line
        line=$(echo "$line" | sed 's/^[[:space:]]*[-*][[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [ -n "$line" ] && [ ${#line} -gt 10 ] && [ ${#line} -lt 200 ]; then
            rules+=("$line")
        fi
    done < <(grep -E '^[[:space:]]*[-*][[:space:]]' "$file" 2>/dev/null | head -20 || true)

    if [ ${#rules[@]} -eq 0 ]; then
        echo "[]"
    else
        printf '%s\n' "${rules[@]}" | jq -R . | jq -s .
    fi
}

# Check for PR process documentation
extract_pr_process() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo ""
        return
    fi

    # Look for PR-related sections
    local section
    section=$(extract_section "$file" "pull request" 15)
    if [ -z "$section" ]; then
        section=$(extract_section "$file" "submitting" 15)
    fi
    if [ -z "$section" ]; then
        section=$(extract_section "$file" "how to contribute" 15)
    fi

    echo "$section" | head -10
}

# Extract security policy
extract_security_policy() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo ""
        return
    fi

    # Get main content
    awk '
        BEGIN { started=0 }
        /^#/ { started=1; next }
        started { print }
    ' "$file" | head -20
}

# Detect changelog format
detect_changelog_format() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "none"
        return
    fi

    # Check for Keep a Changelog format
    if grep -qi "keep a changelog" "$file" 2>/dev/null; then
        echo "keepachangelog"
        return
    fi

    # Check for conventional changelog
    if grep -qE '^\s*###?\s*(Added|Changed|Deprecated|Removed|Fixed|Security)' "$file" 2>/dev/null; then
        echo "keepachangelog"
        return
    fi

    # Check for date-based entries
    if grep -qE '^\s*##\s*\[?[0-9]+\.[0-9]+' "$file" 2>/dev/null; then
        echo "semver-sections"
        return
    fi

    # Check for simple list format
    if grep -qE '^[-*]\s+' "$file" 2>/dev/null; then
        echo "simple-list"
        return
    fi

    echo "custom"
}

# Main extraction

# README.md
if [ -f "README.md" ]; then
    PROJECT_DESCRIPTION=$(extract_description "README.md")
    BADGES_JSON=$(extract_badges "README.md")
    ARCHITECTURE_SECTION=$(extract_section "README.md" "architecture" 30)
    if [ -z "$ARCHITECTURE_SECTION" ]; then
        ARCHITECTURE_SECTION=$(extract_section "README.md" "structure" 30)
    fi
fi

# CONTRIBUTING.md (check multiple locations)
CONTRIBUTING_FILE=""
for f in CONTRIBUTING.md .github/CONTRIBUTING.md docs/CONTRIBUTING.md; do
    if [ -f "$f" ]; then
        CONTRIBUTING_FILE="$f"
        break
    fi
done

if [ -n "$CONTRIBUTING_FILE" ]; then
    CONTRIBUTING_RULES_JSON=$(extract_contributing_rules "$CONTRIBUTING_FILE")
    PR_PROCESS=$(extract_pr_process "$CONTRIBUTING_FILE")
    CODE_STYLE_SECTION=$(extract_section "$CONTRIBUTING_FILE" "code style" 20)
    if [ -z "$CODE_STYLE_SECTION" ]; then
        CODE_STYLE_SECTION=$(extract_section "$CONTRIBUTING_FILE" "style guide" 20)
    fi
else
    CONTRIBUTING_RULES_JSON="[]"
    CODE_STYLE_SECTION=""
fi

# SECURITY.md (check multiple locations)
SECURITY_FILE=""
for f in SECURITY.md .github/SECURITY.md docs/SECURITY.md; do
    if [ -f "$f" ]; then
        SECURITY_FILE="$f"
        break
    fi
done

if [ -n "$SECURITY_FILE" ]; then
    SECURITY_POLICY=$(extract_security_policy "$SECURITY_FILE")
    VULNERABILITY_REPORTING=$(extract_section "$SECURITY_FILE" "reporting" 15)
else
    SECURITY_POLICY=""
    VULNERABILITY_REPORTING=""
fi

# CHANGELOG.md
CHANGELOG_FILE=""
for f in CHANGELOG.md HISTORY.md CHANGES.md; do
    if [ -f "$f" ]; then
        CHANGELOG_FILE="$f"
        break
    fi
done

if [ -n "$CHANGELOG_FILE" ]; then
    CHANGELOG_FORMAT=$(detect_changelog_format "$CHANGELOG_FILE")
else
    CHANGELOG_FORMAT="none"
fi

# CODE_OF_CONDUCT.md
COC_FILE=""
for f in CODE_OF_CONDUCT.md .github/CODE_OF_CONDUCT.md; do
    if [ -f "$f" ]; then
        COC_FILE="$f"
        break
    fi
done

HAS_CODE_OF_CONDUCT=false
if [ -n "$COC_FILE" ]; then
    HAS_CODE_OF_CONDUCT=true
fi

# Build JSON output
jq -n \
    --arg desc "$PROJECT_DESCRIPTION" \
    --argjson badges "${BADGES_JSON:-[]}" \
    --arg arch "$ARCHITECTURE_SECTION" \
    --arg contributing_file "$CONTRIBUTING_FILE" \
    --argjson contributing_rules "${CONTRIBUTING_RULES_JSON:-[]}" \
    --arg pr_process "$PR_PROCESS" \
    --arg code_style "$CODE_STYLE_SECTION" \
    --arg security_file "$SECURITY_FILE" \
    --arg security_policy "$SECURITY_POLICY" \
    --arg vuln_reporting "$VULNERABILITY_REPORTING" \
    --arg changelog_file "$CHANGELOG_FILE" \
    --arg changelog_format "$CHANGELOG_FORMAT" \
    --argjson has_coc "$HAS_CODE_OF_CONDUCT" \
    --arg coc_file "$COC_FILE" \
    '{
        readme: {
            description: $desc,
            badges: $badges,
            architecture_section: $arch
        },
        contributing: {
            file: $contributing_file,
            rules: $contributing_rules,
            pr_process: $pr_process,
            code_style: $code_style
        },
        security: {
            file: $security_file,
            policy: $security_policy,
            vulnerability_reporting: $vuln_reporting
        },
        changelog: {
            file: $changelog_file,
            format: $changelog_format
        },
        code_of_conduct: {
            exists: $has_coc,
            file: $coc_file
        }
    }'
