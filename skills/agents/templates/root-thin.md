<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: {{TIMESTAMP}} -->

# AGENTS.md (root)

This file explains repo-wide conventions and where to find scoped rules.
**Precedence:** the **closest `AGENTS.md`** to the files you're changing wins. Root holds global defaults only.

## Global rules
- Keep diffs small; add tests for new code paths
- Ask first before: adding heavy deps, running full e2e suites, or repo-wide rewrites
- Never commit secrets or sensitive data to the repository
{{LANGUAGE_CONVENTIONS}}

## Minimal pre-commit checks
- Typecheck: {{TYPECHECK_CMD}}
- Lint/format: {{LINT_CMD}}{{FORMAT_CMD}}
- Tests: {{TEST_CMD}}

## Index of scoped AGENTS.md
{{SCOPE_INDEX}}

## When instructions conflict
- The nearest `AGENTS.md` wins. Explicit user prompts override files.
{{LANGUAGE_SPECIFIC_CONFLICT_RESOLUTION}}
