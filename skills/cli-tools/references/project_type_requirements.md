# Project Type Requirements

Map project types to required and recommended tools.

## Python Projects

**Detection files:** `pyproject.toml`, `setup.py`, `setup.cfg`, `requirements.txt`, `Pipfile`, `poetry.lock`

| Category | Tools | Priority |
|----------|-------|----------|
| **Required** | `python`, `uv` or `pip` | Critical |
| **Recommended** | `ruff`, `black`, `mypy` | High |
| **Optional** | `isort`, `bandit`, `pre-commit` | Medium |

**Install command:** `scripts/install_tool.sh python && scripts/install_tool.sh uv`

## Node.js Projects

**Detection files:** `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`

| Category | Tools | Priority |
|----------|-------|----------|
| **Required** | `node`, `npm` or `pnpm` or `yarn` | Critical |
| **Recommended** | `eslint`, `prettier` | High |
| **Optional** | `typescript` (if tsconfig.json) | Medium |

**Install command:** `scripts/install_tool.sh node`

## Rust Projects

**Detection files:** `Cargo.toml`, `Cargo.lock`

| Category | Tools | Priority |
|----------|-------|----------|
| **Required** | `rust` (provides cargo, rustc) | Critical |
| **Recommended** | `cargo-watch`, `cargo-audit` | Medium |

**Install command:** `scripts/install_tool.sh rust`

## Go Projects

**Detection files:** `go.mod`, `go.sum`

| Category | Tools | Priority |
|----------|-------|----------|
| **Required** | `go` | Critical |
| **Recommended** | `golangci-lint`, `gosec` | High |

**Install command:** `scripts/install_tool.sh go`

## PHP Projects

**Detection files:** `composer.json`, `composer.lock`, `*.php`

| Category | Tools | Priority |
|----------|-------|----------|
| **Required** | `php`, `composer` | Critical |
| **Recommended** | `phpstan`, `phpcs` | High |
| **Optional** | `phpunit`, `php-cs-fixer` | Medium |

**Install command:** `scripts/install_tool.sh php && scripts/install_tool.sh composer`

## Ruby Projects

**Detection files:** `Gemfile`, `Gemfile.lock`, `.ruby-version`

| Category | Tools | Priority |
|----------|-------|----------|
| **Required** | `ruby`, `bundler` | Critical |
| **Recommended** | `rubocop` | High |

**Install command:** `scripts/install_tool.sh ruby`

## Infrastructure Projects

**Detection files:** `Dockerfile`, `docker-compose.yml`, `terraform/*.tf`, `ansible/*.yml`

| Type | Required | Recommended |
|------|----------|-------------|
| Docker | `docker`, `compose` | `dive`, `trivy` |
| Terraform | `terraform` | `tfsec`, `trivy` |
| Kubernetes | `kubectl` | `helm` |
| Ansible | `ansible-core` | `ansible-lint` |

## Shell/Bash Projects

**Detection files:** `*.sh`, `Makefile`, `.bashrc`

| Category | Tools |
|----------|-------|
| **Recommended** | `shellcheck`, `shfmt` |

## Generic Development

**Always useful regardless of project type:**

| Tool | Purpose |
|------|---------|
| `git` | Version control |
| `gh` | GitHub CLI |
| `jq` | JSON processing |
| `yq` | YAML processing |
| `ripgrep` | Fast search |
| `fd` | Fast find |
| `fzf` | Fuzzy finder |
| `bat` | Better cat |
| `delta` | Better diff |

## Detection Priority

When multiple project types detected:
1. Check most specific first (Cargo.toml before generic files)
2. Report all detected types
3. Merge required tools from all types
