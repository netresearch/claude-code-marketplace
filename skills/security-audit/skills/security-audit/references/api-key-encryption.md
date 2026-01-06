# API Key Encryption at Rest

**Source:** nr_llm Extension - ADR-012 API Key Encryption
**Purpose:** Secure storage of API keys and secrets in database

## Overview

API keys and secrets stored in databases must be encrypted at rest to prevent exposure in case of database breaches, backup leaks, or unauthorized access.

## Recommended Pattern: sodium_crypto_secretbox

Use PHP's libsodium extension with XSalsa20-Poly1305 authenticated encryption.

### Why sodium_crypto_secretbox?

| Feature | Benefit |
|---------|---------|
| Authenticated encryption | Prevents tampering and truncation attacks |
| 256-bit key | Quantum-resistant key length |
| Random nonce | Each encryption is unique |
| Built into PHP 7.2+ | No external dependencies |
| Constant-time operations | Resistant to timing attacks |

## Implementation Pattern

### Key Derivation with Domain Separation

```php
<?php
declare(strict_types=1);

final class ProviderEncryptionService
{
    private const string ENCRYPTION_PREFIX = 'enc:';
    private const string KEY_DOMAIN = ':provider_encryption';

    public function __construct(
        private readonly string $encryptionKey,
    ) {}

    /**
     * Derive encryption key with domain separation.
     * This prevents key reuse across different contexts.
     */
    private function getEncryptionKey(): string
    {
        return hash('sha256', $this->encryptionKey . self::KEY_DOMAIN, true);
    }
}
```

**Key derivation requirements:**
- Use application-level secret (e.g., TYPO3's `encryptionKey`)
- Apply domain separator to prevent cross-context key reuse
- Use SHA-256 to derive 32-byte key from variable-length input
- Binary output (`true` parameter) for raw key bytes

### Encryption

```php
public function encrypt(string $plaintext): string
{
    if ($plaintext === '') {
        return '';
    }

    $key = $this->getEncryptionKey();

    // Generate cryptographically secure random nonce
    $nonce = random_bytes(SODIUM_CRYPTO_SECRETBOX_NONCEBYTES); // 24 bytes

    // Encrypt with authentication
    $ciphertext = sodium_crypto_secretbox($plaintext, $nonce, $key);

    // Clear sensitive data from memory
    sodium_memzero($plaintext);

    // Format: enc:{base64(nonce || ciphertext)}
    return self::ENCRYPTION_PREFIX . base64_encode($nonce . $ciphertext);
}
```

**Critical points:**
- Never reuse nonces - always generate fresh random bytes
- Clear plaintext from memory with `sodium_memzero()`
- Prefix encrypted values for identification
- Concatenate nonce with ciphertext for storage

### Decryption

```php
public function decrypt(string $encrypted): string
{
    // Handle empty or unencrypted values
    if ($encrypted === '' || !str_starts_with($encrypted, self::ENCRYPTION_PREFIX)) {
        return $encrypted;
    }

    $key = $this->getEncryptionKey();

    // Remove prefix and decode
    $data = base64_decode(substr($encrypted, strlen(self::ENCRYPTION_PREFIX)));
    if ($data === false) {
        throw new DecryptionException('Invalid base64 encoding');
    }

    // Extract nonce (first 24 bytes)
    $nonce = substr($data, 0, SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
    $ciphertext = substr($data, SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);

    // Decrypt and verify authentication tag
    $plaintext = sodium_crypto_secretbox_open($ciphertext, $nonce, $key);
    if ($plaintext === false) {
        throw new DecryptionException('Decryption failed - data may be corrupted or tampered');
    }

    return $plaintext;
}
```

### Detection of Encrypted Values

```php
public function isEncrypted(string $value): bool
{
    return str_starts_with($value, self::ENCRYPTION_PREFIX);
}
```

## Storage Format

```
enc:{base64(nonce || ciphertext || auth_tag)}
```

- **Prefix `enc:`**: Identifies encrypted values
- **Nonce**: 24 bytes (SODIUM_CRYPTO_SECRETBOX_NONCEBYTES)
- **Ciphertext**: Variable length (same as plaintext)
- **Auth tag**: 16 bytes (included by sodium_crypto_secretbox)

## Database Schema Considerations

```sql
-- API keys need sufficient length for encrypted values
-- Base64 overhead: ~33% + 24 byte nonce + 16 byte tag + prefix
-- For 100-char API key: ~180 chars encrypted
api_key VARCHAR(500) NOT NULL DEFAULT ''
```

## Security Audit Checklist

### Storage
- [ ] API keys encrypted before database storage
- [ ] Encrypted values have `enc:` prefix for identification
- [ ] Original plaintext cleared from memory after encryption
- [ ] Encryption key derived with domain separation

### Key Management
- [ ] Master encryption key not in version control
- [ ] Master key stored in environment variable or secrets manager
- [ ] Key rotation procedure documented
- [ ] Re-encryption script available for key rotation

### Detection Patterns

```php
// Audit: Find unencrypted API keys in database
// Pattern: Values that look like API keys but aren't encrypted

// OpenAI keys start with 'sk-'
$vulnerable = !str_starts_with($apiKey, 'enc:') && str_starts_with($apiKey, 'sk-');

// Anthropic keys start with 'sk-ant-'
$vulnerable = !str_starts_with($apiKey, 'enc:') && str_starts_with($apiKey, 'sk-ant-');

// Generic: Long alphanumeric strings without encryption prefix
$vulnerable = !str_starts_with($apiKey, 'enc:') && preg_match('/^[a-zA-Z0-9_-]{32,}$/', $apiKey);
```

## CVSS Scoring for Unencrypted API Keys

```yaml
Vulnerability: Unencrypted API Keys in Database
Vector String: CVSS:3.1/AV:L/AC:L/PR:H/UI:N/S:C/C:H/I:N/A:N

Attack Vector (AV): Local (L)           # Requires database access
Attack Complexity (AC): Low (L)         # Direct read from table
Privileges Required (PR): High (H)      # DBA or backup access
User Interaction (UI): None (N)         # No user action needed
Scope (S): Changed (C)                  # Compromises external services
Confidentiality (C): High (H)           # Full API key exposure
Integrity (I): None (N)                 # No data modification
Availability (A): None (N)              # No service disruption

Base Score: 6.0 (MEDIUM)
```

## Migration Script Pattern

```php
/**
 * Upgrade wizard to encrypt existing plaintext API keys
 */
final class EncryptApiKeysUpgradeWizard implements UpgradeWizardInterface
{
    public function executeUpdate(): bool
    {
        $connection = $this->connectionPool->getConnectionForTable('tx_myext_provider');
        $rows = $connection->select(['uid', 'api_key'], 'tx_myext_provider')->fetchAllAssociative();

        foreach ($rows as $row) {
            if (!$this->encryptionService->isEncrypted($row['api_key'])) {
                $encrypted = $this->encryptionService->encrypt($row['api_key']);
                $connection->update(
                    'tx_myext_provider',
                    ['api_key' => $encrypted],
                    ['uid' => $row['uid']]
                );
            }
        }

        return true;
    }
}
```

## Alternatives Considered

| Alternative | Why Not Recommended |
|-------------|---------------------|
| `openssl_encrypt()` | More configuration needed, easier to misconfigure |
| `password_hash()` | One-way hash, cannot retrieve original value |
| Database-level encryption | Not portable, requires specific DB features |
| External vault (HashiCorp) | Added complexity, but valid for high-security environments |

## Related References

- `owasp-top10.md` - A02:2021 Cryptographic Failures
- `xxe-prevention.md` - General secure coding patterns
- PHP libsodium documentation: https://www.php.net/manual/en/book.sodium.php
