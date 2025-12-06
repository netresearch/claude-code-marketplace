# Security Hardening Guide

> OpenSSF Gold Badge requirements: `hardening`, `crypto_tls12`, `crypto_used_network`
>
> Projects providing network services must use TLS 1.2+ and implement security hardening.

## TLS Configuration

### Minimum TLS 1.2 Requirement

```go
// Go TLS configuration
import (
    "crypto/tls"
    "net/http"
)

func secureServer() *http.Server {
    tlsConfig := &tls.Config{
        MinVersion: tls.VersionTLS12,
        // Prefer TLS 1.3 when available
        MaxVersion: tls.VersionTLS13,
        // Secure cipher suites only
        CipherSuites: []uint16{
            tls.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
            tls.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
            tls.TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,
            tls.TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,
            tls.TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
            tls.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
        },
        // Note: PreferServerCipherSuites is ignored in Go 1.17+ as the
        // standard library now automatically prefers server cipher suites
    }

    return &http.Server{
        Addr:      ":443",
        TLSConfig: tlsConfig,
    }
}
```

### Python TLS Configuration

```python
import ssl
import http.server

def create_secure_context():
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.minimum_version = ssl.TLSVersion.TLSv1_2
    context.maximum_version = ssl.TLSVersion.TLSv1_3

    # Load certificates
    context.load_cert_chain('server.crt', 'server.key')

    # Disable insecure options
    context.options |= ssl.OP_NO_SSLv2
    context.options |= ssl.OP_NO_SSLv3
    context.options |= ssl.OP_NO_TLSv1
    context.options |= ssl.OP_NO_TLSv1_1

    return context
```

### Node.js TLS Configuration

```javascript
const https = require('https');
const fs = require('fs');

const options = {
    key: fs.readFileSync('server.key'),
    cert: fs.readFileSync('server.crt'),
    minVersion: 'TLSv1.2',
    maxVersion: 'TLSv1.3',
    ciphers: [
        'TLS_AES_256_GCM_SHA384',
        'TLS_CHACHA20_POLY1305_SHA256',
        'TLS_AES_128_GCM_SHA256',
        'ECDHE-ECDSA-AES256-GCM-SHA384',
        'ECDHE-RSA-AES256-GCM-SHA384',
    ].join(':'),
    honorCipherOrder: true,
};

https.createServer(options, handler).listen(443);
```

## Security Headers

### HTTP Security Headers

```go
// Go middleware for security headers
func securityHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // Prevent XSS
        w.Header().Set("X-Content-Type-Options", "nosniff")
        w.Header().Set("X-Frame-Options", "DENY")
        w.Header().Set("X-XSS-Protection", "1; mode=block")

        // Content Security Policy
        w.Header().Set("Content-Security-Policy",
            "default-src 'self'; script-src 'self'; style-src 'self'")

        // HSTS (HTTPS only)
        w.Header().Set("Strict-Transport-Security",
            "max-age=31536000; includeSubDomains; preload")

        // Referrer Policy
        w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")

        // Permissions Policy
        w.Header().Set("Permissions-Policy",
            "geolocation=(), microphone=(), camera=()")

        next.ServeHTTP(w, r)
    })
}
```

### Nginx Security Configuration

```nginx
# /etc/nginx/conf.d/security.conf

# TLS Configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_stapling on;
ssl_stapling_verify on;

# Security Headers
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Content-Security-Policy "default-src 'self'" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Hide server version
server_tokens off;
```

## Application Hardening

### Input Validation

```go
import (
    "regexp"
    "strings"
    "unicode/utf8"
)

// Validate and sanitize input
func validateInput(input string, maxLen int) (string, error) {
    // Length check
    if utf8.RuneCountInString(input) > maxLen {
        return "", fmt.Errorf("input exceeds maximum length")
    }

    // Remove null bytes
    input = strings.ReplaceAll(input, "\x00", "")

    // Validate against allowed pattern
    pattern := regexp.MustCompile(`^[a-zA-Z0-9\-_\.]+$`)
    if !pattern.MatchString(input) {
        return "", fmt.Errorf("input contains invalid characters")
    }

    return input, nil
}
```

### SQL Injection Prevention

```go
// ALWAYS use parameterized queries
func getUser(db *sql.DB, userID string) (*User, error) {
    // SAFE - parameterized
    row := db.QueryRow("SELECT * FROM users WHERE id = $1", userID)

    // NEVER do this:
    // db.Query("SELECT * FROM users WHERE id = " + userID)

    var user User
    err := row.Scan(&user.ID, &user.Name, &user.Email)
    return &user, err
}
```

### Command Injection Prevention

```go
import "os/exec"

// SAFE - use exec.Command with separate arguments
func safeCommand(filename string) error {
    // Arguments are separate - no shell interpretation
    cmd := exec.Command("convert", filename, "-resize", "100x100", "output.png")
    return cmd.Run()
}

// DANGEROUS - shell interpretation
func unsafeCommand(filename string) error {
    // NEVER do this - shell injection possible
    cmd := exec.Command("sh", "-c", "convert " + filename + " output.png")
    return cmd.Run()
}
```

## Dependency Security

### Automated Vulnerability Scanning

```yaml
# .github/workflows/security.yml
name: Security Scan
on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 0 * * *'

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'

      - name: Run Snyk
        uses: snyk/actions/golang@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### Go Security Scanning

```bash
# govulncheck - official Go vulnerability scanner
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...

# gosec - static analysis for security
go install github.com/securego/gosec/v2/cmd/gosec@latest
gosec -severity high ./...
```

## Runtime Hardening

### Container Security

```dockerfile
# Dockerfile with security best practices
FROM golang:1.23-alpine AS builder

# Don't run as root
RUN adduser -D -u 1000 appuser

WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -ldflags='-s -w' -o /app/server

FROM scratch
# Copy CA certificates for TLS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
# Copy user
COPY --from=builder /etc/passwd /etc/passwd
# Copy binary
COPY --from=builder /app/server /server

USER appuser
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### Kubernetes Security Context

```yaml
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
    - name: app
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
```

## Verification Scripts

### TLS Version Check

```bash
#!/bin/bash
# scripts/check-tls.sh

HOST="${1:-localhost}"
PORT="${2:-443}"

echo "=== TLS Configuration Check ==="

# Check supported protocols
echo "Testing TLS versions..."
for version in tls1 tls1_1 tls1_2 tls1_3; do
    if openssl s_client -connect "$HOST:$PORT" -"$version" </dev/null 2>/dev/null | grep -q "CONNECTED"; then
        echo "  $version: ✅ Supported"
    else
        echo "  $version: ❌ Not supported"
    fi
done

# Check certificate
echo ""
echo "Certificate info:"
openssl s_client -connect "$HOST:$PORT" </dev/null 2>/dev/null | openssl x509 -noout -dates -subject
```

### Security Headers Check

```bash
#!/bin/bash
# scripts/check-headers.sh

URL="${1:-https://localhost}"

echo "=== Security Headers Check ==="

curl -sI "$URL" | grep -iE "(x-content-type|x-frame|x-xss|strict-transport|content-security|referrer-policy)" | while read -r header; do
    echo "✅ $header"
done
```

## Badge Criteria Alignment

| Criterion | Requirement | Implementation |
|-----------|-------------|----------------|
| `hardening` | Security hardening applied | Security headers, input validation |
| `crypto_tls12` | TLS 1.2+ for network services | MinVersion TLS 1.2 config |
| `crypto_used_network` | Crypto for network data | TLS for all external comms |
| `crypto_random` | Cryptographic randomness | crypto/rand, not math/rand |
| `crypto_keylength` | Adequate key lengths | RSA 2048+, ECDSA 256+ |

## Hardening Checklist

### Network Security
- [ ] TLS 1.2+ only (TLS 1.3 preferred)
- [ ] Strong cipher suites only
- [ ] HSTS enabled with long max-age
- [ ] Certificate pinning for critical connections

### Application Security
- [ ] All inputs validated and sanitized
- [ ] Parameterized queries for databases
- [ ] No shell command interpolation
- [ ] Security headers on all responses

### Authentication
- [ ] 2FA required for privileged access
- [ ] Strong password requirements
- [ ] Rate limiting on auth endpoints
- [ ] Secure session management

### Infrastructure
- [ ] Containers run as non-root
- [ ] Read-only filesystems where possible
- [ ] Network policies restrict traffic
- [ ] Secrets managed securely

## Resources

- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)
- [NIST Cryptographic Standards](https://csrc.nist.gov/projects/cryptographic-standards-and-guidelines)
