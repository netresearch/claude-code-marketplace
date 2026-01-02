# Adapter Registry Pattern

**Source:** nr_llm Extension - ProviderAdapterRegistry
**Purpose:** Dynamic adapter instantiation from database configuration

## Overview

The Adapter Registry pattern separates PHP implementation classes (Adapters) from database configuration records (Providers/Entities). This allows runtime selection of implementation based on database configuration.

## When to Use

- Integrating with multiple external services (APIs, SDKs)
- Supporting multiple implementations of the same interface
- Dynamic provider selection based on database configuration
- Clean separation between protocol logic and connection credentials

## Terminology

| Term | Description | Example |
|------|-------------|---------|
| **Adapter** | PHP class implementing protocol | `OpenAiAdapter`, `AnthropicAdapter` |
| **Provider** | Database entity with credentials | Row in `tx_ext_provider` table |
| **Registry** | Maps provider type to adapter class | `ProviderAdapterRegistry` |

## Pattern Structure

```
┌─────────────────────────────────────────────────────────────┐
│ ProviderAdapterRegistry                                      │
│ ─────────────────────────                                   │
│ Maps adapter_type string → PHP Adapter class                │
│ Creates configured adapter instances from Provider entities │
└──────────────────────────┬──────────────────────────────────┘
                           │ creates
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ AdapterInterface                                             │
│ ─────────────────                                           │
│ Common contract for all adapters                            │
│ configure(), execute(), etc.                                │
└─────────────────────────────────────────────────────────────┘
           ▲                    ▲                    ▲
           │                    │                    │
┌──────────┴─────┐  ┌──────────┴─────┐  ┌──────────┴─────┐
│ OpenAiAdapter  │  │AnthropicAdapter│  │ CustomAdapter  │
│                │  │                │  │                │
│ adapter_type:  │  │ adapter_type:  │  │ adapter_type:  │
│ "openai"       │  │ "anthropic"    │  │ "custom"       │
└────────────────┘  └────────────────┘  └────────────────┘
```

## Implementation

### Adapter Interface

```php
<?php
declare(strict_types=1);

namespace Vendor\Extension\Provider;

interface AdapterInterface
{
    /**
     * Configure adapter with provider settings
     *
     * @param array<string, mixed> $config
     */
    public function configure(array $config): void;

    /**
     * Check if adapter supports a capability
     */
    public function supports(string $capability): bool;
}
```

### Concrete Adapter

```php
<?php
declare(strict_types=1);

namespace Vendor\Extension\Provider\Adapter;

use Vendor\Extension\Provider\AdapterInterface;
use TYPO3\CMS\Core\Http\RequestFactory;

final class OpenAiAdapter implements AdapterInterface
{
    private string $endpoint = 'https://api.openai.com/v1';
    private string $apiKey = '';
    private string $model = 'gpt-4o';
    private int $timeout = 30;

    public function __construct(
        private readonly RequestFactory $requestFactory,
    ) {}

    public function configure(array $config): void
    {
        if (isset($config['endpoint']) && $config['endpoint'] !== '') {
            $this->endpoint = rtrim($config['endpoint'], '/');
        }
        $this->apiKey = $config['apiKey'] ?? '';
        $this->model = $config['model'] ?? 'gpt-4o';
        $this->timeout = (int)($config['timeout'] ?? 30);
    }

    public function supports(string $capability): bool
    {
        return in_array($capability, ['chat', 'completion', 'embedding', 'vision'], true);
    }

    /**
     * @param array<int, array{role: string, content: string}> $messages
     * @return array<string, mixed>
     */
    public function chat(array $messages): array
    {
        $response = $this->requestFactory->request(
            $this->endpoint . '/chat/completions',
            'POST',
            [
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->apiKey,
                    'Content-Type' => 'application/json',
                ],
                'json' => [
                    'model' => $this->model,
                    'messages' => $messages,
                ],
                'timeout' => $this->timeout,
            ]
        );

        return json_decode($response->getBody()->getContents(), true);
    }
}
```

### Provider Entity (Database Record)

```php
<?php
declare(strict_types=1);

namespace Vendor\Extension\Domain\Model;

use TYPO3\CMS\Extbase\DomainObject\AbstractEntity;

class Provider extends AbstractEntity
{
    public const ADAPTER_OPENAI = 'openai';
    public const ADAPTER_ANTHROPIC = 'anthropic';
    public const ADAPTER_GEMINI = 'gemini';
    public const ADAPTER_CUSTOM = 'custom';

    protected string $identifier = '';
    protected string $name = '';
    protected string $adapterType = self::ADAPTER_OPENAI;
    protected string $endpointUrl = '';
    protected string $apiKey = '';  // Stored encrypted
    protected int $timeout = 30;
    protected bool $isActive = true;

    public function getAdapterType(): string
    {
        return $this->adapterType;
    }

    public function getEndpointUrl(): string
    {
        return $this->endpointUrl;
    }

    public function getApiKey(): string
    {
        return $this->apiKey;
    }

    public function getTimeout(): int
    {
        return $this->timeout;
    }
}
```

### Registry Implementation

```php
<?php
declare(strict_types=1);

namespace Vendor\Extension\Provider;

use Psr\Container\ContainerInterface;
use Vendor\Extension\Domain\Model\Model;
use Vendor\Extension\Domain\Model\Provider;
use Vendor\Extension\Provider\Adapter\AnthropicAdapter;
use Vendor\Extension\Provider\Adapter\CustomAdapter;
use Vendor\Extension\Provider\Adapter\GeminiAdapter;
use Vendor\Extension\Provider\Adapter\OpenAiAdapter;
use Vendor\Extension\Security\ProviderEncryptionServiceInterface;

final class ProviderAdapterRegistry
{
    /**
     * Maps adapter_type string to PHP adapter class
     *
     * @var array<string, class-string<AdapterInterface>>
     */
    private const array ADAPTER_MAP = [
        Provider::ADAPTER_OPENAI => OpenAiAdapter::class,
        Provider::ADAPTER_ANTHROPIC => AnthropicAdapter::class,
        Provider::ADAPTER_GEMINI => GeminiAdapter::class,
        Provider::ADAPTER_CUSTOM => CustomAdapter::class,
    ];

    public function __construct(
        private readonly ContainerInterface $container,
        private readonly ProviderEncryptionServiceInterface $encryptionService,
    ) {}

    /**
     * Get list of available adapter types
     *
     * @return array<string>
     */
    public function getAvailableAdapterTypes(): array
    {
        return array_keys(self::ADAPTER_MAP);
    }

    /**
     * Check if adapter type is supported
     */
    public function hasAdapterType(string $adapterType): bool
    {
        return isset(self::ADAPTER_MAP[$adapterType]);
    }

    /**
     * Create adapter instance from Provider entity
     *
     * @throws \InvalidArgumentException If adapter type unknown
     */
    public function createAdapterFromProvider(Provider $provider): AdapterInterface
    {
        $adapterClass = self::ADAPTER_MAP[$provider->getAdapterType()]
            ?? throw new \InvalidArgumentException(
                sprintf('Unknown adapter type: %s', $provider->getAdapterType())
            );

        /** @var AdapterInterface $adapter */
        $adapter = $this->container->get($adapterClass);

        $adapter->configure([
            'endpoint' => $provider->getEndpointUrl(),
            'apiKey' => $this->encryptionService->decrypt($provider->getApiKey()),
            'timeout' => $provider->getTimeout(),
        ]);

        return $adapter;
    }

    /**
     * Create adapter from Model entity (which has Provider relation)
     *
     * @throws \InvalidArgumentException If model has no provider
     */
    public function createAdapterFromModel(Model $model): AdapterInterface
    {
        $provider = $model->getProvider();
        if ($provider === null) {
            throw new \InvalidArgumentException(
                sprintf('Model "%s" has no provider assigned', $model->getName())
            );
        }

        $adapter = $this->createAdapterFromProvider($provider);

        // Configure with model-specific settings
        $adapter->configure([
            'model' => $model->getModelId(),
        ]);

        return $adapter;
    }
}
```

### Services.yaml Configuration

```yaml
services:
  _defaults:
    autowire: true
    autoconfigure: true
    public: false

  Vendor\Extension\Provider\ProviderAdapterRegistry:
    public: true

  # Register all adapters
  Vendor\Extension\Provider\Adapter\OpenAiAdapter: ~
  Vendor\Extension\Provider\Adapter\AnthropicAdapter: ~
  Vendor\Extension\Provider\Adapter\GeminiAdapter: ~
  Vendor\Extension\Provider\Adapter\CustomAdapter: ~
```

## Usage Examples

### In a Service Class

```php
<?php
declare(strict_types=1);

namespace Vendor\Extension\Service;

use Vendor\Extension\Domain\Repository\ConfigurationRepository;
use Vendor\Extension\Provider\ProviderAdapterRegistry;

final class LlmService
{
    public function __construct(
        private readonly ConfigurationRepository $configurationRepository,
        private readonly ProviderAdapterRegistry $adapterRegistry,
    ) {}

    /**
     * @param array<int, array{role: string, content: string}> $messages
     * @return array<string, mixed>
     */
    public function chat(string $configurationIdentifier, array $messages): array
    {
        $config = $this->configurationRepository->findByIdentifier($configurationIdentifier);
        if ($config === null) {
            throw new \InvalidArgumentException('Configuration not found: ' . $configurationIdentifier);
        }

        $adapter = $this->adapterRegistry->createAdapterFromModel($config->getModel());

        return $adapter->chat($messages);
    }
}
```

### In a Controller

```php
<?php
declare(strict_types=1);

namespace Vendor\Extension\Controller\Backend;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Core\Http\JsonResponse;
use Vendor\Extension\Domain\Repository\ProviderRepository;
use Vendor\Extension\Provider\ProviderAdapterRegistry;

final class ProviderController
{
    public function __construct(
        private readonly ProviderRepository $providerRepository,
        private readonly ProviderAdapterRegistry $adapterRegistry,
    ) {}

    public function testConnectionAction(ServerRequestInterface $request): ResponseInterface
    {
        $providerUid = (int)($request->getParsedBody()['provider'] ?? 0);
        $provider = $this->providerRepository->findByUid($providerUid);

        if ($provider === null) {
            return new JsonResponse(['success' => false, 'message' => 'Provider not found'], 404);
        }

        try {
            $adapter = $this->adapterRegistry->createAdapterFromProvider($provider);
            // Perform a lightweight API call to verify connection
            $result = $adapter->testConnection();

            return new JsonResponse([
                'success' => true,
                'message' => 'Connection successful',
                'models' => $result['models'] ?? [],
            ]);
        } catch (\Exception $e) {
            return new JsonResponse([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        }
    }
}
```

## Extending with New Adapters

### 1. Create Adapter Class

```php
<?php
declare(strict_types=1);

namespace Vendor\Extension\Provider\Adapter;

use Vendor\Extension\Provider\AdapterInterface;

final class MistralAdapter implements AdapterInterface
{
    // Implement interface...
}
```

### 2. Add to Provider Constants

```php
// In Provider entity
public const ADAPTER_MISTRAL = 'mistral';
```

### 3. Update Registry Map

```php
// In ProviderAdapterRegistry
private const array ADAPTER_MAP = [
    // ... existing adapters
    Provider::ADAPTER_MISTRAL => MistralAdapter::class,
];
```

### 4. Register in Services.yaml

```yaml
Vendor\Extension\Provider\Adapter\MistralAdapter: ~
```

### 5. Update TCA Select Items

```php
// In TCA for tx_ext_provider
'adapter_type' => [
    'config' => [
        'type' => 'select',
        'renderType' => 'selectSingle',
        'items' => [
            // ... existing items
            ['label' => 'Mistral', 'value' => 'mistral'],
        ],
    ],
],
```

## Benefits

| Benefit | Description |
|---------|-------------|
| **Separation of Concerns** | Protocol logic separate from configuration |
| **Runtime Flexibility** | Select implementation via database config |
| **Testability** | Mock adapters easily in tests |
| **Extensibility** | Add new adapters without changing existing code |
| **Type Safety** | Interface ensures consistent API across adapters |

## Testing

```php
<?php
declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\Provider;

use PHPUnit\Framework\TestCase;
use Psr\Container\ContainerInterface;
use Vendor\Extension\Domain\Model\Provider;
use Vendor\Extension\Provider\Adapter\OpenAiAdapter;
use Vendor\Extension\Provider\ProviderAdapterRegistry;
use Vendor\Extension\Security\ProviderEncryptionServiceInterface;

final class ProviderAdapterRegistryTest extends TestCase
{
    public function testCreatesCorrectAdapterForProviderType(): void
    {
        $mockAdapter = $this->createMock(OpenAiAdapter::class);

        $container = $this->createMock(ContainerInterface::class);
        $container->method('get')
            ->with(OpenAiAdapter::class)
            ->willReturn($mockAdapter);

        $encryption = $this->createMock(ProviderEncryptionServiceInterface::class);
        $encryption->method('decrypt')
            ->with('encrypted-key')
            ->willReturn('decrypted-key');

        $registry = new ProviderAdapterRegistry($container, $encryption);

        $provider = new Provider();
        $provider->_setProperty('adapterType', 'openai');
        $provider->_setProperty('apiKey', 'encrypted-key');

        $adapter = $registry->createAdapterFromProvider($provider);

        self::assertInstanceOf(OpenAiAdapter::class, $adapter);
    }

    public function testThrowsExceptionForUnknownAdapterType(): void
    {
        $container = $this->createMock(ContainerInterface::class);
        $encryption = $this->createMock(ProviderEncryptionServiceInterface::class);

        $registry = new ProviderAdapterRegistry($container, $encryption);

        $provider = new Provider();
        $provider->_setProperty('adapterType', 'unknown');

        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Unknown adapter type: unknown');

        $registry->createAdapterFromProvider($provider);
    }
}
```

## Related Patterns

- **Strategy Pattern**: Adapters implement the Strategy pattern
- **Factory Pattern**: Registry acts as a factory for adapters
- **Dependency Injection**: Adapters created via DI container

## Related References

- `symfony-patterns.md` - Dependency injection patterns
- `type-safety.md` - Interface and type declarations
- Security Audit Skill - `api-key-encryption.md` for credential handling
