<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: 2025-09-29 -->

# AGENTS.md — Examples

## Overview
Example applications demonstrating library usage patterns for authentication, user management, performance optimization, context handling, and error patterns. Entry points are the main.go files in each subdirectory.

## Setup & environment
- Install: `go mod download`
- Run example: `go run examples/<name>/main.go`
- Env: Examples use environment variables from `.env` files when present

## Build & tests (prefer file-scoped)
- Typecheck a file: `go build -v examples/<name>/main.go`
- Format a file: `gofmt -w examples/<name>/main.go`
- Run example: `go run examples/<name>/main.go`

## Code style & conventions
- Examples should be self-contained and runnable
- Use clear variable names that explain the concept
- Include comments explaining non-obvious patterns
- Error handling should demonstrate best practices
- Keep examples focused on a single concept

## Security & safety
- Never include real credentials in examples
- Use placeholder values like "ldap.example.com"
- Document required permissions clearly
- Examples should fail gracefully without real LDAP server

## PR/commit checklist
- Examples must compile without errors
- Include README.md explaining the example's purpose
- Test example with both real and mock LDAP servers if possible
- Ensure examples follow library best practices

## Good vs. bad examples
- Good: `authentication/main.go` (clear flow, error handling)
- Good: `context-usage/main.go` (proper context propagation)
- Pattern to follow: Simple, focused, well-commented demonstrations

## When stuck
- Check the main library documentation in ../docs/
- Review similar examples in sibling directories
- Ensure you have the latest library version