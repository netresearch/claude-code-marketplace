#!/usr/bin/env bash
# Detect project type, language, version, and build tools
set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# Initialize variables
LANGUAGE="unknown"
VERSION="unknown"
BUILD_TOOL="unknown"
FRAMEWORK="none"
PROJECT_TYPE="unknown"
QUALITY_TOOLS=()
TEST_FRAMEWORK="unknown"
HAS_DOCKER=false
CI="none"
IDE_CONFIGS=()
AGENT_CONFIGS=()

# Detect language and version
detect_language() {
    if [ -f "go.mod" ]; then
        LANGUAGE="go"
        VERSION=$(grep '^go ' go.mod | awk '{print $2}' || echo "unknown")
        BUILD_TOOL="go"
        TEST_FRAMEWORK="testing"

        # Detect Go project type
        if [ -d "cmd" ]; then
            PROJECT_TYPE="go-cli"
        elif grep -q "github.com/gofiber/fiber" go.mod 2>/dev/null; then
            PROJECT_TYPE="go-web-app"
            FRAMEWORK="fiber"
        elif grep -q "github.com/labstack/echo" go.mod 2>/dev/null; then
            PROJECT_TYPE="go-web-app"
            FRAMEWORK="echo"
        elif grep -q "github.com/gin-gonic/gin" go.mod 2>/dev/null; then
            PROJECT_TYPE="go-web-app"
            FRAMEWORK="gin"
        else
            PROJECT_TYPE="go-library"
        fi

        # Detect Go quality tools
        { [ -f ".golangci.yml" ] || [ -f ".golangci.yaml" ]; } && QUALITY_TOOLS+=("golangci-lint") || true
        command -v gofmt &>/dev/null && QUALITY_TOOLS+=("gofmt") || true

    elif [ -f "composer.json" ]; then
        LANGUAGE="php"
        VERSION=$(jq -r '.require.php // "unknown"' composer.json 2>/dev/null || echo "unknown")
        BUILD_TOOL="composer"

        # Detect PHP framework
        if jq -e '.require."typo3/cms-core"' composer.json &>/dev/null; then
            PROJECT_TYPE="php-typo3"
            FRAMEWORK="typo3"
            TYPO3_VERSION=$(jq -r '.require."typo3/cms-core"' composer.json 2>/dev/null || echo "unknown")
        elif jq -e '.require."laravel/framework"' composer.json &>/dev/null; then
            PROJECT_TYPE="php-laravel"
            FRAMEWORK="laravel"
        elif jq -e '.require."symfony/symfony"' composer.json &>/dev/null; then
            PROJECT_TYPE="php-symfony"
            FRAMEWORK="symfony"
        else
            PROJECT_TYPE="php-library"
        fi

        # Detect PHP quality tools
        jq -e '.require."phpstan/phpstan" // .["require-dev"]."phpstan/phpstan"' composer.json &>/dev/null && QUALITY_TOOLS+=("phpstan") || true
        jq -e '.require."friendsofphp/php-cs-fixer" // .["require-dev"]."friendsofphp/php-cs-fixer"' composer.json &>/dev/null && QUALITY_TOOLS+=("php-cs-fixer") || true
        { [ -f "phpunit.xml" ] || [ -f "phpunit.xml.dist" ]; } && TEST_FRAMEWORK="phpunit" || true

    elif [ -f "package.json" ]; then
        LANGUAGE="typescript"
        VERSION=$(jq -r '.engines.node // "unknown"' package.json 2>/dev/null || echo "unknown")

        # Detect JS/TS framework
        if jq -e '.dependencies."next"' package.json &>/dev/null; then
            PROJECT_TYPE="typescript-nextjs"
            FRAMEWORK="next.js"
            BUILD_TOOL="npm"
        elif jq -e '.dependencies."react"' package.json &>/dev/null; then
            PROJECT_TYPE="typescript-react"
            FRAMEWORK="react"
            BUILD_TOOL="npm"
        elif jq -e '.dependencies."vue"' package.json &>/dev/null; then
            PROJECT_TYPE="typescript-vue"
            FRAMEWORK="vue"
            BUILD_TOOL="npm"
        elif jq -e '.dependencies."express"' package.json &>/dev/null; then
            PROJECT_TYPE="typescript-node"
            FRAMEWORK="express"
            BUILD_TOOL="npm"
        else
            PROJECT_TYPE="typescript-library"
            BUILD_TOOL="npm"
        fi

        # Check for yarn/pnpm
        [ -f "yarn.lock" ] && BUILD_TOOL="yarn" || true
        [ -f "pnpm-lock.yaml" ] && BUILD_TOOL="pnpm" || true

        # Detect quality tools
        jq -e '.devDependencies."eslint"' package.json &>/dev/null && QUALITY_TOOLS+=("eslint") || true
        jq -e '.devDependencies."prettier"' package.json &>/dev/null && QUALITY_TOOLS+=("prettier") || true
        jq -e '.devDependencies."typescript"' package.json &>/dev/null && QUALITY_TOOLS+=("tsc") || true

        # Detect test framework
        if jq -e '.devDependencies."jest"' package.json &>/dev/null; then
            TEST_FRAMEWORK="jest"
        elif jq -e '.devDependencies."vitest"' package.json &>/dev/null; then
            TEST_FRAMEWORK="vitest"
        fi || true

    elif [ -f "pyproject.toml" ]; then
        LANGUAGE="python"
        VERSION=$(grep 'requires-python' pyproject.toml | cut -d'"' -f2 2>/dev/null || echo "unknown")

        # Detect Python build tool
        if grep -q '\[tool.poetry\]' pyproject.toml 2>/dev/null; then
            BUILD_TOOL="poetry"
        elif grep -q '\[tool.hatch\]' pyproject.toml 2>/dev/null; then
            BUILD_TOOL="hatch"
        else
            BUILD_TOOL="pip"
        fi

        # Detect framework
        if grep -q 'django' pyproject.toml 2>/dev/null; then
            PROJECT_TYPE="python-django"
            FRAMEWORK="django"
        elif grep -q 'flask' pyproject.toml 2>/dev/null; then
            PROJECT_TYPE="python-flask"
            FRAMEWORK="flask"
        elif grep -q 'fastapi' pyproject.toml 2>/dev/null; then
            PROJECT_TYPE="python-fastapi"
            FRAMEWORK="fastapi"
        elif [ -d "scripts" ] && [ "$(find scripts -name '*.py' | wc -l)" -gt 3 ]; then
            PROJECT_TYPE="python-cli"
        else
            PROJECT_TYPE="python-library"
        fi

        # Detect quality tools
        grep -q 'ruff' pyproject.toml 2>/dev/null && QUALITY_TOOLS+=("ruff")
        grep -q 'black' pyproject.toml 2>/dev/null && QUALITY_TOOLS+=("black")
        grep -q 'mypy' pyproject.toml 2>/dev/null && QUALITY_TOOLS+=("mypy")
        grep -q 'pytest' pyproject.toml 2>/dev/null && TEST_FRAMEWORK="pytest"
    fi
}

# Detect if Makefile exists
if [ -f "Makefile" ]; then
    BUILD_TOOL="make"
fi

# Detect Docker (check both old and new compose naming)
[ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ] && HAS_DOCKER=true

# Detect CI
if [ -d ".github/workflows" ]; then
    CI="github-actions"
elif [ -f ".gitlab-ci.yml" ]; then
    CI="gitlab-ci"
elif [ -f ".circleci/config.yml" ]; then
    CI="circleci"
fi

# Detect IDE configurations
[ -f ".editorconfig" ] && IDE_CONFIGS+=("editorconfig") || true
[ -d ".vscode" ] && IDE_CONFIGS+=("vscode") || true
[ -d ".idea" ] && IDE_CONFIGS+=("idea") || true
[ -d ".phpstorm" ] && IDE_CONFIGS+=("phpstorm") || true
[ -d ".fleet" ] && IDE_CONFIGS+=("fleet") || true
[ -f ".sublime-project" ] && IDE_CONFIGS+=("sublime") || true
{ [ -d ".vim" ] || [ -f ".vimrc" ]; } && IDE_CONFIGS+=("vim") || true
{ [ -d ".nvim" ] || [ -f ".nvimrc" ]; } && IDE_CONFIGS+=("neovim") || true

# Detect AI coding agent configurations
[ -d ".cursor" ] && AGENT_CONFIGS+=("cursor") || true
{ [ -d ".claude" ] || [ -f "CLAUDE.md" ] || [ -f ".claude/CLAUDE.md" ]; } && AGENT_CONFIGS+=("claude") || true
[ -d ".windsurf" ] && AGENT_CONFIGS+=("windsurf") || true
{ [ -d ".aider" ] || [ -f ".aider.conf.yml" ]; } && AGENT_CONFIGS+=("aider") || true
[ -d ".continue" ] && AGENT_CONFIGS+=("continue") || true
{ [ -f "copilot-instructions.md" ] || [ -f ".github/copilot-instructions.md" ]; } && AGENT_CONFIGS+=("copilot") || true
[ -d ".codeium" ] && AGENT_CONFIGS+=("codeium") || true
[ -d ".tabnine" ] && AGENT_CONFIGS+=("tabnine") || true
{ [ -d ".sourcegraph" ] || [ -f ".sourcegraph/cody.json" ]; } && AGENT_CONFIGS+=("cody") || true

# Run detection
detect_language

# Output JSON
# Handle empty arrays
if [ ${#QUALITY_TOOLS[@]} -eq 0 ]; then
    TOOLS_JSON="[]"
else
    TOOLS_JSON="$(printf '%s\n' "${QUALITY_TOOLS[@]}" | jq -R . | jq -s .)"
fi

if [ ${#IDE_CONFIGS[@]} -eq 0 ]; then
    IDE_JSON="[]"
else
    IDE_JSON="$(printf '%s\n' "${IDE_CONFIGS[@]}" | jq -R . | jq -s .)"
fi

if [ ${#AGENT_CONFIGS[@]} -eq 0 ]; then
    AGENT_JSON="[]"
else
    AGENT_JSON="$(printf '%s\n' "${AGENT_CONFIGS[@]}" | jq -R . | jq -s .)"
fi

jq -n \
    --arg type "$PROJECT_TYPE" \
    --arg lang "$LANGUAGE" \
    --arg ver "$VERSION" \
    --arg build "$BUILD_TOOL" \
    --arg framework "$FRAMEWORK" \
    --argjson docker "$HAS_DOCKER" \
    --argjson tools "$TOOLS_JSON" \
    --arg test "$TEST_FRAMEWORK" \
    --arg ci "$CI" \
    --argjson ide_configs "$IDE_JSON" \
    --argjson agent_configs "$AGENT_JSON" \
    '{
        type: $type,
        language: $lang,
        version: $ver,
        build_tool: $build,
        framework: $framework,
        has_docker: $docker,
        quality_tools: $tools,
        test_framework: $test,
        ci: $ci,
        ide_configs: $ide_configs,
        agent_configs: $agent_configs
    }'
