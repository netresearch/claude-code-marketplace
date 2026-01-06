# Multi-Tier Configuration Architecture

**Source:** nr_llm Extension - ADR-013 Three-Level Configuration Architecture
**Purpose:** Pattern for complex configuration hierarchies in TYPO3 extensions

## Overview

For extensions managing external services with multiple connections, credentials, and use-case-specific settings, a three-tier architecture provides clear separation of concerns.

## Architecture Pattern

```
┌─────────────────────────────────────────────────────────────┐
│ CONFIGURATION (use-case specific)                           │
│ "blog-summarizer", "product-description", "translator"      │
│ → model_uid, system_prompt, temperature, max_tokens         │
└──────────────────────────┬──────────────────────────────────┘
                           │ references
┌──────────────────────────▼──────────────────────────────────┐
│ MODEL / RESOURCE (available capabilities)                    │
│ "gpt-4o", "claude-sonnet", "large-index"                    │
│ → provider_uid, resource_id, capabilities, pricing          │
└──────────────────────────┬──────────────────────────────────┘
                           │ references
┌──────────────────────────▼──────────────────────────────────┐
│ PROVIDER (API connections)                                   │
│ "openai-prod", "openai-dev", "local-server"                 │
│ → endpoint, api_key (encrypted), adapter_type, timeout      │
└─────────────────────────────────────────────────────────────┘
```

## When to Use This Pattern

| Use Case | Example |
|----------|---------|
| Multiple API keys per service | Production/staging/development environments |
| Custom endpoints | Azure OpenAI, self-hosted services, proxies |
| Reusable resource definitions | Same model used in different configurations |
| Use-case-specific parameters | Different prompts/settings per feature |
| Cost tracking | Pricing information at resource level |

## Database Schema Pattern

### Provider Table

```sql
CREATE TABLE tx_myext_provider (
    uid int(11) NOT NULL auto_increment,
    pid int(11) DEFAULT '0' NOT NULL,

    -- Identification
    identifier varchar(100) DEFAULT '' NOT NULL,
    name varchar(255) DEFAULT '' NOT NULL,
    description text,

    -- Connection
    adapter_type varchar(50) DEFAULT '' NOT NULL,
    endpoint_url varchar(500) DEFAULT '' NOT NULL,
    api_key varchar(500) DEFAULT '' NOT NULL,  -- Encrypted!

    -- Settings
    timeout int(11) DEFAULT '30' NOT NULL,
    max_retries int(11) DEFAULT '3' NOT NULL,
    options text,  -- JSON for adapter-specific options

    -- Status
    is_active tinyint(1) DEFAULT '1' NOT NULL,

    -- TYPO3 standard fields
    sorting int(11) unsigned DEFAULT '0' NOT NULL,
    tstamp int(11) unsigned DEFAULT '0' NOT NULL,
    crdate int(11) unsigned DEFAULT '0' NOT NULL,
    deleted tinyint(4) unsigned DEFAULT '0' NOT NULL,
    hidden tinyint(4) unsigned DEFAULT '0' NOT NULL,

    PRIMARY KEY (uid),
    UNIQUE KEY identifier (identifier, deleted)
);
```

### Model/Resource Table

```sql
CREATE TABLE tx_myext_model (
    uid int(11) NOT NULL auto_increment,
    pid int(11) DEFAULT '0' NOT NULL,

    -- Identification
    identifier varchar(100) DEFAULT '' NOT NULL,
    name varchar(255) DEFAULT '' NOT NULL,
    description text,

    -- Provider relation
    provider_uid int(11) unsigned DEFAULT '0' NOT NULL,

    -- Resource specifics
    model_id varchar(150) DEFAULT '' NOT NULL,  -- API identifier
    capabilities text,  -- CSV: chat,vision,streaming

    -- Optional metadata
    context_length int(11) unsigned DEFAULT '0' NOT NULL,
    cost_input int(11) unsigned DEFAULT '0' NOT NULL,  -- cents per 1M
    cost_output int(11) unsigned DEFAULT '0' NOT NULL,

    -- Status
    is_active tinyint(1) DEFAULT '1' NOT NULL,
    is_default tinyint(1) DEFAULT '0' NOT NULL,

    -- TYPO3 standard fields...

    PRIMARY KEY (uid),
    KEY provider_uid (provider_uid)
);
```

### Configuration Table

```sql
CREATE TABLE tx_myext_configuration (
    uid int(11) NOT NULL auto_increment,
    pid int(11) DEFAULT '0' NOT NULL,

    -- Identification
    identifier varchar(100) DEFAULT '' NOT NULL,
    name varchar(255) DEFAULT '' NOT NULL,
    description text,

    -- Model relation
    model_uid int(11) unsigned DEFAULT '0' NOT NULL,

    -- Use-case settings
    system_prompt text,
    temperature float DEFAULT '0.7' NOT NULL,
    max_tokens int(11) DEFAULT '1000' NOT NULL,
    use_case_type varchar(50) DEFAULT 'general' NOT NULL,

    -- Status
    is_active tinyint(1) DEFAULT '1' NOT NULL,

    -- TYPO3 standard fields...

    PRIMARY KEY (uid),
    KEY model_uid (model_uid)
);
```

## Domain Model Pattern

### Provider Entity

```php
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Domain\Model;

use TYPO3\CMS\Extbase\DomainObject\AbstractEntity;

class Provider extends AbstractEntity
{
    public const ADAPTER_OPENAI = 'openai';
    public const ADAPTER_ANTHROPIC = 'anthropic';
    public const ADAPTER_CUSTOM = 'custom';

    protected string $identifier = '';
    protected string $name = '';
    protected string $adapterType = self::ADAPTER_OPENAI;
    protected string $endpointUrl = '';
    protected string $apiKey = '';  // Stored encrypted
    protected int $timeout = 30;
    protected bool $isActive = true;

    // Getters and setters...
}
```

### Model Entity with Provider Relation

```php
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Domain\Model;

use TYPO3\CMS\Extbase\DomainObject\AbstractEntity;

class Model extends AbstractEntity
{
    protected string $identifier = '';
    protected string $name = '';
    protected ?Provider $provider = null;
    protected string $modelId = '';
    protected string $capabilities = '';
    protected bool $isActive = true;
    protected bool $isDefault = false;

    public function getProvider(): ?Provider
    {
        return $this->provider;
    }

    /**
     * @return array<string>
     */
    public function getCapabilitiesArray(): array
    {
        return array_filter(explode(',', $this->capabilities));
    }

    public function hasCapability(string $capability): bool
    {
        return in_array($capability, $this->getCapabilitiesArray(), true);
    }
}
```

## Adapter Registry Pattern

Separate PHP "Adapter" classes (protocol handlers) from database "Provider" entities (connection instances):

```php
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Provider;

use Psr\Container\ContainerInterface;
use Vendor\ExtensionKey\Domain\Model\Model;
use Vendor\ExtensionKey\Domain\Model\Provider;

final class ProviderAdapterRegistry
{
    /**
     * Maps adapter_type to PHP implementation class
     */
    private const array ADAPTER_CLASS_MAP = [
        Provider::ADAPTER_OPENAI => OpenAiAdapter::class,
        Provider::ADAPTER_ANTHROPIC => AnthropicAdapter::class,
        Provider::ADAPTER_CUSTOM => CustomAdapter::class,
    ];

    public function __construct(
        private readonly ContainerInterface $container,
        private readonly ProviderEncryptionServiceInterface $encryptionService,
    ) {}

    /**
     * Create configured adapter from database Model entity
     */
    public function createAdapterFromModel(Model $model): AdapterInterface
    {
        $provider = $model->getProvider();
        if ($provider === null) {
            throw new \InvalidArgumentException('Model has no provider');
        }

        $adapterClass = self::ADAPTER_CLASS_MAP[$provider->getAdapterType()]
            ?? throw new \InvalidArgumentException(
                sprintf('Unknown adapter type: %s', $provider->getAdapterType())
            );

        /** @var AdapterInterface $adapter */
        $adapter = $this->container->get($adapterClass);

        // Configure adapter with provider settings
        $adapter->configure([
            'endpoint' => $provider->getEndpointUrl(),
            'apiKey' => $this->encryptionService->decrypt($provider->getApiKey()),
            'timeout' => $provider->getTimeout(),
            'model' => $model->getModelId(),
        ]);

        return $adapter;
    }
}
```

## TCA Configuration Pattern

### Provider TCA

```php
<?php
return [
    'ctrl' => [
        'title' => 'Provider',
        'label' => 'name',
        'iconfile' => 'EXT:my_ext/Resources/Public/Icons/Provider.svg',
        // ...
    ],
    'columns' => [
        'adapter_type' => [
            'label' => 'Adapter Type',
            'config' => [
                'type' => 'select',
                'renderType' => 'selectSingle',
                'items' => [
                    ['label' => 'OpenAI', 'value' => 'openai'],
                    ['label' => 'Anthropic', 'value' => 'anthropic'],
                    ['label' => 'Custom', 'value' => 'custom'],
                ],
            ],
        ],
        'api_key' => [
            'label' => 'API Key',
            'config' => [
                'type' => 'password',
                'fieldControl' => [
                    'passwordGenerator' => ['renderType' => 'passwordGenerator'],
                ],
            ],
        ],
    ],
];
```

## Benefits

| Benefit | Description |
|---------|-------------|
| **Multiple credentials** | Separate prod/dev/backup API keys |
| **Custom endpoints** | Azure OpenAI, self-hosted, proxies |
| **Reusable resources** | Same model in different configurations |
| **Clear separation** | Connection vs capability vs use-case |
| **Cost tracking** | Pricing at resource level |
| **Testability** | Swap providers in tests |

## Conformance Checklist

- [ ] Provider table stores encrypted API keys
- [ ] Model/Resource table references Provider
- [ ] Configuration table references Model
- [ ] Adapter registry maps types to classes
- [ ] Relations use proper Extbase mapping
- [ ] TCA provides select fields for relations

## Related References

- `php-architecture.md` - Dependency injection patterns
- `extension-architecture.md` - Directory structure
- Security Audit Skill - `api-key-encryption.md`
