<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: {{TIMESTAMP}} -->

# AGENTS.md (root)

**Precedence:** The **closest AGENTS.md** to changed files wins. Root holds global defaults only.

## Project Overview
{{PROJECT_DESCRIPTION}}

**Tech Stack**: {{LANGUAGE}} {{VERSION}}, {{BUILD_TOOL}}, {{FRAMEWORK}}
**Type**: {{PROJECT_TYPE}}

## Global Rules
- Keep PRs small (~≤300 net LOC)
- Conventional Commits: `type(scope): subject`
{{LANGUAGE_CONVENTIONS}}

## Boundaries

### Always Do
- Run pre-commit checks before committing
- Add tests for new code paths
- Use conventional commit format: `type(scope): subject`
- Keep dependencies updated
- Validate all user inputs

### Ask First
- Adding new dependencies
- Modifying CI/CD configuration
- Changing public API signatures
- Running full e2e test suites
- Repo-wide refactoring or rewrites
- Modifying security-sensitive code
- Changing database schemas

### Never Do
- Commit secrets, credentials, API keys, or PII
- Modify vendor/, node_modules/, or generated files
- Push directly to main/master branch
- Delete migration files or schema changes
- Disable security features or linting rules
- Hardcode environment-specific values
{{LANGUAGE_SPECIFIC_NEVER}}

## Development Workflow
1. Create feature branch: `git checkout -b feature/description`
2. Make changes with tests
3. Run pre-commit checks (see below)
4. Commit with conventional format
5. Push and create PR
6. Address review feedback
7. Merge when approved

## Pre-commit Checks
**Always run before committing:**
- Typecheck: {{TYPECHECK_CMD}}
- Lint: {{LINT_CMD}}
- Format: {{FORMAT_CMD}}
- Tests: {{TEST_CMD}}
- Build: {{BUILD_CMD}}

## Code Quality Standards
{{QUALITY_STANDARDS}}

## Security & Safety
- Never commit secrets, credentials, or PII
- Validate all user inputs
- Use parameterized queries for database access
- Keep dependencies updated
{{SECURITY_SPECIFIC}}

## Testing Requirements
- Write tests for new features
- Maintain {{TEST_COVERAGE}}% minimum coverage
- Run fast tests locally: {{TEST_FAST_CMD}}
- Run full suite in CI: {{TEST_FULL_CMD}}

## Index of Scoped AGENTS.md
{{SCOPE_INDEX}}

## When Instructions Conflict
Nearest AGENTS.md wins. User prompts override files.
{{LANGUAGE_SPECIFIC_CONFLICT_RESOLUTION}}

## Code Examples

### Good Pattern
{{GOOD_EXAMPLE}}

### Avoid
{{BAD_EXAMPLE}}

## Documentation
- Architecture: {{ARCHITECTURE_DOC}}
- API docs: {{API_DOC}}
- Contributing: {{CONTRIBUTING_DOC}}
