#!/usr/bin/env bash
# Detect directories that should have scoped AGENTS.md files
set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

MIN_FILES=5  # Minimum files to warrant scoped AGENTS.md

# Get project info
PROJECT_INFO=$(bash "$(dirname "$0")/detect-project.sh" "$PROJECT_DIR")
LANGUAGE=$(echo "$PROJECT_INFO" | jq -r '.language')

scopes=()

# Function to count source files in a directory
count_source_files() {
    local dir="$1"
    local pattern="$2"
    find "$dir" -maxdepth 3 -type f -name "$pattern" 2>/dev/null | wc -l
}

# Function to add scope
add_scope() {
    local path="$1"
    local type="$2"
    local count="$3"

    scopes+=("{\"path\": \"$path\", \"type\": \"$type\", \"files\": $count}")
}

# Language-specific scope detection
case "$LANGUAGE" in
    "go")
        # Check common Go directories
        [ -d "internal" ] && {
            count=$(count_source_files "internal" "*.go")
            [ "$count" -ge "$MIN_FILES" ] && add_scope "internal" "backend-go" "$count"
        }

        [ -d "pkg" ] && {
            count=$(count_source_files "pkg" "*.go")
            [ "$count" -ge "$MIN_FILES" ] && add_scope "pkg" "backend-go" "$count"
        }

        [ -d "cmd" ] && {
            count=$(count_source_files "cmd" "*.go")
            [ "$count" -ge 3 ] && add_scope "cmd" "cli" "$count"
        }

        [ -d "examples" ] && {
            count=$(count_source_files "examples" "*.go")
            [ "$count" -ge 3 ] && add_scope "examples" "examples" "$count"
        }

        [ -d "testutil" ] && {
            count=$(count_source_files "testutil" "*.go")
            [ "$count" -ge 3 ] && add_scope "testutil" "testing" "$count"
        }

        [ -d "docs" ] && {
            count=$(find docs -type f \( -name "*.md" -o -name "*.rst" \) | wc -l)
            [ "$count" -ge 3 ] && add_scope "docs" "documentation" "$count"
        }
        ;;

    "php")
        # Check common PHP directories
        [ -d "Classes" ] && {
            count=$(count_source_files "Classes" "*.php")
            [ "$count" -ge "$MIN_FILES" ] && add_scope "Classes" "backend-php" "$count"
        }

        [ -d "src" ] && {
            count=$(count_source_files "src" "*.php")
            [ "$count" -ge "$MIN_FILES" ] && add_scope "src" "backend-php" "$count"
        }

        [ -d "Tests" ] && {
            count=$(count_source_files "Tests" "*.php")
            [ "$count" -ge 3 ] && add_scope "Tests" "testing" "$count"
        }

        [ -d "tests" ] && {
            count=$(count_source_files "tests" "*.php")
            [ "$count" -ge 3 ] && add_scope "tests" "testing" "$count"
        }

        [ -d "Documentation" ] && {
            count=$(find Documentation -type f \( -name "*.rst" -o -name "*.md" \) | wc -l)
            [ "$count" -ge 3 ] && add_scope "Documentation" "documentation" "$count"
        }

        [ -d "Resources" ] && {
            count=$(find Resources -type f | wc -l)
            [ "$count" -ge 5 ] && add_scope "Resources" "resources" "$count"
        }
        ;;

    "typescript")
        # Check common TypeScript/JavaScript directories
        [ -d "src" ] && {
            count=$(count_source_files "src" "*.ts")
            ts_count=$count
            count=$(count_source_files "src" "*.tsx")
            tsx_count=$count

            if [ "$tsx_count" -ge "$MIN_FILES" ]; then
                add_scope "src" "frontend-typescript" "$tsx_count"
            elif [ "$ts_count" -ge "$MIN_FILES" ]; then
                add_scope "src" "backend-typescript" "$ts_count"
            fi
        }

        [ -d "components" ] && {
            count=$(count_source_files "components" "*.tsx")
            [ "$count" -ge "$MIN_FILES" ] && add_scope "components" "frontend-typescript" "$count"
        }

        [ -d "pages" ] && {
            count=$(count_source_files "pages" "*.tsx")
            [ "$count" -ge 3 ] && add_scope "pages" "frontend-typescript" "$count"
        }

        [ -d "app" ] && {
            count=$(count_source_files "app" "*.tsx")
            [ "$count" -ge 3 ] && add_scope "app" "frontend-typescript" "$count"
        }

        [ -d "server" ] || [ -d "backend" ] && {
            dir=$([ -d "server" ] && echo "server" || echo "backend")
            count=$(count_source_files "$dir" "*.ts")
            [ "$count" -ge "$MIN_FILES" ] && add_scope "$dir" "backend-typescript" "$count"
        }

        [ -d "__tests__" ] || [ -d "tests" ] && {
            dir=$([ -d "__tests__" ] && echo "__tests__" || echo "tests")
            count=$(count_source_files "$dir" "*.test.ts")
            [ "$count" -ge 3 ] && add_scope "$dir" "testing" "$count"
        }
        ;;

    "python")
        # Check common Python directories
        [ -d "src" ] && {
            count=$(count_source_files "src" "*.py")
            [ "$count" -ge "$MIN_FILES" ] && add_scope "src" "backend-python" "$count"
        }

        [ -d "tests" ] && {
            count=$(count_source_files "tests" "*.py")
            [ "$count" -ge 3 ] && add_scope "tests" "testing" "$count"
        }

        [ -d "scripts" ] && {
            count=$(count_source_files "scripts" "*.py")
            [ "$count" -ge 3 ] && add_scope "scripts" "cli" "$count"
        }

        [ -d "docs" ] && {
            count=$(find docs -type f \( -name "*.md" -o -name "*.rst" \) | wc -l)
            [ "$count" -ge 3 ] && add_scope "docs" "documentation" "$count"
        }
        ;;
esac

# Check for web subdirectories (cross-language)
if [ -d "internal/web" ]; then
    count=$(find internal/web -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) | wc -l)
    [ "$count" -ge "$MIN_FILES" ] && add_scope "internal/web" "frontend-typescript" "$count"
fi

# Output JSON
if [ ${#scopes[@]} -eq 0 ]; then
    echo '{"scopes": []}'
else
    echo "{\"scopes\": [$(IFS=,; echo "${scopes[*]}")]}"
fi
