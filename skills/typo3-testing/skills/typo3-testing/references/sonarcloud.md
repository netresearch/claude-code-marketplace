# SonarCloud for TYPO3 Extensions

> Continuous code quality and security analysis for PHP/TYPO3 projects

## Overview

SonarCloud provides automated code analysis for TYPO3 extensions:
- **200+ PHP rules** for bugs, vulnerabilities, and code smells
- **Coverage tracking** with visual reports
- **PR decoration** for immediate feedback
- **Quality gates** to enforce standards
- **Free for open-source** projects

## Quick Start

### 1. Sign Up

1. Go to [sonarcloud.io](https://sonarcloud.io)
2. Sign in with GitHub
3. Create/join organization
4. Import your TYPO3 extension repository

### 2. Create Configuration

Add `sonar-project.properties` to your extension root:

```properties
sonar.projectKey=your-org_your-extension
sonar.organization=your-org

# TYPO3 Extension Structure
sonar.sources=Classes
sonar.tests=Tests
sonar.exclusions=**/vendor/**,.Build/**,var/**

# PHP Settings
sonar.php.version=8.2
sonar.php.coverage.reportPaths=var/log/coverage.xml
sonar.php.phpstan.reportPaths=var/log/phpstan.json

# Quality Gate
sonar.qualitygate.wait=true
```

### 3. Add GitHub Action

Create `.github/workflows/sonarcloud.yml`:

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
          fetch-depth: 0

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          coverage: xdebug
          extensions: intl, pdo_sqlite

      - name: Install dependencies
        run: |
          composer require --dev typo3/testing-framework
          composer install --no-progress

      - name: Run tests with coverage
        run: |
          vendor/bin/phpunit \
            -c Build/phpunit/UnitTests.xml \
            --coverage-clover var/log/coverage.xml

      - name: Export PHPStan results
        run: |
          vendor/bin/phpstan analyze \
            --configuration Build/phpstan.neon \
            --error-format=json \
            --no-progress \
            > var/log/phpstan.json || true

      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### 4. Add Secret

1. Go to repository Settings → Secrets → Actions
2. Add `SONAR_TOKEN` from SonarCloud (Account → Security)

## TYPO3-Specific Configuration

### Full Configuration Example

```properties
sonar.projectKey=netresearch_my-typo3-extension
sonar.organization=netresearch
sonar.projectName=My TYPO3 Extension
sonar.projectVersion=1.0.0

# Source directories (TYPO3 extension structure)
sonar.sources=Classes,Configuration,Resources
sonar.tests=Tests

# Exclusions
sonar.exclusions=\
  **/vendor/**,\
  .Build/**,\
  var/**,\
  Resources/Public/JavaScript/Libs/**,\
  **/*.min.js,\
  **/*.min.css

# Test exclusions (don't analyze test code for coverage)
sonar.test.exclusions=Tests/**

# Coverage exclusions (files not to measure coverage for)
sonar.coverage.exclusions=\
  Configuration/**,\
  Resources/**,\
  ext_emconf.php,\
  ext_localconf.php,\
  ext_tables.php

# PHP configuration
sonar.php.version=8.2
sonar.php.coverage.reportPaths=var/log/coverage.xml
sonar.php.phpstan.reportPaths=var/log/phpstan.json
sonar.php.tests.reportPath=var/log/junit.xml

# Encoding
sonar.sourceEncoding=UTF-8

# Quality gate
sonar.qualitygate.wait=true
```

### Integration with runTests.sh

If using TYPO3's standard test runner:

```yaml
- name: Run tests with coverage
  run: |
    Build/Scripts/runTests.sh -s unit -x
    mv .Build/var/log/phpunit/coverage.xml var/log/coverage.xml
```

### Multi-TYPO3-Version Testing

```yaml
strategy:
  matrix:
    typo3: ['12.4', '13.0']
    php: ['8.2', '8.3']

steps:
  - name: Install TYPO3 ${{ matrix.typo3 }}
    run: |
      composer require "typo3/cms-core:^${{ matrix.typo3 }}" --no-update
      composer update --no-progress

  - name: Run tests
    run: vendor/bin/phpunit -c Build/phpunit/UnitTests.xml --coverage-clover coverage.xml

  # Only upload to SonarCloud once (main combination)
  - name: SonarCloud Scan
    if: matrix.typo3 == '13.0' && matrix.php == '8.2'
    uses: SonarSource/sonarcloud-github-action@master
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

## PHPStan Integration

### Export PHPStan Results

```bash
# Generate JSON report for SonarCloud
vendor/bin/phpstan analyze \
  --configuration Build/phpstan.neon \
  --error-format=json \
  --no-progress \
  > var/log/phpstan.json
```

### Configuration

```properties
# sonar-project.properties
sonar.php.phpstan.reportPaths=var/log/phpstan.json
```

SonarCloud imports PHPStan issues and displays them alongside its own analysis.

## Coverage Configuration

### PHPUnit Coverage

```xml
<!-- Build/phpunit/UnitTests.xml -->
<phpunit>
    <coverage>
        <report>
            <clover outputFile="var/log/coverage.xml"/>
        </report>
    </coverage>
    <source>
        <include>
            <directory>Classes</directory>
        </include>
        <exclude>
            <directory>Classes/ViewHelpers</directory>
        </exclude>
    </source>
</phpunit>
```

### Functional Test Coverage

```yaml
- name: Run functional tests with coverage
  run: |
    export typo3DatabaseDriver=pdo_sqlite
    vendor/bin/phpunit \
      -c Build/phpunit/FunctionalTests.xml \
      --coverage-clover var/log/coverage-functional.xml

- name: Merge coverage reports
  run: |
    # Use phpcov or merge manually
    vendor/bin/phpcov merge var/log/ --clover var/log/coverage.xml
```

## Quality Gates

### Recommended Gate for TYPO3 Extensions

| Condition | Threshold | Rationale |
|-----------|-----------|-----------|
| New bugs | 0 | No new bugs in PRs |
| New vulnerabilities | 0 | Security first |
| Coverage on new code | ≥80% | TYPO3 best practice |
| Duplicated lines | ≤3% | DRY principle |
| Maintainability rating | A | Clean code |

### Custom Gate Setup

1. Go to SonarCloud → Your Project → Project Settings → Quality Gates
2. Create new gate or copy "Sonar Way"
3. Adjust thresholds for TYPO3 requirements

## PR Decoration

SonarCloud automatically comments on PRs:

```
┌──────────────────────────────────────────────┐
│ Quality Gate passed                          │
├──────────────────────────────────────────────┤
│ Coverage: 85.2% (+3.1%)                     │
│                                              │
│ 0 Bugs                                       │
│ 0 Vulnerabilities                            │
│ 3 Code Smells (1 new)                       │
│ 0.8% Duplication                            │
└──────────────────────────────────────────────┘
```

## Badges

Add to your extension's README:

```markdown
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=your-org_your-extension&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=your-org_your-extension)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=your-org_your-extension&metric=coverage)](https://sonarcloud.io/summary/new_code?id=your-org_your-extension)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=your-org_your-extension&metric=sqale_rating)](https://sonarcloud.io/summary/new_code?id=your-org_your-extension)
```

## Common PHP Rules

SonarCloud catches TYPO3-relevant issues:

| Rule | Example | Severity |
|------|---------|----------|
| SQL Injection | Raw SQL without prepared statements | 🔴 Critical |
| XSS | Unescaped output in templates | 🔴 Critical |
| Hardcoded credentials | Passwords in code | 🔴 Critical |
| Deprecated API | `$GLOBALS['TYPO3_DB']` usage | 🟡 Major |
| Unused code | Dead methods, variables | 🟢 Minor |
| Complexity | Methods >20 cyclomatic complexity | 🟡 Major |
| Duplication | Copy-pasted code blocks | 🟢 Minor |

## Comparison with PHPStan

| Feature | SonarCloud | PHPStan |
|---------|------------|---------|
| Type analysis | Basic | ⭐⭐⭐⭐⭐ |
| Security rules | ⭐⭐⭐⭐⭐ | Basic |
| Coverage tracking | ✅ | ❌ |
| PR decoration | ✅ | ❌ |
| Quality gates | ✅ | ❌ |
| TYPO3-specific | Basic | ⭐⭐⭐⭐⭐ (with phpstan-typo3) |
| Code smells | ⭐⭐⭐⭐⭐ | ❌ |
| Duplication | ✅ | ❌ |

**Recommendation**: Use **both** - PHPStan for deep type analysis, SonarCloud for holistic quality view.

## Troubleshooting

### Coverage Not Showing

1. Verify coverage file exists and has content:
   ```bash
   cat var/log/coverage.xml | head -20
   ```

2. Check path in sonar-project.properties matches actual location

3. Ensure source files in coverage match `sonar.sources` paths

### PHPStan Results Not Imported

1. Verify JSON format:
   ```bash
   cat var/log/phpstan.json | jq .
   ```

2. Check file path in configuration

3. Run PHPStan with `|| true` to not fail on errors

### Quality Gate Failing

1. Check SonarCloud dashboard for specific failures
2. Review new code metrics (not overall)
3. Fix issues or adjust gate thresholds

### Scan Taking Too Long

Add exclusions for generated/vendor code:
```properties
sonar.exclusions=**/vendor/**,.Build/**,var/**,node_modules/**
```

## Best Practices

1. **Run locally first**: Test configuration before CI
   ```bash
   docker run --rm -v $(pwd):/usr/src sonarsource/sonar-scanner-cli
   ```

2. **Focus on new code**: Use quality gates on new code, not legacy

3. **Integrate PHPStan**: Import PHPStan results for comprehensive analysis

4. **Regular reviews**: Check security hotspots weekly

5. **Team onboarding**: Share SonarCloud access with all developers

## Resources

- [SonarCloud PHP Documentation](https://docs.sonarcloud.io/advanced-setup/languages/php/)
- [PHP Rules](https://rules.sonarsource.com/php/)
- [GitHub Actions Integration](https://docs.sonarcloud.io/advanced-setup/ci-based-analysis/github-actions-for-sonarcloud/)
- [TYPO3 Testing Best Practices](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/Index.html)
