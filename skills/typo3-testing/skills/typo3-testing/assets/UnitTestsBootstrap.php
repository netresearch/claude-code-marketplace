<?php

declare(strict_types=1);

/**
 * Bootstrap for TYPO3 Extension Unit Tests
 *
 * Place this file at Tests/Unit/Bootstrap.php
 *
 * This bootstrap is specifically for unit tests that may need
 * TYPO3 class stubs when testing in isolation from the framework.
 *
 * OPTIONAL: Custom autoloader for TYPO3 stubs
 * Use when unit tests need minimal TYPO3 class implementations
 * without loading the full framework.
 */

// Set timezone
date_default_timezone_set('UTC');

// Locate composer autoloader
$autoloadLocations = [
    dirname(__DIR__, 2) . '/.Build/vendor/autoload.php',
    dirname(__DIR__, 4) . '/vendor/autoload.php',
    dirname(__DIR__, 2) . '/vendor/autoload.php',
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

/*
 * OPTIONAL: Register custom autoloader for TYPO3 class stubs
 *
 * This allows unit tests to use minimal TYPO3 class implementations
 * without requiring the full TYPO3 testing framework.
 *
 * Create stub classes in Tests/Unit/Fixtures/TYPO3/CMS/...
 * mirroring the TYPO3 namespace structure.
 *
 * Example stub: Tests/Unit/Fixtures/TYPO3/CMS/Core/Cache/CacheManager.php
 *
 * Uncomment the following block to enable stub autoloading:
 */

// spl_autoload_register(static function (string $class): void {
//     // Only handle TYPO3 classes
//     if (!str_starts_with($class, 'TYPO3\\CMS\\')) {
//         return;
//     }
//
//     // Convert namespace to file path
//     $relativePath = str_replace('\\', '/', $class);
//     $filePath = __DIR__ . '/Fixtures/' . $relativePath . '.php';
//
//     if (file_exists($filePath)) {
//         require_once $filePath;
//     }
// });

// Define TYPO3 constants
if (!defined('TYPO3')) {
    define('TYPO3', true);
}

if (!defined('TYPO3_MODE')) {
    define('TYPO3_MODE', 'BE');
}

if (!defined('TYPO3_REQUESTTYPE')) {
    define('TYPO3_REQUESTTYPE', 2);
}
