# Go Fuzz Testing

Go 1.18+ includes built-in fuzzing support. This guide covers patterns for security-focused fuzz testing.

## When to Use Fuzz Testing

- Input parsing (URLs, queries, content types)
- Data validation and sanitization
- Security-sensitive operations (XSS prevention, path traversal detection)
- Protocol handling and serialization
- Cache key generation

## Basic Pattern

```go
//go:build fuzz

package mypackage

import (
    "testing"
    "unicode/utf8"
)

func FuzzMyFunction(f *testing.F) {
    // 1. Seed with known edge cases
    f.Add("normal input")
    f.Add("")                    // Empty
    f.Add("\x00null")            // Null bytes
    f.Add("../../../etc/passwd") // Path traversal
    f.Add("<script>alert(1)")    // XSS attempt
    f.Add("' OR 1=1--")          // SQL injection

    // 2. Define the fuzz target
    f.Fuzz(func(t *testing.T, input string) {
        // Skip invalid UTF-8 if needed
        if !utf8.ValidString(input) {
            return
        }

        // Exercise the function - should not panic
        result, err := MyFunction(input)

        // Validate invariants
        if err == nil {
            // Check properties that should always hold
            if result == nil {
                t.Error("nil result without error")
            }
        }
    })
}
```

## Security-Focused Seeds

### URL/Path Handling

```go
f.Add("/users")
f.Add("/users/john%20doe")
f.Add("/%2e%2e/etc/passwd")          // Path traversal
f.Add("/%00null")                    // Null byte injection
f.Add("/users/../../../etc/passwd")  // Directory traversal
f.Add("/%252e%252e/")                // Double encoding
f.Add("/路径/用户")                   // Unicode paths
f.Add("//double//slashes//")
f.Add("/users;id")                   // Command injection
f.Add("/users|ls")                   // Pipe injection
```

### Query Parameters

```go
f.Add("key=value")
f.Add("key=")
f.Add("=value")
f.Add("key")
f.Add("")
f.Add("key=value&key=value2")        // Duplicate keys
f.Add("key=%00")                     // Null byte
f.Add("key=<script>")                // XSS
f.Add("key=' OR 1=1--")              // SQL injection
f.Add("key[]=value1&key[]=value2")   // Array syntax
```

### XSS Payloads

```go
f.Add("<script>alert(1)</script>")
f.Add("<img src=x onerror=alert(1)>")
f.Add("javascript:alert(1)")
f.Add("<svg onload=alert(1)>")
f.Add("{{.}}")                       // Template injection
f.Add("${7*7}")                      // Expression injection
```

## Running Fuzz Tests

```bash
# Run specific fuzz test (30 seconds)
go test -fuzz=FuzzMyFunction -fuzztime=30s ./...

# Run all fuzz tests in package
go test -fuzz=. -fuzztime=1m ./path/to/package

# Run with race detector (slower but thorough)
go test -fuzz=FuzzMyFunction -fuzztime=30s -race ./...

# Reproduce a failing case from testdata
go test -run=FuzzMyFunction/failing_case ./...
```

## CI Integration

Add to Makefile:

```makefile
.PHONY: fuzz
fuzz:
	@echo "Running fuzz tests..."
	@for pkg in $$(go list ./... | grep -v /vendor/); do \
		for fuzz in $$(go test -list='^Fuzz' $$pkg 2>/dev/null | grep '^Fuzz'); do \
			echo "Fuzzing $$fuzz in $$pkg..."; \
			go test -fuzz=$$fuzz -fuzztime=30s $$pkg || exit 1; \
		done; \
	done
```

## Best Practices

1. **Use Build Tags**: Isolate fuzz tests with `//go:build fuzz`
2. **Seed Edge Cases**: Include security payloads, boundary values, unicode
3. **Validate UTF-8**: Skip invalid strings early if your code expects valid UTF-8
4. **Check Invariants**: Assert properties that should always hold
5. **No Panics**: Primary goal is proving code doesn't panic on any input
6. **Limit Resource Usage**: Skip extremely long inputs to prevent timeouts

## File Organization

```
package/
├── handler.go
├── handler_test.go       # Unit tests
└── handler_fuzz_test.go  # Fuzz tests (//go:build fuzz)
```

## Related

- [Go Fuzzing Documentation](https://go.dev/security/fuzz/)
- `references/testing.md` - General testing patterns
- `references/mutation-testing.md` - Complementary test quality measurement
