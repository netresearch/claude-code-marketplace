#!/bin/bash
# check-tls-minimum.sh - Verify TLS 1.2+ minimum version is enforced in code
# Usage: ./check-tls-minimum.sh [directory]
# OpenSSF Badge Criteria: crypto_tls12 (Silver), crypto_used_network (Gold)
set -euo pipefail

TARGET_DIR="${1:-.}"

echo "=== TLS Minimum Version Check ==="
echo "Directory: $TARGET_DIR"
echo ""

# Track findings
ISSUES=0
GOOD=0
WARNINGS=0

# Patterns that indicate TLS configuration
declare -a TLS_PATTERNS

echo "=== Checking Go Files ==="
echo ""

# Go: Check for MinVersion configuration
GO_FILES=$(find "$TARGET_DIR" -name "*.go" ! -path "*/vendor/*" ! -path "*_test.go" 2>/dev/null || echo "")

if [ -n "$GO_FILES" ]; then
    # Check for proper TLS 1.2+ enforcement
    while IFS= read -r file; do
        [ -z "$file" ] && continue

        # Check for TLS configuration
        if grep -q "tls\.Config" "$file" 2>/dev/null; then
            # Check if MinVersion is set to TLS 1.2 or higher
            if grep -E "MinVersion.*tls\.VersionTLS1[234]" "$file" >/dev/null 2>&1; then
                echo "✓ $file: TLS 1.2+ minimum configured"
                GOOD=$((GOOD + 1))
            elif grep -E "MinVersion.*tls\.VersionTLS1[01]" "$file" >/dev/null 2>&1; then
                echo "✗ $file: Insecure TLS version (TLS 1.0 or 1.1)"
                ISSUES=$((ISSUES + 1))
            elif grep -q "InsecureSkipVerify.*true" "$file" 2>/dev/null; then
                echo "⚠ $file: InsecureSkipVerify enabled (certificate validation disabled)"
                WARNINGS=$((WARNINGS + 1))
            else
                echo "⚠ $file: TLS config found but MinVersion not explicitly set"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    done <<< "$GO_FILES"
fi

echo ""
echo "=== Checking Python Files ==="
echo ""

# Python: Check for SSL context configuration
PY_FILES=$(find "$TARGET_DIR" -name "*.py" ! -path "*/venv/*" ! -path "*/.venv/*" 2>/dev/null || echo "")

if [ -n "$PY_FILES" ]; then
    while IFS= read -r file; do
        [ -z "$file" ] && continue

        if grep -q "ssl\." "$file" 2>/dev/null; then
            # Check for proper TLS version
            if grep -E "PROTOCOL_TLS|TLSVersion\.TLSv1_2|TLSVersion\.TLSv1_3" "$file" >/dev/null 2>&1; then
                echo "✓ $file: Modern TLS protocol configured"
                GOOD=$((GOOD + 1))
            elif grep -E "PROTOCOL_SSLv[23]|PROTOCOL_TLSv1$|PROTOCOL_TLSv1_1" "$file" >/dev/null 2>&1; then
                echo "✗ $file: Deprecated protocol version"
                ISSUES=$((ISSUES + 1))
            elif grep -q "verify_mode.*CERT_NONE" "$file" 2>/dev/null; then
                echo "⚠ $file: Certificate verification disabled"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    done <<< "$PY_FILES"
fi

echo ""
echo "=== Checking JavaScript/TypeScript Files ==="
echo ""

# Node.js: Check for HTTPS/TLS configuration
JS_FILES=$(find "$TARGET_DIR" \( -name "*.js" -o -name "*.ts" \) ! -path "*/node_modules/*" 2>/dev/null || echo "")

if [ -n "$JS_FILES" ]; then
    while IFS= read -r file; do
        [ -z "$file" ] && continue

        if grep -E "https\.|tls\." "$file" 2>/dev/null; then
            if grep -q "rejectUnauthorized.*false" "$file" 2>/dev/null; then
                echo "⚠ $file: Certificate verification disabled"
                WARNINGS=$((WARNINGS + 1))
            elif grep -E "minVersion.*TLSv1\.[23]" "$file" >/dev/null 2>&1; then
                echo "✓ $file: TLS 1.2+ minimum configured"
                GOOD=$((GOOD + 1))
            elif grep -E "secureProtocol.*TLSv1_method|SSLv" "$file" >/dev/null 2>&1; then
                echo "✗ $file: Deprecated protocol"
                ISSUES=$((ISSUES + 1))
            fi
        fi
    done <<< "$JS_FILES"
fi

echo ""
echo "=== Checking Configuration Files ==="
echo ""

# Check common config files
CONFIG_FILES=$(find "$TARGET_DIR" \( -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.toml" \) \
    ! -path "*/node_modules/*" ! -path "*/vendor/*" 2>/dev/null | head -50 || echo "")

if [ -n "$CONFIG_FILES" ]; then
    while IFS= read -r file; do
        [ -z "$file" ] && continue

        # Check for TLS/SSL configurations in config files
        if grep -qi "ssl\|tls" "$file" 2>/dev/null; then
            if grep -Ei "tls_version.*1\.[01]|ssl_version.*[23]|min.*version.*1\.[01]" "$file" >/dev/null 2>&1; then
                echo "✗ $file: Deprecated TLS/SSL version in config"
                ISSUES=$((ISSUES + 1))
            elif grep -Ei "verify.*false|insecure.*true" "$file" >/dev/null 2>&1; then
                echo "⚠ $file: Certificate verification may be disabled"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    done <<< "$CONFIG_FILES"
fi

echo ""
echo "=== Summary ==="
echo ""
echo "Secure configurations: $GOOD"
echo "Issues (insecure): $ISSUES"
echo "Warnings: $WARNINGS"
echo ""

if [ "$ISSUES" -gt 0 ]; then
    echo "✗ TLS security issues found"
    echo ""
    echo "Recommendations:"
    echo "1. Set minimum TLS version to 1.2 or higher"
    echo "2. Enable certificate verification"
    echo "3. Use modern cipher suites"
    echo ""
    echo "Go example:"
    echo "  tlsConfig := &tls.Config{"
    echo "      MinVersion: tls.VersionTLS12,"
    echo "  }"
    echo ""
    echo "OpenSSF Badge: crypto_tls12 = Unmet"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo "⚠ TLS configuration warnings (review recommended)"
    echo ""
    echo "OpenSSF Badge: crypto_tls12 = Likely Met (verify configurations)"
    exit 0
elif [ "$GOOD" -eq 0 ]; then
    echo "No TLS configurations found to check."
    echo ""
    echo "If this project uses network communication:"
    echo "- Ensure TLS 1.2+ is enforced"
    echo "- Enable certificate verification"
    echo ""
    echo "OpenSSF Badge: crypto_tls12 = N/A (or needs manual review)"
    exit 0
else
    echo "✓ All TLS configurations meet security requirements"
    echo ""
    echo "OpenSSF Badge: crypto_tls12 = Met"
    exit 0
fi
