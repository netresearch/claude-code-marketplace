# GitHub-Specific Enterprise Readiness Checks

Checks specific to GitHub-hosted repositories and GitHub Actions.
Aligned with OpenSSF Scorecard high-risk checks.

## Dangerous Workflow Patterns (8 points) - CRITICAL

*This section addresses the OpenSSF Scorecard "Dangerous-Workflow" check (Critical risk)*

### Script Injection Prevention (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| No direct interpolation of untrusted input in `run` blocks | 2 | Grep for `\$\{\{.*github\.event` in workflow files |
| Environment variables used for user input | 1 | Check for `env:` block before `run:` |
| No `pull_request_target` with checkout of PR code | 1 | Check workflow triggers and checkout patterns |

**Critical Pattern - NEVER DO THIS:**
```yaml
# DANGEROUS - Script injection vulnerability
- run: echo "Title: ${{ github.event.issue.title }}"
```

**Safe Pattern - ALWAYS DO THIS:**
```yaml
# SAFE - Use environment variables
- name: Process issue
  env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "Title: $TITLE"
```

### Dangerous Triggers (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| No `pull_request_target` without careful review | 2 | `grep -r "pull_request_target" .github/workflows/` |
| No `workflow_run` with untrusted artifact access | 1 | Check for artifact downloads from forked PRs |
| Checkout uses explicit ref for PR workflows | 1 | Verify `ref: ${{ github.event.pull_request.head.sha }}` pattern |

**Why**: `pull_request_target` runs in the context of the base branch with write permissions,
making it dangerous when combined with checkout of PR code from forks.

---

## Code Review Requirements (6 points)

*This section addresses the OpenSSF Scorecard "Code-Review" check (High risk)*

### Branch Protection (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Default branch protected | 1 | Check repository settings or `gh api repos/{owner}/{repo}/branches/{branch}/protection` |
| Require pull request before merging | 1 | Check branch protection rules |
| Dismiss stale reviews on new commits | 1 | Check branch protection settings |

### Review Enforcement (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Require at least 1 approving review | 2 | Check required reviewers setting |
| Code owners review required | 1 | Check `require_code_owner_reviews` setting |

**Implementation**:
```bash
# Check branch protection via GitHub CLI
gh api repos/{owner}/{repo}/branches/main/protection \
  --jq '{
    enforce_admins: .enforce_admins.enabled,
    required_reviews: .required_pull_request_reviews.required_approving_review_count,
    dismiss_stale: .required_pull_request_reviews.dismiss_stale_reviews
  }'
```

---

## Workflow Hardening (10 points)

### Harden Runner (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| step-security/harden-runner on security-sensitive jobs | 2 | Check workflow job steps |
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
# Good - Pinned to SHA with version comment
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

# Bad - Tag can be moved by attacker
uses: actions/checkout@v4
```

### Minimal Permissions (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| `permissions: read-all` or explicit permissions at workflow level | 2 | Check workflow top-level permissions |
| Per-job permission escalation only | 1 | Check job-level permissions are minimal |

**Implementation**:
```yaml
permissions: read-all  # Or explicit minimal permissions

jobs:
  build:
    permissions:
      contents: write  # Only what's needed for this job
```

---

## Security Features (10 points)

### Dependabot (2 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Dependabot enabled | 1 | Check `.github/dependabot.yml` |
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

### CodeQL Analysis (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| CodeQL workflow exists | 1 | Check `.github/workflows/codeql*.yml` |
| Scheduled scans (weekly minimum) | 1 | Check schedule trigger |
| All relevant languages configured | 1 | Check language matrix |

**Implementation**:
```yaml
on:
  schedule:
    - cron: '0 6 * * 1'  # Weekly on Monday
```

### Secret Scanning (2 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| GitHub secret scanning enabled | 1 | Check repository security settings |
| Push protection enabled | 1 | Check secret scanning settings |

### Merge Queue (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Merge queue enabled | 1 | Check branch protection settings |
| Workflows handle `merge_group` event | 1 | Check workflow triggers |
| Required status checks configured | 1 | Check branch protection settings |

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

## SLSA Implementation (6 points)

### SLSA Level Achievement (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| SLSA Level 1 (provenance exists) | 1 | Check for `.intoto.jsonl` in releases |
| SLSA Level 2 (hosted build, signed provenance) | 1 | Check for signed attestations |
| SLSA Level 3 (isolated builder, unforgeable) | 2 | Check for slsa-github-generator usage |

### Provenance Verification (2 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Verification instructions documented | 1 | Check README or release notes |
| `slsa-verifier` compatible | 1 | Test with `slsa-verifier verify-artifact` |

**Using slsa-github-generator (Go example)**:
```yaml
uses: slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml@v2.1.0
with:
  go-version-file: go.mod
  config-file: .slsa-goreleaser/${{ matrix.target }}.yml
  evaluated-envs: "VERSION:${{ github.ref_name }}, COMMIT:${{ github.sha }}"
  upload-assets: true
```

**Critical**: Use `{{ .Env.VERSION }}` not `{{ .Tag }}` - SLSA builder uses different template syntax.

---

## Total: 40 points

**Scoring Thresholds**:
- 36-40: Excellent GitHub security posture
- 28-35: Good, minor improvements needed
- 20-27: Fair, significant gaps
- Below 20: Poor, major improvements required

---

## OpenSSF Scorecard Alignment

| Scorecard Check | This Skill Section | Status |
|-----------------|-------------------|--------|
| Branch-Protection | Code Review Requirements | ✅ Covered |
| Code-Review | Code Review Requirements | ✅ Covered |
| Dangerous-Workflow | Dangerous Workflow Patterns | ✅ Covered |
| Dependency-Update-Tool | Security Features (Dependabot) | ✅ Covered |
| Pinned-Dependencies | Workflow Hardening | ✅ Covered |
| SAST | Security Features (CodeQL) | ✅ Covered |
| Token-Permissions | Workflow Hardening | ✅ Covered |
| Webhooks | (Not yet covered) | ⚠️ Future |

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

### Issue: Fork PRs can't access secrets
**Cause**: GitHub doesn't expose secrets to fork PRs for security.
**Fix**: Use `pull_request_target` carefully or use OIDC for external services.

### Issue: Actions pinned to SHA break updates
**Fix**: Use Dependabot with `package-ecosystem: "github-actions"` to update SHA pins.

---

## CI Optimization Patterns

### Disk Space Management

GitHub Actions runners have limited disk space (~14GB free on ubuntu-latest). Heavy test operations can exhaust this, causing failures like:

```
Error: Failed to install package: requires 498.2 MB free space, but only 421.8 MB available
```

**Solution 1: Free Disk Space (Quick Fix)**

Add this step early in your workflow to reclaim ~25GB:

```yaml
- name: Free disk space
  run: |
    sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc
    df -h
```

**What gets removed:**
| Directory | Size | Contents |
|-----------|------|----------|
| `/usr/share/dotnet` | ~6GB | .NET SDK (not needed for most projects) |
| `/usr/local/lib/android` | ~10GB | Android SDK |
| `/opt/ghc` | ~8GB | Haskell compiler |

**Solution 2: Test Variable Overrides (Best Practice)**

For tests that install heavy dependencies (Docker images, Flatpak apps, large packages), override variables in test configuration:

```yaml
# molecule/default/converge.yml for Ansible
vars:
  # Override for CI - minimal set reduces disk usage
  heavy_packages: []  # Empty in CI, full list in defaults/main.yml

# Or for selective testing:
vars:
  test_mode: true
  packages_to_install:
    - small-package-1  # Test the mechanism with minimal resources
```

**Why this works:**
- Production deployments use full defaults from `defaults/main.yml`
- CI tests validate the mechanism works with minimal resources
- Avoids downloading gigabytes of packages in every CI run

### Test Execution Optimization

**Run expensive tests conditionally:**

```yaml
- name: Run lightweight tests
  run: npm test

- name: Run heavy E2E tests
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  run: npm run test:e2e
```

**Use job matrix efficiently:**

```yaml
strategy:
  matrix:
    include:
      # Full test on main only
      - os: ubuntu-latest
        full_test: true
      # Quick smoke test on PRs
      - os: ubuntu-latest
        full_test: false
  fail-fast: false
```

### Docker Layer Caching

For Docker-heavy CI (Molecule, container builds):

```yaml
- uses: docker/setup-buildx-action@v3
- uses: docker/build-push-action@v6
  with:
    context: .
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Common CI Failure Patterns

| Pattern | Symptom | Fix |
|---------|---------|-----|
| Disk space exhaustion | "No space left on device" | Free disk space step |
| Memory exhaustion | OOM killed | Reduce parallelism, add swap |
| Timeout | Job exceeds 6h limit | Split into multiple jobs |
| Rate limiting | API calls fail | Add retry logic, caching |
| Transient API errors | 502/503/504 Bad Gateway | Retry with exponential backoff |

---

## API Resilience Patterns

GitHub API can return transient errors (502, 503, 504) during high load. Scripts making API calls should include retry logic.

### Retry Logic for Python Scripts

```python
import time
import requests

def github_request(url: str, token: str, max_retries: int = 3) -> dict | list:
    """Make authenticated GitHub API request with retry logic."""
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    for attempt in range(max_retries):
        try:
            response = requests.get(url, headers=headers, timeout=30)

            # Retry on transient errors
            if response.status_code in (429, 502, 503, 504):
                retry_after = int(response.headers.get("Retry-After", 2 ** attempt))
                print(f"Retry {attempt + 1}/{max_retries}: {response.status_code}, waiting {retry_after}s")
                time.sleep(retry_after)
                continue

            response.raise_for_status()
            return response.json()

        except requests.exceptions.RequestException as e:
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt
                print(f"Retry {attempt + 1}/{max_retries}: {e}, waiting {wait_time}s")
                time.sleep(wait_time)
            else:
                raise

    raise RuntimeError(f"Max retries exceeded for {url}")
```

### Retry Logic for Shell Scripts

```bash
#!/bin/bash
# GitHub API with retry logic

github_api_request() {
    local url="$1"
    local max_retries=3
    local attempt=0

    while [ $attempt -lt $max_retries ]; do
        response=$(curl -s -w "\n%{http_code}" \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github+json" \
            "$url")

        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')

        case $http_code in
            200|201|204)
                echo "$body"
                return 0
                ;;
            429|502|503|504)
                attempt=$((attempt + 1))
                wait_time=$((2 ** attempt))
                echo "Retry $attempt/$max_retries: HTTP $http_code, waiting ${wait_time}s" >&2
                sleep $wait_time
                ;;
            *)
                echo "Error: HTTP $http_code" >&2
                echo "$body" >&2
                return 1
                ;;
        esac
    done

    echo "Max retries exceeded for $url" >&2
    return 1
}
```

### Retry Logic for GitHub Actions

```yaml
- name: Call GitHub API with retry
  run: |
    for i in 1 2 3; do
      response=$(gh api repos/${{ github.repository }}/releases/latest 2>&1) && break
      echo "Attempt $i failed, retrying in $((i * 2)) seconds..."
      sleep $((i * 2))
    done
    echo "$response"
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### When to Add Retry Logic

| Scenario | Retry Needed? | Reason |
|----------|---------------|--------|
| CI workflow API calls | Yes | Transient failures break builds |
| Release automation | Yes | Critical operations should be resilient |
| One-time scripts | Optional | Manual retry is acceptable |
| User-facing CLI tools | Yes | Better UX than cryptic errors |
