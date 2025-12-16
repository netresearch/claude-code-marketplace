# TYPO3 Extension Upgrade Skill

A Claude Code skill for systematically upgrading TYPO3 extensions to newer LTS versions.

**Developed by [Netresearch DTT GmbH](https://www.netresearch.de/)**

## Overview

This skill guides extension developers through upgrading TYPO3 extensions (third-party or custom) to newer TYPO3 LTS versions with modern PHP compatibility. It covers:

- **Extension Scanner** - Backend module for diagnosing deprecated/removed APIs
- **Rector** - Automated PHP code migrations
- **Fractor** - Automated non-PHP file migrations (FlexForms, TypoScript, YAML, Fluid)
- **PHPStan** - Static analysis
- **PHPUnit** - Testing framework setup

## Scope

This skill is for **extension developers** upgrading extension code. It does NOT cover:
- Upgrading TYPO3 project installations
- TYPO3 core upgrades
- Site/instance migrations

## Supported Upgrade Paths

| From | To | Status |
|------|-----|--------|
| v7 | v8 | Documented |
| v8 | v9 | Documented |
| v9 | v10 | Documented |
| v10 | v11 | Documented |
| v11 | v12 | Documented |
| v12 | v13 | Documented |
| v13 | v14 | Monitoring |
| v12 | v12+v13 (dual) | Documented |

## Installation

### Option 1: Via Netresearch Marketplace (Recommended)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

Then browse skills with `/plugin`.

### Option 2: Download Release

Download the [latest release](https://github.com/netresearch/typo3-extension-upgrade-skill/releases/latest) and extract to `~/.claude/skills/typo3-extension-upgrade/`

### Option 3: Manual Installation

```bash
# Copy to your user skills directory
cp -r typo3-extension-upgrade-skill ~/.claude/skills/
```

## Usage

The skill activates automatically when Claude detects:
- TYPO3 extension upgrade requests
- Compatibility issues with newer TYPO3 versions
- Extension modernization tasks

Example prompts:
- "Upgrade this extension to TYPO3 v13"
- "Make this extension compatible with TYPO3 12 and 13"
- "Fix the deprecated API usage in this TYPO3 extension"

## Contents

```
typo3-extension-upgrade-skill/
├── SKILL.md                 # Main skill instructions
├── README.md                # This file
├── assets/                  # Configuration templates
│   ├── rector.php           # Rector configuration
│   ├── fractor.php          # Fractor configuration
│   ├── phpstan.neon         # PHPStan configuration
│   ├── phpunit.xml          # PHPUnit configuration
│   └── .php-cs-fixer.php    # PHP-CS-Fixer configuration
└── references/              # Detailed documentation
    ├── api-changes.md       # Version-specific API migrations (v7-v14)
    └── pre-upgrade.md       # Pre-upgrade checklist
```

## Key Resources

### Official TYPO3 Changelogs

- [v14 Changelog](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-14.html)
- [v13 Changelog](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-13.html)
- [v12 Changelog](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-12.html)
- [v11 Changelog](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-11.html)

### Tools

- [TYPO3 Rector](https://github.com/sabbelasichon/typo3-rector) - PHP migrations
- [TYPO3 Fractor](https://github.com/andreaswolf/fractor) - Non-PHP migrations
- [Extension Scanner](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ExtensionArchitecture/HowTo/UpdateExtensions/ExtensionScanner.html) - API diagnostics

## Author

**Netresearch DTT GmbH**
[https://www.netresearch.de/](https://www.netresearch.de/)

Netresearch is a Leipzig-based technology company specializing in e-commerce, logistics, and TYPO3 solutions. With extensive experience in TYPO3 extension development and maintenance, Netresearch contributes to the TYPO3 ecosystem through open-source extensions and community involvement.

## License

MIT

---

**Made with ❤️ for Open Source by [Netresearch](https://www.netresearch.de/)**
