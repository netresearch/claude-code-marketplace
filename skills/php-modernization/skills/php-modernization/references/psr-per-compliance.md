# PSR and PER Compliance

This reference covers **active** PHP-FIG standards. All modern PHP code should follow these interoperability recommendations.

> **Source of truth:** https://www.php-fig.org/psr/ and https://www.php-fig.org/per/

## Active PSRs (PHP Standard Recommendations)

### PSR-1: Basic Coding Standard

**Status:** Active | **Required**

Basic coding standards for PHP code interoperability.

```php
<?php

declare(strict_types=1);

namespace Vendor\Package;

// Class names: StudlyCaps
class MyService
{
    // Constants: UPPER_CASE with underscores
    public const VERSION = '1.0.0';

    // Methods: camelCase
    public function doSomething(): void
    {
        // ...
    }
}
```

**Key requirements:**
- Files MUST use only `<?php` and `<?=` tags
- Files MUST use only UTF-8 without BOM
- Class names MUST be declared in `StudlyCaps`
- Class constants MUST be declared in `UPPER_CASE`
- Method names MUST be declared in `camelCase`

### PSR-3: Logger Interface

**Status:** Active | **Use when logging**

```php
use Psr\Log\LoggerInterface;

final class PaymentService
{
    public function __construct(
        private readonly LoggerInterface $logger,
    ) {}

    public function process(Payment $payment): void
    {
        $this->logger->info('Processing payment', [
            'payment_id' => $payment->getId(),
            'amount' => $payment->getAmount(),
        ]);
    }
}
```

**Log levels:** emergency, alert, critical, error, warning, notice, info, debug

### PSR-4: Autoloading Standard

**Status:** Active | **Required**

Maps namespaces to filesystem paths.

```json
{
    "autoload": {
        "psr-4": {
            "App\\": "src/",
            "App\\Tests\\": "tests/"
        }
    }
}
```

**File path mapping:**
- `App\Entity\User` → `src/Entity/User.php`
- `App\Tests\Unit\UserTest` → `tests/Unit/UserTest.php`

### PSR-6: Caching Interface

**Status:** Active | **Use for object caching**

```php
use Psr\Cache\CacheItemPoolInterface;

final class UserRepository
{
    public function __construct(
        private readonly CacheItemPoolInterface $cache,
    ) {}

    public function findById(int $id): ?User
    {
        $item = $this->cache->getItem("user_{$id}");

        if ($item->isHit()) {
            return $item->get();
        }

        $user = $this->fetchFromDatabase($id);

        $item->set($user);
        $item->expiresAfter(3600);
        $this->cache->save($item);

        return $user;
    }
}
```

### PSR-7: HTTP Message Interface

**Status:** Active | **Use for HTTP messages**

Immutable request/response objects.

```php
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

// Requests are immutable - with* methods return new instances
$request = $requestFactory->createRequest('GET', 'https://api.example.com/users');
$request = $request
    ->withHeader('Authorization', 'Bearer ' . $token)
    ->withHeader('Accept', 'application/json');

// Responses are also immutable
$response = $response
    ->withStatus(200)
    ->withHeader('Content-Type', 'application/json');
```

### PSR-11: Container Interface

**Status:** Active | **Use for dependency injection**

```php
use Psr\Container\ContainerInterface;

// Type-hint against the interface
final class ServiceLocator
{
    public function __construct(
        private readonly ContainerInterface $container,
    ) {}

    public function get(string $id): object
    {
        if (!$this->container->has($id)) {
            throw new ServiceNotFoundException($id);
        }

        return $this->container->get($id);
    }
}
```

### PSR-12: Extended Coding Style Guide

**Status:** Active | **Superseded by PER Coding Style for new projects**

Extended coding style guide building on PSR-1. For new projects, use **PER Coding Style** instead.

### PSR-13: Hypermedia Links

**Status:** Active | **Use for HATEOAS**

```php
use Psr\Link\LinkInterface;
use Psr\Link\EvolvableLinkProviderInterface;

// Implement for resources with hypermedia links
final class UserResource implements EvolvableLinkProviderInterface
{
    // ...
}
```

### PSR-14: Event Dispatcher

**Status:** Active | **Required for events**

```php
use Psr\EventDispatcher\EventDispatcherInterface;
use Psr\EventDispatcher\StoppableEventInterface;

// Event class
final class UserRegisteredEvent implements StoppableEventInterface
{
    private bool $propagationStopped = false;

    public function __construct(
        public readonly User $user,
    ) {}

    public function isPropagationStopped(): bool
    {
        return $this->propagationStopped;
    }

    public function stopPropagation(): void
    {
        $this->propagationStopped = true;
    }
}

// Dispatch events
final class UserService
{
    public function __construct(
        private readonly EventDispatcherInterface $dispatcher,
    ) {}

    public function register(User $user): void
    {
        // ... create user
        $this->dispatcher->dispatch(new UserRegisteredEvent($user));
    }
}
```

### PSR-15: HTTP Handlers

**Status:** Active | **Required for HTTP middleware**

```php
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;

// Middleware
final class AuthenticationMiddleware implements MiddlewareInterface
{
    public function process(
        ServerRequestInterface $request,
        RequestHandlerInterface $handler,
    ): ResponseInterface {
        $token = $request->getHeaderLine('Authorization');

        if (!$this->isValidToken($token)) {
            return new Response(401);
        }

        return $handler->handle($request);
    }
}

// Request handler
final class UserController implements RequestHandlerInterface
{
    public function handle(ServerRequestInterface $request): ResponseInterface
    {
        // Handle the request
        return new JsonResponse(['users' => $this->getUsers()]);
    }
}
```

### PSR-16: Simple Cache

**Status:** Active | **Use for simple key-value caching**

```php
use Psr\SimpleCache\CacheInterface;

final class ConfigCache
{
    public function __construct(
        private readonly CacheInterface $cache,
    ) {}

    public function get(string $key, mixed $default = null): mixed
    {
        return $this->cache->get($key, $default);
    }

    public function set(string $key, mixed $value, int $ttl = 3600): bool
    {
        return $this->cache->set($key, $value, $ttl);
    }
}
```

### PSR-17: HTTP Factories

**Status:** Active | **Required when creating HTTP messages**

Use factories to create PSR-7 message objects.

```php
use Psr\Http\Message\RequestFactoryInterface;
use Psr\Http\Message\StreamFactoryInterface;
use Psr\Http\Message\UriFactoryInterface;

final class ApiClient
{
    public function __construct(
        private readonly RequestFactoryInterface $requestFactory,
        private readonly StreamFactoryInterface $streamFactory,
        private readonly UriFactoryInterface $uriFactory,
    ) {}

    public function createRequest(string $method, string $uri): RequestInterface
    {
        return $this->requestFactory->createRequest(
            $method,
            $this->uriFactory->createUri($uri),
        );
    }

    public function createJsonBody(array $data): StreamInterface
    {
        return $this->streamFactory->createStream(
            json_encode($data, JSON_THROW_ON_ERROR),
        );
    }
}
```

### PSR-18: HTTP Client

**Status:** Active | **Required for HTTP clients**

Minimal interface: only `sendRequest()`.

```php
use Psr\Http\Client\ClientInterface;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

// Implement the interface
final class HttpClient implements ClientInterface
{
    public function sendRequest(RequestInterface $request): ResponseInterface
    {
        // Send the request and return response
    }
}

// Type-hint against the interface
final class ApiService
{
    public function __construct(
        private readonly ClientInterface $httpClient,
        private readonly RequestFactoryInterface $requestFactory,
    ) {}

    public function fetchData(string $endpoint): array
    {
        $request = $this->requestFactory->createRequest('GET', $endpoint);
        $response = $this->httpClient->sendRequest($request);

        return json_decode(
            $response->getBody()->getContents(),
            true,
            512,
            JSON_THROW_ON_ERROR,
        );
    }
}
```

**Important:** PSR-18 is intentionally minimal. Request building (PSR-17) is separate from sending (PSR-18). Do NOT add convenience methods like `get()`, `post()` to PSR-18 implementations.

### PSR-20: Clock

**Status:** Active | **Required for time-dependent code**

```php
use Psr\Clock\ClockInterface;

final class TokenValidator
{
    public function __construct(
        private readonly ClockInterface $clock,
    ) {}

    public function isExpired(Token $token): bool
    {
        return $token->getExpiresAt() < $this->clock->now();
    }
}

// In production: inject SystemClock
// In tests: inject FrozenClock for deterministic tests
```

## Active PERs (PHP Evolving Recommendations)

### PER Coding Style

**Status:** Active | **Required for new projects**

Evolves PSR-12 with modern PHP features. This is the current coding style standard.

> **Note:** Use `@PER-CS` in PHP-CS-Fixer (alias for latest version). Avoid deprecated version-specific rulesets like `@PER-CS2.0` - use `@PER-CS2x0` syntax if pinning is required.

```php
<?php

declare(strict_types=1);

namespace Vendor\Package;

use DateTimeImmutable;
use Psr\Log\LoggerInterface;

final readonly class UserService
{
    public function __construct(
        private LoggerInterface $logger,
        private UserRepository $repository,
    ) {}

    public function findActiveUsers(
        DateTimeImmutable $since,
        int $limit = 100,
    ): array {
        return match (true) {
            $limit < 1 => throw new InvalidArgumentException('Limit must be positive'),
            $limit > 1000 => $this->repository->findActivePaginated($since, $limit),
            default => $this->repository->findActive($since, $limit),
        };
    }
}
```

**Key additions over PSR-12:**
- Constructor property promotion formatting
- Named arguments formatting
- Match expressions
- Enums
- Readonly classes and properties
- Intersection types
- Trailing commas in parameters

## Compliance Checklist

### Required for All PHP Projects

- [ ] **PSR-1**: Basic coding standard (class/method naming)
- [ ] **PSR-4**: Autoloading (composer.json autoload config)
- [ ] **PER Coding Style**: Modern coding style

### Required When Using These Features

- [ ] **PSR-3**: When implementing logging
- [ ] **PSR-6/PSR-16**: When implementing caching
- [ ] **PSR-7/PSR-17/PSR-18**: When handling HTTP messages/clients
- [ ] **PSR-11**: When implementing dependency injection containers
- [ ] **PSR-14**: When implementing event dispatching
- [ ] **PSR-15**: When implementing HTTP middleware
- [ ] **PSR-20**: When working with time-dependent code

## Enforcement Tools

### PHP-CS-Fixer

```php
// .php-cs-fixer.dist.php
return (new PhpCsFixer\Config())
    ->setRules([
        '@PER-CS' => true,        // Alias for latest PER Coding Style
        '@PER-CS:risky' => true,
        'declare_strict_types' => true,
    ])
    ->setRiskyAllowed(true)
    ->setFinder(
        PhpCsFixer\Finder::create()
            ->in(__DIR__ . '/src')
            ->in(__DIR__ . '/tests')
    );
```

> **Ruleset naming:** Use `@PER-CS` for latest. For version pinning, use `@PER-CS3x0` (not `@PER-CS3.0` which is deprecated).

### PHPStan

```neon
# phpstan.neon
parameters:
    level: max

includes:
    # Check PSR compliance through extensions
    - vendor/phpstan/phpstan-strict-rules/rules.neon
```

## Common Anti-Patterns

### Extending PSR-18 with Convenience Methods

```php
// BAD: Violates PSR-18's minimal interface principle
interface MyHttpClient extends ClientInterface
{
    public function get(string $uri): ResponseInterface;
    public function post(string $uri, array $data): ResponseInterface;
}

// GOOD: Keep PSR-18 minimal, use composition
final class ApiClient
{
    public function __construct(
        private readonly ClientInterface $client,
        private readonly RequestFactoryInterface $requestFactory,
    ) {}

    public function get(string $uri): ResponseInterface
    {
        return $this->client->sendRequest(
            $this->requestFactory->createRequest('GET', $uri),
        );
    }
}
```

### Ignoring PSR-4 Structure

```php
// BAD: Class location doesn't match namespace
// File: src/helpers/user_helper.php
namespace App\Helpers;
class UserHelper {}  // Should be in src/Helpers/UserHelper.php

// GOOD: File path matches namespace
// File: src/Helpers/UserHelper.php
namespace App\Helpers;
class UserHelper {}
```

### Not Using PSR Interfaces for Type Hints

```php
// BAD: Coupling to implementation
public function __construct(
    private readonly GuzzleClient $client,
) {}

// GOOD: Type-hint against PSR interface
public function __construct(
    private readonly ClientInterface $client,
) {}
```
