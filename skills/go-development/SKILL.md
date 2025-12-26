---
name: go-development
description: "Production-grade Go development patterns for building resilient services. Use when developing Go applications, implementing job schedulers, Docker integrations, LDAP clients, or needing patterns for resilience, testing, and performance optimization. By Netresearch."
---

# Go Development Patterns

## When to Use

- Building Go services or CLI applications
- Implementing job scheduling or task orchestration
- Integrating with Docker API
- Building LDAP/Active Directory clients
- Designing resilient systems with retry logic
- Setting up comprehensive test suites

## Core Principles

### Type Safety is Non-Negotiable

- **Avoid:** `interface{}`, `sync.Map`, scattered type assertions, reflection
- **Prefer:** Generics `[T any]`, concrete types, compile-time verification

### Consistency is Critical

- One pattern per problem domain
- Match existing codebase patterns
- Refactor holistically or not at all

## References

| Reference | Purpose |
|-----------|---------|
| `references/architecture.md` | Package structure, config management, middleware chains |
| `references/resilience.md` | Retry logic, graceful shutdown, context propagation |
| `references/docker.md` | Docker client patterns, buffer pooling |
| `references/ldap.md` | LDAP/Active Directory integration |
| `references/testing.md` | Test strategies, build tags, table-driven tests |
| `references/linting.md` | golangci-lint v2, staticcheck, code quality |
| `references/api-design.md` | Bitmask options, functional options, builders |
| `references/fuzz-testing.md` | Go fuzzing patterns, security seeds |
| `references/mutation-testing.md` | Gremlins configuration, test quality measurement |
| `references/makefile.md` | Standard Makefile interface for CI/CD |

## Package Structure

```
project/
├── cmd/       # Entry points (main packages)
├── core/      # Core business logic, domain types
├── cli/       # CLI commands, configuration
├── web/       # HTTP handlers, middleware
├── config/    # Configuration management
├── metrics/   # Observability (Prometheus, logging)
└── internal/  # Private packages
```

## Testing Quick Reference

```bash
# Unit tests
go test ./...

# With integration tests
go test -tags=integration ./...

# With race detector
go test -race ./...

# With coverage
go test -coverprofile=coverage.out ./...
```

### Build Tags

```go
// Unit (default)
func TestValidation(t *testing.T) { ... }

//go:build integration
func TestDockerExec(t *testing.T) { ... }

//go:build e2e
func TestFullWorkflow(t *testing.T) { ... }
```

## Quality Gates

```makefile
.PHONY: dev-check
dev-check: fmt vet lint security test

lint:
	golangci-lint run --timeout 5m

security:
	gosec ./...
	gitleaks detect
```

## Key Conventions

```go
// Errors: lowercase, no punctuation
return errors.New("invalid input")

// Naming: ID, URL, HTTP (not Id, Url, Http)
var userID string

// Error wrapping
return fmt.Errorf("failed to process: %w", err)
```

See reference files for complete patterns and examples.

## Related Skills

This skill is the primary entry point for Go development. For complete project setup, coordinate with:

| Task | Skill |
|------|-------|
| Repository setup, branch protection, auto-merge | `github-project` |
| OpenSSF Scorecard, SLSA provenance, signed releases | `enterprise-readiness` |
| Security audits (OWASP, CVE analysis) | `security-audit` |

### Workflow

```
go-development (this skill)
├── Code quality: linting, testing, fuzzing
├── Standard Makefile: test, build, lint, fuzz
└── Delegates to:
    ├── github-project → repo setup, CI workflows, branch protection
    └── enterprise-readiness → supply chain security, SLSA, signing
```

---

> **Contributing:** Improvements to this skill should be submitted to the source repository:
> https://github.com/netresearch/go-development-skill
