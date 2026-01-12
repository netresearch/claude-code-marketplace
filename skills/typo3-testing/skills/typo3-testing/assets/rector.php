<?php

declare(strict_types=1);

/*
 * Rector Configuration for TYPO3 Extensions
 *
 * Run check: Build/Scripts/runTests.sh -s rector -n
 * Run fix:   Build/Scripts/runTests.sh -s rector
 *
 * CUSTOMIZATION REQUIRED:
 * - Adjust paths for your extension structure
 * - Update phpVersion() to match your minimum PHP requirement
 * - Update TYPO3 level set to match your minimum TYPO3 version
 */

use Rector\CodingStyle\Rector\Catch_\CatchExceptionNameMatchingTypeRector;
use Rector\Config\RectorConfig;
use Rector\DeadCode\Rector\ClassMethod\RemoveUnusedPrivateMethodParameterRector;
use Rector\DeadCode\Rector\ClassMethod\RemoveUselessParamTagRector;
use Rector\DeadCode\Rector\ClassMethod\RemoveUselessReturnTagRector;
use Rector\DeadCode\Rector\Property\RemoveUselessVarTagRector;
use Rector\Php80\Rector\Class_\ClassPropertyAssignToConstructorPromotionRector;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Ssch\TYPO3Rector\Set\Typo3LevelSetList;

return static function (RectorConfig $rectorConfig): void {
    // Paths to process
    $rectorConfig->paths([
        __DIR__ . '/Classes',
        __DIR__ . '/Configuration',
        __DIR__ . '/Tests',
    ]);

    // Paths to skip
    $rectorConfig->skip([
        __DIR__ . '/ext_emconf.php',
        __DIR__ . '/.Build',
    ]);

    // PHPStan configuration for better type inference
    // $rectorConfig->phpstanConfig(__DIR__ . '/phpstan.neon');

    // Target PHP version (80200 = PHP 8.2, 80300 = PHP 8.3, etc.)
    $rectorConfig->phpVersion(80200);

    // Import and organize use statements
    $rectorConfig->importNames();
    $rectorConfig->removeUnusedImports();

    // Define rule sets to apply
    $rectorConfig->sets([
        // Code quality improvements
        SetList::CODE_QUALITY,
        SetList::CODING_STYLE,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
        SetList::INSTANCEOF,
        SetList::PRIVATIZATION,
        SetList::STRICT_BOOLEANS,
        SetList::TYPE_DECLARATION,

        // PHP version migration (adjust to your minimum PHP version)
        LevelSetList::UP_TO_PHP_82,

        // TYPO3 version migration (adjust to your minimum TYPO3 version)
        // Options: UP_TO_TYPO3_12, UP_TO_TYPO3_13
        Typo3LevelSetList::UP_TO_TYPO3_13,
    ]);

    // Skip rules that may cause issues or conflicts with coding style
    $rectorConfig->skip([
        // Exception naming can be intentional
        CatchExceptionNameMatchingTypeRector::class,

        // Constructor promotion can reduce readability for complex classes
        ClassPropertyAssignToConstructorPromotionRector::class,

        // PHPDoc tags may be needed for IDE support or documentation
        RemoveUselessParamTagRector::class,
        RemoveUselessReturnTagRector::class,
        RemoveUselessVarTagRector::class,

        // Private method parameters may be intentionally unused for interface compatibility
        RemoveUnusedPrivateMethodParameterRector::class,
    ]);
};
