<?php

declare(strict_types=1);

/*
 * PHPat Architecture Test Rules Template
 *
 * This file defines architecture rules enforced via PHPStan.
 * Run with: Build/Scripts/runTests.sh -s phpstan
 *
 * CUSTOMIZATION REQUIRED:
 * - Replace 'Vendor\ExtensionName' with your actual namespace
 * - Adjust layer rules based on your extension's architecture
 * - Add/remove rules based on your security requirements
 */

namespace Vendor\ExtensionName\Tests\Architecture;

use PHPat\Selector\Selector;
use PHPat\Test\Builder\BuildStep;
use PHPat\Test\PHPat;

/**
 * Architecture tests for TYPO3 extension.
 *
 * Enforces clean architecture boundaries and security patterns.
 *
 * Layer dependency rules (allowed dependencies flow downward):
 *
 *   Controller/Command (presentation)
 *          ↓
 *      Service (application)
 *          ↓
 *   Domain/Repository (core)
 *          ↓
 *   Exception/Event (shared kernel)
 */
final class ArchitectureTest
{
    // =========================================================================
    // IMMUTABILITY RULES - Security-critical classes must be immutable
    // =========================================================================

    /**
     * Events must be readonly for immutability.
     *
     * PSR-14 events should never be modified after creation.
     */
    public function testEventsMustBeReadonly(): BuildStep
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Event'))
            ->shouldBeReadonly()
            ->because('events must be immutable for security and predictability');
    }

    /**
     * DTOs must be readonly.
     *
     * Data Transfer Objects should be immutable value objects.
     */
    public function testDtosMustBeReadonly(): BuildStep
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Domain\Dto'))
            ->shouldBeReadonly()
            ->because('DTOs must be immutable value objects');
    }

    // =========================================================================
    // FINALITY RULES - Security classes must not be extended
    // =========================================================================

    /**
     * Exceptions must be final.
     *
     * Prevents exception hierarchy manipulation attacks.
     */
    public function testExceptionsMustBeFinal(): BuildStep
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Exception'))
            ->shouldBeFinal()
            ->because('exceptions should not be extended for security');
    }

    // =========================================================================
    // INTERFACE RULES - Ensure proper abstractions
    // =========================================================================

    /**
     * Services must implement an interface.
     *
     * Enables dependency injection and testing.
     */
    public function testServicesMustImplementInterface(): BuildStep
    {
        return PHPat::rule()
            ->classes(
                Selector::classname('/^Vendor\\\\ExtensionName\\\\Service\\\\.*Service$/', true),
            )
            ->excluding(
                Selector::classname('/.*Interface$/', true),
                Selector::classname('/.*Factory$/', true),
            )
            ->shouldImplement()
            ->classes(Selector::classname('/.*Interface$/', true))
            ->because('services should be injected via interfaces for testability');
    }

    // =========================================================================
    // LAYER DEPENDENCY RULES - Enforce clean architecture
    // =========================================================================

    /**
     * Services must not depend on Controllers.
     *
     * Services are application layer, controllers are presentation.
     */
    public function testServicesDoNotDependOnControllers(): BuildStep
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Service'))
            ->shouldNotDependOn()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Controller'))
            ->because('services should be independent of the presentation layer');
    }

    /**
     * Services must not depend on Commands.
     *
     * CLI commands are presentation layer.
     */
    public function testServicesDoNotDependOnCommands(): BuildStep
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Service'))
            ->shouldNotDependOn()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Command'))
            ->because('services should be independent of CLI commands');
    }

    /**
     * Domain layer must not depend on infrastructure.
     *
     * Domain models should be pure and framework-independent.
     */
    public function testDomainDoesNotDependOnInfrastructure(): BuildStep
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Domain'))
            ->shouldNotDependOn()
            ->classes(
                Selector::inNamespace('Vendor\ExtensionName\Controller'),
                Selector::inNamespace('Vendor\ExtensionName\Command'),
                Selector::inNamespace('Vendor\ExtensionName\Hook'),
                Selector::inNamespace('Vendor\ExtensionName\Form'),
                Selector::inNamespace('Vendor\ExtensionName\Task'),
            )
            ->because('domain layer must be isolated from infrastructure concerns');
    }

    /**
     * Hooks must not depend on Controllers.
     *
     * TYPO3 hooks should call services, not controllers.
     */
    public function testHooksDoNotDependOnControllers(): BuildStep
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Hook'))
            ->shouldNotDependOn()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Controller'))
            ->because('hooks should use services, not controllers');
    }

    /**
     * Commands must not depend on Controllers.
     *
     * CLI and web are separate presentation channels.
     */
    public function testCommandsDoNotDependOnControllers(): BuildStep
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Command'))
            ->shouldNotDependOn()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Controller'))
            ->because('CLI commands should not use web controllers');
    }

    /**
     * Configuration must not depend on Services.
     *
     * Configuration is low-level infrastructure.
     */
    public function testConfigurationDoesNotDependOnServices(): BuildStep
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Configuration'))
            ->shouldNotDependOn()
            ->classes(
                Selector::inNamespace('Vendor\ExtensionName\Service'),
                Selector::inNamespace('Vendor\ExtensionName\Controller'),
                Selector::inNamespace('Vendor\ExtensionName\Command'),
            )
            ->because('configuration should be low-level infrastructure');
    }

    /**
     * EventListeners must not depend on Controllers or Commands.
     *
     * Event handlers should only use services.
     */
    public function testEventListenersDoNotDependOnPresentation(): BuildStep
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\EventListener'))
            ->shouldNotDependOn()
            ->classes(
                Selector::inNamespace('Vendor\ExtensionName\Controller'),
                Selector::inNamespace('Vendor\ExtensionName\Command'),
            )
            ->because('event listeners should use services, not presentation layer');
    }

    /**
     * Utilities must not depend on Services.
     *
     * Utilities should be stateless helper functions.
     */
    public function testUtilitiesDoNotDependOnServices(): BuildStep
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('Vendor\ExtensionName\Utility'))
            ->shouldNotDependOn()
            ->classes(
                Selector::inNamespace('Vendor\ExtensionName\Controller'),
                Selector::inNamespace('Vendor\ExtensionName\Command'),
                Selector::inNamespace('Vendor\ExtensionName\Hook'),
            )
            ->because('utilities should be stateless helpers');
    }
}
