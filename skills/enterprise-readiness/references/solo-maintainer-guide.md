# Solo Maintainer Guide for OpenSSF Badge Certification

> Practical guidance for solo maintainers pursuing Silver and Gold level badges.

## Overview

Many OpenSSF Best Practices Badge criteria assume multi-person teams. This guide helps solo
maintainers understand which criteria apply, which can be marked N/A with justification, and
how to implement compensating controls.

## Criteria Assessment Matrix

### Passing Level (68 criteria)

**Good news:** All Passing level criteria can be met by solo maintainers. Focus on:
- Documentation (SECURITY.md, README, LICENSE)
- CI/CD pipeline setup
- Basic security practices

### Silver Level (55 criteria)

| Criterion | Solo Feasibility | Recommendation |
|-----------|------------------|----------------|
| `dco` | ✅ Easy | Sign your own commits |
| `governance` | ✅ Easy | Document decision-making process |
| `bus_factor` | ⚠️ N/A | Justify with succession plan |
| `access_continuity` | ⚠️ N/A | Document backup access |
| `signed_releases` | ✅ Easy | Use Cosign keyless signing |
| `version_tags_signed` | ✅ Easy | Use GPG or SSH signing |
| `test_statement_coverage80` | ✅ Achievable | Invest in comprehensive tests |
| `automated_integration_testing` | ✅ Achievable | Add integration tests |

### Gold Level (24 criteria)

| Criterion | Solo Feasibility | Recommendation |
|-----------|------------------|----------------|
| `two_person_review` | ❌ N/A | Document compensating controls |
| `contributors_unassociated` | ⚠️ N/A | Open contribution policy |
| `bus_factor` | ⚠️ N/A | Enhanced succession planning |
| `require_2FA` | ⚠️ Depends | Enable on personal account |
| `test_statement_coverage90` | ⚠️ Hard | Significant test investment |
| `test_branch_coverage80` | ⚠️ Hard | Advanced coverage analysis |
| `build_reproducible` | ✅ Achievable | Use proper build flags |
| `security_review` | ✅ Achievable | Self-audit with methodology |

---

## Compensating Controls

### For `two_person_review`

Since self-approval isn't possible, implement these controls:

```yaml
# .github/workflows/pr-quality.yml
name: PR Quality Gates
on: pull_request

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      # Comprehensive testing replaces human review
      - uses: actions/checkout@v4
      - name: Run full test suite
        run: go test -race -coverprofile=coverage.out ./...

      # Static analysis catches issues
      - name: Security scan
        uses: securego/gosec@master

      - name: CodeQL analysis
        uses: github/codeql-action/analyze@v3

      # PR aging requirement
      - name: Check PR age
        run: |
          CREATED=$(gh pr view ${{ github.event.number }} --json createdAt -q .createdAt)
          AGE_HOURS=$(( ($(date +%s) - $(date -d "$CREATED" +%s)) / 3600 ))
          if [ $AGE_HOURS -lt 24 ]; then
            echo "PR must be at least 24 hours old before merging"
            exit 1
          fi
```

### For `bus_factor`

Document your succession plan:

```markdown
# Succession Plan

## Immediate Access
- GitHub repository: Transfer ownership or add backup admin
- Package registries: Document credentials location (secure)
- Domain/hosting: Document access procedures

## Knowledge Transfer
- All decisions documented in ADRs
- Architecture fully documented
- No tribal knowledge required
- Standard tooling used throughout

## Backup Maintainers
Primary: [Name] <email> (confirmed)
Secondary: Community via GitHub Issues

## Trigger Conditions
- 90 days of inactivity → Warning to community
- 180 days of inactivity → Backup maintainer takes over
```

### For `contributors_unassociated`

Actively encourage external contributions:

```markdown
# In CONTRIBUTING.md

## We Welcome All Contributors!

This project has no organizational restrictions on contributions. We especially
welcome contributions from developers at different organizations to ensure
diverse perspectives in the project's development.

### Good First Issues

We maintain a list of "good first issue" tasks to help new contributors get started.
See: [Good First Issues](https://github.com/org/repo/labels/good%20first%20issue)

### Contribution Recognition

All contributors are recognized in our CONTRIBUTORS.md file and release notes.
```

---

## Self-Audit Process for `security_review`

Solo maintainers can conduct credible security reviews:

### Step 1: Preparation

```bash
# Run all security tools
gosec ./...
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...
trivy fs --security-checks vuln,config .
gitleaks detect --source=.
```

### Step 2: Manual Review Checklist

- [ ] Authentication/authorization flows
- [ ] Input validation at boundaries
- [ ] Error handling (no info leakage)
- [ ] Cryptographic usage (if any)
- [ ] Secrets management
- [ ] Logging (no sensitive data)
- [ ] Dependencies (known vulnerabilities)

### Step 3: Document Findings

Use the `SECURITY_AUDIT.md` template to document your review, including:
- Methodology used
- Tools run
- Findings (even if none)
- Remediation actions
- Date and "auditor" (yourself)

### Step 4: Schedule Regular Reviews

```yaml
# .github/workflows/security-review-reminder.yml
name: Security Review Reminder
on:
  schedule:
    - cron: '0 0 1 */6 *'  # Every 6 months

jobs:
  remind:
    runs-on: ubuntu-latest
    steps:
      - name: Create issue
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'Scheduled Security Review Due',
              body: 'Time for the bi-annual security review. See SECURITY_AUDIT.md template.',
              labels: ['security', 'maintenance']
            })
```

---

## Achievable Goals

### 90% Statement Coverage

While challenging, 90% coverage is achievable for solo maintainers:

1. **Start with critical paths** - Ensure main functionality is fully tested
2. **Test error conditions** - Often missed but easy to add
3. **Use table-driven tests** - Efficient way to cover many cases
4. **Mock external dependencies** - Isolate your code for testing
5. **Review uncovered lines** - Use `go tool cover -html` regularly

### 80% Branch Coverage

Requires more sophisticated testing:

```go
// Table-driven tests covering all branches
func TestProcess(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {"valid input", "good", false},
        {"empty input", "", true},       // Error branch
        {"invalid chars", "bad!", true}, // Validation branch
        {"too long", strings.Repeat("x", 1000), true}, // Length check
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := Process(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("Process() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

---

## N/A Justification Template

When marking criteria as N/A, use this format:

```markdown
## Criterion: [criterion_name]

**Status:** N/A

**Reason:** [One sentence explanation]

**Compensating Controls:**
1. [Control 1]
2. [Control 2]
3. [Control 3]

**Evidence:** [Link to documentation/code demonstrating controls]
```

---

## Timeline Expectations

### Passing Level
- Solo maintainer: 1-2 weeks of focused effort
- Mostly documentation and basic CI/CD setup

### Silver Level
- Solo maintainer: 1-2 months
- Significant testing investment required
- Documentation formalization needed

### Gold Level
- Solo maintainer: 3-6 months (or longer)
- May require community building
- Some criteria may remain N/A with justification
- Consider if Gold is necessary for your project

---

## Resources

- [OpenSSF Best Practices Badge](https://www.bestpractices.dev/)
- [Badge Criteria Details](https://www.bestpractices.dev/en/criteria)
- [OpenSSF Scorecard](https://securityscorecards.dev/)
- [Solo Maintainer Support](https://github.com/solo-maintainers)
