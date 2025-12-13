# Resilience Patterns in Go

## Retry Logic

### Basic Exponential Backoff

```go
type RetryConfig struct {
    MaxAttempts   int
    InitialDelay  time.Duration
    MaxDelay      time.Duration
    BackoffFactor float64
    Jitter        bool
}

func DefaultRetryConfig() RetryConfig {
    return RetryConfig{
        MaxAttempts:   3,
        InitialDelay:  100 * time.Millisecond,
        MaxDelay:      30 * time.Second,
        BackoffFactor: 2.0,
        Jitter:        true,
    }
}

func WithRetry(ctx context.Context, cfg RetryConfig, fn func() error) error {
    delay := cfg.InitialDelay

    for attempt := 1; attempt <= cfg.MaxAttempts; attempt++ {
        err := fn()
        if err == nil {
            return nil
        }

        // Don't retry on context cancellation
        if ctx.Err() != nil {
            return ctx.Err()
        }

        // Check if error is retryable
        if !isRetryable(err) {
            return err
        }

        if attempt < cfg.MaxAttempts {
            actualDelay := delay
            if cfg.Jitter {
                actualDelay = addJitter(delay)
            }

            select {
            case <-time.After(actualDelay):
            case <-ctx.Done():
                return ctx.Err()
            }

            delay = time.Duration(float64(delay) * cfg.BackoffFactor)
            if delay > cfg.MaxDelay {
                delay = cfg.MaxDelay
            }
        }
    }

    return fmt.Errorf("operation failed after %d attempts", cfg.MaxAttempts)
}

func addJitter(d time.Duration) time.Duration {
    jitter := time.Duration(rand.Int63n(int64(d / 2)))
    return d + jitter
}

func isRetryable(err error) bool {
    // Network errors, timeouts are retryable
    var netErr net.Error
    if errors.As(err, &netErr) {
        return netErr.Temporary() || netErr.Timeout()
    }

    // Context cancellation is not retryable
    if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
        return false
    }

    return true
}
```

### Retry with Callback

```go
type RetryCallback func(attempt int, err error, nextDelay time.Duration)

func WithRetryCallback(ctx context.Context, cfg RetryConfig, fn func() error, cb RetryCallback) error {
    delay := cfg.InitialDelay

    for attempt := 1; attempt <= cfg.MaxAttempts; attempt++ {
        err := fn()
        if err == nil {
            return nil
        }

        if cb != nil {
            cb(attempt, err, delay)
        }

        if attempt < cfg.MaxAttempts {
            select {
            case <-time.After(delay):
            case <-ctx.Done():
                return ctx.Err()
            }
            delay = time.Duration(float64(delay) * cfg.BackoffFactor)
        }
    }

    return fmt.Errorf("failed after %d attempts", cfg.MaxAttempts)
}
```

## Graceful Shutdown

### Complete Shutdown Handler

```go
type ShutdownManager struct {
    ctx        context.Context
    cancel     context.CancelFunc
    wg         sync.WaitGroup
    timeout    time.Duration
    cleanups   []func(context.Context) error
    mu         sync.Mutex
    shutdownCh chan struct{}
}

func NewShutdownManager(timeout time.Duration) *ShutdownManager {
    ctx, cancel := context.WithCancel(context.Background())
    return &ShutdownManager{
        ctx:        ctx,
        cancel:     cancel,
        timeout:    timeout,
        cleanups:   make([]func(context.Context) error, 0),
        shutdownCh: make(chan struct{}),
    }
}

func (sm *ShutdownManager) RegisterCleanup(fn func(context.Context) error) {
    sm.mu.Lock()
    defer sm.mu.Unlock()
    sm.cleanups = append(sm.cleanups, fn)
}

func (sm *ShutdownManager) Context() context.Context {
    return sm.ctx
}

func (sm *ShutdownManager) AddWorker() {
    sm.wg.Add(1)
}

func (sm *ShutdownManager) WorkerDone() {
    sm.wg.Done()
}

func (sm *ShutdownManager) WaitForSignal() {
    sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, syscall.SIGTERM, syscall.SIGINT, syscall.SIGHUP)

    select {
    case sig := <-sigChan:
        log.WithField("signal", sig).Info("Received shutdown signal")
    case <-sm.shutdownCh:
        log.Info("Shutdown requested programmatically")
    }

    sm.Shutdown()
}

func (sm *ShutdownManager) Shutdown() {
    log.Info("Starting graceful shutdown")

    // Cancel context to stop accepting new work
    sm.cancel()

    // Create timeout context for cleanup
    shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), sm.timeout)
    defer shutdownCancel()

    // Wait for workers with timeout
    workersDone := make(chan struct{})
    go func() {
        sm.wg.Wait()
        close(workersDone)
    }()

    select {
    case <-workersDone:
        log.Info("All workers finished")
    case <-shutdownCtx.Done():
        log.Warn("Timeout waiting for workers")
    }

    // Run cleanup functions
    sm.mu.Lock()
    cleanups := sm.cleanups
    sm.mu.Unlock()

    for i := len(cleanups) - 1; i >= 0; i-- {
        if err := cleanups[i](shutdownCtx); err != nil {
            log.WithError(err).Error("Cleanup function failed")
        }
    }

    log.Info("Graceful shutdown complete")
}

func (sm *ShutdownManager) RequestShutdown() {
    close(sm.shutdownCh)
}
```

### Usage Example

```go
func main() {
    sm := NewShutdownManager(30 * time.Second)

    // Register cleanup functions
    sm.RegisterCleanup(func(ctx context.Context) error {
        log.Info("Closing database connections")
        return db.Close()
    })

    sm.RegisterCleanup(func(ctx context.Context) error {
        log.Info("Flushing metrics")
        return metrics.Flush(ctx)
    })

    // Start server
    server := &http.Server{Addr: ":8080"}
    sm.RegisterCleanup(func(ctx context.Context) error {
        return server.Shutdown(ctx)
    })

    go func() {
        if err := server.ListenAndServe(); err != http.ErrServerClosed {
            log.WithError(err).Fatal("Server error")
        }
    }()

    // Start workers
    for i := 0; i < 5; i++ {
        sm.AddWorker()
        go func(id int) {
            defer sm.WorkerDone()
            worker(sm.Context(), id)
        }(i)
    }

    // Wait for shutdown signal
    sm.WaitForSignal()
}
```

## Circuit Breaker

```go
type CircuitState int

const (
    CircuitClosed CircuitState = iota
    CircuitOpen
    CircuitHalfOpen
)

type CircuitBreaker struct {
    mu              sync.RWMutex
    state           CircuitState
    failures        int
    successes       int
    threshold       int
    resetTimeout    time.Duration
    halfOpenMax     int
    lastFailureTime time.Time
}

func NewCircuitBreaker(threshold int, resetTimeout time.Duration) *CircuitBreaker {
    return &CircuitBreaker{
        state:        CircuitClosed,
        threshold:    threshold,
        resetTimeout: resetTimeout,
        halfOpenMax:  3,
    }
}

func (cb *CircuitBreaker) Execute(fn func() error) error {
    if !cb.canExecute() {
        return errors.New("circuit breaker is open")
    }

    err := fn()
    cb.recordResult(err)
    return err
}

func (cb *CircuitBreaker) canExecute() bool {
    cb.mu.RLock()
    defer cb.mu.RUnlock()

    switch cb.state {
    case CircuitClosed:
        return true
    case CircuitOpen:
        if time.Since(cb.lastFailureTime) > cb.resetTimeout {
            cb.mu.RUnlock()
            cb.mu.Lock()
            cb.state = CircuitHalfOpen
            cb.successes = 0
            cb.mu.Unlock()
            cb.mu.RLock()
            return true
        }
        return false
    case CircuitHalfOpen:
        return true
    }
    return false
}

func (cb *CircuitBreaker) recordResult(err error) {
    cb.mu.Lock()
    defer cb.mu.Unlock()

    if err != nil {
        cb.failures++
        cb.lastFailureTime = time.Now()

        if cb.state == CircuitHalfOpen || cb.failures >= cb.threshold {
            cb.state = CircuitOpen
            cb.failures = 0
        }
    } else {
        if cb.state == CircuitHalfOpen {
            cb.successes++
            if cb.successes >= cb.halfOpenMax {
                cb.state = CircuitClosed
                cb.failures = 0
            }
        } else {
            cb.failures = 0
        }
    }
}
```

## Timeout Patterns

### Operation Timeout

```go
func WithTimeout(timeout time.Duration, fn func(context.Context) error) error {
    ctx, cancel := context.WithTimeout(context.Background(), timeout)
    defer cancel()

    errCh := make(chan error, 1)
    go func() {
        errCh <- fn(ctx)
    }()

    select {
    case err := <-errCh:
        return err
    case <-ctx.Done():
        return fmt.Errorf("operation timed out after %v", timeout)
    }
}
```

### Per-Job Timeout

```go
type TimeoutJob struct {
    Job     BareJob
    Timeout time.Duration
}

func (t *TimeoutJob) Run(ctx context.Context) error {
    timeoutCtx, cancel := context.WithTimeout(ctx, t.Timeout)
    defer cancel()

    errCh := make(chan error, 1)
    go func() {
        errCh <- t.Job.Run(timeoutCtx)
    }()

    select {
    case err := <-errCh:
        return err
    case <-timeoutCtx.Done():
        if timeoutCtx.Err() == context.DeadlineExceeded {
            return fmt.Errorf("job %s timed out after %v", t.Job.GetName(), t.Timeout)
        }
        return timeoutCtx.Err()
    }
}
```

## Rate Limiting

```go
type RateLimiter struct {
    limiter *rate.Limiter
}

func NewRateLimiter(rps float64, burst int) *RateLimiter {
    return &RateLimiter{
        limiter: rate.NewLimiter(rate.Limit(rps), burst),
    }
}

func (rl *RateLimiter) Wait(ctx context.Context) error {
    return rl.limiter.Wait(ctx)
}

func (rl *RateLimiter) Allow() bool {
    return rl.limiter.Allow()
}

// Usage with job execution
func (s *Scheduler) executeWithRateLimit(ctx context.Context, job Job) error {
    if err := s.rateLimiter.Wait(ctx); err != nil {
        return err
    }
    return job.Run(ctx)
}
```

## Health Checks

```go
type HealthChecker struct {
    checks map[string]func(context.Context) error
    mu     sync.RWMutex
}

func NewHealthChecker() *HealthChecker {
    return &HealthChecker{
        checks: make(map[string]func(context.Context) error),
    }
}

func (hc *HealthChecker) Register(name string, check func(context.Context) error) {
    hc.mu.Lock()
    defer hc.mu.Unlock()
    hc.checks[name] = check
}

type HealthStatus struct {
    Status  string            `json:"status"`
    Checks  map[string]string `json:"checks"`
    Healthy bool              `json:"healthy"`
}

func (hc *HealthChecker) Check(ctx context.Context) HealthStatus {
    hc.mu.RLock()
    defer hc.mu.RUnlock()

    status := HealthStatus{
        Status:  "healthy",
        Checks:  make(map[string]string),
        Healthy: true,
    }

    for name, check := range hc.checks {
        if err := check(ctx); err != nil {
            status.Checks[name] = fmt.Sprintf("unhealthy: %v", err)
            status.Status = "unhealthy"
            status.Healthy = false
        } else {
            status.Checks[name] = "healthy"
        }
    }

    return status
}
```
