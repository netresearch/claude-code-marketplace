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

## Conformance Checklist

- [ ] Constructor injection used for all dependencies
- [ ] Services registered in Configuration/Services.yaml
- [ ] PSR-14 events used instead of hooks
- [ ] Event classes are immutable with proper getters/setters
- [ ] Event listeners use #[AsEventListener] attribute
- [ ] PSR-15 middlewares registered in RequestMiddlewares.php
- [ ] No direct class instantiation (new MyClass())
- [ ] No GeneralUtility::makeInstance() for new services
- [ ] Extbase models extend AbstractEntity
- [ ] Repositories extend Repository base class
- [ ] Controllers use constructor injection
- [ ] Validators extend AbstractValidator
- [ ] PSR interfaces used (ResponseInterface, LoggerInterface, etc.)
- [ ] No global state access ($GLOBALS)
- [ ] Factory pattern for complex object creation
