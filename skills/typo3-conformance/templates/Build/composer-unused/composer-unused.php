<?php

declare(strict_types=1);

/**
 * Composer Unused Configuration - TYPO3 Extension
 *
 * This configuration helps identify unused Composer dependencies.
 *
 * Some TYPO3 packages may be reported as unused even though they're required
 * (e.g., typo3/cms-fluid may not show explicit usage but is needed at runtime).
 * Add such packages to the filter list below.
 */

use ComposerUnused\ComposerUnused\Configuration\Configuration;
use ComposerUnused\ComposerUnused\Configuration\NamedFilter;

return static function (Configuration $config): Configuration {
    // Add packages that should be ignored during unused checks
    // These are typically TYPO3 system extensions or runtime dependencies

    // Example: typo3/cms-fluid is often required but not directly referenced in code
    $config->addNamedFilter(NamedFilter::fromString('typo3/cms-fluid'));

    // Add more as needed for your extension:
    // $config->addNamedFilter(NamedFilter::fromString('typo3/cms-frontend'));
    // $config->addNamedFilter(NamedFilter::fromString('typo3/cms-extbase'));

    return $config;
};
