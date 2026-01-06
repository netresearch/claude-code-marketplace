# Dual Version (v12 + v13) Compatibility Patterns

> **Source**: netresearch/contexts extension conformance for TYPO3 12.4 + 13.4 LTS (2024-12)

## Version Constraint Strategy

### composer.json
```json
{
    "require": {
        "php": "^8.2",
        "typo3/cms-core": "^12.4 || ^13.4"
    }
}
```

### ext_emconf.php
```php
'constraints' => [
    'depends' => [
        'typo3' => '12.4.0-13.4.99',
        'php' => '8.2.0-8.4.99',
    ],
],
```

## Critical Rector Configuration

**DO NOT** use `UP_TO_TYPO3_13` when supporting both versions:

```php
// rector.php - CORRECT for dual v12+v13
$rectorConfig->sets([
    LevelSetList::UP_TO_PHP_82,
    Typo3LevelSetList::UP_TO_TYPO3_12,  // NOT UP_TO_TYPO3_13!
    Typo3SetList::CODE_QUALITY,
    Typo3SetList::GENERAL,
]);
```

**Reason**: `UP_TO_TYPO3_13` introduces v13-only APIs that break v12 compatibility.

## API Compatibility Decision Matrix

| Purpose | Use This (v12 Compatible) | Avoid (v13 Only) |
|---------|---------------------------|------------------|
| Frontend user session | `$TSFE->fe_user->getKey()` | `$request->getAttribute('frontend.user')` |
| Page information | `$data['pObj']->rootLine` | `$request->getAttribute('frontend.page.information')` |
| Language | `$TSFE->sys_language_uid` | `$request->getAttribute('language')` |
| Site | `$TSFE->getSite()` | Works in both |

## Compatibility Layer Pattern

When you need different behavior for v12 vs v13:

```php
use TYPO3\CMS\Core\Information\Typo3Version;

class CompatibilityHelper
{
    public static function isTypo3v13OrHigher(): bool
    {
        return (new Typo3Version())->getMajorVersion() >= 13;
    }

    public static function getPageId(ServerRequestInterface $request): int
    {
        if (self::isTypo3v13OrHigher()) {
            $pageInfo = $request->getAttribute('frontend.page.information');
            return $pageInfo?->getId() ?? 0;
        }

        // v12 fallback
        $tsfe = $GLOBALS['TSFE'] ?? null;
        return $tsfe?->id ?? 0;
    }
}
```

## Testing Matrix Requirements

For enterprise-grade dual-version support:

| Test Type | Coverage Target |
|-----------|-----------------|
| Unit Tests | 70%+ |
| Functional Tests | Key integrations |
| E2E Tests | Critical user journeys |

### CI Matrix
```yaml
matrix:
  include:
    - php: '8.2'
      typo3: '^12.4'
    - php: '8.3'
      typo3: '^12.4'
    - php: '8.2'
      typo3: '^13.4'
    - php: '8.3'
      typo3: '^13.4'
    - php: '8.4'
      typo3: '^13.4'
```

## Conformance Scoring Adjustments

### Base Score Modifications
When evaluating dual-version extensions:

| Criterion | Single Version | Dual Version |
|-----------|---------------|--------------|
| Uses v12 APIs only | Full points | Full points |
| Uses v13-only APIs | Full points | -10 points |
| Has version detection | +0 | +5 bonus |
| CI tests both versions | N/A | Required |

### Excellence Indicators
Additional excellence points for dual-version:

| Indicator | Points |
|-----------|--------|
| Matrix CI (both versions) | +3 |
| Compatibility layer documented | +2 |
| Version-specific documentation | +2 |

## Documentation Requirements

Dual-version extensions must document:

1. **Supported versions** prominently in README
2. **Installation differences** (if any)
3. **Feature parity** (any v13-only features)
4. **Migration path** from single to dual version

### Example README Section
```markdown
## Compatibility

| TYPO3 | PHP | Status |
|-------|-----|--------|
| 13.4 LTS | 8.2 - 8.4 | Supported |
| 12.4 LTS | 8.2 - 8.3 | Supported |
| 11.5 LTS | 7.4 - 8.1 | Use v3.x |
```

## Checklist for Dual-Version Extensions

- [ ] `composer.json` has `^12.4 || ^13.4` constraint
- [ ] `ext_emconf.php` has `12.4.0-13.4.99` constraint
- [ ] Rector uses `UP_TO_TYPO3_12` only
- [ ] No v13-only request attributes used directly
- [ ] CI matrix tests both versions
- [ ] All tests pass on both versions
- [ ] Documentation states supported versions
- [ ] PHP minimum is 8.2 (required for v13)
