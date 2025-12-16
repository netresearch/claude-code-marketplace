# TYPO3 CKEditor 5 Development Skill

Expert patterns for CKEditor 5 integration in TYPO3, including custom plugin development, configuration, and migration from CKEditor 4.

## Features

- **CKEditor 5 Architecture**: Plugin system, schema and conversion system, command pattern implementation, UI component development
- **TYPO3 Integration**: RTE configuration (YAML), custom plugin registration, content element integration, backend module integration
- **Migration Patterns**: CKEditor 4 to 5 migration, custom plugin conversion, configuration transformation, data migration strategies
- **Plugin Development**: Complete patterns for creating custom CKEditor 5 plugins with schema definitions, converters, and commands
- **Configuration Management**: YAML-based RTE presets with toolbar, heading, table, and link configurations
- **ES6 Module Development**: Modern JavaScript patterns for CKEditor 5 plugin architecture

## Installation

### Option 1: Via Netresearch Marketplace (Recommended)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

### Option 2: Download Release

Download the [latest release](https://github.com/netresearch/typo3-ckeditor5-skill/releases/latest) and extract to `~/.claude/skills/typo3-ckeditor5-skill/`

### Option 3: Composer (PHP projects)

```bash
composer require netresearch/agent-typo3-ckeditor5-skill
```

**Requires:** [netresearch/composer-agent-skill-plugin](https://github.com/netresearch/composer-agent-skill-plugin)

## Usage

This skill is automatically triggered when:

- Developing custom CKEditor 5 plugins for TYPO3
- Configuring RTE presets in TYPO3 v12+
- Integrating CKEditor with TYPO3 backend modules
- Migrating from CKEditor 4 to CKEditor 5
- Working with CKEditor 5 schema, conversion, or command patterns

Example queries:
- "Create a custom CKEditor 5 plugin for TYPO3"
- "Configure RTE preset with custom toolbar"
- "Migrate CKEditor 4 plugin to CKEditor 5"
- "Implement custom element with schema and converters"

## Structure

```
typo3-ckeditor5-skill/
├── SKILL.md                              # Skill metadata and core patterns
├── references/
│   ├── ckeditor5-architecture.md         # CKEditor 5 core concepts
│   ├── typo3-integration.md              # TYPO3-specific integration patterns
│   ├── plugin-development.md             # Custom plugin creation guide
│   └── migration-guide.md                # CKEditor 4 to 5 migration
└── scripts/
    └── verify-ckeditor5.sh               # Verification script
```

## Expertise Areas

### CKEditor 5 Architecture
- Plugin system and architecture
- Schema and conversion system
- Command pattern implementation
- UI component development

### TYPO3 Integration
- RTE configuration (YAML)
- Custom plugin registration
- Content element integration
- Backend module integration

### Migration Patterns
- CKEditor 4 to 5 migration
- Custom plugin conversion
- Configuration transformation
- Data migration strategies

## Related Skills

- **typo3-extension-upgrade-skill**: References this skill for RTE migration
- **php-modernization-skill**: Modern PHP patterns for backend integration

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

Developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/).

---

**Made with ❤️ for Open Source by [Netresearch](https://www.netresearch.de/)**
