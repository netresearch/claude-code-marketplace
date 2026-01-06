# General Enterprise Readiness Checks

Universal checks applicable to any platform and language. Aligned with OpenSSF Scorecard,
Best Practices Badge, and S2C2F frameworks.

## Governance & Policy (10 points)

### Security Policy (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| SECURITY.md exists with contact info | 2 | Check for `SECURITY.md` in repository root |
| Vulnerability disclosure process defined | 1 | Verify clear reporting instructions |

**Implementation**: Create `SECURITY.md` with:
- Security contact (email or form)
- Vulnerability reporting process
- Expected response timeline
- Scope of security policy

### License Compliance (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| LICENSE file present in repository root | 2 | Check for `LICENSE`, `LICENSE.md`, or `COPYING` |
| OSI-approved or FSF-approved license | 1 | Verify license type |

### Vulnerability Response SLA (2 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Initial response within 14 days | 1 | Check SECURITY.md for SLA commitment |
| Critical vulnerabilities fixed within 30 days | 1 | Check vulnerability history or policy |

**Best Practice**: Define SLAs by severity:
- Critical: Fix within 7 days
- High: Fix within 30 days
- Medium: Fix within 90 days
- Low: Fix within 180 days

### Project Maintenance (2 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Active commits within last 90 days | 1 | `git log --since="90 days ago" --oneline | head -5` |
| Issues/PRs responded to | 1 | Check recent issue activity |

---

## Supply Chain Security (15 points)

### Binary Artifacts (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| No generated binaries in source | 2 | `git ls-files \| grep -E "\.(exe\|dll\|so\|dylib\|bin\|o\|a)$"` should return empty |
| No compiled assets in repository | 1 | Check for minified bundles, compiled bytecode |

**Why**: Binary artifacts in source repositories cannot be reviewed and may contain malware.

### Provenance Attestation (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| SLSA Level 1+ build provenance exists | 2 | Look for `.intoto.jsonl` files or build attestations |
| Provenance automatically generated in CI | 1 | Check CI/CD for provenance generation steps |
| SLSA Level 3 achieved | 1 | Verify isolated build environment, signed provenance |

**Implementation**: Use platform-specific SLSA builders or manually generate with in-toto.

### Artifact Signing (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Release artifacts are signed | 2 | Look for `.sig`, `.asc`, or `.pem` files |
| Keyless signing with OIDC (preferred) | 2 | Check for Sigstore/Cosign with workload identity |

**Implementation**: Prefer keyless signing (Cosign + OIDC) over traditional GPG keys.

### Software Bill of Materials (2 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| SBOM generated for releases | 1 | Look for `.sbom.json`, `.spdx.json`, or CycloneDX files |
| SBOM in standard format (SPDX/CycloneDX) | 1 | Verify format compliance |

**Tools**: Syft, Trivy, or language-specific SBOM generators.

### Checksums (2 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| SHA256 checksums for all artifacts | 1 | Look for `checksums.txt` or `SHA256SUMS` |
| Checksums are signed | 1 | Look for `.sig` or `.pem` accompanying checksums |

---

## Dependency Consumption (10 points)

*Aligned with S2C2F (Secure Supply Chain Consumption Framework)*

### Dependency Ingestion (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Dependencies from trusted registries only | 1 | Check package manager config (npm, Go proxy, PyPI) |
| Lockfile committed (go.sum, package-lock.json) | 1 | Verify lockfile exists and is committed |
| Dependency update automation enabled | 1 | Check for Dependabot, Renovate, or similar |

### Vulnerability Scanning (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Dependency vulnerability scanning in CI | 2 | Check for govulncheck, npm audit, Snyk, etc. |
| Blocking on high/critical vulnerabilities | 1 | Verify CI fails on security issues |
| Malware detection enabled | 1 | Check for Socket.dev, Phylum, or similar |

**Tools**: govulncheck (Go), npm audit (Node), pip-audit (Python), Snyk, Socket.dev

### License Auditing (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Dependency license scanning configured | 2 | Check for go-licenses, FOSSA, Snyk, license-checker |
| License policy defined (allow/deny lists) | 1 | Check for license policy configuration |

**Tools**: FOSSA, Snyk, license-checker, go-licenses

---

## Quality Gates (10 points)

### Code Coverage (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Coverage measurement exists | 1 | Check CI for coverage reports |
| Coverage threshold enforced (60%+) | 1 | Check for threshold enforcement in CI |
| Coverage trend tracking | 1 | Check for Codecov, Coveralls, or similar |

### Static Analysis (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Multiple linters configured | 2 | Check for linter config files |
| Linting enforced in CI (fails on issues) | 1 | Check CI for lint steps |
| SAST tool configured (CodeQL, Semgrep) | 1 | Check for security-focused static analysis |

### Secret Scanning (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Pre-commit secret scanning | 2 | Check for gitleaks, trufflehog, or similar |
| CI secret scanning | 1 | Check CI for secret detection steps |

**Tools**: gitleaks, trufflehog, detect-secrets, git-secrets

---

## Testing Layers (10 points)

### Unit Tests (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Unit tests exist | 1 | Check for test files |
| Unit tests run in CI | 1 | Check CI configuration |
| Tests accompany new features (policy) | 1 | Check CONTRIBUTING.md or PR template |

### Integration Tests (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Integration tests exist | 1 | Check for integration test directory/tags |
| Integration tests run in CI | 1 | Check CI configuration |
| Database/API mocking or fixtures | 1 | Check test infrastructure |

### Security Testing (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Fuzz tests exist | 1 | Check for fuzz test files |
| Fuzz testing in CI (or OSS-Fuzz) | 1 | Check CI or OSS-Fuzz enrollment |
| Dynamic analysis (DAST) | 1 | Check for runtime security testing |
| Penetration testing documented | 1 | Check security documentation |

---

## Documentation & Governance (5 points)

### Project Documentation (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| README with project description | 1 | Check README.md exists and is informative |
| CONTRIBUTING.md with guidelines | 1 | Check for contribution guidelines |
| API/reference documentation | 1 | Check for docs/ directory or generated docs |

### Community Health (2 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| CODEOWNERS file configured | 1 | Check `.github/CODEOWNERS` or `CODEOWNERS` |
| Issue/PR templates exist | 1 | Check `.github/ISSUE_TEMPLATE/` and `.github/PULL_REQUEST_TEMPLATE.md` |

---

## Total: 60 points

**Scoring Thresholds**:
- 54-60: Excellent universal security posture
- 42-53: Good, minor improvements needed
- 30-41: Fair, significant gaps
- Below 30: Poor, major improvements required

---

## OpenSSF Alignment Reference

| OpenSSF Scorecard Check | This Skill Section | Status |
|------------------------|-------------------|--------|
| Binary-Artifacts | Supply Chain Security | ✅ Covered |
| CII-Best-Practices | Governance & Policy | ✅ Covered (via compliance) |
| Contributors | Documentation & Governance | ⚠️ Partial |
| Fuzzing | Testing Layers | ✅ Covered |
| License | Governance & Policy | ✅ Covered |
| Maintained | Governance & Policy | ✅ Covered |
| SBOM | Supply Chain Security | ✅ Covered |
| SAST | Quality Gates | ✅ Covered |
| Security-Policy | Governance & Policy | ✅ Covered |
| Signed-Releases | Supply Chain Security | ✅ Covered |
| Vulnerabilities | Dependency Consumption | ✅ Covered |

| S2C2F Practice | This Skill Section | Status |
|----------------|-------------------|--------|
| Ingest It | Dependency Consumption | ✅ Covered |
| Scan It | Quality Gates, Dependency Consumption | ✅ Covered |
| Inventory It | Supply Chain Security (SBOM) | ✅ Covered |
| Update It | Dependency Consumption | ✅ Covered |
| Audit It | Governance & Policy | ✅ Covered |
| Enforce It | Quality Gates | ✅ Covered |
| Rebuild It | (Platform-specific) | ⚠️ Partial |
| Fix It + Upstream | (Out of scope) | ❌ N/A |
