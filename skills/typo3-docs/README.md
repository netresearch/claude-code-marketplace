# TYPO3 Documentation Skill

A comprehensive Claude Code skill for creating and maintaining TYPO3 extension documentation following official TYPO3 documentation standards.

## Overview

This skill provides guidance for working with TYPO3 extension documentation in reStructuredText (RST) format, including TYPO3-specific directives, local rendering with Docker, validation procedures, and automated deployment through TYPO3 Intercept.

## Features

- **Documentation Extraction** - Automated extraction from code, configs, and repository metadata
- **Gap Analysis** - Identify missing and outdated documentation
- **RST Syntax Reference** - Complete reStructuredText formatting guide
- **TYPO3-Specific Directives** - confval, versionadded, php:method, card-grid
- **Local Rendering** - Docker-based documentation rendering scripts
- **Validation Tools** - RST syntax and quality check scripts
- **Quality Standards** - Pre-commit checklists and best practices
- **TYPO3 Intercept** - Automated deployment guidance
- **AI Assistant Context** - AGENTS.md templates for Documentation/ folders

## Installation

### Option 1: Via Netresearch Marketplace (Recommended)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

Then browse skills with `/plugin`.

### Option 2: Download Release

Download the [latest release](https://github.com/netresearch/typo3-docs-skill/releases/latest) and extract to `~/.claude/skills/typo3-docs/`

### Option 3: Manual Installation

```bash
# Using curl
curl -L https://github.com/netresearch/typo3-docs-skill/archive/refs/heads/main.zip -o typo3-docs.zip
unzip typo3-docs.zip -d ~/.claude/skills/
mv ~/.claude/skills/typo3-docs-skill-main ~/.claude/skills/typo3-docs

# Or using git
git clone https://github.com/netresearch/typo3-docs-skill.git ~/.claude/skills/typo3-docs
```

### Verify Installation

The skill will automatically activate when working with TYPO3 documentation:

- Creating/updating `Documentation/*.rst` files
- Using TYPO3-specific directives
- Rendering documentation locally
- Following TYPO3 documentation guidelines

## Contents

### SKILL.md

Main skill file with comprehensive instructions for:
- Documentation structure and workflow
- Configuration documentation with confval
- Version documentation with versionadded/versionchanged
- PHP API documentation with php:method
- Card grid navigation with stretched links
- Cross-references and quality standards

### references/

**rst-syntax.md** - Complete RST syntax reference:
- Headings, code blocks, lists, links
- Tables, admonitions, images
- Whitespace rules and common mistakes

**typo3-directives.md** - TYPO3-specific directives:
- confval for configuration values
- Version directives (added/changed/deprecated)
- PHP domain (class/method/property)
- Card grids with stretched links
- Intersphinx references
- Quality checklists

**extraction-patterns.md** - Documentation extraction guide:
- Multi-source extraction patterns (PHP, configs, repository)
- Data-to-RST mapping strategies
- Gap analysis workflow
- Template generation approaches
- Quality standards for extraction

**typo3-extension-architecture.md** - TYPO3 official file structure reference:
- File structure hierarchy with priority weights
- Directory structure weights (Classes/, Configuration/, Resources/)
- Extraction weight matrix (Priority 1-5)
- Quality weighting algorithm
- Gap analysis priority calculation
- Documentation mapping strategies

### templates/

**AGENTS.md** - AI assistant context template:
- Documentation strategy and audience
- TYPO3 RST syntax patterns
- Directive usage examples
- Cross-reference patterns
- Validation and rendering procedures

### scripts/

**add-agents-md.sh** - Add AI context to Documentation/:
- Creates AGENTS.md from template
- Provides documentation context for AI assistants
- Helps AI understand project documentation structure

**validate_docs.sh** - Validation script:
- Checks RST syntax
- Validates Settings.cfg and Index.rst
- Detects encoding issues
- Identifies trailing whitespace

**render_docs.sh** - Rendering script:
- Renders documentation locally with Docker
- Uses official TYPO3 render-guides image
- Outputs to Documentation-GENERATED-temp/

**extract-all.sh** - Documentation extraction orchestrator:
- Extracts data from PHP code, extension configs, composer.json
- Optional: build configs (.github/workflows, phpunit.xml)
- Optional: repository metadata (GitHub/GitLab API)
- Outputs to .claude/docs-extraction/data/*.json

**analyze-docs.sh** - Documentation coverage analysis:
- Compares extracted data with existing Documentation/
- Identifies missing and outdated documentation
- Generates Documentation/ANALYSIS.md with recommendations
- Prioritizes action items for systematic documentation

**extract-php.sh** - PHP code extraction:
- Parses Classes/**/*.php for docblocks and signatures
- Extracts class descriptions, methods, constants
- Outputs to .claude/docs-extraction/data/php_apis.json

**extract-extension-config.sh** - Extension configuration extraction:
- Parses ext_emconf.php for extension metadata
- Parses ext_conf_template.txt for configuration options
- Identifies security warnings in config comments
- Outputs to extension_meta.json and config_options.json

**extract-composer.sh** - Composer dependency extraction:
- Extracts requirements and dev-requirements
- Outputs to .claude/docs-extraction/data/dependencies.json

**extract-project-files.sh** - Project file extraction:
- Extracts content from README.md, CHANGELOG.md
- Outputs to .claude/docs-extraction/data/project_files.json

**extract-build-configs.sh** - Build configuration extraction (optional):
- Extracts CI/CD configurations, PHPUnit settings
- Outputs to .claude/docs-extraction/data/build_configs.json

**extract-repo-metadata.sh** - Repository metadata extraction (optional):
- Fetches GitHub/GitLab repository information
- Requires gh or glab CLI tools
- Outputs to .claude/docs-extraction/data/repo_metadata.json
- Cached for 24 hours

## Usage

The skill automatically activates for TYPO3 documentation tasks. You can also manually invoke it:

```
/skill typo3-docs
```

### Quick Examples

**Add AI Assistant Context:**
```bash
cd /path/to/your-extension
~/.claude/skills/typo3-docs/scripts/add-agents-md.sh
# Creates Documentation/AGENTS.md with TYPO3 documentation patterns
```

**Extract and Analyze Documentation:**
```bash
cd /path/to/your-extension

# Extract data from code and configs
~/.claude/skills/typo3-docs/scripts/extract-all.sh

# Analyze documentation coverage
~/.claude/skills/typo3-docs/scripts/analyze-docs.sh

# Review the analysis report
cat Documentation/ANALYSIS.md

# Extract with optional sources
~/.claude/skills/typo3-docs/scripts/extract-all.sh --all  # Include build configs & repo metadata
```

**Document Configuration:**
```rst
.. confval:: fetchExternalImages

   :type: boolean
   :Default: true
   :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['ext_key']['setting']

   Controls whether external image URLs are automatically fetched.
```

**Document Version Changes:**
```rst
.. versionadded:: 13.0.0
   The CKEditor plugin now requires ``StyleUtils`` and ``GeneralHtmlSupport``
   dependencies for style functionality.
```

**Create Card Grid Navigation:**
```rst
.. card-grid::
    :columns: 1
    :columns-md: 2

    ..  card:: 📘 Introduction

        Extension overview and features

        ..  card-footer:: :ref:`Read more <introduction>`
            :button-style: btn btn-primary stretched-link
```

**Validate Documentation:**
```bash
~/.claude/skills/typo3-docs/scripts/validate_docs.sh /path/to/project
```

**Render Documentation:**
```bash
~/.claude/skills/typo3-docs/scripts/render_docs.sh /path/to/project
```

## Deployment Setup

**Enable automatic documentation publishing to docs.typo3.org:**

### Prerequisites
1. Extension published in [TYPO3 Extension Repository (TER)](https://extensions.typo3.org/)
2. Git repository URL referenced on TER detail page
3. Valid Documentation/ structure with Index.rst and Settings.cfg

### Quick Webhook Setup

**GitHub:**
```
Settings → Webhooks → Add webhook
Payload URL: https://docs-hook.typo3.org
Content type: application/json
SSL: Enabled
Events: Just the push event
Active: ✓
```

**GitLab:**
```
Settings → Webhooks
URL: https://docs-hook.typo3.org
Triggers: Push events + Tag push events
SSL: Enabled
```

### Verification

After first push, check:
- **Webhook delivery**: GitHub/GitLab webhook recent deliveries (expect `200`)
- **Build status**: [Intercept Dashboard](https://intercept.typo3.com/admin/docs/deployments)
- **Published docs**: `https://docs.typo3.org/p/{vendor}/{extension}/main/en-us/`

**First build requires approval** by TYPO3 Documentation Team (1-3 business days). Future builds are automatic.

**Full webhook setup guide:** [references/intercept-deployment.md](references/intercept-deployment.md)

## Quality Standards

Before committing documentation changes, ensure:

- ✅ No rendering warnings
- ✅ No broken cross-references
- ✅ All confval directives complete
- ✅ Version information for new features
- ✅ Card grids use stretched-link
- ✅ UTF-8 emoji icons in card titles
- ✅ Code blocks specify language
- ✅ Proper heading hierarchy
- ✅ No trailing whitespace

## Resources

**Official Documentation:**
- [TYPO3 Documentation Guide](https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/)
- [RST Reference](https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html)
- [Rendering with Docker](https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Howto/RenderingDocs/Index.html)

**Example Projects:**
- [TYPO3 Best Practice Extension](https://github.com/TYPO3BestPractices/tea)
- [RTE CKEditor Image](https://docs.typo3.org/p/netresearch/rte-ckeditor-image/main/en-us/)

**TYPO3 Intercept:**
- [Deployment Dashboard](https://intercept.typo3.com/admin/docs/deployments)

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes
4. Test the skill thoroughly
5. Commit your changes (`git commit -m 'Add improvement'`)
6. Push to the branch (`git push origin feature/improvement`)
7. Create a Pull Request

## License

This skill is licensed under the same license as the [TYPO3 RTE CKEditor Image extension](https://github.com/netresearch/t3x-rte_ckeditor_image) - GPL-2.0-or-later.

## Support

**Issues and Questions:**
- GitHub Issues: [Report issues](https://github.com/netresearch/typo3-docs-skill/issues)
- TYPO3 Slack: [#typo3-cms](https://typo3.slack.com/archives/typo3-cms)

## Credits

Created by Netresearch DTT GmbH for the TYPO3 community.

Based on:
- [TYPO3 Official Documentation Standards](https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/)
- [Anthropic Skill Creator](https://github.com/anthropics/skills/tree/main/skill-creator)
- Real-world usage in [RTE CKEditor Image Extension](https://github.com/netresearch/t3x-rte_ckeditor_image)

---

**Version:** 1.0.0
**Maintained By:** Netresearch DTT GmbH
**Last Updated:** 2025-10-18

---

**Made with ❤️ for Open Source by [Netresearch](https://www.netresearch.de/)**
