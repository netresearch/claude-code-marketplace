# Agent Guidelines

<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: 2025-10-09 -->

**Precedence**: Nearest AGENTS.md wins. This is the root file with global defaults.

**Project**: LDAP Selfservice Password Changer — hybrid Go + TypeScript web application with WCAG 2.2 AAA accessibility compliance.

## Quick Navigation

- [internal/AGENTS.md](internal/AGENTS.md) - Go backend services
- [internal/web/AGENTS.md](internal/web/AGENTS.md) - TypeScript frontend & Tailwind CSS

## Global Defaults

### Project Overview

Self-service password change/reset web app for LDAP/ActiveDirectory with email-based password reset, rate limiting, and strict accessibility standards. Single binary deployment with embedded assets.

**Stack**: Go 1.25 + Fiber, TypeScript (ultra-strict), Tailwind CSS 4, Docker multi-stage builds, pnpm 10.18

**Key characteristics**:

- Docker-first: All dev/CI must work via Docker
- Accessibility: WCAG 2.2 AAA compliance (7:1 contrast, keyboard nav, screen readers)
- Type-safe: Go with testcontainers, TypeScript with all strict flags
- Security-focused: LDAPS, rate limiting, token-based reset, no password storage

### Setup

**Prerequisites**: Docker + Docker Compose (required), Go 1.25+, Node.js 24+, pnpm 10.18+ (for native dev)

```bash
# Clone and setup environment
git clone <repo>
cd ldap-selfservice-password-changer
cp .env.local.example .env.local  # Edit with your LDAP config

# Docker (recommended)
docker compose --profile dev up

# Native development
pnpm install
go mod download
pnpm dev  # Runs concurrent TS watch, CSS watch, and Go with hot-reload
```

See [docs/development-guide.md](docs/development-guide.md) for comprehensive setup.

### Build & Test Commands

**Package manager**: pnpm (specified in package.json: `pnpm@10.18.1`)

```bash
# Build everything
pnpm build                # Build frontend assets + Go binary

# Frontend only
pnpm build:assets         # TypeScript + Tailwind CSS
pnpm js:build             # TypeScript compile + minify
pnpm css:build            # Tailwind CSS + PostCSS

# Development (watch mode)
pnpm dev                  # Concurrent: TS watch, CSS watch, Go hot-reload
pnpm js:dev               # TypeScript watch
pnpm css:dev              # CSS watch
pnpm go:dev               # Go with nodemon hot-reload

# Tests
go test -v ./...          # All Go tests with verbose output
go test ./internal/...    # Specific package tests

# Formatting
pnpm prettier --write .   # Format TS, Go templates, config files
pnpm prettier --check .   # Check formatting (CI)

# Type checking
pnpm js:build             # TypeScript strict compilation (no emit in dev)
go build -v ./...         # Go compilation + type checking
```

**CI commands** (from `.github/workflows/check.yml`):

- Type check: `pnpm js:build` and `go build -v ./...`
- Format check: `pnpm prettier --check .`
- Tests: `go test -v ./...`

### Code Style

**TypeScript**:

- Ultra-strict tsconfig: `strict: true`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noPropertyAccessFromIndexSignature`
- Prettier formatting: 120 char width, semicolons, double quotes, 2-space tabs
- No `any` types - use proper type definitions
- Follow existing patterns in `internal/web/static/`

**Go**:

- Standard Go formatting (`go fmt`)
- Prettier with `prettier-plugin-go-template` for HTML templates
- Follow Go project layout: `internal/` for private packages, `main.go` at root
- Use testcontainers for integration tests (see `*_test.go` files)
- Error wrapping with context

**General**:

- Composition over inheritance
- SOLID, KISS, DRY, YAGNI principles
- Law of Demeter: minimize coupling
- No secrets in VCS (use .env.local, excluded from git)

### Security

- **No secrets in git**: Use `.env.local` (gitignored), never commit LDAP credentials
- **LDAPS required**: Production must use encrypted LDAP connections
- **Rate limiting**: 3 requests/hour per IP (configurable via `RATE_LIMIT_*` env vars)
- **Token security**: Cryptographic random tokens with configurable expiry
- **Input validation**: Strict validation on all user inputs (see `internal/validators/`)
- **Dependency scanning**: Renovate enabled, review changelogs for major updates
- **No PII logging**: Redact sensitive data in logs
- **Run as non-root**: Dockerfile uses UID 65534 (nobody)

### PR/Commit Checklist

✅ **Before commit**:

- [ ] Run `pnpm prettier --write .` (format all)
- [ ] Run `pnpm js:build` (TypeScript strict check)
- [ ] Run `go test ./...` (all tests pass)
- [ ] Run `go build` (compilation check)
- [ ] No secrets in changed files
- [ ] Update docs if behavior changed
- [ ] WCAG 2.2 AAA compliance maintained (if UI changed)

✅ **Commit format**: Conventional Commits

```
type(scope): description

Examples:
feat(auth): add password reset via email
fix(validators): correct password policy regex
docs(api): update JSON-RPC examples
chore(deps): update pnpm to v10.18.1
```

**No Claude attribution** in commit messages.

✅ **PR requirements**:

- [ ] All CI checks pass (types, formatting, tests)
- [ ] Keep PRs small (~≤300 net LOC if possible)
- [ ] Include ticket ID if applicable: `fix(rate-limit): ISSUE-123: fix memory leak`
- [ ] Update relevant docs in same PR (README, AGENTS.md, docs/)

### Good vs Bad Examples

**✅ Good - TypeScript strict types**:

```typescript
interface PasswordPolicy {
  minLength: number;
  requireNumbers: boolean;
}

function validatePassword(password: string, policy: PasswordPolicy): boolean {
  const hasNumber = /\d/.test(password);
  return password.length >= policy.minLength && (!policy.requireNumbers || hasNumber);
}
```

**❌ Bad - Using any or unsafe access**:

```typescript
function validatePassword(password: any, policy: any) {
  // ❌ any types
  return password.length >= policy.minLength; // ❌ unsafe access
}
```

**✅ Good - Go error handling**:

```go
func connectLDAP(config LDAPConfig) (*ldap.Conn, error) {
    conn, err := ldap.DialURL(config.URL)
    if err != nil {
        return nil, fmt.Errorf("failed to connect to LDAP at %s: %w", config.URL, err)
    }
    return conn, nil
}
```

**❌ Bad - Ignoring errors**:

```go
func connectLDAP(config LDAPConfig) *ldap.Conn {
    conn, _ := ldap.DialURL(config.URL)  // ❌ ignoring error
    return conn                           // ❌ may return nil
}
```

**✅ Good - Accessible UI**:

```html
<button type="submit" aria-label="Submit password change" class="bg-blue-600 hover:bg-blue-700 focus:ring-4">
  Change Password
</button>
```

**❌ Bad - Inaccessible UI**:

```html
<div onclick="submit()">Submit</div>
❌ not keyboard accessible, wrong semantics
```

### When Stuck

1. **Check existing docs**: [docs/](docs/) has comprehensive guides
2. **Review similar code**: Look for patterns in `internal/` packages
3. **Run tests**: `go test -v ./...` often reveals issues
4. **Check CI logs**: GitHub Actions shows exact failure points
5. **Verify environment**: Ensure `.env.local` is properly configured
6. **Docker issues**: `docker compose down -v && docker compose --profile dev up --build`
7. **Type errors**: Review `tsconfig.json` strict flags, use proper types
8. **Accessibility**: See [docs/accessibility.md](docs/accessibility.md) for WCAG 2.2 AAA guidelines

### House Rules

**Docker-First Philosophy**:

- All dev and CI must work via Docker Compose
- Native setup is optional convenience, not requirement
- Use profiles in compose.yml: `--profile dev` or `--profile test`

**Documentation Currency**:

- Update docs in same PR as code changes
- No drift between code and documentation
- Keep README, AGENTS.md, and docs/ synchronized

**Testing Standards**:

- Aim for ≥80% coverage on changed code
- Use testcontainers for integration tests (see existing `*_test.go`)
- For bugfixes: write failing test first (TDD)
- Tests must pass before PR approval

**Scope Discipline**:

- Build only what's requested
- No speculative features
- MVP first, iterate based on feedback
- YAGNI: You Aren't Gonna Need It

**Accessibility Non-Negotiable**:

- WCAG 2.2 AAA compliance required
- 7:1 contrast ratios for text
- Full keyboard navigation support
- Screen reader tested (VoiceOver/NVDA)
- See [docs/accessibility.md](docs/accessibility.md)

**Commit Practices**:

- Atomic commits: one logical change per commit
- Conventional Commits format enforced
- Never commit secrets or `.env.local`
- Keep PRs focused and reviewable

**Type Safety**:

- TypeScript: No `any`, all strict flags enabled
- Go: Leverage type system, avoid `interface{}`
- Validate inputs at boundaries

**Dependency Management**:

- Renovate auto-updates enabled
- Major version updates require changelog review
- Use Context7 MCP or official docs for migrations
- Keep pnpm-lock.yaml and go.sum committed
