<?php

/**
 * Fractor configuration for TYPO3 extension upgrade
 *
 * Fractor handles non-PHP file migrations:
 * - FlexForms (XML)
 * - TypoScript
 * - YAML (e.g., Services.yaml)
 * - Fluid templates
 * - .htaccess files
 *
 * Usage:
 *   ./vendor/bin/fractor process --dry-run  # Preview changes
 *   ./vendor/bin/fractor process            # Apply changes
 *
 * @see https://github.com/andreaswolf/fractor
 */

declare(strict_types=1);

use a9f\Fractor\Configuration\FractorConfiguration;
use a9f\Typo3Fractor\Set\Typo3LevelSetList;

return FractorConfiguration::configure()
    ->withPaths([
        __DIR__ . '/Configuration',
        __DIR__ . '/Resources',
    ])
    ->withSkip([
        __DIR__ . '/.Build',
        __DIR__ . '/vendor',
    ])
    ->withSets([
        // TYPO3 v12 migrations
        // Handles FlexForm, TypoScript, YAML, Fluid migrations
        Typo3LevelSetList::UP_TO_TYPO3_12,

        // Uncomment for v13 if only supporting v13+
        // Typo3LevelSetList::UP_TO_TYPO3_13,
    ]);
