# GitHub Repository Setup Guide

This guide helps you publish the typo3-ddev-skill to GitHub under the Netresearch organization.

## Option 1: Create Repository via GitHub Web Interface

### Step 1: Create Repository on GitHub

1. Go to https://github.com/orgs/netresearch/repositories
2. Click "New repository"
3. Configure:
   - **Repository name**: `typo3-ddev-skill`
   - **Description**: `Claude Code skill for automating DDEV environment setup in TYPO3 extension projects`
   - **Visibility**: Public
   - **Initialize**: DO NOT initialize with README, .gitignore, or license (we have them)
4. Click "Create repository"

### Step 2: Push Local Repository to GitHub

```bash
cd /tmp/typo3-ddev-skill

# Initialize git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: TYPO3 DDEV skill for Claude Code

- Automated DDEV setup for TYPO3 extension development
- Support for TYPO3 11.5, 12.4, and 13.4 LTS
- Multi-version testing environment
- Custom DDEV commands for easy installation
- Based on ddev-for-typo3-extensions pattern by Armin Vieweg"

# Add GitHub remote (replace with actual org URL)
git remote add origin git@github.com:netresearch/typo3-ddev-skill.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 3: Configure Repository Settings

On GitHub:

1. **Add Topics** (Settings → General → Topics):
   - `typo3`
   - `ddev`
   - `claude-code`
   - `skill`
   - `docker`
   - `typo3-extension`
   - `development-environment`

2. **Set Description**:
   ```
   Claude Code skill for automating DDEV environment setup in TYPO3 extension projects
   ```

3. **Set Website** (if applicable):
   ```
   https://www.netresearch.de
   ```

4. **Enable Features**:
   - ✅ Issues
   - ✅ Discussions (optional, for community support)
   - ✅ Wiki (optional)

## Option 2: Create Repository via GitHub CLI

If you have [GitHub CLI](https://cli.github.com/) installed:

```bash
cd /tmp/typo3-ddev-skill

# Initialize git repository
git init
git add .
git commit -m "Initial commit: TYPO3 DDEV skill for Claude Code"

# Create repository under netresearch org
gh repo create netresearch/typo3-ddev-skill \
  --public \
  --source=. \
  --remote=origin \
  --description="Claude Code skill for automating DDEV environment setup in TYPO3 extension projects"

# Push code
git push -u origin main

# Add topics
gh repo edit netresearch/typo3-ddev-skill \
  --add-topic typo3 \
  --add-topic ddev \
  --add-topic claude-code \
  --add-topic skill \
  --add-topic docker \
  --add-topic typo3-extension
```

## Post-Creation Tasks

### 1. Add Repository Description and Metadata

Create/update `.github/ISSUE_TEMPLATE/bug_report.md`:

```markdown
---
name: Bug report
about: Create a report to help improve the skill
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear description of the bug.

**Environment**
- DDEV version: [e.g., 1.22.0]
- TYPO3 version: [e.g., 13.4]
- OS: [e.g., macOS 14.0]
- Claude Code version: [e.g., 1.0.0]

**To Reproduce**
Steps to reproduce the behavior:
1. Run command '...'
2. See error

**Expected behavior**
What you expected to happen.

**Actual behavior**
What actually happened.

**Logs**
```
Paste relevant logs here
```
```

### 2. Add CI/CD Workflow (Optional)

Create `.github/workflows/validate.yml`:

```yaml
name: Validate Templates

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check template syntax
        run: |
          # Validate YAML files
          for file in templates/*.yaml; do
            echo "Validating $file"
            python3 -c "import yaml; yaml.safe_load(open('$file'))" || exit 1
          done

      - name: Check shell scripts
        run: |
          # Validate shell scripts
          for file in templates/commands/*; do
            echo "Checking $file"
            bash -n "$file" || exit 1
          done
```

### 3. Create Releases

After pushing to GitHub:

```bash
# Tag the initial version
git tag -a v1.0.0 -m "Release v1.0.0: Initial TYPO3 DDEV skill

Features:
- Automated DDEV setup for TYPO3 extensions
- Support for TYPO3 11.5, 12.4, 13.4 LTS
- Multi-version testing environment
- Custom DDEV commands
- Comprehensive documentation"

# Push the tag
git push origin v1.0.0
```

Then create a release on GitHub:

1. Go to Releases → "Create a new release"
2. Select tag `v1.0.0`
3. Title: `v1.0.0 - Initial Release`
4. Description:
   ```markdown
   ## 🎉 Initial Release

   Claude Code skill for automating DDEV environment setup in TYPO3 extension projects.

   ### Features
   - ✅ Automated DDEV configuration generation
   - ✅ Support for TYPO3 11.5, 12.4, 13.4 LTS
   - ✅ Multi-version testing environment
   - ✅ Custom DDEV commands (install-v11, install-v12, install-v13, install-all)
   - ✅ Comprehensive documentation and examples

   ### Installation

   ```bash
   cd ~/.claude/skills/
   git clone https://github.com/netresearch/typo3-ddev-skill.git
   ```

   ### Usage

   ```
   /typo3-ddev
   ```

   Or ask Claude: "Set up DDEV for my TYPO3 extension"

   ### Credits

   Based on the excellent work by [Armin Vieweg](https://github.com/a-r-m-i-n) in [ddev-for-typo3-extensions](https://github.com/a-r-m-i-n/ddev-for-typo3-extensions).
   ```

### 4. Add CONTRIBUTING.md

```bash
cat > /tmp/typo3-ddev-skill/CONTRIBUTING.md << 'EOF'
# Contributing to TYPO3 DDEV Skill

Thank you for your interest in contributing! 🎉

## How to Contribute

### Reporting Bugs

Use the [Bug Report](https://github.com/netresearch/typo3-ddev-skill/issues/new?template=bug_report.md) template.

### Suggesting Features

Open a [Feature Request](https://github.com/netresearch/typo3-ddev-skill/issues/new?template=feature_request.md).

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes
5. Commit with clear messages (`git commit -m 'Add: support for TYPO3 14'`)
6. Push to your fork (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Guidelines

- Keep templates generic and reusable
- Test across TYPO3 11.5, 12.4, and 13.4
- Update documentation for any changes
- Follow existing code style
- Add examples for new features

### Testing Your Changes

```bash
# Test with a real TYPO3 extension
cd ~/test-extension
# Apply your modified skill
# Verify DDEV setup works correctly
```

## Code of Conduct

Be respectful and constructive. We're all here to help improve TYPO3 development.

## Questions?

Open a [Discussion](https://github.com/netresearch/typo3-ddev-skill/discussions).
EOF
```

## Repository Access

Make sure you have:

1. **Write access** to the Netresearch organization on GitHub
2. **SSH key** configured: https://github.com/settings/keys
3. **Git configured** with your Netresearch email:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.name@netresearch.de"
   ```

## Sharing the Skill

After publishing:

1. **Announce on TYPO3 Slack**: #ddev channel
2. **Tweet/Post** (if applicable): @netresearch
3. **Update internal documentation**: Netresearch wiki
4. **Share with team**: Email/Slack

## Maintenance

### Regular Updates

- Monitor TYPO3 releases for new versions
- Update DDEV compatibility as needed
- Respond to issues and PRs
- Keep documentation current

### Version Bumping

```bash
# For bug fixes
git tag v1.0.1

# For new features
git tag v1.1.0

# For breaking changes
git tag v2.0.0
```

---

**Questions?** Contact the team lead or open a GitHub issue.
