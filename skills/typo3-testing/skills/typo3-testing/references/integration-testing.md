# Integration Testing for TYPO3 Extensions

Integration tests verify interactions between components with realistic (but mocked) external dependencies.

## Integration vs Functional vs E2E

| Type | Database | External APIs | TYPO3 Framework | Speed |
|------|----------|---------------|-----------------|-------|
| **Unit** | No | No | No | Fast (ms) |
| **Integration** | No | Mocked | Partial | Medium (ms) |
| **Functional** | Yes | No | Full | Slow (s) |
| **E2E** | Yes | Real/Mocked | Full + Browser | Slowest (s-min) |

**Integration tests** fill the gap between unit tests (isolated) and functional tests (full framework):
- Test component interactions
- Mock external APIs (HTTP, LDAP, OAuth)
- Verify request/response handling
- Test without database overhead

## Directory Structure

```
Tests/
├── Unit/
├── Integration/
│   ├── AbstractIntegrationTestCase.php
│   ├── Service/
│   │   └── ApiServiceIntegrationTest.php
│   └── Provider/
│       └── OAuthProviderIntegrationTest.php
└── Functional/
```

## Base Test Case

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Integration;

use GuzzleHttp\Psr7\HttpFactory;
use GuzzleHttp\Psr7\Response;
use PHPUnit\Framework\MockObject\Stub;
use PHPUnit\Framework\TestCase;
use Psr\Http\Client\ClientInterface;
use Psr\Http\Message\RequestFactoryInterface;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamFactoryInterface;

/**
 * Base class for integration tests.
 *
 * Provides utilities for testing API interactions
 * with realistic HTTP responses.
 */
abstract class AbstractIntegrationTestCase extends TestCase
{
    protected RequestFactoryInterface $requestFactory;
    protected StreamFactoryInterface $streamFactory;

    protected function setUp(): void
    {
        parent::setUp();
        $this->requestFactory = new HttpFactory();
        $this->streamFactory = new HttpFactory();
    }

    /**
     * Create an HTTP client stub that returns sequential responses.
     *
     * @param list<ResponseInterface> $responses
     */
    protected function createHttpClientWithResponses(array $responses): ClientInterface&Stub
    {
        $client = self::createStub(ClientInterface::class);
        $client->method('sendRequest')
            ->willReturnOnConsecutiveCalls(...$responses);

        return $client;
    }

    /**
     * Create a successful JSON response.
     *
     * @param array<string, mixed> $body
     */
    protected function createSuccessResponse(array $body, int $statusCode = 200): ResponseInterface
    {
        return new Response(
            status: $statusCode,
            headers: ['Content-Type' => 'application/json'],
            body: \json_encode($body, JSON_THROW_ON_ERROR),
        );
    }

    /**
     * Create an error response.
     *
     * @param array<string, mixed> $body
     */
    protected function createErrorResponse(array $body, int $statusCode = 400): ResponseInterface
    {
        return new Response(
            status: $statusCode,
            headers: ['Content-Type' => 'application/json'],
            body: \json_encode($body, JSON_THROW_ON_ERROR),
        );
    }

    /**
     * Create a stub HTTP client that captures request bodies.
     *
     * @return array{client: ClientInterface&Stub, requests: array<RequestInterface>}
     */
    protected function createRequestCapturingClient(ResponseInterface $response): array
    {
        $requests = [];
        $client = self::createStub(ClientInterface::class);
        $client->method('sendRequest')
            ->willReturnCallback(function (RequestInterface $request) use ($response, &$requests) {
                $requests[] = $request;
                return $response;
            });

        return ['client' => $client, 'requests' => &$requests];
    }
}
```

## Integration Test Examples

### API Service Integration

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Integration\Service;

use Vendor\Extension\Service\ExternalApiService;
use Vendor\Extension\Tests\Integration\AbstractIntegrationTestCase;

final class ExternalApiServiceIntegrationTest extends AbstractIntegrationTestCase
{
    /**
     * @test
     */
    public function fetchDataReturnsDeserializedResponse(): void
    {
        // Arrange: Mock HTTP client with expected response
        $expectedData = [
            'items' => [
                ['id' => 1, 'name' => 'Item 1'],
                ['id' => 2, 'name' => 'Item 2'],
            ],
            'total' => 2,
        ];

        $client = $this->createHttpClientWithResponses([
            $this->createSuccessResponse($expectedData),
        ]);

        $service = new ExternalApiService(
            httpClient: $client,
            requestFactory: $this->requestFactory,
        );

        // Act
        $result = $service->fetchItems();

        // Assert
        self::assertCount(2, $result->getItems());
        self::assertSame(2, $result->getTotal());
    }

    /**
     * @test
     */
    public function fetchDataHandlesRateLimitWithRetry(): void
    {
        // Arrange: First request fails with 429, second succeeds
        $client = $this->createHttpClientWithResponses([
            $this->createErrorResponse(['error' => 'Rate limit exceeded'], 429),
            $this->createSuccessResponse(['items' => [], 'total' => 0]),
        ]);

        $service = new ExternalApiService(
            httpClient: $client,
            requestFactory: $this->requestFactory,
        );

        // Act
        $result = $service->fetchItems();

        // Assert: Should succeed after retry
        self::assertSame(0, $result->getTotal());
    }

    /**
     * @test
     */
    public function createItemSendsCorrectPayload(): void
    {
        // Arrange: Capture the request
        ['client' => $client, 'requests' => $requests] = $this->createRequestCapturingClient(
            $this->createSuccessResponse(['id' => 123, 'created' => true], 201)
        );

        $service = new ExternalApiService(
            httpClient: $client,
            requestFactory: $this->requestFactory,
            streamFactory: $this->streamFactory,
        );

        // Act
        $service->createItem('Test Item', ['category' => 'test']);

        // Assert: Verify request payload
        self::assertCount(1, $requests);
        $request = $requests[0];

        self::assertSame('POST', $request->getMethod());
        self::assertStringContainsString('/api/items', (string)$request->getUri());

        $body = \json_decode((string)$request->getBody(), true);
        self::assertSame('Test Item', $body['name']);
        self::assertSame('test', $body['category']);
    }
}
```

### OAuth Provider Integration

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Integration\Provider;

use Vendor\Extension\Provider\OAuthProvider;
use Vendor\Extension\Tests\Integration\AbstractIntegrationTestCase;

final class OAuthProviderIntegrationTest extends AbstractIntegrationTestCase
{
    /**
     * @test
     */
    public function exchangeCodeForTokenReturnsAccessToken(): void
    {
        // Arrange: Mock OAuth token endpoint response
        $tokenResponse = [
            'access_token' => 'test_access_token_123',
            'token_type' => 'Bearer',
            'expires_in' => 3600,
            'refresh_token' => 'test_refresh_token_456',
        ];

        $client = $this->createHttpClientWithResponses([
            $this->createSuccessResponse($tokenResponse),
        ]);

        $provider = new OAuthProvider(
            httpClient: $client,
            requestFactory: $this->requestFactory,
            streamFactory: $this->streamFactory,
            clientId: 'test_client',
            clientSecret: 'test_secret',
            tokenEndpoint: 'https://oauth.example.com/token',
        );

        // Act
        $token = $provider->exchangeCodeForToken('auth_code_xyz');

        // Assert
        self::assertSame('test_access_token_123', $token->getAccessToken());
        self::assertSame('Bearer', $token->getTokenType());
        self::assertSame(3600, $token->getExpiresIn());
    }

    /**
     * @test
     */
    public function refreshTokenObtainsNewAccessToken(): void
    {
        // Arrange
        $refreshResponse = [
            'access_token' => 'new_access_token_789',
            'token_type' => 'Bearer',
            'expires_in' => 3600,
        ];

        ['client' => $client, 'requests' => $requests] = $this->createRequestCapturingClient(
            $this->createSuccessResponse($refreshResponse)
        );

        $provider = new OAuthProvider(
            httpClient: $client,
            requestFactory: $this->requestFactory,
            streamFactory: $this->streamFactory,
            clientId: 'test_client',
            clientSecret: 'test_secret',
            tokenEndpoint: 'https://oauth.example.com/token',
        );

        // Act
        $token = $provider->refreshToken('old_refresh_token');

        // Assert: Verify refresh grant was sent
        $body = (string)$requests[0]->getBody();
        self::assertStringContainsString('grant_type=refresh_token', $body);
        self::assertStringContainsString('refresh_token=old_refresh_token', $body);

        self::assertSame('new_access_token_789', $token->getAccessToken());
    }
}
```

## Provider Response Helpers

For LLM/AI provider integrations, create response helpers:

```php
/**
 * Get OpenAI-style chat completion response.
 *
 * @return array<string, mixed>
 */
protected function getOpenAiChatResponse(
    string $content = 'Test response',
    string $model = 'gpt-4o',
    string $finishReason = 'stop',
): array {
    return [
        'id' => 'chatcmpl-' . \bin2hex(\random_bytes(12)),
        'object' => 'chat.completion',
        'created' => \time(),
        'model' => $model,
        'choices' => [
            [
                'index' => 0,
                'message' => [
                    'role' => 'assistant',
                    'content' => $content,
                ],
                'finish_reason' => $finishReason,
            ],
        ],
        'usage' => [
            'prompt_tokens' => \random_int(10, 100),
            'completion_tokens' => \random_int(20, 200),
            'total_tokens' => \random_int(30, 300),
        ],
    ];
}

/**
 * Get Claude-style chat completion response.
 *
 * @return array<string, mixed>
 */
protected function getClaudeChatResponse(
    string $content = 'Test response',
    string $model = 'claude-sonnet-4-20250514',
    string $stopReason = 'end_turn',
): array {
    return [
        'id' => 'msg_' . \bin2hex(\random_bytes(12)),
        'type' => 'message',
        'role' => 'assistant',
        'content' => [
            ['type' => 'text', 'text' => $content],
        ],
        'model' => $model,
        'stop_reason' => $stopReason,
        'usage' => [
            'input_tokens' => \random_int(10, 100),
            'output_tokens' => \random_int(20, 200),
        ],
    ];
}
```

## When to Use Integration Tests

### Use Integration Tests For:
- HTTP client interactions
- OAuth/authentication flows
- Third-party API integrations
- Request/response serialization
- Error handling and retries
- Rate limiting behavior

### Use Functional Tests Instead For:
- Database operations
- TYPO3 DataHandler hooks
- TCA/FlexForm processing
- Caching behavior
- Full request lifecycle

## Running Integration Tests

Integration tests typically run with unit tests (same speed characteristics):

```bash
# Run with unit tests
Build/Scripts/runTests.sh -s unit

# Or in separate suite if desired
.Build/bin/phpunit -c Build/phpunit/IntegrationTests.xml
```

## Best Practices

1. **Mock external dependencies**: Never make real HTTP calls
2. **Test error paths**: 4xx, 5xx, timeouts, malformed responses
3. **Verify request payloads**: Capture and assert request bodies
4. **Use realistic responses**: Copy actual API responses
5. **Keep tests fast**: No database, no network
6. **Document API contracts**: Response helpers serve as documentation

## Dependency Injection Pattern

For services with HTTP dependencies, use constructor injection:

```php
final class MyApiService
{
    public function __construct(
        private readonly ClientInterface $httpClient,
        private readonly RequestFactoryInterface $requestFactory,
        private readonly StreamFactoryInterface $streamFactory,
    ) {}
}
```

This enables easy testing:

```php
$service = new MyApiService(
    httpClient: $this->createHttpClientWithResponses([...]),
    requestFactory: $this->requestFactory,
    streamFactory: $this->streamFactory,
);
```

## Resources

- [PSR-18 HTTP Client](https://www.php-fig.org/psr/psr-18/)
- [PSR-17 HTTP Factories](https://www.php-fig.org/psr/psr-17/)
- [Guzzle PSR-7](https://github.com/guzzle/psr7)
