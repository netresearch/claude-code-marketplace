#!/usr/bin/env bash
# Extract information from platform-specific files (.github/, .gitlab/, etc.)
set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# Helper to extract checklist items from markdown
extract_checklist() {
    local file="$1"
    local items=()

    if [ ! -f "$file" ]; then
        echo "[]"
        return
    fi

    # Find checkbox lines: - [ ] text or - [x] text
    while IFS= read -r line; do
        # Extract text after checkbox
        text=$(echo "$line" | sed -E 's/^[[:space:]]*[-*][[:space:]]*\[[[:space:]x]\][[:space:]]*//')
        if [ -n "$text" ] && [ ${#text} -gt 3 ]; then
            items+=("$text")
        fi
    done < <(grep -E '^\s*[-*]\s*\[[[:space:]x]\]' "$file" 2>/dev/null || true)

    if [ ${#items[@]} -eq 0 ]; then
        echo "[]"
    else
        printf '%s\n' "${items[@]}" | jq -R . | jq -s .
    fi
}

# Extract required fields from issue templates (YAML front matter)
extract_issue_template_fields() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "[]"
        return
    fi

    # Check for YAML form-based template
    if grep -q "^type:" "$file" 2>/dev/null; then
        # Extract field labels marked as required
        grep -B2 "required: true" "$file" 2>/dev/null | grep "label:" | sed 's/.*label:[[:space:]]*//' | jq -R . | jq -s .
    else
        echo "[]"
    fi
}

# Parse CODEOWNERS file
parse_codeowners() {
    local file="$1"
    local owners=()

    if [ ! -f "$file" ]; then
        echo "[]"
        return
    fi

    # Extract pattern and owners (skip comments and empty lines)
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Parse pattern and owners
        pattern=$(echo "$line" | awk '{print $1}')
        owner=$(echo "$line" | awk '{$1=""; print}' | sed 's/^[[:space:]]*//')

        if [ -n "$pattern" ] && [ -n "$owner" ]; then
            owners+=("{\"pattern\": \"$pattern\", \"owners\": \"$owner\"}")
        fi
    done < "$file"

    if [ ${#owners[@]} -eq 0 ]; then
        echo "[]"
    else
        printf '%s\n' "${owners[@]}" | jq -s .
    fi
}

# Parse dependabot.yml
parse_dependabot() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "{}"
        return
    fi

    # Extract package ecosystems and schedules
    local ecosystems=()
    local current_eco=""
    local current_schedule=""

    while IFS= read -r line; do
        if [[ "$line" =~ package-ecosystem:[[:space:]]*\"?([^\"]+)\"? ]]; then
            current_eco="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ interval:[[:space:]]*\"?([^\"]+)\"? ]]; then
            current_schedule="${BASH_REMATCH[1]}"
            if [ -n "$current_eco" ]; then
                ecosystems+=("{\"ecosystem\": \"$current_eco\", \"schedule\": \"$current_schedule\"}")
                current_eco=""
                current_schedule=""
            fi
        fi
    done < "$file"

    if [ ${#ecosystems[@]} -eq 0 ]; then
        echo "{\"updates\": []}"
    else
        printf '%s\n' "${ecosystems[@]}" | jq -s '{updates: .}'
    fi
}

# Parse renovate.json
parse_renovate() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "{}"
        return
    fi

    # Extract key configuration
    jq '{
        extends: .extends,
        schedule: .schedule,
        automerge: .automerge,
        labels: .labels
    }' "$file" 2>/dev/null || echo "{}"
}

# Detect platform type
PLATFORM="none"
if [ -d ".github" ]; then
    PLATFORM="github"
elif [ -d ".gitlab" ]; then
    PLATFORM="gitlab"
elif [ -d ".bitbucket" ]; then
    PLATFORM="bitbucket"
fi

# Initialize result variables
PR_TEMPLATE_FILE=""
PR_CHECKLIST="[]"
ISSUE_TEMPLATES=()
CODEOWNERS_FILE=""
CODEOWNERS_RULES="[]"
DEPENDABOT_FILE=""
DEPENDABOT_CONFIG="{}"
RENOVATE_FILE=""
RENOVATE_CONFIG="{}"
FUNDING_FILE=""
FUNDING_SPONSORS="[]"

# GitHub-specific extraction
if [ "$PLATFORM" = "github" ]; then
    # PR template
    for f in .github/PULL_REQUEST_TEMPLATE.md .github/pull_request_template.md PULL_REQUEST_TEMPLATE.md; do
        if [ -f "$f" ]; then
            PR_TEMPLATE_FILE="$f"
            PR_CHECKLIST=$(extract_checklist "$f")
            break
        fi
    done

    # Issue templates
    if [ -d ".github/ISSUE_TEMPLATE" ]; then
        for template in .github/ISSUE_TEMPLATE/*.md .github/ISSUE_TEMPLATE/*.yml .github/ISSUE_TEMPLATE/*.yaml; do
            if [ -f "$template" ]; then
                name=$(basename "$template" | sed 's/\.[^.]*$//')
                fields=$(extract_issue_template_fields "$template")
                ISSUE_TEMPLATES+=("{\"name\": \"$name\", \"file\": \"$template\", \"required_fields\": $fields}")
            fi
        done
    fi

    # CODEOWNERS
    for f in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do
        if [ -f "$f" ]; then
            CODEOWNERS_FILE="$f"
            CODEOWNERS_RULES=$(parse_codeowners "$f")
            break
        fi
    done

    # Dependabot
    for f in .github/dependabot.yml .github/dependabot.yaml; do
        if [ -f "$f" ]; then
            DEPENDABOT_FILE="$f"
            DEPENDABOT_CONFIG=$(parse_dependabot "$f")
            break
        fi
    done

    # Renovate (can be in root or .github)
    for f in renovate.json .github/renovate.json renovate.json5 .renovaterc .renovaterc.json; do
        if [ -f "$f" ]; then
            RENOVATE_FILE="$f"
            RENOVATE_CONFIG=$(parse_renovate "$f")
            break
        fi
    done

    # Funding
    if [ -f ".github/FUNDING.yml" ]; then
        FUNDING_FILE=".github/FUNDING.yml"
        # Extract sponsor platforms
        FUNDING_SPONSORS=$(grep -E "^[a-z_]+:" "$FUNDING_FILE" 2>/dev/null | cut -d: -f1 | jq -R . | jq -s . || echo "[]")
    fi
fi

# GitLab-specific extraction
if [ "$PLATFORM" = "gitlab" ]; then
    # MR template
    for f in .gitlab/merge_request_templates/Default.md .gitlab/merge_request_templates/*.md; do
        if [ -f "$f" ]; then
            PR_TEMPLATE_FILE="$f"
            PR_CHECKLIST=$(extract_checklist "$f")
            break
        fi
    done

    # Issue templates
    if [ -d ".gitlab/issue_templates" ]; then
        for template in .gitlab/issue_templates/*.md; do
            if [ -f "$template" ]; then
                name=$(basename "$template" .md)
                ISSUE_TEMPLATES+=("{\"name\": \"$name\", \"file\": \"$template\", \"required_fields\": []}")
            fi
        done
    fi

    # CODEOWNERS
    if [ -f "CODEOWNERS" ]; then
        CODEOWNERS_FILE="CODEOWNERS"
        CODEOWNERS_RULES=$(parse_codeowners "CODEOWNERS")
    fi
fi

# Build issue templates JSON
if [ ${#ISSUE_TEMPLATES[@]} -eq 0 ]; then
    ISSUE_TEMPLATES_JSON="[]"
else
    ISSUE_TEMPLATES_JSON=$(printf '%s\n' "${ISSUE_TEMPLATES[@]}" | jq -s .)
fi

# Build final JSON output
jq -n \
    --arg platform "$PLATFORM" \
    --arg pr_template "$PR_TEMPLATE_FILE" \
    --argjson pr_checklist "$PR_CHECKLIST" \
    --argjson issue_templates "$ISSUE_TEMPLATES_JSON" \
    --arg codeowners_file "$CODEOWNERS_FILE" \
    --argjson codeowners_rules "$CODEOWNERS_RULES" \
    --arg dependabot_file "$DEPENDABOT_FILE" \
    --argjson dependabot "$DEPENDABOT_CONFIG" \
    --arg renovate_file "$RENOVATE_FILE" \
    --argjson renovate "$RENOVATE_CONFIG" \
    --arg funding_file "$FUNDING_FILE" \
    --argjson funding_sponsors "$FUNDING_SPONSORS" \
    '{
        platform: $platform,
        pull_request: {
            template_file: $pr_template,
            checklist_items: $pr_checklist
        },
        issue_templates: $issue_templates,
        codeowners: {
            file: $codeowners_file,
            rules: $codeowners_rules
        },
        dependency_updates: {
            dependabot: {
                file: $dependabot_file,
                config: $dependabot
            },
            renovate: {
                file: $renovate_file,
                config: $renovate
            }
        },
        funding: {
            file: $funding_file,
            sponsors: $funding_sponsors
        }
    }'
