# Performance Testing for TYPO3 Extensions

Performance tests validate efficiency claims and detect performance regressions.

## When to Use Performance Tests

- **Benchmark Claims**: Validate documented performance (e.g., "processes 1000 items in <100ms")
- **Regression Detection**: Catch performance degradation during development
- **Memory Leak Detection**: Ensure sustained operations don't leak memory
- **Optimization Validation**: Prove optimizations achieve expected improvements

## Directory Structure

```
Tests/
├── Performance/
│   ├── ServicePerformanceTest.php
│   └── ParserBenchmarkTest.php
Build/
└── phpunit/
    └── PerformanceTests.xml
```

## PHPUnit Configuration

Create `Build/phpunit/PerformanceTests.xml`:

```xml
<?xml version="1.0"?>
<phpunit
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/11.0/phpunit.xsd"
    bootstrap="../../Tests/Unit/Bootstrap.php"
    cacheDirectory=".phpunit.cache"
    executionOrder="random"
    requireCoverageMetadata="false"
    beStrictAboutCoverageMetadata="false"
    beStrictAboutOutputDuringTests="false"
    failOnRisky="true"
    failOnWarning="true"
    colors="true"
>
    <testsuites>
        <testsuite name="Performance Tests">
            <directory>../../Tests/Performance</directory>
        </testsuite>
    </testsuites>

    <source>
        <include>
            <directory suffix=".php">../../Classes</directory>
        </include>
    </source>
</phpunit>
```

## Performance Test Pattern

```php
<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Performance;

use PHPUnit\Framework\TestCase;
use Vendor\Extension\Service\MyService;

/**
 * Performance benchmarks for MyService.
 *
 * Validates efficiency claims:
 * - Processing 1000 items < 100ms
 * - Memory usage remains constant (no leaks)
 */
final class MyServicePerformanceTest extends TestCase
{
    private MyService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new MyService();
    }

    /**
     * @test
     * Benchmark: Processing 1000 items
     * Target: < 100ms
     */
    public function processingPerformance(): void
    {
        $items = $this->generateTestItems(1000);

        $startTime = \microtime(true);
        $startMemory = \memory_get_usage();

        $results = [];
        foreach ($items as $item) {
            $results[] = $this->service->process($item);
        }

        $endTime = \microtime(true);
        $endMemory = \memory_get_usage();

        $duration = ($endTime - $startTime) * 1000; // ms
        $memoryUsed = ($endMemory - $startMemory) / 1024; // KB

        // Output benchmark results
        echo "\n";
        echo "Processing Performance:\n";
        echo "  Items:          1000\n";
        echo "  Duration:       " . \number_format($duration, 2) . " ms\n";
        echo "  Memory Used:    " . \number_format($memoryUsed, 2) . " KB\n";
        echo "  Per Item:       " . \number_format($duration / 1000, 4) . " ms\n";
        echo "\n";

        // Assert performance targets
        self::assertLessThan(100, $duration, 'Should complete in under 100ms');
        self::assertCount(1000, $results, 'Should process all items');
    }

    /**
     * @test
     * Benchmark: Memory leak detection
     * Target: < 500KB growth over 10 iterations
     */
    public function memoryLeakDetection(): void
    {
        $iterations = 10;
        $itemsPerIteration = 100;
        $memorySnapshots = [];

        for ($i = 0; $i < $iterations; $i++) {
            $items = $this->generateTestItems($itemsPerIteration);

            foreach ($items as $item) {
                $this->service->process($item);
            }

            $memorySnapshots[] = \memory_get_usage();
            \gc_collect_cycles();
        }

        $initialMemory = $memorySnapshots[0];
        $finalMemory = \end($memorySnapshots);
        $memoryGrowth = ($finalMemory - $initialMemory) / 1024;

        echo "\n";
        echo "Memory Leak Detection:\n";
        echo "  Iterations:     {$iterations}\n";
        echo "  Items/Iter:     {$itemsPerIteration}\n";
        echo "  Initial Memory: " . \number_format($initialMemory / 1024, 2) . " KB\n";
        echo "  Final Memory:   " . \number_format($finalMemory / 1024, 2) . " KB\n";
        echo "  Memory Growth:  " . \number_format($memoryGrowth, 2) . " KB\n";
        echo "\n";

        self::assertLessThan(500, $memoryGrowth, 'Memory growth should be < 500KB');
    }

    /**
     * Generate test items for benchmarks.
     *
     * @return array<int, mixed>
     */
    private function generateTestItems(int $count): array
    {
        $items = [];
        for ($i = 0; $i < $count; $i++) {
            $items[] = [
                'id' => $i,
                'data' => \str_repeat('x', 100),
            ];
        }
        return $items;
    }
}
```

## Benchmark Patterns

### Timing Measurements

```php
// High-precision timing
$startTime = \microtime(true);
// ... operation ...
$duration = (\microtime(true) - $startTime) * 1000; // milliseconds

// Assert timing
self::assertLessThan(50, $duration, 'Operation should complete in < 50ms');
```

### Memory Measurements

```php
// Memory before/after
$startMemory = \memory_get_usage();
// ... operation ...
$memoryUsed = (\memory_get_usage() - $startMemory) / 1024; // KB

// Peak memory
$peakMemory = \memory_get_peak_usage() / 1024 / 1024; // MB
```

### Throughput Measurements

```php
$operations = 1000;
$startTime = \microtime(true);

for ($i = 0; $i < $operations; $i++) {
    $service->doSomething();
}

$duration = \microtime(true) - $startTime;
$throughput = $operations / $duration; // operations/second

echo "Throughput: " . \number_format($throughput, 0) . " ops/sec\n";
```

## Running Performance Tests

### Via runTests.sh

Add a performance suite to `runTests.sh`:

```bash
'performance')
    COMMAND="php ${PHP_OPCACHE_OPTS} .Build/bin/phpunit -c Build/phpunit/PerformanceTests.xml"
    ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name ${CONTAINER_NAME} ${IMAGE_PHP} ${COMMAND}
    SUITE_EXIT_CODE=$?
    ;;
```

### Via Makefile

```makefile
performance:
	$(RUNTESTS) -s performance
```

### Direct Execution

```bash
.Build/bin/phpunit -c Build/phpunit/PerformanceTests.xml --testdox
```

## CI Integration

Performance tests are typically **not run in CI** due to variable execution times on shared runners. Instead:

1. **Run locally** before merging performance-critical changes
2. **Document baseline** in test output
3. **Set generous thresholds** (2-3x expected) if CI is required

```yaml
# Optional CI performance check (with loose thresholds)
- name: Performance Tests (Optional)
  run: Build/Scripts/runTests.sh -s performance
  continue-on-error: true
```

## Real-World Examples

### Parser Benchmark (from t3x-nr-xliff-streaming)

```php
/**
 * @test
 * Compare streaming vs DOM parsing for large files
 */
public function streamingVsDomComparison(): void
{
    $largeFile = $this->createLargeXliffFile(10000); // 10k units

    // DOM parser
    $domStart = \microtime(true);
    $domParser->parse($largeFile);
    $domTime = \microtime(true) - $domStart;
    $domMemory = \memory_get_peak_usage();

    // Reset
    \gc_collect_cycles();

    // Streaming parser
    $streamStart = \microtime(true);
    $streamParser->parse($largeFile);
    $streamTime = \microtime(true) - $streamStart;
    $streamMemory = \memory_get_peak_usage();

    echo "Comparison (10k units):\n";
    echo "  DOM:       " . \number_format($domTime * 1000, 2) . " ms, "
         . \number_format($domMemory / 1024 / 1024, 2) . " MB\n";
    echo "  Streaming: " . \number_format($streamTime * 1000, 2) . " ms, "
         . \number_format($streamMemory / 1024 / 1024, 2) . " MB\n";

    self::assertLessThan($domTime, $streamTime, 'Streaming should be faster');
    self::assertLessThan($domMemory, $streamMemory, 'Streaming should use less memory');
}
```

### Cache Efficiency Test (from t3x-nr-temporal-cache)

```php
/**
 * @test
 * Validate: Harmonization reduces cache operations by 60-80%
 */
public function cacheChurnReductionMeasurement(): void
{
    $contentElements = $this->generateRandomContent(100);

    // Count unique timestamps BEFORE
    $timestampsBefore = \count(\array_unique(
        \array_map(fn($c) => $c->getStarttime(), $contentElements)
    ));

    // Harmonize all content
    $harmonized = [];
    foreach ($contentElements as $content) {
        $result = $this->harmonizer->harmonize($content);
        $harmonized[] = $result['starttime'];
    }

    $timestampsAfter = \count(\array_unique($harmonized));
    $reduction = (($timestampsBefore - $timestampsAfter) / $timestampsBefore) * 100;

    echo "Cache Churn Reduction: " . \number_format($reduction, 1) . "%\n";

    self::assertGreaterThanOrEqual(60, $reduction, 'Should reduce by at least 60%');
}
```

## Best Practices

1. **Document targets**: State expected performance in test docblocks
2. **Output results**: Echo benchmark data for visibility
3. **Use assertions**: Don't just measure - assert expected bounds
4. **Isolate tests**: Run GC between measurements
5. **Warm up**: Consider JIT/opcache warm-up for accurate results
6. **Multiple runs**: Average over multiple iterations for stability
7. **Generous thresholds**: Allow 2-3x headroom for CI variability

## Resources

- [PHPBench](https://phpbench.readthedocs.io/) - Dedicated PHP benchmarking
- [Blackfire](https://blackfire.io/) - PHP profiling (advanced)
- [XHProf](https://github.com/longxinH/xhprof) - Hierarchical profiler
