# Go Backend Services

<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: 2025-10-09 -->

**Scope**: Go backend packages in `internal/` directory

**See also**: [../AGENTS.md](../AGENTS.md) for global standards, [web/AGENTS.md](web/AGENTS.md) for frontend

## Overview

Backend services for LDAP selfservice password change/reset functionality. Organized as internal Go packages:

- **email/**: SMTP email service for password reset tokens
- **options/**: Configuration management from environment variables
- **ratelimit/**: IP-based rate limiting (3 req/hour default)
- **resettoken/**: Cryptographic token generation and validation
- **rpc/**: JSON-RPC 2.0 API handlers (password change/reset)
- **validators/**: Password policy validation logic
- **web/**: HTTP server setup, static assets, routing (see [web/AGENTS.md](web/AGENTS.md))

## Setup/Environment

**Required environment variables** (configure in `.env.local`):

```bash
# LDAP connection
LDAP_URL=ldaps://ldap.example.com:636
LDAP_USER_BASE_DN=ou=users,dc=example,dc=com
LDAP_BIND_DN=cn=admin,dc=example,dc=com
LDAP_BIND_PASSWORD=secret

# Email for password reset
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@example.com
SMTP_PASSWORD=secret
SMTP_FROM=noreply@example.com
APP_BASE_URL=https://passwd.example.com

# Rate limiting (optional)
RATE_LIMIT_REQUESTS=3
RATE_LIMIT_WINDOW=1h

# Token expiry (optional)
TOKEN_EXPIRY_DURATION=1h
```

**Go toolchain**: Requires Go 1.25+ (specified in `go.mod`)

**Key dependencies**:

- `github.com/gofiber/fiber/v2` - HTTP server
- `github.com/netresearch/simple-ldap-go` - LDAP client
- `github.com/testcontainers/testcontainers-go` - Integration testing
- `github.com/joho/godotenv` - Environment loading

## Build & Tests

```bash
# Development
go run .                      # Start server with hot-reload (via pnpm go:dev)
go build -v ./...             # Compile all packages
go test -v ./...              # Run all tests with verbose output

# Specific package testing
go test ./internal/validators/...    # Test password validators
go test ./internal/ratelimit/...     # Test rate limiter
go test ./internal/resettoken/...    # Test token generation
go test -run TestSpecificFunction    # Run specific test

# Integration tests (uses testcontainers)
go test -v ./internal/email/...      # Requires Docker for MailHog container

# Coverage
go test -cover ./...                 # Coverage summary
go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out

# Build optimized binary
CGO_ENABLED=0 go build -ldflags="-w -s" -o ldap-passwd
```

**CI validation** (from `.github/workflows/check.yml`):

```bash
go mod download
go build -v ./...
go test -v ./...
```

## Code Style

**Go Standards**:

- Use `go fmt` (automatic via Prettier with go-template plugin)
- Follow [Effective Go](https://go.dev/doc/effective_go)
- Package-level documentation comments required
- Exported functions must have doc comments

**Project Conventions**:

- Internal packages only: No public API outside this project
- Error wrapping with context: `fmt.Errorf("context: %w", err)`
- Use structured logging (consider adding in future)
- Prefer explicit over implicit
- Use interfaces for testability (see `email/service.go`)

**Naming**:

- `internal/package/file.go` - implementation
- `internal/package/file_test.go` - tests
- Descriptive variable names (not `x`, `y`, `tmp`)
- No stuttering: `email.Service`, not `email.EmailService`

**Error Handling**:

```go
// ✅ Good: wrap with context
if err != nil {
    return fmt.Errorf("failed to connect LDAP at %s: %w", config.URL, err)
}

// ❌ Bad: lose context
if err != nil {
    return err
}

// ❌ Worse: ignore
conn, _ := ldap.Dial(url)
```

**Testing**:

- Table-driven tests preferred
- Use testcontainers for external dependencies (LDAP, SMTP)
- Test files colocated with code: `validators/validate_test.go`
- Descriptive test names: `TestPasswordValidation_RequiresMinimumLength`

## Security

**LDAP Security**:

- Always use LDAPS in production (`ldaps://` URLs)
- Bind credentials in environment, never hardcoded
- Validate user input before LDAP queries (prevent injection)
- Use `simple-ldap-go` helpers to avoid raw LDAP filter construction

**Password Security**:

- Never log passwords (plain or hashed)
- No password storage - passwords go directly to LDAP
- Passwords only in memory during request lifetime
- HTTPS required for transport security

**Token Security**:

- Cryptographic random tokens (see `resettoken/token.go`)
- Configurable expiry (default 1h)
- Single-use tokens (invalidated after use)
- No token storage in logs or metrics

**Rate Limiting**:

- IP-based limits: 3 requests/hour default
- Configurable via `RATE_LIMIT_*` env vars
- In-memory store (consider Redis for multi-instance)
- Apply to both change and reset endpoints

**Input Validation**:

- Strict validation on all user inputs (see `validators/`)
- Reject malformed requests early
- Validate email format, username format, password policies
- No HTML/script injection vectors

## PR/Commit Checklist

**Before committing Go code**:

- [ ] Run `go fmt ./...` (or `pnpm prettier --write .`)
- [ ] Run `go vet ./...` (static analysis)
- [ ] Run `go test ./...` (all tests pass)
- [ ] Run `go build` (compilation check)
- [ ] Update package doc comments if API changed
- [ ] Add/update tests for new functionality
- [ ] Check for sensitive data in logs
- [ ] Verify error messages provide useful context

**Testing requirements**:

- New features must have tests
- Bug fixes must have regression tests
- Aim for ≥80% coverage on changed packages
- Integration tests for external dependencies

**Documentation**:

- Update package doc comments (godoc)
- Update [docs/api-reference.md](../docs/api-reference.md) for RPC changes
- Update [docs/development-guide.md](../docs/development-guide.md) for new setup steps
- Update environment variable examples in `.env` and docs

## Good vs Bad Examples

**✅ Good: Type-safe configuration**

```go
type Config struct {
    LDAPURL      string `env:"LDAP_URL" validate:"required,url"`
    BindDN       string `env:"LDAP_BIND_DN" validate:"required"`
    BindPassword string `env:"LDAP_BIND_PASSWORD" validate:"required"`
}

func LoadConfig() (*Config, error) {
    var cfg Config
    if err := env.Parse(&cfg); err != nil {
        return nil, fmt.Errorf("parse config: %w", err)
    }
    return &cfg, nil
}
```

**❌ Bad: Unsafe configuration**

```go
func LoadConfig() *Config {
    return &Config{
        LDAPURL: os.Getenv("LDAP_URL"),  // ❌ no validation, may be empty
    }
}
```

**✅ Good: Table-driven tests**

```go
func TestPasswordValidation(t *testing.T) {
    tests := []struct {
        name     string
        password string
        policy   PasswordPolicy
        wantErr  bool
    }{
        {"valid password", "Test123!", PasswordPolicy{MinLength: 8}, false},
        {"too short", "Ab1!", PasswordPolicy{MinLength: 8}, true},
        {"no numbers", "TestTest", PasswordPolicy{RequireNumbers: true}, true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidatePassword(tt.password, tt.policy)
            if (err != nil) != tt.wantErr {
                t.Errorf("got error %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

**❌ Bad: Non-descriptive tests**

```go
func TestPassword(t *testing.T) {
    err := ValidatePassword("test")  // ❌ what policy? what's expected?
    if err == nil {
        t.Fail()
    }
}
```

**✅ Good: Interface for testability**

```go
type EmailService interface {
    SendResetToken(ctx context.Context, to, token string) error
}

type SMTPService struct {
    host string
    port int
}

func (s *SMTPService) SendResetToken(ctx context.Context, to, token string) error {
    // real implementation
}

// In tests, use mock implementation
type MockEmailService struct {
    SendFunc func(ctx context.Context, to, token string) error
}
```

**❌ Bad: Hard-to-test concrete dependency**

```go
func ResetPassword(username string) error {
    service := NewSMTPService()  // ❌ hardcoded, can't mock
    return service.SendEmail(...)
}
```

## When Stuck

**Go-specific issues**:

1. **Module issues**: `go mod tidy` to clean dependencies
2. **Import errors**: Check `go.mod` requires correct versions
3. **Test failures**: `go test -v ./... -run FailingTest` for verbose output
4. **LDAP connection**: Verify `LDAP_URL` format and network access
5. **Email testing**: Ensure Docker running for testcontainers (MailHog)
6. **Rate limit testing**: Tests may fail if system time incorrect

**Debugging**:

```bash
# Verbose test output
go test -v ./internal/package/...

# Run specific test
go test -run TestName ./internal/package/

# Race detector (for concurrency issues)
go test -race ./...

# Build with debug info
go build -gcflags="all=-N -l"
```

**Common pitfalls**:

- **Nil pointer dereference**: Check error returns before using values
- **Context cancellation**: Always respect `context.Context` in long operations
- **Resource leaks**: Defer `Close()` calls immediately after acquiring resources
- **Goroutine leaks**: Ensure all goroutines can exit
- **Time zones**: Use `time.UTC` for consistency

## Package-Specific Notes

### email/

- Uses testcontainers for integration tests
- MailHog container spins up automatically in tests
- Mock `EmailService` interface for unit tests in other packages

### options/

- Configuration loaded from environment via `godotenv`
- Validation happens at startup (fail-fast)
- See `.env.local.example` for required variables

### ratelimit/

- In-memory store (map with mutex)
- Consider Redis for multi-instance deployments
- Tests use fixed time.Now for deterministic results

### resettoken/

- Crypto/rand for token generation (never math/rand)
- Base64 URL encoding (safe for URLs)
- Store tokens server-side with expiry

### rpc/

- JSON-RPC 2.0 specification compliance
- Error codes defined in [docs/api-reference.md](../docs/api-reference.md)
- Request validation before processing

### validators/

- Pure functions (no side effects)
- Configurable policies from environment
- Clear error messages for user feedback
