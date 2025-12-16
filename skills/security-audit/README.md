# Security Audit Skill

Expert patterns for conducting security audits, vulnerability assessment, and implementing secure coding practices aligned with OWASP guidelines.

## Features

- **Vulnerability Assessment**: XXE (XML External Entity) injection detection, SQL injection pattern recognition, XSS (Cross-Site Scripting) analysis, CSRF protection verification, authentication/authorization flaws, insecure deserialization
- **Risk Scoring**: CVSS v3.1 scoring methodology, risk matrix assessment, impact and likelihood analysis, prioritization frameworks
- **Secure Coding**: Input validation patterns, output encoding strategies, secure configuration, cryptographic best practices, session management
- **OWASP Compliance**: OWASP Top 10 vulnerability detection and remediation patterns
- **PHP Security**: PHP-specific security patterns and hardening techniques

## Installation

### Option 1: Via Netresearch Marketplace (Recommended)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

### Option 2: Download Release

Download the [latest release](https://github.com/netresearch/security-audit-skill/releases/latest) and extract to `~/.claude/skills/security-audit-skill/`

### Option 3: Composer (PHP projects)

```bash
composer require netresearch/agent-security-audit-skill
```

**Requires:** [netresearch/composer-agent-skill-plugin](https://github.com/netresearch/composer-agent-skill-plugin)

## Usage

This skill is automatically triggered when:

- Conducting security assessments
- Identifying vulnerabilities (XXE, SQL injection, XSS, CSRF)
- Scoring security risks with CVSS v3.1
- Implementing secure coding practices
- Auditing PHP applications for security issues
- Reviewing code for OWASP Top 10 vulnerabilities

Example queries:
- "Audit this code for XXE vulnerabilities"
- "Check for SQL injection risks"
- "Score this vulnerability using CVSS v3.1"
- "Review authentication implementation for security flaws"
- "Implement secure XML parsing"

## Structure

```
security-audit-skill/
├── SKILL.md                              # Skill metadata and core patterns
├── references/
│   ├── xxe-prevention.md                 # XXE vulnerability detection and prevention
│   ├── owasp-top10.md                    # OWASP Top 10 vulnerability patterns
│   ├── cvss-scoring.md                   # CVSS scoring methodology and examples
│   ├── secure-php.md                     # PHP-specific security patterns
│   └── secure-config.md                  # Secure configuration checklists
└── scripts/
    └── security-audit.sh                 # Security audit script
```

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

## Security Audit Checklist

### Authentication & Authorization
- Password hashing uses bcrypt/Argon2
- Session tokens are cryptographically random
- Session fixation protection enabled
- CSRF tokens on all state-changing operations
- Authorization checks on all protected resources
- Rate limiting on authentication endpoints

### Input Handling
- All input validated server-side
- Parameterized queries for all SQL
- XML parsing with external entities disabled
- File uploads restricted by type and size
- Path traversal prevention on file operations

### Output Handling
- Context-appropriate output encoding
- Content-Type headers set correctly
- X-Content-Type-Options: nosniff
- Content-Security-Policy configured
- X-Frame-Options set

### Data Protection
- Sensitive data encrypted at rest
- TLS 1.2+ for data in transit
- Secrets not in version control
- PII handling compliant with regulations
- Audit logging for sensitive operations

## Related Skills

- **enterprise-readiness-skill**: References this skill for security assessment
- **php-modernization-skill**: Type safety enhances security
- **typo3-testing-skill**: Security test patterns

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

Developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/).

---

**Made with ❤️ for Open Source by [Netresearch](https://www.netresearch.de/)**
