---
name: security-audit
description: "Agent Skill: Security audit patterns for PHP/OWASP. Use when conducting security assessments, identifying vulnerabilities (XXE, SQL injection, XSS), or CVSS scoring. By Netresearch."
---

# Security Audit Skill

Security audits, vulnerability assessment, and secure coding patterns aligned with OWASP.

## Expertise Areas

- **Vulnerabilities**: XXE, SQL injection, XSS, CSRF, auth flaws, insecure deserialization
- **Risk Scoring**: CVSS v3.1 methodology
- **Secure Coding**: Input validation, output encoding, cryptography, session management

## Reference Files

- `references/xxe-prevention.md` - XXE detection and prevention
- `references/owasp-top10.md` - OWASP Top 10 patterns
- `references/cvss-scoring.md` - CVSS scoring methodology
- `references/api-key-encryption.md` - API key encryption at rest (sodium)
- `references/secure-php.md` - PHP-specific security patterns
- `references/secure-config.md` - Secure configuration checklists

## Quick Patterns

**XML parsing (prevent XXE):**
```php
$doc->loadXML($input, LIBXML_NONET | LIBXML_NOENT | LIBXML_DTDLOAD);
```

**SQL (prevent injection):**
```php
$stmt = $pdo->prepare('SELECT * FROM users WHERE id = ?');
$stmt->execute([$id]);
```

**Output (prevent XSS):**
```php
echo htmlspecialchars($input, ENT_QUOTES | ENT_HTML5, 'UTF-8');
```

**API keys (encrypt at rest):**
```php
$nonce = random_bytes(SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
$encrypted = 'enc:' . base64_encode($nonce . sodium_crypto_secretbox($apiKey, $nonce, $key));
```

## Security Checklist

- [ ] bcrypt/Argon2 for passwords, CSRF tokens on state changes
- [ ] All input validated server-side, parameterized SQL
- [ ] XML external entities disabled, file uploads restricted
- [ ] Context-appropriate output encoding, CSP configured
- [ ] API keys encrypted at rest (sodium_crypto_secretbox)
- [ ] TLS 1.2+, secrets not in VCS, audit logging

## Verification

```bash
./scripts/security-audit.sh /path/to/project
```

---

> **Contributing:** https://github.com/netresearch/security-audit-skill
