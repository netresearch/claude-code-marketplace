# Project Governance

This document describes the governance model for [PROJECT_NAME].

## Roles and Responsibilities

### Maintainers

Maintainers are responsible for:
- Reviewing and merging pull requests
- Triaging issues and bug reports
- Releasing new versions
- Ensuring project security and quality
- Making architectural decisions

**Current Maintainers:**
| Name | GitHub | Role | Organization |
|------|--------|------|--------------|
| [Name] | @username | Lead Maintainer | [Org] |

### Contributors

Contributors are community members who contribute code, documentation, or other improvements. All contributions are welcome following our [Contributing Guidelines](CONTRIBUTING.md).

### Security Team

The security team handles vulnerability reports and security-related decisions:
- [Name] (@username) - Security Lead

## Decision Making

### Consensus-Based Decisions

For most decisions, we use a consensus-based approach:
1. Proposal is made via GitHub Issue or Discussion
2. Community feedback is gathered (minimum 7 days for significant changes)
3. Maintainers discuss and reach consensus
4. Decision is documented and implemented

### Voting

For controversial decisions where consensus cannot be reached:
- Each maintainer has one vote
- Simple majority required
- Lead maintainer breaks ties

### Types of Decisions

| Decision Type | Process | Approvers |
|---------------|---------|-----------|
| Bug fixes | PR review | 1 maintainer |
| Features | Issue + PR review | 1 maintainer |
| Breaking changes | RFC + discussion | All maintainers |
| Security fixes | Private review | Security team |
| Governance changes | RFC + vote | All maintainers |

## Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Security**: security@example.com (private)

## Code of Conduct

All participants must follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## Conflict Resolution

1. Attempt resolution through direct communication
2. Escalate to maintainers if needed
3. Lead maintainer makes final decision
4. Code of Conduct violations handled per CoC process

## Changes to Governance

Changes to this governance document require:
1. RFC posted as GitHub Issue
2. Minimum 14-day discussion period
3. Approval from all maintainers
4. PR to update this document

---

*Last updated: [DATE]*
