<?php

declare(strict_types=1);

/**
 * PHP-CS-Fixer Configuration - TYPO3 Extension
 * Based on TYPO3 Best Practices: https://github.com/TYPO3BestPractices/tea
 *
 * This configuration uses the official TYPO3 Coding Standards with parallel execution.
 */

use PhpCsFixer\Runner\Parallel\ParallelConfigFactory;
use TYPO3\CodingStandards\CsFixerConfig;

$config = CsFixerConfig::create();

// Enable parallel execution for faster performance
// Automatically detects available CPU cores
$config->setParallelConfig(ParallelConfigFactory::detect());

// Define which directories to check
$config->getFinder()
    ->in('Classes')
    ->in('Configuration')
    ->in('Tests')
    // CRITICAL: Exclude ext_emconf.php - TYPO3 does NOT want declare(strict_types=1) in this file
    // The ext_emconf.php is processed by TYPO3's extension manager in a special context
    // Adding strict_types breaks extension installation/updates
    ->notName('ext_emconf.php');

// Optionally add more directories:
// ->in('ext_localconf.php')
// ->in('ext_tables.php')

return $config;
