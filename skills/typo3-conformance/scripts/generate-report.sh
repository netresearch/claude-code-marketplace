#!/usr/bin/env bash

#
# Generate final conformance report with recommendations
#

set -e

PROJECT_DIR="${1}"
REPORT_FILE="${2}"
STRUCTURE_SCORE="${3:-15}"
CODING_SCORE="${4:-15}"
ARCH_SCORE="${5:-15}"
TEST_SCORE="${6:-15}"

cd "${PROJECT_DIR}"

# Calculate total
TOTAL_SCORE=$((STRUCTURE_SCORE + CODING_SCORE + ARCH_SCORE + TEST_SCORE + 10))

# Update summary table
sed -i "s/| Extension Architecture .*/| Extension Architecture | ${STRUCTURE_SCORE}\/20 | $(if [ ${STRUCTURE_SCORE} -ge 15 ]; then echo "✅ Passed"; else echo "⚠️  Issues"; fi) |/" "${REPORT_FILE}"
sed -i "/| Extension Architecture /a | Coding Guidelines | ${CODING_SCORE}/20 | $(if [ ${CODING_SCORE} -ge 15 ]; then echo "✅ Passed"; else echo "⚠️  Issues"; fi) |" "${REPORT_FILE}" 2>/dev/null || true
sed -i "/| Coding Guidelines /a | PHP Architecture | ${ARCH_SCORE}/20 | $(if [ ${ARCH_SCORE} -ge 15 ]; then echo "✅ Passed"; else echo "⚠️  Issues"; fi) |" "${REPORT_FILE}" 2>/dev/null || true
sed -i "/| PHP Architecture /a | Testing Standards | ${TEST_SCORE}/20 | $(if [ ${TEST_SCORE} -ge 15 ]; then echo "✅ Passed"; else echo "⚠️  Issues"; fi) |" "${REPORT_FILE}" 2>/dev/null || true
sed -i "/| Testing Standards /a | Best Practices | 10/20 | ℹ️  Partial |" "${REPORT_FILE}" 2>/dev/null || true
sed -i "/| Best Practices /a | **TOTAL** | **${TOTAL_SCORE}/100** | $(if [ ${TOTAL_SCORE} -ge 80 ]; then echo "✅ Excellent"; elif [ ${TOTAL_SCORE} -ge 60 ]; then echo "✅ Good"; else echo "⚠️  Fair"; fi) |" "${REPORT_FILE}" 2>/dev/null || true

# Add final sections
cat >> "${REPORT_FILE}" <<EOF

---

## 5. Best Practices Assessment

### Project Infrastructure
- **README.md:** $(if [ -f "README.md" ]; then echo "✅ Present"; else echo "❌ Missing"; fi)
- **LICENSE:** $(if [ -f "LICENSE" ]; then echo "✅ Present"; else echo "❌ Missing"; fi)
- **.editorconfig:** $(if [ -f ".editorconfig" ]; then echo "✅ Present"; else echo "⚠️  Missing"; fi)
- **.gitignore:** $(if [ -f ".gitignore" ]; then echo "✅ Present"; else echo "⚠️  Missing"; fi)

### Code Quality Tools
- **php-cs-fixer:** $(if [ -f ".php-cs-fixer.dist.php" ] || [ -f ".php-cs-fixer.php" ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)
- **phpstan:** $(if [ -f "phpstan.neon" ] || [ -f "phpstan.neon.dist" ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)
- **rector:** $(if [ -f "rector.php" ]; then echo "✅ Configured"; else echo "ℹ️  Not configured"; fi)

### CI/CD Pipeline
- **GitHub Actions:** $(if [ -d ".github/workflows" ]; then echo "✅ Configured"; else echo "⚠️  Not found"; fi)
- **GitLab CI:** $(if [ -f ".gitlab-ci.yml" ]; then echo "✅ Configured"; else echo "ℹ️  Not found"; fi)

---

## Overall Assessment

**Total Score: ${TOTAL_SCORE}/100**

$(if [ ${TOTAL_SCORE} -ge 80 ]; then
cat <<END
### ✅ EXCELLENT Conformance Level

Your TYPO3 extension demonstrates strong adherence to official standards and best practices.

**Strengths:**
- Well-structured architecture following TYPO3 conventions
- Modern PHP patterns with dependency injection
- Good code quality and testing coverage
- Proper documentation and infrastructure

**Minor Improvements:**
- Continue maintaining high standards
- Keep dependencies updated
- Monitor code coverage trends
END
elif [ ${TOTAL_SCORE} -ge 60 ]; then
cat <<END
### ✅ GOOD Conformance Level

Your TYPO3 extension follows most standards with some areas for improvement.

**Next Steps:**
1. Address critical issues identified above
2. Improve test coverage
3. Add missing configuration files
4. Update deprecated patterns

**Timeline:** 2-4 weeks for improvements
END
else
cat <<END
### ⚠️  FAIR Conformance Level

Your TYPO3 extension requires significant improvements to meet TYPO3 standards.

**Priority Actions:**
1. Fix critical file structure issues
2. Migrate deprecated patterns (GeneralUtility::makeInstance, \$GLOBALS)
3. Add comprehensive testing infrastructure
4. Improve code quality (strict types, PHPDoc, PSR-12)
5. Add project infrastructure (CI/CD, quality tools)

**Timeline:** 4-8 weeks for comprehensive improvements
END
fi)

---

## Quick Action Checklist

### High Priority (Fix Now)
$(if [ ${STRUCTURE_SCORE} -lt 15 ]; then echo "- [ ] Fix critical file structure issues (missing required files/directories)"; fi)
$(if grep -q "GeneralUtility::makeInstance" Classes/ 2>/dev/null; then echo "- [ ] Migrate GeneralUtility::makeInstance to constructor injection"; fi)
$(if grep -q '\$GLOBALS\[' Classes/ 2>/dev/null; then echo "- [ ] Remove \$GLOBALS access, use dependency injection"; fi)
$(if [ ! -f "Configuration/Services.yaml" ]; then echo "- [ ] Add Configuration/Services.yaml with DI configuration"; fi)

### Medium Priority (Fix Soon)
$(if [ ${CODING_SCORE} -lt 15 ]; then echo "- [ ] Add declare(strict_types=1) to all PHP files"; fi)
$(if [ ${CODING_SCORE} -lt 15 ]; then echo "- [ ] Replace array() with [] short syntax"; fi)
$(if [ ${TEST_SCORE} -lt 15 ]; then echo "- [ ] Add unit tests for untested classes"; fi)
$(if [ ! -d "Tests/Functional" ]; then echo "- [ ] Add functional tests for repositories"; fi)

### Low Priority (Improve When Possible)
$(if [ ! -f ".php-cs-fixer.dist.php" ]; then echo "- [ ] Configure PHP CS Fixer"; fi)
$(if [ ! -f "phpstan.neon" ]; then echo "- [ ] Configure PHPStan for static analysis"; fi)
$(if [ ! -d ".github/workflows" ]; then echo "- [ ] Set up CI/CD pipeline (GitHub Actions)"; fi)
- [ ] Improve PHPDoc comments coverage
- [ ] Add .editorconfig for consistent formatting

---

## Resources

- **TYPO3 Extension Architecture:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ExtensionArchitecture/
- **Coding Guidelines:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/CodingGuidelines/
- **Dependency Injection:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/ApiOverview/DependencyInjection/
- **Testing Documentation:** https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/
- **Tea Extension (Best Practice):** https://github.com/TYPO3BestPractices/tea

---

*Report generated by TYPO3 Extension Conformance Checker*
EOF

echo "Final report generated successfully"
