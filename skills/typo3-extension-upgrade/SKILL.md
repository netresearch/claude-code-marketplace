---
name: typo3-extension-upgrade
description: "Agent Skill: Systematic TYPO3 extension upgrades to newer LTS versions. Covers Extension Scanner, Rector, Fractor, PHPStan, and testing. Use when upgrading extensions to newer TYPO3 versions or fixing compatibility issues. By Netresearch."
---

# TYPO3 Extension Upgrade

Systematic framework for upgrading TYPO3 extensions to newer LTS versions.

> **Scope**: Extension code upgrades only. NOT for TYPO3 project/core upgrades.

## Upgrade Toolkit

| Tool | Purpose | Files |
|------|---------|-------|
| Extension Scanner | Diagnose deprecated APIs | TYPO3 Backend |
| Rector | Automated PHP migrations | `.php` |
| Fractor | Non-PHP migrations | FlexForms, TypoScript, YAML, Fluid |
| PHPStan | Static analysis | `.php` |

## Generic Upgrade Workflow

1. Create feature branch (verify git clean)
2. Update `composer.json` constraints for target version
3. Run `rector process --dry-run` → review → apply
4. Run `fractor process --dry-run` → review → apply
5. Run `php-cs-fixer fix`
6. Run `phpstan analyse` → fix errors
7. Run `phpunit` → fix tests
8. Test in target TYPO3 version(s)

## Quick Commands

```bash
./vendor/bin/rector process --dry-run && ./vendor/bin/rector process
./vendor/bin/fractor process --dry-run && ./vendor/bin/fractor process
./vendor/bin/php-cs-fixer fix && ./vendor/bin/phpstan analyse && ./vendor/bin/phpunit
```

## Configuration Templates

Copy from `assets/` and adjust for target version:
- `rector.php`, `fractor.php`, `phpstan.neon`, `phpunit.xml`, `.php-cs-fixer.php`

## Version-Specific Guides

- `references/upgrade-v11-to-v12.md` - TYPO3 v11→v12 specifics
- `references/upgrade-v12-to-v13.md` - TYPO3 v12→v13 specifics
- `references/dual-compatibility.md` - Supporting ^12.4 || ^13.4
- `references/api-changes.md` - Detailed deprecation patterns
- `references/real-world-patterns.md` - Fixes from actual upgrades

## Success Criteria

- `rector/fractor --dry-run` show no changes
- `phpstan analyse` passes
- All tests pass
- Extension works in target TYPO3 version

## TYPO3 Changelogs

| Version | Changelog |
|---------|-----------|
| v14 | [Changelog-14](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-14.html) |
| v13 | [Changelog-13](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-13.html) |
| v12 | [Changelog-12](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-12.html) |

---

> **Contributing:** https://github.com/netresearch/typo3-extension-upgrade-skill
