# Reproducible Builds Implementation Guide

Reproducible builds ensure that anyone can verify that binaries were built from the claimed source code.

## What is a Reproducible Build?

A build is reproducible when:
- Building the same source code produces bit-for-bit identical outputs
- Any third party can verify builds match
- Build environment is fully documented

## OpenSSF Badge Requirements

| Level | Criterion | Requirement |
|-------|-----------|-------------|
| Silver | `build_repeatable` | Build is repeatable/deterministic |
| Gold | `build_reproducible` | Build is fully reproducible |

## Implementation by Language

### Go

Go is particularly well-suited for reproducible builds:

```bash
# Reproducible Go build
CGO_ENABLED=0 go build \
  -trimpath \
  -ldflags='-s -w -buildid=' \
  -o binary .
```

**Flags explained:**
- `CGO_ENABLED=0` - No C dependencies (pure Go)
- `-trimpath` - Remove file paths from binary
- `-ldflags='-s -w -buildid='` - Strip debug info and build ID

**goreleaser config for reproducibility:**

```yaml
# .goreleaser.yml
builds:
  - env:
      - CGO_ENABLED=0
    flags:
      - -trimpath
    ldflags:
      - -s -w -buildid=
    mod_timestamp: '{{ .CommitTimestamp }}'
```

### Rust

```bash
# Reproducible Rust build
RUSTFLAGS="-C debuginfo=0 --remap-path-prefix=$(pwd)=." \
cargo build --release
```

### Python

Use `pip-tools` for reproducible dependencies:

```bash
pip-compile requirements.in --generate-hashes
pip install -r requirements.txt
```

### Node.js

```bash
# Use exact versions and lock file
npm ci  # Not npm install
```

### Docker

```dockerfile
# Reproducible Dockerfile
FROM golang:1.23.0-alpine@sha256:abc123...

# Pin all packages
RUN apk add --no-cache \
    git=2.45.0-r0 \
    make=4.4.1-r0
```

## Verification Process

### 1. Document Build Environment

Create `BUILD.md`:

```markdown
# Build Environment

## Requirements
- Go 1.23.0+
- Linux x86_64 or macOS arm64
- Make 4.4+

## Build Commands
\`\`\`bash
make build
\`\`\`

## Expected Checksums
See `checksums.txt` in releases.
```

### 2. Verify Reproducibility

```bash
#!/bin/bash
# verify-reproducible.sh

# Build twice
make clean && make build
mv binary binary1
make clean && make build
mv binary binary2

# Compare checksums
sha256sum binary1 binary2

if diff <(sha256sum binary1) <(sha256sum binary2 | sed 's/binary2/binary1/'); then
    echo "✓ Build is reproducible"
else
    echo "✗ Build is NOT reproducible"
    exit 1
fi
```

### 3. Cross-Machine Verification

```bash
# Build in Docker for consistent environment
docker run --rm -v $(pwd):/src -w /src golang:1.23.0-alpine \
  go build -trimpath -ldflags='-s -w -buildid=' -o binary .

sha256sum binary
```

## Common Non-Reproducibility Sources

| Source | Fix |
|--------|-----|
| Timestamps | Use `SOURCE_DATE_EPOCH` |
| File paths | Use `-trimpath` |
| Build IDs | Use `-buildid=` |
| Random data | Seed deterministically |
| Parallel builds | Use consistent ordering |
| Floating dependencies | Pin all versions |

## Setting SOURCE_DATE_EPOCH

```bash
# Use commit timestamp
export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)

# Or fixed date
export SOURCE_DATE_EPOCH=0
```

## GitHub Actions Example

```yaml
- name: Reproducible build
  env:
    SOURCE_DATE_EPOCH: ${{ github.event.repository.pushed_at }}
  run: |
    CGO_ENABLED=0 go build \
      -trimpath \
      -ldflags='-s -w -buildid=' \
      -o binary .

    # Document checksum
    sha256sum binary >> checksums.txt
```

## SLSA and Reproducibility

SLSA Level 3 doesn't require reproducibility but helps verify builds:

```yaml
# Verify SLSA provenance matches source
slsa-verifier verify-artifact \
  --provenance-path binary.intoto.jsonl \
  --source-uri github.com/owner/repo \
  binary
```

## Verification Checklist

- [ ] All builds produce identical checksums
- [ ] Build environment is documented
- [ ] Dependencies are pinned (lockfiles)
- [ ] No timestamps embedded in binaries
- [ ] File paths are stripped
- [ ] Build process is automated in CI
- [ ] Checksums are published with releases

## Tools

- **diffoscope** - Detailed diff of binaries
- **reprotest** - Test reproducibility
- **buildinfo** - Document build environment

```bash
# Compare two builds in detail
diffoscope binary1 binary2

# Test reproducibility
reprotest 'go build -o binary .' binary
```

## References

- [Reproducible Builds](https://reproducible-builds.org/)
- [Go Reproducible Builds](https://go.dev/blog/rebuild)
- [SLSA Provenance](https://slsa.dev/provenance)
