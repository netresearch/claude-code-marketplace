# Developer Certificate of Origin (DCO) Implementation Guide

The DCO is a lightweight way to certify that contributors have the right to submit their code under the project's license.

## What is DCO?

The [Developer Certificate of Origin](https://developercertificate.org/) is a legal statement that contributors make when submitting code:

```
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution is maintained
    indefinitely and may be redistributed consistent with this project
    or the open source license(s) involved.
```

## Implementation Steps

### 1. Document DCO in CONTRIBUTING.md

Add this section to your CONTRIBUTING.md:

```markdown
## Developer Certificate of Origin (DCO)

All contributions to this project must be signed off using the DCO.

### Sign Your Commits

Use the `-s` flag when committing:

\`\`\`bash
git commit -s -m "feat: add new feature"
\`\`\`

This adds a `Signed-off-by` line to your commit message:

\`\`\`
feat: add new feature

Signed-off-by: Your Name <your.email@example.com>
\`\`\`

### Retroactive Sign-off

If you forgot to sign a commit:

\`\`\`bash
# For the last commit
git commit --amend -s

# For multiple commits
git rebase --signoff HEAD~N
\`\`\`

### Configure Git for Automatic Sign-off

\`\`\`bash
git config --global alias.cs "commit -s"
\`\`\`
```

### 2. Add GitHub Action for Enforcement

Create `.github/workflows/dco.yml`:

```yaml
name: DCO Check

on:
  pull_request:
    branches: [main, master]

permissions:
  contents: read
  pull-requests: read

jobs:
  dco:
    name: DCO Check
    runs-on: ubuntu-latest
    steps:
      - name: Check DCO
        uses: dcoapp/app@v1
```

### 3. Add DCO to PR Template

Add to `.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## DCO Sign-off

- [ ] I have signed off all commits in this PR (`git commit -s`)

By submitting this PR, I certify that my contribution is made under
the terms of the Developer Certificate of Origin.
```

## Verification

### Check a Commit

```bash
git log --format='%h %s%n  Signed-off-by: %aN <%aE>' -1
```

### Verify All Commits in a PR

```bash
git log origin/main..HEAD --format='%h %B' | grep -B1 "Signed-off-by:"
```

## Common Issues

### 1. Missing Sign-off

**Error**: "DCO check failed"

**Fix**:
```bash
git rebase --signoff HEAD~N
git push --force-with-lease
```

### 2. Email Mismatch

**Error**: "Email in sign-off doesn't match commit author"

**Fix**:
```bash
git config user.email "your.email@example.com"
git commit --amend -s
```

### 3. Corporate Email Required

Some projects require corporate email addresses. Configure:

```bash
git config user.email "you@company.com"
```

## DCO vs CLA

| Aspect | DCO | CLA |
|--------|-----|-----|
| Legal weight | Per-commit attestation | One-time signed agreement |
| Friction | Low (just `-s` flag) | Higher (legal review) |
| Implementation | Git hooks/CI | Bot or manual process |
| Common in | Linux kernel, CNCF | Apache, Google projects |

## OpenSSF Badge Requirements

For **Silver level**:
- `dco`: The project MUST have a way to ensure contributors have rights to contribute

This is satisfied by:
1. DCO enforcement (recommended)
2. CLA (Contributor License Agreement)
3. Clear license in CONTRIBUTING.md

## References

- [Developer Certificate of Origin](https://developercertificate.org/)
- [DCO GitHub App](https://github.com/dcoapp/app)
- [Git sign-off documentation](https://git-scm.com/docs/git-commit#Documentation/git-commit.txt--s)
