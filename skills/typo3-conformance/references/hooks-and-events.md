# TYPO3 Hooks and PSR-14 Events

**Source:** TYPO3 Core API Reference - Hooks, Events, and Signals
**Purpose:** Understanding TYPO3 hook system, PSR-14 events, and migration strategies

## SC_OPTIONS Hooks Status in TYPO3 13

### ⚠️ Common Misconception

**INCORRECT:** "SC_OPTIONS hooks are deprecated in TYPO3 13"

**CORRECT:** SC_OPTIONS hooks are **NOT deprecated** in TYPO3 13. They remain the **official pattern** for specific use cases.

### SC_OPTIONS Hooks That Are Still Official

The following SC_OPTIONS hooks remain the official TYPO3 13 pattern:

#### DataHandler Hooks (Still Official)

```php
// Configuration/Services.yaml
Vendor\Extension\Database\MyDataHandlerHook:
  public: true
  tags:
    - name: event.listener
      identifier: 'my-extension/datahandler-hook'
      method: 'processDatamap_postProcessFieldArray'
```

**Still Official in ext_localconf.php:**
```php
<?php
// TYPO3 13+ DataHandler hooks remain official pattern
$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['t3lib/class.t3lib_tcemain.php']['processDatamapClass'][] =
    \Vendor\Extension\Database\MyDataHandlerHook::class;

$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['t3lib/class.t3lib_tcemain.php']['processCmdmapClass'][] =
    \Vendor\Extension\Database\MyDataHandlerHook::class;
```

**Key DataHandler Hook Methods (TYPO3 13+):**
- `processDatamap_preProcessFieldArray()` - Before field processing
- `processDatamap_postProcessFieldArray()` - After field processing
- `processDatamap_afterDatabaseOperations()` - After DB operations
- `processCmdmap_preProcess()` - Before command processing
- `processCmdmap_postProcess()` - After command processing
- `processCmdmap_afterFinish()` - After all commands finished

#### RTE Transformation Hooks (Still Official)

```php
<?php
// TYPO3 13+ RTE transformation hooks remain official pattern
$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['t3lib/class.t3lib_parsehtml_proc.php']['transformation'][] =
    \Vendor\Extension\RteTransformation\MyRteTransformationHook::class;
```

**Required Methods:**
- `transform_rte()` - Transform content from database to RTE
- `transform_db()` - Transform content from RTE to database

### When to Use SC_OPTIONS vs PSR-14 Events

| Scenario | Use SC_OPTIONS Hook | Use PSR-14 Event |
|----------|-------------------|------------------|
| DataHandler field processing | ✅ Yes (official) | ❌ No event available |
| RTE content transformation | ✅ Yes (official) | ❌ No event available |
| Backend user authentication | ❌ Migrated | ✅ Use PSR-14 events |
| Frontend rendering | ❌ Migrated | ✅ Use PSR-14 events |
| Page generation | ❌ Migrated | ✅ Use PSR-14 events |
| Cache clearing | ❌ Migrated | ✅ Use PSR-14 events |

## PSR-14 Event Listeners (Preferred)

For most scenarios, PSR-14 events are the modern TYPO3 13+ approach.

### Event Listener Configuration

```yaml
# Configuration/Services.yaml
services:
  _defaults:
    autowire: true
    autoconfigure: true
    public: false

  Vendor\Extension\:
    resource: '../Classes/*'

  # PSR-14 Event Listener
  Vendor\Extension\EventListener\MyEventListener:
    tags:
      - name: event.listener
        identifier: 'my-extension/my-event-listener'
        event: TYPO3\CMS\Core\Authentication\Event\AfterUserLoggedInEvent
```

### Event Listener Implementation

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\EventListener;

use TYPO3\CMS\Core\Authentication\Event\AfterUserLoggedInEvent;

/**
 * PSR-14 Event Listener for user login.
 */
final class MyEventListener
{
    public function __invoke(AfterUserLoggedInEvent $event): void
    {
        $user = $event->getUser();

        // Your logic here
    }
}
```

### Common TYPO3 13 Events

**Authentication Events:**
- `AfterUserLoggedInEvent`
- `BeforeUserLogoutEvent`
- `AfterUserLoggedOutEvent`

**Backend Events:**
- `ModifyButtonBarEvent`
- `ModifyDatabaseQueryForContentEvent`
- `BeforePagePreviewUriGeneratedEvent`

**DataHandler Events:**
- `AfterDataInsertedEvent`
- `AfterDataUpdatedEvent`
- `AfterRecordDeletedEvent`

**Page Events:**
- `AfterPageTreeItemsPreparedEvent`
- `ModifyPageLayoutContentEvent`

**Complete Reference:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/Events/EventDispatcher/Index.html

## Migration Strategy

### Step 1: Identify Hook Type

```php
// Check if hook is in ext_localconf.php
$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['...']['...'][]
```

### Step 2: Check Official Documentation

- **DataHandler hooks:** Still official, keep using SC_OPTIONS
- **RTE transformation:** Still official, keep using SC_OPTIONS
- **Other hooks:** Check if PSR-14 event exists

### Step 3: Migrate or Modernize

**If PSR-14 event exists:**
```php
// OLD: ext_localconf.php
$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['t3lib/class.t3lib_userauth.php']['postUserLookUp'][]
    = \Vendor\Extension\Hook\MyHook::class;

// NEW: Configuration/Services.yaml + EventListener class
Vendor\Extension\EventListener\MyEventListener:
  tags:
    - name: event.listener
      identifier: 'my-extension/after-login'
      event: TYPO3\CMS\Core\Authentication\Event\AfterUserLoggedInEvent
```

**If no PSR-14 event exists (DataHandler, RTE):**
```php
// KEEP: Still official in TYPO3 13+
$GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['t3lib/class.t3lib_tcemain.php']['processDatamapClass'][]
    = \Vendor\Extension\Database\MyDataHandlerHook::class;

// MODERNIZE: Add dependency injection
// Configuration/Services.yaml
Vendor\Extension\Database\MyDataHandlerHook:
  public: true
  arguments:
    $resourceFactory: '@TYPO3\CMS\Core\Resource\ResourceFactory'
    $context: '@TYPO3\CMS\Core\Context\Context'
    $logManager: '@TYPO3\CMS\Core\Log\LogManager'
```

## Best Practices

### 1. Constructor Dependency Injection

Even for SC_OPTIONS hooks, use constructor injection (TYPO3 13+):

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Database;

use TYPO3\CMS\Core\Context\Context;
use TYPO3\CMS\Core\Log\LogManager;
use TYPO3\CMS\Core\Resource\ResourceFactory;

/**
 * DataHandler hook with dependency injection.
 */
final class MyDataHandlerHook
{
    public function __construct(
        private readonly ResourceFactory $resourceFactory,
        private readonly Context $context,
        private readonly LogManager $logManager,
    ) {}

    public function processDatamap_postProcessFieldArray(
        string $status,
        string $table,
        string $id,
        array &$fieldArray,
        \TYPO3\CMS\Core\DataHandling\DataHandler &$dataHandler,
    ): void {
        // Use injected dependencies
        $file = $this->resourceFactory->getFileObject($fileId);
    }
}
```

### 2. Avoid GeneralUtility::makeInstance()

```php
// ❌ BAD: Using makeInstance (legacy pattern)
$resourceFactory = GeneralUtility::makeInstance(ResourceFactory::class);

// ✅ GOOD: Constructor injection (TYPO3 13+ pattern)
public function __construct(
    private readonly ResourceFactory $resourceFactory,
) {}
```

### 3. Configure Services Explicitly

```yaml
# Configuration/Services.yaml
services:
  Vendor\Extension\Database\MyDataHandlerHook:
    public: true  # Required for SC_OPTIONS hooks
    arguments:
      $resourceFactory: '@TYPO3\CMS\Core\Resource\ResourceFactory'
      $context: '@TYPO3\CMS\Core\Context\Context'
      $logManager: '@TYPO3\CMS\Core\Log\LogManager'
```

## Acceptable $GLOBALS Usage

Even in TYPO3 13+, certain `$GLOBALS` usage is acceptable:

### ✅ Acceptable $GLOBALS

```php
// TCA access (no alternative available)
$GLOBALS['TCA']['tt_content']['columns']['bodytext']

// Current request (framework-provided)
$GLOBALS['TYPO3_REQUEST']

// Backend user context (framework-provided)
$GLOBALS['BE_USER']

// Frontend user context (framework-provided)
$GLOBALS['TSFE']
```

### ❌ Avoid $GLOBALS

```php
// Database connection (use ConnectionPool)
$GLOBALS['TYPO3_DB']

// Extension configuration (use ExtensionConfiguration)
$GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['my_ext']

// Object instantiation (use dependency injection)
GeneralUtility::makeInstance(SomeClass::class)
```

## Resources

- [TYPO3 Hooks Documentation](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/Hooks/Index.html)
- [PSR-14 Events](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/Events/EventDispatcher/Index.html)
- [DataHandler Hooks](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/Hooks/DataHandler/Index.html)
- [Dependency Injection](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/DependencyInjection/Index.html)
