# Quick Start Guide Implementation

> OpenSSF Silver Badge requirement: `documentation_quick_start`
>
> Projects must provide a quick start guide that enables new users to get started within minutes.

## Quick Start Template Structure

### Essential Sections

```markdown
# Quick Start

## Prerequisites

- Tool 1 (version X.Y+)
- Tool 2 (version X.Y+)

## Installation

### Option 1: Package Manager
\`\`\`bash
# npm
npm install your-package

# pip
pip install your-package

# go
go install github.com/org/project@latest
\`\`\`

### Option 2: Binary Download
\`\`\`bash
curl -sSL https://get.example.com | sh
\`\`\`

### Option 3: From Source
\`\`\`bash
git clone https://github.com/org/project
cd project
make install
\`\`\`

## Verify Installation

\`\`\`bash
your-tool --version
# Expected: your-tool version X.Y.Z
\`\`\`

## Your First [Action]

\`\`\`bash
# Initialize
your-tool init

# Run basic command
your-tool run --example

# Check result
your-tool status
\`\`\`

## Common Use Cases

### Use Case 1: [Description]
\`\`\`bash
your-tool command1 --flag value
\`\`\`

### Use Case 2: [Description]
\`\`\`bash
your-tool command2 --flag value
\`\`\`

## Configuration

Create `config.yaml`:
\`\`\`yaml
setting1: value
setting2: value
\`\`\`

## Next Steps

- [Full Documentation](docs/)
- [API Reference](docs/api.md)
- [Examples](examples/)
- [Troubleshooting](docs/troubleshooting.md)

## Getting Help

- [GitHub Issues](https://github.com/org/project/issues)
- [Discussions](https://github.com/org/project/discussions)
- [Discord/Slack](#invite-link)
```

## Quick Start Checklist

### Required Elements (Silver Badge)

- [ ] **Prerequisites listed** - Clear list of required tools/versions
- [ ] **Installation options** - Multiple installation methods
- [ ] **Verification step** - How to confirm successful installation
- [ ] **First action** - Immediate hands-on example
- [ ] **Expected output** - What users should see
- [ ] **Next steps** - Links to deeper documentation

### Quality Enhancements

- [ ] **Copy-paste commands** - All commands ready to run
- [ ] **Platform-specific** - Instructions for Linux/macOS/Windows
- [ ] **Time estimate** - "Get started in 5 minutes"
- [ ] **Video walkthrough** - Optional visual guide
- [ ] **Troubleshooting** - Common issues and solutions

## Platform-Specific Examples

### Go Project Quick Start

```markdown
## Quick Start

### Prerequisites
- Go 1.21 or later

### Install
\`\`\`bash
go install github.com/org/project@latest
\`\`\`

### Verify
\`\`\`bash
project --version
\`\`\`

### First Run
\`\`\`bash
# Initialize a new project
project init my-app

# Start the application
cd my-app && project run
\`\`\`
```

### Python Project Quick Start

```markdown
## Quick Start

### Prerequisites
- Python 3.9 or later
- pip or pipx

### Install
\`\`\`bash
pip install project-name
# or
pipx install project-name
\`\`\`

### Verify
\`\`\`bash
project --version
\`\`\`

### First Run
\`\`\`python
from project import Client

client = Client()
result = client.do_something()
print(result)
\`\`\`
```

### Container Project Quick Start

```markdown
## Quick Start

### Prerequisites
- Docker 20.10 or later

### Run
\`\`\`bash
docker run -d --name project \
  -p 8080:8080 \
  -v ./config:/config \
  ghcr.io/org/project:latest
\`\`\`

### Verify
\`\`\`bash
curl http://localhost:8080/health
# Expected: {"status": "healthy"}
\`\`\`
```

## Verification Commands

Add these to CI to ensure quick start stays accurate:

```yaml
# .github/workflows/verify-quickstart.yml
name: Verify Quick Start
on:
  push:
    paths:
      - 'docs/quick-start.md'
      - 'README.md'
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Extract and run commands
        run: |
          # Extract code blocks and run them
          grep -A 10 '```bash' README.md | grep -v '```' | bash -x
```

## Badge Criteria Alignment

| Criterion | Requirement | Implementation |
|-----------|-------------|----------------|
| documentation_quick_start | Quick start guide exists | Create QUICKSTART.md or README section |
| documentation_basics | Basic info for potential users | Combine with quick start |
| documentation_interface | External interface docs | Link from quick start to API docs |

## Common Mistakes to Avoid

1. **Assuming knowledge** - Don't skip prerequisite steps
2. **Outdated commands** - Test quick start in CI regularly
3. **Missing verification** - Always show expected output
4. **No error handling** - Include troubleshooting for common issues
5. **Platform assumptions** - Test on multiple OS

## Resources

- [OpenSSF Badge Quick Start Criterion](https://www.bestpractices.dev/en/criteria#1.documentation_quick_start)
- [Write the Docs - Quick Start Guide](https://www.writethedocs.org/guide/writing/beginners-guide-to-docs/)
