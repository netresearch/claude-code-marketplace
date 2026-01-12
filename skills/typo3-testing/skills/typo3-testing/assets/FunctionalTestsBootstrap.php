<?php

declare(strict_types=1);

/**
 * Bootstrap for TYPO3 Extension Functional Tests
 *
 * Place this file at Tests/Functional/Bootstrap.php
 * Reference in Build/phpunit/FunctionalTests.xml bootstrap attribute.
 *
 * This bootstrap initializes the TYPO3 testing framework for functional tests.
 * It creates necessary directories and prepares the test environment.
 */

call_user_func(static function (): void {
    // Locate TYPO3 testing framework
    $testbaseClass = 'TYPO3\\TestingFramework\\Core\\Testbase';

    if (!class_exists($testbaseClass)) {
        // Try to load via composer autoload
        $autoloadLocations = [
            dirname(__DIR__, 2) . '/.Build/vendor/autoload.php',
            dirname(__DIR__, 4) . '/vendor/autoload.php',
        ];

        foreach ($autoloadLocations as $location) {
            if (file_exists($location)) {
                require_once $location;
                break;
            }
        }
    }

    if (!class_exists($testbaseClass)) {
        throw new RuntimeException(
            'TYPO3 TestingFramework not found. Run "composer require --dev typo3/testing-framework".'
        );
    }

    $testbase = new \TYPO3\TestingFramework\Core\Testbase();

    // Define original root path (extension root)
    $testbase->defineOriginalRootPath();

    // Create necessary directories for test execution
    $testbase->createDirectory(ORIGINAL_ROOT . 'typo3temp/var/tests');
    $testbase->createDirectory(ORIGINAL_ROOT . 'typo3temp/var/transient');

    // Optional: Set default timezone
    date_default_timezone_set('UTC');
});
