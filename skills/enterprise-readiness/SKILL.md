---
name: enterprise-readiness
description: "Assess and enhance software projects for enterprise-grade security, quality, and automation. Use when evaluating projects for production readiness, implementing supply chain security (SLSA, signing, SBOMs), hardening CI/CD pipelines, or establishing quality gates. Aligned with OpenSSF Scorecard, Best Practices Badge (all levels), SLSA Framework, and S2C2F. By Netresearch."
---

# Enterprise Readiness Assessment v3.4.0

A comprehensive framework for assessing and improving software projects to meet enterprise-grade
standards for security, quality, and automation. Includes automation scripts, document templates,
and implementation guides. Aligned with major OpenSSF programs.

**v3.4 Highlights:**
- New scripts: signed tag verification, PR review requirements, TLS 1.2+ enforcement
- Complete Silver/Gold badge criteria automation coverage
- Previous: bus factor, SPDX, reproducible builds, branch coverage scripts
- Previous: security audit, badge exceptions templates; solo maintainer guides

## OpenSSF Framework Alignment

This skill provides complete coverage across four major OpenSSF frameworks:

| Framework | Focus | Coverage |
|-----------|-------|----------|
| [OpenSSF Scorecard](https://securityscorecards.dev/) | Automated security health metrics | 18/20 checks (~90%) |
| [Best Practices Badge - Passing](https://www.bestpractices.dev/) | Project maturity (basic) | 68/68 criteria (100%) |
| [Best Practices Badge - Silver](https://www.bestpractices.dev/) | Project maturity (advanced) | 55 criteria documented |
| [Best Practices Badge - Gold](https://www.bestpractices.dev/) | Project maturity (highest) | 24 criteria documented |
| [SLSA Framework](https://slsa.dev/) | Supply chain integrity levels | Full L1-L3 tracking |
| [S2C2F](https://github.com/ossf/s2c2f) | Secure dependency consumption | 6/8 practices (~75%) |

## Purpose

Systematically evaluate and enhance projects across six dimensions:

1. **Governance & Policy** - Security policies, SLAs, maintenance, licensing
2. **Supply Chain Security** - Provenance, signing, SBOMs, binary hygiene
3. **Dependency Consumption** - Ingestion controls, vulnerability scanning, license compliance
4. **Quality Gates** - Testing, coverage, static analysis, secret scanning
5. **Platform Hardening** - CI/CD security, workflow injection prevention, code review
6. **Badge Level Progression** - Passing → Silver → Gold certification path

## Assessment Workflow

### Phase 1: Discovery

1. Identify the hosting platform (GitHub, GitLab, Bitbucket, Azure DevOps)
2. Identify primary language(s) (Go, Python, TypeScript, Rust, Java)
3. Scan existing CI/CD configuration files
4. Check for security tooling presence (SBOM, signing, scanning)
5. Review repository security settings
6. Check current OpenSSF Best Practices Badge level

### Phase 2: Scoring

Apply checklists using **Dynamic Denominator** scoring:
- Calculate `Score = (Points_Earned / Max_Points_Applicable) * 100`
- Skip platform/language sections that don't apply
- This ensures fair scoring across different tech stacks

Load appropriate reference files based on discovered stack:
- `references/general.md` - Always apply (60 points, universal checks)
- `references/github.md` - For GitHub-hosted projects (40 points)
- `references/go.md` - For Go projects (20 points)
- `references/openssf-badge-silver.md` - For Silver level certification (55 criteria)
- `references/openssf-badge-gold.md` - For Gold level certification (24 criteria)

**Scoring Example**:
- GitHub + Go project: Max = 60 + 40 + 20 = 120 points
- GitHub + Python project: Max = 60 + 40 = 100 points (no Go checks)
- GitLab + Go project: Max = 60 + 20 = 80 points (no GitHub checks)

### Phase 3: Badge Level Assessment

For OpenSSF Best Practices Badge progression:

| Level | Requirements | Reference |
|-------|--------------|-----------|
| Passing | 68 criteria, mostly technical | `references/general.md` |
| Silver | 55 additional criteria, governance focus | `references/openssf-badge-silver.md` |
| Gold | 24 additional criteria, organizational maturity | `references/openssf-badge-gold.md` |

**Coverage Threshold Progression:**
| Level | Statement Coverage | Branch Coverage |
|-------|-------------------|-----------------|
| Basic/Passing | 60% minimum | N/A |
| Silver | 80% minimum | N/A |
| Gold | 90% minimum | 80% minimum |

### Phase 4: Gap Analysis

1. List missing security controls with severity:
   - **Critical Blockers** - Must fix immediately (script injection, no branch protection)
   - **High Priority** - Should fix before production (missing SLSA, no code review)
   - **Medium Priority** - Plan for improvement (coverage gaps, missing SBOM)
   - **Low Priority** - Nice to have (documentation gaps)

2. Map findings to OpenSSF Scorecard checks for context

3. For badge progression, identify:
   - Currently met criteria
   - Missing criteria with implementation difficulty
   - N/A criteria with justification

4. Prioritize by impact and implementation effort

### Phase 5: Implementation

For each identified gap:
1. Provide specific code/configuration from this skill's patterns
2. Reference implementation patterns from the assessed project
3. Verify implementation works
4. Re-score after changes
5. Update badge status on bestpractices.dev

## Scoring Interpretation

| Score | Grade | Status |
|-------|-------|--------|
| 90-100 | A | Enterprise Ready |
| 80-89 | B | Production Ready (minor gaps) |
| 70-79 | C | Development Ready (needs hardening) |
| 60-69 | D | Basic (significant gaps) |
| Below 60 | F | Not Ready (major improvements needed) |

## Output Format

Generate a structured report:

```markdown
# Enterprise Readiness Assessment

## Executive Summary
- **Score**: X/100 (Grade: Y)
- **Platform**: GitHub/GitLab/etc.
- **Language(s)**: Go/Python/etc.
- **OpenSSF Scorecard Alignment**: X/20 checks passing
- **Best Practices Badge**: Passing/Silver/Gold or X% toward next level

## Critical Blockers (Stop-Ship)
[Items requiring immediate attention - script injection, exposed secrets, etc.]

## High Priority Findings
[Security gaps that should be addressed before production]

## Detailed Findings

### Governance & Policy (X/10 points)
[Security policy, licensing, maintenance status]

### Supply Chain Security (X/15 points)
[Provenance, signing, SBOM, binary artifacts]

### Dependency Consumption (X/10 points)
[S2C2F alignment, vulnerability scanning, license compliance]

### Quality Gates (X/10 points)
[Coverage, static analysis, secret scanning]

### Testing Layers (X/10 points)
[Unit, integration, fuzz, E2E tests]

### Platform-Specific (X/Y points)
[GitHub/GitLab specific findings]

### Language-Specific (X/Y points)
[Go/Python/TypeScript specific findings]

## OpenSSF Scorecard Mapping
| Check | Status | Notes |
|-------|--------|-------|
| Dangerous-Workflow | ✅/❌ | ... |
| Code-Review | ✅/❌ | ... |
| ... | ... | ... |

## Best Practices Badge Progress
| Level | Status | Criteria Met |
|-------|--------|--------------|
| Passing | ✅ | 68/68 (100%) |
| Silver | 🔄 | X/55 (Y%) |
| Gold | ⏳ | X/24 (Y%) |

## Improvement Roadmap
[Prioritized action items with implementation guidance]
```

## Critical Security Patterns

### Dangerous Workflow Prevention (CRITICAL)

**NEVER interpolate user input directly in workflow scripts:**

```yaml
# DANGEROUS - Script injection vulnerability
- run: echo "Title: ${{ github.event.issue.title }}"

# SAFE - Use environment variables
- name: Process issue
  env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "Title: $TITLE"
```

### SLSA Level 3 Provenance (GitHub)

```yaml
uses: slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml@v2.1.0
with:
  go-version-file: go.mod
  config-file: .slsa-goreleaser/${{ matrix.target }}.yml
  evaluated-envs: "VERSION:${{ github.ref_name }}, COMMIT:${{ github.sha }}"
  upload-assets: true
```

**Critical**: Use `{{ .Env.VERSION }}` in config files, not `{{ .Tag }}`.

### Keyless Signing with Cosign

```yaml
- uses: sigstore/cosign-installer@v3.8.2
- run: |
    cosign sign-blob --yes \
      --output-certificate file.pem \
      --output-signature file.sig \
      file.txt
```

### Workflow Hardening

```yaml
permissions: read-all  # At workflow level

jobs:
  build:
    permissions:
      contents: write  # Escalate only as needed
    steps:
      - uses: step-security/harden-runner@0634a2670c59f64b4a01f0f96f84700a4088b9f0 # v2.12.0
        with:
          egress-policy: audit
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

### Quality Gate Enforcement

```yaml
- name: Check coverage threshold
  run: |
    COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')
    if (( $(echo "$COVERAGE < 60" | bc -l) )); then
      echo "Coverage $COVERAGE% is below 60% threshold"
      exit 1
    fi
```

## Badge Level Quick Reference

### Passing Level Requirements (68 criteria)
- Security policy (SECURITY.md)
- License file
- Public issue tracker
- CI/CD with testing
- Static analysis
- Vulnerability handling process

### Silver Level Requirements (55 additional criteria)
- DCO enforcement
- Governance documentation
- Architecture documentation
- 80% test coverage
- Signed releases AND tags
- TLS 1.2+ enforcement
- Integration testing
- Code review enforcement

### Gold Level Requirements (24 additional criteria)
- 90% statement coverage
- 80% branch coverage
- Two-person review
- Security audit completed
- Reproducible builds
- SPDX headers on all files
- Multiple unassociated contributors

## Common Pitfalls (Lessons Learned)

1. **Script Injection**: Never use `${{ github.event.* }}` directly in `run:` blocks
2. **SLSA Template Syntax**: Use `{{ .Env.VERSION }}` with `evaluated-envs`, not `{{ .Tag }}`
3. **GitHub CLI Context**: Jobs using `gh` commands need `actions/checkout` first
4. **YAML Heredocs**: Careful indentation required for multi-line scripts
5. **Merge Queue Events**: Must handle `merge_group` event type explicitly
6. **Action Pinning**: SHA pins prevent supply chain attacks but need Dependabot for updates
7. **pull_request_target**: Dangerous trigger - never checkout PR code with it
8. **Binary Artifacts**: Generated binaries in source repos are unverifiable
9. **Solo Maintainer**: Some Silver/Gold criteria require justification (bus factor, 2-person review)
10. **Self-Approval**: GitHub doesn't allow self-approval - affects review requirements

## Bundled Resources

This skill includes automation scripts, templates, and detailed guides for implementing
enterprise readiness requirements.

### Automation Scripts (`scripts/`)

| Script | Purpose | Usage |
|--------|---------|-------|
| `verify-badge-criteria.sh` | Automated OpenSSF Badge verification | `./scripts/verify-badge-criteria.sh [--level passing\|silver\|gold]` |
| `check-coverage-threshold.sh` | Statement coverage validation | `./scripts/check-coverage-threshold.sh [threshold] [coverage-file]` |
| `check-branch-coverage.sh` | Branch coverage analysis (Gold) | `./scripts/check-branch-coverage.sh [--threshold 80]` |
| `add-spdx-headers.sh` | Add SPDX license headers (Gold) | `./scripts/add-spdx-headers.sh [license] [copyright]` |
| `verify-spdx-headers.sh` | Verify SPDX headers exist (Gold) | `./scripts/verify-spdx-headers.sh [--fix] [directory]` |
| `analyze-bus-factor.sh` | Bus factor analysis (Silver/Gold) | `./scripts/analyze-bus-factor.sh [--days 365] [--threshold 2]` |
| `verify-reproducible-build.sh` | Reproducible build check (Gold) | `./scripts/verify-reproducible-build.sh [build-cmd] [output]` |
| `verify-signed-tags.sh` | Git tag signature verification (Silver) | `./scripts/verify-signed-tags.sh [tag] [--check-all]` |
| `verify-review-requirements.sh` | PR review requirements check (Silver/Gold) | `./scripts/verify-review-requirements.sh [--level silver\|gold]` |
| `check-tls-minimum.sh` | TLS 1.2+ enforcement check (Silver) | `./scripts/check-tls-minimum.sh [directory]` |

### Document Templates (`assets/templates/`)

| Template | Purpose | OpenSSF Level |
|----------|---------|---------------|
| `GOVERNANCE.md` | Project governance, roles, decisions | Silver |
| `ARCHITECTURE.md` | Technical architecture documentation | Silver |
| `CODE_OF_CONDUCT.md` | Contributor Covenant v2.1 | Passing |
| `ROADMAP.md` | One-year project roadmap | Silver |
| `SECURITY_AUDIT.md` | Security self-audit template | Gold |
| `BADGE_EXCEPTIONS.md` | N/A criteria justifications | Gold |

### Workflow Templates (`assets/workflows/`)

| Workflow | Purpose | OpenSSF Level |
|----------|---------|---------------|
| `dco-check.yml` | DCO sign-off enforcement | Silver |

### Implementation Guides (`references/`)

| Guide | Purpose | Key Topics |
|-------|---------|------------|
| `dco-implementation.md` | DCO setup and enforcement | Git config, CI integration, PR templates |
| `signed-releases.md` | Artifact and tag signing | Cosign keyless, GPG, SLSA provenance |
| `reproducible-builds.md` | Deterministic builds | Go/Rust/Python patterns, verification |
| `quick-start-guide.md` | Quick start documentation | Installation, first run, templates |
| `badge-display.md` | Badge display and verification | README badges, progress tracking |
| `2fa-enforcement.md` | Two-factor authentication | GitHub org 2FA, secure methods |
| `security-hardening.md` | Security hardening | TLS 1.2+, headers, input validation |
| `test-invocation.md` | Test invocation and coverage | Standard commands, CI, thresholds |
| `solo-maintainer-guide.md` | Solo maintainer guidance | N/A criteria, compensating controls |
| `dynamic-analysis.md` | Dynamic analysis techniques | Fuzzing, race detection, sanitizers |
| `branch-coverage.md` | Branch coverage analysis | Tools, strategies, 80% threshold |

## Extensibility

This skill uses a modular architecture. Additional platform and language modules
can be added to `references/` following the same checklist structure:

**Scoring Modules:**
- `references/general.md` - Universal checks (60 points)
- `references/github.md` - GitHub-specific (40 points)
- `references/go.md` - Go-specific (20 points)

**Badge Criteria Modules:**
- `references/openssf-badge-silver.md` - Silver level criteria (55 items)
- `references/openssf-badge-gold.md` - Gold level criteria (24 items)

**Future Platform Modules:**
- `references/gitlab.md`
- `references/bitbucket.md`
- `references/azure-devops.md`

**Future Language Modules:**
- `references/python.md`
- `references/typescript.md`
- `references/rust.md`
- `references/java.md`

## Related Skills

### security-audit-skill
**Use for**: Deep security audits of PHP codebases

While this skill focuses on enterprise infrastructure, CI/CD, and OpenSSF compliance, the security-audit-skill provides complementary code-level security analysis:
- OWASP Top 10 vulnerability patterns
- XXE prevention patterns
- SQL injection detection
- CVSS v3.1 scoring guide
- PHP-specific security patterns

**When to use**: After achieving baseline enterprise readiness, use security-audit-skill for detailed code-level security review, especially for Gold badge security audit requirements.

### git-workflow-skill
**Use for**: Git branching strategies and commit conventions

The git-workflow-skill complements enterprise readiness with:
- Conventional commits for automated versioning
- Branch protection strategies
- PR workflow patterns
- CI/CD integration patterns

**When to use**: When implementing DCO enforcement, signed commits, or release automation.

## Resources

- [SLSA Framework](https://slsa.dev/) - Supply chain security levels
- [OpenSSF Scorecard](https://securityscorecards.dev/) - Security health metrics
- [OpenSSF Best Practices Badge](https://www.bestpractices.dev/) - Project maturity (Passing/Silver/Gold)
- [S2C2F Framework](https://github.com/ossf/s2c2f) - Secure consumption
- [Sigstore/Cosign](https://docs.sigstore.dev/) - Keyless signing
- [step-security/harden-runner](https://github.com/step-security/harden-runner) - Workflow hardening
- [slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator) - SLSA builders
- [Contributor Covenant](https://www.contributor-covenant.org/) - Code of conduct
- [Developer Certificate of Origin](https://developercertificate.org/) - DCO
