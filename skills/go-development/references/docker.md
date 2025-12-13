# Docker Integration Patterns in Go

## Optimized Docker Client

### Client with Connection Pooling

```go
package core

import (
    "context"
    "sync"

    docker "github.com/fsouza/go-dockerclient"
)

type OptimizedDockerClient struct {
    client     *docker.Client
    bufferPool *sync.Pool
    mu         sync.RWMutex
    endpoint   string
}

func NewOptimizedDockerClient(endpoint string) (*OptimizedDockerClient, error) {
    if endpoint == "" {
        endpoint = "unix:///var/run/docker.sock"
    }

    client, err := docker.NewClient(endpoint)
    if err != nil {
        return nil, fmt.Errorf("failed to create Docker client: %w", err)
    }

    return &OptimizedDockerClient{
        client:   client,
        endpoint: endpoint,
        bufferPool: &sync.Pool{
            New: func() interface{} {
                return NewCircularBuffer(64 * 1024) // 64KB buffers
            },
        },
    }, nil
}

func NewOptimizedDockerClientFromEnv() (*OptimizedDockerClient, error) {
    client, err := docker.NewClientFromEnv()
    if err != nil {
        return nil, err
    }

    return &OptimizedDockerClient{
        client: client,
        bufferPool: &sync.Pool{
            New: func() interface{} {
                return NewCircularBuffer(64 * 1024)
            },
        },
    }, nil
}

func (c *OptimizedDockerClient) Close() error {
    // fsouza/go-dockerclient doesn't require explicit close
    // but we can clean up the buffer pool
    return nil
}
```

## Buffer Pooling

### Circular Buffer Implementation

```go
type CircularBuffer struct {
    data   []byte
    size   int
    head   int
    tail   int
    count  int
    mu     sync.Mutex
}

func NewCircularBuffer(size int) *CircularBuffer {
    return &CircularBuffer{
        data: make([]byte, size),
        size: size,
    }
}

func (b *CircularBuffer) Write(p []byte) (int, error) {
    b.mu.Lock()
    defer b.mu.Unlock()

    n := len(p)
    if n > b.size {
        // Only keep the last 'size' bytes
        p = p[n-b.size:]
        n = b.size
    }

    for _, byte := range p {
        b.data[b.tail] = byte
        b.tail = (b.tail + 1) % b.size
        if b.count < b.size {
            b.count++
        } else {
            b.head = (b.head + 1) % b.size
        }
    }

    return n, nil
}

func (b *CircularBuffer) String() string {
    b.mu.Lock()
    defer b.mu.Unlock()

    if b.count == 0 {
        return ""
    }

    result := make([]byte, b.count)
    if b.head < b.tail {
        copy(result, b.data[b.head:b.tail])
    } else {
        n := copy(result, b.data[b.head:])
        copy(result[n:], b.data[:b.tail])
    }

    return string(result)
}

func (b *CircularBuffer) Reset() {
    b.mu.Lock()
    defer b.mu.Unlock()
    b.head = 0
    b.tail = 0
    b.count = 0
}

func (b *CircularBuffer) Len() int {
    b.mu.Lock()
    defer b.mu.Unlock()
    return b.count
}
```

### Using Buffer Pool

```go
func (c *OptimizedDockerClient) ExecInContainer(ctx context.Context, containerID string, cmd []string) (string, string, error) {
    // Get buffers from pool
    stdoutBuf := c.bufferPool.Get().(*CircularBuffer)
    stderrBuf := c.bufferPool.Get().(*CircularBuffer)
    defer func() {
        stdoutBuf.Reset()
        stderrBuf.Reset()
        c.bufferPool.Put(stdoutBuf)
        c.bufferPool.Put(stderrBuf)
    }()

    // Create exec instance
    exec, err := c.client.CreateExec(docker.CreateExecOptions{
        Container:    containerID,
        Cmd:          cmd,
        AttachStdout: true,
        AttachStderr: true,
        Context:      ctx,
    })
    if err != nil {
        return "", "", fmt.Errorf("failed to create exec: %w", err)
    }

    // Start exec and capture output
    err = c.client.StartExec(exec.ID, docker.StartExecOptions{
        OutputStream: stdoutBuf,
        ErrorStream:  stderrBuf,
        Context:      ctx,
    })
    if err != nil {
        return "", "", fmt.Errorf("failed to start exec: %w", err)
    }

    // Check exec exit code
    inspect, err := c.client.InspectExec(exec.ID)
    if err != nil {
        return stdoutBuf.String(), stderrBuf.String(), fmt.Errorf("failed to inspect exec: %w", err)
    }

    if inspect.ExitCode != 0 {
        return stdoutBuf.String(), stderrBuf.String(),
            fmt.Errorf("command exited with code %d", inspect.ExitCode)
    }

    return stdoutBuf.String(), stderrBuf.String(), nil
}
```

## Container Operations

### Create and Run Container

```go
func (c *OptimizedDockerClient) RunContainer(ctx context.Context, image string, cmd []string, env map[string]string) (string, error) {
    // Convert env map to slice
    envSlice := make([]string, 0, len(env))
    for k, v := range env {
        envSlice = append(envSlice, fmt.Sprintf("%s=%s", k, v))
    }

    // Create container
    container, err := c.client.CreateContainer(docker.CreateContainerOptions{
        Config: &docker.Config{
            Image: image,
            Cmd:   cmd,
            Env:   envSlice,
        },
        HostConfig: &docker.HostConfig{
            AutoRemove: true,
        },
        Context: ctx,
    })
    if err != nil {
        return "", fmt.Errorf("failed to create container: %w", err)
    }

    // Start container
    if err := c.client.StartContainer(container.ID, nil); err != nil {
        // Cleanup on error
        c.client.RemoveContainer(docker.RemoveContainerOptions{
            ID:    container.ID,
            Force: true,
        })
        return "", fmt.Errorf("failed to start container: %w", err)
    }

    return container.ID, nil
}

func (c *OptimizedDockerClient) WaitContainer(ctx context.Context, containerID string) (int, error) {
    exitCode, err := c.client.WaitContainer(containerID)
    if err != nil {
        return -1, fmt.Errorf("failed to wait for container: %w", err)
    }
    return exitCode, nil
}

func (c *OptimizedDockerClient) RemoveContainer(ctx context.Context, containerID string, force bool) error {
    return c.client.RemoveContainer(docker.RemoveContainerOptions{
        ID:            containerID,
        Force:         force,
        RemoveVolumes: true,
        Context:       ctx,
    })
}
```

### Container Monitoring

```go
type ContainerStats struct {
    CPUPercent    float64
    MemoryUsage   uint64
    MemoryLimit   uint64
    MemoryPercent float64
    NetworkRx     uint64
    NetworkTx     uint64
}

func (c *OptimizedDockerClient) GetContainerStats(ctx context.Context, containerID string) (*ContainerStats, error) {
    statsCh := make(chan *docker.Stats)
    errCh := make(chan error)

    go func() {
        err := c.client.Stats(docker.StatsOptions{
            ID:     containerID,
            Stats:  statsCh,
            Stream: false,
            Context: ctx,
        })
        errCh <- err
    }()

    select {
    case stats := <-statsCh:
        cpuDelta := float64(stats.CPUStats.CPUUsage.TotalUsage - stats.PreCPUStats.CPUUsage.TotalUsage)
        systemDelta := float64(stats.CPUStats.SystemCPUUsage - stats.PreCPUStats.SystemCPUUsage)
        cpuPercent := 0.0
        if systemDelta > 0 {
            cpuPercent = (cpuDelta / systemDelta) * float64(len(stats.CPUStats.CPUUsage.PercpuUsage)) * 100
        }

        return &ContainerStats{
            CPUPercent:    cpuPercent,
            MemoryUsage:   stats.MemoryStats.Usage,
            MemoryLimit:   stats.MemoryStats.Limit,
            MemoryPercent: float64(stats.MemoryStats.Usage) / float64(stats.MemoryStats.Limit) * 100,
            NetworkRx:     stats.Network.RxBytes,
            NetworkTx:     stats.Network.TxBytes,
        }, nil
    case err := <-errCh:
        return nil, err
    case <-ctx.Done():
        return nil, ctx.Err()
    }
}
```

## Docker Events

### Event Listener

```go
type EventHandler func(event *docker.APIEvents)

func (c *OptimizedDockerClient) ListenEvents(ctx context.Context, handler EventHandler) error {
    listener := make(chan *docker.APIEvents)

    err := c.client.AddEventListener(listener)
    if err != nil {
        return fmt.Errorf("failed to add event listener: %w", err)
    }
    defer c.client.RemoveEventListener(listener)

    for {
        select {
        case event := <-listener:
            if event == nil {
                return nil
            }
            handler(event)
        case <-ctx.Done():
            return ctx.Err()
        }
    }
}

// Usage: React to container events
func handleDockerEvent(event *docker.APIEvents) {
    switch event.Status {
    case "start":
        log.WithField("container", event.ID).Info("Container started")
    case "die":
        log.WithField("container", event.ID).Info("Container died")
    case "destroy":
        log.WithField("container", event.ID).Info("Container destroyed")
    }
}
```

## Docker Labels for Configuration

### Reading Labels

```go
type JobFromLabels struct {
    Type      string
    Name      string
    Schedule  string
    Command   []string
    Container string
}

func (c *OptimizedDockerClient) GetJobsFromLabels(ctx context.Context) ([]JobFromLabels, error) {
    containers, err := c.client.ListContainers(docker.ListContainersOptions{
        Context: ctx,
    })
    if err != nil {
        return nil, err
    }

    var jobs []JobFromLabels

    for _, container := range containers {
        // Look for labels like: ofelia.job-exec.job-name.schedule
        for key, value := range container.Labels {
            if !strings.HasPrefix(key, "ofelia.") {
                continue
            }

            parts := strings.Split(key, ".")
            if len(parts) < 4 {
                continue
            }

            jobType := parts[1]  // job-exec, job-run, etc.
            jobName := parts[2]  // user-defined name
            param := parts[3]    // schedule, command, etc.

            // Build job config from labels
            job := findOrCreateJob(jobs, jobName, jobType)
            switch param {
            case "schedule":
                job.Schedule = value
            case "command":
                job.Command = strings.Split(value, " ")
            case "container":
                job.Container = value
            }
        }
    }

    return jobs, nil
}
```

## Health Check

```go
func (c *OptimizedDockerClient) Ping(ctx context.Context) error {
    return c.client.PingWithContext(ctx)
}

func (c *OptimizedDockerClient) IsHealthy(ctx context.Context) bool {
    return c.Ping(ctx) == nil
}

// Health check for API endpoint
func DockerHealthCheck(client *OptimizedDockerClient) func(context.Context) error {
    return func(ctx context.Context) error {
        if err := client.Ping(ctx); err != nil {
            return fmt.Errorf("docker daemon unavailable: %w", err)
        }
        return nil
    }
}
```

## Image Operations

```go
func (c *OptimizedDockerClient) PullImage(ctx context.Context, image string) error {
    return c.client.PullImage(docker.PullImageOptions{
        Repository: image,
        Context:    ctx,
    }, docker.AuthConfiguration{})
}

func (c *OptimizedDockerClient) ImageExists(ctx context.Context, image string) bool {
    _, err := c.client.InspectImage(image)
    return err == nil
}

func (c *OptimizedDockerClient) EnsureImage(ctx context.Context, image string) error {
    if c.ImageExists(ctx, image) {
        return nil
    }
    return c.PullImage(ctx, image)
}
```
