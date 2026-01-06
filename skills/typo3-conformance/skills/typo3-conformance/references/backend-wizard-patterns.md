# Backend Setup Wizard Patterns

**Source:** nr_llm Extension - SetupWizard Implementation
**Purpose:** Patterns for multi-step configuration wizards in TYPO3 backend modules

## Overview

Backend setup wizards guide users through complex configuration tasks with step-by-step interfaces. This pattern uses DTOs for validation, AJAX routes for async operations, and ES6 modules for frontend logic.

## Architecture Pattern

```
┌─────────────────────────────────────────────────────────────┐
│ SetupWizardController (Backend Module)                      │
│ → Renders wizard UI, handles form submissions               │
└──────────────────────────┬──────────────────────────────────┘
                           │ uses
┌──────────────────────────▼──────────────────────────────────┐
│ WizardStepService (Business Logic)                          │
│ → Step validation, data persistence, workflow orchestration │
└──────────────────────────┬──────────────────────────────────┘
                           │ validates with
┌──────────────────────────▼──────────────────────────────────┐
│ Step DTOs (Data Transfer Objects)                           │
│ → Immutable, validated, type-safe step data                 │
└─────────────────────────────────────────────────────────────┘
```

## When to Use This Pattern

| Use Case | Example |
|----------|---------|
| Initial extension setup | API credentials, connection settings |
| Multi-step configuration | Provider → Model → Configuration flow |
| Guided onboarding | First-time user experience |
| Complex form workflows | Dependent field validation |

## DTO Pattern for Wizard Steps

### Step DTO with Validation

```php
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Domain\Dto;

final readonly class ProviderStepDto
{
    /**
     * @param non-empty-string $name
     * @param non-empty-string $adapterType
     * @param non-empty-string $apiKey
     */
    private function __construct(
        public string $name,
        public string $adapterType,
        public string $apiKey,
        public string $endpointUrl,
        public int $timeout,
    ) {}

    /**
     * Factory method with validation
     *
     * @param array<string, mixed> $data
     * @throws ValidationException
     */
    public static function fromArray(array $data): self
    {
        $errors = [];

        $name = trim((string)($data['name'] ?? ''));
        if ($name === '') {
            $errors['name'] = 'Provider name is required';
        }

        $adapterType = (string)($data['adapterType'] ?? '');
        $validAdapters = ['openai', 'anthropic', 'gemini', 'custom'];
        if (!in_array($adapterType, $validAdapters, true)) {
            $errors['adapterType'] = 'Invalid adapter type';
        }

        $apiKey = trim((string)($data['apiKey'] ?? ''));
        if ($apiKey === '') {
            $errors['apiKey'] = 'API key is required';
        }

        $timeout = (int)($data['timeout'] ?? 30);
        if ($timeout < 1 || $timeout > 300) {
            $errors['timeout'] = 'Timeout must be between 1 and 300 seconds';
        }

        if ($errors !== []) {
            throw ValidationException::fromErrors($errors);
        }

        return new self(
            name: $name,
            adapterType: $adapterType,
            apiKey: $apiKey,
            endpointUrl: trim((string)($data['endpointUrl'] ?? '')),
            timeout: $timeout,
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'name' => $this->name,
            'adapterType' => $this->adapterType,
            'apiKey' => $this->apiKey,
            'endpointUrl' => $this->endpointUrl,
            'timeout' => $this->timeout,
        ];
    }
}
```

### ValidationException Pattern

```php
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Exception;

final class ValidationException extends \RuntimeException
{
    /** @var array<string, string> */
    private array $fieldErrors;

    /**
     * @param array<string, string> $errors
     */
    public static function fromErrors(array $errors): self
    {
        $exception = new self('Validation failed: ' . implode(', ', array_keys($errors)));
        $exception->fieldErrors = $errors;
        return $exception;
    }

    /**
     * @return array<string, string>
     */
    public function getFieldErrors(): array
    {
        return $this->fieldErrors;
    }
}
```

## Wizard Step Service

```php
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Service\SetupWizard;

use Vendor\ExtensionKey\Domain\Dto\ProviderStepDto;
use Vendor\ExtensionKey\Domain\Model\Provider;
use Vendor\ExtensionKey\Domain\Repository\ProviderRepository;
use TYPO3\CMS\Extbase\Persistence\PersistenceManagerInterface;

final class WizardStepService
{
    private const WIZARD_STEPS = ['provider', 'model', 'configuration', 'complete'];

    public function __construct(
        private readonly ProviderRepository $providerRepository,
        private readonly PersistenceManagerInterface $persistenceManager,
        private readonly ProviderEncryptionServiceInterface $encryptionService,
    ) {}

    public function getSteps(): array
    {
        return self::WIZARD_STEPS;
    }

    public function processProviderStep(ProviderStepDto $dto, int $storagePid): Provider
    {
        $provider = new Provider();
        $provider->setPid($storagePid);
        $provider->setName($dto->name);
        $provider->setAdapterType($dto->adapterType);
        $provider->setApiKey($this->encryptionService->encrypt($dto->apiKey));
        $provider->setEndpointUrl($dto->endpointUrl);
        $provider->setTimeout($dto->timeout);
        $provider->setIsActive(true);

        $this->providerRepository->add($provider);
        $this->persistenceManager->persistAll();

        return $provider;
    }

    public function validateStep(string $step, array $data): array
    {
        return match ($step) {
            'provider' => $this->validateProviderStep($data),
            'model' => $this->validateModelStep($data),
            'configuration' => $this->validateConfigurationStep($data),
            default => ['step' => 'Unknown step'],
        };
    }

    private function validateProviderStep(array $data): array
    {
        try {
            ProviderStepDto::fromArray($data);
            return [];
        } catch (ValidationException $e) {
            return $e->getFieldErrors();
        }
    }
}
```

## Backend Controller Pattern

```php
<?php
declare(strict_types=1);

namespace Vendor\ExtensionKey\Controller\Backend;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Backend\Attribute\AsController;
use TYPO3\CMS\Backend\Template\ModuleTemplateFactory;
use TYPO3\CMS\Core\Http\JsonResponse;
use Vendor\ExtensionKey\Service\SetupWizard\WizardStepService;

#[AsController]
final class SetupWizardController
{
    public function __construct(
        private readonly ModuleTemplateFactory $moduleTemplateFactory,
        private readonly WizardStepService $wizardStepService,
    ) {}

    public function indexAction(ServerRequestInterface $request): ResponseInterface
    {
        $moduleTemplate = $this->moduleTemplateFactory->create($request);
        $moduleTemplate->assignMultiple([
            'steps' => $this->wizardStepService->getSteps(),
            'currentStep' => 'provider',
        ]);

        return $moduleTemplate->renderResponse('Backend/SetupWizard/Index');
    }

    /**
     * AJAX endpoint for step validation
     */
    public function validateStepAction(ServerRequestInterface $request): ResponseInterface
    {
        $body = json_decode($request->getBody()->getContents(), true) ?? [];
        $step = (string)($body['step'] ?? '');
        $data = (array)($body['data'] ?? []);

        $errors = $this->wizardStepService->validateStep($step, $data);

        return new JsonResponse([
            'success' => $errors === [],
            'errors' => $errors,
        ]);
    }

    /**
     * AJAX endpoint for connection testing
     */
    public function testConnectionAction(ServerRequestInterface $request): ResponseInterface
    {
        $body = json_decode($request->getBody()->getContents(), true) ?? [];

        try {
            $result = $this->wizardStepService->testConnection($body);
            return new JsonResponse([
                'success' => true,
                'message' => 'Connection successful',
                'models' => $result['models'] ?? [],
            ]);
        } catch (\Exception $e) {
            return new JsonResponse([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        }
    }
}
```

## AJAX Route Registration

```php
<?php
// Configuration/Backend/AjaxRoutes.php

return [
    'myext_wizard_validate' => [
        'path' => '/myext/wizard/validate',
        'target' => \Vendor\ExtensionKey\Controller\Backend\SetupWizardController::class . '::validateStepAction',
    ],
    'myext_wizard_test_connection' => [
        'path' => '/myext/wizard/test-connection',
        'target' => \Vendor\ExtensionKey\Controller\Backend\SetupWizardController::class . '::testConnectionAction',
    ],
    'myext_wizard_save_step' => [
        'path' => '/myext/wizard/save-step',
        'target' => \Vendor\ExtensionKey\Controller\Backend\SetupWizardController::class . '::saveStepAction',
    ],
];
```

## ES6 Module Pattern for Wizard UI

```javascript
// Resources/Public/JavaScript/Backend/SetupWizard.js

/**
 * Setup Wizard ES6 Module
 * @exports @vendor/extension-key/Backend/SetupWizard
 */

import AjaxRequest from '@typo3/core/ajax/ajax-request.js';
import Notification from '@typo3/backend/notification.js';
import Modal from '@typo3/backend/modal.js';

class SetupWizard {
    constructor() {
        this.currentStep = 0;
        this.steps = ['provider', 'model', 'configuration', 'complete'];
        this.formData = {};
        this.initializeEventListeners();
    }

    initializeEventListeners() {
        document.querySelectorAll('[data-wizard-action="next"]').forEach(btn => {
            btn.addEventListener('click', () => this.nextStep());
        });

        document.querySelectorAll('[data-wizard-action="prev"]').forEach(btn => {
            btn.addEventListener('click', () => this.prevStep());
        });

        document.querySelectorAll('[data-wizard-action="test"]').forEach(btn => {
            btn.addEventListener('click', () => this.testConnection());
        });
    }

    async nextStep() {
        const stepName = this.steps[this.currentStep];
        const stepData = this.collectStepData(stepName);

        // Validate current step
        const isValid = await this.validateStep(stepName, stepData);
        if (!isValid) {
            return;
        }

        // Store data and advance
        this.formData[stepName] = stepData;
        this.currentStep++;
        this.renderStep();
    }

    prevStep() {
        if (this.currentStep > 0) {
            this.currentStep--;
            this.renderStep();
        }
    }

    async validateStep(step, data) {
        try {
            const response = await new AjaxRequest(TYPO3.settings.ajaxUrls.myext_wizard_validate)
                .post({ step, data });

            const result = await response.resolve();

            if (!result.success) {
                this.showFieldErrors(result.errors);
                return false;
            }

            this.clearFieldErrors();
            return true;
        } catch (error) {
            Notification.error('Validation Error', error.message);
            return false;
        }
    }

    async testConnection() {
        const stepData = this.collectStepData('provider');
        const testButton = document.querySelector('[data-wizard-action="test"]');

        testButton.disabled = true;
        testButton.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Testing...';

        try {
            const response = await new AjaxRequest(TYPO3.settings.ajaxUrls.myext_wizard_test_connection)
                .post(stepData);

            const result = await response.resolve();

            if (result.success) {
                Notification.success('Connection Successful', result.message);
                // Populate model dropdown if models returned
                if (result.models?.length) {
                    this.populateModels(result.models);
                }
            } else {
                Notification.error('Connection Failed', result.message);
            }
        } catch (error) {
            Notification.error('Connection Error', error.message);
        } finally {
            testButton.disabled = false;
            testButton.innerHTML = 'Test Connection';
        }
    }

    collectStepData(stepName) {
        const form = document.querySelector(`[data-wizard-step="${stepName}"]`);
        const formData = new FormData(form);
        const data = {};

        formData.forEach((value, key) => {
            data[key] = value;
        });

        return data;
    }

    showFieldErrors(errors) {
        this.clearFieldErrors();

        Object.entries(errors).forEach(([field, message]) => {
            const input = document.querySelector(`[name="${field}"]`);
            if (input) {
                input.classList.add('is-invalid');
                const feedback = document.createElement('div');
                feedback.className = 'invalid-feedback';
                feedback.textContent = message;
                input.parentNode.appendChild(feedback);
            }
        });
    }

    clearFieldErrors() {
        document.querySelectorAll('.is-invalid').forEach(el => {
            el.classList.remove('is-invalid');
        });
        document.querySelectorAll('.invalid-feedback').forEach(el => {
            el.remove();
        });
    }

    renderStep() {
        // Hide all steps
        document.querySelectorAll('[data-wizard-step]').forEach(step => {
            step.classList.add('d-none');
        });

        // Show current step
        const currentStepName = this.steps[this.currentStep];
        const currentStepEl = document.querySelector(`[data-wizard-step="${currentStepName}"]`);
        if (currentStepEl) {
            currentStepEl.classList.remove('d-none');
        }

        // Update progress indicator
        this.updateProgress();
    }

    updateProgress() {
        const progressBar = document.querySelector('.wizard-progress-bar');
        if (progressBar) {
            const percent = ((this.currentStep + 1) / this.steps.length) * 100;
            progressBar.style.width = `${percent}%`;
        }
    }

    populateModels(models) {
        const select = document.querySelector('[name="modelId"]');
        if (select) {
            select.innerHTML = '<option value="">Select a model...</option>';
            models.forEach(model => {
                const option = document.createElement('option');
                option.value = model.id;
                option.textContent = `${model.name} (${model.id})`;
                select.appendChild(option);
            });
        }
    }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
    new SetupWizard();
});

export default SetupWizard;
```

## Fluid Template Pattern

```html
<!-- Resources/Private/Templates/Backend/SetupWizard/Index.html -->
<html xmlns:f="http://typo3.org/ns/TYPO3/CMS/Fluid/ViewHelpers"
      xmlns:be="http://typo3.org/ns/TYPO3/CMS/Backend/ViewHelpers"
      data-namespace-typo3-fluid="true">

<f:layout name="Module" />

<f:section name="Content">
    <f:be.pageRenderer
        includeJavaScriptModules="{
            0: '@vendor/extension-key/Backend/SetupWizard.js'
        }"
    />

    <div class="setup-wizard">
        <!-- Progress Bar -->
        <div class="progress mb-4">
            <div class="wizard-progress-bar progress-bar" role="progressbar" style="width: 25%"></div>
        </div>

        <!-- Step 1: Provider -->
        <div data-wizard-step="provider">
            <h2>Step 1: Configure Provider</h2>
            <div class="mb-3">
                <label class="form-label">Provider Name</label>
                <input type="text" name="name" class="form-control" required />
            </div>
            <div class="mb-3">
                <label class="form-label">Adapter Type</label>
                <select name="adapterType" class="form-select">
                    <option value="openai">OpenAI</option>
                    <option value="anthropic">Anthropic Claude</option>
                    <option value="gemini">Google Gemini</option>
                    <option value="custom">Custom</option>
                </select>
            </div>
            <div class="mb-3">
                <label class="form-label">API Key</label>
                <input type="password" name="apiKey" class="form-control" required />
            </div>
            <div class="mb-3">
                <label class="form-label">Custom Endpoint (optional)</label>
                <input type="url" name="endpointUrl" class="form-control" />
            </div>
            <div class="d-flex gap-2">
                <button type="button" class="btn btn-secondary" data-wizard-action="test">
                    Test Connection
                </button>
                <button type="button" class="btn btn-primary" data-wizard-action="next">
                    Next Step
                </button>
            </div>
        </div>

        <!-- Additional steps... -->
    </div>
</f:section>
</html>
```

## JavaScriptModules Registration (TYPO3 v12+)

```php
<?php
// Configuration/JavaScriptModules.php

return [
    'dependencies' => [
        'backend',
    ],
    'imports' => [
        '@vendor/extension-key/' => 'EXT:extension_key/Resources/Public/JavaScript/',
    ],
];
```

## Benefits

| Benefit | Description |
|---------|-------------|
| **Type Safety** | DTOs ensure validated, typed data throughout |
| **Separation** | Controller → Service → DTO layering |
| **Testability** | Each layer independently testable |
| **UX** | Async validation, progress indication |
| **Accessibility** | ARIA attributes, keyboard navigation |
| **Modern Stack** | ES6 modules, async/await, Bootstrap 5 |

## Conformance Checklist

- [ ] DTOs use readonly classes with factory methods
- [ ] ValidationException provides field-level errors
- [ ] AJAX routes registered in `Configuration/Backend/AjaxRoutes.php`
- [ ] ES6 modules registered in `Configuration/JavaScriptModules.php`
- [ ] No inline JavaScript in Fluid templates
- [ ] TYPO3 Notification API for user feedback
- [ ] Progress indication for multi-step flows
- [ ] Form validation with Bootstrap classes
- [ ] Proper error handling with try/catch

## Related References

- `php-architecture.md` - Dependency injection patterns
- `backend-module-v13.md` - Backend module requirements
- `multi-tier-configuration.md` - Multi-tier data model
- Security Audit Skill - `api-key-encryption.md`
