# Go API Design Patterns

## Bitmask Options Pattern

The bitmask pattern allows combining multiple options into a single value, enabling flexible API configuration.

### Defining Options

```go
// ParseOption represents parser configuration flags.
type ParseOption int

const (
    Second         ParseOption = 1 << iota // Enable seconds field
    SecondOptional                         // Seconds field is optional
    Minute                                 // Enable minutes field
    Hour                                   // Enable hours field
    Dom                                    // Day of month
    Month                                  // Month field
    Dow                                    // Day of week
    DowOptional                            // Day of week is optional
    Descriptor                             // Allow @hourly, @daily, etc.
    Year                                   // Year field support
    Hash                                   // Jenkins-style H expressions
)
```

### Using Combined Options

```go
// Users can combine options with bitwise OR
parser := NewParser(Minute | Hour | Dom | Month | Dow | Descriptor)

// Check if option is enabled
func (p Parser) hasOption(opt ParseOption) bool {
    return p.options&opt != 0
}

// Common presets
const (
    StandardParser = Minute | Hour | Dom | Month | Dow | Descriptor
    ExtendedParser = Second | Minute | Hour | Dom | Month | Dow | Descriptor
)
```

### Variadic Options Alternative

For simpler APIs, use variadic functional options:

```go
// Option is a function that configures Parser
type Option func(*Parser)

// WithSeconds enables seconds field
func WithSeconds() Option {
    return func(p *Parser) {
        p.parseSeconds = true
    }
}

// WithHash enables hash expressions with a key
func WithHash(key string) Option {
    return func(p *Parser) {
        p.hashEnabled = true
        p.hashKey = key
    }
}

// Usage
parser := NewParser(
    WithSeconds(),
    WithHash("my-job"),
)
```

### Comparison

| Pattern | Best For | Example |
|---------|----------|---------|
| **Bitmask** | Many boolean flags, performance-critical | `Minute \| Hour \| Dom` |
| **Functional Options** | Complex configuration, optional params | `WithTimeout(30*time.Second)` |
| **Builder** | Step-by-step construction, validation | `NewBuilder().WithX().WithY().Build()` |

## Functional Options Pattern

For APIs with many optional parameters:

```go
// Config holds parser configuration
type Config struct {
    timeout     time.Duration
    location    *time.Location
    hashKey     string
    maxJobs     int
}

// Option configures the parser
type Option func(*Config)

// WithTimeout sets operation timeout
func WithTimeout(d time.Duration) Option {
    return func(c *Config) {
        c.timeout = d
    }
}

// WithLocation sets timezone
func WithLocation(loc *time.Location) Option {
    return func(c *Config) {
        c.location = loc
    }
}

// WithHashKey enables hash expressions
func WithHashKey(key string) Option {
    return func(c *Config) {
        c.hashKey = key
    }
}

// NewParser creates a parser with options
func NewParser(opts ...Option) *Parser {
    // Start with defaults
    cfg := &Config{
        timeout:  30 * time.Second,
        location: time.Local,
        maxJobs:  100,
    }

    // Apply options
    for _, opt := range opts {
        opt(cfg)
    }

    return &Parser{config: cfg}
}

// Usage
parser := NewParser(
    WithTimeout(1*time.Minute),
    WithLocation(time.UTC),
    WithHashKey("my-job"),
)
```

## Builder Pattern with Chaining

For complex object construction with validation:

```go
// ParserBuilder constructs Parser instances
type ParserBuilder struct {
    options   ParseOption
    hashKey   string
    location  *time.Location
    err       error
}

// NewParserBuilder starts building a parser
func NewParserBuilder() *ParserBuilder {
    return &ParserBuilder{
        location: time.Local,
    }
}

// WithOptions sets parsing options
func (b *ParserBuilder) WithOptions(opts ParseOption) *ParserBuilder {
    b.options = opts
    return b
}

// WithHashKey enables and sets hash key
func (b *ParserBuilder) WithHashKey(key string) *ParserBuilder {
    if key == "" {
        b.err = errors.New("hash key cannot be empty")
        return b
    }
    b.options |= Hash
    b.hashKey = key
    return b
}

// WithLocation sets timezone
func (b *ParserBuilder) WithLocation(loc *time.Location) *ParserBuilder {
    if loc == nil {
        b.err = errors.New("location cannot be nil")
        return b
    }
    b.location = loc
    return b
}

// Build creates the parser or returns an error
func (b *ParserBuilder) Build() (*Parser, error) {
    if b.err != nil {
        return nil, b.err
    }

    // Validate configuration
    if b.options&Hash != 0 && b.hashKey == "" {
        return nil, errors.New("hash option requires hash key")
    }

    return &Parser{
        options:  b.options,
        hashKey:  b.hashKey,
        location: b.location,
    }, nil
}

// Usage
parser, err := NewParserBuilder().
    WithOptions(Minute | Hour | Dom | Month | Dow).
    WithHashKey("my-job").
    WithLocation(time.UTC).
    Build()
```

## Method Chaining for Parser Configuration

Combine builder-style configuration with immediate use:

```go
// Parser supports method chaining
type Parser struct {
    options ParseOption
    hashKey string
}

// NewParser creates a parser with base options
func NewParser(opts ParseOption) Parser {
    return Parser{options: opts}
}

// WithHashKey returns a new parser with hash support
func (p Parser) WithHashKey(key string) Parser {
    return Parser{
        options: p.options | Hash,
        hashKey: key,
    }
}

// Parse parses a cron expression
func (p Parser) Parse(spec string) (Schedule, error) {
    // Implementation
}

// ParseWithHashKey parses with explicit hash key
func (p Parser) ParseWithHashKey(spec, key string) (Schedule, error) {
    return p.WithHashKey(key).Parse(spec)
}

// Usage - multiple styles
parser := NewParser(Minute | Hour | Dom | Month | Dow | Descriptor)

// Style 1: Method chaining
schedule, err := parser.WithHashKey("job1").Parse("H * * * *")

// Style 2: Direct method
schedule, err := parser.ParseWithHashKey("H * * * *", "job1")

// Style 3: Reusable configured parser
hashParser := parser.WithHashKey("default-job")
schedule, err := hashParser.Parse("H H * * *")
```

## Error Design

### Custom Error Types

```go
// ValidationError provides detailed validation feedback
type ValidationError struct {
    Message string
    Field   string // Which field caused the error
    Value   string // The invalid value
}

func (e *ValidationError) Error() string {
    if e.Field != "" {
        return e.Message + " in " + e.Field + ": " + e.Value
    }
    return e.Message
}

// Sentinel errors for common cases
var (
    ErrEmptySpec = &ValidationError{Message: "empty spec string"}
    ErrInvalidFormat = &ValidationError{Message: "invalid format"}
)

// Usage with errors.Is/As
if errors.Is(err, ErrEmptySpec) {
    // Handle empty spec
}

var validationErr *ValidationError
if errors.As(err, &validationErr) {
    fmt.Printf("Field %s is invalid: %s\n", validationErr.Field, validationErr.Value)
}
```

### Error Strings Convention (ST1005)

```go
// BAD - Capitalized, has punctuation
return errors.New("Invalid input provided.")

// GOOD - Lowercase, no punctuation
return errors.New("invalid input provided")

// BAD - Starts with uppercase
return fmt.Errorf("Failed to parse: %w", err)

// GOOD - Starts with lowercase
return fmt.Errorf("failed to parse: %w", err)
```

## Interface Design

### Small, Focused Interfaces

```go
// BAD - Kitchen sink interface
type Scheduler interface {
    AddJob(spec string, cmd func()) (EntryID, error)
    RemoveJob(id EntryID)
    Start()
    Stop()
    Running() bool
    Entries() []Entry
    Location() *time.Location
    // ... many more methods
}

// GOOD - Focused interfaces
type JobAdder interface {
    AddJob(spec string, cmd func()) (EntryID, error)
}

type JobRemover interface {
    RemoveJob(id EntryID)
}

type Lifecycle interface {
    Start()
    Stop()
    Running() bool
}

// Composed when needed
type Scheduler interface {
    JobAdder
    JobRemover
    Lifecycle
}
```

### Accept Interfaces, Return Structs

```go
// GOOD - Accept interface for flexibility
func ProcessSchedule(s Schedule) error {
    next := s.Next(time.Now())
    // ...
}

// GOOD - Return concrete type for usability
func Parse(spec string) (*SpecSchedule, error) {
    // Users get full type with all methods
}
```

## Validation API Pattern

Provide both quick validation and detailed analysis:

```go
// Quick validation - returns error or nil
func ValidateSpec(spec string, opts ...ParseOption) error {
    parser := getParserForOptions(opts)
    _, err := parser.Parse(spec)
    return err
}

// Detailed analysis - returns rich result
type SpecAnalysis struct {
    Valid       bool
    Error       error
    NextRun     time.Time
    Location    *time.Location
    Fields      map[string]string
    IsDescriptor bool
    Interval    time.Duration
    Schedule    Schedule
}

func AnalyzeSpec(spec string, opts ...ParseOption) SpecAnalysis {
    result := SpecAnalysis{Fields: make(map[string]string)}

    parser := getParserForOptions(opts)
    schedule, err := parser.Parse(spec)
    if err != nil {
        result.Error = err
        return result
    }

    result.Valid = true
    result.Schedule = schedule
    result.NextRun = schedule.Next(time.Now())
    // ... populate other fields

    return result
}

// Usage
if err := ValidateSpec(userInput); err != nil {
    return fmt.Errorf("invalid cron: %w", err)
}

// Or for detailed feedback
analysis := AnalyzeSpec(userInput)
if !analysis.Valid {
    log.Printf("Invalid: %v", analysis.Error)
} else {
    log.Printf("Next run: %v, Fields: %v", analysis.NextRun, analysis.Fields)
}
```
