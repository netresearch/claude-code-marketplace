# OpenSSF Best Practices Badge - Exceptions and Justifications

> Documentation for badge criteria marked as "N/A" (Not Applicable) or requiring justification.

## Project Information

| Field | Value |
|-------|-------|
| Project | [PROJECT_NAME] |
| Badge Level | Passing / Silver / Gold |
| Last Updated | [DATE] |

---

## Summary of Exceptions

| Criterion | Level | Status | Justification Summary |
|-----------|-------|--------|----------------------|
| `two_person_review` | Gold | N/A | Solo maintainer project |
| `contributors_unassociated` | Gold | N/A | Specialized domain |
| `bus_factor` | Silver/Gold | N/A | Active succession plan |
| `accessibility_best_practices` | Silver | N/A | CLI tool, no UI |
| `internationalization` | Silver | N/A | Developer tooling |

---

## Detailed Justifications

### Solo Maintainer Criteria

#### `two_person_review` (Gold)

**Form Question:** "Do changes require 2-person review before merging?"

**Status:** N/A

**Justification:**
This is a solo maintainer project. While two-person review is not possible, the following
compensating controls ensure code quality and security:

**Compensating Controls:**
1. **Comprehensive CI/CD Pipeline**
   - All changes go through automated testing (>80% coverage)
   - Static analysis with CodeQL and gosec
   - Dependency vulnerability scanning
   - Secret detection with gitleaks

2. **Self-Review Process**
   - All changes sit as PR for minimum 24 hours before merge
   - Detailed PR descriptions with rationale
   - Security-critical changes reviewed with fresh eyes after delay

3. **Community Oversight**
   - Public pull requests visible to all
   - Issue discussions before major changes
   - Security researchers can review code

4. **Automated Safeguards**
   - Branch protection requiring CI pass
   - Signed commits required
   - Force push disabled on main branch

---

#### `contributors_unassociated` (Gold)

**Form Question:** "Are there unassociated contributors from different organizations?"

**Status:** N/A

**Justification:**
This is a specialized project with a limited contributor base. The project welcomes contributions
from any organization and has no restrictions on contributor affiliation.

**Compensating Controls:**
1. Open contribution policy documented in CONTRIBUTING.md
2. No organizational control over project decisions
3. Governance model allows for external maintainers
4. No CLA required (uses DCO instead)

---

#### `bus_factor` (Silver/Gold)

**Form Question:** "Is the bus factor >= 2?"

**Status:** N/A (or Met with explanation)

**Justification:**
Solo maintainer project with documented succession plan.

**Compensating Controls:**
1. **Documentation**
   - Comprehensive ARCHITECTURE.md
   - Detailed CONTRIBUTING.md
   - Decision rationale in ADRs
   - All critical processes documented

2. **Succession Planning**
   - Backup maintainer identified (optional: name)
   - Repository access can be transferred
   - No proprietary dependencies or secrets

3. **Community Resilience**
   - All development happens in public
   - No private infrastructure required
   - Standard tooling used throughout

---

### Technical N/A Criteria

#### `accessibility_best_practices` (Silver)

**Form Question:** "Does the project follow accessibility best practices?"

**Status:** N/A

**Justification:**
This is a command-line tool / library with no user interface. Accessibility best practices
for visual UI elements do not apply.

**Evidence:**
- No HTML, CSS, or frontend code
- CLI output follows standard conventions
- Documentation available in accessible text formats

---

#### `internationalization` (Silver)

**Form Question:** "Does the project support internationalization?"

**Status:** N/A

**Justification:**
This is developer tooling where the primary user base is English-speaking developers.
The project outputs technical information (logs, errors) that are typically not localized
in developer tools.

**Compensating Controls:**
- Error messages are clear and actionable
- Documentation is comprehensive
- Contributions for i18n would be accepted if needed

---

#### `crypto_used_network` (Silver)

**Form Question:** "Is cryptography used for network communications?"

**Status:** N/A

**Justification:**
This project does not perform network communications. It operates entirely on local files
and does not transmit data over networks.

**Evidence:**
- No network-related imports in codebase
- No HTTP client or server code
- Offline-only operation

---

#### `sites_password_security` (Silver)

**Form Question:** "Are passwords stored securely if applicable?"

**Status:** N/A

**Justification:**
This project does not store, process, or handle passwords. There is no user authentication
or credential management functionality.

**Evidence:**
- No password-related code
- No user authentication
- No credential storage

---

## Review History

| Date | Reviewer | Changes |
|------|----------|---------|
| YYYY-MM-DD | @maintainer | Initial exceptions documented |
| YYYY-MM-DD | @maintainer | Updated compensating controls |

---

## Certification

I certify that the above justifications are accurate and the compensating controls
described are implemented and active.

**Maintainer:** ________________________

**Date:** ________________________
