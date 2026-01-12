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

# Documentation checks delegated to check-documentation.sh (typo3-docs skill standards)
if [ -d "Documentation" ]; then
    echo "- ✅ Documentation/ directory present (details in Documentation check)"
else
    echo "- ⚠️  Documentation/ directory missing"
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

# Check for PHP files in root (except allowed config files)
# Show all files but distinguish between tracked (issues) and untracked (info)
tracked_files=()
untracked_files=()
all_root_php_files=()

# Allowed PHP config files in root (standard tool configurations)
allowed_root_php=(
    ".php-cs-fixer.php"
    ".php-cs-fixer.dist.php"
    "php-cs-fixer.php"
    "rector.php"
    "fractor.php"
    "ecs.php"
    "phpstan.php"
    "phpunit.php"
    "captainhook.php"
    "grumphp.php"
    "pint.php"
    "scoper.inc.php"
)

# Find all PHP files in root (except ext_* files and allowed config files)
while IFS= read -r file; do
    filename=$(basename "$file")
    # Skip ext_* files
    if [[ "$filename" == ext_*.php ]]; then
        continue
    fi
    # Check if file is in allowed list
    is_allowed=0
    for allowed in "${allowed_root_php[@]}"; do
        if [[ "$filename" == "$allowed" ]]; then
            is_allowed=1
            break
        fi
    done
    if [ $is_allowed -eq 0 ]; then
        all_root_php_files+=("$filename")
    fi
done < <(find . -maxdepth 1 -name "*.php" 2>/dev/null || true)

# Check if files are tracked in git (if git repository exists)
if [ -d ".git" ]; then
    for file in "${all_root_php_files[@]}"; do
        if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
            tracked_files+=("$file")
        else
            untracked_files+=("$file")
        fi
    done
else
    # No git repository - treat all files as tracked (potential issues)
    tracked_files=("${all_root_php_files[@]}")
fi

# Report tracked files (these are issues)
if [ ${#tracked_files[@]} -gt 0 ]; then
    if [ -d ".git" ]; then
        echo "- ❌ ${#tracked_files[@]} PHP file(s) in root directory committed to repository:"
    else
        echo "- ❌ ${#tracked_files[@]} PHP file(s) found in root directory:"
    fi
    for file in "${tracked_files[@]}"; do
        echo "  - ${file} (ISSUE: should be in Classes/ or Build/)"
    done
    has_issues=1
fi

# Report untracked files (informational only)
if [ ${#untracked_files[@]} -gt 0 ]; then
    echo "- ℹ️  ${#untracked_files[@]} untracked PHP file(s) in root (ignored, not committed):"
    for file in "${untracked_files[@]}"; do
        echo "  - ${file} (local file, not in repository)"
    done
fi

# Success message if no files found
if [ ${#all_root_php_files[@]} -eq 0 ]; then
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
