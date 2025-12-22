# Go Testing Patterns

## Test Pyramid

```
       E2E Tests (~5-30s)
         Complete scenarios
         Real infrastructure
         Slowest, most brittle

    Integration Tests (~1-5s)
       Real external deps
       Docker, databases
       Moderate speed

  Unit Tests (~<100ms)
     Mocked dependencies
     Fast, reliable
     Highest coverage
```

## Build Tags for Test Isolation

### Tag Convention

```go
// Unit tests - no tags, run by default
// File: job_test.go
package core

func TestJobValidation(t *testing.T) {
    // Fast, no external deps
}

// Integration tests - require real Docker
// File: docker_integration_test.go
//go:build integration

package core

func TestDockerExec(t *testing.T) {
    // Requires Docker daemon
}

// E2E tests - complete system
// File: workflow_e2e_test.go
//go:build e2e

package e2e

func TestFullWorkflow(t *testing.T) {
    // Start server, run jobs, verify
}
```

### Running Tests

```bash
# Unit tests only (CI default)
go test ./...

# With integration tests
go test -tags=integration ./...

# Full suite
go test -tags="integration e2e" ./...

# Specific package with tags
go test -tags=integration ./core/...
```

## Table-Driven Tests

### Basic Pattern

```go
func TestParseSchedule(t *testing.T) {
    tests := []struct {
        name     string
        input    string
        expected Schedule
        wantErr  bool
    }{
        {
            name:     "every minute",
            input:    "* * * * *",
            expected: Schedule{Minute: "*", Hour: "*", Day: "*", Month: "*", Weekday: "*"},
            wantErr:  false,
        },
        {
            name:     "specific time",
            input:    "30 9 * * 1-5",
            expected: Schedule{Minute: "30", Hour: "9", Day: "*", Month: "*", Weekday: "1-5"},
            wantErr:  false,
        },
        {
            name:    "invalid format",
            input:   "invalid",
            wantErr: true,
        },
        {
            name:    "too few fields",
            input:   "* * *",
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseSchedule(tt.input)

            if (err != nil) != tt.wantErr {
                t.Errorf("ParseSchedule() error = %v, wantErr %v", err, tt.wantErr)
                return
            }

            if !tt.wantErr && !reflect.DeepEqual(got, tt.expected) {
                t.Errorf("ParseSchedule() = %v, want %v", got, tt.expected)
            }
        })
    }
}
```

### Subtests with Setup/Teardown

```go
func TestJobExecution(t *testing.T) {
    // Shared setup
    logger := logrus.New()
    logger.SetOutput(io.Discard)

    tests := []struct {
        name    string
        job     Job
        setup   func()
        cleanup func()
        wantErr bool
    }{
        {
            name: "successful execution",
            job:  &LocalJob{Command: []string{"echo", "hello"}},
            setup: func() {
                // Optional per-test setup
            },
            wantErr: false,
        },
        {
            name:    "command not found",
            job:     &LocalJob{Command: []string{"nonexistent"}},
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            if tt.setup != nil {
                tt.setup()
            }
            if tt.cleanup != nil {
                defer tt.cleanup()
            }

            err := tt.job.Run(context.Background())
            if (err != nil) != tt.wantErr {
                t.Errorf("Job.Run() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

## Mocking Patterns

### Interface-Based Mocking

```go
// Define interface in consumer package
type DockerClient interface {
    ExecInContainer(ctx context.Context, containerID string, cmd []string) (string, string, error)
    RunContainer(ctx context.Context, image string, cmd []string) (string, error)
}

// Mock implementation for tests
type MockDockerClient struct {
    ExecFunc func(ctx context.Context, containerID string, cmd []string) (string, string, error)
    RunFunc  func(ctx context.Context, image string, cmd []string) (string, error)
}

func (m *MockDockerClient) ExecInContainer(ctx context.Context, containerID string, cmd []string) (string, string, error) {
    if m.ExecFunc != nil {
        return m.ExecFunc(ctx, containerID, cmd)
    }
    return "", "", nil
}

// Usage in tests
func TestExecJob(t *testing.T) {
    mock := &MockDockerClient{
        ExecFunc: func(ctx context.Context, containerID string, cmd []string) (string, string, error) {
            if containerID != "test-container" {
                return "", "", errors.New("container not found")
            }
            return "output", "", nil
        },
    }

    job := &ExecJob{
        Container: "test-container",
        Command:   []string{"ls", "-la"},
        Client:    mock,
    }

    err := job.Run(context.Background())
    if err != nil {
        t.Errorf("unexpected error: %v", err)
    }
}
```

### Using testify/mock

```go
import "github.com/stretchr/testify/mock"

type MockDockerClient struct {
    mock.Mock
}

func (m *MockDockerClient) ExecInContainer(ctx context.Context, containerID string, cmd []string) (string, string, error) {
    args := m.Called(ctx, containerID, cmd)
    return args.String(0), args.String(1), args.Error(2)
}

func TestWithTestify(t *testing.T) {
    mockClient := new(MockDockerClient)

    // Set expectations
    mockClient.On("ExecInContainer",
        mock.Anything,
        "container-123",
        []string{"ls"},
    ).Return("file1\nfile2", "", nil)

    job := &ExecJob{
        Container: "container-123",
        Command:   []string{"ls"},
        Client:    mockClient,
    }

    err := job.Run(context.Background())

    assert.NoError(t, err)
    mockClient.AssertExpectations(t)
}
```

## Time Control with FakeClock

Testing time-dependent code (schedulers, caches, rate limiters) is notoriously difficult. A Clock interface with FakeClock implementation enables instant, deterministic testing.

### Clock Interface

```go
// core/clock.go
package core

import (
    "sync"
    "time"
)

// Clock abstracts time operations for testability
type Clock interface {
    Now() time.Time
    NewTicker(d time.Duration) Ticker
    NewTimer(d time.Duration) Timer
    After(d time.Duration) <-chan time.Time
    Sleep(d time.Duration)
}

type Timer interface {
    C() <-chan time.Time
    Stop() bool
    Reset(d time.Duration) bool
}

type Ticker interface {
    C() <-chan time.Time
    Stop()
}

// RealClock wraps standard time package
type realClock struct{}

func NewRealClock() Clock { return &realClock{} }

func (c *realClock) Now() time.Time                         { return time.Now() }
func (c *realClock) NewTicker(d time.Duration) Ticker       { return &realTicker{time.NewTicker(d)} }
func (c *realClock) NewTimer(d time.Duration) Timer         { return &realTimer{time.NewTimer(d)} }
func (c *realClock) After(d time.Duration) <-chan time.Time { return time.After(d) }
func (c *realClock) Sleep(d time.Duration)                  { time.Sleep(d) }
```

### FakeClock Implementation

```go
// FakeClock allows instant time control in tests
type FakeClock struct {
    mu       sync.RWMutex
    now      time.Time
    tickers  []*fakeTicker
    timers   []*fakeTimer
    waiters  []waiter
}

func NewFakeClock(start time.Time) *FakeClock {
    return &FakeClock{now: start}
}

func (c *FakeClock) Now() time.Time {
    c.mu.RLock()
    defer c.mu.RUnlock()
    return c.now
}

// Advance moves time forward, firing any pending timers/tickers
func (c *FakeClock) Advance(d time.Duration) {
    c.mu.Lock()
    defer c.mu.Unlock()

    target := c.now.Add(d)
    for {
        earliest := c.findEarliestEvent()
        if earliest == nil || earliest.After(target) {
            c.now = target
            break
        }
        c.now = *earliest
        c.fireTickers()
        c.fireTimers()
        c.fireWaiters()
    }
}

// Set jumps to a specific time
func (c *FakeClock) Set(t time.Time) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.now = t
}
```

### Using FakeClock for Scheduler Testing

```go
func TestSchedulerExecutesJobsOnTime(t *testing.T) {
    // Create fake clock starting at a known time
    clock := NewFakeClock(time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC))

    // Inject clock into scheduler
    scheduler := NewScheduler(WithClock(clock))

    executed := false
    scheduler.AddJob("test", "*/5 * * * *", func() {
        executed = true
    })

    scheduler.Start()
    defer scheduler.Stop()

    // Advance time by 5 minutes - INSTANT, no waiting!
    clock.Advance(5 * time.Minute)

    // Job should have executed
    assert.True(t, executed)
}

func TestCacheExpiration(t *testing.T) {
    clock := NewFakeClock(time.Now())
    cache := NewCache(WithClock(clock), WithTTL(1*time.Hour))

    cache.Set("key", "value")
    assert.Equal(t, "value", cache.Get("key"))

    // Advance past TTL - instant!
    clock.Advance(2 * time.Hour)

    // Cache entry should be expired
    assert.Nil(t, cache.Get("key"))
}
```

### CronClock for go-cron Compatibility

When using libraries that expect specific timer interfaces (like go-cron):

```go
// CronClock wraps FakeClock with go-cron Timer interface
type CronClock struct {
    *FakeClock
}

func NewCronClock(start time.Time) *CronClock {
    return &CronClock{FakeClock: NewFakeClock(start)}
}

// NewTimer returns a timer compatible with go-cron
func (c *CronClock) NewTimer(d time.Duration) cron.Timer {
    return c.FakeClock.NewTimer(d)
}

// Usage with go-cron scheduler
func TestCronScheduler(t *testing.T) {
    clock := NewCronClock(time.Now())
    c := cron.New(cron.WithClock(clock))

    var runs int
    c.AddFunc("@every 1m", func() { runs++ })
    c.Start()

    // Advance 5 minutes instantly
    clock.Advance(5 * time.Minute)

    assert.Equal(t, 5, runs) // Ran 5 times
}
```

### Benefits

| Without FakeClock | With FakeClock |
|-------------------|----------------|
| `time.Sleep(5*time.Minute)` | `clock.Advance(5*time.Minute)` |
| Tests take minutes | Tests take milliseconds |
| Flaky due to timing | Deterministic |
| Can't test edge cases | Test any time scenario |

## Test Helpers

### Eventually Pattern (Recommended)

The Eventually pattern replaces brittle `time.Sleep`-based synchronization with event-driven waiting. This makes tests faster and more reliable.

**Why not `time.Sleep`?**
- Too short: flaky tests
- Too long: slow test suite
- Fixed delays don't adapt to system load

```go
// test/testutil/eventually.go
package testutil

import (
    "context"
    "testing"
    "time"
)

const (
    DefaultTimeout  = 5 * time.Second
    DefaultInterval = 50 * time.Millisecond
)

type config struct {
    timeout  time.Duration
    interval time.Duration
    message  string
}

type Option func(*config)

func WithTimeout(d time.Duration) Option {
    return func(c *config) { c.timeout = d }
}

func WithInterval(d time.Duration) Option {
    return func(c *config) { c.interval = d }
}

func WithMessage(msg string) Option {
    return func(c *config) { c.message = msg }
}

// Eventually polls a condition until true or timeout.
// Replaces time.Sleep with event-driven waiting.
func Eventually(t testing.TB, condition func() bool, opts ...Option) bool {
    t.Helper()

    cfg := &config{
        timeout:  DefaultTimeout,
        interval: DefaultInterval,
        message:  "condition was not satisfied",
    }
    for _, opt := range opts {
        opt(cfg)
    }

    ctx, cancel := context.WithTimeout(context.Background(), cfg.timeout)
    defer cancel()

    ticker := time.NewTicker(cfg.interval)
    defer ticker.Stop()

    // Check immediately first
    if condition() {
        return true
    }

    for {
        select {
        case <-ctx.Done():
            t.Errorf("Eventually timed out after %v: %s", cfg.timeout, cfg.message)
            return false
        case <-ticker.C:
            if condition() {
                return true
            }
        }
    }
}

// EventuallyWithT passes a collector for deferred assertions
func EventuallyWithT(t testing.TB, condition func(collect *T) bool, opts ...Option) bool {
    // Similar implementation with assertion collection
    // See full implementation in production code
}
```

### Using Eventually

```go
func TestServerStartup(t *testing.T) {
    server := startServer()
    defer server.Stop()

    // BAD: Fixed delay - too slow or flaky
    // time.Sleep(2 * time.Second)

    // GOOD: Event-driven - fast and reliable
    testutil.Eventually(t, func() bool {
        return server.IsReady()
    }, testutil.WithTimeout(5*time.Second),
       testutil.WithMessage("server failed to start"))
}

func TestJobCompletion(t *testing.T) {
    job := scheduler.Submit(myJob)

    testutil.Eventually(t, func() bool {
        return job.Status() == StatusComplete
    }, testutil.WithTimeout(10*time.Second),
       testutil.WithInterval(100*time.Millisecond))

    assert.Equal(t, "success", job.Result())
}
```

### Legacy Helpers

For simpler cases, these patterns still work:

```go
// TempDir creates a temp directory and returns cleanup function
func TempDir(t *testing.T) (string, func()) {
    t.Helper()
    dir, err := os.MkdirTemp("", "test-*")
    if err != nil {
        t.Fatalf("failed to create temp dir: %v", err)
    }
    return dir, func() { os.RemoveAll(dir) }
}
```

### Test Fixtures

```go
// test/fixtures/fixtures.go
package fixtures

import (
    "embed"
    "testing"
)

//go:embed *.json *.yaml
var testData embed.FS

func LoadFixture(t *testing.T, name string) []byte {
    t.Helper()
    data, err := testData.ReadFile(name)
    if err != nil {
        t.Fatalf("failed to load fixture %s: %v", name, err)
    }
    return data
}

// Usage:
// data := fixtures.LoadFixture(t, "valid_config.yaml")
```

## Integration Test Patterns

### Docker-Based Integration Tests

```go
//go:build integration

package core_test

import (
    "context"
    "testing"
    "time"
)

func TestDockerIntegration(t *testing.T) {
    // Skip if Docker not available
    client, err := NewOptimizedDockerClientFromEnv()
    if err != nil {
        t.Skip("Docker not available:", err)
    }

    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    // Ensure test image exists
    if err := client.EnsureImage(ctx, "alpine:latest"); err != nil {
        t.Fatalf("failed to pull image: %v", err)
    }

    t.Run("exec in container", func(t *testing.T) {
        // Create test container
        containerID, err := client.RunContainer(ctx, "alpine:latest", []string{"sleep", "60"}, nil)
        if err != nil {
            t.Fatalf("failed to create container: %v", err)
        }
        defer client.RemoveContainer(ctx, containerID, true)

        // Execute command
        stdout, _, err := client.ExecInContainer(ctx, containerID, []string{"echo", "hello"})
        if err != nil {
            t.Fatalf("exec failed: %v", err)
        }

        if stdout != "hello\n" {
            t.Errorf("unexpected output: %q", stdout)
        }
    })
}
```

## Coverage and Benchmarks

### Coverage

```bash
# Generate coverage profile
go test -coverprofile=coverage.out ./...

# View coverage by function
go tool cover -func=coverage.out

# HTML report
go tool cover -html=coverage.out -o coverage.html

# Coverage with build tags
go test -tags=integration -coverprofile=coverage.out ./...
```

### Benchmarks

```go
func BenchmarkJobExecution(b *testing.B) {
    job := &LocalJob{Command: []string{"true"}}
    ctx := context.Background()

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        job.Run(ctx)
    }
}

func BenchmarkParseSchedule(b *testing.B) {
    schedule := "*/5 * * * *"

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        ParseSchedule(schedule)
    }
}

// Run benchmarks
// go test -bench=. -benchmem ./...
```

## Test Configuration

### testdata Directory

```
package/
├── parser.go
├── parser_test.go
└── testdata/
    ├── valid_config.ini
    ├── invalid_config.ini
    └── complex_schedule.json
```

```go
func TestParseConfig(t *testing.T) {
    data, err := os.ReadFile("testdata/valid_config.ini")
    if err != nil {
        t.Fatalf("failed to read test data: %v", err)
    }

    config, err := ParseConfig(data)
    if err != nil {
        t.Fatalf("parse failed: %v", err)
    }

    // Assertions...
}
```

## Fuzz Testing (Go 1.18+)

Fuzz testing automatically generates inputs to find edge cases and crashes.

### Basic Fuzz Test

```go
func FuzzParseSchedule(f *testing.F) {
    // Seed corpus with known valid inputs
    f.Add("* * * * *")
    f.Add("0 0 1 1 *")
    f.Add("*/5 * * * *")
    f.Add("0 9 * * MON-FRI")

    f.Fuzz(func(t *testing.T, input string) {
        // Should not panic on any input
        result, err := ParseSchedule(input)

        // If no error, result should be usable
        if err == nil && result != nil {
            // Additional invariant checks
            _ = result.Next(time.Now())
        }
    })
}
```

### Running Fuzz Tests

```bash
# Run fuzz test for 30 seconds
go test -fuzz=FuzzParseSchedule -fuzztime=30s

# Run with specific corpus directory
go test -fuzz=FuzzParseSchedule -fuzztime=1m -test.fuzzcachedir=./testdata/fuzz

# Run all fuzz tests
go test -fuzz=. -fuzztime=30s ./...
```

### CI Configuration for Fuzz Testing

```yaml
# GitHub Actions
fuzz-testing:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-go@v5
      with:
        go-version: '1.22'
    - name: Fuzz Tests
      run: |
        go test -fuzz=. -fuzztime=60s ./...
```

### Best Practices

1. **Seed meaningful inputs**: Start with valid edge cases
2. **Check invariants**: Verify properties that should always hold
3. **Never crash**: Parser should never panic on malformed input
4. **Run in CI**: Short fuzz duration (30-60s) catches regressions

## Parallel Test Execution

Running tests in parallel dramatically speeds up test suites. Go's testing package supports this natively.

### Basic Parallel Pattern

```go
func TestParseConfig(t *testing.T) {
    t.Parallel() // Mark test as safe to run in parallel

    tests := []struct {
        name  string
        input string
        want  Config
    }{
        {"empty", "", Config{}},
        {"basic", "key=value", Config{Key: "value"}},
    }

    for _, tt := range tests {
        tt := tt // Capture range variable (required for parallel subtests)
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel() // Subtests can also be parallel

            got := ParseConfig(tt.input)
            assert.Equal(t, tt.want, got)
        })
    }
}
```

### When to Use t.Parallel()

| Use Parallel | Avoid Parallel |
|--------------|----------------|
| Pure functions | Shared mutable state |
| Independent tests | Tests that modify global vars |
| Table-driven tests | Tests using shared database |
| Read-only operations | Tests with port conflicts |

### Parallel with Shared Setup

```go
func TestWithSharedSetup(t *testing.T) {
    // Shared setup runs once before parallel tests
    server := startTestServer(t)
    t.Cleanup(func() { server.Stop() })

    tests := []struct {
        name     string
        endpoint string
        want     int
    }{
        {"health", "/health", 200},
        {"metrics", "/metrics", 200},
        {"invalid", "/notfound", 404},
    }

    for _, tt := range tests {
        tt := tt
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            resp := server.Get(tt.endpoint)
            assert.Equal(t, tt.want, resp.StatusCode)
        })
    }
}
```

### Controlling Parallelism

```bash
# Run with 4 parallel test processes
go test -parallel 4 ./...

# Run with parallelism matching CPU cores (default)
go test ./...

# Disable parallelism
go test -parallel 1 ./...
```

## Race Detection

Go's race detector finds data races at runtime. Essential for concurrent code.

### Running with Race Detection

```bash
# Run tests with race detector
go test -race ./...

# Build binary with race detection
go build -race ./cmd/app

# Run specific package
go test -race -v ./core/...
```

### Common Race Patterns and Fixes

**1. Unsynchronized map access:**

```go
// BAD: Race condition
type Cache struct {
    data map[string]string
}

func (c *Cache) Set(k, v string) { c.data[k] = v } // Race!
func (c *Cache) Get(k string) string { return c.data[k] } // Race!

// GOOD: Protected with mutex
type Cache struct {
    mu   sync.RWMutex
    data map[string]string
}

func (c *Cache) Set(k, v string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.data[k] = v
}

func (c *Cache) Get(k string) string {
    c.mu.RLock()
    defer c.mu.RUnlock()
    return c.data[k]
}
```

**2. Goroutine capturing loop variable:**

```go
// BAD: All goroutines see final value of i
for i := 0; i < 10; i++ {
    go func() {
        fmt.Println(i) // Race! Prints 10 ten times
    }()
}

// GOOD: Capture variable
for i := 0; i < 10; i++ {
    i := i // Shadow the variable
    go func() {
        fmt.Println(i) // Safe: each goroutine has its own copy
    }()
}

// GOOD: Pass as argument
for i := 0; i < 10; i++ {
    go func(n int) {
        fmt.Println(n)
    }(i)
}
```

**3. Check-then-act pattern:**

```go
// BAD: Race between check and update
if cache.Get(key) == nil {
    cache.Set(key, compute()) // Another goroutine might have set it!
}

// GOOD: Atomic operation
value := cache.GetOrSet(key, func() string {
    return compute()
})
```

### CI Integration

```yaml
# GitHub Actions - always run with race detector
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-go@v5
    - run: go test -race -v ./...
```

## Mutation Testing

Mutation testing validates test quality by introducing bugs and checking if tests catch them.

### Using gremlins (Recommended)

[gremlins](https://github.com/go-gremlins/gremlins) is a modern, fast mutation testing tool for Go.

```bash
# Install
go install github.com/go-gremlins/gremlins/cmd/gremlins@latest

# Run mutation testing
gremlins unleash ./...

# With configuration file
gremlins unleash --config .gremlins.yaml ./...
```

### Configuration (.gremlins.yaml)

```yaml
# .gremlins.yaml
timeout: 10        # Seconds per mutation test
workers: 4         # Parallel workers
threshold: 0.7     # Minimum mutation score (0.0-1.0)
exclude:
  - "**/*_test.go"
  - "**/testdata/**"
  - "**/mock/**"
```

### CI Integration

```yaml
# GitHub Actions
mutation-testing:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-go@v5
    - name: Install gremlins
      run: go install github.com/go-gremlins/gremlins/cmd/gremlins@latest
    - name: Run mutation tests
      run: gremlins unleash --threshold 0.7 ./...
```

### Alternative: go-mutesting

```bash
# Install
go install github.com/zimmski/go-mutesting/cmd/go-mutesting@latest

# Run mutation testing
go-mutesting ./...

# With specific mutators
go-mutesting --mutator=branch ./...
```

### Common Mutators

| Mutator | What It Does | Example |
|---------|-------------|---------|
| `branch` | Removes branches | `if x > 0` → ` ` |
| `expression` | Modifies operators | `a + b` → `a - b` |
| `statement` | Removes statements | Deletes return statements |

### Interpreting Results

```
Mutation Score: 85% (68/80 mutations killed)

Survived mutations:
  - parser.go:45 removed branch (if err != nil)
  - validate.go:78 changed == to !=
```

**Target**: 70%+ mutation score indicates robust tests. 80%+ is excellent.

### Boundary Condition Testing

Mutation testing often reveals missing boundary tests:

```go
// Original code
func isValidMinute(m int) bool {
    return m >= 0 && m <= 59
}

// Mutations that might survive:
// - m >= 0 → m > 0    (boundary at 0)
// - m <= 59 → m < 59  (boundary at 59)

// Tests needed to kill mutations:
func TestIsValidMinute(t *testing.T) {
    tests := []struct {
        input int
        want  bool
    }{
        {-1, false},   // Below range
        {0, true},     // Lower boundary (kills >= → >)
        {30, true},    // Middle
        {59, true},    // Upper boundary (kills <= → <)
        {60, false},   // Above range
    }
    // ...
}
```

## Makefile Integration

```makefile
.PHONY: test test-race test-cover test-integration test-e2e test-fuzz test-mutation test-all

# Fast unit tests (default)
test:
	go test -v ./...

# Unit tests with race detector (CI default)
test-race:
	go test -race -v ./...

# Parallel tests with higher parallelism
test-parallel:
	go test -v -parallel 8 ./...

# Coverage report
test-cover:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

# Integration tests (require Docker, etc.)
test-integration:
	go test -v -tags=integration ./...

# E2E tests (complete system)
test-e2e:
	go test -v -tags=e2e ./...

# Fuzz testing (30 seconds per target)
test-fuzz:
	go test -fuzz=. -fuzztime=30s ./...

# Mutation testing with gremlins (recommended)
test-mutation:
	gremlins unleash --threshold 0.7 ./...

# Legacy mutation testing with go-mutesting
test-mutation-legacy:
	go-mutesting ./...

# Full test suite with all quality checks
test-all:
	go test -v -tags="integration e2e" -race -parallel 4 ./...
```
