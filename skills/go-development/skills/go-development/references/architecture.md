# Go Architecture Patterns

## Package Structure

### Standard Layout

```
project/
├── cmd/                    # Entry points
│   ├── server/
│   │   └── main.go
│   └── cli/
│       └── main.go
├── core/                   # Core business logic
│   ├── job.go             # Domain types
│   ├── scheduler.go       # Core orchestration
│   ├── resilient_job.go   # Wrapper with retry
│   └── docker_client.go   # External integrations
├── cli/                    # CLI commands
│   ├── daemon.go
│   ├── validate.go
│   └── config.go
├── web/                    # HTTP layer
│   ├── server.go
│   ├── handlers.go
│   ├── middleware.go
│   └── auth.go
├── config/                 # Configuration
│   ├── config.go
│   ├── validator.go
│   └── sanitizer.go
├── middlewares/            # Cross-cutting concerns
│   ├── logging.go
│   ├── metrics.go
│   └── notifications.go
├── metrics/                # Observability
│   └── prometheus.go
├── internal/               # Private packages
│   └── helpers/
└── test/                   # Test utilities
    ├── fixtures/
    └── helpers.go
```

### Package Responsibilities

| Package | Purpose | Dependencies |
|---------|---------|--------------|
| `cmd/` | Entry points, wire up | All |
| `core/` | Business logic | Minimal |
| `cli/` | User interface | core, config |
| `web/` | HTTP API | core, config |
| `config/` | Configuration | None |
| `middlewares/` | Cross-cutting | core |
| `internal/` | Private helpers | None |

## Job Abstraction Hierarchy

### Interface Definition

```go
// BareJob defines the minimal job interface
type BareJob interface {
    GetName() string
    GetSchedule() string
    Run(ctx context.Context) error
}

// JobConfig contains common job configuration
type JobConfig struct {
    Name        string
    Schedule    string
    Command     []string
    Environment map[string]string
    Timeout     time.Duration
}
```

### Implementation Patterns

```go
// ExecJob executes in a running container
type ExecJob struct {
    JobConfig
    Container string
    Client    DockerClient
}

func (j *ExecJob) Run(ctx context.Context) error {
    return j.Client.ExecInContainer(ctx, j.Container, j.Command)
}

// RunJob starts a new container
type RunJob struct {
    JobConfig
    Image  string
    Client DockerClient
}

func (j *RunJob) Run(ctx context.Context) error {
    containerID, err := j.Client.CreateContainer(ctx, j.Image, j.Command)
    if err != nil {
        return err
    }
    defer j.Client.RemoveContainer(ctx, containerID)
    return j.Client.StartContainer(ctx, containerID)
}

// LocalJob executes on the host
type LocalJob struct {
    JobConfig
}

func (j *LocalJob) Run(ctx context.Context) error {
    cmd := exec.CommandContext(ctx, j.Command[0], j.Command[1:]...)
    return cmd.Run()
}
```

### Resilient Wrapper

```go
// ResilientJob wraps any BareJob with retry logic
type ResilientJob struct {
    Job         BareJob
    MaxRetries  int
    RetryDelay  time.Duration
    OnError     func(error, int)
}

func (r *ResilientJob) Run(ctx context.Context) error {
    var lastErr error
    for attempt := 1; attempt <= r.MaxRetries; attempt++ {
        if err := r.Job.Run(ctx); err == nil {
            return nil
        } else {
            lastErr = err
            if r.OnError != nil {
                r.OnError(err, attempt)
            }
            if attempt < r.MaxRetries {
                select {
                case <-time.After(r.RetryDelay):
                case <-ctx.Done():
                    return ctx.Err()
                }
            }
        }
    }
    return fmt.Errorf("job failed after %d attempts: %w", r.MaxRetries, lastErr)
}
```

## Configuration Management

### 5-Layer Precedence

```go
type Config struct {
    // Layer 1: Built-in defaults (struct tags)
    LogLevel     string `default:"info"`
    PollInterval int    `default:"10"`

    // Layer 2: File configuration
    ConfigFile string `flag:"config" default:"/etc/app/config.ini"`

    // Layer 3: External sources (Docker labels, K8s)
    // Loaded dynamically

    // Layer 4: CLI flags
    Verbose bool `flag:"verbose" short:"v"`

    // Layer 5: Environment variables (highest priority)
    // PREFIX_LOG_LEVEL, PREFIX_POLL_INTERVAL
}

func LoadConfig() (*Config, error) {
    cfg := &Config{}

    // 1. Apply defaults
    applyDefaults(cfg)

    // 2. Load from config file
    if err := loadFromFile(cfg, cfg.ConfigFile); err != nil {
        log.Warn("Config file not found, using defaults")
    }

    // 3. Load from external sources (if applicable)
    loadFromExternalSources(cfg)

    // 4. Parse CLI flags
    parseFlags(cfg)

    // 5. Override with environment variables
    loadFromEnv(cfg, "APP")

    return cfg, validate(cfg)
}
```

### Dynamic Configuration Reloading

```go
type ConfigWatcher struct {
    path     string
    config   atomic.Value
    onChange func(*Config)
}

func (w *ConfigWatcher) Watch(ctx context.Context) {
    watcher, _ := fsnotify.NewWatcher()
    watcher.Add(w.path)

    for {
        select {
        case event := <-watcher.Events:
            if event.Op&fsnotify.Write == fsnotify.Write {
                if cfg, err := LoadConfigFromFile(w.path); err == nil {
                    w.config.Store(cfg)
                    if w.onChange != nil {
                        w.onChange(cfg)
                    }
                }
            }
        case <-ctx.Done():
            return
        }
    }
}
```

## Middleware Chain Pattern

### Implementation

```go
type Middleware func(Job) Job

type MiddlewareChain struct {
    middlewares []Middleware
}

func (c *MiddlewareChain) Use(m Middleware) {
    c.middlewares = append(c.middlewares, m)
}

func (c *MiddlewareChain) Wrap(job Job) Job {
    wrapped := job
    for i := len(c.middlewares) - 1; i >= 0; i-- {
        wrapped = c.middlewares[i](wrapped)
    }
    return wrapped
}
```

### Common Middlewares

```go
// Logging middleware
func WithLogging(logger *logrus.Logger) Middleware {
    return func(next Job) Job {
        return JobFunc(func(ctx context.Context) error {
            start := time.Now()
            logger.WithField("job", next.GetName()).Info("Starting job")

            err := next.Run(ctx)

            fields := logrus.Fields{
                "job":      next.GetName(),
                "duration": time.Since(start),
            }
            if err != nil {
                logger.WithFields(fields).WithError(err).Error("Job failed")
            } else {
                logger.WithFields(fields).Info("Job completed")
            }
            return err
        })
    }
}

// Metrics middleware
func WithMetrics(registry *prometheus.Registry) Middleware {
    duration := prometheus.NewHistogramVec(...)
    counter := prometheus.NewCounterVec(...)

    return func(next Job) Job {
        return JobFunc(func(ctx context.Context) error {
            timer := prometheus.NewTimer(duration.WithLabelValues(next.GetName()))
            defer timer.ObserveDuration()

            err := next.Run(ctx)
            if err != nil {
                counter.WithLabelValues(next.GetName(), "error").Inc()
            } else {
                counter.WithLabelValues(next.GetName(), "success").Inc()
            }
            return err
        })
    }
}

// Notification middleware
func WithSlackNotification(webhookURL string, onlyOnError bool) Middleware {
    return func(next Job) Job {
        return JobFunc(func(ctx context.Context) error {
            err := next.Run(ctx)
            if err != nil || !onlyOnError {
                sendSlackNotification(webhookURL, next.GetName(), err)
            }
            return err
        })
    }
}
```

## Scheduler Architecture

### Core Loop Pattern

```go
type Scheduler struct {
    cron    *cron.Cron
    jobs    map[string]cron.EntryID
    mu      sync.RWMutex
    ctx     context.Context
    cancel  context.CancelFunc
}

func NewScheduler() *Scheduler {
    ctx, cancel := context.WithCancel(context.Background())
    return &Scheduler{
        cron:   cron.New(cron.WithSeconds()),
        jobs:   make(map[string]cron.EntryID),
        ctx:    ctx,
        cancel: cancel,
    }
}

func (s *Scheduler) AddJob(job Job) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    entryID, err := s.cron.AddFunc(job.GetSchedule(), func() {
        if err := job.Run(s.ctx); err != nil {
            log.WithError(err).Error("Job execution failed")
        }
    })
    if err != nil {
        return err
    }

    s.jobs[job.GetName()] = entryID
    return nil
}

func (s *Scheduler) Start() {
    s.cron.Start()
}

func (s *Scheduler) Stop() {
    s.cancel()
    ctx := s.cron.Stop()
    <-ctx.Done()
}
```

### Dynamic Job Management

```go
func (s *Scheduler) RemoveJob(name string) {
    s.mu.Lock()
    defer s.mu.Unlock()

    if entryID, ok := s.jobs[name]; ok {
        s.cron.Remove(entryID)
        delete(s.jobs, name)
    }
}

func (s *Scheduler) UpdateJob(job Job) error {
    s.RemoveJob(job.GetName())
    return s.AddJob(job)
}

func (s *Scheduler) ListJobs() []string {
    s.mu.RLock()
    defer s.mu.RUnlock()

    names := make([]string, 0, len(s.jobs))
    for name := range s.jobs {
        names = append(names, name)
    }
    return names
}
```

## Web API Architecture

### Standard Endpoints

```go
// API endpoint structure
GET  /api/jobs              // List all jobs
GET  /api/jobs/{name}       // Get job details
POST /api/jobs              // Create new job
PUT  /api/jobs/{name}       // Update job
DELETE /api/jobs/{name}     // Delete job
POST /api/jobs/{name}/run   // Trigger job manually
GET  /api/jobs/{name}/history // Execution history
GET  /health                // Health check
GET  /metrics               // Prometheus metrics
```

### Handler Pattern

```go
type Handler struct {
    scheduler *Scheduler
    logger    *logrus.Logger
}

func (h *Handler) ListJobs(w http.ResponseWriter, r *http.Request) {
    jobs := h.scheduler.ListJobs()
    json.NewEncoder(w).Encode(jobs)
}

func (h *Handler) TriggerJob(w http.ResponseWriter, r *http.Request) {
    name := chi.URLParam(r, "name")

    job, err := h.scheduler.GetJob(name)
    if err != nil {
        http.Error(w, "Job not found", http.StatusNotFound)
        return
    }

    go func() {
        if err := job.Run(context.Background()); err != nil {
            h.logger.WithError(err).Error("Manual job execution failed")
        }
    }()

    w.WriteHeader(http.StatusAccepted)
}
```

## Error Handling Patterns

### Domain Errors

```go
// Custom error types
type JobNotFoundError struct {
    Name string
}

func (e *JobNotFoundError) Error() string {
    return fmt.Sprintf("job not found: %s", e.Name)
}

type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed for %s: %s", e.Field, e.Message)
}

// Error checking
func HandleJob(name string) error {
    job, err := scheduler.GetJob(name)
    if err != nil {
        var notFound *JobNotFoundError
        if errors.As(err, &notFound) {
            // Handle not found
            return nil
        }
        return err
    }
    return job.Run(context.Background())
}
```

### Sentinel Errors

```go
var (
    ErrJobNotFound     = errors.New("job not found")
    ErrInvalidSchedule = errors.New("invalid schedule expression")
    ErrContainerDied   = errors.New("container died unexpectedly")
)

func GetJob(name string) (Job, error) {
    job, ok := jobs[name]
    if !ok {
        return nil, fmt.Errorf("%w: %s", ErrJobNotFound, name)
    }
    return job, nil
}
```
