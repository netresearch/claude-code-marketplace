<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: 2025-09-29 -->

# AGENTS.md (root)

This file explains repo-wide conventions and where to find scoped rules.
**Precedence:** the **closest `AGENTS.md`** to the files you're changing wins. Root holds global defaults only.

## Global rules
- Keep diffs small; add tests for new code paths
- Ask first before: adding heavy deps, running full e2e suites, or repo-wide rewrites
- Never commit secrets or sensitive data to the repository
- Follow Go 1.24 conventions and idioms
- Maintain minimum test coverage of 40%

## Minimal pre-commit checks
- Typecheck (all packages): `go build -v ./...`
- Lint/format (file scope): `gofmt -w <file.go>` and `~/go/bin/golangci-lint run ./...`
- Unit tests (fast): `go test -v -race -short -timeout=10s ./...`

## Index of scoped AGENTS.md
- `./examples/AGENTS.md` — Example applications and usage patterns
- `./testutil/AGENTS.md` — Testing utilities and container management
- `./docs/AGENTS.md` — Documentation and guides

## When instructions conflict
- The nearest `AGENTS.md` wins. Explicit user prompts override files.
- For Go-specific patterns, defer to language idioms and standard library conventions