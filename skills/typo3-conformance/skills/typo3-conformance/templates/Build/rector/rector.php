<?php

declare(strict_types=1);

/**
 * Rector Configuration - TYPO3 Extension
 * Based on TYPO3 Best Practices: https://github.com/TYPO3BestPractices/tea
 *
 * This configuration enables:
 * - Automated TYPO3 migrations (version upgrades)
 * - PHP modernization (up to PHP 8.1+)
 * - PHPUnit test modernization
 * - Code quality improvements
 * - ExtEmConf automatic maintenance
 */

use Rector\CodeQuality\Rector\If_\ExplicitBoolCompareRector;
use Rector\CodeQuality\Rector\Ternary\SwitchNegatedTernaryRector;
use Rector\Config\RectorConfig;
use Rector\PHPUnit\Set\PHPUnitSetList;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Rector\Strict\Rector\Empty_\DisallowedEmptyRuleFixerRector;
use Rector\TypeDeclaration\Rector\ClassMethod\AddVoidReturnTypeWhereNoReturnRector;
use Rector\ValueObject\PhpVersion;
use Ssch\TYPO3Rector\CodeQuality\General\ConvertImplicitVariablesToExplicitGlobalsRector;
use Ssch\TYPO3Rector\CodeQuality\General\ExtEmConfRector;
use Ssch\TYPO3Rector\Configuration\Typo3Option;
use Ssch\TYPO3Rector\Set\Typo3LevelSetList;
use Ssch\TYPO3Rector\Set\Typo3SetList;
use Ssch\Typo3RectorTestingFramework\Set\TYPO3TestingFrameworkSetList;

return RectorConfig::configure()
    ->withPaths([
        __DIR__ . '/../../Classes/',
        __DIR__ . '/../../Configuration/',
        __DIR__ . '/../../Tests/',
        __DIR__ . '/../../ext_emconf.php',
        __DIR__ . '/../../ext_localconf.php',
        // __DIR__ . '/../../ext_tables.php',  // Uncomment if you still use this (deprecated)
    ])
    // Minimum PHP version your extension supports
    ->withPhpVersion(PhpVersion::PHP_82)
    // Enable all PHP sets for modernization
    ->withPhpSets(
        true
    )
    // Note: We're enabling specific sets by default.
    // You can temporarily enable more sets as needed for larger refactorings.
    ->withSets([
        // Rector Core Sets (uncomment as needed for major refactorings)
        // LevelSetList::UP_TO_PHP_81,
        // SetList::CODE_QUALITY,
        // SetList::CODING_STYLE,
        // SetList::DEAD_CODE,
        // SetList::EARLY_RETURN,
        // SetList::TYPE_DECLARATION,

        // PHPUnit Sets - modernize tests
        PHPUnitSetList::PHPUNIT_100,
        // PHPUnitSetList::PHPUNIT_CODE_QUALITY,

        // TYPO3 Sets - CRITICAL for TYPO3 migrations
        // https://github.com/sabbelasichon/typo3-rector/blob/main/src/Set/Typo3LevelSetList.php
        // https://github.com/sabbelasichon/typo3-rector/blob/main/src/Set/Typo3SetList.php
        Typo3SetList::CODE_QUALITY,
        Typo3SetList::GENERAL,

        // TYPO3 Version Migration - ADJUST TO YOUR TARGET VERSION
        Typo3LevelSetList::UP_TO_TYPO3_12,  // Change to UP_TO_TYPO3_13 when upgrading

        // TYPO3 Testing Framework (if using typo3/testing-framework)
        // TYPO3TestingFrameworkSetList::TYPO3_TESTING_FRAMEWORK_7,
    ])
    // To have a better analysis from PHPStan, we teach it here some more things
    ->withPHPStanConfigs([
        Typo3Option::PHPSTAN_FOR_RECTOR_PATH,
    ])
    // Additional useful rules
    ->withRules([
        AddVoidReturnTypeWhereNoReturnRector::class,
        ConvertImplicitVariablesToExplicitGlobalsRector::class,
    ])
    // Auto-import class names (removes need for full namespaces)
    ->withImportNames(true, true, false)
    // ExtEmConfRector: Automatically maintains ext_emconf.php
    ->withConfiguredRule(ExtEmConfRector::class, [
        // Adjust these constraints to match your extension requirements
        ExtEmConfRector::PHP_VERSION_CONSTRAINT => '8.2.0-8.5.99',
        ExtEmConfRector::TYPO3_VERSION_CONSTRAINT => '12.4.0-12.4.99',  // or '13.0.0-13.99.99'
        ExtEmConfRector::ADDITIONAL_VALUES_TO_BE_REMOVED => [],
    ])
    // Skip specific rules if they cause issues
    ->withSkip([
        // Example: Skip specific rules
        // ExplicitBoolCompareRector::class,
        // SwitchNegatedTernaryRector::class,

        // Example: Skip specific paths
        // ExplicitBoolCompareRector::class => [
        //     __DIR__ . '/../../Classes/Legacy/',
        // ],
    ]);
