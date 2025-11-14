# Netresearch Claude Code Marketplace

Claude Code plugins for TYPO3 development and technical documentation.

## Installation

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

Then use `/plugin` to browse and install plugins.

## Sync Status

**Last Sync:** 2025-10-27 (via scheduled weekly sync)
**Sync Frequency:** Weekly (Monday 2 AM UTC)
**Immediate Sync:** ⚠️ Not configured (requires notify workflow in source repos - see [SYNC-SETUP.md](SYNC-SETUP.md))

## Installed Skills

| Skill | Repository | Description |
|-------|------------|-------------|
| TYPO3 Documentation | [typo3-docs-skill](https://github.com/netresearch/typo3-docs-skill) | Create TYPO3 extension documentation |
| TYPO3 Testing | [typo3-testing-skill](https://github.com/netresearch/typo3-testing-skill) | Manage TYPO3 extension tests |
| TYPO3 DDEV Setup | [typo3-ddev-skill](https://github.com/netresearch/typo3-ddev-skill) | Automate DDEV environment setup |
| TYPO3 Core Contributions | [typo3-core-contributions-skill](https://github.com/netresearch/typo3-core-contributions-skill) | Guide TYPO3 core contributions |
| TYPO3 Conformance | [typo3-conformance-skill](https://github.com/netresearch/typo3-conformance-skill) | Evaluate TYPO3 standards compliance |
| Netresearch Branding | [netresearch-branding-skill](https://github.com/netresearch/netresearch-branding-skill) | Apply Netresearch brand guidelines |
| AGENTS.md Generator | [agents-skill](https://github.com/netresearch/agents-skill) | Generate AGENTS.md documentation |

## Architecture

This marketplace uses an **automated sync workflow** to maintain skills from individual source repositories. Each skill is maintained in its own repository and synced to this marketplace via GitHub Actions.

**Benefits:**
- ✅ Single source of truth - each skill in its own repository
- ✅ Independent development and testing
- ✅ Automated version tracking with semantic versioning + commit dates
- ✅ Scheduled and on-demand synchronization
- ✅ Consistent marketplace structure

**Sync Workflow:**
1. Skills are developed and versioned in separate repositories (see "Installed Skills" table for repository links)
2. GitHub Actions sync workflow clones each skill repository
3. Semantic version is extracted from skill's `SKILL.md`
4. Last commit date is appended to create final version (e.g., `1.2.3-20251021`)
5. Skills are copied to `skills/` directory
6. Marketplace metadata is updated with current versions

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

### TYPO3 DDEV Setup
Automate DDEV environment setup for TYPO3 extension development with multi-version testing.

**Repository:** https://github.com/netresearch/typo3-ddev-skill

**Features:**
- Automated DDEV configuration generation for TYPO3 extensions
- Multi-version TYPO3 testing environment (11.5, 12.4, 13.4 LTS)
- Custom DDEV commands for one-command installation
- Intelligent extension metadata detection
- Apache vhost configuration for all TYPO3 versions
- Docker volume management for persistent data
- Pre-configured development settings (debug, trusted hosts)
- Complete automation from detection to ready-to-use backend

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

### TYPO3 Core Contributions
Guide contributions to TYPO3 core following official contribution guidelines.

**Repository:** https://github.com/netresearch/typo3-core-contributions-skill

**Features:**
- Patch creation and Gerrit workflow
- TYPO3 coding guidelines compliance
- Testing requirements for core contributions
- Review process guidance
- Forge issue integration
- Commit message formatting
- Change request best practices

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

### AGENTS.md Generator
Generate and maintain AGENTS.md files following the public agents.md convention.

**Repository:** https://github.com/netresearch/agents-skill

**Features:**
- Thin root files with precedence rules
- Scoped files for subsystems
- Auto-extract commands from build tools
- Language-specific templates (Go, PHP, TypeScript, Python)
- Standard conventions adherence
- Build system integration

---

**Maintained by:** Netresearch DTT GmbH, Leipzig

**For Sync Setup & Maintenance:** See [SYNC-SETUP.md](SYNC-SETUP.md)
