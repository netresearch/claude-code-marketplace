#!/usr/bin/env bash
# Template rendering helper functions

# Render template with placeholder replacement
# Supports multi-line values using bash string replacement
render_template() {
    local template_file="$1"
    local output_file="$2"
    local -n template_vars=$3

    local content
    content=$(cat "$template_file")

    # Replace all placeholders using bash parameter expansion
    # This handles multi-line values correctly
    for key in "${!template_vars[@]}"; do
        local value="${template_vars[$key]}"
        content="${content//"{{$key}}"/$value}"
    done

    # Write output
    printf '%s\n' "$content" > "$output_file"
}

# Generate timestamp
get_timestamp() {
    date +%Y-%m-%d
}

# Build scope index for root template
build_scope_index() {
    local scopes_json="$1"
    local index=""

    local count=$(echo "$scopes_json" | jq '.scopes | length')
    if [ "$count" -eq 0 ]; then
        echo "- (No scoped AGENTS.md files yet)"
        return
    fi

    while read -r scope; do
        local path=$(echo "$scope" | jq -r '.path')
        local type=$(echo "$scope" | jq -r '.type')
        local description=$(get_scope_description "$type")

        index="$index- \`./$path/AGENTS.md\` — $description\n"
    done < <(echo "$scopes_json" | jq -c '.scopes[]')

    echo -e "$index"
}

# Get description for scope type
get_scope_description() {
    local type="$1"

    case "$type" in
        "backend-go") echo "Backend services (Go)" ;;
        "backend-php") echo "Backend services (PHP)" ;;
        "backend-typescript") echo "Backend services (TypeScript/Node.js)" ;;
        "backend-python") echo "Backend services (Python)" ;;
        "frontend-typescript") echo "Frontend application (TypeScript/React/Vue)" ;;
        "cli") echo "Command-line interface tools" ;;
        "testing") echo "Test suites and testing utilities" ;;
        "documentation") echo "Documentation and guides" ;;
        "examples") echo "Example applications and usage patterns" ;;
        "resources") echo "Static resources and assets" ;;
        *) echo "$type" ;;
    esac
}

# Get language-specific conventions text
get_language_conventions() {
    local language="$1"
    local version="$2"

    case "$language" in
        "go")
            echo "- Follow Go $version conventions and idioms"
            ;;
        "php")
            echo "- Follow PSR-12 coding standards and PHP $version features"
            ;;
        "typescript")
            echo "- Use TypeScript strict mode with proper type annotations"
            ;;
        "python")
            echo "- Follow PEP 8 style guide and Python $version features"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Format command with fallback text
format_command() {
    local cmd="$1"
    local fallback="$2"

    if [ -n "$cmd" ] && [ "$cmd" != "null" ]; then
        echo "$cmd"
    else
        echo "$fallback"
    fi
}
