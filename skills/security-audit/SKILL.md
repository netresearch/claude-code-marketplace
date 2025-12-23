---
name: security-audit
description: "Agent Skill: Security audit patterns for PHP applications following OWASP guidelines. This skill should be used when conducting security assessments, identifying vulnerabilities (XXE, SQL injection, XSS, CSRF), scoring security risks with CVSS v3.1, or implementing secure coding practices. Covers OWASP Top 10 detection patterns, vulnerability remediation, and security hardening checklists. By Netresearch."
---

# Security Audit Skill

Expert patterns for conducting security audits, vulnerability assessment, and implementing secure coding practices aligned with OWASP guidelines.

## Expertise Areas

### Vulnerability Assessment
- XXE (XML External Entity) injection detection
- SQL injection pattern recognition
- XSS (Cross-Site Scripting) analysis
- CSRF protection verification
- Authentication/authorization flaws
- Insecure deserialization

### Risk Scoring
- CVSS v3.1 scoring methodology
- Risk matrix assessment
- Impact and likelihood analysis
- Prioritization frameworks

### Secure Coding
- Input validation patterns
- Output encoding strategies
- Secure configuration
- Cryptographic best practices
- Session management

## Reference Files

- `references/xxe-prevention.md` - XXE vulnerability detection and prevention
- `references/owasp-top10.md` - OWASP Top 10 vulnerability patterns
- `references/cvss-scoring.md` - CVSS scoring methodology and examples
- `references/secure-php.md` - PHP-specific security patterns
- `references/secure-config.md` - Secure configuration checklists

## Core Patterns

### XXE Vulnerability Detection

```php
// VULNERABLE: External entity processing enabled
$doc = new DOMDocument();
$doc->loadXML($userInput);  // XXE possible!

// SECURE: Disable external entities
$doc = new DOMDocument();
$doc->loadXML($userInput, LIBXML_NOENT | LIBXML_DTDLOAD);

// MOST SECURE: Disable all dangerous features
libxml_disable_entity_loader(true);  // PHP < 8.0
$doc = new DOMDocument();
$doc->loadXML(
    $userInput,
    LIBXML_NONET |           // Disable network access
    LIBXML_NOENT |           // Substitute entities
    LIBXML_DTDLOAD |         // Load external DTD
    LIBXML_DTDATTR |         // Default DTD attributes
    LIBXML_DTDVALID          // Validate against DTD
);
```

### SimpleXML Secure Usage

```php
// VULNERABLE
$xml = simplexml_load_string($userInput);

// SECURE: Disable external entities
$previousValue = libxml_disable_entity_loader(true);
try {
    $xml = simplexml_load_string(
        $userInput,
        'SimpleXMLElement',
        LIBXML_NONET | LIBXML_NOENT
    );
} finally {
    libxml_disable_entity_loader($previousValue);
}

// PHP 8.0+ approach (libxml_disable_entity_loader deprecated)
$xml = simplexml_load_string(
    $userInput,
    'SimpleXMLElement',
    LIBXML_NONET | LIBXML_NOENT | LIBXML_DTDLOAD
);
```

### CVSS v3.1 Scoring Example

```yaml
# XXE Vulnerability Score Example
Vulnerability: XXE in XML Import Feature

Attack Vector (AV): Network (N)        # Remotely exploitable
Attack Complexity (AC): Low (L)        # No special conditions
Privileges Required (PR): Low (L)      # Requires authenticated user
User Interaction (UI): None (N)        # No user action needed
Scope (S): Changed (C)                 # Impacts other components
Confidentiality (C): High (H)          # Can read arbitrary files
Integrity (I): Low (L)                 # Limited write capability
Availability (A): Low (L)              # Minor service disruption

Base Score: 8.5 (HIGH)
Vector String: CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:L
```

### Input Validation Pattern

```php
final class InputValidator
{
    /**
     * Validate and sanitize user input
     */
    public static function sanitizeString(
        string $input,
        int $maxLength = 255,
        bool $allowHtml = false
    ): string {
        // Trim whitespace
        $input = trim($input);

        // Enforce length limit
        if (strlen($input) > $maxLength) {
            $input = substr($input, 0, $maxLength);
        }

        // Handle HTML
        if (!$allowHtml) {
            $input = htmlspecialchars($input, ENT_QUOTES | ENT_HTML5, 'UTF-8');
        }

        return $input;
    }

    /**
     * Validate email with strict checking
     */
    public static function validateEmail(string $email): ?string
    {
        $email = filter_var($email, FILTER_SANITIZE_EMAIL);

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return null;
        }

        // Additional DNS check for domain
        $domain = substr($email, strpos($email, '@') + 1);
        if (!checkdnsrr($domain, 'MX') && !checkdnsrr($domain, 'A')) {
            return null;
        }

        return $email;
    }

    /**
     * Validate integer within range
     */
    public static function validateInt(
        mixed $value,
        int $min = PHP_INT_MIN,
        int $max = PHP_INT_MAX
    ): ?int {
        $options = [
            'options' => [
                'min_range' => $min,
                'max_range' => $max,
            ],
        ];

        $result = filter_var($value, FILTER_VALIDATE_INT, $options);

        return $result === false ? null : $result;
    }
}
```

### SQL Injection Prevention

```php
// VULNERABLE: Direct string interpolation
$query = "SELECT * FROM users WHERE id = $id";

// SECURE: Prepared statements (PDO)
$stmt = $pdo->prepare('SELECT * FROM users WHERE id = :id');
$stmt->execute(['id' => $id]);

// SECURE: Doctrine QueryBuilder
$qb = $em->createQueryBuilder()
    ->select('u')
    ->from(User::class, 'u')
    ->where('u.id = :id')
    ->setParameter('id', $id);

// SECURE: Type-safe parameter binding
$stmt = $pdo->prepare('SELECT * FROM users WHERE id = ?');
$stmt->bindValue(1, $id, PDO::PARAM_INT);
$stmt->execute();
```

### XSS Prevention

```php
// Output encoding context-aware

// HTML context
echo htmlspecialchars($userInput, ENT_QUOTES | ENT_HTML5, 'UTF-8');

// JavaScript context
echo json_encode($userInput, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT | JSON_HEX_AMP);

// URL context
echo urlencode($userInput);

// CSS context
echo preg_replace('/[^a-zA-Z0-9]/', '', $userInput);  // Whitelist approach

// Twig auto-escaping (enabled by default)
{{ userInput }}           {# HTML escaped #}
{{ userInput|raw }}       {# NO escaping - dangerous! #}
{{ userInput|e('js') }}   {# JavaScript context #}
```

## Security Audit Checklist

### Authentication & Authorization
- [ ] Password hashing uses bcrypt/Argon2
- [ ] Session tokens are cryptographically random
- [ ] Session fixation protection enabled
- [ ] CSRF tokens on all state-changing operations
- [ ] Authorization checks on all protected resources
- [ ] Rate limiting on authentication endpoints

### Input Handling
- [ ] All input validated server-side
- [ ] Parameterized queries for all SQL
- [ ] XML parsing with external entities disabled
- [ ] File uploads restricted by type and size
- [ ] Path traversal prevention on file operations

### Output Handling
- [ ] Context-appropriate output encoding
- [ ] Content-Type headers set correctly
- [ ] X-Content-Type-Options: nosniff
- [ ] Content-Security-Policy configured
- [ ] X-Frame-Options set

### Data Protection
- [ ] Sensitive data encrypted at rest
- [ ] TLS 1.2+ for data in transit
- [ ] Secrets not in version control
- [ ] PII handling compliant with regulations
- [ ] Audit logging for sensitive operations

## Verification

Run the security audit script:

```bash
./scripts/security-audit.sh /path/to/project
```

## Related Skills

- **enterprise-readiness-skill**: References this skill for security assessment
- **php-modernization-skill**: Type safety enhances security
- **typo3-testing-skill**: Security test patterns
