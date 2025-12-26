# TYPO3 v11 to v12 Upgrade Guide

## Version Constraints

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

## Rector Configuration

```php
$rectorConfig->sets([
    LevelSetList::UP_TO_PHP_81,
    Typo3LevelSetList::UP_TO_TYPO3_12,
    Typo3SetList::CODE_QUALITY,
    Typo3SetList::GENERAL,
]);
```

## Key Breaking Changes

| Change | Search | Fix |
|--------|--------|-----|
| Doctrine DBAL 4.x | `grep -rn "PDO::PARAM_"` | Use `Connection::PARAM_*` |
| GeneralUtility::_GET/POST | `grep -rn "GeneralUtility::_GET"` | Use `$_GET['param'] ?? null` |
| TCA required flag | `grep -rn "'eval'.*'required'"` | Use `'required' => true` |
| itemFormElID removed | `grep -rn "itemFormElID"` | Generate from `itemFormElName` |
| FlexForm structure | Run Fractor | Fractor auto-fixes |
| TypoScript [end] | Run Fractor | Changed to `[global]` |

## Composer Dependencies

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

See also: `api-changes.md` for detailed patterns.
