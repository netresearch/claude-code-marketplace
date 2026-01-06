# Go Mutation Testing

Mutation testing measures test quality by introducing small code changes (mutations) and verifying tests detect them. Higher scores indicate more effective tests.

## Tool: Gremlins

[go-gremlins](https://github.com/go-gremlins/gremlins) is the recommended mutation testing tool for Go.

```bash
# Install
go install github.com/go-gremlins/gremlins/cmd/gremlins@v0.6.0

# Run
gremlins unleash --config=.gremlins.yaml
```

## Configuration

Create `.gremlins.yaml` in project root:

```yaml
# Packages to test
test-packages:
  - .
  - ./cmd/...
  - ./internal/...

# Mutator types to enable
mutators:
  - CONDITIONALS_BOUNDARY    # Change < to <=, > to >=
  - CONDITIONALS_NEGATION    # Negate conditions (== to !=)
  - INCREMENT_DECREMENT      # Change ++ to --
  - INVERT_LOGICAL           # Invert && to ||
  - INVERT_NEGATIVES         # Remove negation operators
  - INVERT_LOOPCTRL          # Change break to continue

# Files/patterns to exclude
exclude:
  - "**/*_test.go"           # Test files
  - "**/test/**"             # Test helpers
  - "**/mock/**"             # Mock implementations
  - "**/generated/**"        # Generated code

# Only mutate code covered by tests
coverage: true

# Minimum acceptable mutation score (%)
threshold: 60

# Timeout multiplier for test runs
timeout-coefficient: 5

# Output reports
output:
  json: mutation-report.json
  html: mutation-report.html

# Test timeout
test-timeout: 120s
```

## Understanding Results

| Metric | Meaning |
|--------|---------|
| **Killed** | Tests detected the mutation (good!) |
| **Survived** | Tests missed the mutation (needs improvement) |
| **Timed Out** | Tests hung on mutation (usually killed) |
| **Skipped** | Excluded from analysis |

**Test Efficacy** = (Killed + Timed Out) / Total Mutations

Target: **60%+ for production code**

## CI Integration

### GitHub Actions Workflow

```yaml
name: Mutation Testing

on:
  push:
    branches: [main]
  pull_request:
    paths:
      - '**.go'
      - '.gremlins.yaml'

jobs:
  mutation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod

      - name: Install gremlins
        run: go install github.com/go-gremlins/gremlins/cmd/gremlins@v0.6.0

      - name: Run mutation tests
        run: |
          gremlins unleash --config=.gremlins.yaml 2>&1 | tee output.txt
          SCORE=$(grep -oP 'Test efficacy: \K[\d.]+' output.txt || echo "0")
          echo "Mutation Score: ${SCORE}%"
          if (( $(echo "$SCORE < 60" | bc -l) )); then
            echo "::warning::Mutation score below 60%"
          fi

      - name: Upload reports
        uses: actions/upload-artifact@v4
        with:
          name: mutation-reports
          path: |
            mutation-report.json
            mutation-report.html
```

### Diff-Based Testing (PRs only)

For efficiency, only test mutations in changed files on PRs:

```yaml
- name: Run mutation tests (diff only)
  if: github.event_name == 'pull_request'
  run: |
    BASE_REF="${{ github.event.pull_request.base.sha }}"
    gremlins unleash --config=.gremlins.yaml --diff "$BASE_REF"
```

## Makefile Integration

```makefile
.PHONY: mutation
mutation:
	@echo "Running mutation tests..."
	@gremlins unleash --config=.gremlins.yaml

.PHONY: mutation-report
mutation-report: mutation
	@echo "Opening mutation report..."
	@open mutation-report.html 2>/dev/null || xdg-open mutation-report.html
```

## Improving Mutation Score

### Common Surviving Mutations

1. **Boundary conditions** - Add tests for `<` vs `<=`, `>` vs `>=`
2. **Error paths** - Test both success and failure cases
3. **Loop controls** - Verify break/continue behavior
4. **Negation** - Test both true and false conditions
5. **Increment/Decrement** - Check exact values, not just "changed"

### Example: Fixing a Survivor

```go
// Original code
func IsValid(x int) bool {
    return x > 0  // Mutation: x >= 0 survives
}

// Original test (insufficient)
func TestIsValid(t *testing.T) {
    assert.True(t, IsValid(1))   // x > 0 and x >= 0 both pass
    assert.False(t, IsValid(-1)) // x > 0 and x >= 0 both fail
}

// Fixed test (kills the mutation)
func TestIsValid(t *testing.T) {
    assert.True(t, IsValid(1))
    assert.False(t, IsValid(-1))
    assert.False(t, IsValid(0))  // Boundary case kills x >= 0
}
```

## Best Practices

1. **Start with 60% threshold** - Increase as tests mature
2. **Exclude generated code** - Focus on hand-written logic
3. **Use coverage mode** - Only mutate tested code
4. **Run on CI** - Catch regressions early
5. **Diff mode for PRs** - Full runs on main branch only

## Related

- `references/testing.md` - General testing patterns
- `references/fuzz-testing.md` - Complementary input validation testing
- [go-gremlins documentation](https://github.com/go-gremlins/gremlins)
