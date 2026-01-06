<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Acceptance;

use Vendor\Extension\Tests\Acceptance\AcceptanceTester;

/**
 * Example acceptance test demonstrating TYPO3 testing patterns
 *
 * Acceptance tests use a real browser to test complete user workflows.
 * They verify frontend functionality and user interactions.
 */
final class LoginCest
{
    public function _before(AcceptanceTester $I): void
    {
        // Runs before each test method
        // Setup: Import fixtures, reset state, etc.
    }

    public function loginAsBackendUser(AcceptanceTester $I): void
    {
        // Navigate to login page
        $I->amOnPage('/typo3');

        // Fill login form
        $I->fillField('username', 'admin');
        $I->fillField('password', 'password');

        // Submit form
        $I->click('Login');

        // Verify successful login
        $I->see('Dashboard');
        $I->seeInCurrentUrl('/typo3/module/dashboard');
    }

    public function loginFailsWithInvalidCredentials(AcceptanceTester $I): void
    {
        $I->amOnPage('/typo3');

        $I->fillField('username', 'admin');
        $I->fillField('password', 'wrong_password');
        $I->click('Login');

        // Verify login failed
        $I->see('Login error');
        $I->seeInCurrentUrl('/typo3');
    }

    public function searchesForProducts(AcceptanceTester $I): void
    {
        // Navigate to product listing
        $I->amOnPage('/products');

        // Wait for page to load
        $I->waitForElement('.product-list', 5);

        // Use search
        $I->fillField('#search', 'laptop');
        $I->click('Search');

        // Wait for results
        $I->waitForElement('.search-results', 5);

        // Verify search results
        $I->see('laptop', '.product-title');
        $I->seeNumberOfElements('.product-item', [1, 10]);
    }

    public function addsProductToCart(AcceptanceTester $I): void
    {
        $I->amOnPage('/products/1');

        // Click add to cart button
        $I->click('#add-to-cart');

        // Wait for AJAX response
        $I->waitForElement('.cart-badge', 3);

        // Verify cart updated
        $I->see('1', '.cart-badge');
        $I->see('Product added to cart');
    }
}
