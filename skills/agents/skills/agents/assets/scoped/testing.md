<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: {{TIMESTAMP}} -->

# AGENTS.md — {{SCOPE_NAME}}

## Overview
{{SCOPE_DESCRIPTION}}

Test suites, fixtures, and testing utilities for the project.

## Setup & environment
- Install dev dependencies before running tests
- Some tests may require additional setup (see individual test files)
- Use the project's test framework consistently

## Running tests
- Run all tests: {{TEST_CMD}}
- Run specific test file: {{TEST_CMD}} <file>
- Run with coverage: {{TEST_CMD}} --coverage (if supported)
- Watch mode: {{TEST_CMD}} --watch (if supported)

## Test organization
- Group tests by feature or module
- Name test files to match source files (e.g., `foo_test.go`, `foo.test.ts`)
- Use descriptive test names that explain the expected behavior
- Keep fixtures and mocks in dedicated directories

## Code style & conventions
- One assertion per test when possible
- Use descriptive test names: `test_should_return_error_when_input_is_empty`
- Avoid testing implementation details; focus on behavior
- Keep tests independent - no shared mutable state
- Mock external dependencies (network, filesystem, time)
- Use table-driven tests for multiple similar cases

## Security & safety
- Never commit real credentials in test fixtures
- Use environment variables or mock services for sensitive data
- Sanitize any test data that might contain PII
- Ensure test databases are isolated from production

## PR/commit checklist
- [ ] All tests pass locally
- [ ] New functionality has corresponding tests
- [ ] Test names describe expected behavior
- [ ] No hardcoded credentials or sensitive data
- [ ] Mocks are appropriate and maintainable
- [ ] Coverage hasn't decreased significantly

## Good vs. bad examples
**Good**: Descriptive test name
```
test_should_return_validation_error_when_email_format_is_invalid
test_creates_user_with_valid_input
```

**Bad**: Vague test name
```
test_email
test_user_creation
test1
```

**Good**: Independent tests
```
func TestUserCreation(t *testing.T) {
    user := createTestUser()  // Fresh setup each test
    // assertions...
}
```

**Bad**: Shared state
```
var globalUser User  // Shared between tests - order-dependent!
```

## When stuck
- Check existing tests for patterns
- Review test framework documentation
- Ensure test isolation (no shared state)
- Check root AGENTS.md for project conventions

## House Rules (optional)
{{HOUSE_RULES}}
