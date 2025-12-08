# Real-World Upgrade Patterns

> **Source**: netresearch/contexts extension upgrade from v11 to v12/v13 (2024-12)

## Deprecation Patterns Discovered

### 1. Container::registerImplementation() Removed

**v11 Pattern** (ext_localconf.php):
```php
\TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance(
    \TYPO3\CMS\Extbase\Object\Container\Container::class
)->registerImplementation(
    \Netresearch\Contexts\Context\AbstractContext::class,
    \Netresearch\Contexts\Context\IpContext::class
);
```

**v12+ Fix**: Remove entirely. Use `Services.yaml` for DI:
```yaml
services:
  Netresearch\Contexts\Context\IpContext:
    public: true
```

### 2. GeneralUtility::_GET() Deprecated

**Search Pattern**:
```bash
grep -rn "GeneralUtility::_GET\|GeneralUtility::_POST\|GeneralUtility::_GP" Classes/
```

**v11 Pattern**:
```php
$value = GeneralUtility::_GET('tx_myext');
```

**v12+ Fix**:
```php
// Option 1: Direct superglobal (for simple cases)
$value = $_GET['tx_myext'] ?? null;

// Option 2: From PSR-7 request (preferred)
$value = $request->getQueryParams()['tx_myext'] ?? null;
```

### 3. $TSFE Global Undefined

**Search Pattern**:
```bash
grep -rn "\$GLOBALS\['TSFE'\]" Classes/
```

**v11 Pattern**:
```php
$pageId = $GLOBALS['TSFE']->id;
```

**v12 Compatible Fix**:
```php
$tsfe = $GLOBALS['TSFE'] ?? null;
$pageId = $tsfe?->id ?? 0;
```

**v13 Preferred** (with request):
```php
$pageInfo = $request->getAttribute('frontend.page.information');
$pageId = $pageInfo?->getId() ?? 0;
```

### 4. Doctrine DBAL 4.x createNamedParameter

**Search Pattern**:
```bash
grep -rn "createNamedParameter" Classes/
```

**v11 (DBAL 3.x)**:
```php
$queryBuilder->createNamedParameter($value, \PDO::PARAM_INT);
```

**v12+ (DBAL 4.x)**:
```php
use Doctrine\DBAL\Connection;

$queryBuilder->createNamedParameter($value, Connection::PARAM_INT);
```

**Available Constants**:
| PDO Constant | DBAL Constant |
|--------------|---------------|
| `PDO::PARAM_INT` | `Connection::PARAM_INT` |
| `PDO::PARAM_STR` | `Connection::PARAM_STR` |
| `PDO::PARAM_BOOL` | `Connection::PARAM_BOOL` |
| `PDO::PARAM_NULL` | `Connection::PARAM_NULL` |

### 5. itemFormElID Removed in FormEngine

**Search Pattern**:
```bash
grep -rn "itemFormElID" Classes/
```

**v11 Pattern**:
```php
$elementId = $data['parameterArray']['itemFormElID'];
```

**v12+ Fix** (generate from itemFormElName):
```php
$elementName = $data['parameterArray']['itemFormElName'];
$elementId = str_replace(['[', ']'], ['_', ''], $elementName);
```

### 6. xml2array() Null Argument

**Issue**: `GeneralUtility::xml2array()` doesn't accept null

**v11 Pattern**:
```php
$config = GeneralUtility::xml2array($row['config']);
```

**v12+ Fix**:
```php
$config = !empty($row['config'])
    ? GeneralUtility::xml2array((string) $row['config'])
    : [];
```

## SC_OPTIONS Hooks to PSR-14 Events

### Common Hook Migrations

| SC_OPTIONS Hook | PSR-14 Event |
|----------------|--------------|
| `$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['t3lib/class.t3lib_tcemain.php']['processDatamapClass']` | `AfterRecordOperationEvent` |
| `$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['tslib/class.tslib_fe.php']['determineId-PostProc']` | `AfterTypoScriptDeterminedEvent` |
| `$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['tslib/class.tslib_content.php']['getData']` | Custom middleware or PSR-14 event |

### Migration Pattern

**v11 Hook** (ext_localconf.php):
```php
$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['t3lib/class.t3lib_tcemain.php']['processDatamapClass'][]
    = \Vendor\Extension\Hooks\DataHandler::class;
```

**v12+ PSR-14 Event** (Services.yaml):
```yaml
services:
  Vendor\Extension\EventListener\DataHandlerListener:
    tags:
      - name: event.listener
        event: TYPO3\CMS\Core\DataHandling\Event\AfterRecordOperationEvent
```

## Fractor Migrations Applied

Successfully migrated non-PHP files:

| File Type | Migration |
|-----------|-----------|
| FlexForms XML | Structure updates for v12 |
| TypoScript | `[end]` → `[global]` |
| Fluid Templates | Namespace updates |

**Command**:
```bash
./vendor/bin/fractor process --dry-run  # Preview
./vendor/bin/fractor process            # Apply
```

## Site Sets for TYPO3 13

New configuration structure:

```
Configuration/
├── Sets/
│   └── MyExtension/
│       ├── config.yaml
│       ├── settings.yaml
│       └── setup.typoscript
```

**config.yaml**:
```yaml
name: vendor/my-extension
label: My Extension
dependencies:
  - typo3/fluid-styled-content
```

## CI Matrix Pattern for Dual v12/v13 Support

```yaml
# .github/workflows/ci.yml
jobs:
  test:
    strategy:
      matrix:
        typo3: ['12.4', '13.4']
        php: ['8.2', '8.3', '8.4']
        exclude:
          - typo3: '12.4'
            php: '8.4'  # v12 max PHP 8.3
```
