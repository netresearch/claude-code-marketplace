#!/usr/bin/env bash
# Extract information from IDE and editor configuration files
set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# Parse .editorconfig
parse_editorconfig() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "{}"
        return
    fi

    local indent_style=""
    local indent_size=""
    local tab_width=""
    local end_of_line=""
    local charset=""
    local trim_trailing=""
    local insert_final=""
    local max_line_length=""

    # Parse INI-style format (simplified)
    while IFS= read -r line; do
        # Skip comments and section headers
        [[ "$line" =~ ^[[:space:]]*[#\;] ]] && continue
        [[ "$line" =~ ^\[.*\] ]] && continue

        # Parse key=value
        if [[ "$line" =~ ^([a-z_]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"

            case "$key" in
                indent_style) indent_style="$value" ;;
                indent_size) indent_size="$value" ;;
                tab_width) tab_width="$value" ;;
                end_of_line) end_of_line="$value" ;;
                charset) charset="$value" ;;
                trim_trailing_whitespace) trim_trailing="$value" ;;
                insert_final_newline) insert_final="$value" ;;
                max_line_length) max_line_length="$value" ;;
            esac
        fi
    done < "$file"

    jq -n \
        --arg indent_style "$indent_style" \
        --arg indent_size "$indent_size" \
        --arg tab_width "$tab_width" \
        --arg end_of_line "$end_of_line" \
        --arg charset "$charset" \
        --arg trim_trailing "$trim_trailing" \
        --arg insert_final "$insert_final" \
        --arg max_line_length "$max_line_length" \
        '{
            indent_style: $indent_style,
            indent_size: $indent_size,
            tab_width: $tab_width,
            end_of_line: $end_of_line,
            charset: $charset,
            trim_trailing_whitespace: $trim_trailing,
            insert_final_newline: $insert_final,
            max_line_length: $max_line_length
        } | with_entries(select(.value != ""))'
}

# Parse VSCode settings.json
parse_vscode_settings() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "{}"
        return
    fi

    # Extract key settings (remove comments first)
    sed 's|//.*||g' "$file" 2>/dev/null | jq '{
        formatter: (."editor.defaultFormatter" // null),
        format_on_save: (."editor.formatOnSave" // null),
        tab_size: (."editor.tabSize" // null),
        insert_spaces: (."editor.insertSpaces" // null),
        eol: (."files.eol" // null),
        trailing_whitespace: (."files.trimTrailingWhitespace" // null),
        final_newline: (."files.insertFinalNewline" // null),
        rulers: (."editor.rulers" // null),
        python_linting: (."python.linting.enabled" // null),
        python_formatter: (."python.formatting.provider" // null),
        typescript_preferences: (."typescript.preferences.quoteStyle" // null),
        eslint_enable: (."eslint.enable" // null),
        prettier_enable: (."prettier.enable" // null)
    } | with_entries(select(.value != null))' 2>/dev/null || echo "{}"
}

# Parse VSCode extensions.json
parse_vscode_extensions() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "[]"
        return
    fi

    # Extract recommendations
    jq '.recommendations // []' "$file" 2>/dev/null || echo "[]"
}

# Parse VSCode launch.json
parse_vscode_launch() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "[]"
        return
    fi

    # Extract configuration names and types
    jq '[.configurations[] | {name: .name, type: .type, request: .request}]' "$file" 2>/dev/null || echo "[]"
}

# Check for JetBrains IDE settings
parse_jetbrains_settings() {
    local idea_dir="$1"

    if [ ! -d "$idea_dir" ]; then
        echo "{}"
        return
    fi

    local code_style_file=""
    local inspection_profile=""
    local project_settings=()

    # Find code style settings
    if [ -d "$idea_dir/codeStyles" ]; then
        code_style_file=$(find "$idea_dir/codeStyles" -name "*.xml" -type f 2>/dev/null | head -1)
    fi

    # Find inspection profile
    if [ -d "$idea_dir/inspectionProfiles" ]; then
        inspection_profile=$(find "$idea_dir/inspectionProfiles" -name "*.xml" -type f 2>/dev/null | head -1)
    fi

    # Check for common settings files
    [ -f "$idea_dir/misc.xml" ] && project_settings+=("misc.xml")
    [ -f "$idea_dir/modules.xml" ] && project_settings+=("modules.xml")
    [ -f "$idea_dir/vcs.xml" ] && project_settings+=("vcs.xml")
    [ -f "$idea_dir/php.xml" ] && project_settings+=("php.xml")
    [ -f "$idea_dir/jsLibraryMappings.xml" ] && project_settings+=("jsLibraryMappings.xml")

    local settings_json="[]"
    if [ ${#project_settings[@]} -gt 0 ]; then
        settings_json=$(printf '%s\n' "${project_settings[@]}" | jq -R . | jq -s .)
    fi

    jq -n \
        --arg code_style "$code_style_file" \
        --arg inspection "$inspection_profile" \
        --argjson settings "$settings_json" \
        '{
            code_style_file: $code_style,
            inspection_profile: $inspection,
            project_settings: $settings
        } | with_entries(select(.value != "" and .value != []))'
}

# Detect IDEs present
IDES=()
[ -f ".editorconfig" ] && IDES+=("editorconfig")
[ -d ".vscode" ] && IDES+=("vscode")
[ -d ".idea" ] && IDES+=("idea")
[ -d ".phpstorm" ] && IDES+=("phpstorm")
[ -d ".fleet" ] && IDES+=("fleet")
{ [ -d ".vim" ] || [ -f ".vimrc" ]; } && IDES+=("vim")
{ [ -d ".nvim" ] || [ -f ".nvimrc" ]; } && IDES+=("neovim")
[ -f ".sublime-project" ] && IDES+=("sublime")

# Build IDE list JSON
if [ ${#IDES[@]} -eq 0 ]; then
    IDES_JSON="[]"
else
    IDES_JSON=$(printf '%s\n' "${IDES[@]}" | jq -R . | jq -s .)
fi

# Extract specific settings
EDITORCONFIG_SETTINGS="{}"
VSCODE_SETTINGS="{}"
VSCODE_EXTENSIONS="[]"
VSCODE_LAUNCH="[]"
JETBRAINS_SETTINGS="{}"

if [ -f ".editorconfig" ]; then
    EDITORCONFIG_SETTINGS=$(parse_editorconfig ".editorconfig")
fi

if [ -d ".vscode" ]; then
    VSCODE_SETTINGS=$(parse_vscode_settings ".vscode/settings.json")
    VSCODE_EXTENSIONS=$(parse_vscode_extensions ".vscode/extensions.json")
    VSCODE_LAUNCH=$(parse_vscode_launch ".vscode/launch.json")
fi

if [ -d ".idea" ]; then
    JETBRAINS_SETTINGS=$(parse_jetbrains_settings ".idea")
elif [ -d ".phpstorm" ]; then
    JETBRAINS_SETTINGS=$(parse_jetbrains_settings ".phpstorm")
fi

# Build final JSON output
jq -n \
    --argjson ides "$IDES_JSON" \
    --argjson editorconfig "$EDITORCONFIG_SETTINGS" \
    --argjson vscode_settings "$VSCODE_SETTINGS" \
    --argjson vscode_extensions "$VSCODE_EXTENSIONS" \
    --argjson vscode_launch "$VSCODE_LAUNCH" \
    --argjson jetbrains "$JETBRAINS_SETTINGS" \
    '{
        detected_ides: $ides,
        editorconfig: $editorconfig,
        vscode: {
            settings: $vscode_settings,
            recommended_extensions: $vscode_extensions,
            launch_configurations: $vscode_launch
        },
        jetbrains: $jetbrains
    }'
