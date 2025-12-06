# API Changes Reference

Search patterns, replacements, and key breaking changes organized by TYPO3 version upgrade path.

---

## v7 → v8 Upgrade

### Database Layer: TYPO3_DB → Doctrine DBAL

**Search Pattern**
```bash
grep -rn "\$GLOBALS\['TYPO3_DB'\]\|exec_SELECTquery\|exec_INSERTquery\|exec_UPDATEquery\|exec_DELETEquery" Classes/
```

**Replace**

| Before (v7) | After (v8+) |
|-------------|-------------|
| `$GLOBALS['TYPO3_DB']->exec_SELECTquery()` | Use `QueryBuilder` |
| `$GLOBALS['TYPO3_DB']->exec_INSERTquery()` | `$queryBuilder->insert()` |
| `$GLOBALS['TYPO3_DB']->exec_UPDATEquery()` | `$queryBuilder->update()` |
| `$GLOBALS['TYPO3_DB']->exec_DELETEquery()` | `$queryBuilder->delete()` |
| `$GLOBALS['TYPO3_DB']->fullQuoteStr()` | `$queryBuilder->createNamedParameter()` |

**Example Migration**
```php
// Before (v7)
$rows = $GLOBALS['TYPO3_DB']->exec_SELECTgetRows('*', 'tt_content', 'pid=' . $pid);

// After (v8+)
$queryBuilder = GeneralUtility::makeInstance(ConnectionPool::class)->getQueryBuilderForTable('tt_content');
$rows = $queryBuilder
    ->select('*')
    ->from('tt_content')
    ->where($queryBuilder->expr()->eq('pid', $queryBuilder->createNamedParameter($pid, Connection::PARAM_INT)))
    ->executeQuery()
    ->fetchAllAssociative();
```

### ExtJS/Prototype Removal

**Search Pattern**
```bash
grep -rn "Ext\.onReady\|new Ext\.\|Prototype\.\|Element\.extend" Resources/
```

**Fix**: Replace with vanilla JavaScript or jQuery.

### Icon Factory

**Search Pattern**
```bash
grep -rn "IconUtility::\|t3skin\|t3lib_iconWorks" Classes/
```

**Replace**

| Before | After |
|--------|-------|
| `IconUtility::getSpriteIcon()` | `IconFactory->getIcon()` |
| `IconUtility::getSpriteIconForRecord()` | `IconFactory->getIconForRecord()` |

---

## v8 → v9 Upgrade

### Site Configuration Introduction

**Search Pattern**
```bash
grep -rn "sys_domain\|config\.baseURL\|absRefPrefix\s*=\s*auto" Configuration/
```

**Fix**: Migrate to Site Configuration (`config/sites/*/config.yaml`).

### PSR-15 Middleware

**Search Pattern**
```bash
grep -rn "AbstractUserAuthentication\|tslib_fe\|tslib_cObj" Classes/
```

**Replace**

| Before | After |
|--------|-------|
| `tslib_fe` | `TypoScriptFrontendController` |
| `tslib_cObj` | `ContentObjectRenderer` |
| Hook-based request handling | PSR-15 middleware |

### Routing API

**Search Pattern**
```bash
grep -rn "tx_realurl\|cooluri\|simulatestatic" Configuration/
```

**Fix**: Migrate to native TYPO3 Routing with Site Configuration.

### Signal/Slot Deprecation Start

**Search Pattern**
```bash
grep -rn "SignalSlotDispatcher\|->connect\(" Classes/
```

**Note**: Mark for migration to PSR-14 Events (complete in v10).

---

## v9 → v10 Upgrade

### Symfony 5 Upgrade

**Search Pattern**
```bash
grep -rn "Symfony\\\\Component\\\\Console\\\\Command\|setDescription\|setHelp" Classes/Command/
```

**Replace**: Update command registration to use `Services.yaml`.

### Dependency Injection

**Search Pattern**
```bash
grep -rn "GeneralUtility::makeInstance\|ObjectManager::get" Classes/
```

**Replace**: Use constructor injection with `Services.yaml`.

```php
// Before
$service = GeneralUtility::makeInstance(MyService::class);

// After (Services.yaml)
services:
  Vendor\Extension\Service\MyService:
    public: true
```

### PSR-14 Events

**Search Pattern**
```bash
grep -rn "SignalSlotDispatcher\|->emit\|->connect\(" Classes/
```

**Replace**

| Before | After |
|--------|-------|
| Signal/Slot `connect()` | Event Listener via `Services.yaml` |
| Signal/Slot `dispatch()` | `EventDispatcher->dispatch(new Event())` |

### Fluid Namespace

**Search Pattern**
```bash
grep -rn "{namespace\|xmlns:f=" Resources/Private/
```

**Replace**: Use XML namespace declarations.
```html
<!-- Before -->
{namespace v=Vendor\Extension\ViewHelpers}

<!-- After -->
<html xmlns:f="http://typo3.org/ns/TYPO3/CMS/Fluid/ViewHelpers"
      xmlns:v="http://typo3.org/ns/Vendor/Extension/ViewHelpers"
      data-namespace-typo3-fluid="true">
```

---

## v10 → v11 Upgrade

### Fluid Standalone

**Search Pattern**
```bash
grep -rn "TYPO3Fluid\|StandaloneView\|setTemplatePathAndFilename" Classes/
```

**Replace**
```php
// Before
$view->setTemplatePathAndFilename($templatePath);

// After
$view->setTemplate($templatePath);
$view->setTemplateRootPaths([$rootPath]);
```

### Backend Controller Changes

**Search Pattern**
```bash
grep -rn "extends ActionController\|AbstractModule" Classes/Controller/
```

**Note**: Backend modules must return `ResponseInterface`.

```php
// Before
public function indexAction() {
    $this->view->assign('data', $data);
}

// After
public function indexAction(): ResponseInterface {
    $this->view->assign('data', $data);
    return $this->htmlResponse();
}
```

### TCA Wizard Changes

**Search Pattern**
```bash
grep -rn "'wizards'\s*=>\|'wizard_'" Configuration/TCA/
```

**Replace**: Use `fieldControl`, `fieldInformation`, `fieldWizard`.

---

## v11 → v12 Upgrade

### Doctrine DBAL 4.x (Critical)

**Search Pattern**
```bash
grep -rn "PDO::PARAM_" Classes/
```

**Replace**

| Before | After |
|--------|-------|
| `PDO::PARAM_INT` | `Connection::PARAM_INT` |
| `PDO::PARAM_STR` | `Connection::PARAM_STR` |
| `PDO::PARAM_BOOL` | `Connection::PARAM_BOOL` |
| `PDO::PARAM_NULL` | `Connection::PARAM_NULL` |

**Required Import**
```php
use TYPO3\CMS\Core\Database\Connection;
```

### GeneralUtility Deprecated Methods

**Search Pattern**
```bash
grep -rn "GeneralUtility::_GET\|GeneralUtility::_POST\|GeneralUtility::_GP" Classes/
```

**Replace**

| Before | After |
|--------|-------|
| `GeneralUtility::_GET('param')` | `$_GET['param'] ?? null` |
| `GeneralUtility::_POST('param')` | `$_POST['param'] ?? null` |
| `GeneralUtility::_GP('param')` | `$_GET['param'] ?? $_POST['param'] ?? null` |

**For Controllers/Middleware (PSR-7)**
```php
// GET parameters
$value = $request->getQueryParams()['param'] ?? null;

// POST parameters
$value = $request->getParsedBody()['param'] ?? null;
```

### TCA Required Field

**Search Pattern**
```bash
grep -rn "'eval'.*'required'" Configuration/TCA/
```

**Replace**
```php
// Before
'config' => [
    'type' => 'input',
    'eval' => 'required,trim',
],

// After
'config' => [
    'type' => 'input',
    'required' => true,
    'eval' => 'trim',
],
```

### Form Element Data Structure

**Search Pattern**
```bash
grep -rn "itemFormElID" Classes/
```

**Fix Pattern**
```php
// Before (removed in v12)
$id = $this->data['parameterArray']['itemFormElID'];

// After
$baseId = str_replace(['[', ']'], '_', $this->data['parameterArray']['itemFormElName']);
$baseId = trim($baseId, '_');
```

### xml2array Null Handling

**Search Pattern**
```bash
grep -rn "xml2array" Classes/
```

**Fix Pattern**
```php
// Before
if ($row['field'] !== '') {
    $config = GeneralUtility::xml2array($row['field']);
}

// After
if (!empty($row['field'])) {
    $config = (array) GeneralUtility::xml2array((string) $row['field']);
}
```

### FlexForm Structure (Fractor handles)

**Search Pattern**
```bash
grep -rn "<required>1</required>" Configuration/FlexForms/
```

**Fix**: Run Fractor - migrates to `<required>true</required>`.

### TypoScript Conditions

**Search Pattern**
```bash
grep -rn "\[end\]" Configuration/TypoScript/
```

**Replace**: `[end]` → `[global]` (Fractor handles).

### Click Menu Parameters

**Search Pattern**
```bash
grep -rn "BackendUtility::wrapClickMenuOnIcon\|getClickMenuOnIconTagParameters" Classes/
```

**Fix**: Remove 4th parameter if `'true'` or `'1'`.

---

## v12 → v13 Upgrade

### Request Attributes (Critical)

**Search Pattern**
```bash
grep -rn "\$TSFE->fe_user\|\$GLOBALS\['TSFE'\]->fe_user" Classes/
```

**Replace**

| Before (v12) | After (v13) |
|--------------|-------------|
| `$TSFE->fe_user` | `$request->getAttribute('frontend.user')` |
| `$TSFE->page` | `$request->getAttribute('frontend.page.information')->getPageRecord()` |
| `$TSFE->rootLine` | `$request->getAttribute('frontend.page.information')->getRootLine()` |
| `$TSFE->id` | `$request->getAttribute('frontend.page.information')->getId()` |

### Site Sets Introduction

**Search Pattern**
```bash
grep -rn "ext_typoscript_setup\.typoscript\|ext_typoscript_constants"
```

**Replace**: Migrate to Site Sets (`Configuration/Sets/`).

```yaml
# Configuration/Sets/MySet/config.yaml
name: vendor/my-set
label: My Extension Set
dependencies:
  - typo3/fluid-styled-content
```

### Backend Module Registration

**Search Pattern**
```bash
grep -rn "registerModule\|TYPO3_MOD_PATH" ext_tables.php
```

**Replace**: Use `Configuration/Backend/Modules.php`.

### TCA Type Changes

**Search Pattern**
```bash
grep -rn "'type'\s*=>\s*'text'" Configuration/TCA/
```

**Note**: Review `type => text` fields for migration to `type => json` where applicable.

---

## v13 → v14 Upgrade

### Upcoming Changes

Monitor [Changelog-14](https://docs.typo3.org/c/typo3/cms-core/main/en-us/Changelog-14.html) for breaking changes.

**Known Deprecations to Watch**
- Further TSFE deprecations
- Additional Request attribute migrations
- Continued Site Set enhancements

---

## PHP 8.4 Compatibility

These changes are required for PHP 8.4 compatibility regardless of TYPO3 version.

### Implicit Nullable Parameters (Critical)

PHP 8.4 deprecates implicit nullable parameters. This affects all TYPO3 versions.

**Search Pattern**
```bash
# Find parameters with null default but no explicit nullable type
grep -rn '\(.*\$[a-zA-Z_]* = null\)' Classes/ | grep -v '?[a-zA-Z_\\]*\s*\$'
```

**Replace**
```php
// ❌ Deprecated in PHP 8.4 (E_DEPRECATED), Error in PHP 9.0
public function foo(string $param = null): void
public function bar(array $config = null): void

// ✅ Required - Explicit nullable type
public function foo(?string $param = null): void
public function bar(?array $config = null): void
```

**Common Occurrences**
- FlexForm configuration parameters
- Optional service dependencies in constructors
- Default TCA configuration arrays
- Callback/hook method signatures

**Rector Rule**: Use `NullableTypeDeclarationRector` to auto-fix.

### TCA Items Array Format

**Search Pattern**
```bash
grep -rn "'items'\s*=>\s*\[" Configuration/TCA/ | grep -v "label"
```

**Replace**
```php
// ❌ Old format (deprecated)
'items' => [
    ['Label', 'value'],
    ['Other Label', 'other_value'],
],

// ✅ New format (TYPO3 v12+)
'items' => [
    ['label' => 'Label', 'value' => 'value'],
    ['label' => 'Other Label', 'value' => 'other_value'],
],
```

---

## PSR-7 Request Handling Patterns

### Query Parameter Access in Context Classes

When migrating context matching or middleware that needs request data:

**Search Pattern**
```bash
grep -rn "\$_GET\['\|\$_POST\['" Classes/
```

**Replace Pattern**
```php
// ❌ Old pattern - doesn't work with PSR-7 request flow
$value = $_GET['param'] ?? null;

// ✅ TYPO3 v12+ - Use PSR-7 request from container/middleware
use Psr\Http\Message\ServerRequestInterface;

class MyContext
{
    private ?ServerRequestInterface $request = null;

    public function setRequest(ServerRequestInterface $request): self
    {
        $this->request = $request;
        return $this;
    }

    public function match(): bool
    {
        // Get from stored request first, fallback to GLOBALS
        $request = $this->request
            ?? $GLOBALS['TYPO3_REQUEST']
            ?? null;

        if ($request === null) {
            return false;
        }

        $value = $request->getQueryParams()['param'] ?? null;
        return $value === 'expected';
    }
}
```

### Middleware Request Passing

```php
// In middleware, pass request to context/service
public function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler
): ResponseInterface {
    // Store request for context matching
    Container::get()->setRequest($request)->initMatching();

    return $handler->handle($request);
}
```

---

## SC_OPTIONS Hooks to PSR-14 Events

### Page Visibility Hooks (Critical for v12+)

SC_OPTIONS hooks for page visibility may not work correctly in TYPO3 v12+.

**Search Pattern**
```bash
grep -rn "SC_OPTIONS\['t3lib/class.t3lib_page.php'\]" ext_localconf.php
grep -rn "additionalQueryRestrictions" ext_localconf.php
```

**Issue**: Query restrictions registered in `additionalQueryRestrictions` may not be applied during page resolution in v12+.

**Solution**: Migrate to PSR-14 events:

```php
// Configuration/Services.yaml
services:
  Vendor\Extension\EventListener\PageAccessListener:
    tags:
      - name: event.listener
        identifier: 'vendor-extension/page-access'
        event: TYPO3\CMS\Core\Domain\Event\BeforePageIsRetrievedEvent
```

```php
// Classes/EventListener/PageAccessListener.php
use TYPO3\CMS\Core\Domain\Event\BeforePageIsRetrievedEvent;

final class PageAccessListener
{
    public function __invoke(BeforePageIsRetrievedEvent $event): void
    {
        // Check context and modify page access
        $pageId = $event->getPageId();
        // ... context matching logic
    }
}
```

**Note**: Test page visibility thoroughly after migration. Some hook-based restrictions require complete PSR-14 event migration to work correctly.

---

## Dual Version Compatibility Matrix

When supporting multiple versions (e.g., `^12.4 || ^13.4`):

| API | v11 | v12 | v13 | v14 |
|-----|-----|-----|-----|-----|
| `$GLOBALS['TYPO3_DB']` | ❌ | ❌ | ❌ | ❌ |
| `QueryBuilder` | ✅ | ✅ | ✅ | ✅ |
| `PDO::PARAM_*` | ✅ | ❌ | ❌ | ❌ |
| `Connection::PARAM_*` | ✅ | ✅ | ✅ | ✅ |
| `GeneralUtility::_GET()` | ✅ | ⚠️ | ❌ | ❌ |
| `$_GET['param'] ?? null` | ✅ | ✅ | ✅ | ✅ |
| `$TSFE->fe_user` | ✅ | ✅ | ⚠️ | ❌ |
| `$request->getAttribute('frontend.user')` | ❌ | ❌ | ✅ | ✅ |
| Signal/Slot | ⚠️ | ❌ | ❌ | ❌ |
| PSR-14 Events | ✅ | ✅ | ✅ | ✅ |

Legend: ✅ Supported | ⚠️ Deprecated | ❌ Removed

**Rule**: For dual compatibility, always use the older-version-compatible API.

---

## Quick Search Commands

```bash
# v7→v8: Old database API
grep -rn "TYPO3_DB\|exec_SELECTquery" Classes/

# v8→v9: Old routing
grep -rn "tx_realurl\|cooluri\|sys_domain"

# v9→v10: Signal/Slot
grep -rn "SignalSlotDispatcher\|->connect\(" Classes/

# v10→v11: Old Fluid
grep -rn "setTemplatePathAndFilename" Classes/

# v11→v12: PDO constants & deprecated methods
grep -rn "PDO::PARAM_\|GeneralUtility::_GET\|itemFormElID" Classes/

# v12→v13: TSFE direct access
grep -rn "\$TSFE->fe_user\|\$TSFE->page\|\$TSFE->rootLine" Classes/

# PHP 8.4: Implicit nullable parameters
grep -rn '\$[a-zA-Z_]* = null)' Classes/ | grep -v '?'

# PHP 8.4: Old TCA items format
grep -rn "'items'\s*=>" Configuration/TCA/ | head -20

# PSR-7: Direct superglobal access
grep -rn "\$_GET\['\|\$_POST\['" Classes/

# SC_OPTIONS hooks (may need PSR-14 migration)
grep -rn "SC_OPTIONS" ext_localconf.php

# All versions: Full deprecation scan
grep -rn "@deprecated\|trigger_error.*E_USER_DEPRECATED" Classes/
```

---

## Verification Commands

After making changes:

```bash
# Static analysis
./vendor/bin/phpstan analyse

# Code style
./vendor/bin/php-cs-fixer fix --dry-run --diff

# Unit tests
./vendor/bin/phpunit --testsuite Unit

# Functional tests
./vendor/bin/phpunit --testsuite Functional
```
