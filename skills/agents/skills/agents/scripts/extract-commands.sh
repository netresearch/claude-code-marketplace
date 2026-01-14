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
    [ ! -f "Makefile" ] && return 0

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
    [ ! -f "package.json" ] && return 0

    local has_typecheck has_lint has_format has_test has_build has_dev
    has_typecheck=$(jq -r '.scripts.typecheck // .scripts["type-check"] // empty' package.json 2>/dev/null)
    has_lint=$(jq -r '.scripts.lint // empty' package.json 2>/dev/null)
    has_format=$(jq -r '.scripts.format // empty' package.json 2>/dev/null)
    has_test=$(jq -r '.scripts.test // empty' package.json 2>/dev/null)
    has_build=$(jq -r '.scripts.build // empty' package.json 2>/dev/null)
    has_dev=$(jq -r '.scripts.dev // .scripts.start // empty' package.json 2>/dev/null)

    if [ -n "$has_typecheck" ]; then
        TYPECHECK_CMD="npm run typecheck"
    else
        TYPECHECK_CMD="npx tsc --noEmit"
    fi

    if [ -n "$has_lint" ]; then
        LINT_CMD="npm run lint"
    else
        LINT_CMD="npx eslint ."
    fi

    if [ -n "$has_format" ]; then
        FORMAT_CMD="npm run format"
    else
        FORMAT_CMD="npx prettier --write ."
    fi

    if [ -n "$has_test" ]; then
        TEST_CMD="npm test"
    fi

    if [ -n "$has_build" ]; then
        BUILD_CMD="npm run build"
    fi

    if [ -n "$has_dev" ]; then
        DEV_CMD="npm run dev"
    fi
}

# Extract from composer.json
extract_from_composer_json() {
    [ ! -f "composer.json" ] && return 0

    local has_lint has_format has_test has_phpstan
    has_lint=$(jq -r '.scripts.lint // .scripts["cs:check"] // empty' composer.json 2>/dev/null)
    has_format=$(jq -r '.scripts.format // .scripts["cs:fix"] // empty' composer.json 2>/dev/null)
    has_test=$(jq -r '.scripts.test // empty' composer.json 2>/dev/null)
    has_phpstan=$(jq -r '.scripts.phpstan // .scripts["stan"] // empty' composer.json 2>/dev/null)

    if [ -n "$has_lint" ]; then
        LINT_CMD="composer run lint"
    fi

    if [ -n "$has_format" ]; then
        FORMAT_CMD="composer run format"
    fi

    if [ -n "$has_test" ]; then
        TEST_CMD="composer run test"
    else
        TEST_CMD="vendor/bin/phpunit"
    fi

    if [ -n "$has_phpstan" ]; then
        TYPECHECK_CMD="composer run phpstan"
    elif [ -f "phpstan.neon" ] || [ -f "Build/phpstan.neon" ]; then
        TYPECHECK_CMD="vendor/bin/phpstan analyze"
    fi
}

# Extract from pyproject.toml
extract_from_pyproject() {
    [ ! -f "pyproject.toml" ] && return 0

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
            : "${TYPECHECK_CMD:=go build -v ./...}"
            if [ -z "$LINT_CMD" ]; then
                if [ -f ".golangci.yml" ] || [ -f ".golangci.yaml" ]; then
                    LINT_CMD="golangci-lint run ./..."
                fi
            fi
            : "${FORMAT_CMD:=gofmt -w .}"
            : "${TEST_CMD:=go test -v -race -short ./...}"
            : "${BUILD_CMD:=go build -v ./...}"
            ;;

        "php")
            if [ -z "$TYPECHECK_CMD" ]; then
                if [ -f "phpstan.neon" ] || [ -f "Build/phpstan.neon" ]; then
                    TYPECHECK_CMD="vendor/bin/phpstan analyze"
                fi
            fi
            : "${LINT_CMD:=vendor/bin/php-cs-fixer fix --dry-run}"
            : "${FORMAT_CMD:=vendor/bin/php-cs-fixer fix}"
            : "${TEST_CMD:=vendor/bin/phpunit}"
            ;;

        "typescript")
            : "${TYPECHECK_CMD:=npx tsc --noEmit}"
            : "${LINT_CMD:=npx eslint .}"
            : "${FORMAT_CMD:=npx prettier --write .}"
            if [ -z "$TEST_CMD" ]; then
                if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ]; then
                    TEST_CMD="npm test"
                elif grep -q 'vitest' package.json 2>/dev/null; then
                    TEST_CMD="npx vitest"
                fi
            fi
            ;;

        "python")
            : "${LINT_CMD:=ruff check .}"
            : "${FORMAT_CMD:=ruff format .}"
            : "${TYPECHECK_CMD:=mypy .}"
            : "${TEST_CMD:=pytest}"
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
