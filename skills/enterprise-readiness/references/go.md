# Go-Specific Enterprise Readiness Checks

Checks specific to Go projects and the Go ecosystem.

## Build Reproducibility (10 points)

### Static Binaries (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| CGO_ENABLED=0 for static builds | 2 | Check build scripts/CI |
| Static linking verified | 1 | `ldd binary` shows "not a dynamic executable" |

**Implementation**:
```bash
CGO_ENABLED=0 go build -o myapp .
```

### Reproducible Paths (2 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| -trimpath flag used | 2 | Check build flags |

**Implementation**:
```bash
go build -trimpath -o myapp .
```

### Binary Optimization (2 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| -ldflags '-s -w' for stripped binaries | 2 | Check build flags |

**Implementation**:
```bash
go build -ldflags '-s -w' -o myapp .
```

### Toolchain Pinning (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Explicit go version in go.mod | 2 | Check `go X.Y` directive |
| Toolchain directive present | 1 | Check `toolchain goX.Y.Z` directive |

**Implementation**:
```go
// go.mod
module mymodule

go 1.22

toolchain go1.22.0
```

---

## Quality Tooling (10 points)

### golangci-lint (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| golangci-lint configured | 2 | Check `.golangci.yml` or `.golangci.yaml` |
| 20+ linters enabled | 2 | Count enabled linters in config |

**Recommended Linters**:
```yaml
# .golangci.yml
linters:
  enable:
    # Bugs
    - govet
    - staticcheck
    - errcheck
    - ineffassign
    - typecheck

    # Style
    - gofmt
    - goimports
    - revive
    - misspell

    # Complexity
    - gocyclo
    - gocognit
    - funlen

    # Security
    - gosec
    - gocritic

    # Performance
    - prealloc
    - bodyclose

    # Error handling
    - errorlint
    - wrapcheck

    # Unused
    - unused
    - deadcode
    - unparam
```

### Vulnerability Scanning (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| govulncheck in CI | 2 | Check CI for govulncheck step |
| Vulnerability check on PRs | 1 | Check PR workflow |

**Implementation**:
```yaml
- name: Install govulncheck
  run: go install golang.org/x/vuln/cmd/govulncheck@latest

- name: Run govulncheck
  run: govulncheck ./...
```

### Race Detector (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Tests run with -race flag | 2 | Check test commands in CI |
| Race detection on all packages | 1 | Verify `./...` scope |

**Implementation**:
```bash
go test -race -v ./...
```

---

## Testing Patterns (bonus, not scored)

### Table-Driven Tests
- [ ] Tests use table-driven pattern
- [ ] Subtests with `t.Run()` for clarity

**Example**:
```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 1, 2, 3},
        {"negative", -1, -2, -3},
        {"zero", 0, 0, 0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d", tt.a, tt.b, got, tt.expected)
            }
        })
    }
}
```

### Fuzz Testing (Go 1.18+)
- [ ] Fuzz tests exist for parsing/input handling
- [ ] Fuzz tests integrated with CI or OSS-Fuzz

**Example**:
```go
func FuzzParse(f *testing.F) {
    f.Add([]byte("example input"))
    f.Fuzz(func(t *testing.T, data []byte) {
        Parse(data) // Should not panic
    })
}
```

### Coverage with Atomic Mode
- [ ] Coverage uses `-covermode=atomic` for race-safe counting
- [ ] Coverage output in standard format for tools

**Implementation**:
```bash
go test -race -coverprofile=coverage.out -covermode=atomic ./...
go tool cover -func=coverage.out
```

---

## Architecture Patterns (bonus, not scored)

### Hexagonal Architecture
- [ ] Clear separation: domain, ports, adapters
- [ ] Interfaces define contracts (ports)
- [ ] External dependencies injected (adapters)

### Dependency Injection
- [ ] Dependencies passed via constructors
- [ ] No global state or singletons
- [ ] Interfaces for testability

**Example**:
```go
type Service struct {
    repo Repository  // Interface, not concrete type
    log  Logger
}

func NewService(repo Repository, log Logger) *Service {
    return &Service{repo: repo, log: log}
}
```

### Error Handling
- [ ] Errors wrapped with context
- [ ] Sentinel errors for expected conditions
- [ ] Error types for programmatic handling

**Example**:
```go
import "fmt"

func doSomething() error {
    if err := dependency(); err != nil {
        return fmt.Errorf("failed to do something: %w", err)
    }
    return nil
}
```

### Structured Logging
- [ ] Structured logging (slog, zerolog, zap)
- [ ] Log levels appropriately used
- [ ] Contextual fields included

---

## Module Management (bonus, not scored)

### go.mod Best Practices
- [ ] Module path matches import path
- [ ] Go version specified
- [ ] Dependencies regularly updated
- [ ] `go mod tidy` runs cleanly

### Vendoring (optional)
- [ ] If vendoring, `vendor/` is committed
- [ ] `go mod vendor` runs cleanly

---

## Total: 20 points

**Scoring Thresholds**:
- 18-20: Excellent Go practices
- 14-17: Good, minor improvements needed
- 10-13: Fair, significant gaps
- Below 10: Poor, major improvements required

---

## Go-Specific Tools Reference

| Tool | Purpose | Install |
|------|---------|---------|
| golangci-lint | Multi-linter aggregator | `go install github.com/golangci-lint/golangci-lint/cmd/golangci-lint@latest` |
| govulncheck | Vulnerability scanner | `go install golang.org/x/vuln/cmd/govulncheck@latest` |
| staticcheck | Advanced static analysis | `go install honnef.co/go/tools/cmd/staticcheck@latest` |
| gofumpt | Stricter gofmt | `go install mvdan.cc/gofumpt@latest` |
| go-licenses | License compliance | `go install github.com/google/go-licenses@latest` |
| syft | SBOM generation | Binary from GitHub releases |
