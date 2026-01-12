<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: {{TIMESTAMP}} -->

# AGENTS.md — {{SCOPE_NAME}}

## Overview
{{SCOPE_DESCRIPTION}}

## Setup & environment
- Install: `composer install`
- PHP version: {{PHP_VERSION}}
- Framework: {{FRAMEWORK}}
- Required extensions: {{PHP_EXTENSIONS}}
- Environment variables: {{ENV_VARS}}

## Build & tests (prefer file-scoped)
- Typecheck a file: `vendor/bin/phpstan analyze {{FILE_PATH}} --level={{PHPSTAN_LEVEL}}`
- Format a file: `vendor/bin/php-cs-fixer fix {{FILE_PATH}}`
- Lint a file: `php -l {{FILE_PATH}}`
- Test a file: `vendor/bin/phpunit {{FILE_PATH}}`
- Build: {{BUILD_CMD}}

## Code style & conventions
- Follow PSR-12 coding standard
- Use strict types: `declare(strict_types=1);`
- Type hints: always use for parameters and return types
- Naming: `camelCase` for methods, `PascalCase` for classes
- Visibility: always declare (public, protected, private)
- PHPDoc: required for public APIs, include `@param` and `@return`
{{FRAMEWORK_CONVENTIONS}}

## Security & safety
- Validate and sanitize all user inputs
- Use prepared statements for database queries
- Escape output in templates
- Never use `eval()` or dynamic code execution
- Sensitive data: never log or expose in errors
- CSRF protection: enable for all forms
- XSS protection: escape all user-generated content

## PR/commit checklist
- [ ] Tests pass: `vendor/bin/phpunit`
- [ ] PHPStan Level {{PHPSTAN_LEVEL}} clean: `vendor/bin/phpstan analyze`
- [ ] PSR-12 compliant: `vendor/bin/php-cs-fixer fix --dry-run`
- [ ] No deprecated functions used
- [ ] Public methods have PHPDoc
- [ ] Security: inputs validated, outputs escaped

## Good vs. bad examples
**Good**: Proper type hints and strict types
```php
declare(strict_types=1);

public function calculateTotal(int $quantity, float $price): float
{
    return $quantity * $price;
}
```

**Bad**: Missing type hints
```php
public function calculateTotal($quantity, $price)
{
    return $quantity * $price;
}
```

**Good**: Prepared statements
```php
$stmt = $db->prepare('SELECT * FROM users WHERE id = :id');
$stmt->execute(['id' => $userId]);
```

**Bad**: String concatenation
```php
$result = $db->query("SELECT * FROM users WHERE id = " . $userId);
```

## When stuck
- Check PHP documentation: https://www.php.net
- {{FRAMEWORK_DOCS}}
- Review existing patterns in this codebase
- Check root AGENTS.md for project-wide conventions

## House Rules (optional)
{{HOUSE_RULES}}
