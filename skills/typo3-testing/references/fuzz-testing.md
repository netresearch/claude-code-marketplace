# Fuzz Testing for TYPO3 Extensions

## Overview

Fuzz testing (fuzzing) automatically generates random/mutated inputs to find crashes, memory exhaustion, or unexpected exceptions. This is critical for code that parses untrusted input like HTML, XML, or user data.

> **Key Distinction**: Fuzz testing mutates **inputs** to find bugs. For testing that mutates **code** to verify test quality, see [Mutation Testing](mutation-testing.md).

## When to Use Fuzz Testing

- HTML/XML parsers (e.g., DOMDocument-based code)
- User input processors
- Data transformation services
- File format parsers
- Any code handling untrusted external data

## Tools

### nikic/php-fuzzer (Recommended)

Coverage-guided fuzzer for PHP library/parser testing.

**Installation:**
```bash
composer require --dev nikic/php-fuzzer:^0.0.11
```

**Key features:**
- Coverage-guided mutation (finds new code paths)
- Corpus management (saves interesting inputs)
- Crash detection and reproduction
- Memory limit enforcement

## Creating Fuzz Targets

### Basic Structure

Create fuzz targets in `Tests/Fuzz/` directory:

```php
<?php

declare(strict_types=1);

use MyVendor\MyExtension\Service\MyParser;

require_once dirname(__DIR__, 2) . '/.Build/vendor/autoload.php';

/** @var PhpFuzzer\Config $config */
$parser = new MyParser();

$config->setTarget(function (string $input) use ($parser): void {
    // Call the method being fuzzed
    $parser->parse($input);
});

// Limit input length to prevent memory exhaustion
$config->setMaxLen(65536);
```

### TYPO3 Extension Example

For a TYPO3 extension with HTML parsing (like an RTE image handler):

```php
<?php

declare(strict_types=1);

/**
 * Fuzzing target for ImageAttributeParser.
 *
 * Tests parseImageAttributes() with random/mutated HTML inputs
 * to find crashes, memory exhaustion, or unexpected exceptions.
 */

use MyVendor\MyExtension\Service\ImageAttributeParser;

require_once dirname(__DIR__, 2) . '/.Build/vendor/autoload.php';

/** @var PhpFuzzer\Config $config */
$parser = new ImageAttributeParser();

$config->setTarget(function (string $input) use ($parser): void {
    // Test primary parsing method
    $parser->parseImageAttributes($input);

    // Test related methods with same input
    $parser->parseLinkWithImages($input);
});

$config->setMaxLen(65536);
```

### Testing Classes with Dependencies

For classes requiring TYPO3 dependencies:

```php
<?php

declare(strict_types=1);

use MyVendor\MyExtension\DataHandling\SoftReference\MySoftReferenceParser;
use TYPO3\CMS\Core\Html\HtmlParser;

require_once dirname(__DIR__, 2) . '/.Build/vendor/autoload.php';

/** @var PhpFuzzer\Config $config */

// Create dependencies
$htmlParser = new HtmlParser();
$parser = new MySoftReferenceParser($htmlParser);

// Set required properties via reflection if needed
$reflection    = new ReflectionClass($parser);
$parserKeyProp = $reflection->getProperty('parserKey');
$parserKeyProp->setValue($parser, 'my_parser_key');

$config->setTarget(function (string $input) use ($parser): void {
    $parser->parse(
        'tt_content',
        'bodytext',
        1,
        $input,
    );
});

$config->setMaxLen(65536);
```

## Seed Corpus

Create seed inputs that the fuzzer uses as starting points in `Tests/Fuzz/corpus/`:

```
Tests/Fuzz/
├── ImageAttributeParserTarget.php
├── SoftReferenceParserTarget.php
├── corpus/
│   ├── image-parser/
│   │   ├── basic-img.txt           # <img src="test.jpg" alt="Test" />
│   │   ├── fal-reference.txt       # <img data-htmlarea-file-uid="123" />
│   │   ├── nested-structure.txt    # <a href="#"><img src="x.jpg" /></a>
│   │   └── malformed.txt           # <img src="test
│   └── softref-parser/
│       ├── basic-content.txt
│       └── multiple-images.txt
└── README.md
```

### Good Seed Inputs

Include variety in seeds:
- Valid minimal inputs
- Valid complex inputs
- Edge cases (empty, very long)
- Malformed inputs
- Special characters and encoding edge cases

## Running Fuzz Tests

### Via Composer Scripts

```json
{
    "scripts": {
        "ci:fuzz:image-parser": [
            ".Build/bin/php-fuzzer fuzz Tests/Fuzz/ImageAttributeParserTarget.php Tests/Fuzz/corpus/image-parser --max-runs 10000"
        ],
        "ci:fuzz:softref-parser": [
            ".Build/bin/php-fuzzer fuzz Tests/Fuzz/SoftReferenceParserTarget.php Tests/Fuzz/corpus/softref-parser --max-runs 10000"
        ],
        "ci:fuzz": [
            "@ci:fuzz:image-parser",
            "@ci:fuzz:softref-parser"
        ]
    }
}
```

### Via runTests.sh

```bash
# Add to Build/Scripts/runTests.sh
fuzz)
    FUZZ_TARGET="${1:-Tests/Fuzz/ImageAttributeParserTarget.php}"
    FUZZ_CORPUS="Tests/Fuzz/corpus/image-parser"
    FUZZ_MAX_RUNS="${2:-10000}"

    if [[ "${FUZZ_TARGET}" == *"SoftReference"* ]]; then
        FUZZ_CORPUS="Tests/Fuzz/corpus/softref-parser"
    fi

    COMMAND=(.Build/bin/php-fuzzer fuzz "${FUZZ_TARGET}" "${FUZZ_CORPUS}" --max-runs "${FUZZ_MAX_RUNS}")
    ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name fuzz-${SUFFIX} ${IMAGE_PHP} "${COMMAND[@]}"
    SUITE_EXIT_CODE=$?
    ;;
```

Usage:
```bash
# Default target
Build/Scripts/runTests.sh -s fuzz

# Specific target
Build/Scripts/runTests.sh -s fuzz Tests/Fuzz/ImageAttributeParserTarget.php

# Custom max-runs
Build/Scripts/runTests.sh -s fuzz Tests/Fuzz/ImageAttributeParserTarget.php 50000
```

### Directly

```bash
# Run fuzzer with corpus directory (positional argument, not --corpus option!)
.Build/bin/php-fuzzer fuzz Tests/Fuzz/ImageAttributeParserTarget.php \
    Tests/Fuzz/corpus/image-parser \
    --max-runs 10000
```

## Interpreting Results

### Normal Output

```
Running fuzz test...
  NEW: 0xabc123 - Found new coverage path
  REDUCE: 0xdef456 - Simplified input while maintaining coverage
  ...
Fuzzing complete. 10000 runs, 0 crashes.
```

### Crash Found

```
CRASH: Tests/Fuzz/crashes/crash-abc123.txt
  Error: Call to undefined method...

To reproduce:
  php Tests/Fuzz/ImageAttributeParserTarget.php < Tests/Fuzz/crashes/crash-abc123.txt
```

### What to Look For

| Result | Meaning | Action |
|--------|---------|--------|
| NEW | Found input triggering new code path | Good - corpus expanding |
| REDUCE | Simplified input while keeping coverage | Good - efficient corpus |
| CRASH | Input caused exception/error | **Fix the bug** |
| TIMEOUT | Input caused infinite loop/hang | **Fix the performance issue** |
| OOM | Input caused memory exhaustion | **Fix memory handling** |

## CI Integration

Fuzz testing is typically **not run in CI** due to time requirements. Instead:

1. Run locally before releases
2. Run on schedule (weekly) for security-critical code
3. Run in dedicated security testing pipelines

### Optional CI Integration (Short Runs)

```yaml
# .github/workflows/fuzz.yml
name: Fuzz Testing

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  workflow_dispatch:      # Manual trigger

jobs:
  fuzz:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
      - run: composer install
      - name: Fuzz ImageAttributeParser
        run: composer ci:fuzz:image-parser
        continue-on-error: true
      - name: Upload crash artifacts
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: fuzz-crashes
          path: Tests/Fuzz/crashes/
```

## Best Practices

1. **Target security-critical code** - Prioritize parsers handling untrusted input
2. **Use meaningful seeds** - Good starting corpus improves coverage
3. **Set memory limits** - Prevent runaway memory usage with `setMaxLen()`
4. **Fix crashes immediately** - Fuzzer-found bugs are often exploitable
5. **Don't ignore OOM** - Memory exhaustion can be a DoS vector
6. **Document findings** - Track what was fuzzed and any issues found

## Directory Structure

```
Tests/
├── Unit/
├── Functional/
├── E2E/
└── Fuzz/
    ├── README.md
    ├── ImageAttributeParserTarget.php
    ├── SoftReferenceParserTarget.php
    ├── corpus/
    │   ├── image-parser/
    │   │   ├── seed1.txt
    │   │   └── seed2.txt
    │   └── softref-parser/
    │       └── seed1.txt
    └── crashes/          # Auto-generated when crashes found
        └── crash-xxx.txt
```

## Resources

- [nikic/php-fuzzer](https://github.com/nikic/PHP-Fuzzer) - PHP coverage-guided fuzzer
- [Google OSS-Fuzz](https://google.github.io/oss-fuzz/) - Continuous fuzzing infrastructure
- [OWASP Fuzzing](https://owasp.org/www-community/Fuzzing) - Security fuzzing concepts
