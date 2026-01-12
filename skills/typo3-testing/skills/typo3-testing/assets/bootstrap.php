<?php

declare(strict_types=1);

/**
 * General Bootstrap for TYPO3 Extension Tests
 *
 * Place this file at Tests/bootstrap.php
 *
 * This bootstrap initializes the test environment for all test types.
 * It sets up autoloading and basic TYPO3 constants.
 */

// Set timezone to avoid date/time warnings
date_default_timezone_set('UTC');

// Locate composer autoloader
$autoloadLocations = [
    // Standard .Build directory (runTests.sh)
    dirname(__DIR__) . '/.Build/vendor/autoload.php',
    // Composer root installation
    dirname(__DIR__, 3) . '/vendor/autoload.php',
    // Local vendor directory
    dirname(__DIR__) . '/vendor/autoload.php',
];

$autoloadFile = null;
foreach ($autoloadLocations as $location) {
    if (file_exists($location)) {
        $autoloadFile = $location;
        break;
    }
}

if ($autoloadFile === null) {
    throw new RuntimeException(
        'Could not find composer autoload.php. Run "composer install" first.'
    );
}

require_once $autoloadFile;

// Define TYPO3 constants if not already defined
// These are needed for some TYPO3 core classes even in unit tests
if (!defined('TYPO3')) {
    // TYPO3 v12+ uses this constant
    define('TYPO3', true);
}

if (!defined('TYPO3_MODE')) {
    // Legacy constant for backwards compatibility
    define('TYPO3_MODE', 'BE');
}

if (!defined('TYPO3_REQUESTTYPE')) {
    // CLI request type
    define('TYPO3_REQUESTTYPE', 2);
}
