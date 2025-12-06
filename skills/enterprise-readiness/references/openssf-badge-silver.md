# OpenSSF Best Practices Badge - Silver Level

Complete checklist for Silver level certification aligned with
[OpenSSF Best Practices Badge](https://www.bestpractices.dev/) criteria.

## Prerequisites

| Criterion | Requirement | Status |
|-----------|-------------|--------|
| achieve_passing | Passing level (100%) achieved | Required |

---

## Basics (17 criteria)

### Governance & Community (6 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| dco | "Does the project require a Developer Certificate of Origin (DCO)?" | Check CONTRIBUTING.md for DCO requirement | Add DCO sign-off requirement to CONTRIBUTING.md |
| governance | "Is there a documented governance model?" | Check GOVERNANCE.md exists | Create GOVERNANCE.md with decision-making process |
| code_of_conduct | "Does the project have a code of conduct?" | Check CODE_OF_CONDUCT.md exists | Adopt Contributor Covenant v2.1 |
| roles_responsibilities | "Are roles and responsibilities documented?" | Check GOVERNANCE.md for role definitions | Document maintainer, contributor, security team roles |
| access_continuity | "Is there access continuity (bus factor > 1)?" | Check for multiple maintainers with write access | Add backup maintainers with repository access |
| bus_factor | "Is the bus factor >= 2?" | Check contributor statistics | Ensure 2+ people understand critical code |

**DCO Implementation:**
```markdown
<!-- In CONTRIBUTING.md -->
## Developer Certificate of Origin

All contributions must be signed off using the DCO:

git commit -s -m "Your commit message"

This certifies you wrote the code or have the right to submit it under the project license.
```

**Enforcement (GitHub Action):**
```yaml
# .github/workflows/dco.yml
name: DCO Check
on: [pull_request]
jobs:
  dco:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: dcoapp/app@v1
```

### Documentation (8 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| documentation_roadmap | "Is there a project roadmap?" | Check ROADMAP.md or GitHub Projects | Create ROADMAP.md or use GitHub milestones |
| documentation_architecture | "Is the software architecture documented?" | Check ARCHITECTURE.md | Create system architecture documentation |
| documentation_security | "Are security considerations documented?" | Check SECURITY.md for design principles | Add security design section to SECURITY.md |
| documentation_quick_start | "Is there a quick start guide?" | Check README.md for getting started | Add quick start section to README |
| documentation_current | "Is documentation reasonably current?" | Compare docs date vs code changes | Update docs with each release |
| documentation_achievements | "Are achievements/capabilities documented?" | Check feature documentation | Document what the software can do |
| accessibility_best_practices | "Does the project follow accessibility best practices?" | N/A for non-UI libraries | Document accessibility approach for UI projects |
| internationalization | "Does the project support internationalization?" | N/A for non-localized tools | Implement i18n if user-facing |

**Architecture Documentation Template:**
```markdown
# Architecture

## Overview
[High-level system description]

## Components
- Component A: [Purpose]
- Component B: [Purpose]

## Data Flow
[Diagram or description]

## Security Considerations
[Key security design decisions]
```

### Sites & Security (3 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| sites_https | "Does the project website use HTTPS?" | Check project URLs | Ensure all links use HTTPS |
| sites_password_security | "Are passwords stored securely if applicable?" | N/A if no password storage | Use bcrypt/argon2 with proper parameters |
| contribution_requirements | "Are contribution requirements clear?" | Check CONTRIBUTING.md | Document PR process, coding standards |

---

## Change Control (1 criterion)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| maintenance_or_update | "Is the project actively maintained?" | Check commit frequency, issue responses | Respond to issues within 14 days |

---

## Reporting (3 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| report_tracker | "Is there a public issue tracker?" | Check GitHub Issues enabled | Enable and monitor issue tracker |
| vulnerability_report_credit | "Are vulnerability reporters credited?" | Check SECURITY.md or release notes | Add credits section to security advisories |
| vulnerability_response_process | "Is there a documented response process?" | Check SECURITY.md for response timeline | Document triage, fix, disclosure process |

---

## Quality (19 criteria)

### Coding Standards (4 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| coding_standards | "Does the project have coding standards?" | Check for linter configs | Document in CONTRIBUTING.md |
| coding_standards_enforced | "Are coding standards automatically enforced?" | Check CI for linting steps | Add linting to CI (fail on violations) |
| warnings | "Are compiler warnings addressed?" | Check build logs, linter output | Fix all warnings, use strict mode |
| warnings_strict | "Does the project use strict warning settings?" | Check compiler/linter config | Enable all recommended warnings |

**Enforcement Example (Go):**
```yaml
- name: Lint
  run: golangci-lint run --timeout 5m
  # Fails on any warning
```

### Build (5 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| build_standard_variables | "Does the build use standard variables?" | Check Makefile/build scripts | Use standard env vars (CC, CFLAGS, etc.) |
| build_preserve_debug | "Can debug info be preserved?" | Check build flags | Support debug builds |
| build_non_recursive | "Does the build avoid recursive make?" | Check Makefile structure | Use non-recursive make patterns |
| build_repeatable | "Is the build repeatable/deterministic?" | Build twice, compare hashes | Use -trimpath, pin dependencies |
| installation_common | "Does installation follow common conventions?" | Check install process | Support standard install locations |

**Repeatable Build (Go):**
```bash
CGO_ENABLED=0 go build \
  -trimpath \
  -ldflags '-s -w -buildid=' \
  -o binary .
```

### Installation (3 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| installation_standard_variables | "Does installation use standard variables?" | Check install scripts | Use PREFIX, DESTDIR conventions |
| installation_development_quick | "Can developers quickly install?" | Check dev setup time | Document quick dev setup (<30 min) |
| external_dependencies | "Are external dependencies documented?" | Check README prerequisites | List all runtime dependencies |

### Dependencies (3 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| dependency_monitoring | "Are dependencies monitored for vulnerabilities?" | Check Dependabot/Renovate | Enable automated dependency scanning |
| updateable_reused_components | "Can dependencies be updated?" | Check lockfile management | Support dependency updates |
| interfaces_current | "Are external interfaces current?" | Check API documentation | Document all public APIs |

### Testing (4 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| automated_integration_testing | "Is there automated integration testing?" | Check CI for integration tests | Add integration test suite |
| regression_tests_added50 | "Are regression tests added for 50%+ bugs?" | Check test additions in bug fix PRs | Require tests for bug fixes |
| test_statement_coverage80 | "Is statement coverage >= 80%?" | Check coverage reports | Enforce 80% coverage threshold |
| test_policy_mandated | "Are tests required for new functionality?" | Check PR requirements | Document test policy in CONTRIBUTING.md |

**Coverage Threshold (Go):**
```yaml
- name: Check coverage
  run: |
    go test -coverprofile=coverage.out ./...
    COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')
    if (( $(echo "$COVERAGE < 80" | bc -l) )); then
      echo "Coverage $COVERAGE% is below 80%"
      exit 1
    fi
```

---

## Security (13 criteria)

### Secure Design (3 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| implement_secure_design | "Does implementation follow secure design?" | Code review for security patterns | Follow OWASP guidelines |
| input_validation | "Is input validated before processing?" | Check input handling code | Validate all external input |
| hardening | "Are hardening techniques applied?" | Check for security headers, minimal privileges | Document hardening measures |

### Cryptography (6 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| crypto_algorithm_agility | "Can crypto algorithms be replaced?" | Check crypto abstraction | Use algorithm-agnostic interfaces |
| crypto_credential_agility | "Can credentials be replaced?" | Check credential management | Support credential rotation |
| crypto_used_network | "Is crypto used for network comms?" | Check network code | Use TLS for all network connections |
| crypto_tls12 | "Is TLS 1.2+ required?" | Check TLS configuration | Set minimum TLS version to 1.2 |
| crypto_certificate_verification | "Are certificates verified?" | Check TLS client config | Enable certificate verification |
| crypto_verification_private | "Are private comms verified?" | Check for MITM protection | Use authenticated encryption |

**TLS 1.2+ Enforcement (Go):**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
    // Go 1.14+ automatically selects optimal cipher suites
    // No need for PreferServerCipherSuites (deprecated/ignored)
}
```

### Release Security (2 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| signed_releases | "Are releases cryptographically signed?" | Check for .sig files in releases | Sign with Cosign/GPG |
| version_tags_signed | "Are version tags signed?" | Check `git tag -v` output | Use `git tag -s` for releases |

**Signed Tags:**
```bash
# Create signed tag
git tag -s v1.0.0 -m "Release v1.0.0"

# Verify signed tag
git tag -v v1.0.0
```

### Analysis (2 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| assurance_case | "Is there a security assurance case?" | Check security documentation | Document security claims and evidence |
| static_analysis_common_vulnerabilities | "Does static analysis check for common vulns?" | Check SAST tools in CI | Use CodeQL, gosec, Semgrep |

---

## Analysis (2 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| dynamic_analysis | "Is dynamic analysis performed?" | Check for fuzzing, DAST | Run fuzz tests, integration security tests |
| dynamic_analysis_unsafe | "Does dynamic analysis check unsafe behavior?" | Check for memory safety tests | Use race detector, sanitizers |

---

## Total: 55 criteria

**Progress Tracking:**
- [ ] 0-20% - Just starting
- [ ] 21-50% - Making progress
- [ ] 51-80% - Near completion
- [ ] 81-99% - Final push
- [ ] 100% - Silver achieved!

---

## Quick Reference: Files Needed

| File | Purpose | Silver Criteria |
|------|---------|-----------------|
| GOVERNANCE.md | Decision-making, roles | governance, roles_responsibilities |
| CODE_OF_CONDUCT.md | Community standards | code_of_conduct |
| ARCHITECTURE.md | System design | documentation_architecture |
| SECURITY.md | Security policy, design | documentation_security, assurance_case |
| CONTRIBUTING.md | Contribution process | dco, coding_standards, test_policy |
| ROADMAP.md | Future plans | documentation_roadmap |

---

## Implementation Priority

### High Priority (Blocking)
1. DCO enforcement
2. 80% test coverage
3. Signed releases AND tags
4. Integration testing

### Medium Priority
1. Architecture documentation
2. Build reproducibility
3. TLS 1.2+ enforcement
4. Input validation documentation

### Lower Priority (N/A for many projects)
1. Accessibility (non-UI)
2. Internationalization
3. Password storage (if not applicable)
