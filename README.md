# Netresearch Claude Code Marketplace

Claude Code plugins for TYPO3 development and technical documentation.

## 🔌 Compatibility

This is an **Agent Skill** following the [open standard](https://agentskills.io) originally developed by Anthropic and released for cross-platform use.

**Supported Platforms:**
- ✅ Claude Code (Anthropic)
- ✅ Cursor
- ✅ GitHub Copilot
- ✅ Other skills-compatible AI agents

> Skills are portable packages of procedural knowledge that work across any AI agent supporting the Agent Skills specification.


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
| TYPO3 CKEditor 5 | [typo3-ckeditor5-skill](https://github.com/netresearch/typo3-ckeditor5-skill) | CKEditor 5 development for TYPO3 v12+ |
| TYPO3 Extension Upgrade | [typo3-extension-upgrade-skill](https://github.com/netresearch/typo3-extension-upgrade-skill) | Systematic extension upgrades to newer LTS versions |
| Jira Integration | [jira-skill](https://github.com/netresearch/jira-skill) | Jira API operations, wiki markup, and workflow automation |
| Git Workflow | [git-workflow-skill](https://github.com/netresearch/git-workflow-skill) | Git branching strategies and Conventional Commits |
| GitHub Project | [github-project-skill](https://github.com/netresearch/github-project-skill) | GitHub repository setup and platform features |
| Enterprise Readiness | [enterprise-readiness-skill](https://github.com/netresearch/enterprise-readiness-skill) | OpenSSF security assessment and compliance |
| Security Audit | [security-audit-skill](https://github.com/netresearch/security-audit-skill) | OWASP security audit patterns for PHP |
| PHP Modernization | [php-modernization-skill](https://github.com/netresearch/php-modernization-skill) | PHP 8.x modernization and type safety |
| Go Development | [go-development-skill](https://github.com/netresearch/go-development-skill) | Production-grade Go development patterns |
| Netresearch Branding | [netresearch-branding-skill](https://github.com/netresearch/netresearch-branding-skill) | Apply Netresearch brand guidelines |
| AGENTS.md Generator | [agents-skill](https://github.com/netresearch/agents-skill) | Generate AGENTS.md documentation |
| CLI Tools | [cli-tools-skill](https://github.com/netresearch/cli-tools-skill) | Auto-install missing CLI tools |
| Coach | [claude-coach-plugin](https://github.com/netresearch/claude-coach-plugin) | Self-improving learning system with friction detection |
| Skill Repo | [skill-repo-skill](https://github.com/netresearch/skill-repo-skill) | Guide for structuring Netresearch skill repositories |

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

### TYPO3 Extension Upgrade
Systematic TYPO3 extension upgrades to newer LTS versions with modern PHP compatibility.

**Repository:** https://github.com/netresearch/typo3-extension-upgrade-skill

**Features:**
- Extension Scanner assessment for deprecated/removed APIs
- Rector for automated PHP code transformations
- Fractor for non-PHP file migrations (FlexForms, TypoScript, YAML, Fluid)
- PHPStan for static analysis
- Version-specific guidance for v11→v12, v12→v13 upgrades
- Dual-version compatibility scenarios (v12+v13 support)
- Common issue solutions and troubleshooting
- Official TYPO3 changelog references (v7-v14)

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

### CLI Tools
Automatic CLI tool management for coding agents with reactive and proactive modes.

**Repository:** https://github.com/netresearch/cli-tools-skill

**Features:**
- Auto-detect "command not found" errors and install missing tools
- 74+ tool catalog (ripgrep, fd, jq, docker, terraform, etc.)
- Project environment auditing and reporting
- Batch update capabilities across package managers
- Smart installation method selection (GitHub releases, cargo, npm, apt/brew)
- Support for Python, Node.js, Rust, Go, PHP, Ruby, and infrastructure projects
- User-level installation priority (~/.local/bin, ~/.cargo/bin)

### Coach
Self-improving learning system that detects friction signals and proposes rule updates.

**Repository:** https://github.com/netresearch/claude-coach-plugin

**Features:**
- Automatic friction signal detection (user corrections, tool failures, repeated instructions, tone escalation)
- LLM-assisted candidate generation using Claude Haiku
- Session-end transcript analysis for comprehensive learning
- Cross-repo learning with fingerprint-based deduplication
- Explicit approval workflow via `/coach` slash commands
- Project vs global scope determination with promotion support
- Auto-configured hooks for UserPromptSubmit, PostToolUse, and Stop events

**Slash Commands:**
| Command | Description |
|---------|-------------|
| `/coach status` | Show system status and statistics |
| `/coach review` | Show pending learning proposals |
| `/coach approve <id>` | Approve and apply a proposal |
| `/coach reject <id>` | Reject a proposal with reason |
| `/coach edit <id>` | Edit a proposal before approving |
| `/coach promote <id>` | Promote project rule to global |
| `/coach init` | Initialize the coach system |

### TYPO3 CKEditor 5
CKEditor 5 development patterns for TYPO3 v12+ including custom plugin development and migration.

**Repository:** https://github.com/netresearch/typo3-ckeditor5-skill

**Features:**
- CKEditor 5 plugin architecture (schema, conversion, commands)
- TYPO3 RTE configuration via YAML
- Custom plugin registration and UI components
- ES6 module development patterns
- Complete CKEditor 4 to 5 migration guides
- Integration with TYPO3 backend modules

### Jira Integration
Comprehensive Jira integration through lightweight Python CLI scripts.

**Repository:** https://github.com/netresearch/jira-skill

**Features:**
- JQL search queries and issue management
- Issue creation, updates, and transitions
- Comment and worklog management
- Sprint and board operations
- Issue linking and attachments
- Jira wiki markup syntax (not Markdown)
- Support for Jira Cloud and Server/Data Center

### Git Workflow
Git workflow best practices for teams and CI/CD pipelines.

**Repository:** https://github.com/netresearch/git-workflow-skill

**Features:**
- Branching strategies (Git Flow, GitHub Flow, Trunk-based)
- Conventional Commits for semantic versioning
- Pull request workflows and code review
- Branch protection configuration
- GitHub Actions and GitLab CI integration
- Advanced Git operations and troubleshooting

### GitHub Project
GitHub repository setup and platform-specific features configuration.

**Repository:** https://github.com/netresearch/github-project-skill

**Features:**
- Repository creation and configuration
- Branch protection rules and PR workflows
- CODEOWNERS configuration
- GitHub Issues, Discussions, and Projects
- Sub-issues and issue hierarchies
- Dependabot/Renovate auto-merge setup
- Merge queue configuration with GraphQL

### Enterprise Readiness
Assess and enhance software projects for enterprise-grade security and compliance.

**Repository:** https://github.com/netresearch/enterprise-readiness-skill

**Features:**
- OpenSSF Scorecard assessment
- Best Practices Badge criteria (Passing/Silver/Gold)
- SLSA Framework compliance
- Supply chain security (SBOMs, signing)
- CI/CD pipeline hardening
- Quality gates and automation scripts
- S2C2F alignment

### Security Audit
Security audit patterns for PHP applications following OWASP guidelines.

**Repository:** https://github.com/netresearch/security-audit-skill

**Features:**
- OWASP Top 10 vulnerability detection
- XXE, SQL injection, XSS, CSRF analysis
- CVSS v3.1 risk scoring
- Secure coding practice validation
- Authentication/authorization assessment
- Security hardening checklists
- Remediation guidance

### PHP Modernization
PHP 8.x modernization patterns for upgrading legacy applications.

**Repository:** https://github.com/netresearch/php-modernization-skill

**Features:**
- PHP 8.1/8.2/8.3 feature adoption
- Constructor property promotion and readonly classes
- Enums, attributes, and match expressions
- Union/intersection types and nullsafe operator
- PHPStan level 9+ compliance
- Symfony best practices integration
- Migration strategies and tooling

### Go Development
Production-grade Go development patterns for building resilient services.

**Repository:** https://github.com/netresearch/go-development-skill

**Features:**
- Architecture patterns for Go services
- Job scheduling and task orchestration
- Docker API integration patterns
- LDAP/Active Directory client implementation
- Resilience patterns (retry, circuit breaker)
- Middleware chains and buffer pooling
- Comprehensive testing strategies

### Skill Repo
Guide for structuring Netresearch skill repositories.

**Repository:** https://github.com/netresearch/skill-repo-skill

**Features:**
- Standard repository layout for skills
- Multi-channel distribution (marketplace, releases, composer)
- PHP ecosystem integration via Composer
- Release workflow configuration
- Validation scripts and templates
- Documentation standards

---

**Maintained by:** Netresearch DTT GmbH, Leipzig

**For Sync Setup & Maintenance:** See [SYNC-SETUP.md](SYNC-SETUP.md)
