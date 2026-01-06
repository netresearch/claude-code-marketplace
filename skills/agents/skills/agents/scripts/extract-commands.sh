#!/usr/bin/env bash
# Extract build commands from various build tool files
set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# Get project info
PROJECT_INFO=$(bash "$(dirname "$0")/detect-project.sh" "$PROJECT_DIR")
LANGUAGE=$(echo "$PROJECT_INFO" | jq -r '.language')
BUILD_TOOL=$(echo "$PROJECT_INFO" | jq -r '.build_tool')

# Initialize command variables
TYPECHECK_CMD=""
LINT_CMD=""
FORMAT_CMD=""
TEST_CMD=""
BUILD_CMD=""
DEV_CMD=""

# Extract from Makefile
extract_from_makefile() {
    [ ! -f "Makefile" ] && return

    # Extract targets with ## comments
    while IFS= read -r line; do
        if [[ $line =~ ^([a-zA-Z_-]+):.*\#\#(.*)$ ]]; then
            target="${BASH_REMATCH[1]}"
            description="${BASH_REMATCH[2]}"

            case "$target" in
                lint|check) LINT_CMD="make $target" ;;
                format|fmt) FORMAT_CMD="make $target" ;;
                test|tests) TEST_CMD="make $target" ;;
                build) BUILD_CMD="make $target" ;;
                typecheck|types) TYPECHECK_CMD="make $target" ;;
                dev|serve) DEV_CMD="make $target" ;;
            esac
        fi
    done < Makefile
}

# Extract from package.json
extract_from_package_json() {
    [ ! -f "package.json" ] && return

    TYPECHECK_CMD=$(jq -r '.scripts.typecheck // .scripts["type-check"] // empty' package.json 2>/dev/null)
    [ -n "$TYPECHECK_CMD" ] && TYPECHECK_CMD="npm run typecheck" || TYPECHECK_CMD="npx tsc --noEmit"

    LINT_CMD=$(jq -r '.scripts.lint // empty' package.json 2>/dev/null)
    [ -n "$LINT_CMD" ] && LINT_CMD="npm run lint" || LINT_CMD="npx eslint ."

    FORMAT_CMD=$(jq -r '.scripts.format // empty' package.json 2>/dev/null)
    [ -n "$FORMAT_CMD" ] && FORMAT_CMD="npm run format" || FORMAT_CMD="npx prettier --write ."

    TEST_CMD=$(jq -r '.scripts.test // empty' package.json 2>/dev/null)
    [ -n "$TEST_CMD" ] && TEST_CMD="npm test"

    BUILD_CMD=$(jq -r '.scripts.build // empty' package.json 2>/dev/null)
    [ -n "$BUILD_CMD" ] && BUILD_CMD="npm run build"

    DEV_CMD=$(jq -r '.scripts.dev // .scripts.start // empty' package.json 2>/dev/null)
    [ -n "$DEV_CMD" ] && DEV_CMD="npm run dev"
}

# Extract from composer.json
extract_from_composer_json() {
    [ ! -f "composer.json" ] && return

    LINT_CMD=$(jq -r '.scripts.lint // .scripts["cs:check"] // empty' composer.json 2>/dev/null)
    [ -n "$LINT_CMD" ] && LINT_CMD="composer run lint"

    FORMAT_CMD=$(jq -r '.scripts.format // .scripts["cs:fix"] // empty' composer.json 2>/dev/null)
    [ -n "$FORMAT_CMD" ] && FORMAT_CMD="composer run format"

    TEST_CMD=$(jq -r '.scripts.test // empty' composer.json 2>/dev/null)
    [ -n "$TEST_CMD" ] && TEST_CMD="composer run test" || TEST_CMD="vendor/bin/phpunit"

    TYPECHECK_CMD=$(jq -r '.scripts.phpstan // .scripts["stan"] // empty' composer.json 2>/dev/null)
    [ -n "$TYPECHECK_CMD" ] && TYPECHECK_CMD="composer run phpstan" || {
        if [ -f "phpstan.neon" ] || [ -f "Build/phpstan.neon" ]; then
            TYPECHECK_CMD="vendor/bin/phpstan analyze"
        fi
    }
}

# Extract from pyproject.toml
extract_from_pyproject() {
    [ ! -f "pyproject.toml" ] && return

    # Check for ruff
    if grep -q '\[tool.ruff\]' pyproject.toml; then
        LINT_CMD="ruff check ."
        FORMAT_CMD="ruff format ."
    fi

    # Check for black
    if grep -q 'black' pyproject.toml; then
        FORMAT_CMD="black ."
    fi

    # Check for mypy
    if grep -q 'mypy' pyproject.toml; then
        TYPECHECK_CMD="mypy ."
    fi

    # Check for pytest
    if grep -q 'pytest' pyproject.toml; then
        TEST_CMD="pytest"
    fi
}

# Language-specific defaults
set_language_defaults() {
    case "$LANGUAGE" in
        "go")
            [ -z "$TYPECHECK_CMD" ] && TYPECHECK_CMD="go build -v ./..."
            [ -z "$LINT_CMD" ] && {
                if [ -f ".golangci.yml" ] || [ -f ".golangci.yaml" ]; then
                    LINT_CMD="golangci-lint run ./..."
                fi
            }
            [ -z "$FORMAT_CMD" ] && FORMAT_CMD="gofmt -w ."
            [ -z "$TEST_CMD" ] && TEST_CMD="go test -v -race -short ./..."
            [ -z "$BUILD_CMD" ] && BUILD_CMD="go build -v ./..."
            ;;

        "php")
            [ -z "$TYPECHECK_CMD" ] && {
                if [ -f "phpstan.neon" ] || [ -f "Build/phpstan.neon" ]; then
                    TYPECHECK_CMD="vendor/bin/phpstan analyze"
                fi
            }
            [ -z "$LINT_CMD" ] && LINT_CMD="vendor/bin/php-cs-fixer fix --dry-run"
            [ -z "$FORMAT_CMD" ] && FORMAT_CMD="vendor/bin/php-cs-fixer fix"
            [ -z "$TEST_CMD" ] && TEST_CMD="vendor/bin/phpunit"
            ;;

        "typescript")
            [ -z "$TYPECHECK_CMD" ] && TYPECHECK_CMD="npx tsc --noEmit"
            [ -z "$LINT_CMD" ] && LINT_CMD="npx eslint ."
            [ -z "$FORMAT_CMD" ] && FORMAT_CMD="npx prettier --write ."
            [ -z "$TEST_CMD" ] && {
                if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ]; then
                    TEST_CMD="npm test"
                elif grep -q 'vitest' package.json 2>/dev/null; then
                    TEST_CMD="npx vitest"
                fi
            }
            ;;

        "python")
            [ -z "$LINT_CMD" ] && LINT_CMD="ruff check ."
            [ -z "$FORMAT_CMD" ] && FORMAT_CMD="ruff format ."
            [ -z "$TYPECHECK_CMD" ] && TYPECHECK_CMD="mypy ."
            [ -z "$TEST_CMD" ] && TEST_CMD="pytest"
            ;;
    esac
}

# Run extraction
extract_from_makefile
extract_from_package_json
extract_from_composer_json
extract_from_pyproject
set_language_defaults

# Output JSON
jq -n \
    --arg typecheck "$TYPECHECK_CMD" \
    --arg lint "$LINT_CMD" \
    --arg format "$FORMAT_CMD" \
    --arg test "$TEST_CMD" \
    --arg build "$BUILD_CMD" \
    --arg dev "$DEV_CMD" \
    '{
        typecheck: $typecheck,
        lint: $lint,
        format: $format,
        test: $test,
        build: $build,
        dev: $dev
    }'
