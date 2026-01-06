# CVSS v3.1 Scoring Guide

## Base Metrics

### Attack Vector (AV)

| Value | Description | Score |
|-------|-------------|-------|
| Network (N) | Remotely exploitable via network | 0.85 |
| Adjacent (A) | Requires adjacent network access | 0.62 |
| Local (L) | Requires local system access | 0.55 |
| Physical (P) | Requires physical access | 0.20 |

### Attack Complexity (AC)

| Value | Description | Score |
|-------|-------------|-------|
| Low (L) | No special conditions required | 0.77 |
| High (H) | Requires special conditions | 0.44 |

### Privileges Required (PR)

| Value | Unchanged Scope | Changed Scope |
|-------|-----------------|---------------|
| None (N) | 0.85 | 0.85 |
| Low (L) | 0.62 | 0.68 |
| High (H) | 0.27 | 0.50 |

### User Interaction (UI)

| Value | Description | Score |
|-------|-------------|-------|
| None (N) | No user interaction required | 0.85 |
| Required (R) | User must perform action | 0.62 |

### Scope (S)

| Value | Description |
|-------|-------------|
| Unchanged (U) | Impact limited to vulnerable component |
| Changed (C) | Impact extends beyond vulnerable component |

### Impact Metrics (CIA)

| Value | Description | Score |
|-------|-------------|-------|
| High (H) | Total loss | 0.56 |
| Low (L) | Some loss | 0.22 |
| None (N) | No impact | 0.00 |

## Severity Ratings

| Score Range | Severity |
|-------------|----------|
| 0.0 | None |
| 0.1 - 3.9 | Low |
| 4.0 - 6.9 | Medium |
| 7.0 - 8.9 | High |
| 9.0 - 10.0 | Critical |

## Example Vulnerability Scores

### XXE with File Disclosure

```yaml
Vulnerability: XXE allowing arbitrary file read
Vector: CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:L

Analysis:
  Attack Vector: Network (N)
    - Exploitable via HTTP request
  Attack Complexity: Low (L)
    - No special conditions needed
  Privileges Required: Low (L)
    - Requires authenticated user
  User Interaction: None (N)
    - No user action needed
  Scope: Changed (C)
    - Can access files outside application
  Confidentiality: High (H)
    - Can read /etc/passwd, config files
  Integrity: Low (L)
    - Limited write via SSRF
  Availability: Low (L)
    - DoS via billion laughs

Base Score: 8.5 (HIGH)
```

### SQL Injection (Unauthenticated)

```yaml
Vulnerability: SQL injection in login form
Vector: CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H

Analysis:
  Attack Vector: Network (N)
  Attack Complexity: Low (L)
  Privileges Required: None (N)
    - Unauthenticated exploitation
  User Interaction: None (N)
  Scope: Unchanged (U)
  Confidentiality: High (H)
    - Full database access
  Integrity: High (H)
    - Can modify/delete data
  Availability: High (H)
    - Can drop tables

Base Score: 9.8 (CRITICAL)
```

### Stored XSS

```yaml
Vulnerability: Stored XSS in comment field
Vector: CVSS:3.1/AV:N/AC:L/PR:L/UI:R/S:C/C:L/I:L/A:N

Analysis:
  Attack Vector: Network (N)
  Attack Complexity: Low (L)
  Privileges Required: Low (L)
    - Must be able to post comments
  User Interaction: Required (R)
    - Victim must view page
  Scope: Changed (C)
    - Runs in victim's browser context
  Confidentiality: Low (L)
    - Session theft possible
  Integrity: Low (L)
    - Can modify page content
  Availability: None (N)

Base Score: 5.4 (MEDIUM)
```

### CSRF

```yaml
Vulnerability: CSRF on password change
Vector: CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:N/I:H/A:N

Analysis:
  Attack Vector: Network (N)
  Attack Complexity: Low (L)
  Privileges Required: None (N)
    - Attacker needs no privileges
  User Interaction: Required (R)
    - Victim must click malicious link
  Scope: Unchanged (U)
  Confidentiality: None (N)
  Integrity: High (H)
    - Account takeover possible
  Availability: None (N)

Base Score: 6.5 (MEDIUM)
```

### Insecure Direct Object Reference

```yaml
Vulnerability: IDOR allowing access to other users' data
Vector: CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N

Analysis:
  Attack Vector: Network (N)
  Attack Complexity: Low (L)
  Privileges Required: Low (L)
    - Must be authenticated
  User Interaction: None (N)
  Scope: Unchanged (U)
  Confidentiality: High (H)
    - Can access all user data
  Integrity: None (N)
    - Read-only access
  Availability: None (N)

Base Score: 6.5 (MEDIUM)
```

## Scoring Calculator

```php
final class CvssCalculator
{
    public function calculateBaseScore(
        string $attackVector,
        string $attackComplexity,
        string $privilegesRequired,
        string $userInteraction,
        string $scope,
        string $confidentiality,
        string $integrity,
        string $availability
    ): float {
        $av = $this->getAttackVectorScore($attackVector);
        $ac = $this->getAttackComplexityScore($attackComplexity);
        $pr = $this->getPrivilegesRequiredScore($privilegesRequired, $scope);
        $ui = $this->getUserInteractionScore($userInteraction);

        $exploitability = 8.22 * $av * $ac * $pr * $ui;

        $c = $this->getImpactScore($confidentiality);
        $i = $this->getImpactScore($integrity);
        $a = $this->getImpactScore($availability);

        $iscBase = 1 - ((1 - $c) * (1 - $i) * (1 - $a));

        if ($scope === 'U') {
            $impact = 6.42 * $iscBase;
        } else {
            $impact = 7.52 * ($iscBase - 0.029) - 3.25 * pow($iscBase - 0.02, 15);
        }

        if ($impact <= 0) {
            return 0.0;
        }

        if ($scope === 'U') {
            return $this->roundUp(min($impact + $exploitability, 10));
        }

        return $this->roundUp(min(1.08 * ($impact + $exploitability), 10));
    }

    private function roundUp(float $value): float
    {
        return ceil($value * 10) / 10;
    }

    private function getAttackVectorScore(string $av): float
    {
        return match($av) {
            'N' => 0.85,
            'A' => 0.62,
            'L' => 0.55,
            'P' => 0.20,
            default => throw new InvalidArgumentException("Invalid AV: $av"),
        };
    }

    private function getAttackComplexityScore(string $ac): float
    {
        return match($ac) {
            'L' => 0.77,
            'H' => 0.44,
            default => throw new InvalidArgumentException("Invalid AC: $ac"),
        };
    }

    private function getPrivilegesRequiredScore(string $pr, string $scope): float
    {
        if ($scope === 'U') {
            return match($pr) {
                'N' => 0.85,
                'L' => 0.62,
                'H' => 0.27,
                default => throw new InvalidArgumentException("Invalid PR: $pr"),
            };
        }

        return match($pr) {
            'N' => 0.85,
            'L' => 0.68,
            'H' => 0.50,
            default => throw new InvalidArgumentException("Invalid PR: $pr"),
        };
    }

    private function getUserInteractionScore(string $ui): float
    {
        return match($ui) {
            'N' => 0.85,
            'R' => 0.62,
            default => throw new InvalidArgumentException("Invalid UI: $ui"),
        };
    }

    private function getImpactScore(string $impact): float
    {
        return match($impact) {
            'H' => 0.56,
            'L' => 0.22,
            'N' => 0.00,
            default => throw new InvalidArgumentException("Invalid impact: $impact"),
        };
    }
}
```

## Risk Matrix Template

```
                    IMPACT
              Low   Medium   High
         ┌────────┬────────┬────────┐
    High │ Medium │  High  │Critical│
         ├────────┼────────┼────────┤
L  Medium│  Low   │ Medium │  High  │
I        ├────────┼────────┼────────┤
K    Low │  Low   │  Low   │ Medium │
E        └────────┴────────┴────────┘
L
I   Legend:
H     Critical: Immediate action required
O     High: Address within 24 hours
O     Medium: Address within 1 week
D     Low: Address within 1 month
```

## Reporting Template

```markdown
## Vulnerability Report

### Summary
- **Title**: [Vulnerability Name]
- **Severity**: [Critical/High/Medium/Low]
- **CVSS Score**: [X.X]
- **Vector String**: CVSS:3.1/AV:X/AC:X/PR:X/UI:X/S:X/C:X/I:X/A:X

### Description
[Detailed description of the vulnerability]

### Affected Components
- [Component 1]
- [Component 2]

### Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Impact
[Description of potential impact]

### Remediation
[Recommended fix or mitigation]

### Timeline
- **Discovered**: [Date]
- **Reported**: [Date]
- **Fixed**: [Date]
- **Verified**: [Date]
```
