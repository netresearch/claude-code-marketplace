---
name: go-development
description: "Production-grade Go development patterns for building resilient services. Use when developing Go applications, implementing job schedulers, Docker integrations, LDAP clients, or needing patterns for resilience, testing, and performance optimization. Covers architecture patterns, middleware chains, buffer pooling, graceful shutdown, and comprehensive testing strategies. By Netresearch."
---

# Go Development Patterns

This skill provides production-grade patterns for Go application development, extracted from real-world projects including job schedulers, Docker integrations, and LDAP clients.

## When to Use

- Building Go services or CLI applications
- Implementing job scheduling or task orchestration
- Integrating with Docker API
- Building LDAP/Active Directory clients
- Designing resilient systems with retry logic
- Setting up comprehensive test suites

## Core Principles

### Type Safety is Non-Negotiable

**Type safety is a MUST-HAVE requirement.** Go's compile-time type checking is one of its greatest strengths. Never sacrifice it for convenience.

**Avoid:**
- `interface{}` / `any` when concrete types are possible
- `sync.Map` when a typed map with mutex works
- Type assertions scattered throughout code
- Reflection-heavy designs

**Prefer:**
- Generics (`[T any]`) for type-safe reusable code
- Concrete types with explicit interfaces
- Compile-time verification over runtime checks

```go
// BAD: Lost type safety
var cache sync.Map
cache.Store("key", value)
v, _ := cache.Load("key")
item := v.(*MyType)  // Runtime assertion - can panic!

// GOOD: Type-safe with generics
type Cache[T any] struct {
    mu    sync.RWMutex
    items map[string]T
}

func (c *Cache[T]) Get(key string) (T, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    v, ok := c.items[key]
    return v, ok  // Compile-time type safety
}
```

### Consistency is Critical

**Architectural consistency is VERY IMPORTANT.** A codebase should follow consistent patterns throughout. Mixed approaches create confusion and bugs.

**Rules:**
1. **One pattern per problem domain**: If using channels for synchronization, use channels everywhere for that purpose
2. **Match existing patterns**: New code should follow established conventions in the codebase
3. **Refactor holistically**: When changing a pattern, change it everywhere or don't change it at all

**Example - Concurrency patterns:**
```go
// If your codebase uses channels for coordination:
type Scheduler struct {
    add      chan *Entry      // Channel-based
    remove   chan EntryID     // Channel-based
    snapshot chan chan []Entry // Channel-based
    // DON'T mix in sync.Map or other patterns!
}

// Consistency means predictable behavior and easier debugging
```

**Why consistency matters:**
- Reduces cognitive load for maintainers
- Makes code review more effective
- Prevents subtle bugs from pattern mismatches
- Enables better tooling and static analysis

## Architecture Patterns

### Package Structure

**Reference:** `references/architecture.md`

Recommended layout for Go services:

```
project/
├── cmd/              # Entry points (main packages)
├── core/             # Core business logic, domain types
├── cli/              # CLI commands, configuration
├── web/              # HTTP handlers, middleware
├── config/           # Configuration management
├── metrics/          # Observability (Prometheus, logging)
└── internal/         # Private packages
```

### Job Abstraction Hierarchy

For task/job scheduling systems:

```
BareJob (interface)
├── Common: Name, Schedule, Command
└── Implementations:
    ├── ExecJob      (execute in running container)
    ├── RunJob       (new container from image)
    ├── LocalJob     (host system execution)
    └── ServiceJob   (orchestrator service)

ResilientJob (wrapper)
└── Adds retry logic, error handling
```

### Configuration Management

**Reference:** `references/architecture.md`

5-layer precedence pattern:

1. Built-in defaults (hardcoded)
2. Configuration file (INI, YAML, TOML)
3. External source (Docker labels, K8s annotations)
4. Command-line flags
5. Environment variables (highest priority)

```go
type Config struct {
    LogLevel    string `default:"info" env:"LOG_LEVEL" flag:"log-level"`
    ConfigFile  string `default:"/etc/app/config.ini" flag:"config"`
    // ...
}
```

### Middleware Chain Pattern

**Reference:** `references/architecture.md`

```
Request/Job Execution
├── Pre-execution middleware (logging, validation)
├── Execute core logic
├── Capture output (stdout/stderr)
├── Post-execution middleware (metrics, notifications)
└── Results to:
    ├── Notification middleware (Slack, email)
    ├── Metrics middleware (Prometheus)
    └── Persistence middleware (file reports)
```

## Resilience Patterns

**Reference:** `references/resilience.md`

### Retry Logic

```go
type RetryConfig struct {
    MaxAttempts     int
    InitialDelay    time.Duration
    MaxDelay        time.Duration
    BackoffFactor   float64
}

func WithRetry(fn func() error, cfg RetryConfig) error {
    delay := cfg.InitialDelay
    for attempt := 1; attempt <= cfg.MaxAttempts; attempt++ {
        if err := fn(); err == nil {
            return nil
        }
        if attempt < cfg.MaxAttempts {
            time.Sleep(delay)
            delay = time.Duration(float64(delay) * cfg.BackoffFactor)
            if delay > cfg.MaxDelay {
                delay = cfg.MaxDelay
            }
        }
    }
    return fmt.Errorf("failed after %d attempts", cfg.MaxAttempts)
}
```

### Graceful Shutdown

```go
func GracefulShutdown(ctx context.Context, timeout time.Duration, cleanup func()) {
    sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, syscall.SIGTERM, syscall.SIGINT)

    select {
    case <-sigChan:
        log.Info("Shutdown signal received")
    case <-ctx.Done():
        log.Info("Context cancelled")
    }

    shutdownCtx, cancel := context.WithTimeout(context.Background(), timeout)
    defer cancel()

    done := make(chan struct{})
    go func() {
        cleanup()
        close(done)
    }()

    select {
    case <-done:
        log.Info("Graceful shutdown complete")
    case <-shutdownCtx.Done():
        log.Warn("Shutdown timeout exceeded")
    }
}
```

### Context Propagation

Always propagate context for cancellation:

```go
func (j *Job) Run(ctx context.Context) error {
    // Check cancellation before expensive operations
    select {
    case <-ctx.Done():
        return ctx.Err()
    default:
    }

    // Execute with context
    return j.execute(ctx)
}
```

## Docker Integration

**Reference:** `references/docker.md`

### Optimized Client Pattern

```go
type OptimizedDockerClient struct {
    client     *docker.Client
    bufferPool *sync.Pool
    mu         sync.RWMutex
}

func NewOptimizedClient() (*OptimizedDockerClient, error) {
    client, err := docker.NewClientFromEnv()
    if err != nil {
        return nil, err
    }

    return &OptimizedDockerClient{
        client: client,
        bufferPool: &sync.Pool{
            New: func() interface{} {
                return NewCircularBuffer(64 * 1024) // 64KB buffers
            },
        },
    }, nil
}
```

### Buffer Pooling

Reduce GC pressure for high-throughput operations:

```go
func (c *OptimizedDockerClient) ExecInContainer(ctx context.Context, containerID string, cmd []string) (string, error) {
    buf := c.bufferPool.Get().(*CircularBuffer)
    defer func() {
        buf.Reset()
        c.bufferPool.Put(buf)
    }()

    // Execute and capture to pooled buffer
    exec, err := c.client.CreateExec(docker.CreateExecOptions{
        Container:    containerID,
        Cmd:          cmd,
        AttachStdout: true,
        AttachStderr: true,
    })
    // ...
}
```

## LDAP Integration

**Reference:** `references/ldap.md`

### Active Directory Patterns

```go
type LDAPClient struct {
    conn       *ldap.Conn
    baseDN     string
    userFilter string
}

func (c *LDAPClient) FindUserBySAM(samAccountName string) (*User, error) {
    filter := fmt.Sprintf("(&(objectClass=user)(sAMAccountName=%s))",
        ldap.EscapeFilter(samAccountName))

    result, err := c.conn.Search(&ldap.SearchRequest{
        BaseDN:     c.baseDN,
        Scope:      ldap.ScopeWholeSubtree,
        Filter:     filter,
        Attributes: []string{"cn", "mail", "memberOf", "distinguishedName"},
    })
    // ...
}
```

## Testing Strategy

**Reference:** `references/testing.md`

### Test Pyramid

```
       E2E Tests (~5-30s)        # Complete scenarios
    Integration Tests (~1-5s)    # Real external deps
  Unit Tests (~<100ms)           # Mocked deps, fast
```

### Build Tags for Test Isolation

```go
// Unit tests (no tags) - run by default
func TestJobValidation(t *testing.T) { ... }

//go:build integration
// Integration tests - require real Docker
func TestDockerExec(t *testing.T) { ... }

//go:build e2e
// E2E tests - complete system
func TestFullWorkflow(t *testing.T) { ... }
```

### Testify Best Practices

Use `stretchr/testify` for readable assertions:

```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestUserValidation(t *testing.T) {
    t.Parallel()  // Enable parallel execution

    user := NewUser("test@example.com")

    // Use assert for non-fatal checks
    assert.NotNil(t, user)
    assert.Equal(t, "test@example.com", user.Email)

    // Use require for fatal checks (stops test on failure)
    require.NoError(t, user.Validate())

    // Use specific assertions for better error messages
    assert.Empty(t, user.Errors)           // NOT: assert.Equal(t, "", ...)
    assert.True(t, user.IsActive)          // NOT: assert.Equal(t, true, ...)
    assert.Nil(t, user.DeletedAt)          // NOT: assert.Equal(t, nil, ...)
    assert.Len(t, user.Roles, 2)           // NOT: assert.Equal(t, 2, len(...))
    assert.Contains(t, user.Roles, "admin")
}
```

### Parallel Test Considerations

```go
// Tests that CAN run in parallel
func TestPureFunction(t *testing.T) {
    t.Parallel()  // Safe - no shared state
    // ...
}

// Tests that CANNOT run in parallel (global state)
//nolint:paralleltest // Tests modify global logrus state and cannot run in parallel
func TestBuildLogger_ValidLevels(t *testing.T) {
    // Modifies global logger - NOT parallel safe
    logrus.SetLevel(logrus.DebugLevel)
    // ...
}

// Tests that modify global variables
//nolint:paralleltest // Modifies global newDockerHandler
func TestBootLogsConfigError(t *testing.T) {
    orig := newDockerHandler
    defer func() { newDockerHandler = orig }()
    // ...
}
```

### Modern Go Syntax (1.22+)

```go
// Go 1.22+ integer range syntax
for range 5 {  // Instead of: for i := 0; i < 5; i++
    doSomething()
}

// With index when needed
for i := range 5 {
    doSomethingWith(i)
}

// Range over function (Go 1.23+)
for item := range iter.Seq(items) {
    process(item)
}
```

### HTTP Test Patterns

```go
func TestAPIEndpoint(t *testing.T) {
    t.Parallel()

    // Use http.Method* constants
    req := httptest.NewRequest(http.MethodPost, "/api/users", body)  // NOT: "POST"
    req.Header.Set("Content-Type", "application/json")

    rec := httptest.NewRecorder()
    handler.ServeHTTP(rec, req)

    assert.Equal(t, http.StatusCreated, rec.Code)  // NOT: 201
}
```

### Common Linter Directives

```go
//nolint:paralleltest    // Test cannot run in parallel (modifies global state)
//nolint:tparallel       // Subtests cannot run in parallel
//nolint:testifylint     // Disable testify-specific checks (use sparingly)
//nolint:gosec           // Security check false positive (document why)
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

### Table-Driven Tests

```go
func TestScheduleParsing(t *testing.T) {
    tests := []struct {
        name     string
        input    string
        expected Schedule
        wantErr  bool
    }{
        {"every minute", "* * * * *", Schedule{...}, false},
        {"invalid", "invalid", Schedule{}, true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseSchedule(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
            }
            if !tt.wantErr && !reflect.DeepEqual(got, tt.expected) {
                t.Errorf("got %v, want %v", got, tt.expected)
            }
        })
    }
}
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

### Pre-commit Hooks (lefthook)

```yaml
# .lefthook.yml
pre-commit:
  parallel: true
  commands:
    fmt:
      run: gofmt -l . | grep -q . && exit 1 || exit 0
    vet:
      run: go vet ./...
    lint:
      run: golangci-lint run --new-from-rev=HEAD~1
```

## Performance Optimization

### Key Patterns

1. **Buffer Pooling**: Reuse allocations with `sync.Pool`
2. **Connection Reuse**: Single client instance, connection pooling
3. **Lazy Initialization**: Initialize resources on first use
4. **Context Deadlines**: Prevent runaway operations

### Metrics Integration

```go
import "github.com/prometheus/client_golang/prometheus"

var (
    jobDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "job_duration_seconds",
            Help:    "Job execution duration",
            Buckets: prometheus.DefBuckets,
        },
        []string{"job_name", "status"},
    )
)

func (j *Job) Run(ctx context.Context) error {
    timer := prometheus.NewTimer(prometheus.ObserverFunc(func(v float64) {
        jobDuration.WithLabelValues(j.Name, "success").Observe(v)
    }))
    defer timer.ObserveDuration()
    // ...
}
```

## Code Quality & Linting

**Reference:** `references/linting.md`

### Key Conventions

```go
// ST1005: Error strings must be lowercase, no punctuation
return errors.New("invalid input")           // GOOD
return errors.New("Invalid input.")          // BAD

// gosec G104: Explicitly ignore known-nil errors
_, _ = hash.Write(data)  // hash.Hash.Write never errors

// Naming: Use ID, URL, HTTP (not Id, Url, Http)
var userID string        // GOOD
var userId string        // BAD (ST1003)
```

### golangci-lint v2

See `references/linting.md` for complete configuration including:
- Linter selection by category (bugs, security, style, performance)
- Exclusion patterns for complex functions
- Common fixes for staticcheck/revive

## API Design Patterns

**Reference:** `references/api-design.md`

### Bitmask Options

```go
type ParseOption int

const (
    Second    ParseOption = 1 << iota
    Minute
    Hour
    Descriptor
    Hash
)

// Usage: parser := NewParser(Minute | Hour | Descriptor | Hash)
```

### Functional Options

```go
func WithTimeout(d time.Duration) Option {
    return func(c *Config) { c.timeout = d }
}

// Usage: NewParser(WithTimeout(30*time.Second), WithHash("key"))
```

## Error Handling Best Practices

```go
// Wrap errors with context
if err := doSomething(); err != nil {
    return fmt.Errorf("failed to do something: %w", err)
}

// Check specific error types
if errors.Is(err, context.DeadlineExceeded) {
    // Handle timeout
}

// Custom error types for domain errors
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed for %s: %s", e.Field, e.Message)
}
```

## Resources

- `references/architecture.md` - Package structure, patterns
- `references/resilience.md` - Retry, shutdown, recovery
- `references/docker.md` - Docker client patterns
- `references/ldap.md` - LDAP/Active Directory integration
- `references/testing.md` - Test strategies, fuzz testing, mutation testing
- `references/linting.md` - golangci-lint v2, staticcheck, code quality
- `references/api-design.md` - Bitmask options, functional options, builders
