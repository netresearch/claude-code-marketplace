# GitHub-Specific Enterprise Readiness Checks

Checks specific to GitHub-hosted repositories and GitHub Actions.

## Workflow Hardening (15 points)

### Harden Runner (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| step-security/harden-runner on all jobs | 3 | Check all workflow job steps |
| Egress policy configured | 1 | Check for `egress-policy: audit` or `block` |

**Implementation**:
```yaml
- name: Harden Runner
  uses: step-security/harden-runner@0634a2670c59f64b4a01f0f96f84700a4088b9f0 # v2.12.0
  with:
    egress-policy: audit
```

### Pinned Action Versions (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| All actions pinned to SHA (not tags) | 3 | `grep -E "uses:.*@[a-f0-9]{40}" .github/workflows/*.yml` |
| Version comments for readability | 1 | Check for `# vX.Y.Z` comments |

**Example**:
```yaml
# Good
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

# Bad
uses: actions/checkout@v4
```

### Minimal Permissions (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| `permissions: read-all` at workflow level | 2 | Check workflow top-level permissions |
| Per-job permission escalation only | 2 | Check job-level permissions are minimal |

**Implementation**:
```yaml
permissions: read-all

jobs:
  build:
    permissions:
      contents: write  # Only what's needed
```

### Network Restrictions (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Egress policy set to audit or block | 2 | Check harden-runner config |
| Allowed endpoints documented | 1 | Check for endpoint allowlist |

---

## Security Features (15 points)

### Dependabot (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Dependabot enabled | 2 | Check `.github/dependabot.yml` |
| Grouped updates configured | 1 | Check for `groups:` in config |

**Implementation**:
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      all-dependencies:
        patterns: ["*"]
```

### CodeQL Analysis (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| CodeQL workflow exists | 2 | Check `.github/workflows/codeql*.yml` |
| Scheduled scans (weekly minimum) | 2 | Check schedule trigger |

**Implementation**:
```yaml
on:
  schedule:
    - cron: '0 6 * * 1'  # Weekly on Monday
```

### Branch Protection (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Required reviews enabled | 2 | Check branch protection settings |
| Required status checks | 2 | Check for required CI checks |

**Note**: For solo developers, branch protection may be relaxed but should still exist.

### Secret Scanning (2 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| GitHub secret scanning enabled | 1 | Check repository security settings |
| Push protection enabled | 1 | Check secret scanning settings |

### Merge Queue (2 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Merge queue enabled | 1 | Check branch protection settings |
| Workflows handle `merge_group` event | 1 | Check workflow triggers |

**Implementation**:
```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  merge_group:  # Required for merge queue
```

---

## CI/CD Patterns (bonus, not scored)

### Reusable Workflows
- [ ] Common workflows extracted to reusable templates
- [ ] Version-controlled workflow references

### Matrix Builds
- [ ] Multi-platform testing via matrix strategy
- [ ] Fail-fast disabled for comprehensive results

### Artifact Management
- [ ] Build artifacts uploaded for job coordination
- [ ] Proper artifact retention policies

### Release Automation
- [ ] Automated changelog generation (git-cliff, conventional-changelog)
- [ ] Release asset upload automation
- [ ] Container image publishing with signing

---

## SLSA Implementation (GitHub-specific)

### Using slsa-github-generator

For Go projects:
```yaml
uses: slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml@v2.1.0
with:
  go-version-file: go.mod
  config-file: .slsa-goreleaser/${{ matrix.target }}.yml
  evaluated-envs: "VERSION:${{ github.ref_name }}, COMMIT:${{ github.sha }}"
  upload-assets: true
```

### SLSA Config File Template
```yaml
# .slsa-goreleaser/linux-amd64.yml
version: 1
env:
  - CGO_ENABLED=0
  - GO111MODULE=on
flags:
  - -trimpath
goos: linux
goarch: amd64
main: .
binary: myapp-{{ .Os }}-{{ .Arch }}
ldflags:
  - "-s -w -X main.version={{ .Env.VERSION }} -X main.build={{ .Env.COMMIT }}"
```

**Critical**: Use `{{ .Env.VERSION }}` not `{{ .Tag }}` - SLSA builder uses different template syntax.

---

## Common GitHub Workflow Issues

### Issue: gh CLI fails with "not a git repository"
**Cause**: Jobs using `gh release download` or `gh release edit` need repository context.
**Fix**: Add `actions/checkout` step before using gh CLI.

### Issue: YAML heredoc parsing errors
**Cause**: Incorrect indentation in multi-line scripts.
**Fix**: Use consistent indentation, prefer `|` or `>` block scalars.

### Issue: Merge queue builds fail
**Cause**: Workflow doesn't handle `merge_group` event.
**Fix**: Add `merge_group:` to workflow triggers.

---

## Total: 30 points

**Scoring Thresholds**:
- 27-30: Excellent GitHub hardening
- 21-26: Good, minor improvements needed
- 15-20: Fair, significant gaps
- Below 15: Poor, major improvements required
