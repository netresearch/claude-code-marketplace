---
name: typo3-extension-upgrade
description: "Agent Skill: Systematic TYPO3 extension upgrades to newer LTS versions with modern PHP compatibility. Covers Extension Scanner assessment, Rector for PHP migrations, Fractor for non-PHP file migrations, PHPStan for static analysis, and testing setup. This skill should be used when upgrading extension code to support newer TYPO3 versions, fixing extension compatibility issues, or modernizing TYPO3 extensions. Developed by Netresearch DTT GmbH."
---

# TYPO3 Extension Upgrade

Systematic framework for upgrading TYPO3 extensions to newer LTS versions.

> **Scope**: This skill is for extension developers upgrading extension code. It does NOT cover upgrading TYPO3 project installations or core.

---

## Part 1: Generic Upgrade Framework

This section applies to ANY TYPO3 extension upgrade regardless of target version.

### Upgrade Toolkit

| Tool | Type | Purpose | Files |
|------|------|---------|-------|
| **Extension Scanner** | TYPO3 Backend | Diagnose deprecated/removed APIs | `.php` |
| **Rector** | CLI | Automated PHP migrations | `.php` |
| **Fractor** | CLI | Automated non-PHP migrations | FlexForms, TypoScript, YAML, Fluid |
| **PHPStan** | CLI | Static analysis | `.php` |
| **PHP-CS-Fixer** | CLI | Code style | `.php` |
| **PHPUnit** | CLI | Testing | Test execution |

### Tool Function Comparison

| Tool | Function | Requires TYPO3 |
|------|----------|----------------|
| **Extension Scanner** | **Diagnoses** issues (read-only) | Yes (backend module) |
| **Rector** | **Fixes** PHP code automatically | No (standalone CLI) |
| **Fractor** | **Fixes** non-PHP files automatically | No (standalone CLI) |

### Pre-Upgrade Checklist

Before starting any upgrade:

- [ ] Git repository is clean
- [ ] Feature branch created for upgrade work
- [ ] Current TYPO3/PHP version support documented
- [ ] Extension has tests (unit/functional)
- [ ] CI/CD pipeline green on current version

For detailed checklist, see `references/pre-upgrade.md`.

### Extension Scanner (Optional Assessment)

The Extension Scanner is a built-in TYPO3 backend tool for diagnosing deprecated/removed Core API usage.

**Location**: TYPO3 Backend → Admin Tools → Upgrade → Scan Extension Files

**Usage**:
1. Install extension in target TYPO3 version environment
2. Navigate to Admin Tools → Upgrade → Scan Extension Files
3. Select extension and click Scan Extension
4. Review: Strong matches = likely issues, Weak matches = verify manually

**Reference**: [Extension Scanner Documentation](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ExtensionArchitecture/HowTo/UpdateExtensions/ExtensionScanner.html)

### Generic Upgrade Workflow

```
1. Create feature branch
2. (Optional) Run Extension Scanner for initial assessment
3. Update composer.json constraints
4. Install/update dependencies
5. Configure upgrade tools (rector.php, fractor.php, phpstan.neon)
6. Run Rector --dry-run → review → apply
7. Run Fractor --dry-run → review → apply
8. Run php-cs-fixer
9. Run phpstan → fix errors
10. Run phpunit → fix tests
11. (Optional) Run Extension Scanner for verification
12. Test in target TYPO3 versions
13. Commit and push
```

### Tool Installation (Generic)

```json
{
    "require-dev": {
        "a9f/typo3-fractor": "^0.4",
        "friendsofphp/php-cs-fixer": "^3.64",
        "phpstan/phpstan": "^2.0",
        "phpstan/phpstan-deprecation-rules": "^2.0",
        "phpstan/phpstan-phpunit": "^2.0",
        "phpunit/phpunit": "^11.0",
        "rector/rector": "^2.0",
        "ssch/typo3-rector": "^3.0",
        "typo3/testing-framework": "^9.0"
    }
}
```

### Configuration Templates

Copy from `assets/` directory and adjust for target version:

- `assets/rector.php` - Rector configuration
- `assets/fractor.php` - Fractor configuration
- `assets/phpstan.neon` - PHPStan configuration
- `assets/phpunit.xml` - PHPUnit configuration
- `assets/.php-cs-fixer.php` - PHP-CS-Fixer configuration

### Quick Reference Commands

```bash
# === MIGRATION TOOLS ===
./vendor/bin/rector process --dry-run    # Preview PHP changes
./vendor/bin/rector process              # Apply PHP changes
./vendor/bin/fractor process --dry-run   # Preview non-PHP changes
./vendor/bin/fractor process             # Apply non-PHP changes

# === QUALITY TOOLS ===
./vendor/bin/php-cs-fixer fix --dry-run --diff
./vendor/bin/php-cs-fixer fix
./vendor/bin/phpstan analyse
./vendor/bin/phpunit

# === FULL UPGRADE SEQUENCE ===
./vendor/bin/rector process && \
./vendor/bin/fractor process && \
./vendor/bin/php-cs-fixer fix && \
./vendor/bin/phpstan analyse && \
./vendor/bin/phpunit
```

### Success Criteria (Generic)

- [ ] `rector process --dry-run` shows no changes
- [ ] `fractor process --dry-run` shows no changes
- [ ] `php-cs-fixer fix --dry-run` shows no changes
- [ ] `phpstan analyse` passes
- [ ] All tests pass
- [ ] Extension installs in target TYPO3 version(s)
- [ ] Backend functionality works
- [ ] Frontend functionality works
- [ ] No PHP deprecation warnings in logs

---

## Part 2: Version-Specific Guides

### TYPO3 v11 to v12 Upgrade

#### Version Constraints

```json
{
    "require": {
        "php": "^8.1",
        "typo3/cms-core": "^12.4"
    }
}
```

```php
// ext_emconf.php
'constraints' => [
    'depends' => [
        'typo3' => '12.4.0-12.4.99',
        'php' => '8.1.0-8.4.99',
    ],
],
```

#### Rector Configuration

```php
$rectorConfig->sets([
    LevelSetList::UP_TO_PHP_81,
    Typo3LevelSetList::UP_TO_TYPO3_12,
    Typo3SetList::CODE_QUALITY,
    Typo3SetList::GENERAL,
]);
```

#### Key Breaking Changes

| Change | Search | Fix |
|--------|--------|-----|
| Doctrine DBAL 4.x | `grep -rn "PDO::PARAM_"` | Use `Connection::PARAM_*` |
| GeneralUtility::_GET/POST | `grep -rn "GeneralUtility::_GET"` | Use `$_GET['param'] ?? null` |
| TCA required flag | `grep -rn "'eval'.*'required'"` | Use `'required' => true` |
| itemFormElID removed | `grep -rn "itemFormElID"` | Generate from `itemFormElName` |
| FlexForm structure | Run Fractor | Fractor auto-fixes |
| TypoScript [end] | Run Fractor | Changed to `[global]` |

See `references/api-changes.md` for detailed patterns.

---

### TYPO3 v12 to v13 Upgrade

#### Version Constraints

```json
{
    "require": {
        "php": "^8.2",
        "typo3/cms-core": "^13.4"
    }
}
```

```php
// ext_emconf.php
'constraints' => [
    'depends' => [
        'typo3' => '13.4.0-13.4.99',
        'php' => '8.2.0-8.4.99',
    ],
],
```

#### Rector Configuration

```php
$rectorConfig->sets([
    LevelSetList::UP_TO_PHP_82,
    Typo3LevelSetList::UP_TO_TYPO3_13,
    Typo3SetList::CODE_QUALITY,
    Typo3SetList::GENERAL,
]);
```

#### Key Breaking Changes

| Change | v12 API | v13 API |
|--------|---------|---------|
| Frontend user | `$TSFE->fe_user` | `$request->getAttribute('frontend.user')` |
| Page info | `$data['pObj']->rootLine` | `$request->getAttribute('frontend.page.information')` |

---

### TYPO3 v12 + v13 Dual Compatibility

When extension must support BOTH `^12.4 || ^13.4`:

#### Version Constraints

```json
{
    "require": {
        "php": "^8.2",
        "typo3/cms-core": "^12.4 || ^13.4"
    }
}
```

```php
// ext_emconf.php
'constraints' => [
    'depends' => [
        'typo3' => '12.4.0-13.4.99',
        'php' => '8.2.0-8.4.99',
    ],
],
```

#### Critical: Rector Configuration

**Do NOT use `UP_TO_TYPO3_13`** - it introduces v13-only APIs that break v12.

```php
$rectorConfig->sets([
    LevelSetList::UP_TO_PHP_82,
    // ONLY v12 rules for dual compatibility
    Typo3LevelSetList::UP_TO_TYPO3_12,
    Typo3SetList::CODE_QUALITY,
    Typo3SetList::GENERAL,
]);
```

#### API Compatibility Matrix

| Purpose | v12 Compatible (use this) | v13 Only (avoid) |
|---------|---------------------------|------------------|
| Session access | `$TSFE->fe_user->getKey()` | `$request->getAttribute('frontend.user')` |
| Page info | `$data['pObj']->rootLine` | `$request->getAttribute('frontend.page.information')` |

**Rule**: Always use v12-compatible APIs when supporting both versions.

---

## Part 3: Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| `PDO::PARAM_INT` type error | Doctrine DBAL 4.x (v12+) | Use `Connection::PARAM_INT` |
| `itemFormElID` undefined | Removed in v12 | Generate from `itemFormElName` |
| `xml2array()` null argument | Null column value | Use `!empty()` + `(string)` cast |
| `$TSFE` undefined | Not always set | Use `$GLOBALS['TSFE'] ?? null` |
| `GeneralUtility::_GET()` deprecated | Deprecated in v12 | Use `$_GET[$param] ?? null` |
| Rector v13 breaks v12 | v13-only APIs | Only use `UP_TO_TYPO3_12` for dual compat |
| FlexForm structure errors | Changed in v12 | Run Fractor |

---

## Part 4: Future Version Upgrades

When upgrading to future TYPO3 versions:

1. **Check TYPO3 Changelog** (see links below)
2. **Update typo3-rector**: `composer update ssch/typo3-rector`
3. **Update typo3-fractor**: `composer update a9f/typo3-fractor`
4. **Adjust Rector sets**: Add new `Typo3LevelSetList::UP_TO_TYPO3_XX`
5. **Run Extension Scanner** in new version
6. **Follow generic workflow** from Part 1

The tools and workflow remain the same - only version-specific rules change.

---

## Part 5: Official TYPO3 Changelogs

Complete documentation of breaking changes, deprecations, and features for each version.

### Changelog by Version

| Version | Changelog | Breaking Changes Summary |
|---------|-----------|-------------------------|
| **v14** | [Changelog-14](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-14.html) / [Combined](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-14-combined.html) | (In development) |
| **v13** | [Changelog-13](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-13.html) / [Combined](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-13-combined.html) | Request attributes, PSR-14 events |
| **v12** | [Changelog-12](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-12.html) / [Combined](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-12-combined.html) | Doctrine DBAL 3→4, Symfony 6, CKEditor 5 |
| **v11** | [Changelog-11](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-11.html) / [Combined](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-11-combined.html) | Fluid standalone, Backend API changes |
| **v10** | [Changelog-10](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-10.html) / [Combined](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-10-combined.html) | Symfony 5, Site configuration |
| **v9** | [Changelog-9](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-9.html) / [Combined](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-9-combined.html) | Site handling, Routing, PSR-15 middleware |
| **v8** | [Changelog-8](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-8.html) / [Combined](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-8-combined.html) | Doctrine DBAL introduction, FAL changes |
| **v7** | [Changelog-7](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-7.html) / [Combined](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-7-combined.html) | FormEngine rewrite, Backend restructure |

### Changelog Types Explained

Each changelog contains four categories:

| Type | Meaning |
|------|---------|
| **Breaking** | Changes that break existing functionality - handle before upgrading |
| **Deprecation** | Functionality marked for removal in next major version - fix proactively |
| **Feature** | New functionality added |
| **Important** | Significant behavioral or configuration changes |

### Reading Strategy

1. **Before upgrade**: Review Breaking Changes for target version
2. **Proactive maintenance**: Review Deprecations in current version
3. **After upgrade**: Review Features for new capabilities

### Additional Resources

- [Pre-upgrade Tasks](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Administration/Upgrade/Major/PreupgradeTasks/Index.html)
- [Extension Scanner Documentation](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ExtensionArchitecture/HowTo/UpdateExtensions/ExtensionScanner.html)
- [TYPO3 Rector GitHub](https://github.com/sabbelasichon/typo3-rector)
- [TYPO3 Fractor GitHub](https://github.com/andreaswolf/fractor)

---

## Part 6: Real-World Patterns

For detailed deprecation patterns and fixes discovered from actual extension upgrades:

See `references/real-world-patterns.md` - includes:
- Container::registerImplementation() removal
- GeneralUtility::_GET() deprecation fixes
- $TSFE global undefined handling
- Doctrine DBAL 4.x migrations
- SC_OPTIONS hooks to PSR-14 events
- Fractor migrations applied
- Site Sets for TYPO3 13
