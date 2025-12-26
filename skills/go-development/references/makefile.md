# Standard Makefile Interface

A consistent Makefile interface enables CI/CD automation and cross-project tooling. This defines the standard targets every Go project should implement.

## Required Targets

| Target | Description | Exit Code |
|--------|-------------|-----------|
| `make test` | Run tests with race detection and coverage | 0 on pass, 1 on fail |
| `make build` | Build the application binary | 0 on success |
| `make lint` | Run golangci-lint | 0 on pass, 1 on issues |

## Recommended Targets

| Target | Description |
|--------|-------------|
| `make fuzz` | Run fuzz tests (30s per target) |
| `make vuln-check` | Run govulncheck |
| `make security` | Run security checks (gosec, gitleaks) |
| `make all` | lint + test + build |
| `make clean` | Remove build artifacts |
| `make fmt` | Format code |
| `make setup` | Install dependencies and tools |
| `make dev-check` | Pre-commit quality gates |

## Template

```makefile
# Project Makefile
# Implements standard interface for CI/CD compatibility

# Build configuration
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS := -s -w -X 'main.version=$(VERSION)' -X 'main.commit=$(COMMIT)'
BUILDFLAGS := -ldflags="$(LDFLAGS)" -trimpath

# Coverage settings
COVERAGE_THRESHOLD := 80
COVERAGE_FILE := coverage.out

.DEFAULT_GOAL := all

# =============================================================================
# STANDARD INTERFACE (Required)
# =============================================================================

.PHONY: all
all: lint test build

.PHONY: test
test: ## Run tests with race detection and coverage
	@go test -race -coverprofile=$(COVERAGE_FILE) -covermode=atomic ./...
	@go tool cover -func=$(COVERAGE_FILE) | tail -n 1

.PHONY: build
build: ## Build the application binary
	@CGO_ENABLED=0 go build $(BUILDFLAGS) -o bin/app ./cmd/app

.PHONY: lint
lint: ## Run golangci-lint
	@golangci-lint run --timeout 5m

# =============================================================================
# RECOMMENDED TARGETS
# =============================================================================

.PHONY: fuzz
fuzz: ## Run fuzz tests (30s per target)
	@for pkg in $$(go list ./... | grep -v /vendor/); do \
		for fuzz in $$(go test -list='^Fuzz' $$pkg 2>/dev/null | grep '^Fuzz'); do \
			echo "Fuzzing $$fuzz in $$pkg..."; \
			go test -fuzz=$$fuzz -fuzztime=30s $$pkg || exit 1; \
		done; \
	done

.PHONY: vuln-check
vuln-check: ## Run govulncheck
	@go run golang.org/x/vuln/cmd/govulncheck@latest ./...

.PHONY: security
security: ## Run security checks (gosec, gitleaks)
	@gosec ./...
	@gitleaks detect

.PHONY: fmt
fmt: ## Format code
	@gofmt -w $$(git ls-files '*.go')
	@goimports -w $$(git ls-files '*.go')

.PHONY: vet
vet: ## Run go vet
	@go vet ./...

.PHONY: clean
clean: ## Remove build artifacts
	@rm -rf bin/ $(COVERAGE_FILE) coverage-reports/

.PHONY: setup
setup: ## Install dependencies and tools
	@go mod download
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@go install golang.org/x/vuln/cmd/govulncheck@latest

.PHONY: dev-check
dev-check: fmt vet lint security test ## Pre-commit quality gates
	@echo "All checks passed!"

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
```

## CI Integration

The standard interface enables simple CI workflows:

```yaml
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
      - run: make lint
      - run: make test
      - run: make build
```

## Coverage Enforcement

```makefile
.PHONY: test-coverage
test-coverage: test
	@COVERAGE=$$(go tool cover -func=$(COVERAGE_FILE) | grep "^total:" | awk '{print $$3}' | sed 's/%//'); \
	if [ "$${COVERAGE%.*}" -lt "$(COVERAGE_THRESHOLD)" ]; then \
		echo "Coverage $${COVERAGE}% below threshold $(COVERAGE_THRESHOLD)%"; \
		exit 1; \
	fi
```

## Docker Integration

```makefile
DOCKER_IMAGE := myapp
DOCKER_TAG := $(VERSION)

.PHONY: docker-build
docker-build: ## Build Docker image
	@docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

.PHONY: docker-test
docker-test: ## Run tests in Docker
	@docker run --rm $(DOCKER_IMAGE):$(DOCKER_TAG) make test
```

## Related

- `references/linting.md` - golangci-lint configuration
- `references/testing.md` - Testing patterns
- `references/fuzz-testing.md` - Fuzz testing setup
- `references/mutation-testing.md` - Mutation testing setup
