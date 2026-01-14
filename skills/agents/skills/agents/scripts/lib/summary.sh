#!/usr/bin/env bash
# Summary output formatting helpers

# Colors (only if terminal supports it)
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    GRAY='\033[0;90m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    GRAY=''
    BOLD=''
    NC=''
fi

# Summary data storage
declare -A SUMMARY_SOURCES
declare -a SUMMARY_RULES
declare -a SUMMARY_WARNINGS

# Initialize summary
init_summary() {
    SUMMARY_SOURCES=()
    SUMMARY_RULES=()
    SUMMARY_WARNINGS=()
}

# Record a detected value with its source
# Usage: record_detection "category" "value" "source_file" "source_detail"
record_detection() {
    local category="$1"
    local value="$2"
    local source_file="$3"
    local source_detail="${4:-}"

    if [[ -n "$source_detail" ]]; then
        SUMMARY_SOURCES["$category"]="$value (from $source_file: $source_detail)"
    else
        SUMMARY_SOURCES["$category"]="$value (from $source_file)"
    fi
}

# Record an extracted rule
# Usage: record_rule "rule_type" "rule_value" "source"
record_rule() {
    local rule_type="$1"
    local rule_value="$2"
    local source="$3"

    SUMMARY_RULES+=("$rule_type: $rule_value [$source]")
}

# Record a warning
# Usage: record_warning "message"
record_warning() {
    local message="$1"
    SUMMARY_WARNINGS+=("$message")
}

# Print the extraction summary
print_summary() {
    local project_info="$1"
    local scopes_info="$2"
    local commands_info="$3"
    local docs_info="${4:-{}}"
    local platform_info="${5:-{}}"
    local ide_info="${6:-{}}"
    local agent_info="${7:-{}}"

    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                    EXTRACTION SUMMARY                          ${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Project Detection
    echo -e "${CYAN}▸ Project Detection${NC}"
    echo -e "  ${GRAY}────────────────────────────────────────${NC}"

    local lang=$(echo "$project_info" | jq -r '.language')
    local version=$(echo "$project_info" | jq -r '.version')
    local ptype=$(echo "$project_info" | jq -r '.type')
    local framework=$(echo "$project_info" | jq -r '.framework')
    local build_tool=$(echo "$project_info" | jq -r '.build_tool')
    local test_fw=$(echo "$project_info" | jq -r '.test_framework')
    local ci=$(echo "$project_info" | jq -r '.ci')
    local docker=$(echo "$project_info" | jq -r '.has_docker')

    # Determine source file
    local lang_source=""
    case "$lang" in
        go) lang_source="go.mod" ;;
        php) lang_source="composer.json" ;;
        typescript) lang_source="package.json" ;;
        python) lang_source="pyproject.toml" ;;
    esac

    printf "  %-16s ${GREEN}%s${NC} ${GRAY}(from %s)${NC}\n" "Language:" "$lang" "$lang_source"
    [[ "$version" != "unknown" ]] && printf "  %-16s ${GREEN}%s${NC}\n" "Version:" "$version"
    [[ "$ptype" != "unknown" ]] && printf "  %-16s %s\n" "Project type:" "$ptype"
    [[ "$framework" != "none" ]] && printf "  %-16s %s\n" "Framework:" "$framework"
    printf "  %-16s %s\n" "Build tool:" "$build_tool"
    [[ "$test_fw" != "unknown" ]] && printf "  %-16s %s\n" "Test framework:" "$test_fw"
    [[ "$ci" != "none" ]] && printf "  %-16s %s\n" "CI/CD:" "$ci"
    [[ "$docker" == "true" ]] && printf "  %-16s %s\n" "Docker:" "yes"

    # Quality Tools
    local tools=$(echo "$project_info" | jq -r '.quality_tools | join(", ")')
    if [[ -n "$tools" && "$tools" != "" ]]; then
        echo ""
        echo -e "${CYAN}▸ Quality Tools Detected${NC}"
        echo -e "  ${GRAY}────────────────────────────────────────${NC}"
        printf "  %s\n" "$tools"
    fi

    # IDE Configs (from ide_info)
    local detected_ides=$(echo "$ide_info" | jq -r '.detected_ides | join(", ")' 2>/dev/null || echo "")
    if [[ -n "$detected_ides" && "$detected_ides" != "" ]]; then
        echo ""
        echo -e "${CYAN}▸ IDE Configurations${NC}"
        echo -e "  ${GRAY}────────────────────────────────────────${NC}"
        printf "  %s\n" "$detected_ides"

        # Show editorconfig details if present
        local indent=$(echo "$ide_info" | jq -r '.editorconfig.indent_style // ""' 2>/dev/null || echo "")
        if [[ -n "$indent" ]]; then
            local indent_size=$(echo "$ide_info" | jq -r '.editorconfig.indent_size // ""' 2>/dev/null || echo "")
            printf "  ${GRAY}→ indent: %s (%s)${NC}\n" "$indent" "$indent_size"
        fi
    fi

    # AI Agent Configs (from agent_info)
    local detected_agents=$(echo "$agent_info" | jq -r '.detected_agents | join(", ")' 2>/dev/null || echo "")
    if [[ -n "$detected_agents" && "$detected_agents" != "" ]]; then
        echo ""
        echo -e "${CYAN}▸ AI Agent Configurations${NC}"
        echo -e "  ${GRAY}────────────────────────────────────────${NC}"
        printf "  %s\n" "$detected_agents"
    fi

    # Documentation Files (from docs_info)
    local has_contributing=$(echo "$docs_info" | jq -r '.contributing.file // ""' 2>/dev/null || echo "")
    local has_security=$(echo "$docs_info" | jq -r '.security.file // ""' 2>/dev/null || echo "")
    local has_changelog=$(echo "$docs_info" | jq -r '.changelog.file // ""' 2>/dev/null || echo "")
    local has_coc=$(echo "$docs_info" | jq -r '.code_of_conduct.exists // false' 2>/dev/null || echo "false")

    if [[ -n "$has_contributing" || -n "$has_security" || -n "$has_changelog" || "$has_coc" == "true" ]]; then
        echo ""
        echo -e "${CYAN}▸ Documentation Files${NC}"
        echo -e "  ${GRAY}────────────────────────────────────────${NC}"
        [[ -n "$has_contributing" ]] && printf "  ✓ %s\n" "$has_contributing"
        [[ -n "$has_security" ]] && printf "  ✓ %s\n" "$has_security"
        [[ -n "$has_changelog" ]] && printf "  ✓ %s\n" "$has_changelog"
        [[ "$has_coc" == "true" ]] && printf "  ✓ CODE_OF_CONDUCT.md\n"
    fi

    # Platform Files (from platform_info)
    local platform=$(echo "$platform_info" | jq -r '.platform // "none"' 2>/dev/null || echo "none")
    if [[ "$platform" != "none" ]]; then
        local pr_template=$(echo "$platform_info" | jq -r '.pull_request.template_file // ""' 2>/dev/null || echo "")
        local codeowners=$(echo "$platform_info" | jq -r '.codeowners.file // ""' 2>/dev/null || echo "")
        local dependabot=$(echo "$platform_info" | jq -r '.dependency_updates.dependabot.file // ""' 2>/dev/null || echo "")

        if [[ -n "$pr_template" || -n "$codeowners" || -n "$dependabot" ]]; then
            echo ""
            echo -e "${CYAN}▸ Platform Files (${platform})${NC}"
            echo -e "  ${GRAY}────────────────────────────────────────${NC}"
            [[ -n "$pr_template" ]] && printf "  ✓ PR template: %s\n" "$pr_template"
            [[ -n "$codeowners" ]] && printf "  ✓ CODEOWNERS: %s\n" "$codeowners"
            [[ -n "$dependabot" ]] && printf "  ✓ Dependabot: %s\n" "$dependabot"
        fi
    fi

    # Commands Extracted
    echo ""
    echo -e "${CYAN}▸ Commands Extracted${NC}"
    echo -e "  ${GRAY}────────────────────────────────────────${NC}"

    local typecheck=$(echo "$commands_info" | jq -r '.typecheck')
    local lint=$(echo "$commands_info" | jq -r '.lint')
    local format=$(echo "$commands_info" | jq -r '.format')
    local test_cmd=$(echo "$commands_info" | jq -r '.test')
    local build=$(echo "$commands_info" | jq -r '.build')
    local dev=$(echo "$commands_info" | jq -r '.dev')

    [[ -n "$typecheck" && "$typecheck" != "" ]] && printf "  %-12s ${YELLOW}%s${NC}\n" "typecheck:" "$typecheck"
    [[ -n "$lint" && "$lint" != "" ]] && printf "  %-12s ${YELLOW}%s${NC}\n" "lint:" "$lint"
    [[ -n "$format" && "$format" != "" ]] && printf "  %-12s ${YELLOW}%s${NC}\n" "format:" "$format"
    [[ -n "$test_cmd" && "$test_cmd" != "" ]] && printf "  %-12s ${YELLOW}%s${NC}\n" "test:" "$test_cmd"
    [[ -n "$build" && "$build" != "" ]] && printf "  %-12s ${YELLOW}%s${NC}\n" "build:" "$build"
    [[ -n "$dev" && "$dev" != "" ]] && printf "  %-12s ${YELLOW}%s${NC}\n" "dev:" "$dev"

    # Scopes Detected
    local scope_count=$(echo "$scopes_info" | jq '.scopes | length')
    if [[ "$scope_count" -gt 0 ]]; then
        echo ""
        echo -e "${CYAN}▸ Scopes Detected ($scope_count)${NC}"
        echo -e "  ${GRAY}────────────────────────────────────────${NC}"

        echo "$scopes_info" | jq -r '.scopes[] | "  \(.path)/ (\(.files) files) → \(.type)"'
    fi

    # Files to Generate
    echo ""
    echo -e "${CYAN}▸ Files to Generate${NC}"
    echo -e "  ${GRAY}────────────────────────────────────────${NC}"
    echo "  AGENTS.md (root)"
    if [[ "$scope_count" -gt 0 ]]; then
        echo "$scopes_info" | jq -r '.scopes[] | "  \(.path)/AGENTS.md"'
    fi

    # Warnings
    if [[ ${#SUMMARY_WARNINGS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}▸ Warnings${NC}"
        echo -e "  ${GRAY}────────────────────────────────────────${NC}"
        for warning in "${SUMMARY_WARNINGS[@]}"; do
            echo -e "  ${YELLOW}⚠${NC}  $warning"
        done
    fi

    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Print a compact summary (for non-verbose mode)
print_compact_summary() {
    local project_info="$1"
    local scopes_info="$2"

    local lang=$(echo "$project_info" | jq -r '.language')
    local ptype=$(echo "$project_info" | jq -r '.type')
    local scope_count=$(echo "$scopes_info" | jq '.scopes | length')

    echo "Detected: $lang ($ptype), $((scope_count + 1)) AGENTS.md file(s) to generate"
}
