<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Unit\Domain\Validator;

use TYPO3\TestingFramework\Core\Unit\UnitTestCase;
use Vendor\Extension\Domain\Validator\EmailValidator;

/**
 * Example unit test demonstrating TYPO3 testing patterns
 *
 * Unit tests are fast, isolated tests without external dependencies.
 * They test individual components (validators, utilities, domain logic).
 */
final class EmailValidatorTest extends UnitTestCase
{
    protected EmailValidator $subject;

    protected function setUp(): void
    {
        parent::setUp();
        $this->subject = new EmailValidator();
    }

    /**
     * @test
     */
    public function validEmailPassesValidation(): void
    {
        $result = $this->subject->validate('user@example.com');

        self::assertFalse($result->hasErrors());
    }

    /**
     * @test
     */
    public function invalidEmailFailsValidation(): void
    {
        $result = $this->subject->validate('invalid-email');

        self::assertTrue($result->hasErrors());
    }

    /**
     * @test
     * @dataProvider invalidEmailProvider
     */
    public function rejectsInvalidEmails(string $email): void
    {
        $result = $this->subject->validate($email);

        self::assertTrue($result->hasErrors(), "Email '$email' should be invalid");
    }

    public static function invalidEmailProvider(): array
    {
        return [
            'missing @' => ['userexample.com'],
            'missing domain' => ['user@'],
            'empty string' => [''],
            'spaces' => ['user @example.com'],
        ];
    }
}
