#!/usr/bin/env bash
# Extract information from AI coding agent configuration files
set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# Extract content from markdown-based instructions
extract_md_instructions() {
    local file="$1"
    local max_lines="${2:-50}"

    if [ ! -f "$file" ]; then
        echo ""
        return
    fi

    # Get content, skip frontmatter if present
    awk '
        BEGIN { in_frontmatter=0; started=0 }
        /^---$/ && !started { in_frontmatter=!in_frontmatter; next }
        !in_frontmatter { started=1; print }
    ' "$file" | head -"$max_lines"
}

# Extract rules from various formats
extract_rules() {
    local file="$1"
    local rules=()

    if [ ! -f "$file" ]; then
        echo "[]"
        return
    fi

    # Extract bullet points or lines that look like rules
    while IFS= read -r line; do
        # Clean up the line
        line=$(echo "$line" | sed 's/^[[:space:]]*[-*][[:space:]]*//' | sed 's/[[:space:]]*$//')
        # Keep lines that look like rules (not empty, reasonable length)
        if [ -n "$line" ] && [ ${#line} -gt 5 ] && [ ${#line} -lt 500 ]; then
            rules+=("$line")
        fi
    done < <(grep -E '^[[:space:]]*[-*][[:space:]]' "$file" 2>/dev/null | head -30 || true)

    if [ ${#rules[@]} -eq 0 ]; then
        echo "[]"
    else
        printf '%s\n' "${rules[@]}" | jq -R . | jq -s .
    fi
}

# Parse Cursor settings/rules
parse_cursor() {
    local cursor_dir=".cursor"

    if [ ! -d "$cursor_dir" ]; then
        echo "{}"
        return
    fi

    local rules_file=""
    local rules_content="[]"
    local settings_file=""
    local model=""
    local context_files="[]"

    # Check for rules files
    for f in "$cursor_dir/rules" "$cursor_dir/rules.md" "$cursor_dir/.cursorrules"; do
        if [ -f "$f" ]; then
            rules_file="$f"
            rules_content=$(extract_rules "$f")
            break
        fi
    done

    # Also check root .cursorrules
    if [ -z "$rules_file" ] && [ -f ".cursorrules" ]; then
        rules_file=".cursorrules"
        rules_content=$(extract_rules ".cursorrules")
    fi

    # Check for settings
    if [ -f "$cursor_dir/settings.json" ]; then
        settings_file="$cursor_dir/settings.json"
        model=$(jq -r '.model // ""' "$settings_file" 2>/dev/null || echo "")
    fi

    jq -n \
        --arg rules_file "$rules_file" \
        --argjson rules "$rules_content" \
        --arg settings_file "$settings_file" \
        --arg model "$model" \
        '{
            rules_file: $rules_file,
            rules: $rules,
            settings_file: $settings_file,
            model: $model
        } | with_entries(select(.value != "" and .value != []))'
}

# Parse Claude Code config
parse_claude() {
    local claude_dir=".claude"
    local instructions_file=""
    local instructions=""
    local settings_file=""
    local model=""

    # Check for CLAUDE.md in various locations
    for f in "CLAUDE.md" "$claude_dir/CLAUDE.md" "$claude_dir/settings/CLAUDE.md"; do
        if [ -f "$f" ]; then
            instructions_file="$f"
            instructions=$(extract_md_instructions "$f" 30)
            break
        fi
    done

    # Check for settings.json
    if [ -f "$claude_dir/settings.json" ]; then
        settings_file="$claude_dir/settings.json"
        model=$(jq -r '.model // ""' "$settings_file" 2>/dev/null || echo "")
    fi

    # Check for .claude.json in root
    if [ -z "$settings_file" ] && [ -f ".claude.json" ]; then
        settings_file=".claude.json"
        model=$(jq -r '.model // ""' "$settings_file" 2>/dev/null || echo "")
    fi

    jq -n \
        --arg instructions_file "$instructions_file" \
        --arg instructions "$instructions" \
        --arg settings_file "$settings_file" \
        --arg model "$model" \
        '{
            instructions_file: $instructions_file,
            instructions_preview: $instructions,
            settings_file: $settings_file,
            model: $model
        } | with_entries(select(.value != "" and .value != []))'
}

# Parse GitHub Copilot config
parse_copilot() {
    local instructions_file=""
    local instructions=""

    # Check for copilot instructions
    for f in ".github/copilot-instructions.md" "copilot-instructions.md"; do
        if [ -f "$f" ]; then
            instructions_file="$f"
            instructions=$(extract_md_instructions "$f" 30)
            break
        fi
    done

    jq -n \
        --arg instructions_file "$instructions_file" \
        --arg instructions "$instructions" \
        '{
            instructions_file: $instructions_file,
            instructions_preview: $instructions
        } | with_entries(select(.value != ""))'
}

# Parse Windsurf config
parse_windsurf() {
    local windsurf_dir=".windsurf"

    if [ ! -d "$windsurf_dir" ]; then
        echo "{}"
        return
    fi

    local rules_file=""
    local rules_content="[]"

    # Check for rules/instructions
    for f in "$windsurf_dir/rules.md" "$windsurf_dir/instructions.md" "$windsurf_dir/.windsurfrules"; do
        if [ -f "$f" ]; then
            rules_file="$f"
            rules_content=$(extract_rules "$f")
            break
        fi
    done

    jq -n \
        --arg rules_file "$rules_file" \
        --argjson rules "$rules_content" \
        '{
            rules_file: $rules_file,
            rules: $rules
        } | with_entries(select(.value != "" and .value != []))'
}

# Parse Aider config
parse_aider() {
    local config_file=""
    local model=""
    local conventions=""

    # Check for aider config files
    for f in ".aider.conf.yml" ".aider.conf.yaml" ".aider/config.yml"; do
        if [ -f "$f" ]; then
            config_file="$f"
            # Extract model if present
            model=$(grep -E '^model:' "$f" 2>/dev/null | sed 's/model:[[:space:]]*//' | head -1 || echo "")
            break
        fi
    done

    # Check for conventions file
    if [ -f ".aider/CONVENTIONS.md" ]; then
        conventions=".aider/CONVENTIONS.md"
    fi

    jq -n \
        --arg config_file "$config_file" \
        --arg model "$model" \
        --arg conventions "$conventions" \
        '{
            config_file: $config_file,
            model: $model,
            conventions_file: $conventions
        } | with_entries(select(.value != ""))'
}

# Parse Continue config
parse_continue() {
    local continue_dir=".continue"

    if [ ! -d "$continue_dir" ]; then
        echo "{}"
        return
    fi

    local config_file=""
    local models="[]"

    # Check for config files
    for f in "$continue_dir/config.json" "$continue_dir/config.yaml"; do
        if [ -f "$f" ]; then
            config_file="$f"
            if [[ "$f" == *.json ]]; then
                models=$(jq '[.models[]? | .title // .model] // []' "$f" 2>/dev/null || echo "[]")
            fi
            break
        fi
    done

    jq -n \
        --arg config_file "$config_file" \
        --argjson models "$models" \
        '{
            config_file: $config_file,
            configured_models: $models
        } | with_entries(select(.value != "" and .value != []))'
}

# Parse Cody (Sourcegraph) config
parse_cody() {
    local cody_file=""
    local model=""

    # Check for cody config
    for f in ".sourcegraph/cody.json" ".cody/config.json"; do
        if [ -f "$f" ]; then
            cody_file="$f"
            model=$(jq -r '.model // ""' "$f" 2>/dev/null || echo "")
            break
        fi
    done

    jq -n \
        --arg config_file "$cody_file" \
        --arg model "$model" \
        '{
            config_file: $config_file,
            model: $model
        } | with_entries(select(.value != ""))'
}

# Detect which agents are configured
AGENTS=()
{ [ -d ".cursor" ] || [ -f ".cursorrules" ]; } && AGENTS+=("cursor")
{ [ -d ".claude" ] || [ -f "CLAUDE.md" ]; } && AGENTS+=("claude")
{ [ -f ".github/copilot-instructions.md" ] || [ -f "copilot-instructions.md" ]; } && AGENTS+=("copilot")
[ -d ".windsurf" ] && AGENTS+=("windsurf")
{ [ -d ".aider" ] || [ -f ".aider.conf.yml" ] || [ -f ".aider.conf.yaml" ]; } && AGENTS+=("aider")
[ -d ".continue" ] && AGENTS+=("continue")
{ [ -d ".codeium" ]; } && AGENTS+=("codeium")
{ [ -d ".tabnine" ]; } && AGENTS+=("tabnine")
{ [ -d ".sourcegraph" ] || [ -f ".sourcegraph/cody.json" ]; } && AGENTS+=("cody")

# Build agents list JSON
if [ ${#AGENTS[@]} -eq 0 ]; then
    AGENTS_JSON="[]"
else
    AGENTS_JSON=$(printf '%s\n' "${AGENTS[@]}" | jq -R . | jq -s .)
fi

# Extract configs for detected agents
CURSOR_CONFIG=$(parse_cursor)
CLAUDE_CONFIG=$(parse_claude)
COPILOT_CONFIG=$(parse_copilot)
WINDSURF_CONFIG=$(parse_windsurf)
AIDER_CONFIG=$(parse_aider)
CONTINUE_CONFIG=$(parse_continue)
CODY_CONFIG=$(parse_cody)

# Build final JSON output
jq -n \
    --argjson detected "$AGENTS_JSON" \
    --argjson cursor "$CURSOR_CONFIG" \
    --argjson claude "$CLAUDE_CONFIG" \
    --argjson copilot "$COPILOT_CONFIG" \
    --argjson windsurf "$WINDSURF_CONFIG" \
    --argjson aider "$AIDER_CONFIG" \
    --argjson continue_config "$CONTINUE_CONFIG" \
    --argjson cody "$CODY_CONFIG" \
    '{
        detected_agents: $detected,
        cursor: $cursor,
        claude: $claude,
        copilot: $copilot,
        windsurf: $windsurf,
        aider: $aider,
        continue: $continue_config,
        cody: $cody
    }'
