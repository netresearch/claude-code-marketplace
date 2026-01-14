<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: {{TIMESTAMP}} -->

# AGENTS.md (root)

This file explains repo-wide conventions and where to find scoped rules.
**Precedence:** the **closest `AGENTS.md`** to the files you're changing wins. Root holds global defaults only.

## Global rules
- Keep diffs small; add tests for new code paths
{{LANGUAGE_CONVENTIONS}}

## Boundaries

### Always Do
- Run pre-commit checks before committing
- Add tests for new code paths
- Use conventional commit format (if established)

### Ask First
- Adding new dependencies
- Modifying CI/CD configuration
- Changing public API signatures
- Running full e2e test suites
- Repo-wide refactoring or rewrites

### Never Do
- Commit secrets, credentials, or sensitive data
- Modify vendor/, node_modules/, or generated files
- Push directly to main/master branch
- Delete migration files or schema changes
{{LANGUAGE_SPECIFIC_NEVER}}

## Minimal pre-commit checks
- Typecheck: {{TYPECHECK_CMD}}
- Lint/format: {{LINT_CMD}}{{FORMAT_CMD}}
- Tests: {{TEST_CMD}}

## Index of scoped AGENTS.md
{{SCOPE_INDEX}}

## Code examples
{{CODE_EXAMPLES}}

## When instructions conflict
- The nearest `AGENTS.md` wins. Explicit user prompts override files.
{{LANGUAGE_SPECIFIC_CONFLICT_RESOLUTION}}
