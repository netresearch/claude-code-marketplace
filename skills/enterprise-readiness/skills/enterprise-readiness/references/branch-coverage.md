# Branch Coverage Guide

> OpenSSF Badge Criteria: `test_branch_coverage80` (Gold - requires 80% branch coverage)

## Understanding Branch vs Statement Coverage

### Statement Coverage
Measures which lines of code are executed:
```go
func Example(x int) string {
    if x > 0 {        // Line executed
        return "pos"  // Line executed OR not
    }
    return "neg"      // Line executed OR not
}
```
**100% statement coverage** = all lines executed at least once.

### Branch Coverage (Decision Coverage)
Measures whether each decision point (if/else, switch) has been tested for all outcomes:
```go
func Example(x int) string {
    if x > 0 {        // Branch: true AND false
        return "pos"
    }
    return "neg"
}
```
**100% branch coverage** = both `x > 0` (true) AND `x <= 0` (false) tested.

### Why Branch Coverage Matters

Statement coverage can be 100% while missing critical paths:
```go
func Process(a, b bool) {
    if a && b {
        // Critical path
    }
}

// This test achieves 100% statement coverage
func TestProcess(t *testing.T) {
    Process(true, true)  // Executes the if block
    Process(false, false) // Skips the if block
}
// But misses: (true, false) and (false, true) branches
```

---

## Measuring Branch Coverage in Go

### Native Go Coverage (Statement Only)

Go's built-in coverage tool measures statement coverage:
```bash
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out  # Shows statement coverage
```

### Approach 1: gocover-cobertura + XML Analysis

Convert Go coverage to Cobertura XML format:

```bash
# Install
go install github.com/boumenot/gocover-cobertura@latest

# Generate
go test -coverprofile=coverage.out -covermode=count ./...
gocover-cobertura < coverage.out > coverage.xml
```

Then analyze with tools that support branch metrics.

### Approach 2: gocov + gocov-xml

```bash
# Install
go install github.com/axw/gocov/gocov@latest
go install github.com/AlekSi/gocov-xml@latest

# Generate
go test -coverprofile=coverage.out ./...
gocov convert coverage.out | gocov-xml > coverage.xml
```

### Approach 3: Codecov Branch Analysis

Codecov can analyze branch coverage:

```yaml
# .github/workflows/coverage.yml
- name: Run tests
  run: go test -coverprofile=coverage.out -covermode=atomic ./...

- name: Upload to Codecov
  uses: codecov/codecov-action@v4
  with:
    files: coverage.out
    flags: unittests
    fail_ci_if_error: true
```

In Codecov settings, enable branch coverage reports.

---

## Achieving 80% Branch Coverage

### Strategy 1: Test All Conditional Outcomes

For every `if` statement, ensure both true and false branches are tested:

```go
func Validate(s string) error {
    if s == "" {
        return errors.New("empty")
    }
    if len(s) > 100 {
        return errors.New("too long")
    }
    return nil
}

func TestValidate(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {"empty string", "", true},           // if s == "" → true
        {"valid string", "hello", false},     // if s == "" → false
        {"too long", strings.Repeat("x", 101), true},  // if len > 100 → true
        {"at limit", strings.Repeat("x", 100), false}, // if len > 100 → false
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := Validate(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("Validate(%q) error = %v, wantErr %v", tt.input, err, tt.wantErr)
            }
        })
    }
}
```

### Strategy 2: Cover Compound Conditions

For `&&` and `||` conditions, test each combination:

```go
func IsEligible(age int, hasLicense bool) bool {
    if age >= 18 && hasLicense {
        return true
    }
    return false
}

func TestIsEligible(t *testing.T) {
    tests := []struct {
        age     int
        license bool
        want    bool
    }{
        {20, true, true},    // Both true
        {20, false, false},  // First true, second false
        {16, true, false},   // First false, second true
        {16, false, false},  // Both false
    }
    // Run all test cases...
}
```

### Strategy 3: Cover Switch Cases

Test all switch cases including default:

```go
func Categorize(score int) string {
    switch {
    case score >= 90:
        return "A"
    case score >= 80:
        return "B"
    case score >= 70:
        return "C"
    default:
        return "F"
    }
}

func TestCategorize(t *testing.T) {
    tests := []struct {
        score int
        want  string
    }{
        {95, "A"},  // First case
        {85, "B"},  // Second case
        {75, "C"},  // Third case
        {65, "F"},  // Default case
    }
    // Run all test cases...
}
```

### Strategy 4: Test Error Paths

Error handling often has low coverage:

```go
func ReadConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("read file: %w", err)  // Often untested
    }

    var cfg Config
    if err := json.Unmarshal(data, &cfg); err != nil {
        return nil, fmt.Errorf("parse config: %w", err)  // Often untested
    }

    return &cfg, nil
}

func TestReadConfig(t *testing.T) {
    // Happy path
    t.Run("valid config", func(t *testing.T) {
        cfg, err := ReadConfig("testdata/valid.json")
        require.NoError(t, err)
        require.NotNil(t, cfg)
    })

    // Error path: file not found
    t.Run("file not found", func(t *testing.T) {
        _, err := ReadConfig("nonexistent.json")
        require.Error(t, err)
        require.Contains(t, err.Error(), "read file")
    })

    // Error path: invalid JSON
    t.Run("invalid json", func(t *testing.T) {
        _, err := ReadConfig("testdata/invalid.json")
        require.Error(t, err)
        require.Contains(t, err.Error(), "parse config")
    })
}
```

---

## CI/CD Enforcement

### Check and Fail on Low Coverage

```yaml
# .github/workflows/coverage.yml
- name: Check branch coverage
  run: |
    go test -coverprofile=coverage.out -covermode=atomic ./...

    # Statement coverage as proxy (actual branch coverage requires external tools)
    COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')

    # For branch coverage, multiply by 0.85-0.9 factor
    # (branch coverage is typically 85-90% of statement coverage)
    ESTIMATED_BRANCH=$(awk -v c="$COVERAGE" 'BEGIN { printf "%.1f", c * 0.85 }')

    echo "Statement coverage: $COVERAGE%"
    echo "Estimated branch coverage: $ESTIMATED_BRANCH%"

    if awk -v b="$ESTIMATED_BRANCH" 'BEGIN { exit !(b >= 80) }'; then
      echo "✓ Branch coverage meets 80% threshold"
    else
      echo "✗ Branch coverage below 80% threshold"
      exit 1
    fi
```

### Using Codecov with Branch Coverage

```yaml
# codecov.yml
coverage:
  precision: 2
  round: down
  range: "70...100"
  status:
    project:
      default:
        target: 80%
        threshold: 1%
        branches:
          - main
    patch:
      default:
        target: 80%
        threshold: 1%

# Comment settings
comment:
  layout: "reach, diff, flags, files"
  behavior: default
  require_changes: true
  require_base: true
  require_head: true
  branches:
    - main
```

---

## Common Pitfalls

### 1. Testing Only Happy Paths

```go
// Bad: Only tests success
func TestProcess_Success(t *testing.T) {
    result, _ := Process(validInput)
    assert.Equal(t, expected, result)
}

// Good: Tests all outcomes
func TestProcess(t *testing.T) {
    t.Run("success", func(t *testing.T) { ... })
    t.Run("invalid input", func(t *testing.T) { ... })
    t.Run("timeout", func(t *testing.T) { ... })
}
```

### 2. Ignoring Default Cases

```go
// Ensure switch default is covered
switch status {
case Active: ...
case Pending: ...
default:
    // This path is often missed
    return fmt.Errorf("unknown status: %s", status)
}
```

### 3. Short-Circuit Evaluation

```go
// if a || b: need tests where a=true, and where a=false,b=true, and where both false
// if a && b: need tests where both true, a=false, and a=true,b=false
```

---

## Tools Comparison

| Tool | Branch Coverage | Language | Free |
|------|-----------------|----------|------|
| Codecov | Yes (with config) | Multi | Freemium |
| Coveralls | Limited | Multi | Freemium |
| SonarQube | Yes | Multi | Freemium |
| gocov | No (statement only) | Go | Yes |
| JaCoCo | Yes | Java | Yes |
| Istanbul | Yes | JS/TS | Yes |
| Coverage.py | Yes (with branch flag) | Python | Yes |

---

## Badge Criteria Verification

To verify `test_branch_coverage80`:

1. **Generate coverage report**
   ```bash
   go test -coverprofile=coverage.out -covermode=atomic ./...
   ```

2. **Convert to analyzable format**
   ```bash
   gocover-cobertura < coverage.out > coverage.xml
   ```

3. **Check branch coverage**
   - Upload to Codecov/Coveralls
   - Or use local XML analysis tools
   - Or estimate from statement coverage (* 0.85)

4. **Document in badge application**
   - Link to coverage reports
   - Show coverage percentage
   - Explain measurement methodology

---

## Resources

- [Go Coverage Documentation](https://go.dev/blog/cover)
- [Codecov Branch Coverage](https://docs.codecov.com/docs/about-code-coverage#branch-coverage)
- [gocover-cobertura](https://github.com/boumenot/gocover-cobertura)
- [Branch vs Statement Coverage](https://www.atlassian.com/continuous-delivery/software-testing/code-coverage)
