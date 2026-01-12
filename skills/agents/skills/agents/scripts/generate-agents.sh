#!/usr/bin/env bash
# Main AGENTS.md generator script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$SKILL_DIR/assets"

# Source helper library
source "$SCRIPT_DIR/lib/template.sh"

# Default options
PROJECT_DIR="${1:-.}"
STYLE="${STYLE:-thin}"
DRY_RUN=false
UPDATE_ONLY=false
FORCE=false
VERBOSE=false

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --style=*)
            STYLE="${1#*=}"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --update)
            UPDATE_ONLY=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage: generate-agents.sh [PROJECT_DIR] [OPTIONS]

Generate AGENTS.md files for a project following the public agents.md convention.

Options:
  --style=thin|verbose    Template style (default: thin)
  --dry-run               Preview what will be created
  --update                Update existing files only
  --force                 Force regeneration of existing files
  --verbose, -v           Verbose output
  --help, -h              Show this help message

Examples:
  generate-agents.sh .                    # Generate thin root + scoped files
  generate-agents.sh . --dry-run          # Preview changes
  generate-agents.sh . --style=verbose    # Use verbose root template
  generate-agents.sh . --update           # Update existing files
EOF
            exit 0
            ;;
        *)
            PROJECT_DIR="$1"
            shift
            ;;
    esac
done

cd "$PROJECT_DIR"

log() {
    [ "$VERBOSE" = true ] && echo "[INFO] $*" >&2
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

# Detect project
log "Detecting project type..."
PROJECT_INFO=$("$SCRIPT_DIR/detect-project.sh" "$PROJECT_DIR")
[ "$VERBOSE" = true ] && echo "$PROJECT_INFO" | jq . >&2

LANGUAGE=$(echo "$PROJECT_INFO" | jq -r '.language')
VERSION=$(echo "$PROJECT_INFO" | jq -r '.version')
PROJECT_TYPE=$(echo "$PROJECT_INFO" | jq -r '.type')

[ "$LANGUAGE" = "unknown" ] && error "Could not detect project language"

# Detect scopes
log "Detecting scopes..."
SCOPES_INFO=$("$SCRIPT_DIR/detect-scopes.sh" "$PROJECT_DIR")
[ "$VERBOSE" = true ] && echo "$SCOPES_INFO" | jq . >&2

# Extract commands
log "Extracting build commands..."
COMMANDS=$("$SCRIPT_DIR/extract-commands.sh" "$PROJECT_DIR")
[ "$VERBOSE" = true ] && echo "$COMMANDS" | jq . >&2

# Generate root AGENTS.md
ROOT_FILE="$PROJECT_DIR/AGENTS.md"

if [ -f "$ROOT_FILE" ] && [ "$FORCE" = false ] && [ "$UPDATE_ONLY" = false ]; then
    log "Root AGENTS.md already exists, skipping (use --force to regenerate)"
elif [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] Would create/update: $ROOT_FILE"
else
    log "Generating root AGENTS.md..."

    # Select template
    if [ "$STYLE" = "verbose" ]; then
        TEMPLATE="$TEMPLATE_DIR/root-verbose.md"
    else
        TEMPLATE="$TEMPLATE_DIR/root-thin.md"
    fi

    # Prepare template variables
    declare -A vars
    vars[TIMESTAMP]=$(get_timestamp)
    vars[LANGUAGE_CONVENTIONS]=$(get_language_conventions "$LANGUAGE" "$VERSION")
    vars[TYPECHECK_CMD]=$(echo "$COMMANDS" | jq -r '.typecheck')
    vars[LINT_CMD]=$(echo "$COMMANDS" | jq -r '.lint')
    vars[FORMAT_CMD]=$(echo "$COMMANDS" | jq -r '.format' | sed 's/^/ (file scope): /')
    vars[TEST_CMD]=$(echo "$COMMANDS" | jq -r '.test')
    vars[SCOPE_INDEX]=$(build_scope_index "$SCOPES_INFO")

    # Verbose template additional vars
    if [ "$STYLE" = "verbose" ]; then
        vars[PROJECT_DESCRIPTION]="TODO: Add project description"
        vars[VERSION]="$VERSION"
        vars[BUILD_TOOL]=$(echo "$PROJECT_INFO" | jq -r '.build_tool')
        vars[FRAMEWORK]=$(echo "$PROJECT_INFO" | jq -r '.framework')
        vars[PROJECT_TYPE]="$PROJECT_TYPE"
        vars[BUILD_CMD]=$(echo "$COMMANDS" | jq -r '.build')
        vars[QUALITY_STANDARDS]="TODO: Add quality standards"
        vars[SECURITY_SPECIFIC]="TODO: Add security-specific guidelines"
        vars[TEST_COVERAGE]="40"
        vars[TEST_FAST_CMD]=$(echo "$COMMANDS" | jq -r '.test')
        vars[TEST_FULL_CMD]=$(echo "$COMMANDS" | jq -r '.test')
        vars[ARCHITECTURE_DOC]="./docs/architecture.md"
        vars[API_DOC]="./docs/api.md"
        vars[CONTRIBUTING_DOC]="./CONTRIBUTING.md"
    fi

    # Language-specific conflict resolution
    case "$LANGUAGE" in
        "go")
            vars[LANGUAGE_SPECIFIC_CONFLICT_RESOLUTION]="- For Go-specific patterns, defer to language idioms and standard library conventions"
            ;;
        *)
            vars[LANGUAGE_SPECIFIC_CONFLICT_RESOLUTION]=""
            ;;
    esac

    # Render template
    render_template "$TEMPLATE" "$ROOT_FILE" vars

    echo "✅ Created: $ROOT_FILE"
fi

# Generate scoped AGENTS.md files
SCOPE_COUNT=$(echo "$SCOPES_INFO" | jq '.scopes | length')

if [ "$SCOPE_COUNT" -eq 0 ]; then
    log "No scopes detected (directories with <$MIN_FILES source files)"
else
    log "Generating $SCOPE_COUNT scoped AGENTS.md files..."

    while read -r scope; do
        SCOPE_PATH=$(echo "$scope" | jq -r '.path')
        SCOPE_TYPE=$(echo "$scope" | jq -r '.type')
        SCOPE_FILE="$PROJECT_DIR/$SCOPE_PATH/AGENTS.md"

        if [ -f "$SCOPE_FILE" ] && [ "$FORCE" = false ] && [ "$UPDATE_ONLY" = false ]; then
            log "Scoped AGENTS.md already exists: $SCOPE_PATH, skipping"
            continue
        fi

        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] Would create/update: $SCOPE_FILE"
            continue
        fi

        # Select template based on scope type
        SCOPE_TEMPLATE="$TEMPLATE_DIR/scoped/$SCOPE_TYPE.md"

        if [ ! -f "$SCOPE_TEMPLATE" ]; then
            log "No template for scope type: $SCOPE_TYPE, skipping $SCOPE_PATH"
            continue
        fi

        # Prepare scoped template variables
        declare -A scope_vars
        scope_vars[TIMESTAMP]=$(get_timestamp)
        scope_vars[SCOPE_NAME]=$(basename "$SCOPE_PATH")
        scope_vars[SCOPE_DESCRIPTION]=$(get_scope_description "$SCOPE_TYPE")
        scope_vars[FILE_PATH]="<file>"
        scope_vars[HOUSE_RULES]=""

        # Language-specific variables
        case "$SCOPE_TYPE" in
            "backend-go")
                scope_vars[GO_VERSION]="$VERSION"
                scope_vars[GO_MINOR_VERSION]=$(echo "$VERSION" | cut -d. -f2)
                scope_vars[GO_TOOLS]="golangci-lint, gofmt"
                scope_vars[ENV_VARS]="See .env.example"
                scope_vars[BUILD_CMD]=$(echo "$COMMANDS" | jq -r '.build')
                ;;

            "backend-php")
                scope_vars[PHP_VERSION]="$VERSION"
                FRAMEWORK=$(echo "$PROJECT_INFO" | jq -r '.framework')
                scope_vars[FRAMEWORK]="$FRAMEWORK"
                scope_vars[PHP_EXTENSIONS]="json, mbstring, xml"
                scope_vars[ENV_VARS]="See .env.example"
                scope_vars[PHPSTAN_LEVEL]="10"
                scope_vars[BUILD_CMD]=$(echo "$COMMANDS" | jq -r '.build')

                if [ "$FRAMEWORK" = "typo3" ]; then
                    scope_vars[FRAMEWORK_CONVENTIONS]="- TYPO3-specific: Use dependency injection, follow TYPO3 CGL"
                    scope_vars[FRAMEWORK_DOCS]="- TYPO3 documentation: https://docs.typo3.org"
                else
                    scope_vars[FRAMEWORK_CONVENTIONS]=""
                    scope_vars[FRAMEWORK_DOCS]=""
                fi
                ;;

            "frontend-typescript")
                scope_vars[NODE_VERSION]="$VERSION"
                FRAMEWORK=$(echo "$PROJECT_INFO" | jq -r '.framework')
                scope_vars[FRAMEWORK]="$FRAMEWORK"
                scope_vars[PACKAGE_MANAGER]=$(echo "$PROJECT_INFO" | jq -r '.build_tool')
                scope_vars[ENV_VARS]="See .env.example"
                scope_vars[BUILD_CMD]=$(echo "$COMMANDS" | jq -r '.build')
                scope_vars[DEV_CMD]=$(echo "$COMMANDS" | jq -r '.dev')
                scope_vars[CSS_APPROACH]="CSS Modules"

                case "$FRAMEWORK" in
                    "react")
                        scope_vars[FRAMEWORK_CONVENTIONS]="- Use functional components with hooks\n- Avoid class components"
                        scope_vars[FRAMEWORK_DOCS]="https://react.dev"
                        ;;
                    "next.js")
                        scope_vars[FRAMEWORK_CONVENTIONS]="- Use App Router (app/)\n- Server Components by default"
                        scope_vars[FRAMEWORK_DOCS]="https://nextjs.org/docs"
                        ;;
                    "vue")
                        scope_vars[FRAMEWORK_CONVENTIONS]="- Use Composition API\n- Avoid Options API for new code"
                        scope_vars[FRAMEWORK_DOCS]="https://vuejs.org/guide"
                        ;;
                    *)
                        scope_vars[FRAMEWORK_CONVENTIONS]=""
                        scope_vars[FRAMEWORK_DOCS]=""
                        ;;
                esac
                ;;

            "cli")
                scope_vars[LANGUAGE]="$LANGUAGE"
                CLI_FRAMEWORK="standard"
                [ -f "go.mod" ] && grep -q "github.com/spf13/cobra" go.mod 2>/dev/null && CLI_FRAMEWORK="cobra"
                [ -f "go.mod" ] && grep -q "github.com/urfave/cli" go.mod 2>/dev/null && CLI_FRAMEWORK="urfave/cli"
                scope_vars[CLI_FRAMEWORK]="$CLI_FRAMEWORK"
                scope_vars[BUILD_OUTPUT_PATH]="./bin/"
                scope_vars[SETUP_INSTRUCTIONS]="- Build: $(echo "$COMMANDS" | jq -r '.build')"
                scope_vars[BUILD_CMD]=$(echo "$COMMANDS" | jq -r '.build')
                scope_vars[RUN_CMD]="./bin/$(basename "$PROJECT_DIR")"
                scope_vars[TEST_CMD]=$(echo "$COMMANDS" | jq -r '.test')
                scope_vars[LINT_CMD]=$(echo "$COMMANDS" | jq -r '.lint')
                ;;
        esac

        # Render template
        render_template "$SCOPE_TEMPLATE" "$SCOPE_FILE" scope_vars

        echo "✅ Created: $SCOPE_FILE"

    done < <(echo "$SCOPES_INFO" | jq -c '.scopes[]')
fi

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "[DRY-RUN] No files were modified. Remove --dry-run to apply changes."
fi

echo ""
echo "✅ AGENTS.md generation complete!"
[ "$SCOPE_COUNT" -gt 0 ] && echo "   Generated: 1 root + $SCOPE_COUNT scoped files"
