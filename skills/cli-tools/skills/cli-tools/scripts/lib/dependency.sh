#!/usr/bin/env bash
# dependency.sh - Dependency resolution and ordering
#
# This library handles tool dependencies:
# - Check if dependencies are satisfied
# - Resolve installation order via topological sort
# - Detect circular dependencies
# - Validate catalog order field consistency

set -euo pipefail

# Check if dependencies for a tool are satisfied
# Args: catalog_file
# Returns: 0 if satisfied, 1 if not
check_dependencies() {
  local catalog_file="$1"
  local tool
  tool="$(basename "$catalog_file" .json)"

  if ! command -v jq >/dev/null 2>&1; then
    echo "[$tool] Warning: jq not available, cannot check dependencies" >&2
    return 0  # Assume satisfied
  fi

  # Get requires array
  local requires_count
  requires_count="$(jq '.requires // [] | length' "$catalog_file" 2>/dev/null || echo "0")"

  if [ "$requires_count" -eq 0 ]; then
    return 0  # No dependencies
  fi

  local missing=()
  for ((i=0; i<requires_count; i++)); do
    local dep
    dep="$(jq -r ".requires[$i]" "$catalog_file" 2>/dev/null || echo "")"
    [ -z "$dep" ] && continue

    # Check if dependency is installed
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing+=("$dep")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "[$tool] Missing dependencies: ${missing[*]}" >&2
    return 1
  fi

  return 0
}

# Get list of dependencies for a tool
# Args: catalog_file
# Returns: space-separated list of dependencies
get_dependencies() {
  local catalog_file="$1"

  if ! command -v jq >/dev/null 2>&1; then
    echo ""
    return 0
  fi

  local deps
  deps="$(jq -r '.requires // [] | join(" ")' "$catalog_file" 2>/dev/null || echo "")"
  echo "$deps"
}

# Topological sort for installation order
# Args: catalog_dir
# Returns: ordered list of tools (one per line)
topological_sort() {
  local catalog_dir="$1"

  if [ ! -d "$catalog_dir" ]; then
    echo "Error: Catalog directory not found: $catalog_dir" >&2
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq not available for topological sort" >&2
    return 1
  fi

  # Build dependency graph
  declare -A deps      # tool -> space-separated dependencies
  declare -A in_degree # tool -> number of incoming edges
  declare -a all_tools

  for catalog_file in "$catalog_dir"/*.json; do
    [ -f "$catalog_file" ] || continue

    local tool
    tool="$(basename "$catalog_file" .json)"
    all_tools+=("$tool")

    # Get dependencies
    local tool_deps
    tool_deps="$(get_dependencies "$catalog_file")"
    deps[$tool]="$tool_deps"

    # Initialize in_degree
    in_degree[$tool]=0
  done

  # Calculate in_degree
  for tool in "${all_tools[@]}"; do
    for dep in ${deps[$tool]}; do
      if [ -n "${in_degree[$dep]+x}" ]; then
        in_degree[$dep]=$((in_degree[$dep] + 1))
      fi
    done
  done

  # Find tools with no dependencies (in_degree == 0)
  local queue=()
  for tool in "${all_tools[@]}"; do
    if [ "${in_degree[$tool]}" -eq 0 ]; then
      queue+=("$tool")
    fi
  done

  # Process queue
  local sorted=()
  while [ ${#queue[@]} -gt 0 ]; do
    # Pop from queue
    local current="${queue[0]}"
    queue=("${queue[@]:1}")
    sorted+=("$current")

    # Reduce in_degree for dependents
    for tool in "${all_tools[@]}"; do
      if [[ " ${deps[$tool]} " == *" $current "* ]]; then
        in_degree[$tool]=$((in_degree[$tool] - 1))
        if [ "${in_degree[$tool]}" -eq 0 ]; then
          queue+=("$tool")
        fi
      fi
    done
  done

  # Check for cycles
  if [ ${#sorted[@]} -ne ${#all_tools[@]} ]; then
    echo "Error: Circular dependency detected" >&2
    # Find tools not in sorted (they're part of cycle)
    for tool in "${all_tools[@]}"; do
      if [[ ! " ${sorted[*]} " =~ " ${tool} " ]]; then
        echo "  Tool in cycle: $tool (depends on: ${deps[$tool]})" >&2
      fi
    done
    return 1
  fi

  # Output sorted list
  printf '%s\n' "${sorted[@]}"
}

# Validate that catalog "order" field matches dependency requirements
# Args: catalog_dir
# Returns: 0 if consistent, 1 if not
validate_order_consistency() {
  local catalog_dir="$1"

  if [ ! -d "$catalog_dir" ]; then
    echo "Error: Catalog directory not found: $catalog_dir" >&2
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "Warning: jq not available, cannot validate order consistency" >&2
    return 0
  fi

  local errors=0

  for catalog_file in "$catalog_dir"/*.json; do
    [ -f "$catalog_file" ] || continue

    local tool
    tool="$(basename "$catalog_file" .json)"

    # Get tool's order
    local tool_order
    tool_order="$(jq -r '.guide.order // 999' "$catalog_file" 2>/dev/null || echo "999")"

    # Get dependencies
    local requires_count
    requires_count="$(jq '.requires // [] | length' "$catalog_file" 2>/dev/null || echo "0")"

    for ((i=0; i<requires_count; i++)); do
      local dep
      dep="$(jq -r ".requires[$i]" "$catalog_file" 2>/dev/null || echo "")"
      [ -z "$dep" ] && continue

      # Find dependency's catalog file
      local dep_catalog="$catalog_dir/$dep.json"
      if [ ! -f "$dep_catalog" ]; then
        echo "Warning: Dependency $dep for $tool not found in catalog" >&2
        continue
      fi

      # Get dependency's order
      local dep_order
      dep_order="$(jq -r '.guide.order // 999' "$dep_catalog" 2>/dev/null || echo "999")"

      # Check if dependency has lower order (installed first)
      if [ "$dep_order" -ge "$tool_order" ]; then
        echo "Error: Order inconsistency: $tool (order=$tool_order) depends on $dep (order=$dep_order)" >&2
        echo "       Dependency $dep should have lower order number (installed before $tool)" >&2
        errors=$((errors + 1))
      fi
    done
  done

  if [ $errors -gt 0 ]; then
    echo ""
    echo "Found $errors order consistency errors" >&2
    return 1
  fi

  echo "✓ All order fields are consistent with dependencies"
  return 0
}

# Get installation order respecting dependencies
# Args: catalog_dir, tool_list (optional, space-separated)
# Returns: ordered list of tools
get_install_order() {
  local catalog_dir="$1"
  local tool_list="${2:-}"

  if [ -z "$tool_list" ]; then
    # No specific tools requested, sort all tools
    topological_sort "$catalog_dir"
  else
    # Build subgraph for requested tools + their dependencies
    declare -A needed
    declare -a queue

    # Add requested tools to queue
    for tool in $tool_list; do
      queue+=("$tool")
    done

    # BFS to collect all dependencies
    while [ ${#queue[@]} -gt 0 ]; do
      local current="${queue[0]}"
      queue=("${queue[@]:1}")

      # Skip if already processed
      [ -n "${needed[$current]+x}" ] && continue
      needed[$current]=1

      # Get dependencies
      local catalog_file="$catalog_dir/$current.json"
      if [ -f "$catalog_file" ]; then
        local deps
        deps="$(get_dependencies "$catalog_file")"
        for dep in $deps; do
          queue+=("$dep")
        done
      fi
    done

    # Now run topological sort on full catalog, filter to needed tools
    local sorted
    sorted="$(topological_sort "$catalog_dir")"

    # Filter to only needed tools
    while IFS= read -r tool; do
      if [ -n "${needed[$tool]+x}" ]; then
        echo "$tool"
      fi
    done <<< "$sorted"
  fi
}
