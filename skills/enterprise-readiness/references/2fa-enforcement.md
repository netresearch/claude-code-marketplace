# Two-Factor Authentication Enforcement Guide

> OpenSSF Gold Badge requirements: `require_2FA`, `secure_2FA`
>
> Projects must require 2FA for contributors with commit/accept rights
> and encourage secure 2FA methods (hardware tokens, TOTP).

## GitHub Organization 2FA

### Enable Organization-Wide 2FA Requirement

1. Go to **Organization Settings** → **Security** → **Authentication security**
2. Enable **Require two-factor authentication**
3. Set grace period for existing members (recommended: 7 days)

```
Settings → Security → Authentication security
☑️ Require two-factor authentication for everyone in the organization
```

### Verify Member Compliance

```bash
# List members without 2FA (requires admin)
gh api orgs/YOUR_ORG/members --jq '.[] | select(.two_factor_disabled == true) | .login'

# Organization security overview
gh api orgs/YOUR_ORG --jq '{
  members: .members_with_two_factor_disabled,
  total: .members_count
}'
```

## Repository-Level Protection

### Branch Protection with 2FA

```yaml
# Recommended branch protection settings
branch_protection:
  required_status_checks:
    strict: true
    contexts: ["ci", "security"]
  enforce_admins: true
  required_pull_request_reviews:
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
    required_approving_review_count: 1
  # Note: GitHub enforces org-level 2FA requirement
```

### Commit Signing (Additional Security)

2FA protects account access; commit signing protects commit integrity:

```bash
# Configure GPG signing
git config --global commit.gpgsign true
git config --global user.signingkey YOUR_KEY_ID

# Or use SSH signing (requires 2FA to add key)
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
```

## Secure 2FA Methods

### Recommended (Gold Badge: `secure_2FA`)

| Method | Security Level | Notes |
|--------|---------------|-------|
| Hardware Security Key | ⭐⭐⭐⭐⭐ | YubiKey, Titan - phishing resistant |
| TOTP Authenticator App | ⭐⭐⭐⭐ | Google Auth, Authy, 1Password |
| GitHub Mobile | ⭐⭐⭐⭐ | Push notifications |
| Passkeys | ⭐⭐⭐⭐⭐ | Platform authenticators, biometric |

### Not Recommended

| Method | Issues |
|--------|--------|
| SMS | Vulnerable to SIM swapping |
| Email | Single point of failure |
| Backup codes only | Static, easily compromised |

## Documentation Requirements

### SECURITY.md Section

Add to your SECURITY.md:

```markdown
## Contributor Security Requirements

### Two-Factor Authentication

All contributors with commit access MUST enable two-factor authentication (2FA).

**Required for:**
- Repository administrators
- Contributors with write access
- Code owners
- Release managers

**Recommended 2FA methods:**
1. Hardware security keys (YubiKey, Titan Key)
2. TOTP authenticator apps (not SMS)
3. Passkeys/Platform authenticators

**Setup instructions:**
- [GitHub 2FA Setup](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa)
- [Hardware Key Setup](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication#configuring-two-factor-authentication-using-a-security-key)

### Commit Signing

We encourage (but do not require) GPG or SSH signed commits.
See [Signing Commits](https://docs.github.com/en/authentication/managing-commit-signature-verification).
```

### CONTRIBUTING.md Section

```markdown
## Security Requirements

Before your first contribution:

1. **Enable 2FA** on your GitHub account
   - Required for all contributors with commit access
   - Recommended: Hardware security key or authenticator app
   - [Setup Guide](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa)

2. **Optional: Sign your commits**
   - GPG signing provides non-repudiation
   - [Signing Guide](https://docs.github.com/en/authentication/managing-commit-signature-verification)
```

## Verification Workflow

### Check 2FA Status in CI

```yaml
# .github/workflows/security-check.yml
name: Security Compliance
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  check-contributor:
    runs-on: ubuntu-latest
    steps:
      - name: Check PR author 2FA (informational)
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          # Note: 2FA status not directly available via API
          # Organization-level 2FA requirement is the enforcement mechanism
          echo "✅ PR from ${{ github.actor }}"
          echo "ℹ️ 2FA enforcement is handled at organization level"
```

### Organization Audit

```bash
#!/bin/bash
# scripts/audit-2fa.sh

ORG="your-org"

echo "=== 2FA Compliance Audit ==="

# Check org 2FA requirement
REQUIRED=$(gh api orgs/$ORG --jq '.two_factor_requirement_enabled')
echo "2FA Required: $REQUIRED"

if [ "$REQUIRED" = "true" ]; then
    echo "✅ Organization requires 2FA"
else
    echo "❌ Organization does NOT require 2FA"
    echo "Action: Enable at Settings → Security → Authentication security"
fi

# List admins (should all have 2FA if org requires it)
echo ""
echo "Repository Admins (all should have 2FA):"
gh api repos/$ORG/REPO/collaborators --jq '.[] | select(.permissions.admin == true) | .login'
```

## Badge Criteria Alignment

| Criterion | Requirement | Implementation |
|-----------|-------------|----------------|
| `require_2FA` | 2FA required for privileged access | Organization 2FA requirement |
| `secure_2FA` | Encourage non-SMS 2FA | Document recommended methods |
| `access_continuity` | Maintain access if contributor unavailable | Multiple admins with 2FA |

## Solo Maintainer Considerations

For solo maintainers who cannot enforce organization-level 2FA:

```markdown
## 2FA Statement (Solo Maintainer)

This project is maintained by a single developer.

**2FA Status:**
- ✅ Maintainer uses hardware security key (YubiKey)
- ✅ Backup codes stored securely offline
- ✅ Recovery email protected with 2FA

**For future contributors:**
- 2FA will be required before granting write access
- Hardware keys or authenticator apps recommended
```

## Resources

- [GitHub 2FA Documentation](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa)
- [FIDO Alliance - Security Keys](https://fidoalliance.org/)
- [OpenSSF Badge 2FA Criteria](https://www.bestpractices.dev/en/criteria#2.require_2FA)
- [NIST Digital Identity Guidelines](https://pages.nist.gov/800-63-3/)
