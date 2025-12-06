# SonarCloud Integration

> Enterprise-grade continuous code quality and security analysis platform

## Overview

SonarCloud is the cloud-hosted version of SonarQube, providing:
- **Static code analysis** with 5,000+ rules across 30+ languages
- **Security vulnerability detection** (OWASP Top 10, CWE, SANS Top 25)
- **Code smell and maintainability tracking**
- **Test coverage visualization**
- **Quality gates** for automated enforcement
- **PR decoration** for immediate feedback

## Pricing

| Tier | Cost | Scope |
|------|------|-------|
| **Free** | $0 | Unlimited public repos, full features |
| **Team** | From $14/mo | Private repos, based on LOC |
| **Enterprise** | Custom | Advanced features, SSO, support |

**Key**: Free tier provides **full enterprise features** for open-source projects.

## Enterprise Value

### Security Analysis

SonarCloud detects:
- SQL injection, XSS, command injection
- Insecure cryptography and hashing
- Authentication/authorization flaws
- Sensitive data exposure
- Security misconfigurations
- Known vulnerable dependencies

### Compliance Support

Aligns with:
- **OWASP Top 10** - Web application security
- **CWE/SANS Top 25** - Most dangerous software weaknesses
- **PCI DSS** - Payment card security
- **HIPAA** - Healthcare data protection

### Quality Metrics

| Metric | Description | Enterprise Relevance |
|--------|-------------|---------------------|
| Reliability | Bug count and severity | System stability |
| Security | Vulnerabilities and hotspots | Risk management |
| Maintainability | Code smells and tech debt | Long-term costs |
| Coverage | Test coverage percentage | Quality assurance |
| Duplications | Code duplication percentage | Maintainability |

## Setup

### 1. Connect Repository

1. Go to [sonarcloud.io](https://sonarcloud.io)
2. Sign in with GitHub/GitLab/Bitbucket
3. Create organization (matches your GitHub org)
4. Import repository

### 2. Generate Token

1. Account → Security → Generate Token
2. Save as `SONAR_TOKEN` repository secret

### 3. Add Configuration

Create `sonar-project.properties` in repository root:

```properties
sonar.projectKey=org_repo-name
sonar.organization=your-org

# Source configuration
sonar.sources=src,Classes
sonar.tests=tests,Tests
sonar.exclusions=**/vendor/**,**/node_modules/**,**/*.min.js

# Language-specific
sonar.php.coverage.reportPaths=coverage.xml
sonar.php.phpstan.reportPaths=phpstan-report.json
sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.go.coverage.reportPaths=coverage.out

# Quality settings
sonar.qualitygate.wait=true
```

### 4. GitHub Actions Workflow

```yaml
name: SonarCloud

on:
  push:
    branches: [main]
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  sonarcloud:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for accurate blame

      - name: Run tests with coverage
        run: |
          # PHP example
          vendor/bin/phpunit --coverage-clover coverage.xml
          # Or Go example
          # go test -coverprofile=coverage.out ./...

      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

## Quality Gates

### Default "Sonar Way" Gate

| Condition | Threshold | Applies To |
|-----------|-----------|------------|
| New bugs | 0 | New code |
| New vulnerabilities | 0 | New code |
| New security hotspots reviewed | 100% | New code |
| New code coverage | ≥80% | New code |
| New duplicated lines | ≤3% | New code |
| Maintainability rating | A | New code |
| Reliability rating | A | New code |
| Security rating | A | New code |

### Enterprise Custom Gate

For stricter enterprise requirements:

```
Conditions on New Code:
- Coverage ≥ 90%
- Duplicated Lines ≤ 1%
- Maintainability Rating = A
- Reliability Rating = A
- Security Rating = A
- Security Hotspots Reviewed = 100%
- New Bugs = 0
- New Vulnerabilities = 0
- New Code Smells ≤ 5

Conditions on Overall Code:
- Coverage ≥ 80%
- Duplicated Lines ≤ 3%
- Technical Debt Ratio ≤ 5%
```

## PR Decoration

SonarCloud automatically comments on PRs:

```
┌────────────────────────────────────────────────────┐
│ Quality Gate passed                                │
├────────────────────────────────────────────────────┤
│ Coverage: 87.3% (+2.1%)                           │
│                                                    │
│ 0 Bugs (0 new)                                    │
│ 0 Vulnerabilities (0 new)                         │
│ 2 Security Hotspots (1 to review)                 │
│ 5 Code Smells (2 new)                             │
│ 0.5% Duplication (0.0% new)                       │
└────────────────────────────────────────────────────┘
```

## Security Hotspots

Security-sensitive code requiring manual review:

| Category | Examples |
|----------|----------|
| **Authentication** | Password handling, session management |
| **Cryptography** | Encryption, hashing, random number generation |
| **Injection** | SQL, command, LDAP injection risks |
| **File handling** | Path traversal, file uploads |
| **Networking** | HTTP requests, SSL/TLS configuration |

### Hotspot Review Workflow

1. SonarCloud flags security-sensitive code
2. Developer reviews in SonarCloud UI
3. Mark as **Safe**, **Fixed**, or **To Review**
4. Document rationale for **Safe** decisions

## Integration with Existing Tools

### PHPStan Integration

Export PHPStan results to SonarCloud:

```bash
vendor/bin/phpstan analyze --error-format=json > phpstan-report.json
```

```properties
# sonar-project.properties
sonar.php.phpstan.reportPaths=phpstan-report.json
```

### ESLint Integration

```bash
npx eslint --format json --output-file eslint-report.json .
```

```properties
sonar.eslint.reportPaths=eslint-report.json
```

### Coverage Integration

| Language | Coverage Tool | Property |
|----------|--------------|----------|
| PHP | PHPUnit | `sonar.php.coverage.reportPaths` |
| JavaScript | Istanbul/NYC | `sonar.javascript.lcov.reportPaths` |
| Go | go test | `sonar.go.coverage.reportPaths` |
| Python | Coverage.py | `sonar.python.coverage.reportPaths` |
| Java | JaCoCo | `sonar.coverage.jacoco.xmlReportPaths` |

## Badges

Add to README for visibility:

```markdown
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=org_repo&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=org_repo)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=org_repo&metric=coverage)](https://sonarcloud.io/summary/new_code?id=org_repo)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=org_repo&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=org_repo)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=org_repo&metric=sqale_rating)](https://sonarcloud.io/summary/new_code?id=org_repo)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=org_repo&metric=reliability_rating)](https://sonarcloud.io/summary/new_code?id=org_repo)
```

## OpenSSF Badge Alignment

SonarCloud helps satisfy OpenSSF Best Practices criteria:

| Criterion | SonarCloud Feature |
|-----------|-------------------|
| `static_analysis` | ✅ Core feature |
| `static_analysis_fixed` | ✅ Quality Gate enforcement |
| `dynamic_analysis` | ⚠️ Partial (security hotspots) |
| `test_statement_coverage80` | ✅ Coverage tracking |
| `test_branch_coverage80` | ✅ Branch coverage (Gold) |
| `warnings_fixed` | ✅ Code smell tracking |

## Enterprise Best Practices

### 1. Baseline for Legacy Code

For existing projects with technical debt:

```properties
# Focus quality gate on new code only
sonar.leak.period=previous_version
```

### 2. Branch Analysis

```properties
# Analyze feature branches
sonar.branch.name=${BRANCH_NAME}
sonar.branch.target=main
```

### 3. Monorepo Support

```properties
# Multiple projects in one repo
sonar.projectKey=org_monorepo_service-a
sonar.projectBaseDir=services/service-a
```

### 4. Pull Request Analysis

```yaml
# Only analyze PRs to main/develop
on:
  pull_request:
    branches: [main, develop]
```

### 5. Scheduled Full Analysis

```yaml
# Weekly full analysis
on:
  schedule:
    - cron: '0 2 * * 0'  # Sunday 2 AM
```

## Comparison with Alternatives

| Feature | SonarCloud | CodeClimate | Codacy | GitHub CodeQL |
|---------|------------|-------------|--------|---------------|
| Free for OSS | ✅ Full | ✅ Full | ⚠️ Limited | ✅ Full |
| Security rules | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| PHP support | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Coverage | ✅ | ✅ | ✅ | ❌ |
| Quality gates | ✅ | ✅ | ✅ | ❌ |
| PR decoration | ✅ | ✅ | ✅ | ✅ |
| Self-hosted | SonarQube | ❌ | ❌ | ✅ |

## Resources

- [SonarCloud Documentation](https://docs.sonarcloud.io/)
- [Security Rules](https://rules.sonarsource.com/)
- [Quality Gates](https://docs.sonarcloud.io/improving/quality-gates/)
- [GitHub Actions Integration](https://docs.sonarcloud.io/advanced-setup/ci-based-analysis/github-actions-for-sonarcloud/)
- [SonarQube (Self-hosted)](https://www.sonarqube.org/)
