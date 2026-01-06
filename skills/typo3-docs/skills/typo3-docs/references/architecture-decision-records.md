# Architecture Decision Records (ADRs)

**Source:** nr_llm Extension - ADR Documentation Patterns
**Purpose:** Document architectural decisions with context and consequences

## Overview

Architecture Decision Records capture important architectural decisions along with their context and consequences. They provide a historical record of why certain decisions were made, helping future maintainers understand the codebase.

## When to Write an ADR

- Major architectural changes (new patterns, frameworks, approaches)
- Technology choices (libraries, APIs, protocols)
- Significant refactoring decisions
- Security-relevant decisions
- Performance optimization strategies
- Deprecation of existing patterns

## Directory Structure

```
Extension/
├── Documentation/
│   └── DeveloperGuide/
│       └── ArchitectureDecisions/
│           └── Index.rst           # Links to ADRs
├── claudedocs/                      # AI-readable ADRs
│   ├── ADR-001-initial-architecture.md
│   ├── ADR-002-provider-abstraction.md
│   └── ADR-013-api-key-encryption.md
└── README.md
```

## ADR Format

### Standard Template

```markdown
# ADR-NNN: Title

## Status

[Proposed | Accepted | Deprecated | Superseded by ADR-XXX]

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive
- Benefit 1
- Benefit 2

### Negative
- Tradeoff 1
- Tradeoff 2

### Neutral
- Side effect 1
```

### Extended Template (Recommended)

```markdown
# ADR-NNN: Descriptive Title

## Status

Accepted

## Date

2024-12-30

## Context

Describe the forces at play, including technical, political, social, and
project local. These forces are probably in tension.

## Problem Statement

Clear statement of the specific problem being solved.

## Decision Drivers

- Driver 1: What factors influenced this decision?
- Driver 2: Performance requirements?
- Driver 3: Security considerations?
- Driver 4: Maintainability concerns?

## Considered Options

### Option 1: [Name]
**Description:** Brief explanation

**Pros:**
- Advantage 1
- Advantage 2

**Cons:**
- Disadvantage 1
- Disadvantage 2

### Option 2: [Name]
**Description:** Brief explanation

**Pros:**
- Advantage 1

**Cons:**
- Disadvantage 1

## Decision

We chose Option 1 because...

## Implementation Details

```php
// Code example showing the decided approach
```

## Consequences

### Positive
- What becomes easier

### Negative
- What becomes harder

### Risks
- Potential issues to watch for

## Related Decisions

- ADR-005: Related decision
- ADR-012: Prerequisite decision

## References

- [External documentation](https://example.com)
- [TYPO3 documentation](https://docs.typo3.org)
```

## Example ADRs

### ADR-012: API Key Encryption

```markdown
# ADR-012: API Key Encryption at Rest

## Status

Accepted

## Date

2024-12-15

## Context

The extension stores API keys for external services (OpenAI, Anthropic, etc.)
in the database. These keys provide full access to paid APIs and could be
misused if exposed through:

- Database breaches
- Backup file exposure
- SQL injection attacks
- Unauthorized admin access

## Problem Statement

How do we protect API keys stored in the database while maintaining
usability for backend configuration?

## Decision Drivers

- Security: Keys must not be readable from raw database content
- Usability: Editors must be able to configure keys in backend
- Performance: Encryption/decryption should be fast
- Simplicity: No external dependencies (vault services)

## Considered Options

### Option 1: sodium_crypto_secretbox
**Description:** Use PHP's built-in libsodium with XSalsa20-Poly1305

**Pros:**
- Built into PHP 7.2+
- Authenticated encryption (detects tampering)
- Constant-time operations (timing attack resistant)
- Well-audited cryptographic library

**Cons:**
- Requires key management
- Keys in memory during processing

### Option 2: openssl_encrypt
**Description:** Use OpenSSL with AES-256-GCM

**Pros:**
- Well-known algorithm
- Built into PHP

**Cons:**
- More configuration options (easier to misconfigure)
- IV management complexity

### Option 3: External Vault (HashiCorp)
**Description:** Store keys in external secrets manager

**Pros:**
- Enterprise-grade security
- Audit logging
- Key rotation built-in

**Cons:**
- Added infrastructure dependency
- Increased complexity
- Overkill for most TYPO3 installations

## Decision

We chose **sodium_crypto_secretbox** because:
1. No external dependencies
2. Simple API with secure defaults
3. Built into modern PHP
4. Authenticated encryption prevents tampering

## Implementation

Key derivation uses TYPO3's encryptionKey with domain separation:

```php
private function getEncryptionKey(): string
{
    return hash('sha256', $this->encryptionKey . ':provider_encryption', true);
}

public function encrypt(string $plaintext): string
{
    $nonce = random_bytes(SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
    $ciphertext = sodium_crypto_secretbox($plaintext, $nonce, $this->getEncryptionKey());
    sodium_memzero($plaintext);
    return 'enc:' . base64_encode($nonce . $ciphertext);
}
```

## Consequences

### Positive
- API keys protected at rest
- No plaintext keys in database dumps
- Tampering is detectable
- Compatible with TYPO3 security model

### Negative
- Keys visible in memory during encryption/decryption
- Key rotation requires re-encryption of all values
- Encrypted values are longer than plaintext

### Risks
- Loss of TYPO3 encryptionKey = loss of all API keys
- Backup/restore must preserve encryptionKey

## Related Decisions

- ADR-013: Three-level configuration architecture
```

### ADR-013: Three-Level Configuration Architecture

```markdown
# ADR-013: Three-Level Configuration Architecture

## Status

Accepted

## Date

2024-12-20

## Context

The extension needs to support:
- Multiple API keys per provider (production/development)
- Custom endpoints (Azure OpenAI, self-hosted models)
- Reusable model definitions
- Use-case-specific configurations

The existing single-table design cannot represent these relationships cleanly.

## Decision

Implement a three-tier architecture:

```
Configuration (use-case settings)
      ↓ references
Model (capability definitions)
      ↓ references
Provider (API connection)
```

## Implementation

Three database tables with Extbase relations:
- tx_nrllm_provider: Connection credentials
- tx_nrllm_model: Model capabilities
- tx_nrllm_configuration: Use-case settings

## Consequences

### Positive
- Multiple credentials per provider type
- Clean separation of concerns
- Reusable model definitions
- Testability (swap providers in tests)

### Negative
- More complex database schema
- Migration needed for existing data
- Three TCA files to maintain
```

## Best Practices

### Naming Conventions

- Format: `ADR-NNN-kebab-case-title.md`
- Numbers: Zero-padded, sequential (001, 002, 003)
- Title: Descriptive, action-oriented

### Content Guidelines

1. **Be specific** - Include code examples, not just concepts
2. **Document alternatives** - Show what wasn't chosen and why
3. **Include dates** - Decisions have context in time
4. **Link related ADRs** - Build a decision graph
5. **Update status** - Mark deprecated/superseded decisions

### RST Integration

```rst
.. toctree::
   :maxdepth: 2
   :caption: Architecture Decisions

   ArchitectureDecisions/ADR-001-InitialArchitecture
   ArchitectureDecisions/ADR-012-ApiKeyEncryption
   ArchitectureDecisions/ADR-013-ThreeLevelConfiguration
```

### AI-Readable Format (claudedocs/)

Keep a parallel set of ADRs in Markdown for AI assistants:

```
claudedocs/
├── README.md                    # Overview for AI
├── ADR-001-initial-architecture.md
├── ADR-012-api-key-encryption.md
├── context-architecture.md      # Current state summary
└── patterns/                    # Reusable patterns
    ├── adapter-registry.md
    └── encryption-service.md
```

## ADR Lifecycle

```
┌──────────┐     ┌──────────┐     ┌────────────┐
│ Proposed │ ──▶ │ Accepted │ ──▶ │ Deprecated │
└──────────┘     └──────────┘     └────────────┘
                      │                  │
                      │                  ▼
                      │           ┌────────────────┐
                      └─────────▶ │ Superseded by  │
                                  │   ADR-XXX      │
                                  └────────────────┘
```

## Tools and Automation

### Generate ADR Index

```bash
#!/bin/bash
# scripts/generate-adr-index.sh

echo "# Architecture Decision Records" > docs/adr/README.md
echo "" >> docs/adr/README.md
echo "| ADR | Title | Status |" >> docs/adr/README.md
echo "|-----|-------|--------|" >> docs/adr/README.md

for file in docs/adr/ADR-*.md; do
    number=$(basename "$file" | grep -oP 'ADR-\d+')
    title=$(head -1 "$file" | sed 's/# //')
    status=$(grep -m1 "^## Status" -A2 "$file" | tail -1)
    echo "| [$number]($file) | $title | $status |" >> docs/adr/README.md
done
```

### ADR Template Script

```bash
#!/bin/bash
# scripts/new-adr.sh

NEXT_NUM=$(ls docs/adr/ADR-*.md 2>/dev/null | wc -l)
NEXT_NUM=$((NEXT_NUM + 1))
PADDED=$(printf "%03d" $NEXT_NUM)

TITLE="${1:-untitled}"
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
FILENAME="docs/adr/ADR-${PADDED}-${SLUG}.md"

cat > "$FILENAME" << EOF
# ADR-${PADDED}: ${TITLE}

## Status

Proposed

## Date

$(date +%Y-%m-%d)

## Context

[Describe the context]

## Decision

[Describe the decision]

## Consequences

### Positive
-

### Negative
-
EOF

echo "Created: $FILENAME"
```

## Related References

- [Michael Nygard's ADR format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [ADR Tools](https://github.com/npryce/adr-tools)
- `rst-syntax.md` - RST formatting for TYPO3 docs
- `typo3-extension-architecture.md` - Extension structure
