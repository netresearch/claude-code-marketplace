#!/usr/bin/env bash

#
# TYPO3 File Structure Conformance Checker
#
# Validates extension directory structure and required files
#

set -e

PROJECT_DIR="${1:-.}"
cd "${PROJECT_DIR}"

echo "## 1. File Structure Conformance"
echo ""

# Track issues
has_issues=0

echo "### Required Files"
echo ""

# Check required files
if [ -f "composer.json" ]; then
    echo "- ✅ composer.json present"
else
    echo "- ❌ composer.json missing (CRITICAL)"
    has_issues=1
fi

if [ -f "ext_emconf.php" ]; then
    echo "- ✅ ext_emconf.php present"
else
    echo "- ⚠️  ext_emconf.php missing (required for TER publication)"
fi

if [ -f "Documentation/Index.rst" ]; then
    echo "- ✅ Documentation/Index.rst present"
else
    echo "- ⚠️  Documentation/Index.rst missing (required for docs.typo3.org)"
fi

if [ -f "Documentation/Settings.cfg" ]; then
    echo "- ✅ Documentation/Settings.cfg present"
else
    echo "- ⚠️  Documentation/Settings.cfg missing (required for docs.typo3.org)"
fi

echo ""
echo "### Directory Structure"
echo ""

# Check core directories
if [ -d "Classes" ]; then
    echo "- ✅ Classes/ directory present"
    # Check for common subdirectories
    if [ -d "Classes/Controller" ]; then
        echo "  - ✅ Classes/Controller/ found"
    fi
    if [ -d "Classes/Domain/Model" ]; then
        echo "  - ✅ Classes/Domain/Model/ found"
    fi
    if [ -d "Classes/Domain/Repository" ]; then
        echo "  - ✅ Classes/Domain/Repository/ found"
    fi
else
    echo "- ❌ Classes/ directory missing (CRITICAL)"
    has_issues=1
fi

if [ -d "Configuration" ]; then
    echo "- ✅ Configuration/ directory present"
    if [ -d "Configuration/TCA" ]; then
        echo "  - ✅ Configuration/TCA/ found"
    fi
    if [ -f "Configuration/Services.yaml" ]; then
        echo "  - ✅ Configuration/Services.yaml found"
    else
        echo "  - ⚠️  Configuration/Services.yaml missing (recommended)"
    fi
    if [ -d "Configuration/Backend" ]; then
        echo "  - ✅ Configuration/Backend/ found"
    fi
else
    echo "- ⚠️  Configuration/ directory missing"
fi

if [ -d "Resources" ]; then
    echo "- ✅ Resources/ directory present"
    if [ -d "Resources/Private" ] && [ -d "Resources/Public" ]; then
        echo "  - ✅ Resources/Private/ and Resources/Public/ properly separated"
    else
        echo "  - ⚠️  Resources/ not properly separated into Private/ and Public/"
    fi
else
    echo "- ⚠️  Resources/ directory missing"
fi

if [ -d "Tests" ]; then
    echo "- ✅ Tests/ directory present"
    if [ -d "Tests/Unit" ]; then
        echo "  - ✅ Tests/Unit/ found"
    else
        echo "  - ⚠️  Tests/Unit/ missing"
    fi
    if [ -d "Tests/Functional" ]; then
        echo "  - ✅ Tests/Functional/ found"
    else
        echo "  - ⚠️  Tests/Functional/ missing"
    fi
else
    echo "- ⚠️  Tests/ directory missing"
fi

echo ""
echo "### Anti-Patterns Check"
echo ""

# Check for PHP files in root (except ext_* files)
root_php_files=$(find . -maxdepth 1 -name "*.php" ! -name "ext_*.php" | wc -l)
if [ ${root_php_files} -gt 0 ]; then
    echo "- ❌ ${root_php_files} PHP files found in root directory (should be in Classes/)"
    find . -maxdepth 1 -name "*.php" ! -name "ext_*.php" | sed 's/^/  - /'
    has_issues=1
else
    echo "- ✅ No PHP files in root (except ext_* files)"
fi

# Check for deprecated ext_tables.php
if [ -f "ext_tables.php" ]; then
    echo "- ⚠️  ext_tables.php present (consider migrating to Configuration/Backend/)"
fi

# Check for wrong directory naming
if [ -d "Classes/Controllers" ]; then
    echo "- ❌ Classes/Controllers/ found (should be Controller/ singular)"
    has_issues=1
fi

if [ -d "Classes/Helpers" ]; then
    echo "- ⚠️  Classes/Helpers/ found (should use Utility/ instead)"
fi

echo ""
echo "---"
echo ""

# Return appropriate exit code
if [ ${has_issues} -eq 0 ]; then
    exit 0
else
    exit 1
fi
