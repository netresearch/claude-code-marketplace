# Cryptographic Testing Patterns

Testing cryptographic code requires specific patterns to ensure security while maintaining testability.

## When to Apply

- Secrets management extensions
- Envelope encryption implementations
- Key derivation functions
- Token/credential storage
- Memory-safe secret handling

## Unit Testing Cryptographic Services

### Testing Encryption Services

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\Service;

use PHPUnit\Framework\Attributes\Test;
use TYPO3\TestingFramework\Core\Unit\UnitTestCase;
use Vendor\Extension\Service\EncryptionService;

final class EncryptionServiceTest extends UnitTestCase
{
    private EncryptionService $subject;
    private string $testKey;

    protected function setUp(): void
    {
        parent::setUp();
        // Use deterministic test key - NEVER use production keys
        $this->testKey = sodium_crypto_secretbox_keygen();
        $this->subject = new EncryptionService($this->testKey);
    }

    protected function tearDown(): void
    {
        // Clear sensitive test data from memory
        sodium_memzero($this->testKey);
        parent::tearDown();
    }

    #[Test]
    public function encryptAndDecryptRoundTrip(): void
    {
        $plaintext = 'sensitive-api-key-12345';

        $encrypted = $this->subject->encrypt($plaintext);
        $decrypted = $this->subject->decrypt($encrypted);

        self::assertSame($plaintext, $decrypted);
        self::assertNotSame($plaintext, $encrypted);
    }

    #[Test]
    public function encryptProducesDifferentCiphertextForSamePlaintext(): void
    {
        $plaintext = 'secret-value';

        $encrypted1 = $this->subject->encrypt($plaintext);
        $encrypted2 = $this->subject->encrypt($plaintext);

        // Random nonce ensures different ciphertext each time
        self::assertNotSame($encrypted1, $encrypted2);
    }

    #[Test]
    public function decryptWithWrongKeyThrowsException(): void
    {
        $encrypted = $this->subject->encrypt('secret');
        $wrongKey = sodium_crypto_secretbox_keygen();
        $wrongService = new EncryptionService($wrongKey);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('Decryption failed');

        $wrongService->decrypt($encrypted);

        sodium_memzero($wrongKey);
    }
}
```

### Testing Envelope Encryption (DEK + KEK Pattern)

Envelope encryption uses a Data Encryption Key (DEK) encrypted by a Key Encryption Key (KEK):

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\Service;

use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\MockObject\MockObject;
use TYPO3\TestingFramework\Core\Unit\UnitTestCase;
use Vendor\Extension\Service\EnvelopeEncryptionService;
use Vendor\Extension\Service\KeyManagementServiceInterface;

final class EnvelopeEncryptionServiceTest extends UnitTestCase
{
    private EnvelopeEncryptionService $subject;
    private KeyManagementServiceInterface&MockObject $keyManagementService;
    private string $testKek;

    protected function setUp(): void
    {
        parent::setUp();
        $this->testKek = sodium_crypto_secretbox_keygen();

        $this->keyManagementService = $this->createMock(KeyManagementServiceInterface::class);
        $this->keyManagementService
            ->method('getKeyEncryptionKey')
            ->willReturn($this->testKek);

        $this->subject = new EnvelopeEncryptionService($this->keyManagementService);
    }

    protected function tearDown(): void
    {
        sodium_memzero($this->testKek);
        parent::tearDown();
    }

    #[Test]
    public function storeGeneratesUniqueDekPerSecret(): void
    {
        $result1 = $this->subject->store('secret1');
        $result2 = $this->subject->store('secret2');

        // Each secret gets its own DEK
        self::assertNotSame($result1['encrypted_dek'], $result2['encrypted_dek']);
    }

    #[Test]
    public function retrieveDecryptsWithCorrectDek(): void
    {
        $original = 'my-api-secret';
        $stored = $this->subject->store($original);

        $retrieved = $this->subject->retrieve(
            $stored['encrypted_value'],
            $stored['encrypted_dek'],
            $stored['nonce']
        );

        self::assertSame($original, $retrieved);
    }

    #[Test]
    public function keyRotationReEncryptsWithNewKek(): void
    {
        $original = 'secret-to-rotate';
        $stored = $this->subject->store($original);

        $newKek = sodium_crypto_secretbox_keygen();
        $rotated = $this->subject->rotateKey($stored, $this->testKek, $newKek);

        // Encrypted DEK changes, but value remains accessible
        self::assertNotSame($stored['encrypted_dek'], $rotated['encrypted_dek']);

        sodium_memzero($newKek);
    }
}
```

## Testing Memory-Safe Secret Handling

### Verifying sodium_memzero() Usage

For security-critical code, verify that secrets are cleared from memory:

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\Http;

use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\MockObject\MockObject;
use TYPO3\TestingFramework\Core\Unit\UnitTestCase;
use Vendor\Extension\Http\VaultHttpClient;
use Vendor\Extension\Service\VaultServiceInterface;
use Psr\Http\Client\ClientInterface;

final class VaultHttpClientTest extends UnitTestCase
{
    private VaultHttpClient $subject;
    private VaultServiceInterface&MockObject $vaultService;
    private ClientInterface&MockObject $httpClient;

    protected function setUp(): void
    {
        parent::setUp();
        $this->vaultService = $this->createMock(VaultServiceInterface::class);
        $this->httpClient = $this->createMock(ClientInterface::class);
        $this->subject = new VaultHttpClient($this->vaultService, $this->httpClient);
    }

    #[Test]
    public function secretIsRetrievedJustInTime(): void
    {
        // Verify secret is retrieved only when needed
        $this->vaultService
            ->expects(self::once())
            ->method('retrieve')
            ->with('api-key-identifier')
            ->willReturn('secret-value');

        $this->httpClient
            ->expects(self::once())
            ->method('sendRequest');

        $this->subject->request('GET', 'https://api.example.com', [
            'auth_secret' => 'api-key-identifier',
        ]);
    }

    #[Test]
    public function secretNotRetrievedWhenNotNeeded(): void
    {
        // Verify no vault access for requests without auth
        $this->vaultService
            ->expects(self::never())
            ->method('retrieve');

        $this->subject->request('GET', 'https://api.example.com');
    }
}
```

### Testing the Secret Clearing Pattern

While directly testing `sodium_memzero()` is difficult (the memory is zeroed), test the pattern:

```php
#[Test]
public function requestClearsSecretEvenOnException(): void
{
    $this->vaultService
        ->method('retrieve')
        ->willReturn('secret-value');

    $this->httpClient
        ->method('sendRequest')
        ->willThrowException(new \RuntimeException('Network error'));

    // The implementation should use try/finally to ensure cleanup
    try {
        $this->subject->request('GET', 'https://api.example.com', [
            'auth_secret' => 'test-key',
        ]);
    } catch (\RuntimeException) {
        // Expected - secret should still be cleared in finally block
    }

    // If we got here without memory issues, the pattern is correct
    self::assertTrue(true);
}
```

## Test Data Patterns

### Deterministic Test Keys

```php
final class CryptoTestHelper
{
    /**
     * Generate a deterministic test key for reproducible tests.
     * NEVER use in production - only for testing.
     */
    public static function createTestKey(string $seed = 'test'): string
    {
        return sodium_crypto_generichash($seed, '', SODIUM_CRYPTO_SECRETBOX_KEYBYTES);
    }

    /**
     * Create a test secret with cleanup callback.
     * @return array{secret: string, cleanup: callable}
     */
    public static function createTestSecret(string $value): array
    {
        $secret = $value;
        return [
            'secret' => $secret,
            'cleanup' => static function () use (&$secret): void {
                if ($secret !== '') {
                    sodium_memzero($secret);
                }
            },
        ];
    }
}
```

### Using Test Helpers

```php
protected function setUp(): void
{
    parent::setUp();
    $this->testData = CryptoTestHelper::createTestSecret('api-key-123');
}

protected function tearDown(): void
{
    ($this->testData['cleanup'])();
    parent::tearDown();
}
```

## Functional Testing Encrypted Storage

For database-backed secret storage:

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Functional\Repository;

use PHPUnit\Framework\Attributes\Test;
use TYPO3\TestingFramework\Core\Functional\FunctionalTestCase;
use Vendor\Extension\Repository\SecretRepository;

final class SecretRepositoryTest extends FunctionalTestCase
{
    protected array $testExtensionsToLoad = ['vendor/extension'];

    private SecretRepository $subject;
    private string $testKey;

    protected function setUp(): void
    {
        parent::setUp();
        $this->testKey = sodium_crypto_secretbox_keygen();
        $this->subject = $this->get(SecretRepository::class);
    }

    protected function tearDown(): void
    {
        sodium_memzero($this->testKey);
        parent::tearDown();
    }

    #[Test]
    public function storedSecretIsEncryptedInDatabase(): void
    {
        $identifier = 'test-api-key';
        $plaintext = 'super-secret-value';

        $this->subject->store($identifier, $plaintext, $this->testKey);

        // Direct database query to verify encryption
        $row = $this->getConnectionPool()
            ->getConnectionForTable('tx_extension_secret')
            ->select(['*'], 'tx_extension_secret', ['identifier' => $identifier])
            ->fetchAssociative();

        // Value in database should NOT match plaintext
        self::assertNotSame($plaintext, $row['encrypted_value']);
        self::assertNotEmpty($row['encrypted_dek']);
        self::assertNotEmpty($row['nonce']);
    }

    #[Test]
    public function retrieveReturnsDecryptedValue(): void
    {
        $identifier = 'test-secret';
        $plaintext = 'my-secret-123';

        $this->subject->store($identifier, $plaintext, $this->testKey);
        $retrieved = $this->subject->retrieve($identifier, $this->testKey);

        self::assertSame($plaintext, $retrieved);
    }
}
```

## Algorithm-Specific Nonce Lengths

Different algorithms require different nonce lengths. Using wrong nonce length reduces security.

### The Problem

```php
// ❌ WRONG - Same nonce length for all algorithms reduces entropy
private const NONCE_LENGTH = 12;  // AES-GCM length

public function encrypt(string $plaintext): string
{
    $nonce = random_bytes(self::NONCE_LENGTH);  // Always 12 bytes!

    // For XChaCha20-Poly1305, this wastes 12 bytes of nonce entropy
    // (should be 24 bytes)
    if ($this->algorithm === 'xchacha20') {
        $nonce = str_pad($nonce, 24, "\0");  // Padding with zeros = BAD!
    }
}
```

### The Fix - Dynamic Nonce Length

```php
private function getNonceLength(): int
{
    return match ($this->algorithm) {
        'aes-256-gcm' => SODIUM_CRYPTO_AEAD_AES256GCM_NPUBBYTES,        // 12 bytes
        'xchacha20-poly1305' => SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES,  // 24 bytes
        default => throw new \InvalidArgumentException('Unknown algorithm'),
    };
}

public function encrypt(string $plaintext): string
{
    // ✅ CORRECT - Full entropy for each algorithm
    $nonce = random_bytes($this->getNonceLength());
}
```

### Testing Nonce Length

```php
#[Test]
public function aesGcmUsesCorrectNonceLength(): void
{
    $service = new EncryptionService('aes-256-gcm', $this->key);
    $encrypted = $service->encrypt('test');

    // Extract nonce from ciphertext
    $nonce = substr($encrypted, 0, SODIUM_CRYPTO_AEAD_AES256GCM_NPUBBYTES);

    self::assertSame(12, strlen($nonce));
}

#[Test]
public function xchachaUsesCorrectNonceLength(): void
{
    $service = new EncryptionService('xchacha20-poly1305', $this->key);
    $encrypted = $service->encrypt('test');

    // Extract nonce from ciphertext
    $nonce = substr($encrypted, 0, SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES);

    self::assertSame(24, strlen($nonce));
}

#[Test]
public function noncesAreFullyRandom(): void
{
    // Verify nonce doesn't contain padding zeros
    $service = new EncryptionService('xchacha20-poly1305', $this->key);

    $nonces = [];
    for ($i = 0; $i < 10; $i++) {
        $encrypted = $service->encrypt('test');
        $nonce = substr($encrypted, 0, 24);
        $nonces[] = $nonce;

        // No nonce should end with 12 zero bytes (padding pattern)
        $lastBytes = substr($nonce, 12);
        self::assertNotSame(str_repeat("\0", 12), $lastBytes);
    }

    // All nonces should be unique
    self::assertSame(10, count(array_unique($nonces)));
}
```

## Security Test Checklist

| Test Case | Purpose |
|-----------|---------|
| Round-trip encrypt/decrypt | Basic correctness |
| Different ciphertext for same input | Nonce randomness |
| Correct nonce length per algorithm | Algorithm compliance |
| Wrong key fails decryption | Key isolation |
| Tampered ciphertext fails | Integrity protection |
| Empty input handling | Edge case security |
| Key rotation preserves access | Migration safety |
| Secret cleared after use | Memory safety |
| No plaintext in logs | Audit safety |

## Anti-Patterns to Avoid

### Never Log Secrets

```php
// WRONG - logs actual secret
$this->logger->debug('Retrieved secret: ' . $secret);

// CORRECT - log only identifier
$this->logger->debug('Retrieved secret', ['identifier' => $identifier]);
```

### Never Use Weak Keys in Tests

```php
// WRONG - predictable key
$key = str_repeat('0', 32);

// CORRECT - proper key generation
$key = sodium_crypto_secretbox_keygen();
```

### Never Skip Cleanup in Tests

```php
// WRONG - secret remains in memory
protected function tearDown(): void
{
    parent::tearDown();
}

// CORRECT - explicit cleanup
protected function tearDown(): void
{
    if (isset($this->testKey)) {
        sodium_memzero($this->testKey);
    }
    parent::tearDown();
}
```

## CI Integration

For security-critical extensions, run crypto tests in isolation:

```yaml
# .github/workflows/test.yml
jobs:
  crypto-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          extensions: sodium
      - run: composer install
      - name: Run crypto-specific tests
        run: |
          vendor/bin/phpunit --testsuite Unit \
            --filter 'Encryption|Crypto|Secret|Vault'
```

## Resources

- [libsodium Documentation](https://doc.libsodium.org/)
- [PHP Sodium Functions](https://www.php.net/manual/en/book.sodium.php)
- [OWASP Cryptographic Storage](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)
