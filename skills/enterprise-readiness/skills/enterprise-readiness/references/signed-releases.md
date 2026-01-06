# Signed Releases Implementation Guide

Cryptographic signing of releases and tags provides verification that artifacts come from trusted sources.

## Two Types of Signing Required

For **Silver level** OpenSSF Badge:
1. `signed_releases` - Release artifacts are cryptographically signed
2. `version_tags_signed` - Git tags are signed

## Part 1: Signed Git Tags

### Setup GPG Key

```bash
# Generate a GPG key
gpg --full-generate-key

# List keys to get your key ID
gpg --list-secret-keys --keyid-format=long

# Export public key for GitHub
gpg --armor --export YOUR_KEY_ID
```

### Configure Git

```bash
# Set signing key
git config --global user.signingkey YOUR_KEY_ID

# Enable automatic tag signing
git config --global tag.gpgSign true

# Optional: Enable commit signing
git config --global commit.gpgSign true
```

### Create Signed Tags

```bash
# Create signed tag
git tag -s v1.0.0 -m "Release v1.0.0"

# Verify a signed tag
git tag -v v1.0.0

# Push tags
git push origin v1.0.0
```

### Add GPG Key to GitHub

1. Go to Settings → SSH and GPG keys
2. Click "New GPG key"
3. Paste your public key
4. Verify tags will show "Verified" badge

## Part 2: Signed Release Artifacts

### Option A: Cosign (Keyless - Recommended)

Cosign uses OIDC for keyless signing via Sigstore.

**GitHub Actions Workflow:**

```yaml
name: Release

on:
  push:
    tags: ['v*']

permissions:
  contents: write
  id-token: write  # Required for OIDC

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build artifacts
        run: make build

      - name: Install Cosign
        uses: sigstore/cosign-installer@v3.8.2

      - name: Sign artifacts
        run: |
          for file in dist/*; do
            cosign sign-blob --yes \
              --output-certificate "${file}.pem" \
              --output-signature "${file}.sig" \
              "$file"
          done

      - name: Create release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            dist/*
            dist/*.sig
            dist/*.pem
```

**Verification Instructions (add to release notes):**

```markdown
## Verification

Install cosign: https://docs.sigstore.dev/cosign/installation/

Verify artifacts:
\`\`\`bash
cosign verify-blob \
  --certificate ofelia_linux_amd64.pem \
  --signature ofelia_linux_amd64.sig \
  --certificate-identity "https://github.com/owner/repo/.github/workflows/release.yml@refs/tags/v1.0.0" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ofelia_linux_amd64
\`\`\`
```

### Option B: GPG Signing

**GitHub Actions Workflow:**

```yaml
- name: Import GPG key
  uses: crazy-max/ghaction-import-gpg@v6
  with:
    gpg_private_key: ${{ secrets.GPG_PRIVATE_KEY }}
    passphrase: ${{ secrets.GPG_PASSPHRASE }}

- name: Sign artifacts
  run: |
    for file in dist/*; do
      gpg --batch --yes --detach-sign --armor "$file"
    done
```

## Part 3: SLSA Provenance (Level 3)

For highest assurance, use SLSA provenance generation:

```yaml
# Use SLSA GitHub Generator for Go
uses: slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml@v2.1.0
with:
  go-version-file: go.mod
  upload-assets: true
```

This automatically:
- Builds in isolated environment
- Generates signed provenance
- Uploads attestations to release

## Verification Commands

### Verify GPG Signature

```bash
# Verify detached signature
gpg --verify file.asc file

# Verify signed tag
git tag -v v1.0.0
```

### Verify Cosign Signature

```bash
cosign verify-blob \
  --certificate file.pem \
  --signature file.sig \
  --certificate-identity "IDENTITY" \
  --certificate-oidc-issuer "ISSUER" \
  file
```

### Verify SLSA Provenance

```bash
slsa-verifier verify-artifact \
  --provenance-path file.intoto.jsonl \
  --source-uri github.com/owner/repo \
  file
```

## OpenSSF Badge Criteria

| Criterion | Requirement | Implementation |
|-----------|-------------|----------------|
| signed_releases | Artifacts signed | Cosign or GPG |
| version_tags_signed | Git tags signed | `git tag -s` |

## Best Practices

1. **Prefer keyless signing** (Cosign + OIDC) over traditional keys
2. **Sign ALL release artifacts** including checksums and SBOMs
3. **Document verification** in release notes
4. **Automate in CI** - never sign manually
5. **Rotate keys** if using traditional GPG

## Common Issues

### Cosign: "no identity found"
- Ensure `id-token: write` permission
- Verify GitHub OIDC is configured

### GPG: "secret key not available"
- Import key in CI: `gpg --import`
- Set `GPG_TTY` environment variable

### Git: "gpg failed to sign the data"
- Configure `gpg-agent`
- Use `export GPG_TTY=$(tty)`

## References

- [Sigstore/Cosign](https://docs.sigstore.dev/cosign/overview/)
- [SLSA Framework](https://slsa.dev/)
- [Git Signing Documentation](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)
- [GitHub Signed Commits](https://docs.github.com/en/authentication/managing-commit-signature-verification)
