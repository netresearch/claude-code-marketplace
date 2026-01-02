# PHP 8.x Feature Adoption Patterns

## PHP 8.0 Features

### Named Arguments

```php
// Before: positional arguments
htmlspecialchars($string, ENT_QUOTES, 'UTF-8', true);

// After: named arguments for clarity
htmlspecialchars(
    string: $string,
    flags: ENT_QUOTES,
    encoding: 'UTF-8',
    double_encode: true
);

// Skip optional parameters
setcookie(
    name: 'session',
    value: $token,
    httponly: true,
    secure: true,
);
```

### Constructor Property Promotion

```php
// Traditional constructor
class Point
{
    public float $x;
    public float $y;
    public float $z;

    public function __construct(float $x, float $y, float $z)
    {
        $this->x = $x;
        $this->y = $y;
        $this->z = $z;
    }
}

// PHP 8.0 promoted properties
class Point
{
    public function __construct(
        public float $x,
        public float $y,
        public float $z,
    ) {}
}

// Mixed promotion (some promoted, some not)
class Entity
{
    private \DateTimeImmutable $createdAt;

    public function __construct(
        public readonly int $id,
        public string $name,
        ?\DateTimeImmutable $createdAt = null,
    ) {
        $this->createdAt = $createdAt ?? new \DateTimeImmutable();
    }
}
```

### Union Types

```php
// Accept multiple types
function processInput(string|array|Stringable $input): string|false
{
    if (is_array($input)) {
        return implode(', ', $input);
    }
    return (string) $input;
}

// Nullable shorthand still works
function find(int $id): ?User  // Same as User|null
{
    return $this->repository->find($id);
}

// Union with false (common return pattern)
function fetchData(): array|false
{
    $result = file_get_contents($url);
    return $result !== false ? json_decode($result, true) : false;
}
```

### Match Expression

```php
// Before: switch statement
switch ($status) {
    case 'draft':
        $label = 'Draft';
        break;
    case 'published':
        $label = 'Published';
        break;
    default:
        $label = 'Unknown';
}

// After: match expression
$label = match($status) {
    'draft' => 'Draft',
    'published' => 'Published',
    default => 'Unknown',
};

// Match with multiple conditions
$category = match(true) {
    $age < 13 => 'child',
    $age < 20 => 'teen',
    $age < 65 => 'adult',
    default => 'senior',
};

// Match in return statements
public function getStatusCode(): int
{
    return match($this->status) {
        Status::OK => 200,
        Status::CREATED => 201,
        Status::NOT_FOUND => 404,
        Status::ERROR => 500,
    };
}
```

### Nullsafe Operator

```php
// Before: nested null checks
$country = null;
if ($user !== null) {
    $address = $user->getAddress();
    if ($address !== null) {
        $country = $address->getCountry();
    }
}

// After: nullsafe operator
$country = $user?->getAddress()?->getCountry();

// Combine with null coalescing
$countryCode = $user?->getAddress()?->getCountry()?->getCode() ?? 'US';
```

### Attributes

```php
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Validator\Constraints as Assert;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: 'users')]
class User
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\Column(length: 180, unique: true)]
    #[Assert\NotBlank]
    #[Assert\Email]
    private string $email;

    #[ORM\Column]
    #[Assert\Length(min: 2, max: 100)]
    private string $name;
}

// Controller with route attribute
#[Route('/api/users', name: 'api_users_')]
class UserController
{
    #[Route('', name: 'list', methods: ['GET'])]
    public function list(): JsonResponse
    {
        // ...
    }

    #[Route('/{id}', name: 'show', methods: ['GET'])]
    public function show(int $id): JsonResponse
    {
        // ...
    }
}
```

## PHP 8.1 Features

### Enums

```php
// Basic enum
enum Suit
{
    case Hearts;
    case Diamonds;
    case Clubs;
    case Spades;
}

// Backed enum with values
enum Status: string
{
    case DRAFT = 'draft';
    case PENDING = 'pending';
    case PUBLISHED = 'published';

    public function label(): string
    {
        return match($this) {
            self::DRAFT => 'Draft',
            self::PENDING => 'Pending Review',
            self::PUBLISHED => 'Published',
        };
    }

    public function color(): string
    {
        return match($this) {
            self::DRAFT => 'gray',
            self::PENDING => 'yellow',
            self::PUBLISHED => 'green',
        };
    }
}

// Int-backed enum
enum Priority: int
{
    case LOW = 1;
    case MEDIUM = 2;
    case HIGH = 3;
    case CRITICAL = 4;

    public static function fromScore(int $score): self
    {
        return match(true) {
            $score < 25 => self::LOW,
            $score < 50 => self::MEDIUM,
            $score < 75 => self::HIGH,
            default => self::CRITICAL,
        };
    }
}
```

### Enums for Type-Safe Options

Replace string/array constants with backed enums for type-safe API design:

```php
/**
 * Defines how a secret should be placed in an HTTP request.
 */
enum SecretPlacement: string
{
    case Bearer = 'bearer';
    case BasicAuth = 'basic';
    case Header = 'header';
    case QueryParam = 'query';
    case BodyField = 'body_field';
    case OAuth2 = 'oauth2';
    case ApiKey = 'api_key';

    /**
     * Human-readable description for UI/docs.
     */
    public function description(): string
    {
        return match ($this) {
            self::Bearer => 'Bearer token in Authorization header',
            self::BasicAuth => 'HTTP Basic Authentication',
            self::Header => 'Custom header value',
            self::QueryParam => 'URL query parameter',
            self::BodyField => 'Request body field',
            self::OAuth2 => 'OAuth 2.0 with automatic token refresh',
            self::ApiKey => 'X-API-Key header',
        };
    }

    /**
     * Check if this placement requires additional config.
     */
    public function requiresConfig(): bool
    {
        return match ($this) {
            self::Header, self::QueryParam, self::BodyField, self::OAuth2 => true,
            default => false,
        };
    }

    /**
     * Default config key if applicable.
     */
    public function defaultConfigKey(): ?string
    {
        return match ($this) {
            self::Header, self::ApiKey => 'X-API-Key',
            self::QueryParam, self::BodyField => 'api_key',
            default => null,
        };
    }
}

// Usage with type safety
public function injectAuth(
    array $options,
    SecretPlacement $placement,  // Type-safe, IDE autocompletion
): array {
    return match ($placement) {
        SecretPlacement::Bearer => $this->addBearerAuth($options),
        SecretPlacement::BasicAuth => $this->addBasicAuth($options),
        SecretPlacement::Header => $this->addHeaderAuth($options),
        // match() ensures all cases are handled!
    };
}
```

**Benefits over string constants:**
- Compile-time type checking
- IDE autocompletion
- Exhaustive match() enforcement
- Methods encapsulate related logic
- Self-documenting API
```

### Readonly Properties

```php
class BlogPost
{
    public function __construct(
        public readonly int $id,
        public readonly string $title,
        public readonly \DateTimeImmutable $publishedAt,
        private string $content,  // Not readonly, can be updated
    ) {}

    public function updateContent(string $content): void
    {
        $this->content = $content;  // OK
        // $this->title = 'New';    // Error: Cannot modify readonly property
    }
}
```

### First-class Callable Syntax

```php
// Before: Closure::fromCallable()
$fn = Closure::fromCallable([$this, 'process']);

// After: First-class callable syntax
$fn = $this->process(...);

// Works with static methods too
$validator = Validator::validate(...);

// And with functions
$trimmer = trim(...);

// Use in array_map
$names = array_map($user->getName(...), $users);
```

### Intersection Types

```php
// Require multiple interfaces
function processTraversableAndCountable(Traversable&Countable $collection): int
{
    return count($collection);
}

// Type alias via PHPDoc for complex intersections
/**
 * @param ArrayAccess&Countable&Iterator $collection
 */
function processCollection($collection): void
{
    foreach ($collection as $item) {
        // ...
    }
}
```

### New in Initializers

```php
class Service
{
    public function __construct(
        private Logger $logger = new NullLogger(),
        private array $options = [],
    ) {}
}

// With attributes
#[Attribute]
class MyAttribute
{
    public function __construct(
        public array $values = [],
        public \DateTimeImmutable $since = new \DateTimeImmutable('2024-01-01'),
    ) {}
}
```

## PHP 8.2 Features

### Readonly Classes

```php
// All properties are implicitly readonly
readonly class UserDTO
{
    public function __construct(
        public int $id,
        public string $name,
        public string $email,
        public ?string $phone,
    ) {}
}

// Cannot have non-readonly properties
// Cannot have static properties
// All properties must be typed
```

### Disjunctive Normal Form (DNF) Types

```php
// Combine union and intersection types
function process((Countable&Iterator)|array $input): int
{
    if (is_array($input)) {
        return count($input);
    }
    return iterator_count($input);
}
```

### Constants in Traits

```php
trait HasVersion
{
    public const VERSION = '1.0.0';

    public function getVersion(): string
    {
        return self::VERSION;
    }
}
```

### Sensitive Parameter Attribute

```php
function authenticate(
    string $username,
    #[\SensitiveParameter] string $password,
): bool {
    // If exception is thrown, $password is redacted in stack trace
    return $this->authService->verify($username, $password);
}
```

## PHP 8.3 Features

### Typed Class Constants

```php
class Config
{
    public const string APP_NAME = 'MyApp';
    public const int MAX_RETRIES = 3;
    public const array ALLOWED_HOSTS = ['localhost', 'example.com'];

    // Works with visibility
    protected const float TAX_RATE = 0.21;
    private const string SECRET = 'xxx';
}

interface Configurable
{
    public const string VERSION;  // Must be implemented with string type
}
```

### Dynamic Class Constant Fetch

```php
class Permissions
{
    public const READ = 1;
    public const WRITE = 2;
    public const DELETE = 4;
}

$permission = 'WRITE';
$value = Permissions::{$permission};  // 2
```

### #[Override] Attribute

```php
class ParentClass
{
    public function process(): void {}
}

class ChildClass extends ParentClass
{
    #[Override]
    public function process(): void
    {
        // If parent method is removed/renamed, this will error
        parent::process();
    }

    #[Override]
    public function prcess(): void  // Typo! Error at compile time
    {
    }
}
```

### json_validate() Function

```php
// Before: Decode and check for errors
$data = json_decode($json);
if (json_last_error() !== JSON_ERROR_NONE) {
    throw new InvalidArgumentException('Invalid JSON');
}

// After: Validate without decoding
if (!json_validate($json)) {
    throw new InvalidArgumentException('Invalid JSON');
}
```

## PHP 8.4 Features (Preview)

### Property Hooks

```php
class User
{
    public string $fullName {
        get => $this->firstName . ' ' . $this->lastName;
        set => [$this->firstName, $this->lastName] = explode(' ', $value, 2);
    }

    public function __construct(
        private string $firstName,
        private string $lastName,
    ) {}
}
```

### Asymmetric Visibility

```php
class BankAccount
{
    public private(set) float $balance = 0.0;

    public function deposit(float $amount): void
    {
        $this->balance += $amount;
    }
}

// $account->balance;      // OK - public read
// $account->balance = 10; // Error - private write
```
