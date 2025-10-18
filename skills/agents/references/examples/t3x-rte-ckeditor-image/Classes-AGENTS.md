# Classes/AGENTS.md

<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: 2025-10-15 -->

**Scope:** PHP backend components (Controllers, EventListeners, DataHandling, Utils)
**Parent:** [../AGENTS.md](../AGENTS.md)

## 📋 Overview

PHP backend implementation for TYPO3 CKEditor Image extension. Components:

### Controllers
- **SelectImageController** - Image browser wizard, file selection, image info API
- **ImageRenderingController** - Image rendering and processing for frontend
- **ImageLinkRenderingController** - Link-wrapped image rendering

### EventListeners
- **RteConfigurationListener** - PSR-14 event for RTE configuration injection

### DataHandling
- **RteImagesDbHook** - Database hooks for image magic reference handling
- **RteImageSoftReferenceParser** - Soft reference parsing for RTE images

### Backend Components
- **RteImagePreviewRenderer** - Backend preview rendering

### Utilities
- **ProcessedFilesHandler** - File processing and manipulation utilities

## 🏗️ Architecture Patterns

### TYPO3 Patterns
- **FAL (File Abstraction Layer):** All file operations via ResourceFactory
- **PSR-7 Request/Response:** HTTP message interfaces for controllers
- **PSR-14 Events:** Event-driven configuration and hooks
- **Dependency Injection:** Constructor-based DI (TYPO3 v13+)
- **Service Configuration:** `Configuration/Services.yaml` for DI registration

### File Structure
```
Classes/
├── Backend/
│   └── Preview/
│       └── RteImagePreviewRenderer.php
├── Controller/
│   ├── ImageLinkRenderingController.php
│   ├── ImageRenderingController.php
│   └── SelectImageController.php
├── DataHandling/
│   └── SoftReference/
│       └── RteImageSoftReferenceParser.php
├── Database/
│   └── RteImagesDbHook.php
├── EventListener/
│   └── RteConfigurationListener.php
└── Utils/
    └── ProcessedFilesHandler.php
```

## 🔧 Build & Tests

```bash
# PHP-specific quality checks
make lint                      # All linters (syntax + PHPStan + Rector + style)
composer ci:test:php:lint      # PHP syntax check
composer ci:test:php:phpstan   # Static analysis
composer ci:test:php:rector    # Rector modernization check
composer ci:test:php:cgl       # Code style check

# Fixes
make format                    # Auto-fix code style
composer ci:cgl               # Alternative: fix style
composer ci:rector            # Apply Rector changes

# Full CI
make ci                       # Complete pipeline
```

## 📝 Code Style

### Required Patterns

**1. Strict Types (Always First)**
```php
<?php

declare(strict_types=1);
```

**2. File Header (Auto-managed by PHP-CS-Fixer)**
```php
/**
 * This file is part of the package netresearch/rte-ckeditor-image.
 *
 * For the full copyright and license information, please read the
 * LICENSE file that was distributed with this source code.
 */
```

**3. Import Order**
- Classes first
- Functions second
- Constants third
- One blank line before namespace

**4. Type Hints**
- All parameters must have type hints
- All return types must be declared
- Use nullable types `?Type` when appropriate
- Use union types `Type1|Type2` for PHP 8+

**5. Property Types**
```php
private ResourceFactory $resourceFactory;        // Required type declaration
private readonly ResourceFactory $factory;       // Readonly for immutability
```

**6. Alignment**
```php
$config = [
    'short'  => 'value',       // Align on =>
    'longer' => 'another',
];
```

## 🔒 Security

### FAL (File Abstraction Layer)
- **Always use FAL:** Never direct file system access
- **ResourceFactory:** For retrieving files by UID
- **File validation:** Check isDeleted(), isMissing()
- **ProcessedFile:** Use process() for image manipulation

```php
// ✅ Good: FAL usage
$file = $this->resourceFactory->getFileObject($id);
if ($file->isDeleted() || $file->isMissing()) {
    throw new \Exception('File not found');
}

// ❌ Bad: Direct file access
$file = file_get_contents('/var/www/uploads/' . $filename);
```

### Input Validation
- **Type cast superglobals:** `(int)($request->getQueryParams()['id'] ?? 0)`
- **Validate before use:** Check ranges, formats, existence
- **Exit on error:** Use HTTP status codes with `HttpUtility::HTTP_STATUS_*`

### XSS Prevention
- **Fluid templates:** Auto-escaping enabled by default
- **JSON responses:** Use `JsonResponse` class
- **Localization:** Via `LocalizationUtility::translate()`

## ✅ PR/Commit Checklist

### PHP-Specific Checks
1. ✅ **Strict types:** `declare(strict_types=1);` in all files
2. ✅ **Type hints:** All parameters and return types declared
3. ✅ **PHPStan:** Zero errors (`composer ci:test:php:phpstan`)
4. ✅ **Code style:** PSR-12/PER-CS2.0 compliant (`make format`)
5. ✅ **Rector:** No modernization suggestions (`composer ci:test:php:rector`)
6. ✅ **FAL usage:** No direct file system access
7. ✅ **DI pattern:** Constructor injection, no `new ClassName()`
8. ✅ **PSR-7:** Request/Response for controllers
9. ✅ **Documentation:** PHPDoc for public methods

## 🎓 Good vs Bad Examples

### ✅ Good: Controller Pattern

```php
<?php

declare(strict_types=1);

namespace Netresearch\RteCKEditorImage\Controller;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Core\Http\JsonResponse;
use TYPO3\CMS\Core\Resource\ResourceFactory;

final class SelectImageController
{
    public function __construct(
        private readonly ResourceFactory $resourceFactory
    ) {
    }

    public function infoAction(ServerRequestInterface $request): ResponseInterface
    {
        $fileUid = (int)($request->getQueryParams()['fileId'] ?? 0);

        if ($fileUid <= 0) {
            return new JsonResponse(['error' => 'Invalid file ID'], 400);
        }

        $file = $this->resourceFactory->getFileObject($fileUid);

        return new JsonResponse([
            'uid'    => $file->getUid(),
            'width'  => $file->getProperty('width'),
            'height' => $file->getProperty('height'),
        ]);
    }
}
```

### ❌ Bad: Anti-patterns

```php
<?php
// ❌ Missing strict types
namespace Netresearch\RteCKEditorImage\Controller;

// ❌ Missing PSR-7 types
class SelectImageController
{
    // ❌ No constructor DI
    public function infoAction($request)
    {
        // ❌ Direct superglobal access
        $fileUid = $_GET['fileId'];

        // ❌ No DI - manual instantiation
        $factory = new ResourceFactory();

        // ❌ No type safety, no validation
        $file = $factory->getFileObject($fileUid);

        // ❌ Manual JSON encoding
        header('Content-Type: application/json');
        echo json_encode(['uid' => $file->getUid()]);
        exit;
    }
}
```

### ✅ Good: EventListener Pattern

```php
<?php

declare(strict_types=1);

namespace Netresearch\RteCKEditorImage\EventListener;

use TYPO3\CMS\Backend\Routing\UriBuilder;
use TYPO3\CMS\RteCKEditor\Form\Element\Event\AfterPrepareConfigurationForEditorEvent;

final class RteConfigurationListener
{
    public function __construct(
        private readonly UriBuilder $uriBuilder
    ) {
    }

    public function __invoke(AfterPrepareConfigurationForEditorEvent $event): void
    {
        $configuration = $event->getConfiguration();
        $configuration['style']['typo3image'] = [
            'routeUrl' => (string)$this->uriBuilder->buildUriFromRoute('rteckeditorimage_wizard_select_image'),
        ];
        $event->setConfiguration($configuration);
    }
}
```

### ❌ Bad: EventListener Anti-pattern

```php
<?php
namespace Netresearch\RteCKEditorImage\EventListener;

class RteConfigurationListener
{
    // ❌ Wrong signature - not invokable
    public function handle($event)
    {
        // ❌ Manual instantiation instead of DI
        $uriBuilder = \TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance(UriBuilder::class);

        // ❌ Array access without type safety
        $config = $event->getConfiguration();
        $config['style']['typo3image']['routeUrl'] = $uriBuilder->buildUriFromRoute('rteckeditorimage_wizard_select_image');
        $event->setConfiguration($config);
    }
}
```

### ✅ Good: FAL Usage

```php
protected function getImage(int $id): File
{
    try {
        $file = $this->resourceFactory->getFileObject($id);

        if ($file->isDeleted() || $file->isMissing()) {
            throw new FileNotFoundException('File not found or deleted', 1234567890);
        }
    } catch (\Exception $e) {
        throw new FileNotFoundException('Could not load file', 1234567891, $e);
    }

    return $file;
}
```

### ❌ Bad: Direct File Access

```php
// ❌ Multiple issues
protected function getImage($id)  // Missing return type, no type hint
{
    // ❌ Direct file system access, bypassing FAL
    $path = '/var/www/html/fileadmin/' . $id;

    // ❌ No validation, no error handling
    if (file_exists($path)) {
        return file_get_contents($path);
    }

    return null;  // ❌ Should throw exception or return typed null
}
```

## 🆘 When Stuck

### Documentation
- **API Reference:** [docs/API/Controllers.md](../docs/API/Controllers.md) - Controller APIs
- **Event Listeners:** [docs/API/EventListeners.md](../docs/API/EventListeners.md) - PSR-14 events
- **Data Handling:** [docs/API/DataHandling.md](../docs/API/DataHandling.md) - Database hooks
- **Architecture:** [docs/Architecture/Overview.md](../docs/Architecture/Overview.md) - System design

### TYPO3 Resources
- **FAL Documentation:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/Fal/Index.html
- **PSR-14 Events:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/Events/Index.html
- **Dependency Injection:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/DependencyInjection/Index.html
- **Controllers:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/Backend/Controllers/Index.html

### Common Issues
- **ResourceFactory errors:** Check file exists, not deleted, proper UID
- **DI not working:** Verify `Configuration/Services.yaml` registration
- **PHPStan errors:** Update baseline: `composer ci:test:php:phpstan:baseline`
- **Type errors:** Enable strict_types, add all type hints

## 📐 House Rules

### Controllers
- **Extend framework controllers:** ElementBrowserController for browsers
- **Final by default:** Use `final class` unless inheritance required
- **PSR-7 types:** ServerRequestInterface → ResponseInterface
- **JSON responses:** Use `JsonResponse` class
- **Validation first:** Validate all input parameters at method start

### EventListeners
- **Invokable:** Use `__invoke()` method signature
- **Event type hints:** Type-hint specific event classes
- **Immutability aware:** Get, modify, set configuration/state
- **Final classes:** Event listeners should be final

### DataHandling
- **Soft references:** Implement soft reference parsing for data integrity
- **Database hooks:** Use for maintaining referential integrity
- **Transaction safety:** Consider rollback scenarios

### Dependencies
- **Constructor injection:** All dependencies via constructor
- **Readonly properties:** Use `readonly` for immutable dependencies
- **Interface over implementation:** Depend on interfaces when available
- **GeneralUtility::makeInstance:** Only for factories or when DI unavailable

### Error Handling
- **Type-specific exceptions:** Use TYPO3 exception hierarchy
- **HTTP status codes:** Via HttpUtility constants
- **Meaningful messages:** Include context in exception messages
- **Log important errors:** Use TYPO3 logging framework

### Testing
- **Functional tests:** For controllers, database operations
- **Unit tests:** For utilities, isolated logic
- **Mock FAL:** Use TYPO3 testing framework FAL mocks
- **Test location:** `Tests/Functional/` and `Tests/Unit/`

## 🔗 Related

- **[Resources/AGENTS.md](../Resources/AGENTS.md)** - JavaScript/CKEditor integration
- **[Tests/AGENTS.md](../Tests/AGENTS.md)** - Testing patterns
- **[Configuration/Services.yaml](../Configuration/Services.yaml)** - DI container configuration
- **[docs/API/](../docs/API/)** - Complete API documentation
