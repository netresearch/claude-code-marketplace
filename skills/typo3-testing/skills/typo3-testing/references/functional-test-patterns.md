# Functional Test Patterns for TYPO3 12/13

> **Source**: Real-world patterns from netresearch/contexts extension testing (2024-12)

## Container Reset Between Tests

When testing classes that use dependency injection, reset the container between tests:

```php
protected function setUp(): void
{
    parent::setUp();
    // Reset container to ensure clean DI state
    $this->resetContainer();
}
```

**Why**: Prevents test pollution from cached service instances.

## Site Configuration in Functional Tests

Create site configuration via YAML files, not PHP APIs:

```php
protected function setUp(): void
{
    parent::setUp();
    $this->importCSVDataSet(__DIR__ . '/Fixtures/pages.csv');

    // Create site configuration directory
    $siteConfigPath = $this->instancePath . '/config/sites/main';
    GeneralUtility::mkdir_p($siteConfigPath);

    // Write YAML configuration directly
    file_put_contents(
        $siteConfigPath . '/config.yaml',
        Yaml::dump([
            'rootPageId' => 1,
            'base' => '/',
            'languages' => [
                [
                    'languageId' => 0,
                    'title' => 'English',
                    'locale' => 'en_US.UTF-8',
                    'base' => '/',
                ],
            ],
        ])
    );
}
```

## Disabling Session for Context Fixtures

When testing contexts that don't need session:

```php
// Fixture: Tests/Functional/Fixtures/tx_contexts_contexts.csv
"uid","pid","title","type","type_conf","disabled","hide_in_backend"
1,0,"Test Context","ip","","0","0"

// Test class
protected function setUp(): void
{
    parent::setUp();
    $this->importCSVDataSet(__DIR__ . '/Fixtures/tx_contexts_contexts.csv');

    // Disable session to avoid "session not available" errors
    $GLOBALS['TYPO3_CONF_VARS']['FE']['sessionDataLifetime'] = 0;
}
```

## LinkVars Warning Fix

Avoid `linkVars not set` warnings in functional tests:

```php
// In test setup or fixture TypoScript
$GLOBALS['TSFE']->config['config']['linkVars'] = '';
```

Or in site TypoScript fixture:
```typoscript
config.linkVars =
```

## PHPUnit 10/11/12 Migration Patterns

### Removed: `$this->at()` Matcher

**PHPUnit 9** (deprecated):
```php
$mock->expects($this->at(0))->method('foo')->willReturn('first');
$mock->expects($this->at(1))->method('foo')->willReturn('second');
```

**PHPUnit 10+**:
```php
$mock->expects($this->exactly(2))
    ->method('foo')
    ->willReturnOnConsecutiveCalls('first', 'second');
```

### Callback Matcher for Complex Sequences

```php
$callCount = 0;
$mock->method('foo')
    ->willReturnCallback(function () use (&$callCount) {
        return match (++$callCount) {
            1 => 'first',
            2 => 'second',
            default => 'default',
        };
    });
```

### PHPUnit 12: Mock Objects Without Expectations

PHPUnit 12 shows notices when mocks have no configured expectations. Suppress with the attribute:

```php
use PHPUnit\Framework\Attributes\AllowMockObjectsWithoutExpectations;
use PHPUnit\Framework\Attributes\CoversClass;

#[CoversClass(MyService::class)]
#[AllowMockObjectsWithoutExpectations]  // Suppress "no expectations" notice
final class MyServiceTest extends FunctionalTestCase
{
    public function testSomething(): void
    {
        // Mock created but no expects() configured - that's OK
        $mock = $this->createMock(DependencyInterface::class);
        $service = new MyService($mock);

        // Test the service behavior
        self::assertTrue($service->isValid());
    }
}
```

**When to use:**
- Mocks used only for satisfying type hints
- Fuzz tests where mocks aren't the focus
- Tests where the mock's behavior is irrelevant

**Best practice:** Only use when genuinely appropriate. Most tests should verify mock interactions.

### PHPUnit 12: Attribute-Based Annotations

PHPUnit 12 prefers PHP 8 attributes over docblock annotations:

```php
// Old (deprecated)
/**
 * @covers \MyClass
 * @group slow
 */
class MyTest extends TestCase {}

// New (PHPUnit 10+)
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\Test;

#[CoversClass(MyClass::class)]
#[Group('slow')]
final class MyTest extends TestCase
{
    #[Test]
    public function itDoesTheThing(): void {}
}
```

### Common PHPUnit 12 Attributes

| Attribute | Purpose |
|-----------|---------|
| `#[Test]` | Mark method as test |
| `#[CoversClass(Foo::class)]` | Code coverage target |
| `#[CoversNothing]` | Exclude from coverage |
| `#[Group('slow')]` | Test grouping |
| `#[DataProvider('dataMethod')]` | Data provider |
| `#[Depends('testFirst')]` | Test dependencies |
| `#[AllowMockObjectsWithoutExpectations]` | Suppress mock notices |

## Database Credentials for DDEV

In `Build/phpunit/FunctionalTests.xml`:

```xml
<php>
    <env name="typo3DatabaseDriver" value="mysqli"/>
    <env name="typo3DatabaseHost" value="db"/>
    <env name="typo3DatabasePort" value="3306"/>
    <env name="typo3DatabaseUsername" value="db"/>
    <env name="typo3DatabasePassword" value="db"/>
    <env name="typo3DatabaseName" value="func_tests"/>
</php>
```

## Test Framework Compatibility Matrix

| PHPUnit | TYPO3 Testing Framework | TYPO3 Version |
|---------|------------------------|---------------|
| ^10.5   | ^8.0                   | 12.4 LTS      |
| ^11.0   | ^8.2 \|\| ^9.0         | 12.4, 13.4    |
| ^12.0   | ^9.0                   | 13.4 LTS      |

## Functional Test with Request Attribute (v13)

Testing code that uses PSR-7 request attributes:

```php
use TYPO3\CMS\Core\Http\ServerRequest;
use TYPO3\CMS\Frontend\Page\PageInformation;

public function testWithPageInformation(): void
{
    $pageInfo = new PageInformation();
    $pageInfo->setId(1);
    $pageInfo->setRootLine([['uid' => 1]]);

    $request = (new ServerRequest())
        ->withAttribute('frontend.page.information', $pageInfo);

    $result = $this->subject->process($request);

    self::assertSame(1, $result->getPageId());
}
```
