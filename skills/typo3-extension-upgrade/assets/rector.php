<?php

/**
 * Rector configuration for TYPO3 v12/v13 extension upgrade
 *
 * Usage:
 *   ./vendor/bin/rector process --dry-run  # Preview changes
 *   ./vendor/bin/rector process            # Apply changes
 */

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\DeadCode\Rector\StaticCall\RemoveParentCallWithoutParentRector;
use Rector\Php80\Rector\Class_\ClassPropertyAssignToConstructorPromotionRector;
use Rector\Set\ValueObject\LevelSetList;
use Ssch\TYPO3Rector\Set\Typo3LevelSetList;
use Ssch\TYPO3Rector\Set\Typo3SetList;

return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->paths([
        __DIR__ . '/Classes',
        __DIR__ . '/Configuration',
        __DIR__ . '/Tests',
    ]);

    $rectorConfig->skip([
        __DIR__ . '/ext_emconf.php',
        __DIR__ . '/.Build',
        __DIR__ . '/vendor',
    ]);

    $rectorConfig->phpstanConfig(__DIR__ . '/phpstan.neon');
    $rectorConfig->importNames();
    $rectorConfig->removeUnusedImports();

    // Define what rule sets will be applied
    $rectorConfig->sets([
        // PHP level upgrades to 8.2
        LevelSetList::UP_TO_PHP_82,

        // TYPO3 v12 migrations only
        // IMPORTANT: Don't use UP_TO_TYPO3_13 if extension supports both ^12.4 || ^13.4
        // v13 rules introduce v13-only APIs that break v12 compatibility:
        // - $GLOBALS['TYPO3_REQUEST']->getAttribute('frontend.user')
        // - $GLOBALS['TYPO3_REQUEST']->getAttribute('frontend.page.information')
        Typo3LevelSetList::UP_TO_TYPO3_12,

        // TYPO3 code quality and general improvements
        Typo3SetList::CODE_QUALITY,
        Typo3SetList::GENERAL,
    ]);

    // Skip rules that may cause issues or require manual review
    $rectorConfig->skip([
        // Skip constructor promotion - keep explicit property declarations for clarity
        ClassPropertyAssignToConstructorPromotionRector::class,

        // Skip removing parent calls - may be needed for TYPO3 hooks
        RemoveParentCallWithoutParentRector::class,
    ]);
};
