# Repository Structure Reference

Standard files and directories for GitHub open source projects.

## Root Directory Files

### README.md
Primary project documentation visible on repository homepage.

**Essential Sections:**
```markdown
# Project Name

Brief description (1-2 sentences)

## Features
- Key feature 1
- Key feature 2

## Installation
```bash
# Installation commands
```

## Quick Start
```bash
# Usage example
```

## Documentation
Link to full docs

## Contributing
Link to CONTRIBUTING.md

## License
License type with link
```

### LICENSE
Standard open source license file.

**Common Choices:**
| License | Use Case |
|---------|----------|
| MIT | Maximum permissiveness |
| Apache-2.0 | Patent protection |
| GPL-3.0 | Copyleft requirement |
| BSD-3-Clause | Simple permissive |

### CHANGELOG.md
Version history following [Keep a Changelog](https://keepachangelog.com/) format.

**Structure:**
```markdown
# Changelog

## [Unreleased]

## [1.2.0] - 2024-01-15
### Added
- New feature X

### Changed
- Updated behavior Y

### Fixed
- Bug in Z

### Removed
- Deprecated feature W
```

### CONTRIBUTING.md
Contributor guidelines and development setup.

**Essential Sections:**
- Development environment setup
- Code style requirements
- Testing expectations
- Pull request process
- Commit message format

### CODE_OF_CONDUCT.md
Community behavior standards.

**Recommended:** [Contributor Covenant](https://www.contributor-covenant.org/) v2.1

### SECURITY.md
Security policy and vulnerability reporting.

**Essential Sections:**
- Supported versions
- Reporting process (GitHub Security Advisories preferred)
- Response timeline
- Security measures in place

### GOVERNANCE.md
Project decision-making structure.

**Models:**
- BDFL (Benevolent Dictator For Life)
- Meritocracy
- Liberal contribution
- Technical steering committee

## .github Directory

### CODEOWNERS
Automatic review assignment.

```
# Default owners
* @org/maintainers

# Directory-specific
/src/ @org/core-team
/.github/ @org/maintainers
/SECURITY.md @org/security-team
```

### dependabot.yml
Automated dependency updates.

### renovate.json
Alternative to Dependabot with more configuration options.

### ISSUE_TEMPLATE/
- `bug_report.md` - Bug report template
- `feature_request.md` - Feature request template
- `config.yml` - Issue template chooser configuration

### PULL_REQUEST_TEMPLATE.md
Standard PR description format.

### workflows/
GitHub Actions workflow files.

**Common Workflows:**
| File | Purpose |
|------|---------|
| ci.yml | Continuous integration |
| release.yml | Release automation |
| scorecard.yml | OpenSSF Scorecard |
| auto-merge.yml | Dependency auto-merge |

## Language-Specific Files

### Go Projects
```
project/
├── go.mod
├── go.sum
├── .golangci.yml
├── .goreleaser.yml (optional)
└── .slsa-goreleaser/ (for SLSA releases)
```

### PHP/TYPO3 Projects
```
project/
├── composer.json
├── composer.lock
├── .php-cs-fixer.php
├── phpstan.neon
├── rector.php
└── Build/
    └── phpunit/
```

### Node.js Projects
```
project/
├── package.json
├── package-lock.json
├── .eslintrc.js
├── .prettierrc
└── tsconfig.json (TypeScript)
```

## Directory Structure Patterns

### By Feature (Recommended)
```
project/
├── cmd/           # Go: Entry points
├── internal/      # Go: Private packages
├── pkg/           # Go: Public packages
├── Classes/       # PHP: Source code
├── src/           # Generic: Source code
├── tests/         # Test files
├── docs/          # Documentation
└── scripts/       # Utility scripts
```

### By Layer
```
project/
├── controllers/
├── services/
├── repositories/
├── models/
└── utils/
```

## Best Practices

1. **Keep root clean**: Only essential config files at root
2. **Group related files**: Use directories for organization
3. **Follow conventions**: Use standard names (src/, tests/, docs/)
4. **Document structure**: Include structure explanation in README
5. **Ignore properly**: Maintain comprehensive .gitignore
