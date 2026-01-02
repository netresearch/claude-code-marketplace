# TYPO3 PHP Architecture Standards

**Source:** TYPO3 Core API Reference - PHP Architecture
**Purpose:** Dependency injection, services, events, Extbase, middleware patterns

## Dependency Injection

TYPO3 uses **Symfony's Dependency Injection Container** for service management.

### Constructor Injection (Preferred)

```php
// ✅ Right: Constructor injection with readonly properties
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Controller;

use Psr\Http\Message\ResponseInterface;
use TYPO3\CMS\Extbase\Mvc\Controller\ActionController;
use Vendor\ExtensionKey\Domain\Repository\UserRepository;

final class UserController extends ActionController
{
    public function __construct(
        private readonly UserRepository $userRepository
    ) {}

    public function listAction(): ResponseInterface
    {
        $users = $this->userRepository->findAll();
        $this->view->assign('users', $users);
        return $this->htmlResponse();
    }
}
```

### Method Injection (inject* Methods)

```php
// ✅ Right: Method injection for abstract classes
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Controller;

use TYPO3\CMS\Extbase\Mvc\Controller\ActionController;
use Vendor\ExtensionKey\Domain\Repository\UserRepository;

class UserController extends ActionController
{
    protected ?UserRepository $userRepository = null;

    public function injectUserRepository(UserRepository $userRepository): void
    {
        $this->userRepository = $userRepository;
    }
}
```

**When to Use Method Injection:**
- Extending abstract core classes (ActionController, AbstractValidator)
- Avoiding breaking changes when base class constructor changes
- Optional dependencies

**When to Use Constructor Injection:**
- All new code (preferred)
- Required dependencies
- Better testability

### Interface Injection

```php
// ✅ Right: Depend on interfaces, not implementations
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Controller;

use Psr\Http\Message\ResponseInterface;
use TYPO3\CMS\Extbase\Mvc\Controller\ActionController;
use Vendor\ExtensionKey\Domain\Repository\UserRepositoryInterface;

final class UserController extends ActionController
{
    public function __construct(
        private readonly UserRepositoryInterface $userRepository
    ) {}
}
```

## Service Configuration

### Configuration/Services.yaml

```yaml
# ✅ Right: Proper service configuration
services:
  _defaults:
    autowire: true
    autoconfigure: true
    public: false

  # Auto-register all classes
  Vendor\ExtensionKey\:
    resource: '../Classes/*'

  # Explicit service configuration
  Vendor\ExtensionKey\Service\MyService:
    arguments:
      $configValue: '%env(MY_CONFIG_VALUE)%'

  # Factory pattern for Connection
  Vendor\ExtensionKey\Domain\Repository\MyTableRepository:
    factory: ['@TYPO3\CMS\Core\Database\ConnectionPool', 'getConnectionForTable']
    arguments:
      - 'my_table'

  # Interface binding
  Vendor\ExtensionKey\Domain\Repository\UserRepositoryInterface:
    class: Vendor\ExtensionKey\Domain\Repository\UserRepository
```

### Autowire Attribute (TYPO3 v12+)

```php
// ✅ Right: Inject configuration using Autowire attribute
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Service;

use TYPO3\CMS\Core\DependencyInjection\Attribute\Autowire;

final class MyService
{
    public function __construct(
        #[Autowire(expression: 'service("configuration.extension").get("my_extension", "mySetting")')]
        private readonly string $myExtensionSetting
    ) {}
}
```

## PSR-14 Event Dispatcher

### Defining Custom Events

```php
// ✅ Right: Immutable event class with getters/setters
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Event;

final class BeforeUserCreatedEvent
{
    public function __construct(
        private string $username,
        private string $email,
        private array $additionalData = []
    ) {}

    public function getUsername(): string
    {
        return $this->username;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function getAdditionalData(): array
    {
        return $this->additionalData;
    }

    public function setAdditionalData(array $additionalData): void
    {
        $this->additionalData = $additionalData;
    }
}
```

### Dispatching Events

```php
// ✅ Right: Inject and dispatch events
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Service;

use Psr\EventDispatcher\EventDispatcherInterface;
use Vendor\ExtensionKey\Event\BeforeUserCreatedEvent;

final class UserService
{
    public function __construct(
        private readonly EventDispatcherInterface $eventDispatcher
    ) {}

    public function createUser(string $username, string $email): void
    {
        $event = new BeforeUserCreatedEvent($username, $email);
        $event = $this->eventDispatcher->dispatch($event);

        // Use potentially modified data from event
        $finalUsername = $event->getUsername();
        $finalEmail = $event->getEmail();

        // Create user with final data
    }
}
```

### Event Listeners

```php
// ✅ Right: Event listener with AsEventListener attribute
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\EventListener;

use TYPO3\CMS\Core\Attribute\AsEventListener;
use Vendor\ExtensionKey\Event\BeforeUserCreatedEvent;

#[AsEventListener(
    identifier: 'vendor/extension-key/validate-user-creation',
    event: BeforeUserCreatedEvent::class
)]
final class ValidateUserCreationListener
{
    public function __invoke(BeforeUserCreatedEvent $event): void
    {
        // Validate email format
        if (!filter_var($event->getEmail(), FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException('Invalid email format');
        }

        // Add custom data
        $event->setAdditionalData([
            'validated_at' => time(),
            'validator' => 'ValidateUserCreationListener',
        ]);
    }
}
```

### Event Listener Registration (Services.yaml)

```yaml
# Alternative: Register event listeners in Services.yaml
services:
  Vendor\ExtensionKey\EventListener\ValidateUserCreationListener:
    tags:
      - name: event.listener
        identifier: 'vendor/extension-key/validate-user-creation'
        event: Vendor\ExtensionKey\Event\BeforeUserCreatedEvent
        method: '__invoke'
```

### PSR-14 Event Class Standards (TYPO3 13+)

Modern event classes should follow these quality standards:

```php
// ✅ Right: Modern event class with final keyword and readonly properties
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Event;

use Psr\Http\Message\ServerRequestInterface;

final class NewsListActionEvent  // ✅ Use 'final' keyword
{
    public function __construct(
        private NewsController $newsController,
        private array $assignedValues,
        private readonly ServerRequestInterface $request  // ✅ Use 'readonly' for immutable properties
    ) {}

    public function getNewsController(): NewsController
    {
        return $this->newsController;
    }

    public function getAssignedValues(): array
    {
        return $this->assignedValues;
    }

    public function setAssignedValues(array $assignedValues): void
    {
        $this->assignedValues = $assignedValues;
    }

    public function getRequest(): ServerRequestInterface
    {
        return $this->request;  // Read-only, no setter
    }
}
```

**Event Class Quality Checklist:**
- [ ] Use `final` keyword (prevents inheritance, ensures immutability)
- [ ] Use `readonly` for properties that should never change after construction
- [ ] Provide getters for all properties
- [ ] Provide setters ONLY for properties that should be modifiable
- [ ] Type hint all properties and methods
- [ ] Document the purpose and usage of the event

**Why `final` for Events?**
- Events are data carriers, not meant to be extended
- Prevents unexpected behavior from inheritance
- Makes event behavior predictable and testable
- Follows modern PHP best practices

**Why `readonly` for Properties?**
- Some event data should never change (e.g., original request, user context)
- Explicit immutability prevents accidental modifications
- Clearly communicates intent to event listeners
- Available in PHP 8.1+ (TYPO3 13 minimum is PHP 8.1)

## TYPO3 13 Site Sets

**Purpose:** Modern configuration distribution system replacing static TypoScript includes

### Site Sets Structure

```
Configuration/Sets/
├── MyExtension/           # Base configuration set
│   ├── config.yaml        # Set metadata and dependencies
│   ├── setup.typoscript   # Frontend TypoScript
│   ├── constants.typoscript
│   └── settings.definitions.yaml  # Setting definitions for extension configuration
├── RecordLinks/           # Optional feature set
│   ├── config.yaml
│   └── setup.typoscript
└── Bootstrap5/            # Frontend framework preset
    ├── config.yaml
    ├── setup.typoscript
    └── settings.yaml
```

### config.yaml Structure

```yaml
# ✅ Right: Proper Site Set configuration
name: vendor/extension-key
label: Extension Name Base Configuration

# Dependencies on other sets
dependencies:
  - typo3/fluid-styled-content
  - vendor/extension-key-styles

# Load order priority (optional)
priority: 50

# Settings that can be overridden
settings:
  mySetting:
    value: 'default value'
    type: string
    label: 'My Setting Label'
    description: 'Description of what this setting does'
```

### settings.definitions.yaml

```yaml
# ✅ Right: Define extension settings with validation
settings:
  # Text input
  mySetting:
    type: string
    default: 'default value'
    label: 'LLL:EXT:extension_key/Resources/Private/Language/locallang.xlf:settings.mySetting'
    description: 'LLL:EXT:extension_key/Resources/Private/Language/locallang.xlf:settings.mySetting.description'

  # Boolean checkbox
  enableFeature:
    type: bool
    default: false
    label: 'Enable Feature'

  # Integer input
  itemsPerPage:
    type: int
    default: 10
    label: 'Items per page'
    validators:
      - name: NumberRange
        options:
          minimum: 1
          maximum: 100

  # Select dropdown
  layout:
    type: string
    default: 'default'
    label: 'Layout'
    enum:
      default: 'Default'
      compact: 'Compact'
      detailed: 'Detailed'
```

### Benefits of Site Sets

1. **Modular Configuration**: Split configuration into focused, reusable sets
2. **Dependency Management**: Declare dependencies on other sets
3. **Override Capability**: Sites can override set settings without editing files
4. **Type Safety**: Settings are validated with defined types
5. **Better UX**: Settings UI auto-generated from definitions
6. **Version Control**: Configuration changes tracked properly

### Migration from Static TypoScript

```php
// ❌ Old: Static TypoScript includes (TYPO3 12 and earlier)
Configuration/TCA/Overrides/sys_template.php:
<?php
\TYPO3\CMS\Core\Utility\ExtensionManagementUtility::addStaticFile(
    'extension_key',
    'Configuration/TypoScript',
    'Extension Name'
);
```

```yaml
# ✅ New: Site Sets (TYPO3 13+)
Configuration/Sets/ExtensionKey/config.yaml:
name: vendor/extension-key
label: Extension Name
```

**Site Sets Conformance Checklist:**
- [ ] Configuration/Sets/ directory exists
- [ ] At least one base set with config.yaml
- [ ] settings.definitions.yaml defines all extension settings
- [ ] Set names follow vendor/package naming convention
- [ ] Dependencies declared in config.yaml
- [ ] Labels use LLL: references for translations
- [ ] Settings have appropriate type validation

## Advanced Services.yaml Patterns

Beyond basic service registration, modern TYPO3 extensions use advanced Services.yaml patterns.

### Event Listeners

```yaml
# ✅ Right: Event listener registration
services:
  Vendor\ExtensionKey\EventListener\HrefLangEventListener:
    tags:
      - name: event.listener
        identifier: 'ext-extension-key/modify-hreflang'
        event: TYPO3\CMS\Frontend\Event\ModifyHrefLangTagsEvent
        method: '__invoke'

  # Multiple listeners for same event
  Vendor\ExtensionKey\EventListener\PageCacheListener:
    tags:
      - name: event.listener
        identifier: 'ext-extension-key/cache-before'
        event: TYPO3\CMS\Core\Cache\Event\BeforePageCacheIdentifierIsHashedEvent
      - name: event.listener
        identifier: 'ext-extension-key/cache-after'
        event: TYPO3\CMS\Core\Cache\Event\AfterPageCacheIdentifierIsHashedEvent
```

### Console Commands

```yaml
# ✅ Right: Console command registration
services:
  Vendor\ExtensionKey\Command\ProxyClassRebuildCommand:
    tags:
      - name: 'console.command'
        command: 'extension:rebuildProxyClasses'
        description: 'Rebuild Extbase proxy classes'
        schedulable: false  # Cannot be run via scheduler

  Vendor\ExtensionKey\Command\CleanupCommand:
    tags:
      - name: 'console.command'
        command: 'extension:cleanup'
        description: 'Clean up old records'
        schedulable: true  # Can be run via scheduler
        hidden: false      # Visible in command list
```

### Data Processors

```yaml
# ✅ Right: Data processor registration for Fluid templates
services:
  Vendor\ExtensionKey\DataProcessing\AddNewsToMenuProcessor:
    tags:
      - name: 'data.processor'
        identifier: 'add-news-to-menu'

  Vendor\ExtensionKey\DataProcessing\CategoryProcessor:
    tags:
      - name: 'data.processor'
        identifier: 'category-processor'
```

### Cache Services

```yaml
# ✅ Right: Cache service configuration
services:
  cache.extension_custom:
    class: TYPO3\CMS\Core\Cache\Frontend\VariableFrontend
    factory:
      - '@TYPO3\CMS\Core\Cache\CacheManager'
      - 'getCache'
    arguments:
      - 'extension_custom'
```

### Advanced Service Patterns

```yaml
# ✅ Right: Comprehensive Services.yaml with advanced patterns
services:
  _defaults:
    autowire: true
    autoconfigure: true
    public: false

  # Auto-register all classes
  Vendor\ExtensionKey\:
    resource: '../Classes/*'
    exclude:
      - '../Classes/Domain/Model/*'  # Exclude Extbase models

  # Event Listeners
  Vendor\ExtensionKey\EventListener\NewsListActionListener:
    tags:
      - name: event.listener
        identifier: 'ext-extension-key/news-list'
        event: Vendor\ExtensionKey\Event\NewsListActionEvent

  # Console Commands
  Vendor\ExtensionKey\Command\ImportCommand:
    tags:
      - name: 'console.command'
        command: 'news:import'
        description: 'Import news from external source'
        schedulable: true

  # Data Processors
  Vendor\ExtensionKey\DataProcessing\MenuProcessor:
    tags:
      - name: 'data.processor'
        identifier: 'news-menu-processor'

  # Cache Factory
  cache.news_category:
    class: TYPO3\CMS\Core\Cache\Frontend\VariableFrontend
    factory: ['@TYPO3\CMS\Core\Cache\CacheManager', 'getCache']
    arguments: ['news_category']

  # ViewHelper registration (if needed for testing)
  Vendor\ExtensionKey\ViewHelpers\FormatViewHelper:
    public: true
```

**Advanced Services.yaml Conformance Checklist:**
- [ ] Event listeners registered with proper tags
- [ ] Console commands tagged with schedulable flag
- [ ] Data processors registered with unique identifiers
- [ ] Cache services use factory pattern
- [ ] ViewHelpers marked public if needed externally
- [ ] Service tags include all required attributes (identifier, event, method)
- [ ] Commands have meaningful names and descriptions

## PSR-15 Middleware

### Middleware Structure

```php
// ✅ Right: PSR-15 middleware implementation
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Middleware;

use Psr\Http\Message\ResponseFactoryInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;

final class StatusCheckMiddleware implements MiddlewareInterface
{
    public function __construct(
        private readonly ResponseFactoryInterface $responseFactory
    ) {}

    public function process(
        ServerRequestInterface $request,
        RequestHandlerInterface $handler
    ): ResponseInterface {
        // Check for specific condition
        if (($request->getQueryParams()['status'] ?? null) === 'check') {
            $response = $this->responseFactory->createResponse(200, 'OK');
            $response->getBody()->write(json_encode([
                'status' => 'ok',
                'message' => 'System is healthy'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        }

        // Pass to next middleware
        return $handler->handle($request);
    }
}
```

### Middleware Registration

```php
// Configuration/RequestMiddlewares.php
<?php
return [
    'frontend' => [
        'vendor/extension-key/status-check' => [
            'target' => \Vendor\ExtensionKey\Middleware\StatusCheckMiddleware::class,
            'before' => [
                'typo3/cms-frontend/page-resolver',
            ],
            'after' => [
                'typo3/cms-core/normalized-params-attribute',
            ],
        ],
    ],
];
```

## Extbase Architecture

### Domain Models

```php
// ✅ Right: Extbase domain model
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Domain\Model;

use TYPO3\CMS\Extbase\DomainObject\AbstractEntity;

class Product extends AbstractEntity
{
    protected string $title = '';
    protected float $price = 0.0;
    protected bool $available = true;

    public function getTitle(): string
    {
        return $this->title;
    }

    public function setTitle(string $title): void
    {
        $this->title = $title;
    }

    public function getPrice(): float
    {
        return $this->price;
    }

    public function setPrice(float $price): void
    {
        $this->price = $price;
    }

    public function isAvailable(): bool
    {
        return $this->available;
    }

    public function setAvailable(bool $available): void
    {
        $this->available = $available;
    }
}
```

### Repositories

```php
// ✅ Right: Extbase repository with dependency injection
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Domain\Repository;

use TYPO3\CMS\Extbase\Persistence\Repository;
use Vendor\ExtensionKey\Domain\Model\Product;

class ProductRepository extends Repository
{
    /**
     * Find products by price range
     *
     * @param float $minPrice
     * @param float $maxPrice
     * @return array<Product>
     */
    public function findByPriceRange(float $minPrice, float $maxPrice): array
    {
        $query = $this->createQuery();
        $query->matching(
            $query->logicalAnd(
                $query->greaterThanOrEqual('price', $minPrice),
                $query->lessThanOrEqual('price', $maxPrice)
            )
        );
        return $query->execute()->toArray();
    }
}
```

### Controllers

```php
// ✅ Right: Extbase controller with dependency injection
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Controller;

use Psr\Http\Message\ResponseInterface;
use TYPO3\CMS\Extbase\Mvc\Controller\ActionController;
use Vendor\ExtensionKey\Domain\Repository\ProductRepository;

final class ProductController extends ActionController
{
    public function __construct(
        private readonly ProductRepository $productRepository
    ) {}

    public function listAction(): ResponseInterface
    {
        $products = $this->productRepository->findAll();
        $this->view->assign('products', $products);
        return $this->htmlResponse();
    }

    public function showAction(int $productId): ResponseInterface
    {
        $product = $this->productRepository->findByUid($productId);
        $this->view->assign('product', $product);
        return $this->htmlResponse();
    }
}
```

### Validators

```php
// ✅ Right: Extbase validator with dependency injection
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Domain\Validator;

use TYPO3\CMS\Extbase\Validation\Validator\AbstractValidator;
use Vendor\ExtensionKey\Domain\Repository\ProductRepository;

class UniqueProductTitleValidator extends AbstractValidator
{
    public function __construct(
        private readonly ProductRepository $productRepository
    ) {}

    protected function isValid(mixed $value): void
    {
        if (!is_string($value)) {
            $this->addError('Value must be a string', 1234567890);
            return;
        }

        $existingProduct = $this->productRepository->findOneByTitle($value);
        if ($existingProduct !== null) {
            $this->addError(
                'Product with title "%s" already exists',
                1234567891,
                [$value]
            );
        }
    }
}
```

## Common Patterns

### Factory Pattern

```php
// ✅ Right: Factory for Connection objects
services:
  Vendor\ExtensionKey\Domain\Repository\MyRepository:
    factory: ['@TYPO3\CMS\Core\Database\ConnectionPool', 'getConnectionForTable']
    arguments:
      - 'my_table'
```

### Singleton Services

```php
// ✅ Right: Use DI container, not Singleton pattern
// Services are automatically singleton by default

// ❌ Wrong: Don't use GeneralUtility::makeInstance() for new code
use TYPO3\CMS\Core\Utility\GeneralUtility;
$service = GeneralUtility::makeInstance(MyService::class);  // Deprecated
```

### PSR Interfaces

```php
// ✅ Right: Use PSR interfaces
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Client\ClientInterface;
use Psr\EventDispatcher\EventDispatcherInterface;
use Psr\Log\LoggerInterface;
use Psr\Clock\ClockInterface;

// Inject PSR-compliant services
public function __construct(
    private readonly LoggerInterface $logger,
    private readonly ClockInterface $clock
) {}
```

## Anti-Patterns to Avoid

### ❌ Wrong: Direct instantiation
```php
$repository = new ProductRepository();  // Missing dependencies
```

### ❌ Wrong: Using GeneralUtility::makeInstance()
```php
use TYPO3\CMS\Core\Utility\GeneralUtility;
$repository = GeneralUtility::makeInstance(ProductRepository::class);
```

### ❌ Wrong: Global state access
```php
$user = $GLOBALS['BE_USER'];  // Avoid global state
$typoScript = $GLOBALS['TSFE']->tmpl->setup;
```

### ✅ Right: Dependency injection
```php
public function __construct(
    private readonly ProductRepository $repository,
    private readonly Context $context
) {}
```

## PSR-17/PSR-18 HTTP Client Integration

TYPO3 provides HTTP client functionality through factory classes, not direct PSR interface aliases.

### Correct Pattern: Use TYPO3 Core Factories

```php
// ✅ Right: Inject TYPO3 Core factories
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Service;

use Psr\Http\Message\RequestInterface;
use TYPO3\CMS\Core\Http\RequestFactory;

final class ApiClientService
{
    public function __construct(
        private readonly RequestFactory $requestFactory,
    ) {}

    public function fetchData(string $url): array
    {
        $response = $this->requestFactory->request($url, 'GET', [
            'headers' => ['Accept' => 'application/json'],
        ]);

        return json_decode($response->getBody()->getContents(), true);
    }
}
```

### Services.yaml Configuration

```yaml
# ✅ Right: Use TYPO3 Core factories (no custom aliases needed)
services:
  Vendor\ExtensionKey\Service\ApiClientService:
    arguments:
      $requestFactory: '@TYPO3\CMS\Core\Http\RequestFactory'

# ❌ Wrong: Don't create custom PSR-17 interface aliases
# TYPO3 Core doesn't register these interfaces directly
# services:
#   Psr\Http\Message\RequestFactoryInterface:
#     class: GuzzleHttp\Psr7\HttpFactory
```

### Why This Matters

TYPO3 uses a **factory pattern** for HTTP client functionality:

| What You Need | Use This |
|---------------|----------|
| Create HTTP requests | `TYPO3\CMS\Core\Http\RequestFactory` |
| Create PSR-7 responses | `TYPO3\CMS\Core\Http\ResponseFactory` |
| Create streams | `TYPO3\CMS\Core\Http\StreamFactory` |
| Send HTTP requests | `RequestFactory::request()` method |

**Common Mistake:** Creating custom `Psr\Http\Message\RequestFactoryInterface` aliases in `Services.yaml` conflicts with TYPO3 Core's existing service definitions and causes container compilation errors.

### For Custom HTTP Client Wrappers

```php
// ✅ Right: Use TYPO3's GuzzleClientFactory for advanced configuration
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Service;

use GuzzleHttp\ClientInterface;
use TYPO3\CMS\Core\Http\Client\GuzzleClientFactory;

final class CustomHttpClient
{
    private ClientInterface $client;

    public function __construct(
        GuzzleClientFactory $clientFactory,
    ) {
        $this->client = $clientFactory->getClient([
            'timeout' => 30,
            'verify' => true,
            'headers' => [
                'User-Agent' => 'MyExtension/1.0',
            ],
        ]);
    }
}
```

## Conformance Checklist

### Basic Dependency Injection
- [ ] Constructor injection used for all dependencies
- [ ] Services registered in Configuration/Services.yaml
- [ ] No direct class instantiation (new MyClass())
- [ ] No GeneralUtility::makeInstance() for new services
- [ ] PSR interfaces used (ResponseInterface, LoggerInterface, etc.)
- [ ] No global state access ($GLOBALS)

### PSR-17/PSR-18 HTTP Client (Important)
- [ ] Use TYPO3\CMS\Core\Http\RequestFactory for HTTP requests
- [ ] No custom PSR-17 interface aliases in Services.yaml
- [ ] Use GuzzleClientFactory for custom client configuration

### PSR-14 Events (Mandatory)
- [ ] PSR-14 events used instead of hooks
- [ ] Event classes are immutable with proper getters/setters
- [ ] Event listeners use #[AsEventListener] attribute or Services.yaml tags
- [ ] Event classes use `final` keyword (TYPO3 13+)
- [ ] Event classes use `readonly` for immutable properties (TYPO3 13+)

### TYPO3 13 Site Sets (Mandatory for TYPO3 13)
- [ ] Configuration/Sets/ directory exists
- [ ] Base set has config.yaml with proper metadata
- [ ] settings.definitions.yaml defines extension settings with types
- [ ] Set names follow vendor/package convention
- [ ] Dependencies declared in config.yaml

### Advanced Services.yaml (Mandatory)
- [ ] Event listeners registered with proper tags
- [ ] Console commands tagged with schedulable flag
- [ ] Data processors registered with unique identifiers
- [ ] Cache services use factory pattern
- [ ] Service tags include all required attributes

### PSR-15 Middleware
- [ ] PSR-15 middlewares registered in RequestMiddlewares.php
- [ ] Middleware ordering defined with before/after

### Extbase Architecture
- [ ] Extbase models extend AbstractEntity
- [ ] Repositories extend Repository base class
- [ ] Controllers use constructor injection
- [ ] Validators extend AbstractValidator

### Factory Pattern
- [ ] Factory pattern for complex object creation (e.g., Connection objects)
