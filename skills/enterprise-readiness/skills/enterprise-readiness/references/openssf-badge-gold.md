# OpenSSF Best Practices Badge - Gold Level

Complete checklist for Gold level certification aligned with
[OpenSSF Best Practices Badge](https://www.bestpractices.dev/) criteria.

## Prerequisites

| Criterion | Requirement | Status |
|-----------|-------------|--------|
| achieve_passing | Passing level (100%) achieved | Required |
| achieve_silver | Silver level (100%) achieved | Required |

**Note:** Gold level represents the highest tier of project maturity and security.
Most criteria require organizational commitment beyond individual maintainer capabilities.

---

## Basics (6 criteria)

### Project Identity (2 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| identification | "Is the project uniquely identifiable?" | Check for unique project identity | Ensure distinct name, namespace |
| contributors_unassociated | "Are there unassociated contributors?" | Check contributor affiliations | Have contributors from 2+ organizations |

**Why Unassociated Contributors Matter:**
- Reduces organizational bias in decision-making
- Demonstrates project is not controlled by single entity
- Required for Gold: 2+ significant contributors from different organizations

### Licensing (3 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| copyright_per_file | "Does each file have copyright notice?" | Grep for copyright headers | Add headers to all source files |
| license_per_file | "Does each file have license notice?" | Grep for license headers | Add SPDX identifiers to all files |
| bus_factor | "Is bus factor >= 2?" | Analyze commit distribution | Ensure 2+ people can maintain project |

**SPDX License Header:**
```go
// SPDX-License-Identifier: MIT
// Copyright (c) 2024 Project Authors

package main
```

**Adding Headers (Go):**
```bash
# Use addlicense tool
go install github.com/google/addlicense@latest
addlicense -c "Project Authors" -l mit .
```

---

## Change Control (4 criteria)

### Version Control (4 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| repo_distributed | "Is the repository distributed?" | Check VCS type | Use Git (distributed by design) |
| require_2FA | "Is 2FA required for collaborators?" | Check GitHub org settings | Enable 2FA requirement for org |
| secure_2FA | "Is 2FA using secure methods?" | Check for hardware keys | Prefer FIDO2/WebAuthn over TOTP |

**GitHub 2FA Enforcement:**
```
Settings → Organization → Security → Require 2FA for everyone
```

---

## Quality (7 criteria)

### Code Review (2 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| code_review_standards | "Are there code review standards?" | Check CONTRIBUTING.md | Document review expectations |
| two_person_review | "Do changes require 2-person review?" | Check branch protection | Require 2 reviewers for main branch |

**Two-Person Review:**
```bash
# Set via GitHub API
gh api repos/{owner}/{repo}/branches/main/protection \
  -X PUT \
  -f required_approving_review_count=2
```

**Note:** This is challenging for solo maintainers. Options:
- Partner with another project for cross-review
- Use bot reviewers (limited effectiveness)
- Mark as N/A with justification

### Build (1 criterion)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| build_reproducible | "Is the build reproducible?" | Build twice, compare checksums | Achieve bit-for-bit reproducible builds |

**Reproducible Builds (Go):**
```bash
# Build with all reproducibility flags
CGO_ENABLED=0 go build \
  -trimpath \
  -ldflags '-s -w -buildid= -extldflags=-static' \
  -o binary .

# Verify
sha256sum binary  # Should be identical across builds
```

### Testing (4 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| test_invocation | "Can tests be invoked with standard command?" | Check test documentation | Use `go test`, `npm test`, etc. |
| test_continuous_integration | "Are tests run in CI?" | Check CI configuration | All PRs must pass tests |
| test_statement_coverage90 | "Is statement coverage >= 90%?" | Check coverage reports | Enforce 90% coverage threshold |
| test_branch_coverage80 | "Is branch coverage >= 80%?" | Check coverage reports | Measure and enforce branch coverage |

**90% Statement + 80% Branch Coverage (Go):**
```yaml
- name: Run tests with coverage
  run: |
    go test -coverprofile=coverage.out -covermode=atomic ./...

    # Statement coverage
    STMT=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')
    if (( $(echo "$STMT < 90" | bc -l) )); then
      echo "Statement coverage $STMT% below 90%"
      exit 1
    fi

    # For branch coverage, use more sophisticated tools
    # gocov, gocover-cobertura + branch analysis
```

---

## Security (5 criteria)

### Cryptography (2 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| crypto_used_network | "Is strong crypto used for network?" | Check TLS implementation | Use TLS 1.2+ with strong ciphers |
| crypto_tls12 | "Is TLS 1.2 or higher enforced?" | Check minimum TLS version | Set MinVersion to TLS 1.2 |

### Hardening (3 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| hardened_site | "Is the project website hardened?" | Check security headers | Add CSP, HSTS, X-Frame-Options |
| security_review | "Has there been a security review?" | Check for audit reports | Conduct or commission security audit |
| hardening | "Are hardening techniques documented?" | Check security documentation | Document all hardening measures |

**Security Review Options:**
1. **Internal review** - Documented security code review
2. **External audit** - Third-party security assessment
3. **Bug bounty** - Public security testing program
4. **OSS security programs** - OSTIF, Trail of Bits grants

---

## Analysis (2 criteria)

| Criterion | Form Question | How to Verify | Implementation |
|-----------|---------------|---------------|----------------|
| dynamic_analysis | "Is dynamic analysis performed?" | Check for runtime testing | Fuzz testing, DAST, sanitizers |
| dynamic_analysis_enable_assertions | "Are assertions enabled in testing?" | Check test configuration | Run tests with assertions enabled |

**Dynamic Analysis (Go):**
```yaml
# Fuzz testing
- name: Fuzz tests
  run: go test -fuzz=. -fuzztime=60s ./...

# Race detector
- name: Race detection
  run: go test -race ./...

# Memory sanitizer (if applicable)
- name: Address sanitizer
  run: |
    CC=clang go test -msan ./...
```

---

## Total: 24 criteria (plus prerequisites)

**Gold Level Requirements Summary:**
- Passing level: 100%
- Silver level: 100%
- Gold criteria: 24 additional

---

## Critical Gold Requirements

### Organizational (Hard for Solo Maintainers)

| Requirement | Challenge | Mitigation |
|-------------|-----------|------------|
| 2-person review | Can't self-approve | Partner projects, bot reviewers |
| Bus factor >= 2 | Single maintainer | Recruit co-maintainers |
| Unassociated contributors | Small team | Encourage external contributions |
| 2FA enforcement | Org setting | Document 2FA usage |

### Technical (Achievable)

| Requirement | Effort | Tools |
|-------------|--------|-------|
| 90% coverage | High | gocov, Codecov |
| 80% branch coverage | High | Advanced coverage tools |
| Reproducible builds | Medium | -trimpath, -buildid= |
| Security review | High | OSTIF, self-audit |
| Copyright headers | Low | addlicense |

---

## Gold Level Roadmap

### Phase 1: Technical Foundation
1. [ ] Achieve 90% statement coverage
2. [ ] Achieve 80% branch coverage
3. [ ] Implement reproducible builds
4. [ ] Add copyright/license headers to all files

### Phase 2: Process Requirements
1. [ ] Document code review standards
2. [ ] Enable 2FA for all contributors
3. [ ] Conduct security review (or self-audit)
4. [ ] Create "good first issue" tasks

### Phase 3: Organizational Growth
1. [ ] Recruit second maintainer
2. [ ] Attract external contributors
3. [ ] Establish two-person review (or document exception)
4. [ ] Complete Gold certification

---

## Files Needed for Gold

| File | Purpose | Gold Criteria |
|------|---------|---------------|
| All files | Copyright headers | copyright_per_file |
| All files | SPDX identifiers | license_per_file |
| CONTRIBUTING.md | Review standards | code_review_standards |
| SECURITY.md | Audit documentation | security_review |
| README.md | Standard test commands | test_invocation |

---

## Exceptions and Justifications

Some Gold criteria may not apply to all projects. Document exceptions clearly:

```markdown
## OpenSSF Best Practices Badge - Gold Exceptions

### two_person_review (N/A)
Justification: Solo maintainer project. Compensating controls:
- All changes go through CI with comprehensive testing
- CodeQL and security scanning on all PRs
- Regular self-review of security-critical changes

### contributors_unassociated (N/A)
Justification: Specialized project with limited contributor pool.
Compensating controls:
- Open to contributions from any organization
- No organizational restrictions on contribution
```

---

## Verification Commands

```bash
# Check copyright headers
grep -rL "Copyright" --include="*.go" .

# Check SPDX identifiers
grep -rL "SPDX-License-Identifier" --include="*.go" .

# Check coverage
go test -coverprofile=c.out ./... && go tool cover -func=c.out | grep total

# Verify reproducible build
sha256sum binary1 binary2  # Should match

# List good first issues
gh issue list --label "good first issue"
```
