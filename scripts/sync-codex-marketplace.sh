#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
# Generate the ChatGPT/Codex catalog from the canonical Claude catalog.

set -eu

case "${1:-}" in
    ''|--check) ;;
    *) echo "Usage: $0 [--check]" >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
    echo "Usage: $0 [--check]" >&2
    exit 2
fi

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SOURCE="$ROOT/.claude-plugin/marketplace.json"
TARGET="$ROOT/.agents/plugins/marketplace.json"
GENERATED=$(mktemp)
trap 'rm -f "$GENERATED"' EXIT HUP INT TERM

# Workspace sync accepts native URL sources, not Claude's github/repo form.
# Only emit documented native fields; keep source revision pins when present.
jq '
    # Native entry names must match the referenced package manifests. Keep
    # the established Claude/site catalog IDs through these two aliases.
    def codex_name:
        if .name == "jira-integration" then "jira"
        elif .name == "orocommerce" then "orocommerce-skills"
        else .name end;
    def codex_source:
        . as $source |
        (if .source == "github" and
                (.repo | type == "string" and test("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")) then
            {source: "url", url: ("https://github.com/" + .repo + ".git")}
        elif .source == "url" and
                (.url | type == "string" and test("^https://github\\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")) then
            {source: "url", url: .url}
        else
            error("Unsupported marketplace source: " + (. | tojson))
        end) + ($source | with_entries(select(.key == "ref" or .key == "sha")));
    {
        name: .name,
        interface: {displayName: "Netresearch Agent Skills"},
        plugins: [.plugins[] | {name: codex_name, source: (.source | codex_source), category}]
    }
    | if (.plugins | map(.name) | unique | length) != (.plugins | length) then
        error("Duplicate native plugin names after applying package-name aliases")
      else . end
' "$SOURCE" > "$GENERATED"

if [ "${1:-}" = --check ]; then
    if ! cmp -s "$GENERATED" "$TARGET"; then
        echo "Codex marketplace is missing or out of date. Run ./scripts/sync-codex-marketplace.sh" >&2
        exit 1
    fi
    echo "✓ Codex marketplace matches the Claude catalog"
else
    mkdir -p "$(dirname -- "$TARGET")"
    cp "$GENERATED" "$TARGET"
    echo "Generated .agents/plugins/marketplace.json"
fi
