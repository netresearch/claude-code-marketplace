<?php

declare(strict_types=1);

/**
 * Bootstrap file for TYPO3 functional tests
 *
 * This file initializes the testing environment for functional tests.
 * It sets up the necessary directory structure and prepares the TYPO3 instance.
 */

call_user_func(static function () {
    $testbase = new \TYPO3\TestingFramework\Core\Testbase();

    // Define original root path
    $testbase->defineOriginalRootPath();

    // Create necessary directories for test execution
    $testbase->createDirectory(ORIGINAL_ROOT . 'typo3temp/var/tests');
    $testbase->createDirectory(ORIGINAL_ROOT . 'typo3temp/var/transient');
});
