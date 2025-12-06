# OpenSSF Badge Display Guide

> OpenSSF Silver Badge requirement: `documentation_achievements`
>
> Projects must display their OpenSSF Best Practices Badge prominently in the README.

## Badge URLs

### Get Your Badge

1. Register at https://www.bestpractices.dev/
2. Complete criteria for your target level
3. Copy badge URL from your project page

### Badge Formats

```markdown
# Markdown (Recommended for README.md)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/YOUR_PROJECT_ID/badge)](https://www.bestpractices.dev/projects/YOUR_PROJECT_ID)

# HTML
<a href="https://www.bestpractices.dev/projects/YOUR_PROJECT_ID">
  <img src="https://www.bestpractices.dev/projects/YOUR_PROJECT_ID/badge" alt="OpenSSF Best Practices">
</a>

# reStructuredText (for Python docs)
.. image:: https://www.bestpractices.dev/projects/YOUR_PROJECT_ID/badge
   :target: https://www.bestpractices.dev/projects/YOUR_PROJECT_ID
   :alt: OpenSSF Best Practices
```

### Badge Levels

| Level | Visual | Description |
|-------|--------|-------------|
| Passing | ![passing](https://www.bestpractices.dev/assets/passing-12d6fbe3a203e06c5b1730a5ede78e8e.svg) | Basic security practices |
| Silver | ![silver](https://www.bestpractices.dev/assets/silver-c6d8c2a8e0e57be8b1530aa4d6f54a7e.svg) | Advanced governance & security |
| Gold | ![gold](https://www.bestpractices.dev/assets/gold-0a66c44c15c80c17a0a82cf8ac0f3a9e.svg) | Highest maturity level |

## README Badge Section

### Recommended Placement

```markdown
# Project Name

[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/ID/badge)](https://www.bestpractices.dev/projects/ID)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/ORG/REPO/badge)](https://securityscorecards.dev/viewer/?uri=github.com/ORG/REPO)
[![Go Report Card](https://goreportcard.com/badge/github.com/ORG/REPO)](https://goreportcard.com/report/github.com/ORG/REPO)
[![License](https://img.shields.io/github/license/ORG/REPO)](LICENSE)

Project description here...
```

### Complete Badge Row Example

```markdown
<!-- Recommended badge order: Security → Quality → Build → License -->
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/ID/badge)](https://www.bestpractices.dev/projects/ID)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/ORG/REPO/badge)](https://securityscorecards.dev/viewer/?uri=github.com/ORG/REPO)
[![Security Audit](https://img.shields.io/badge/security-audited-green)](SECURITY.md)
[![codecov](https://codecov.io/gh/ORG/REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/ORG/REPO)
[![Go Report Card](https://goreportcard.com/badge/github.com/ORG/REPO)](https://goreportcard.com/report/github.com/ORG/REPO)
[![CI](https://github.com/ORG/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/ORG/REPO/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/ORG/REPO)](LICENSE)
```

## Additional Security Badges

### OpenSSF Scorecard

```markdown
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/ORG/REPO/badge)](https://securityscorecards.dev/viewer/?uri=github.com/ORG/REPO)
```

### SLSA Provenance Level

```markdown
[![SLSA 3](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev)
```

### Sigstore Signed

```markdown
[![Sigstore](https://img.shields.io/badge/sigstore-signed-blue)](https://search.sigstore.dev/?hash=SHA256_HASH)
```

### Security Policy

```markdown
[![Security Policy](https://img.shields.io/badge/security-policy-blue)](SECURITY.md)
```

## Badge Verification

### Automated Badge Check

```yaml
# .github/workflows/verify-badges.yml
name: Verify Badges
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly
  workflow_dispatch:

jobs:
  check-badges:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check OpenSSF Badge Status
        run: |
          STATUS=$(curl -s "https://www.bestpractices.dev/projects/YOUR_ID.json" | jq -r '.badge_level')
          echo "Current badge level: $STATUS"
          if [ "$STATUS" = "passing" ] || [ "$STATUS" = "silver" ] || [ "$STATUS" = "gold" ]; then
            echo "✅ Badge status valid"
          else
            echo "❌ Badge status issue"
            exit 1
          fi

      - name: Check Scorecard
        run: |
          SCORE=$(curl -s "https://api.securityscorecards.dev/projects/github.com/ORG/REPO" | jq -r '.score')
          echo "Scorecard score: $SCORE"
```

### Badge Link Validator

```bash
#!/bin/bash
# scripts/verify-badge-links.sh

echo "Checking badge links in README.md..."

# Extract all badge URLs
BADGES=$(grep -oP 'https://[^)]+badge[^)]*' README.md)

for URL in $BADGES; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
    if [ "$STATUS" = "200" ]; then
        echo "✅ $URL"
    else
        echo "❌ $URL (HTTP $STATUS)"
        EXIT_CODE=1
    fi
done

exit ${EXIT_CODE:-0}
```

## Tracking Progress

### Progress Badge

For projects working toward a badge level:

```markdown
<!-- Show progress toward Silver -->
[![OpenSSF Progress](https://img.shields.io/badge/OpenSSF-85%25%20toward%20Silver-yellow)](https://www.bestpractices.dev/projects/ID)
```

### Criteria Checklist in README

```markdown
## OpenSSF Best Practices Progress

- [x] Passing Level (100%)
- [x] Security policy documented
- [x] Signed releases
- [ ] Silver Level (85%)
  - [x] DCO enforcement
  - [x] 80% test coverage
  - [ ] Two-person review (solo maintainer)
- [ ] Gold Level (40%)
  - [ ] 90% test coverage
  - [ ] Security audit
```

## Badge Criteria Alignment

| Criterion | Requirement | How to Display |
|-----------|-------------|----------------|
| documentation_achievements | Badge displayed | Add to README.md header |
| documentation_basics | Project purpose clear | README intro section |
| achieve_passing | Passing badge earned | Badge shows automatically |
| achieve_silver | Silver badge earned | Badge shows automatically |

## Resources

- [OpenSSF Best Practices Badge](https://www.bestpractices.dev/)
- [OpenSSF Scorecard](https://securityscorecards.dev/)
- [Shields.io Custom Badges](https://shields.io/)
- [SLSA Badge Generator](https://slsa.dev/get-started)
