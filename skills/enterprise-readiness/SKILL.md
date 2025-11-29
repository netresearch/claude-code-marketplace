---
name: enterprise-readiness
description: "Assess and enhance software projects for enterprise-grade security, quality, and automation. This skill should be used when evaluating projects for production readiness, implementing supply chain security (SLSA, signing, SBOMs), hardening CI/CD pipelines, or establishing quality gates. Triggers on keywords: enterprise, production ready, security hardening, supply chain security, SLSA, OpenSSF Scorecard, release automation."
---

# Enterprise Readiness Assessment

This skill provides a comprehensive framework for assessing and improving software projects
to meet enterprise-grade standards for security, quality, and automation.

## Purpose

Systematically evaluate and enhance projects across three dimensions:
1. **Supply Chain Security** - Provenance, signing, SBOMs, vulnerability scanning
2. **Quality Gates** - Testing, coverage, static analysis, linting
3. **Automation** - CI/CD hardening, release workflows, dependency management

## Assessment Workflow

### Phase 1: Discovery

1. Identify the hosting platform (GitHub, GitLab, Bitbucket, Azure DevOps)
2. Identify primary language(s) (Go, Python, TypeScript, Rust, Java)
3. Scan existing CI/CD configuration files
4. Check for security tooling presence (SBOM, signing, scanning)

### Phase 2: Scoring

Apply checklists using **Dynamic Denominator** scoring:
- Calculate `Score = (Points_Earned / Max_Points_Applicable) * 100`
- Skip platform/language sections that don't apply
- This ensures fair scoring across different tech stacks

Load appropriate reference files based on discovered stack:
- `references/general.md` - Always apply (universal checks)
- `references/github.md` - For GitHub-hosted projects
- `references/go.md` - For Go projects

### Phase 3: Gap Analysis

1. List missing security controls with severity
2. Categorize as:
   - **Critical Blockers** - Must fix immediately (hardcoded secrets, no auth)
   - **Quick Wins** - Low effort, high impact (CODEOWNERS, basic linting)
   - **Roadmap Items** - Long-term improvements (SLSA Level 3)
3. Prioritize by impact and implementation effort

### Phase 4: Implementation

For each identified gap:
1. Provide specific code/configuration
2. Reference implementation patterns from the project
3. Verify implementation works
4. Re-score after changes

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

## Critical Blockers
[Items requiring immediate attention]

## Quick Wins
[Low-effort, high-impact improvements]

## Detailed Findings

### Supply Chain Security (X/Y points)
[Detailed breakdown]

### Quality Gates (X/Y points)
[Detailed breakdown]

### Platform-Specific (X/Y points)
[Detailed breakdown]

### Language-Specific (X/Y points)
[Detailed breakdown]

## Improvement Roadmap
[Prioritized action items with implementation guidance]
```

## Key Implementation Patterns

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
      - uses: step-security/harden-runner@SHA
        with:
          egress-policy: audit
      - uses: actions/checkout@SHA  # Pin to SHA, not tag
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

## Common Pitfalls (Lessons Learned)

1. **SLSA Template Syntax**: Use `{{ .Env.VERSION }}` with `evaluated-envs`, not `{{ .Tag }}`
2. **GitHub CLI Context**: Jobs using `gh` commands need `actions/checkout` first
3. **YAML Heredocs**: Careful indentation required for multi-line scripts
4. **Merge Queue Events**: Must handle `merge_group` event type explicitly
5. **Action Pinning**: SHA pins prevent supply chain attacks but need regular updates

## Extensibility

This skill uses a modular architecture. Additional platform and language modules
can be added to `references/` following the same checklist structure:

**Future Platform Modules:**
- `references/gitlab.md`
- `references/bitbucket.md`
- `references/azure-devops.md`

**Future Language Modules:**
- `references/python.md`
- `references/typescript.md`
- `references/rust.md`
- `references/java.md`

## Resources

- [SLSA Framework](https://slsa.dev/) - Supply chain security levels
- [OpenSSF Scorecard](https://securityscorecards.dev/) - Security health metrics
- [Sigstore/Cosign](https://docs.sigstore.dev/) - Keyless signing
- [step-security/harden-runner](https://github.com/step-security/harden-runner) - Workflow hardening
