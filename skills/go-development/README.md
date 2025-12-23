# Go Development Skill

Production-grade Go development patterns for building resilient services, extracted from real-world projects including job schedulers, Docker integrations, and LDAP clients.

## 🔌 Compatibility

This is an **Agent Skill** following the [open standard](https://agentskills.io) originally developed by Anthropic and released for cross-platform use.

**Supported Platforms:**
- ✅ Claude Code (Anthropic)
- ✅ Cursor
- ✅ GitHub Copilot
- ✅ Other skills-compatible AI agents

> Skills are portable packages of procedural knowledge that work across any AI agent supporting the Agent Skills specification.


## Features

- **Architecture Patterns**: Package structure best practices, job abstraction hierarchy, configuration management (5-layer precedence), middleware chain pattern
- **Resilience Patterns**: Retry logic with exponential backoff, graceful shutdown, context propagation, error handling strategies
- **Docker Integration**: Optimized Docker client patterns, buffer pooling for performance, container execution patterns
- **LDAP Integration**: Active Directory patterns, user and group management, authentication flows
- **Testing Strategy**: Test pyramid (unit/integration/e2e), build tags for test isolation, table-driven tests, comprehensive coverage
- **Performance Optimization**: Buffer pooling, connection reuse, lazy initialization, context deadlines
- **Observability**: Prometheus metrics integration, structured logging, error tracking

## Installation

### Option 1: Via Netresearch Marketplace (Recommended)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

### Option 2: Download Release

Download the [latest release](https://github.com/netresearch/go-development-skill/releases/latest) and extract to `~/.claude/skills/go-development-skill/`

## Usage

This skill is automatically triggered when:

- Building Go services or CLI applications
- Implementing job scheduling or task orchestration
- Integrating with Docker API
- Building LDAP/Active Directory clients
- Designing resilient systems with retry logic
- Setting up comprehensive test suites
- Implementing middleware patterns
- Optimizing Go application performance

Example queries:
- "Create a resilient job scheduler in Go"
- "Implement Docker container execution with retry logic"
- "Build LDAP authentication client"
- "Set up graceful shutdown for Go service"
- "Implement buffer pooling for high-throughput operations"
- "Create comprehensive test suite with build tags"

## Structure

```
go-development-skill/
├── SKILL.md                              # Skill metadata and core patterns
└── references/
    ├── architecture.md                   # Package structure, patterns
    ├── resilience.md                     # Retry, shutdown, recovery
    ├── docker.md                         # Docker client patterns
    ├── ldap.md                           # LDAP/Active Directory integration
    └── testing.md                        # Test strategies and patterns
```

## Expertise Areas

### Architecture Patterns
- Package structure best practices
- Job abstraction hierarchy
- Configuration management (5-layer precedence)
- Middleware chain pattern

### Resilience Patterns
- Retry logic with exponential backoff
- Graceful shutdown
- Context propagation
- Error handling strategies

### Docker Integration
- Optimized Docker client patterns
- Buffer pooling for performance
- Container execution patterns

### LDAP Integration
- Active Directory patterns
- User and group management
- Authentication flows

### Testing Strategy
- Test pyramid (unit/integration/e2e)
- Build tags for test isolation
- Table-driven tests
- Comprehensive coverage

## Configuration Management

5-layer precedence pattern (highest priority last):

1. Built-in defaults (hardcoded)
2. Configuration file (INI, YAML, TOML)
3. External source (Docker labels, K8s annotations)
4. Command-line flags
5. Environment variables (highest priority)

## Testing Pyramid

```
       E2E Tests (~5-30s)        # Complete scenarios
    Integration Tests (~1-5s)    # Real external deps
  Unit Tests (~<100ms)           # Mocked deps, fast
```

### Running Tests

```bash
# Unit tests only (default)
go test ./...

# With integration tests
go test -tags=integration ./...

# Full suite including E2E
go test -tags=e2e ./...

# With race detector
go test -race ./...

# With coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## Quality Gates

### Recommended Tooling

```makefile
.PHONY: dev-check
dev-check: fmt vet lint security test

fmt:
	gofmt -w $(shell git ls-files '*.go')
	gci write .

vet:
	go vet ./...

lint:
	golangci-lint run --timeout 5m

security:
	gosec ./...
	gitleaks detect

test:
	go test -race ./...
```

## Performance Optimization

### Key Patterns

1. **Buffer Pooling**: Reuse allocations with `sync.Pool`
2. **Connection Reuse**: Single client instance, connection pooling
3. **Lazy Initialization**: Initialize resources on first use
4. **Context Deadlines**: Prevent runaway operations

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

Developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/).

---

**Made with ❤️ for Open Source by [Netresearch](https://www.netresearch.de/)**
