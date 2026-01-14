#!/usr/bin/env bash
# Extract detailed settings from quality tool configuration files
# (linters, formatters, type checkers, etc.)
set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# Helper to safely parse YAML values
yaml_get() {
    local file="$1"
    local key="$2"
    local default="${3:-}"

    if [ ! -f "$file" ]; then
        echo "$default"
        return
    fi

    # Simple YAML extraction (handles basic cases)
    grep -E "^${key}:" "$file" 2>/dev/null | sed "s/^${key}:[[:space:]]*//" | head -1 || echo "$default"
}

# Parse golangci-lint config (.golangci.yml or .golangci.yaml)
parse_golangci() {
    local config_file=""
    for f in .golangci.yml .golangci.yaml; do
        [ -f "$f" ] && config_file="$f" && break
    done

    if [ -z "$config_file" ]; then
        echo "{}"
        return
    fi

    local line_length=""
    local enabled_linters=()
    local disabled_linters=()

    # Extract line-length from linters-settings.lll
    line_length=$(grep -A5 "lll:" "$config_file" 2>/dev/null | grep "line-length:" | sed 's/.*line-length:[[:space:]]*//' | head -1 || echo "")

    # Extract enabled linters
    local in_enable=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*enable: ]]; then
            in_enable=true
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*disable: ]] || [[ "$line" =~ ^[[:space:]]*[a-z]+: && ! "$line" =~ ^[[:space:]]*- ]]; then
            in_enable=false
        fi
        if $in_enable && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*([a-z0-9_-]+) ]]; then
            enabled_linters+=("${BASH_REMATCH[1]}")
        fi
    done < "$config_file"

    # Extract disabled linters
    local in_disable=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*disable: ]]; then
            in_disable=true
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*enable: ]] || [[ "$line" =~ ^[[:space:]]*[a-z]+: && ! "$line" =~ ^[[:space:]]*- ]]; then
            in_disable=false
        fi
        if $in_disable && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*([a-z0-9_-]+) ]]; then
            disabled_linters+=("${BASH_REMATCH[1]}")
        fi
    done < "$config_file"

    # Build JSON arrays
    local enabled_json="[]"
    local disabled_json="[]"
    [ ${#enabled_linters[@]} -gt 0 ] && enabled_json=$(printf '%s\n' "${enabled_linters[@]}" | jq -R . | jq -s .)
    [ ${#disabled_linters[@]} -gt 0 ] && disabled_json=$(printf '%s\n' "${disabled_linters[@]}" | jq -R . | jq -s .)

    jq -n \
        --arg file "$config_file" \
        --arg line_length "$line_length" \
        --argjson enabled "$enabled_json" \
        --argjson disabled "$disabled_json" \
        '{
            file: $file,
            line_length: $line_length,
            enabled_linters: $enabled,
            disabled_linters: $disabled
        } | with_entries(select(.value != "" and .value != []))'
}

# Parse PHPStan config (phpstan.neon or phpstan.neon.dist)
parse_phpstan() {
    local config_file=""
    for f in phpstan.neon phpstan.neon.dist phpstan.dist.neon; do
        [ -f "$f" ] && config_file="$f" && break
    done

    if [ -z "$config_file" ]; then
        echo "{}"
        return
    fi

    local level=""
    local paths=()

    # Extract level
    level=$(grep -E "^[[:space:]]*level:" "$config_file" 2>/dev/null | sed 's/.*level:[[:space:]]*//' | head -1 || echo "")

    # Extract paths
    local in_paths=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*paths: ]]; then
            in_paths=true
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*[a-z]+: && ! "$line" =~ ^[[:space:]]*- ]]; then
            in_paths=false
        fi
        if $in_paths && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.+) ]]; then
            paths+=("${BASH_REMATCH[1]}")
        fi
    done < "$config_file"

    local paths_json="[]"
    [ ${#paths[@]} -gt 0 ] && paths_json=$(printf '%s\n' "${paths[@]}" | jq -R . | jq -s .)

    jq -n \
        --arg file "$config_file" \
        --arg level "$level" \
        --argjson paths "$paths_json" \
        '{
            file: $file,
            level: $level,
            paths: $paths
        } | with_entries(select(.value != "" and .value != []))'
}

# Parse ESLint config
parse_eslint() {
    local config_file=""
    for f in eslint.config.js eslint.config.mjs .eslintrc.js .eslintrc.cjs .eslintrc.json .eslintrc.yml .eslintrc.yaml .eslintrc; do
        [ -f "$f" ] && config_file="$f" && break
    done

    if [ -z "$config_file" ]; then
        echo "{}"
        return
    fi

    local extends=()
    local plugins=()

    # For JSON config files
    if [[ "$config_file" == *.json ]] || [[ "$config_file" == .eslintrc ]]; then
        extends=$(jq -r '.extends // [] | if type == "array" then . else [.] end | join(", ")' "$config_file" 2>/dev/null || echo "")
        plugins=$(jq -r '.plugins // [] | join(", ")' "$config_file" 2>/dev/null || echo "")
    fi

    jq -n \
        --arg file "$config_file" \
        --arg extends "$extends" \
        --arg plugins "$plugins" \
        '{
            file: $file,
            extends: $extends,
            plugins: $plugins
        } | with_entries(select(.value != ""))'
}

# Parse Prettier config
parse_prettier() {
    local config_file=""
    for f in .prettierrc .prettierrc.json .prettierrc.yml .prettierrc.yaml .prettierrc.js .prettierrc.cjs prettier.config.js prettier.config.cjs; do
        [ -f "$f" ] && config_file="$f" && break
    done

    if [ -z "$config_file" ]; then
        echo "{}"
        return
    fi

    local print_width=""
    local tab_width=""
    local use_tabs=""
    local semi=""
    local single_quote=""

    # For JSON config files
    if [[ "$config_file" == *.json ]] || [[ "$config_file" == .prettierrc ]]; then
        print_width=$(jq -r '.printWidth // ""' "$config_file" 2>/dev/null || echo "")
        tab_width=$(jq -r '.tabWidth // ""' "$config_file" 2>/dev/null || echo "")
        use_tabs=$(jq -r '.useTabs // ""' "$config_file" 2>/dev/null || echo "")
        semi=$(jq -r '.semi // ""' "$config_file" 2>/dev/null || echo "")
        single_quote=$(jq -r '.singleQuote // ""' "$config_file" 2>/dev/null || echo "")
    fi

    jq -n \
        --arg file "$config_file" \
        --arg print_width "$print_width" \
        --arg tab_width "$tab_width" \
        --arg use_tabs "$use_tabs" \
        --arg semi "$semi" \
        --arg single_quote "$single_quote" \
        '{
            file: $file,
            print_width: $print_width,
            tab_width: $tab_width,
            use_tabs: $use_tabs,
            semi: $semi,
            single_quote: $single_quote
        } | with_entries(select(.value != ""))'
}

# Parse TypeScript config (tsconfig.json)
parse_tsconfig() {
    if [ ! -f "tsconfig.json" ]; then
        echo "{}"
        return
    fi

    local strict=""
    local target=""
    local module=""
    local strict_null=""

    strict=$(jq -r '.compilerOptions.strict // ""' tsconfig.json 2>/dev/null || echo "")
    target=$(jq -r '.compilerOptions.target // ""' tsconfig.json 2>/dev/null || echo "")
    module=$(jq -r '.compilerOptions.module // ""' tsconfig.json 2>/dev/null || echo "")
    strict_null=$(jq -r '.compilerOptions.strictNullChecks // ""' tsconfig.json 2>/dev/null || echo "")

    jq -n \
        --arg file "tsconfig.json" \
        --arg strict "$strict" \
        --arg target "$target" \
        --arg module "$module" \
        --arg strict_null "$strict_null" \
        '{
            file: $file,
            strict: $strict,
            target: $target,
            module: $module,
            strict_null_checks: $strict_null
        } | with_entries(select(.value != ""))'
}

# Parse Ruff config (ruff.toml or pyproject.toml)
parse_ruff() {
    local config_file=""
    local line_length=""
    local select_rules=""
    local ignore_rules=""

    # Check for standalone ruff.toml
    if [ -f "ruff.toml" ]; then
        config_file="ruff.toml"
        line_length=$(grep -E "^line-length" "$config_file" 2>/dev/null | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
        select_rules=$(grep -E "^select" "$config_file" 2>/dev/null | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
        ignore_rules=$(grep -E "^ignore" "$config_file" 2>/dev/null | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
    elif [ -f "pyproject.toml" ] && grep -q '\[tool.ruff\]' pyproject.toml 2>/dev/null; then
        config_file="pyproject.toml"
        # Extract from [tool.ruff] section
        line_length=$(sed -n '/\[tool.ruff\]/,/^\[/p' pyproject.toml 2>/dev/null | grep -E "^line-length" | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
        select_rules=$(sed -n '/\[tool.ruff\]/,/^\[/p' pyproject.toml 2>/dev/null | grep -E "^select" | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
    fi

    if [ -z "$config_file" ]; then
        echo "{}"
        return
    fi

    jq -n \
        --arg file "$config_file" \
        --arg line_length "$line_length" \
        --arg select "$select_rules" \
        --arg ignore "$ignore_rules" \
        '{
            file: $file,
            line_length: $line_length,
            select: $select,
            ignore: $ignore
        } | with_entries(select(.value != ""))'
}

# Parse mypy config
parse_mypy() {
    local config_file=""
    local strict=""
    local python_version=""

    # Check various config locations
    if [ -f "mypy.ini" ]; then
        config_file="mypy.ini"
        strict=$(grep -E "^strict[[:space:]]*=" "$config_file" 2>/dev/null | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
        python_version=$(grep -E "^python_version[[:space:]]*=" "$config_file" 2>/dev/null | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
    elif [ -f ".mypy.ini" ]; then
        config_file=".mypy.ini"
        strict=$(grep -E "^strict[[:space:]]*=" "$config_file" 2>/dev/null | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
    elif [ -f "pyproject.toml" ] && grep -q '\[tool.mypy\]' pyproject.toml 2>/dev/null; then
        config_file="pyproject.toml"
        strict=$(sed -n '/\[tool.mypy\]/,/^\[/p' pyproject.toml 2>/dev/null | grep -E "^strict" | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
        python_version=$(sed -n '/\[tool.mypy\]/,/^\[/p' pyproject.toml 2>/dev/null | grep -E "^python_version" | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
    elif [ -f "setup.cfg" ] && grep -q '\[mypy\]' setup.cfg 2>/dev/null; then
        config_file="setup.cfg"
        strict=$(sed -n '/\[mypy\]/,/^\[/p' setup.cfg 2>/dev/null | grep -E "^strict[[:space:]]*=" | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
    fi

    if [ -z "$config_file" ]; then
        echo "{}"
        return
    fi

    jq -n \
        --arg file "$config_file" \
        --arg strict "$strict" \
        --arg python_version "$python_version" \
        '{
            file: $file,
            strict: $strict,
            python_version: $python_version
        } | with_entries(select(.value != ""))'
}

# Parse Black config
parse_black() {
    local config_file=""
    local line_length=""
    local target_version=""

    if [ -f "pyproject.toml" ] && grep -q '\[tool.black\]' pyproject.toml 2>/dev/null; then
        config_file="pyproject.toml"
        line_length=$(sed -n '/\[tool.black\]/,/^\[/p' pyproject.toml 2>/dev/null | grep -E "^line-length" | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
        target_version=$(sed -n '/\[tool.black\]/,/^\[/p' pyproject.toml 2>/dev/null | grep -E "^target-version" | sed 's/.*=[[:space:]]*//' | head -1 || echo "")
    fi

    if [ -z "$config_file" ]; then
        echo "{}"
        return
    fi

    jq -n \
        --arg file "$config_file" \
        --arg line_length "$line_length" \
        --arg target_version "$target_version" \
        '{
            file: $file,
            line_length: $line_length,
            target_version: $target_version
        } | with_entries(select(.value != ""))'
}

# Parse PHP-CS-Fixer config
parse_php_cs_fixer() {
    local config_file=""
    for f in .php-cs-fixer.php .php-cs-fixer.dist.php .php_cs .php_cs.dist; do
        [ -f "$f" ] && config_file="$f" && break
    done

    if [ -z "$config_file" ]; then
        echo "{}"
        return
    fi

    # Check for risky rules
    local has_risky="false"
    grep -q "setRiskyAllowed(true)" "$config_file" 2>/dev/null && has_risky="true"

    # Try to extract rule set
    local rule_set=""
    rule_set=$(grep -oE "@(PSR12|PSR2|Symfony|PhpCsFixer)" "$config_file" 2>/dev/null | head -1 || echo "")

    jq -n \
        --arg file "$config_file" \
        --arg rule_set "$rule_set" \
        --argjson risky "$has_risky" \
        '{
            file: $file,
            rule_set: $rule_set,
            risky_allowed: $risky
        } | with_entries(select(.value != "" and .value != false))'
}

# Detect which tools are configured
TOOLS=()
[ -f ".golangci.yml" ] || [ -f ".golangci.yaml" ] && TOOLS+=("golangci-lint")
[ -f "phpstan.neon" ] || [ -f "phpstan.neon.dist" ] || [ -f "phpstan.dist.neon" ] && TOOLS+=("phpstan")
for f in eslint.config.js eslint.config.mjs .eslintrc.js .eslintrc.cjs .eslintrc.json .eslintrc.yml .eslintrc.yaml .eslintrc; do
    [ -f "$f" ] && TOOLS+=("eslint") && break
done
for f in .prettierrc .prettierrc.json .prettierrc.yml prettier.config.js; do
    [ -f "$f" ] && TOOLS+=("prettier") && break
done
[ -f "tsconfig.json" ] && TOOLS+=("typescript")
{ [ -f "ruff.toml" ] || grep -q '\[tool.ruff\]' pyproject.toml 2>/dev/null; } && TOOLS+=("ruff")
{ [ -f "mypy.ini" ] || [ -f ".mypy.ini" ] || grep -q '\[tool.mypy\]' pyproject.toml 2>/dev/null || grep -q '\[mypy\]' setup.cfg 2>/dev/null; } && TOOLS+=("mypy")
grep -q '\[tool.black\]' pyproject.toml 2>/dev/null && TOOLS+=("black")
for f in .php-cs-fixer.php .php-cs-fixer.dist.php .php_cs .php_cs.dist; do
    [ -f "$f" ] && TOOLS+=("php-cs-fixer") && break
done

# Build tools list JSON
if [ ${#TOOLS[@]} -eq 0 ]; then
    TOOLS_JSON="[]"
else
    TOOLS_JSON=$(printf '%s\n' "${TOOLS[@]}" | jq -R . | jq -s .)
fi

# Parse each tool config
GOLANGCI_CONFIG=$(parse_golangci)
PHPSTAN_CONFIG=$(parse_phpstan)
ESLINT_CONFIG=$(parse_eslint)
PRETTIER_CONFIG=$(parse_prettier)
TSCONFIG=$(parse_tsconfig)
RUFF_CONFIG=$(parse_ruff)
MYPY_CONFIG=$(parse_mypy)
BLACK_CONFIG=$(parse_black)
PHP_CS_FIXER_CONFIG=$(parse_php_cs_fixer)

# Build final JSON output
jq -n \
    --argjson tools "$TOOLS_JSON" \
    --argjson golangci "$GOLANGCI_CONFIG" \
    --argjson phpstan "$PHPSTAN_CONFIG" \
    --argjson eslint "$ESLINT_CONFIG" \
    --argjson prettier "$PRETTIER_CONFIG" \
    --argjson typescript "$TSCONFIG" \
    --argjson ruff "$RUFF_CONFIG" \
    --argjson mypy "$MYPY_CONFIG" \
    --argjson black "$BLACK_CONFIG" \
    --argjson php_cs_fixer "$PHP_CS_FIXER_CONFIG" \
    '{
        detected_tools: $tools,
        golangci_lint: $golangci,
        phpstan: $phpstan,
        eslint: $eslint,
        prettier: $prettier,
        typescript: $typescript,
        ruff: $ruff,
        mypy: $mypy,
        black: $black,
        php_cs_fixer: $php_cs_fixer
    }'
