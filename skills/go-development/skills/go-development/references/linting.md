# Go Linting and Code Quality

## golangci-lint v2 Configuration

golangci-lint v2 uses a new YAML structure. Here's a production-ready configuration:

```yaml
# .golangci.yml
version: "2"
run:
  tests: true

linters:
  default: none
  enable:
    # Bugs & Correctness (Critical)
    - govet           # Go vet checks
    - staticcheck     # Comprehensive static analysis
    - errcheck        # Unchecked errors
    - errorlint       # Error wrapping issues
    - bodyclose       # HTTP response body close
    - noctx           # HTTP requests without context
    - durationcheck   # Detects time.Second * time.Second bugs
    - nilerr          # Catches return nil when err != nil
    - nilnesserr      # Checks err != nil but returns different nil
    - fatcontext      # Detects nested contexts in loops
    - contextcheck    # Non-inherited context usage
    - copyloopvar     # Loop variable copy issues (Go 1.22+)
    - forcetypeassert # Unchecked type assertions (panic risk)
    - makezero        # Slice with non-zero initial length bugs

    # Security
    - gosec           # Security issues

    # Performance
    - prealloc        # Slice preallocation suggestions
    - unconvert       # Unnecessary type conversions
    - perfsprint      # Faster sprintf alternatives

    # Style & Maintainability
    - gocyclo         # Cyclomatic complexity
    - gocognit        # Cognitive complexity
    - funlen          # Function length limits
    - nestif          # Nested if statement depth
    - ineffassign     # Ineffective assignments
    - unused          # Unused code detection
    - misspell        # Spelling mistakes
    - revive          # Fast, configurable linter
    - gocritic        # Opinionated linter

    # Modernization (Go 1.21+)
    - intrange        # Use for range n
    - usestdlibvars   # Use http.StatusOK instead of 200
    - modernize       # Modern Go features

    # Testing Quality
    - thelper         # Test helpers should call t.Helper()
    - tparallel       # Correct t.Parallel() usage

  settings:
    gocyclo:
      min-complexity: 15
    gocognit:
      min-complexity: 30
    funlen:
      lines: 80
      statements: 50
    nestif:
      min-complexity: 4
    misspell:
      locale: US
    errcheck:
      check-type-assertions: true
      check-blank: false  # Allow explicit _ = err

  exclusions:
    generated: lax
    presets:
      - comments
      - common-false-positives
      - legacy
      - std-error-handling
    rules:
      # Exclude complexity checks in test files
      - linters:
          - gocyclo
          - gocognit
          - funlen
          - nestif
        path: _test\.go

      # Example: Exclude inherently complex functions
      # - linters:
      #     - gocyclo
      #     - gocognit
      #   path: parser\.go
      #   text: "(parse|complexFunction)"

formatters:
  enable:
    - gci       # Import grouping
    - gofumpt   # Stricter gofmt
  settings:
    gci:
      sections:
        - standard
        - default
        - prefix(github.com/your-org/your-project)
```

## Linter Selection Strategy

### By Category

| Category | Linters | Priority |
|----------|---------|----------|
| **Bugs** | govet, staticcheck, errcheck, nilerr | Critical |
| **Security** | gosec, bidichk | High |
| **Performance** | prealloc, unconvert, perfsprint | Medium |
| **Style** | gocyclo, funlen, revive, gocritic | Medium |
| **Modernization** | intrange, modernize, usestdlibvars | Low |

### Adding Exclusions Properly

When a linter flags inherently complex code that cannot be simplified:

```yaml
exclusions:
  rules:
    # Document WHY the exclusion is needed
    # Next() and Prev() have inherent complexity due to
    # multi-field time calculation with wraparound logic
    - linters:
        - gocognit
        - gocyclo
      path: spec\.go
      text: "(Next|Prev)"
```

**Best Practice**: Always add a comment explaining why the exclusion is justified.

## Common staticcheck/revive Fixes

### ST1005: Error String Formatting

Error strings should NOT be capitalized or end with punctuation:

```go
// BAD - Will trigger ST1005
return errors.New("H expressions require a hash key")
return fmt.Errorf("Invalid input: %s.", input)

// GOOD
return errors.New("h expressions require a hash key")
return fmt.Errorf("invalid input: %s", input)
```

**Rationale**: Error messages are often wrapped or concatenated. Lowercase prevents awkward capitalization like `"failed: Invalid input"`.

### ST1003: Naming Conventions

```go
// BAD
var serverId string    // Should be serverID
func GetUserId() {}    // Should be GetUserID
type HttpClient struct  // Should be HTTPClient

// GOOD
var serverID string
func GetUserID() {}
type HTTPClient struct
```

### gosec G104: Unhandled Errors

For functions that always return nil errors (like `hash.Hash.Write`):

```go
// BAD - gosec G104 warning
h := fnv.New64a()
h.Write([]byte(key))  // Error unhandled

// GOOD - Explicitly acknowledge the ignored return
h := fnv.New64a()
_, _ = h.Write([]byte(key))  // hash.Hash.Write never returns error
```

**When to use `_, _ =`**:
- `hash.Hash.Write()` - Never returns error per spec
- `bytes.Buffer.Write()` - Never returns error
- `strings.Builder.WriteString()` - Never returns error

### revive: Error Naming

```go
// BAD
var InvalidInput = errors.New("invalid input")  // Should start with Err
type ValidationFailed struct{}                  // Should end with Error

// GOOD
var ErrInvalidInput = errors.New("invalid input")
type ValidationError struct{}
```

## Running Linters

### Development Workflow

```bash
# Quick check during development
golangci-lint run --fast

# Full check before commit
golangci-lint run

# Check specific files
golangci-lint run ./pkg/...

# Auto-fix where possible
golangci-lint run --fix
```

### CI Configuration

```yaml
# GitHub Actions
- name: golangci-lint
  uses: golangci/golangci-lint-action@v6
  with:
    version: v1.62
    args: --timeout 5m
```

### Pre-commit Hook (lefthook)

```yaml
# .lefthook.yml
pre-commit:
  parallel: true
  commands:
    lint:
      glob: "*.go"
      run: golangci-lint run --new-from-rev=HEAD~1
```

## Complexity Guidelines

| Metric | Threshold | Action if Exceeded |
|--------|-----------|-------------------|
| Cyclomatic (gocyclo) | 15 | Refactor or document why justified |
| Cognitive (gocognit) | 30 | Simplify or add exclusion with rationale |
| Function Length | 80 lines | Extract helper functions |
| Nesting Depth | 4 levels | Refactor with early returns |

### When Complexity is Justified

Some functions have inherent complexity that cannot be reduced without fragmenting the algorithm:

1. **Parser functions** - Multiple input formats require branching
2. **Time calculations** - Multi-field wraparound (year/month/day/hour/minute/second)
3. **State machines** - Multiple states and transitions

In these cases, add an exclusion with clear documentation.

## Makefile Integration

```makefile
.PHONY: lint lint-full lint-fix

# Quick lint for development
lint:
	golangci-lint run --fast

# Full lint for CI
lint-full:
	golangci-lint run --timeout 5m

# Auto-fix issues
lint-fix:
	golangci-lint run --fix

# Run specific linters only
lint-security:
	golangci-lint run -E gosec,bidichk

lint-bugs:
	golangci-lint run -E govet,staticcheck,errcheck,nilerr
```
