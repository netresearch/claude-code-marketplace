# TYPO3 v12 to v13 Upgrade Guide

## Version Constraints

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

## Rector Configuration

```php
$rectorConfig->sets([
    LevelSetList::UP_TO_PHP_82,
    Typo3LevelSetList::UP_TO_TYPO3_13,
    Typo3SetList::CODE_QUALITY,
    Typo3SetList::GENERAL,
]);
```

## Key Breaking Changes

| Change | v12 API | v13 API |
|--------|---------|---------|
| Frontend user | `$TSFE->fe_user` | `$request->getAttribute('frontend.user')` |
| Page info | `$data['pObj']->rootLine` | `$request->getAttribute('frontend.page.information')` |

See also: `api-changes.md` for detailed patterns.
