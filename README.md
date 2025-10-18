# Netresearch Claude Code Marketplace

Claude Code plugins for TYPO3 development and technical documentation.

## Installation

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

Then use `/plugin` to browse and install plugins.

## Architecture

This marketplace uses **git submodules** to reference individual skill repositories. Each skill is maintained in its own repository and linked here via submodules in the `skills/` directory.

**Benefits:**
- ✅ Single source of truth - each skill in its own repository
- ✅ Independent versioning and releases
- ✅ No duplicate code
- ✅ Easy to update individual skills
- ✅ Proper version tracking via submodule commits

**Skill Repositories:**
- [typo3-docs-skill](https://github.com/netresearch/typo3-docs-skill)
- [typo3-testing-skill](https://github.com/netresearch/typo3-testing-skill)
- [typo3-conformance-skill](https://github.com/netresearch/typo3-conformance-skill)
- [netresearch-branding-skill](https://github.com/netresearch/netresearch-branding-skill)

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
