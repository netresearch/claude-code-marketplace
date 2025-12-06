# Enterprise Readiness Skill

A [Claude Code](https://claude.ai/claude-code) skill for assessing and enhancing software projects to meet enterprise-grade standards for security, quality, and automation.

## Overview

This skill provides a comprehensive framework with:
- **Complete OpenSSF Badge Coverage** - Passing, Silver, and Gold level criteria
- **Dynamic Scoring System** - Fair assessment across different tech stacks
- **120+ Security & Quality Checks** - Covering supply chain, testing, governance, and automation
- **Implementation Patterns** - Ready-to-use code for SLSA, Cosign, GitHub hardening
- **Extensible Architecture** - General → Platform → Language → Badge Level modular design

## OpenSSF Framework Alignment

| Framework | Coverage |
|-----------|----------|
| OpenSSF Scorecard | 18/20 checks (~90%) |
| Best Practices Badge - Passing | 68/68 criteria (100%) |
| Best Practices Badge - Silver | 55 criteria documented |
| Best Practices Badge - Gold | 24 criteria documented |
| SLSA Framework | Full L1-L3 |
| S2C2F | 6/8 practices (~75%) |

## Installation

### Option 1: Direct Installation

```bash
# Clone to your Claude skills directory
git clone https://github.com/netresearch/enterprise-readiness-skill.git ~/.claude/skills/enterprise-readiness
```

### Option 2: Download ZIP

Download the [latest release](https://github.com/netresearch/enterprise-readiness-skill/releases) and extract to `~/.claude/skills/enterprise-readiness/`.

## Usage

The skill triggers automatically on keywords like:
- "enterprise ready"
- "production ready"
- "security hardening"
- "supply chain security"
- "SLSA"
- "OpenSSF Scorecard"
- "silver badge" / "gold badge"

### Example Prompts

```
"Assess this project for enterprise readiness"
"How can I make this repository production ready?"
"Implement SLSA Level 3 provenance for this project"
"Harden the GitHub Actions workflows"
"What do I need for OpenSSF Silver badge?"
"Help me achieve Gold level certification"
```

## Assessment Categories

### Core Assessment (120 points)

| Category | Points | Description |
|----------|--------|-------------|
| Governance & Policy | 10 | Security policy, licensing, maintenance, SLAs |
| Supply Chain Security | 15 | Provenance, signing, SBOMs, checksums |
| Dependency Consumption | 10 | Vulnerability scanning, license compliance |
| Quality Gates | 10 | Coverage thresholds, static analysis |
| Testing Layers | 10 | Unit, integration, fuzz, E2E tests |
| Documentation | 5 | README, CONTRIBUTING, API docs |
| **Total General** | **60** | Universal checks for any platform/language |
| GitHub Hardening | 40 | Harden runner, pinned actions, permissions |
| Go Best Practices | 20 | Static builds, golangci-lint, govulncheck |

### Badge Level Criteria

| Level | Criteria | Focus |
|-------|----------|-------|
| Passing | 68 | Technical basics, security policy |
| Silver | +55 | Governance, documentation, 80% coverage |
| Gold | +24 | Organizational maturity, 90% coverage, audits |

## Scoring

Uses **Dynamic Denominator** scoring for fairness:

```
Score = (Points_Earned / Max_Points_Applicable) × 100
```

| Score | Grade | Status |
|-------|-------|--------|
| 90-100 | A | Enterprise Ready |
| 80-89 | B | Production Ready (minor gaps) |
| 70-79 | C | Development Ready (needs hardening) |
| 60-69 | D | Basic (significant gaps) |
| Below 60 | F | Not Ready (major improvements needed) |

## Structure

```
enterprise-readiness/
├── SKILL.md                              # Main skill with workflow and patterns
├── scripts/
│   ├── verify-badge-criteria.sh          # Automated OpenSSF Badge verification
│   ├── check-coverage-threshold.sh       # Statement coverage validation
│   ├── check-branch-coverage.sh          # Branch coverage analysis (Gold)
│   ├── add-spdx-headers.sh               # Add SPDX license headers (Gold)
│   ├── verify-spdx-headers.sh            # Verify SPDX headers exist (Gold)
│   ├── analyze-bus-factor.sh             # Bus factor analysis (Silver/Gold)
│   ├── verify-reproducible-build.sh      # Reproducible build check (Gold)
│   ├── verify-signed-tags.sh             # Git tag signature verification (Silver)
│   ├── verify-review-requirements.sh     # PR review requirements check (Silver/Gold)
│   └── check-tls-minimum.sh              # TLS 1.2+ enforcement check (Silver)
├── assets/
│   ├── templates/
│   │   ├── GOVERNANCE.md                 # Governance document template
│   │   ├── ARCHITECTURE.md               # Architecture doc template
│   │   ├── CODE_OF_CONDUCT.md            # Contributor Covenant v2.1
│   │   ├── ROADMAP.md                    # One-year roadmap template (Silver)
│   │   ├── SECURITY_AUDIT.md             # Security self-audit template (Gold)
│   │   └── BADGE_EXCEPTIONS.md           # N/A criteria justifications (Gold)
│   └── workflows/
│       └── dco-check.yml                 # DCO enforcement workflow
└── references/
    ├── general.md                        # Universal checks (60 points)
    ├── github.md                         # GitHub-specific checks (40 points)
    ├── go.md                             # Go-specific checks (20 points)
    ├── openssf-badge-silver.md           # Silver level criteria (55 items)
    ├── openssf-badge-gold.md             # Gold level criteria (24 items)
    ├── dco-implementation.md             # DCO setup guide
    ├── signed-releases.md                # Cosign/GPG signing guide
    ├── reproducible-builds.md            # Reproducible build guide
    ├── quick-start-guide.md              # Quick start documentation guide
    ├── badge-display.md                  # Badge display and verification
    ├── 2fa-enforcement.md                # Two-factor authentication guide
    ├── security-hardening.md             # TLS 1.2+, headers, hardening
    ├── test-invocation.md                # Test invocation and coverage
    ├── solo-maintainer-guide.md          # Solo maintainer guidance (NEW)
    ├── dynamic-analysis.md               # Fuzzing, race detection (NEW)
    └── branch-coverage.md                # Branch coverage tools (NEW)
```

## Extensibility

The skill is designed for extension. Additional modules can be added:

**Platform Modules (planned):**
- `references/gitlab.md`
- `references/bitbucket.md`
- `references/azure-devops.md`

**Language Modules (planned):**
- `references/python.md`
- `references/typescript.md`
- `references/rust.md`
- `references/java.md`

## Key Implementation Patterns

### SLSA Level 3 Provenance

```yaml
uses: slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml@v2.1.0
with:
  go-version-file: go.mod
  config-file: .slsa-goreleaser/${{ matrix.target }}.yml
  evaluated-envs: "VERSION:${{ github.ref_name }}, COMMIT:${{ github.sha }}"
```

### Keyless Signing with Cosign

```yaml
- uses: sigstore/cosign-installer@v3.8.2
- run: cosign sign-blob --yes --output-certificate file.pem --output-signature file.sig file.txt
```

### Workflow Hardening

```yaml
permissions: read-all

jobs:
  build:
    steps:
      - uses: step-security/harden-runner@SHA
        with:
          egress-policy: audit
      - uses: actions/checkout@SHA  # Pin to SHA, not tag
```

### Badge Level Quick Reference

**Passing:** SECURITY.md, LICENSE, CI/CD, static analysis
**Silver:** DCO, GOVERNANCE.md, ARCHITECTURE.md, 80% coverage, signed releases
**Gold:** 90% coverage, 2-person review, security audit, reproducible builds

## Sources

This skill was developed based on:
- [SLSA Framework](https://slsa.dev/) - Supply chain security levels
- [OpenSSF Scorecard](https://securityscorecards.dev/) - Security health metrics
- [OpenSSF Best Practices Badge](https://www.bestpractices.dev/) - Project maturity certification
- [Sigstore/Cosign](https://docs.sigstore.dev/) - Keyless signing
- [step-security/harden-runner](https://github.com/step-security/harden-runner) - Workflow hardening
- [Contributor Covenant](https://www.contributor-covenant.org/) - Code of conduct
- [Developer Certificate of Origin](https://developercertificate.org/) - DCO
- Real-world implementation experience from the [ofelia](https://github.com/netresearch/ofelia) project

## Contributing

Contributions are welcome! Please feel free to submit PRs for:
- Additional platform modules (GitLab, Bitbucket, Azure DevOps)
- Additional language modules (Python, TypeScript, Rust, Java)
- New security checks and patterns
- Documentation improvements
- Badge criteria updates

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

Developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/).

---

**Made with ❤️ for Open Source by [Netresearch](https://www.netresearch.de/)**
