# TYPO3 Coding Guidelines

**Source:** TYPO3 Core API Reference - Coding Guidelines
**Purpose:** PHP code style, formatting standards, and PSR-12 compliance for TYPO3 extensions

## PSR-12 Compliance

TYPO3 follows **PSR-12: Extended Coding Style** as the foundation for PHP code style.

**Key PSR-12 Requirements:**
- 4 spaces for indentation (NO tabs)
- Unix line endings (LF)
- Maximum line length: 120 characters (soft limit), 80 recommended
- Opening braces for classes/methods on same line
- One statement per line
- Visibility MUST be declared on all properties and methods

## Identifier Naming Conventions

### Variables and Methods: camelCase

```php
// ✅ Right
$userName = 'John';
$totalPrice = 100;
public function calculateTotal() {}
public function getUserData() {}

// ❌ Wrong
$user_name = 'John';           // snake_case
$UserName = 'John';            // PascalCase
public function CalculateTotal() {}  // PascalCase
public function get_user_data() {}   // snake_case
```

### Classes: UpperCamelCase (PascalCase)

```php
// ✅ Right
class UserController {}
class PaymentService {}
class ProductRepository {}

// ❌ Wrong
class userController {}        // camelCase
class payment_service {}       // snake_case
class productRepository {}     // camelCase
```

### Constants: SCREAMING_SNAKE_CASE

```php
// ✅ Right
const MAX_UPLOAD_SIZE = 1024;
const API_ENDPOINT = 'https://api.example.com';
private const DEFAULT_TIMEOUT = 30;

// ❌ Wrong
const maxUploadSize = 1024;    // camelCase
const ApiEndpoint = '...';     // PascalCase
```

### Namespaces: UpperCamelCase

```php
// ✅ Right
namespace Vendor\ExtensionKey\Domain\Model;
namespace Vendor\ExtensionKey\Controller;

// ❌ Wrong
namespace vendor\extension_key\domain\model;
namespace Vendor\extension_key\Controller;
```

## Function and Method Naming

### Descriptive Names with Verbs

```php
// ✅ Right: Verb + noun, descriptive
public function getUserById(int $id): ?User {}
public function calculateTotalPrice(array $items): float {}
public function isValidEmail(string $email): bool {}
public function hasPermission(string $action): bool {}

// ❌ Wrong: No verb, ambiguous
public function user(int $id) {}
public function price(array $items) {}
public function email(string $email) {}
public function permission(string $action) {}
```

### Boolean Methods: is/has/can/should

```php
// ✅ Right
public function isActive(): bool {}
public function hasAccess(): bool {}
public function canEdit(): bool {}
public function shouldRender(): bool {}

// ❌ Wrong
public function active(): bool {}
public function access(): bool {}
public function checkEdit(): bool {}
```

## Array Formatting

### Short Syntax Only

```php
// ✅ Right: Short array syntax
$items = [];
$config = ['foo' => 'bar'];
$users = [
    ['name' => 'John', 'age' => 30],
    ['name' => 'Jane', 'age' => 25],
];

// ❌ Wrong: Long array syntax (deprecated)
$items = array();
$config = array('foo' => 'bar');
```

### Multi-line Array Formatting

```php
// ✅ Right: Proper indentation and trailing comma
$configuration = [
    'key1' => 'value1',
    'key2' => 'value2',
    'nested' => [
        'subkey1' => 'subvalue1',
        'subkey2' => 'subvalue2',
    ],  // Trailing comma
];

// ❌ Wrong: No trailing comma, inconsistent indentation
$configuration = [
    'key1' => 'value1',
    'key2' => 'value2',
  'nested' => [
      'subkey1' => 'subvalue1',
      'subkey2' => 'subvalue2'
  ]
];
```

## Conditional Statement Layout

### If/ElseIf/Else

```php
// ✅ Right: Proper spacing and braces
if ($condition) {
    doSomething();
} elseif ($otherCondition) {
    doSomethingElse();
} else {
    doDefault();
}

// ❌ Wrong: Missing spaces, wrong brace placement
if($condition){
    doSomething();
}
else if ($otherCondition) {
    doSomethingElse();
}
else {
    doDefault();
}
```

### Switch Statements

```php
// ✅ Right
switch ($status) {
    case 'active':
        processActive();
        break;
    case 'pending':
        processPending();
        break;
    default:
        processDefault();
}

// ❌ Wrong: Inconsistent indentation
switch ($status) {
case 'active':
    processActive();
    break;
case 'pending':
processPending();
break;
default:
processDefault();
}
```

## String Handling

### Single Quotes Default

```php
// ✅ Right: Single quotes for simple strings
$message = 'Hello, World!';
$path = 'path/to/file.php';

// ❌ Wrong: Unnecessary double quotes
$message = "Hello, World!";  // No variable interpolation
$path = "path/to/file.php";
```

### Double Quotes for Interpolation

```php
// ✅ Right: Double quotes when interpolating
$name = 'John';
$message = "Hello, {$name}!";

// ❌ Wrong: Concatenation instead of interpolation
$message = 'Hello, ' . $name . '!';  // Less readable
```

### String Concatenation

```php
// ✅ Right: Spaces around concatenation operator
$fullPath = $basePath . '/' . $filename;
$message = 'Hello ' . $name . ', welcome!';

// ❌ Wrong: No spaces around operator
$fullPath = $basePath.'/'.$filename;
$message = 'Hello '.$name.', welcome!';
```

## PHPDoc Comment Standards

### Class Documentation

```php
// ✅ Right: Complete class documentation
/**
 * Service for calculating product prices with tax and discounts
 *
 * This service handles complex price calculations including:
 * - Tax rates based on country
 * - Quantity discounts
 * - Promotional codes
 *
 * @author John Doe <john@example.com>
 * @license GPL-2.0-or-later
 */
final class PriceCalculationService
{
    // ...
}
```

### Method Documentation

```php
// ✅ Right: Complete method documentation
/**
 * Calculate total price with tax for given items
 *
 * @param array<int, array{product: Product, quantity: int}> $items
 * @param string $countryCode ISO 3166-1 alpha-2 country code
 * @param float $discountPercent Discount percentage (0-100)
 * @return float Total price including tax
 * @throws \InvalidArgumentException If country code is invalid
 */
public function calculateTotal(
    array $items,
    string $countryCode,
    float $discountPercent = 0.0
): float {
    // ...
}

// ❌ Wrong: Missing or incomplete documentation
/**
 * Calculates total
 */
public function calculateTotal($items, $countryCode, $discountPercent = 0.0) {
    // Missing param types, descriptions, return type
}
```

### Property Documentation

```php
// ✅ Right
/**
 * @var UserRepository User data repository
 */
private readonly UserRepository $userRepository;

/**
 * @var array<string, mixed> Configuration options
 */
private array $config = [];

// ❌ Wrong: No type hint or description
/**
 * @var mixed
 */
private $userRepository;
```

## Curly Brace Placement

### Classes and Methods: Same Line

```php
// ✅ Right: Opening brace on same line
class MyController
{
    public function indexAction(): ResponseInterface
    {
        // ...
    }
}

// ❌ Wrong: Opening brace on new line (K&R style)
class MyController {
    public function indexAction(): ResponseInterface {
        // ...
    }
}
```

### Control Structures: Same Line

```php
// ✅ Right
if ($condition) {
    doSomething();
}

foreach ($items as $item) {
    processItem($item);
}

// ❌ Wrong: Opening brace on new line
if ($condition)
{
    doSomething();
}
```

## Namespace and Use Statements

### Namespace Structure

```php
// ✅ Right: Proper namespace declaration
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Domain\Model;

use TYPO3\CMS\Extbase\DomainObject\AbstractEntity;

class Product extends AbstractEntity
{
    // ...
}
```

### Use Statements Organization

```php
// ✅ Right: Grouped and sorted
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Controller;

use Psr\Http\Message\ResponseInterface;
use TYPO3\CMS\Backend\Template\ModuleTemplateFactory;
use TYPO3\CMS\Core\Imaging\IconFactory;
use TYPO3\CMS\Extbase\Mvc\Controller\ActionController;
use Vendor\ExtensionKey\Domain\Repository\ProductRepository;

// ❌ Wrong: Unsorted, mixed
use TYPO3\CMS\Extbase\Mvc\Controller\ActionController;
use Vendor\ExtensionKey\Domain\Repository\ProductRepository;
use Psr\Http\Message\ResponseInterface;
use TYPO3\CMS\Core\Imaging\IconFactory;
```

## Type Declarations

### Strict Types

```php
// ✅ Right: declare(strict_types=1) at the top
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Service;

class MyService
{
    public function calculate(int $value): float
    {
        return $value * 1.19;
    }
}

// ❌ Wrong: No strict types declaration
<?php
namespace Vendor\ExtensionKey\Service;

class MyService
{
    public function calculate($value)  // No type hints
    {
        return $value * 1.19;
    }
}
```

### Property Type Declarations (PHP 7.4+)

```php
// ✅ Right: Typed properties
class User
{
    private string $username;
    private int $id;
    private ?string $email = null;
    private array $roles = [];
}

// ❌ Wrong: No type declarations
class User
{
    private $username;
    private $id;
    private $email;
    private $roles;
}
```

## File Structure

### Standard File Template

```php
<?php
declare(strict_types=1);

/*
 * This file is part of the TYPO3 CMS project.
 *
 * It is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, either version 2
 * of the License, or any later version.
 *
 * For the full copyright and license information, please read the
 * LICENSE.txt file that was distributed with this source code.
 *
 * The TYPO3 project - inspiring people to share!
 */

namespace Vendor\ExtensionKey\Domain\Model;

use TYPO3\CMS\Extbase\DomainObject\AbstractEntity;

/**
 * Product model
 */
class Product extends AbstractEntity
{
    /**
     * @var string Product title
     */
    private string $title = '';

    public function getTitle(): string
    {
        return $this->title;
    }

    public function setTitle(string $title): void
    {
        $this->title = $title;
    }
}
```

## Conformance Checklist

- [ ] All PHP files use 4 spaces for indentation (NO tabs)
- [ ] Variables and methods use camelCase
- [ ] Classes use UpperCamelCase
- [ ] Constants use SCREAMING_SNAKE_CASE
- [ ] Array short syntax [] used (not array())
- [ ] Multi-line arrays have trailing commas
- [ ] Strings use single quotes by default
- [ ] String concatenation has spaces around `.` operator
- [ ] All classes have PHPDoc comments
- [ ] All public methods have PHPDoc with @param and @return
- [ ] Opening braces on same line for classes/methods
- [ ] declare(strict_types=1) at top of all PHP files
- [ ] Proper namespace structure matching directory
- [ ] Use statements grouped and sorted
- [ ] Type declarations on all properties and method parameters
- [ ] Maximum line length 120 characters
- [ ] Unix line endings (LF)
