# Test Invocation Guide

> OpenSSF Gold Badge requirements: `test_invocation`, `test_continuous_integration`,
> `test_statement_coverage90`, `test_branch_coverage80`, `dynamic_analysis_enable_assertions`
>
> Projects must have standard test invocation, CI integration, and meet coverage thresholds.

## Standard Test Invocation

### Go Projects

```bash
# Standard invocation (Gold requirement: test_invocation)
go test ./...

# With coverage (Gold: 90% statement coverage)
go test -coverprofile=coverage.out -covermode=atomic ./...

# View coverage
go tool cover -func=coverage.out
go tool cover -html=coverage.out -o coverage.html

# With race detection
go test -race ./...

# Verbose with coverage
go test -v -coverprofile=coverage.out ./...
```

### Python Projects

```bash
# Standard invocation
pytest

# With coverage (Gold: 90% statement, 80% branch)
pytest --cov=. --cov-report=term --cov-report=html --cov-branch

# With assertions enabled (always enabled in pytest by default)
python -O -m pytest  # Optimized mode DISABLES assertions - don't use

# Verbose with coverage
pytest -v --cov=. --cov-fail-under=90
```

### Node.js Projects

```bash
# Standard invocation
npm test

# With coverage
npm test -- --coverage --coverageThreshold='{"global":{"statements":90,"branches":80}}'

# Or with Jest directly
jest --coverage --coverageReporters=text --coverageReporters=html
```

### Rust Projects

```bash
# Standard invocation
cargo test

# With coverage (requires cargo-llvm-cov)
cargo llvm-cov --html

# With assertions (debug builds have assertions by default)
cargo test  # assertions enabled
cargo test --release  # some assertions disabled - use debug_assert! for release
```

## CI Integration

### GitHub Actions Test Workflow

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version-file: go.mod

      - name: Run tests with coverage
        run: |
          go test -v -race -coverprofile=coverage.out -covermode=atomic ./...

      - name: Check coverage threshold
        run: |
          COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')
          echo "Total coverage: ${COVERAGE}%"

          # Gold level: 90% statement coverage
          if (( $(echo "$COVERAGE < 90" | bc -l) )); then
            echo "❌ Coverage ${COVERAGE}% is below 90% threshold"
            exit 1
          fi
          echo "✅ Coverage meets Gold level threshold"

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: coverage.out
```

### Branch Coverage for Gold Level

```yaml
# Python with branch coverage
- name: Run tests with branch coverage
  run: |
    pytest --cov=. --cov-branch --cov-report=term --cov-fail-under=90

    # Check branch coverage specifically
    BRANCH_COV=$(coverage report --include="*.py" | grep TOTAL | awk '{print $NF}' | tr -d '%')
    if (( $(echo "$BRANCH_COV < 80" | bc -l) )); then
      echo "❌ Branch coverage ${BRANCH_COV}% is below 80% threshold"
      exit 1
    fi
```

## Assertions

### Go Assertions

```go
// Go doesn't have built-in assertions, but you can:

// 1. Use testing assertions
func TestSomething(t *testing.T) {
    result := compute()
    if result != expected {
        t.Fatalf("expected %v, got %v", expected, result)
    }
}

// 2. Use panic for invariants (always enabled)
func process(data []byte) {
    if len(data) == 0 {
        panic("invariant violation: empty data")
    }
    // ...
}

// 3. Use testify for rich assertions
import "github.com/stretchr/testify/assert"

func TestSomething(t *testing.T) {
    assert.Equal(t, expected, actual)
    assert.NoError(t, err)
    assert.NotNil(t, result)
}
```

### Python Assertions

```python
# Python assertions are enabled by default
# They're disabled with python -O (optimize) flag

def process(data):
    assert data is not None, "data cannot be None"
    assert len(data) > 0, "data cannot be empty"
    # ...

# pytest assertions
def test_something():
    result = compute()
    assert result == expected
    assert isinstance(result, MyClass)
```

### Rust Assertions

```rust
// debug_assert! - only in debug builds
fn process(data: &[u8]) {
    debug_assert!(!data.is_empty(), "data cannot be empty");
    // ...
}

// assert! - always enabled
fn critical_process(data: &[u8]) {
    assert!(!data.is_empty(), "data cannot be empty");
    // ...
}

// Tests use assert! macros
#[test]
fn test_something() {
    let result = compute();
    assert_eq!(result, expected);
    assert!(result.is_valid());
}
```

## Coverage Thresholds

### Coverage Configuration Files

**Go (no config file, use scripts):**
```bash
#!/bin/bash
# scripts/check-coverage.sh

THRESHOLD="${1:-90}"
COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')

if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
    echo "Coverage $COVERAGE% < $THRESHOLD%"
    exit 1
fi
```

**Python (pyproject.toml):**
```toml
[tool.coverage.run]
branch = true
source = ["."]

[tool.coverage.report]
fail_under = 90
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise NotImplementedError",
]
```

**Node.js (jest.config.js):**
```javascript
module.exports = {
  coverageThreshold: {
    global: {
      statements: 90,
      branches: 80,
      functions: 90,
      lines: 90,
    },
  },
};
```

## Multi-Level Coverage Script

```bash
#!/bin/bash
# scripts/check-coverage-level.sh
# Usage: ./check-coverage-level.sh [passing|silver|gold]

LEVEL="${1:-passing}"
COVERAGE_FILE="${2:-coverage.out}"

case "$LEVEL" in
    passing)
        STATEMENT_THRESHOLD=60
        BRANCH_THRESHOLD=0  # Not required
        ;;
    silver)
        STATEMENT_THRESHOLD=80
        BRANCH_THRESHOLD=0  # Not required
        ;;
    gold)
        STATEMENT_THRESHOLD=90
        BRANCH_THRESHOLD=80
        ;;
    *)
        echo "Usage: $0 [passing|silver|gold]"
        exit 1
        ;;
esac

echo "=== Coverage Check: $LEVEL Level ==="
echo "Statement threshold: ${STATEMENT_THRESHOLD}%"
echo "Branch threshold: ${BRANCH_THRESHOLD}%"

# Extract statement coverage
if [[ -f "$COVERAGE_FILE" ]]; then
    STATEMENT_COV=$(go tool cover -func="$COVERAGE_FILE" | grep total | awk '{print $3}' | tr -d '%')
    echo "Statement coverage: ${STATEMENT_COV}%"

    if (( $(echo "$STATEMENT_COV < $STATEMENT_THRESHOLD" | bc -l) )); then
        echo "❌ Statement coverage below ${STATEMENT_THRESHOLD}%"
        exit 1
    fi
    echo "✅ Statement coverage meets $LEVEL threshold"
fi

# For Python, also check branch coverage
if [[ "$LEVEL" == "gold" && -f ".coverage" ]]; then
    BRANCH_COV=$(coverage report --show-missing | grep TOTAL | awk '{print $(NF-1)}' | tr -d '%')
    echo "Branch coverage: ${BRANCH_COV}%"

    if (( $(echo "$BRANCH_COV < $BRANCH_THRESHOLD" | bc -l) )); then
        echo "❌ Branch coverage below ${BRANCH_THRESHOLD}%"
        exit 1
    fi
    echo "✅ Branch coverage meets Gold threshold"
fi

echo ""
echo "✅ All coverage thresholds met for $LEVEL level"
```

## Documentation Requirements

Add to README.md:

```markdown
## Testing

### Running Tests

\`\`\`bash
# Standard test invocation
go test ./...

# With coverage
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
\`\`\`

### Coverage Requirements

| Level | Statement | Branch |
|-------|-----------|--------|
| Passing | 60% | - |
| Silver | 80% | - |
| Gold | 90% | 80% |

Current coverage: ![Coverage](https://codecov.io/gh/ORG/REPO/branch/main/graph/badge.svg)
```

## Badge Criteria Alignment

| Criterion | Requirement | Implementation |
|-----------|-------------|----------------|
| `test_invocation` | Standard test command | `go test`, `pytest`, `npm test` |
| `test_continuous_integration` | Tests run in CI | GitHub Actions workflow |
| `test_statement_coverage90` | 90% statement coverage | Coverage threshold check |
| `test_branch_coverage80` | 80% branch coverage | Branch coverage enabled |
| `dynamic_analysis_enable_assertions` | Assertions enabled | Default in test/debug mode |

## Resources

- [Go Testing](https://go.dev/doc/tutorial/add-a-test)
- [pytest Documentation](https://docs.pytest.org/)
- [Jest Coverage](https://jestjs.io/docs/cli#--coverage)
- [OpenSSF Testing Criteria](https://www.bestpractices.dev/en/criteria#1.test)
