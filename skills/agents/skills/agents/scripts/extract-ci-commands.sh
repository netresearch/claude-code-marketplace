#!/usr/bin/env bash
# Extract commands and configuration from CI/CD workflow files
set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# Parse GitHub Actions workflows
parse_github_actions() {
    local workflows_dir=".github/workflows"

    if [ ! -d "$workflows_dir" ]; then
        echo "{}"
        return
    fi

    local workflow_files=()
    local all_commands=()
    local jobs=()
    local triggers=()

    # Find all workflow files
    for f in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
        [ -f "$f" ] || continue
        workflow_files+=("$(basename "$f")")

        # Extract triggers (on: section)
        local file_triggers
        file_triggers=$(grep -A10 "^on:" "$f" 2>/dev/null | grep -E "^\s+(push|pull_request|workflow_dispatch|schedule|release):" | sed 's/[[:space:]]*\([a-z_]*\):.*/\1/' | tr '\n' ',' | sed 's/,$//' || echo "")
        [ -n "$file_triggers" ] && triggers+=("$file_triggers")

        # Extract job names
        local in_jobs=false
        while IFS= read -r line; do
            if [[ "$line" =~ ^jobs: ]]; then
                in_jobs=true
                continue
            fi
            if $in_jobs && [[ "$line" =~ ^[[:space:]]{2}([a-zA-Z0-9_-]+): ]]; then
                jobs+=("${BASH_REMATCH[1]}")
            fi
        done < "$f"

        # Extract run commands
        while IFS= read -r line; do
            if [[ "$line" =~ run:[[:space:]]*(.+) ]]; then
                local cmd="${BASH_REMATCH[1]}"
                # Skip if it's a multi-line indicator
                [[ "$cmd" == "|" ]] && continue
                [[ "$cmd" == "|-" ]] && continue
                # Clean and add
                cmd=$(echo "$cmd" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                [ -n "$cmd" ] && all_commands+=("$cmd")
            fi
        done < "$f"
    done

    # Deduplicate
    local unique_commands=()
    local unique_triggers=()
    local unique_jobs=()

    if [ ${#all_commands[@]} -gt 0 ]; then
        mapfile -t unique_commands < <(printf '%s\n' "${all_commands[@]}" | sort -u | head -20)
    fi
    if [ ${#triggers[@]} -gt 0 ]; then
        mapfile -t unique_triggers < <(printf '%s\n' "${triggers[@]}" | tr ',' '\n' | sort -u)
    fi
    if [ ${#jobs[@]} -gt 0 ]; then
        mapfile -t unique_jobs < <(printf '%s\n' "${jobs[@]}" | sort -u)
    fi

    # Build JSON arrays
    local files_json="[]"
    local commands_json="[]"
    local triggers_json="[]"
    local jobs_json="[]"

    [ ${#workflow_files[@]} -gt 0 ] && files_json=$(printf '%s\n' "${workflow_files[@]}" | jq -R . | jq -s .)
    [ ${#unique_commands[@]} -gt 0 ] && commands_json=$(printf '%s\n' "${unique_commands[@]}" | jq -R . | jq -s .)
    [ ${#unique_triggers[@]} -gt 0 ] && triggers_json=$(printf '%s\n' "${unique_triggers[@]}" | jq -R . | jq -s .)
    [ ${#unique_jobs[@]} -gt 0 ] && jobs_json=$(printf '%s\n' "${unique_jobs[@]}" | jq -R . | jq -s .)

    jq -n \
        --argjson files "$files_json" \
        --argjson commands "$commands_json" \
        --argjson triggers "$triggers_json" \
        --argjson jobs "$jobs_json" \
        '{
            workflow_files: $files,
            triggers: $triggers,
            jobs: $jobs,
            run_commands: $commands
        }'
}

# Parse GitLab CI
parse_gitlab_ci() {
    if [ ! -f ".gitlab-ci.yml" ]; then
        echo "{}"
        return
    fi

    local stages=()
    local jobs=()
    local commands=()

    # Extract stages
    local in_stages=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^stages: ]]; then
            in_stages=true
            continue
        fi
        if $in_stages && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.+) ]]; then
            stages+=("${BASH_REMATCH[1]}")
        elif $in_stages && [[ ! "$line" =~ ^[[:space:]] ]]; then
            in_stages=false
        fi
    done < ".gitlab-ci.yml"

    # Extract job names (lines that start with a name and have a colon, not indented, not keywords)
    while IFS= read -r line; do
        if [[ "$line" =~ ^([a-zA-Z0-9_-]+): ]] && [[ ! "$line" =~ ^(stages|variables|default|include|workflow|image|services|before_script|after_script|cache): ]]; then
            jobs+=("${BASH_REMATCH[1]}")
        fi
    done < ".gitlab-ci.yml"

    # Extract script commands
    local in_script=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]+script: ]]; then
            in_script=true
            continue
        fi
        if $in_script && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.+) ]]; then
            local cmd="${BASH_REMATCH[1]}"
            cmd=$(echo "$cmd" | sed "s/^['\"]//;s/['\"]$//")
            [ -n "$cmd" ] && commands+=("$cmd")
        elif $in_script && [[ ! "$line" =~ ^[[:space:]] ]]; then
            in_script=false
        fi
    done < ".gitlab-ci.yml"

    # Build JSON arrays
    local stages_json="[]"
    local jobs_json="[]"
    local commands_json="[]"

    [ ${#stages[@]} -gt 0 ] && stages_json=$(printf '%s\n' "${stages[@]}" | jq -R . | jq -s .)
    [ ${#jobs[@]} -gt 0 ] && jobs_json=$(printf '%s\n' "${jobs[@]}" | jq -R . | jq -s .)
    [ ${#commands[@]} -gt 0 ] && commands_json=$(printf '%s\n' "${commands[@]}" | sort -u | head -20 | jq -R . | jq -s .)

    jq -n \
        --argjson stages "$stages_json" \
        --argjson jobs "$jobs_json" \
        --argjson commands "$commands_json" \
        '{
            stages: $stages,
            jobs: $jobs,
            script_commands: $commands
        }'
}

# Parse CircleCI
parse_circleci() {
    if [ ! -f ".circleci/config.yml" ]; then
        echo "{}"
        return
    fi

    local jobs=()
    local commands=()
    local orbs=()

    # Extract orbs
    local in_orbs=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^orbs: ]]; then
            in_orbs=true
            continue
        fi
        if $in_orbs && [[ "$line" =~ ^[[:space:]]+([a-zA-Z0-9_-]+):[[:space:]]* ]]; then
            orbs+=("${BASH_REMATCH[1]}")
        elif $in_orbs && [[ ! "$line" =~ ^[[:space:]] ]]; then
            in_orbs=false
        fi
    done < ".circleci/config.yml"

    # Extract job names
    local in_jobs=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^jobs: ]]; then
            in_jobs=true
            continue
        fi
        if $in_jobs && [[ "$line" =~ ^[[:space:]]{2}([a-zA-Z0-9_-]+): ]]; then
            jobs+=("${BASH_REMATCH[1]}")
        elif $in_jobs && [[ ! "$line" =~ ^[[:space:]] ]]; then
            in_jobs=false
        fi
    done < ".circleci/config.yml"

    # Extract run commands
    while IFS= read -r line; do
        if [[ "$line" =~ command:[[:space:]]*(.+) ]]; then
            local cmd="${BASH_REMATCH[1]}"
            [[ "$cmd" == "|" ]] && continue
            cmd=$(echo "$cmd" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            [ -n "$cmd" ] && commands+=("$cmd")
        fi
    done < ".circleci/config.yml"

    # Build JSON arrays
    local jobs_json="[]"
    local commands_json="[]"
    local orbs_json="[]"

    [ ${#jobs[@]} -gt 0 ] && jobs_json=$(printf '%s\n' "${jobs[@]}" | jq -R . | jq -s .)
    [ ${#commands[@]} -gt 0 ] && commands_json=$(printf '%s\n' "${commands[@]}" | sort -u | head -20 | jq -R . | jq -s .)
    [ ${#orbs[@]} -gt 0 ] && orbs_json=$(printf '%s\n' "${orbs[@]}" | jq -R . | jq -s .)

    jq -n \
        --argjson jobs "$jobs_json" \
        --argjson commands "$commands_json" \
        --argjson orbs "$orbs_json" \
        '{
            orbs: $orbs,
            jobs: $jobs,
            run_commands: $commands
        }'
}

# Parse Travis CI
parse_travis() {
    if [ ! -f ".travis.yml" ]; then
        echo "{}"
        return
    fi

    local commands=()
    local language=""

    # Extract language
    language=$(grep -E "^language:" ".travis.yml" 2>/dev/null | sed 's/language:[[:space:]]*//' | head -1 || echo "")

    # Extract script commands
    local in_script=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^script: ]]; then
            in_script=true
            # Check if single-line script
            if [[ "$line" =~ ^script:[[:space:]]+(.+) ]]; then
                commands+=("${BASH_REMATCH[1]}")
                in_script=false
            fi
            continue
        fi
        if $in_script && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.+) ]]; then
            commands+=("${BASH_REMATCH[1]}")
        elif $in_script && [[ ! "$line" =~ ^[[:space:]] ]]; then
            in_script=false
        fi
    done < ".travis.yml"

    local commands_json="[]"
    [ ${#commands[@]} -gt 0 ] && commands_json=$(printf '%s\n' "${commands[@]}" | jq -R . | jq -s .)

    jq -n \
        --arg language "$language" \
        --argjson commands "$commands_json" \
        '{
            language: $language,
            script_commands: $commands
        } | with_entries(select(.value != "" and .value != []))'
}

# Detect CI system
CI_SYSTEM="none"
if [ -d ".github/workflows" ]; then
    CI_SYSTEM="github-actions"
elif [ -f ".gitlab-ci.yml" ]; then
    CI_SYSTEM="gitlab-ci"
elif [ -f ".circleci/config.yml" ]; then
    CI_SYSTEM="circleci"
elif [ -f ".travis.yml" ]; then
    CI_SYSTEM="travis-ci"
elif [ -f "Jenkinsfile" ]; then
    CI_SYSTEM="jenkins"
elif [ -f "azure-pipelines.yml" ]; then
    CI_SYSTEM="azure-pipelines"
elif [ -f "bitbucket-pipelines.yml" ]; then
    CI_SYSTEM="bitbucket-pipelines"
fi

# Parse the detected CI system
GITHUB_ACTIONS="{}"
GITLAB_CI="{}"
CIRCLECI="{}"
TRAVIS="{}"

case "$CI_SYSTEM" in
    "github-actions")
        GITHUB_ACTIONS=$(parse_github_actions)
        ;;
    "gitlab-ci")
        GITLAB_CI=$(parse_gitlab_ci)
        ;;
    "circleci")
        CIRCLECI=$(parse_circleci)
        ;;
    "travis-ci")
        TRAVIS=$(parse_travis)
        ;;
esac

# Build final JSON output
jq -n \
    --arg ci_system "$CI_SYSTEM" \
    --argjson github_actions "$GITHUB_ACTIONS" \
    --argjson gitlab_ci "$GITLAB_CI" \
    --argjson circleci "$CIRCLECI" \
    --argjson travis "$TRAVIS" \
    '{
        ci_system: $ci_system,
        github_actions: $github_actions,
        gitlab_ci: $gitlab_ci,
        circleci: $circleci,
        travis: $travis
    }'
