# Netresearch Claude Code Marketplace

Claude Code plugins for TYPO3 development and technical documentation.

## Installation

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

Then use `/plugin` to browse and install plugins.

## Installed Skills

| Skill | Version | Last Updated | Description |
|-------|---------|--------------|-------------|
| TYPO3 Documentation | 1.0.0-20251021 | 2025-10-21 | Create TYPO3 extension documentation |
| TYPO3 Testing | 1.0.0-20251021 | 2025-10-21 | Manage TYPO3 extension tests |
| TYPO3 Conformance | 1.0.0-20251021 | 2025-10-21 | Evaluate TYPO3 standards compliance |
| Netresearch Branding | 1.0.0-20251021 | 2025-10-21 | Apply Netresearch brand guidelines |
| AGENTS.md Generator | 1.0.0-20251021 | 2025-10-21 | Generate AGENTS.md documentation |

> **Version Format:** `MAJOR.MINOR.PATCH-YYYYMMDD` (semantic version + last commit date)
>
> See [VERSIONING.md](VERSIONING.md) for details on the versioning strategy.

## Architecture

This marketplace uses an **automated sync workflow** to maintain skills from individual source repositories. Each skill is maintained in its own repository and synced to this marketplace via GitHub Actions.

**Benefits:**
- ✅ Single source of truth - each skill in its own repository
- ✅ Independent development and testing
- ✅ Automated version tracking with semantic versioning + commit dates
- ✅ Scheduled and on-demand synchronization
- ✅ Consistent marketplace structure

**Sync Workflow:**
1. Skills are developed and versioned in separate repositories
2. GitHub Actions sync workflow clones each skill repository
3. Semantic version is extracted from skill's `SKILL.md`
4. Last commit date is appended to create final version (e.g., `1.2.3-20251021`)
5. Skills are copied to `skills/` directory
6. Marketplace metadata is updated with current versions

**Source Repositories:**
- [typo3-docs-skill](https://github.com/netresearch/typo3-docs-skill)
- [typo3-testing-skill](https://github.com/netresearch/typo3-testing-skill)
- [typo3-conformance-skill](https://github.com/netresearch/typo3-conformance-skill)
- [netresearch-branding-skill](https://github.com/netresearch/netresearch-branding-skill)
- [agents-skill](https://github.com/netresearch/agents-skill)

## Available Plugins

### TYPO3 Documentation
Create and maintain TYPO3 extension documentation following official TYPO3 standards.

**Repository:** https://github.com/netresearch/typo3-docs-skill

**Features:**
- Automated documentation extraction from code and configs
- Priority-weighted gap analysis based on TYPO3 architecture
- Smart documentation recommendations sorted by importance
- RST syntax and TYPO3-specific directives
- Local rendering and validation
- TYPO3 Intercept deployment setup

### TYPO3 Testing
Create and manage TYPO3 extension tests with comprehensive testing infrastructure.

**Repository:** https://github.com/netresearch/typo3-testing-skill

**Features:**
- Unit, functional, and acceptance testing support
- PHPUnit configurations with strict quality settings
- Docker Compose for acceptance tests
- Automated test generation scripts
- CI/CD templates (GitHub Actions, GitLab CI)
- AGENTS.md templates for test context
- Quality tools integration (PHPStan, Rector, php-cs-fixer)

### TYPO3 Conformance Checker
Evaluate TYPO3 extensions for conformance to official TYPO3 standards and best practices.

**Repository:** https://github.com/netresearch/typo3-conformance-skill

**Features:**
- Automated validation against TYPO3 Extension Architecture standards
- PSR-12 and TYPO3-specific code style enforcement
- PHP architecture patterns validation (DI, events, Extbase)
- Testing infrastructure assessment
- Comprehensive conformance scoring (0-100)
- Priority-based action items with migration guides
- Detailed reports with specific file:line references

### Netresearch Branding
Implement Netresearch brand guidelines in web projects with complete design system.

**Repository:** https://github.com/netresearch/netresearch-branding-skill

**Features:**
- Complete color system (Turquoise, Orange, Anthracite)
- Typography standards (Raleway, Open Sans, Calibri)
- Responsive component library (buttons, forms, cards, navigation)
- Production-ready HTML/CSS templates
- WCAG AA accessibility compliance
- Social media specifications
- Web design patterns and best practices
- Interactive component showcase

---

**Maintained by:** Netresearch DTT GmbH, Leipzig
