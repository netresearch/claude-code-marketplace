#!/bin/bash
# Security Audit Script
# Performs basic security checks on PHP projects

set -e

PROJECT_DIR="${1:-.}"
ERRORS=0
WARNINGS=0

echo "=== Security Audit ==="
echo "Directory: $PROJECT_DIR"
echo ""

# Check for hardcoded secrets
echo "=== Checking for Hardcoded Secrets ==="
if [[ -d "$PROJECT_DIR/src" ]]; then
    # Check for potential API keys/passwords
    SECRETS=$(grep -rn -E "(password|api_key|secret|token)\s*=\s*['\"][^'\"]+['\"]" "$PROJECT_DIR/src" --include="*.php" 2>/dev/null | grep -v "getenv\|env(" | head -10 || true)
    if [[ -n "$SECRETS" ]]; then
        echo "⚠️  Potential hardcoded secrets found:"
        echo "$SECRETS" | head -5
        ((WARNINGS++))
    else
        echo "✅ No obvious hardcoded secrets detected"
    fi
fi

# Check for SQL injection patterns
echo ""
echo "=== Checking for SQL Injection Patterns ==="
if [[ -d "$PROJECT_DIR/src" ]]; then
    SQL_VULN=$(grep -rn -E '\$_(GET|POST|REQUEST|COOKIE).*\.(query|execute|prepare)' "$PROJECT_DIR/src" --include="*.php" 2>/dev/null | head -5 || true)
    if [[ -n "$SQL_VULN" ]]; then
        echo "⚠️  Potential SQL injection patterns found:"
        echo "$SQL_VULN"
        ((WARNINGS++))
    else
        echo "✅ No obvious SQL injection patterns detected"
    fi
fi

# Check for XXE vulnerabilities
echo ""
echo "=== Checking for XXE Vulnerabilities ==="
if [[ -d "$PROJECT_DIR/src" ]]; then
    XXE_PATTERNS=$(grep -rn -E "(simplexml_load_string|DOMDocument|XMLReader)" "$PROJECT_DIR/src" --include="*.php" 2>/dev/null | head -10 || true)
    if [[ -n "$XXE_PATTERNS" ]]; then
        # Check if LIBXML_NOENT is used
        SECURED=$(grep -rn "LIBXML_NOENT\|LIBXML_NONET\|libxml_disable_entity_loader" "$PROJECT_DIR/src" --include="*.php" 2>/dev/null | wc -l || echo "0")
        if [[ "$SECURED" -eq 0 ]]; then
            echo "⚠️  XML parsing found without obvious XXE protection:"
            echo "$XXE_PATTERNS" | head -5
            ((WARNINGS++))
        else
            echo "✅ XML parsing with security flags detected"
        fi
    else
        echo "✅ No XML parsing detected"
    fi
fi

# Check for dangerous functions
echo ""
echo "=== Checking for Dangerous Functions ==="
if [[ -d "$PROJECT_DIR/src" ]]; then
    DANGEROUS=$(grep -rn -E "(eval|assert|create_function|preg_replace.*\/e|unserialize\s*\(\s*\$)" "$PROJECT_DIR/src" --include="*.php" 2>/dev/null | head -5 || true)
    if [[ -n "$DANGEROUS" ]]; then
        echo "⚠️  Potentially dangerous functions found:"
        echo "$DANGEROUS"
        ((WARNINGS++))
    else
        echo "✅ No obviously dangerous functions detected"
    fi
fi

# Check for file inclusion vulnerabilities
echo ""
echo "=== Checking for File Inclusion Vulnerabilities ==="
if [[ -d "$PROJECT_DIR/src" ]]; then
    INCLUDE_VULN=$(grep -rn -E "(include|require|include_once|require_once)\s*\(\s*\$" "$PROJECT_DIR/src" --include="*.php" 2>/dev/null | head -5 || true)
    if [[ -n "$INCLUDE_VULN" ]]; then
        echo "⚠️  Potential file inclusion vulnerabilities:"
        echo "$INCLUDE_VULN"
        ((WARNINGS++))
    else
        echo "✅ No obvious file inclusion vulnerabilities"
    fi
fi

# Check for XSS patterns
echo ""
echo "=== Checking for XSS Patterns ==="
if [[ -d "$PROJECT_DIR/src" ]]; then
    XSS_PATTERNS=$(grep -rn -E "echo\s+\\\$_(GET|POST|REQUEST)" "$PROJECT_DIR/src" --include="*.php" 2>/dev/null | head -5 || true)
    if [[ -n "$XSS_PATTERNS" ]]; then
        echo "⚠️  Potential XSS vulnerabilities:"
        echo "$XSS_PATTERNS"
        ((WARNINGS++))
    else
        echo "✅ No obvious XSS patterns detected"
    fi
fi

# Check for composer vulnerabilities
echo ""
echo "=== Checking Dependencies ==="
if [[ -f "$PROJECT_DIR/composer.lock" ]]; then
    if command -v composer &> /dev/null; then
        cd "$PROJECT_DIR"
        AUDIT_OUTPUT=$(composer audit 2>&1 || true)
        if echo "$AUDIT_OUTPUT" | grep -q "Found"; then
            echo "⚠️  Vulnerable dependencies found:"
            echo "$AUDIT_OUTPUT" | head -20
            ((WARNINGS++))
        else
            echo "✅ No known vulnerable dependencies"
        fi
    else
        echo "⚠️  Composer not available for dependency audit"
        ((WARNINGS++))
    fi
else
    echo "⚠️  No composer.lock found"
    ((WARNINGS++))
fi

# Check security headers in code
echo ""
echo "=== Checking Security Headers ==="
if [[ -d "$PROJECT_DIR/src" ]]; then
    HEADERS=$(grep -rn "X-Content-Type-Options\|X-Frame-Options\|Content-Security-Policy" "$PROJECT_DIR/src" --include="*.php" 2>/dev/null | wc -l || echo "0")
    if [[ "$HEADERS" -gt 0 ]]; then
        echo "✅ Security headers configuration found ($HEADERS references)"
    else
        echo "⚠️  No security headers configuration detected"
        ((WARNINGS++))
    fi
fi

# Check for CSRF protection
echo ""
echo "=== Checking CSRF Protection ==="
if [[ -d "$PROJECT_DIR/src" ]]; then
    CSRF=$(grep -rn -E "(csrf|_token|CsrfToken)" "$PROJECT_DIR/src" --include="*.php" 2>/dev/null | wc -l || echo "0")
    if [[ "$CSRF" -gt 0 ]]; then
        echo "✅ CSRF protection references found ($CSRF occurrences)"
    else
        echo "⚠️  No CSRF protection detected"
        ((WARNINGS++))
    fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [[ $ERRORS -gt 0 ]]; then
    echo "❌ Security audit FAILED"
    exit 1
elif [[ $WARNINGS -gt 3 ]]; then
    echo "⚠️  Security audit completed with significant warnings"
    exit 0
else
    echo "✅ Security audit PASSED"
    exit 0
fi
