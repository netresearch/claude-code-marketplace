#!/usr/bin/env bash

#
# TYPO3 PHP Architecture Conformance Checker
#
# Validates dependency injection, services, events, and architectural patterns
#

set -e

PROJECT_DIR="${1:-.}"
cd "${PROJECT_DIR}"

echo "## 3. PHP Architecture Conformance"
echo ""

has_issues=0

### Check for Services.yaml
echo "### Dependency Injection Configuration"
echo ""

if [ -f "Configuration/Services.yaml" ]; then
    echo "- ✅ Configuration/Services.yaml present"

    # Check if it has basic DI configuration
    if grep -q "autowire: true" Configuration/Services.yaml; then
        echo "  - ✅ Autowiring enabled"
    else
        echo "  - ⚠️  Autowiring not enabled"
    fi

    if grep -q "autoconfigure: true" Configuration/Services.yaml; then
        echo "  - ✅ Autoconfiguration enabled"
    else
        echo "  - ⚠️  Autoconfiguration not enabled"
    fi
else
    echo "- ❌ Configuration/Services.yaml missing (CRITICAL)"
    has_issues=1
fi

### Check for deprecated patterns
echo ""
echo "### Deprecated Pattern Detection"
echo ""

# Check for GeneralUtility::makeInstance
makeinstance_count=$(grep -r "GeneralUtility::makeInstance" Classes/ 2>/dev/null | wc -l)
if [ $makeinstance_count -eq 0 ]; then
    echo "- ✅ No GeneralUtility::makeInstance() usage found"
else
    echo "- ❌ ${makeinstance_count} instances of GeneralUtility::makeInstance() found"
    echo "  - Should use constructor injection instead"
    has_issues=1
fi

# Check for global state access
globals_count=$(grep -r '\$GLOBALS\[' Classes/ 2>/dev/null | wc -l)
if [ $globals_count -eq 0 ]; then
    echo "- ✅ No \$GLOBALS access found"
else
    echo "- ❌ ${globals_count} instances of \$GLOBALS access found"
    echo "  - Should use dependency injection instead"
    has_issues=1
fi

### Check for constructor injection
echo ""
echo "### Dependency Injection Patterns"
echo ""

# Check for constructors with dependencies
constructors=$(grep -r "public function __construct" Classes/ 2>/dev/null | wc -l)
if [ $constructors -gt 0 ]; then
    echo "- ✅ ${constructors} classes use constructors (potential DI)"
else
    echo "- ⚠️  No constructor injection found"
fi

# Check for method injection (inject* methods)
inject_methods=$(grep -r "public function inject[A-Z]" Classes/ 2>/dev/null | wc -l)
if [ $inject_methods -gt 0 ]; then
    echo "- ⚠️  ${inject_methods} method injection patterns found (inject*)"
    echo "  - Consider using constructor injection instead (more modern)"
fi

### Check for PSR-14 events
echo ""
echo "### Event System"
echo ""

# Check for event classes
event_classes=$(find Classes/ -type d -name "Event" 2>/dev/null || echo "")
if [ -n "$event_classes" ]; then
    event_count=$(find Classes/ -path "*/Event/*.php" 2>/dev/null | wc -l)
    echo "- ✅ ${event_count} event classes found in Classes/Event/"
else
    echo "- ⚠️  No Classes/Event/ directory found"
fi

# Check for event listeners
listener_classes=$(find Classes/ -type d -name "EventListener" 2>/dev/null || echo "")
if [ -n "$listener_classes" ]; then
    listener_count=$(find Classes/ -path "*/EventListener/*.php" 2>/dev/null | wc -l)
    echo "- ✅ ${listener_count} event listeners found in Classes/EventListener/"
else
    echo "- ⚠️  No Classes/EventListener/ directory found"
fi

### Check for Extbase patterns
echo ""
echo "### Extbase Architecture"
echo ""

# Check for domain models
if [ -d "Classes/Domain/Model" ]; then
    model_count=$(find Classes/Domain/Model/ -name "*.php" 2>/dev/null | wc -l)
    echo "- ✅ ${model_count} domain models found"
else
    echo "- ℹ️  No Classes/Domain/Model/ (not using Extbase models)"
fi

# Check for repositories
if [ -d "Classes/Domain/Repository" ]; then
    repo_count=$(find Classes/Domain/Repository/ -name "*.php" 2>/dev/null | wc -l)
    echo "- ✅ ${repo_count} repositories found"

    # Check if repositories extend Repository
    proper_repos=$(grep -r "extends.*Repository" Classes/Domain/Repository/ 2>/dev/null | wc -l)
    if [ $proper_repos -gt 0 ]; then
        echo "  - ✅ Repositories extend base Repository class"
    fi
else
    echo "- ℹ️  No Classes/Domain/Repository/ (not using Extbase repositories)"
fi

# Check for controllers
if [ -d "Classes/Controller" ]; then
    controller_count=$(find Classes/Controller/ -name "*.php" 2>/dev/null | wc -l)
    echo "- ✅ ${controller_count} controllers found"

    # Check if controllers extend ActionController
    proper_controllers=$(grep -r "extends ActionController" Classes/Controller/ 2>/dev/null | wc -l)
    if [ $proper_controllers -gt 0 ]; then
        echo "  - ✅ Controllers extend ActionController"
    fi
fi

### Check for PSR-15 middleware
echo ""
echo "### Middleware"
echo ""

if [ -f "Configuration/RequestMiddlewares.php" ]; then
    echo "- ✅ Configuration/RequestMiddlewares.php present"

    middleware_count=$(find Classes/ -path "*/Middleware/*.php" 2>/dev/null | wc -l)
    if [ $middleware_count -gt 0 ]; then
        echo "  - ✅ ${middleware_count} middleware classes found"
    fi
else
    echo "- ℹ️  No Configuration/RequestMiddlewares.php (not using custom middleware)"
fi

echo ""
echo "### Summary"
echo ""

if [ $has_issues -eq 0 ]; then
    echo "- ✅ **PHP Architecture: PASSED**"
else
    echo "- ⚠️  **PHP Architecture: ISSUES FOUND**"
fi

echo ""
echo "---"
echo ""

exit $has_issues
