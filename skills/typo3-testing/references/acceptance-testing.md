# Acceptance Testing in TYPO3

Acceptance tests verify complete user workflows through browser automation using Codeception and Selenium.

## When to Use Acceptance Tests

- Testing complete user journeys (login → browse → checkout)
- Frontend functionality validation
- Cross-browser compatibility
- JavaScript-heavy interactions
- Visual regression testing

## Requirements

- Docker and Docker Compose
- Codeception
- Selenium (ChromeDriver or Firefox)
- Web server (Nginx/Apache)

## Setup

### 1. Install Codeception

```bash
composer require --dev codeception/codeception codeception/module-webdriver codeception/module-asserts
```

### 2. Initialize Codeception

```bash
vendor/bin/codecept bootstrap
```

### 3. Docker Compose

Create `Build/docker-compose.yml`:

```yaml
version: '3.8'

services:
  web:
    image: php:8.2-apache
    volumes:
      - ../../:/var/www/html
    ports:
      - "8000:80"
    environment:
      - TYPO3_CONTEXT=Testing
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: typo3_test
    ports:
      - "3306:3306"

  selenium:
    image: selenium/standalone-chrome:latest
    ports:
      - "4444:4444"
    shm_size: 2gb
```

### 4. Codeception Configuration

Create `codeception.yml`:

```yaml
paths:
    tests: Tests/Acceptance
    output: var/log/acceptance
    data: Tests/Acceptance/_data
    support: Tests/Acceptance/_support
    envs: Tests/Acceptance/_envs

actor_suffix: Tester

extensions:
    enabled:
        - Codeception\Extension\RunFailed

params:
    - .env.testing

suites:
    acceptance:
        actor: AcceptanceTester
        modules:
            enabled:
                - WebDriver:
                    url: http://web:8000
                    browser: chrome
                    host: selenium
                    port: 4444
                - \\Helper\\Acceptance
```

## Test Structure

### Basic Test (Cest)

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Acceptance;

use Vendor\Extension\Tests\Acceptance\AcceptanceTester;

final class LoginCest
{
    public function _before(AcceptanceTester $I): void
    {
        // Runs before each test
        $I->amOnPage('/');
    }

    public function loginAsBackendUser(AcceptanceTester $I): void
    {
        $I->amOnPage('/typo3');
        $I->fillField('username', 'admin');
        $I->fillField('password', 'password');
        $I->click('Login');

        $I->see('Dashboard');
        $I->seeInCurrentUrl('/typo3/module/dashboard');
    }

    public function loginFailsWithWrongPassword(AcceptanceTester $I): void
    {
        $I->amOnPage('/typo3');
        $I->fillField('username', 'admin');
        $I->fillField('password', 'wrong_password');
        $I->click('Login');

        $I->see('Login error');
        $I->seeInCurrentUrl('/typo3');
    }
}
```

### Page Objects Pattern

Create reusable page objects:

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Acceptance\PageObject;

use Vendor\Extension\Tests\Acceptance\AcceptanceTester;

final class LoginPage
{
    public static string $URL = '/typo3';

    public static string $usernameField = '#username';
    public static string $passwordField = '#password';
    public static string $loginButton = 'button[type="submit"]';

    private AcceptanceTester $tester;

    public function __construct(AcceptanceTester $I)
    {
        $this->tester = $I;
    }

    public function login(string $username, string $password): void
    {
        $I = $this->tester;

        $I->amOnPage(self::$URL);
        $I->fillField(self::$usernameField, $username);
        $I->fillField(self::$passwordField, $password);
        $I->click(self::$loginButton);
    }
}
```

Use page object in test:

```php
public function loginWithPageObject(AcceptanceTester $I): void
{
    $loginPage = new LoginPage($I);
    $loginPage->login('admin', 'password');

    $I->see('Dashboard');
}
```

## Common Actions

### Navigation

```php
// Navigate to URL
$I->amOnPage('/products');
$I->amOnUrl('https://example.com/page');

// Click links
$I->click('Products');
$I->click('#menu-products');
$I->click(['link' => 'View Details']);
```

### Form Interaction

```php
// Fill fields
$I->fillField('email', 'user@example.com');
$I->fillField('#password', 'secret');

// Select options
$I->selectOption('country', 'Germany');
$I->selectOption('category', ['Books', 'Electronics']);

// Checkboxes and radio buttons
$I->checkOption('terms');
$I->uncheckOption('newsletter');

// Submit forms
$I->submitForm('#contact-form', [
    'name' => 'John Doe',
    'email' => 'john@example.com',
]);
```

### Assertions

```php
// See text
$I->see('Welcome');
$I->see('Product added', '.success-message');
$I->dontSee('Error');

// See elements
$I->seeElement('.product-list');
$I->seeElement('#add-to-cart');
$I->dontSeeElement('.error-message');

// URL checks
$I->seeInCurrentUrl('/checkout');
$I->seeCurrentUrlEquals('/thank-you');

// Field values
$I->seeInField('email', 'user@example.com');

// Number of elements
$I->seeNumberOfElements('.product-item', 10);
```

### JavaScript

```php
// Execute JavaScript
$I->executeJS('window.scrollTo(0, document.body.scrollHeight);');

// Wait for JavaScript
$I->waitForJS('return document.readyState === "complete"', 5);

// Wait for element
$I->waitForElement('.product-list', 10);
$I->waitForElementVisible('#modal', 5);

// AJAX requests
$I->waitForAjaxLoad();
```

### Screenshots

```php
// Take screenshot
$I->makeScreenshot('product_page');

// Screenshot on failure (automatic in codeception.yml)
$I->makeScreenshot('FAILED_' . $test->getName());
```

## Data Management

### Using Fixtures

```php
public function _before(AcceptanceTester $I): void
{
    // Reset database
    $I->resetDatabase();

    // Import fixtures
    $I->importFixture('products.sql');
}
```

### Test Data

Create data providers:

```php
protected function productData(): array
{
    return [
        ['name' => 'Product A', 'price' => 10.00],
        ['name' => 'Product B', 'price' => 20.00],
    ];
}

/**
 * @dataProvider productData
 */
public function createsProduct(AcceptanceTester $I, \Codeception\Example $example): void
{
    $I->amOnPage('/admin/products/new');
    $I->fillField('name', $example['name']);
    $I->fillField('price', $example['price']);
    $I->click('Save');

    $I->see($example['name']);
}
```

## Browser Configuration

### Multiple Browsers

```yaml
# codeception.yml
suites:
    acceptance:
        modules:
            config:
                WebDriver:
                    browser: '%BROWSER%'

# Run with different browsers
BROWSER=chrome vendor/bin/codecept run acceptance
BROWSER=firefox vendor/bin/codecept run acceptance
```

### Headless Mode

```yaml
WebDriver:
    capabilities:
        chromeOptions:
            args: ['--headless', '--no-sandbox', '--disable-gpu']
```

## Running Tests

### Basic Execution

```bash
# All acceptance tests
vendor/bin/codecept run acceptance

# Specific test
vendor/bin/codecept run acceptance LoginCest

# Specific method
vendor/bin/codecept run acceptance LoginCest:loginAsBackendUser

# With HTML report
vendor/bin/codecept run acceptance --html
```

### Via runTests.sh

```bash
Build/Scripts/runTests.sh -s acceptance
```

### With Docker Compose

```bash
# Start services
docker-compose -f Build/docker-compose.yml up -d

# Run tests
vendor/bin/codecept run acceptance

# Stop services
docker-compose -f Build/docker-compose.yml down
```

## Best Practices

1. **Use Page Objects**: Reusable page representations
2. **Wait Strategically**: Use `waitFor*` methods for dynamic content
3. **Independent Tests**: Each test can run standalone
4. **Descriptive Names**: Clear test method names
5. **Screenshot on Failure**: Automatic debugging aid
6. **Minimal Setup**: Only necessary fixtures and data
7. **Stable Selectors**: Use IDs or data attributes, not fragile CSS

## Common Pitfalls

❌ **No Waits for Dynamic Content**
```php
$I->click('Load More');
$I->see('Product 11'); // May fail if AJAX is slow
```

✅ **Proper Waits**
```php
$I->click('Load More');
$I->waitForElement('.product-item:nth-child(11)', 5);
$I->see('Product 11');
```

❌ **Brittle Selectors**
```php
$I->click('div.container > div:nth-child(3) > button'); // Fragile
```

✅ **Stable Selectors**
```php
$I->click('[data-test="add-to-cart"]'); // Stable
$I->click('#product-add-button'); // Better
```

❌ **Large Test Scenarios**
```php
// Don't test entire user journey in one test
public function completeUserJourney() { /* 50 steps */ }
```

✅ **Focused Tests**
```php
public function addsProductToCart() { /* 5 steps */ }
public function proceedsToCheckout() { /* 7 steps */ }
```

## Debugging

### Interactive Mode

```bash
vendor/bin/codecept run acceptance --debug
vendor/bin/codecept run acceptance --steps
```

### Pause Execution

```php
$I->pauseExecution(); // Opens interactive shell
```

### HTML Reports

```bash
vendor/bin/codecept run acceptance --html
# View report at Tests/Acceptance/_output/report.html
```

## Resources

- [Codeception Documentation](https://codeception.com/docs/)
- [WebDriver Module](https://codeception.com/docs/modules/WebDriver)
- [Page Objects](https://codeception.com/docs/06-ReusingTestCode#pageobjects)
- [TYPO3 Acceptance Testing](https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/Testing/AcceptanceTests.html)
