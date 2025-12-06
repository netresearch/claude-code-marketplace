# Mutation Testing for TYPO3 Extensions

## Overview

Mutation testing verifies test suite quality by introducing small bugs (mutants) into the code and checking if tests catch them. If a test suite has good coverage but low mutation score, the tests may not be actually testing the important behaviors.

> **Key Distinction**: Mutation testing mutates **code** to verify test quality. For testing that mutates **inputs** to find crashes, see [Fuzz Testing](fuzz-testing.md).

| Aspect | Mutation Testing | Fuzz Testing |
|--------|-----------------|--------------|
| **Mutates** | Source code | Input data |
| **Purpose** | Verify test quality | Find crashes/vulnerabilities |
| **Example** | `if (x != y)` → `if (x == y)` | `<img src="` → `<img src="../../../../etc/passwd` |
| **Finds** | Weak/missing tests | Parsing bugs, security issues |
| **Tool (PHP)** | Infection | nikic/php-fuzzer |

## When to Use Mutation Testing

- After achieving high code coverage (70%+) to verify test quality
- Before releases to ensure critical paths are well-tested
- When refactoring to ensure tests catch regressions
- To identify "weak spots" in test coverage

## Tools

### Infection (Recommended)

PHP mutation testing framework with PHPUnit integration.

**Installation:**
```bash
composer require --dev infection/infection:^0.27
```

**Key features:**
- Mutates PHP code with various operators
- Integrates with PHPUnit and Pest
- Generates HTML and JSON reports
- Supports incremental analysis

## Configuration

Create `infection.json5` in project root:

```json5
{
    "$schema": "https://raw.githubusercontent.com/infection/infection/master/resources/schema.json",
    "source": {
        "directories": [
            "Classes"
        ],
        "excludes": [
            "Domain/Model"  // Skip simple DTOs
        ]
    },
    "logs": {
        "html": ".Build/logs/infection.html",
        "text": ".Build/logs/infection.log",
        "summary": ".Build/logs/infection-summary.log"
    },
    "mutators": {
        "@default": true,
        // Disable noisy mutators if needed
        "TrueValue": false,
        "FalseValue": false
    },
    "minMsi": 60,           // Minimum Mutation Score Indicator
    "minCoveredMsi": 80,    // Minimum MSI for covered code only
    "testFramework": "phpunit",
    "testFrameworkOptions": "-c Build/phpunit/UnitTests.xml"
}
```

## Mutation Operators

Infection applies these types of mutations:

### Arithmetic Operators
```php
// Original
$result = $a + $b;

// Mutants
$result = $a - $b;  // PlusToMinus
$result = $a * $b;  // PlusToMultiplication
```

### Comparison Operators
```php
// Original
if ($value > 10) { ... }

// Mutants
if ($value >= 10) { ... }  // GreaterThan to GreaterThanOrEqual
if ($value < 10) { ... }   // GreaterThan to LessThan
if (true) { ... }          // Always truthy
```

### Boolean Operators
```php
// Original
if ($a && $b) { ... }

// Mutants
if ($a || $b) { ... }  // LogicalAnd to LogicalOr
if ($a) { ... }        // Remove operand
```

### Return Values
```php
// Original
return $value;

// Mutants
return null;           // Return null
return [];             // Return empty array
return !$value;        // Negate boolean
```

### Method Calls
```php
// Original
$this->save($entity);

// Mutant
// Line removed (method call deleted)
```

## Running Mutation Tests

### Via Composer Scripts

```json
{
    "scripts": {
        "ci:test:mutation": [
            "@ci:test:php:unit",
            ".Build/bin/infection --threads=4"
        ],
        "ci:test:mutation:quick": [
            ".Build/bin/infection --threads=4 --only-covered --min-msi=60"
        ]
    }
}
```

### Via runTests.sh

```bash
# Add to Build/Scripts/runTests.sh
mutation)
    # Run unit tests first to generate coverage
    COMMAND=(.Build/bin/phpunit -c Build/phpunit/UnitTests.xml --coverage-xml=.Build/logs/coverage-xml --coverage-html=.Build/logs/coverage-html)
    ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name unit-${SUFFIX} ${IMAGE_PHP} "${COMMAND[@]}"

    # Run mutation testing
    COMMAND=(.Build/bin/infection --threads=4 --coverage=.Build/logs/coverage-xml)
    ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name mutation-${SUFFIX} ${IMAGE_PHP} "${COMMAND[@]}"
    SUITE_EXIT_CODE=$?
    ;;
```

### Directly

```bash
# Full mutation test run
.Build/bin/infection --threads=4

# Quick run (only test covered code)
.Build/bin/infection --threads=4 --only-covered

# With existing coverage
.Build/bin/infection --threads=4 --coverage=.Build/logs/coverage-xml

# Filter to specific directory
.Build/bin/infection --threads=4 --filter=Classes/Service
```

## Interpreting Results

### Mutation Score Indicator (MSI)

```
Mutations:       150 total
Killed:          120 (80%)    ← Tests caught the mutation
Escaped:          15 (10%)    ← Tests MISSED the mutation (bad!)
Errors:            5 (3%)     ← Mutation caused fatal error
Uncovered:        10 (7%)     ← No tests for this code

MSI: 80%                      ← (Killed + Errors) / Total
Covered MSI: 86%              ← MSI for covered code only
```

### Understanding Results

| Status | Meaning | Action |
|--------|---------|--------|
| **Killed** | Test failed when mutant introduced | Good - test is effective |
| **Escaped** | Test passed with mutant | **Bad - add/improve tests** |
| **Errors** | Mutant caused fatal error | Usually OK (type errors) |
| **Uncovered** | No test coverage | Add coverage first |
| **Timeout** | Test took too long with mutant | Usually OK |
| **Skipped** | Mutant not tested | Check config |

### Target Scores

| Level | MSI | Covered MSI | Use Case |
|-------|-----|-------------|----------|
| Basic | 50%+ | 60%+ | Initial implementation |
| Good | 70%+ | 80%+ | Production code |
| Excellent | 85%+ | 90%+ | Critical/security code |

## Improving Mutation Score

### 1. Fix Escaped Mutants

Review the HTML report to find escaped mutants:

```html
<!-- .Build/logs/infection.html -->
<!-- Shows: Original code, Mutated code, Test that should have caught it -->
```

### 2. Add Boundary Tests

```php
// If this escapes:
//   if ($age >= 18) → if ($age > 18)
// Add boundary test:
public function testAgeExactly18IsAllowed(): void
{
    self::assertTrue($this->validator->isAdult(18));
}
```

### 3. Add Negative Tests

```php
// If method removal escapes:
//   $logger->error($message);  // removed
// Add test verifying the call:
public function testErrorIsLogged(): void
{
    $logger = $this->createMock(LoggerInterface::class);
    $logger->expects(self::once())
        ->method('error')
        ->with('Expected message');

    $service = new MyService($logger);
    $service->doSomethingThatLogs();
}
```

### 4. Test Return Values

```php
// If return value mutation escapes:
//   return $result; → return null;
// Verify return value explicitly:
public function testReturnsCalculatedValue(): void
{
    $result = $calculator->compute(5, 3);
    self::assertSame(8, $result);  // Not just assertNotNull!
}
```

## CI Integration

### GitHub Actions

```yaml
# .github/workflows/tests.yml
mutation:
  name: Mutation Testing
  runs-on: ubuntu-latest
  needs: [unit]  # Run after unit tests pass
  steps:
    - uses: actions/checkout@v4
    - uses: shivammathur/setup-php@v2
      with:
        php-version: '8.2'
        coverage: pcov

    - run: composer install

    - name: Run unit tests with coverage
      run: |
        .Build/bin/phpunit -c Build/phpunit/UnitTests.xml \
          --coverage-xml=.Build/logs/coverage-xml \
          --log-junit=.Build/logs/phpunit.xml

    - name: Run mutation testing
      run: |
        .Build/bin/infection \
          --threads=4 \
          --coverage=.Build/logs/coverage-xml \
          --min-msi=60 \
          --min-covered-msi=80 \
          --skip-initial-tests

    - name: Upload mutation report
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: mutation-report
        path: .Build/logs/infection.html
```

### Quality Gate

```yaml
# Fail CI if mutation score drops
- name: Check mutation score
  run: |
    .Build/bin/infection \
      --threads=4 \
      --min-msi=60 \
      --min-covered-msi=80 \
      --only-covered
```

## Best Practices

1. **Run unit tests first** - Mutation testing needs passing tests
2. **Start with low thresholds** - Increase gradually (50% → 60% → 70%)
3. **Focus on covered code** - Use `--only-covered` for actionable results
4. **Prioritize escaped mutants** - These indicate weak tests
5. **Exclude trivial code** - Skip getters/setters/DTOs in config
6. **Run incrementally** - Use `--git-diff-filter=AM` for changed files only
7. **Document exclusions** - Explain why code is excluded from mutation testing

## Incremental Mutation Testing

For large codebases, run mutation testing only on changed files:

```bash
# Only test files changed in current branch
.Build/bin/infection \
  --threads=4 \
  --git-diff-filter=AM \
  --git-diff-base=origin/main \
  --only-covered
```

## Directory Structure

```
project/
├── infection.json5           # Infection configuration
├── .Build/
│   └── logs/
│       ├── infection.html    # HTML report
│       ├── infection.log     # Detailed log
│       └── infection-summary.log
└── Tests/
    └── Unit/
        └── Service/
            └── MyServiceTest.php
```

## Resources

- [Infection PHP](https://infection.github.io/) - PHP mutation testing framework
- [Mutation Testing](https://en.wikipedia.org/wiki/Mutation_testing) - Concept overview
- [Pitest](https://pitest.org/) - Java mutation testing (for comparison)
- [Stryker](https://stryker-mutator.io/) - JavaScript/TypeScript mutation testing
