#!/usr/bin/env bash
# detect_project_type.sh - Detect project type from files in current directory
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Output format: json or text
FORMAT="${1:-text}"

detect_types() {
    local types=()
    local dir="${1:-.}"

    # Python
    if [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ] || [ -f "$dir/requirements.txt" ] || [ -f "$dir/Pipfile" ]; then
        types+=("python")
    fi

    # Node.js
    if [ -f "$dir/package.json" ]; then
        types+=("node")
    fi

    # Rust
    if [ -f "$dir/Cargo.toml" ]; then
        types+=("rust")
    fi

    # Go
    if [ -f "$dir/go.mod" ]; then
        types+=("go")
    fi

    # Ruby
    if [ -f "$dir/Gemfile" ] || [ -f "$dir/.ruby-version" ]; then
        types+=("ruby")
    fi

    # PHP
    if [ -f "$dir/composer.json" ] || [ -f "$dir/composer.lock" ] || compgen -G "$dir/*.php" > /dev/null 2>&1; then
        types+=("php")
    fi

    # Docker
    if [ -f "$dir/Dockerfile" ] || [ -f "$dir/docker-compose.yml" ] || [ -f "$dir/docker-compose.yaml" ] || [ -f "$dir/compose.yml" ]; then
        types+=("docker")
    fi

    # Terraform
    if compgen -G "$dir/*.tf" > /dev/null 2>&1 || [ -d "$dir/terraform" ]; then
        types+=("terraform")
    fi

    # Kubernetes
    if [ -f "$dir/k8s" ] || compgen -G "$dir/**/deployment.yaml" > /dev/null 2>&1; then
        types+=("kubernetes")
    fi

    # Ansible
    if [ -f "$dir/ansible.cfg" ] || [ -d "$dir/playbooks" ] || compgen -G "$dir/*.yml" > /dev/null 2>&1; then
        # Check if yaml files look like ansible
        if grep -rq "hosts:" "$dir"/*.yml 2>/dev/null || grep -rq "tasks:" "$dir"/*.yml 2>/dev/null; then
            types+=("ansible")
        fi
    fi

    # Shell/Make
    if [ -f "$dir/Makefile" ] || compgen -G "$dir/*.sh" > /dev/null 2>&1; then
        types+=("shell")
    fi

    echo "${types[@]}"
}

get_required_tools() {
    local project_type="$1"
    case "$project_type" in
        python)  echo "python uv" ;;
        node)    echo "node npm" ;;
        rust)    echo "rust" ;;
        go)      echo "go" ;;
        ruby)    echo "ruby" ;;
        php)     echo "php composer" ;;
        docker)  echo "docker compose" ;;
        terraform) echo "terraform" ;;
        kubernetes) echo "kubectl" ;;
        ansible) echo "ansible-core" ;;
        shell)   echo "" ;;
        *)       echo "" ;;
    esac
}

get_recommended_tools() {
    local project_type="$1"
    case "$project_type" in
        python)  echo "ruff black mypy" ;;
        node)    echo "eslint prettier" ;;
        rust)    echo "" ;;
        go)      echo "golangci-lint" ;;
        ruby)    echo "" ;;
        php)     echo "phpstan phpcs" ;;
        docker)  echo "dive trivy" ;;
        terraform) echo "tfsec trivy" ;;
        kubernetes) echo "" ;;
        ansible) echo "" ;;
        shell)   echo "shellcheck shfmt" ;;
        *)       echo "" ;;
    esac
}

# Main
PROJECT_DIR="${2:-.}"
TYPES=$(detect_types "$PROJECT_DIR")

if [ "$FORMAT" = "json" ]; then
    # Output as JSON
    echo "{"
    echo "  \"project_types\": [$(echo "$TYPES" | tr ' ' '\n' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')],"

    all_required=""
    all_recommended=""
    for t in $TYPES; do
        all_required="$all_required $(get_required_tools "$t")"
        all_recommended="$all_recommended $(get_recommended_tools "$t")"
    done

    # Dedupe
    all_required=$(echo "$all_required" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    all_recommended=$(echo "$all_recommended" | tr ' ' '\n' | sort -u | tr '\n' ' ')

    echo "  \"required_tools\": [$(echo "$all_required" | tr ' ' '\n' | grep -v '^$' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')],"
    echo "  \"recommended_tools\": [$(echo "$all_recommended" | tr ' ' '\n' | grep -v '^$' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')]"
    echo "}"
else
    # Text output
    if [ -z "$TYPES" ]; then
        echo "No specific project type detected"
        exit 0
    fi

    echo "Detected project types: $TYPES"
    echo ""

    for t in $TYPES; do
        req=$(get_required_tools "$t")
        rec=$(get_recommended_tools "$t")
        echo "[$t]"
        [ -n "$req" ] && echo "  Required: $req"
        [ -n "$rec" ] && echo "  Recommended: $rec"
    done
fi
