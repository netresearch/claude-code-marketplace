# OWASP Top 10 (2021) Security Patterns

## A01: Broken Access Control

### Detection Patterns

```php
// VULNERABLE: Direct Object Reference
public function viewDocument(int $id): Response
{
    $document = $this->repository->find($id);  // No auth check!
    return $this->render('document.html', ['doc' => $document]);
}

// SECURE: Authorization check
public function viewDocument(int $id): Response
{
    $document = $this->repository->find($id);

    if (!$this->isGranted('VIEW', $document)) {
        throw $this->createAccessDeniedException();
    }

    return $this->render('document.html', ['doc' => $document]);
}
```

### Prevention Checklist

- [ ] Implement deny-by-default access control
- [ ] Use role-based access control (RBAC)
- [ ] Validate user ownership of resources
- [ ] Log access control failures
- [ ] Rate limit API access
- [ ] Disable directory listing
- [ ] Invalidate JWT tokens on logout

## A02: Cryptographic Failures

### Secure Password Hashing

```php
// VULNERABLE - DO NOT USE
$hash = md5($password);
$hash = sha1($password);

// SECURE: Use password_hash
$hash = password_hash($password, PASSWORD_DEFAULT);  // Uses bcrypt
$hash = password_hash($password, PASSWORD_ARGON2ID); // Stronger

// Verification
if (password_verify($password, $hash)) {
    // Password correct
}
```

### Secure Random Generation

```php
// VULNERABLE - DO NOT USE
$token = md5(uniqid());

// SECURE
$token = bin2hex(random_bytes(32));
$token = base64_encode(random_bytes(32));
```

### Data Encryption

```php
// Symmetric encryption with authenticated encryption
final class Encryptor
{
    public function __construct(
        private readonly string $key  // 32 bytes for AES-256
    ) {}

    public function encrypt(string $plaintext): string
    {
        $nonce = random_bytes(SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
        $ciphertext = sodium_crypto_secretbox($plaintext, $nonce, $this->key);
        return base64_encode($nonce . $ciphertext);
    }

    public function decrypt(string $encrypted): string
    {
        $decoded = base64_decode($encrypted, true);
        $nonce = substr($decoded, 0, SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
        $ciphertext = substr($decoded, SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
        $plaintext = sodium_crypto_secretbox_open($ciphertext, $nonce, $this->key);

        if ($plaintext === false) {
            throw new DecryptionException('Decryption failed');
        }
        return $plaintext;
    }
}
```

## A03: Injection

### SQL Injection Prevention

```php
// VULNERABLE - DO NOT USE
$query = "SELECT * FROM users WHERE username = '$username'";

// SECURE: Prepared statements
$stmt = $pdo->prepare('SELECT * FROM users WHERE username = ?');
$stmt->execute([$username]);

// SECURE: Named parameters
$stmt = $pdo->prepare('SELECT * FROM users WHERE username = :username');
$stmt->execute(['username' => $username]);
```

### Command Injection Prevention

```php
// VULNERABLE - shell_exec with user input is dangerous
// $output = shell_exec("ls " . $_GET['dir']);

// SECURE: Use escapeshellarg
$output = shell_exec("ls " . escapeshellarg($dir));

// SECURE: Use Symfony Process component with array
use Symfony\Component\Process\Process;
$process = new Process(['ls', '-la', $dir]);
$process->run();

// SECURE: Whitelist approach
$allowedCommands = ['list', 'status', 'version'];
if (!in_array($command, $allowedCommands, true)) {
    throw new InvalidArgumentException('Invalid command');
}
```

### LDAP Injection Prevention

```php
// VULNERABLE
$filter = "(uid=$username)";

// SECURE: Escape special characters
$filter = "(uid=" . ldap_escape($username, '', LDAP_ESCAPE_FILTER) . ")";
```

## A04: Insecure Design

### Rate Limiting Implementation

```php
final class RateLimiter
{
    public function __construct(
        private readonly CacheInterface $cache,
        private readonly int $maxAttempts = 5,
        private readonly int $decayMinutes = 15
    ) {}

    public function tooManyAttempts(string $key): bool
    {
        $attempts = (int) $this->cache->get($key, 0);
        return $attempts >= $this->maxAttempts;
    }

    public function hit(string $key): int
    {
        $attempts = (int) $this->cache->get($key, 0) + 1;
        $this->cache->set($key, $attempts, $this->decayMinutes * 60);
        return $attempts;
    }
}
```

## A05: Security Misconfiguration

### PHP Configuration

```ini
; php.ini security settings
expose_php = Off
display_errors = Off
log_errors = On

; Session security
session.cookie_httponly = 1
session.cookie_secure = 1
session.cookie_samesite = Strict
```

### HTTP Security Headers

```php
// Middleware to add security headers
final class SecurityHeadersMiddleware
{
    public function __invoke(Request $request, callable $next): Response
    {
        $response = $next($request);

        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('X-XSS-Protection', '1; mode=block');
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');

        return $response;
    }
}
```

## A06: Vulnerable Components

### Dependency Scanning

```bash
# Check for known vulnerabilities
composer audit

# Update dependencies
composer update --with-dependencies

# Check outdated packages
composer outdated --direct
```

## A07: Authentication Failures

### Secure Session Management

```php
final class SessionManager
{
    public function regenerate(): void
    {
        session_regenerate_id(true);
    }

    public function destroy(): void
    {
        $_SESSION = [];
        session_destroy();
    }
}
```

## A08: Software and Data Integrity

### Subresource Integrity

```html
<script
  src="https://cdn.example.com/library.js"
  integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6..."
  crossorigin="anonymous">
</script>
```

## A09: Security Logging & Monitoring

### Audit Logging

```php
final class SecurityLogger
{
    public function __construct(
        private readonly LoggerInterface $logger
    ) {}

    public function logAuthenticationFailure(
        string $username,
        string $ip,
        string $reason
    ): void {
        $this->logger->warning('Authentication failure', [
            'username' => $username,
            'ip' => $ip,
            'reason' => $reason,
            'timestamp' => (new \DateTimeImmutable())->format('c'),
        ]);
    }
}
```

## A10: Server-Side Request Forgery (SSRF)

### URL Validation

```php
final class UrlValidator
{
    private const BLOCKED_SCHEMES = ['file', 'ftp', 'gopher'];
    private const BLOCKED_HOSTS = ['localhost', '127.0.0.1', '::1'];

    public function isAllowed(string $url): bool
    {
        $parsed = parse_url($url);

        if ($parsed === false) {
            return false;
        }

        $scheme = strtolower($parsed['scheme'] ?? '');
        if (in_array($scheme, self::BLOCKED_SCHEMES, true)) {
            return false;
        }

        $host = strtolower($parsed['host'] ?? '');
        if (in_array($host, self::BLOCKED_HOSTS, true)) {
            return false;
        }

        // Check for internal IP ranges
        $ip = gethostbyname($host);
        if ($this->isInternalIp($ip)) {
            return false;
        }

        return true;
    }

    private function isInternalIp(string $ip): bool
    {
        return filter_var(
            $ip,
            FILTER_VALIDATE_IP,
            FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE
        ) === false;
    }
}
```
