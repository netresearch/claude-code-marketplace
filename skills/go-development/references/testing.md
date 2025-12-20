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

## Test Helpers

### Common Helpers

```go
// test/helpers.go
package test

import (
    "testing"
    "time"
)

// WaitFor waits for condition to be true
func WaitFor(t *testing.T, timeout time.Duration, condition func() bool) {
    t.Helper()
    deadline := time.Now().Add(timeout)
    for time.Now().Before(deadline) {
        if condition() {
            return
        }
        time.Sleep(100 * time.Millisecond)
    }
    t.Fatal("timeout waiting for condition")
}

// AssertEventually asserts condition becomes true within timeout
func AssertEventually(t *testing.T, timeout time.Duration, fn func() bool, msg string) {
    t.Helper()
    deadline := time.Now().Add(timeout)
    for time.Now().Before(deadline) {
        if fn() {
            return
        }
        time.Sleep(50 * time.Millisecond)
    }
    t.Fatalf("assertion failed: %s", msg)
}

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

## Mutation Testing

Mutation testing validates test quality by introducing bugs and checking if tests catch them.

### Using go-mutesting

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

**Target**: 80%+ mutation score indicates robust tests.

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
.PHONY: test test-race test-cover test-integration test-e2e test-fuzz test-mutation

test:
	go test -v ./...

test-race:
	go test -race -v ./...

test-cover:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

test-integration:
	go test -v -tags=integration ./...

test-e2e:
	go test -v -tags=e2e ./...

test-fuzz:
	go test -fuzz=. -fuzztime=30s ./...

test-mutation:
	go-mutesting ./...

test-all:
	go test -v -tags="integration e2e" -race ./...
```
