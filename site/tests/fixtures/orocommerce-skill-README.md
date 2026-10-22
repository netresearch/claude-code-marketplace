<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# OroCommerce Skills for Claude Code

A Claude Code plugin providing 14 domain-specific skills for OroCommerce v6.1 development. Each skill delivers accurate, version-pinned guidance for common development tasks — from entity creation and datagrid configuration to API design, workflow setup, and security hardening. Built for Oro-experienced developers who need correctness and awareness of non-obvious pitfalls rather than introductory tutorials.

## Skills

| Skill | Description |
|-------|-------------|
| **oro-api** | REST API configuration via `api.yml` / `api_frontend.yml`, processors, and resource policies |
| **oro-behat-ci** | Behat in CI/CD pipelines — compose fanout, headless Chrome, consumer parallelization, artifacts |
| **oro-behat-debugging** | Debugging failing or flaky Behat scenarios — AJAX races, isolation, screenshots, log forensics |
| **oro-behat-testing** | Writing and configuring Behat tests — suites, contexts, elements, Alice fixtures |
| **oro-bundle** | Bundle scaffolding, dependency injection, service configuration, navigation, and system config |
| **oro-datagrid** | Datagrid YAML configuration — columns, filters, sorters, properties, and mass actions |
| **oro-e2e-testing** | Behat against deployed environments — skip-isolators, secrets handling, remote ChromeDriver, healers |
| **oro-entity** | Entity creation with ownership, `ExtendEntityInterface`, field config, and migrations |
| **oro-frontend** | Theme setup, SCSS, Twig layout updates, and Chaplin.js view integration |
| **oro-functional-testing** | PHPUnit functional tests — WebTestCase, fixtures, dbIsolation, API/datagrid/command testing |
| **oro-integration** | Message queue consumers, import/export, integration connectors, and cron jobs |
| **oro-k6-testing** | k6 performance and load testing — storefront benchmarks, checkout scenarios, cache warm-up |
| **oro-security** | ACL annotations, permission configuration, access rules, and field-level ACL |
| **oro-workflow** | Workflow definitions, transitions, transition actions, and checkout customization |

## Installation

### Claude Code Marketplace

```bash
/plugin marketplace add netresearch/claude-code-marketplace
/plugin install orocommerce@netresearch-claude-code-marketplace
```

### Manual Installation

Clone this repository into your Claude Code plugins directory:

```bash
git clone https://github.com/netresearch/orocommerce-skill.git ~/.claude/plugins/orocommerce-skills
```

### Composer (for OroCommerce projects)

The package is not published on Packagist, so add this repository as a VCS repository first. The skills are registered by the `netresearch/composer-agent-skill-plugin` Composer plugin, which must be allowed and asked to trust the package:

```bash
composer config repositories.orocommerce-skill vcs https://github.com/netresearch/orocommerce-skill
composer config allow-plugins.netresearch/composer-agent-skill-plugin true
composer require netresearch/orocommerce-skill
composer skills:trust netresearch/orocommerce-skill
```

## Related resources

- [oroinc/ai-upgrade](https://github.com/oroinc/ai-upgrade) — Oro's own Claude Code upgrade kit (package + project upgrade pipelines, 6.1 → 7.0 BC corpus). Complements these domain skills for major-version upgrade work; the Netresearch bundle-upgrade workflow lives in the internal `oro-bundle-upgrade-skill`.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI

## License

This project uses a split license:

- **Code** (plugin metadata, tooling): [MIT](LICENSE-MIT)
- **Skill content** (SKILL.md files, reference docs): [CC BY-SA 4.0](LICENSE-CC-BY-SA-4.0)

## Contributing

Contributions are welcome. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Author

[Netresearch DTT GmbH](https://www.netresearch.de)

