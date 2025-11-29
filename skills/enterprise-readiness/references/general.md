# General Enterprise Readiness Checks

Universal checks applicable to any platform and language.

## Supply Chain Security (20 points)

### Provenance Attestation (5 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| SLSA Level 1+ build provenance exists | 3 | Look for `.intoto.jsonl` files or build attestations |
| Provenance is automatically generated | 2 | Check CI/CD for provenance generation steps |

**Implementation**: Use platform-specific SLSA builders or manually generate with in-toto.

### Artifact Signing (5 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Release artifacts are signed | 3 | Look for `.sig`, `.asc`, or `.pem` files |
| Keyless signing with OIDC (preferred) | 2 | Check for Sigstore/Cosign with workload identity |

**Implementation**: Prefer keyless signing (Cosign + OIDC) over traditional GPG keys.

### Software Bill of Materials (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| SBOM generated for releases | 2 | Look for `.sbom.json`, `.spdx.json`, or CycloneDX files |
| SBOM in standard format (SPDX/CycloneDX) | 2 | Verify format compliance |

**Implementation**: Use Syft, Trivy, or language-specific SBOM generators.

### Checksums (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| SHA256 checksums for all artifacts | 2 | Look for `checksums.txt` or `SHA256SUMS` |
| Checksums are signed | 1 | Look for `.sig` or `.pem` accompanying checksums |

### Secret Scanning (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Pre-commit secret scanning | 2 | Check for gitleaks, trufflehog, or similar |
| CI secret scanning | 1 | Check CI for secret detection steps |

**Tools**: gitleaks, trufflehog, detect-secrets, git-secrets

---

## Quality Gates (15 points)

### Code Coverage (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Coverage measurement exists | 2 | Check CI for coverage reports |
| Coverage threshold enforced (≥60%) | 2 | Check for threshold enforcement in CI |

### Static Analysis (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Multiple linters configured | 2 | Check for linter config files |
| Linting enforced in CI | 2 | Check CI for lint steps that fail on issues |

### Security Analysis (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| SAST tool configured | 2 | Check for CodeQL, Semgrep, SonarQube, etc. |
| Security scanning in CI | 2 | Check CI for security scan steps |

### License Compliance (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Dependency license auditing | 2 | Check for license scanning tools |
| License policy defined | 1 | Check for allowed/denied license lists |

**Tools**: FOSSA, Snyk, license-checker, go-licenses

---

## Testing Layers (15 points)

### Unit Tests (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Unit tests exist | 2 | Check for test files |
| Unit tests run in CI | 2 | Check CI configuration |

### Integration Tests (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Integration tests exist | 2 | Check for integration test directory/tags |
| Integration tests run in CI | 2 | Check CI configuration |

### Fuzz Testing (4 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| Fuzz tests exist | 2 | Check for fuzz test files |
| Fuzz testing in CI (or OSS-Fuzz) | 2 | Check CI or OSS-Fuzz enrollment |

### E2E/Smoke Tests (3 points)
| Criteria | Points | How to Check |
|----------|--------|--------------|
| E2E or smoke tests exist | 2 | Check for e2e test directory |
| E2E tests run on PRs or releases | 1 | Check CI configuration |

---

## Documentation & Governance (bonus, not scored)

These are recommended but not scored:

- [ ] SECURITY.md with vulnerability reporting process
- [ ] CODEOWNERS file with valid team handles
- [ ] CONTRIBUTING.md with development guidelines
- [ ] LICENSE file present
- [ ] README with badges for CI status, coverage, security
- [ ] Changelog (CHANGELOG.md or generated)
- [ ] Semantic versioning followed

---

## Total: 50 points

**Scoring Thresholds**:
- 45-50: Excellent supply chain security
- 35-44: Good, minor improvements needed
- 25-34: Fair, significant gaps
- Below 25: Poor, major improvements required
