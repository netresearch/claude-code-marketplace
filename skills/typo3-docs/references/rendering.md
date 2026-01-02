# Documentation Rendering Reference

Complete reference for rendering TYPO3 documentation locally using Docker.

Based on: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/RenderingContainer.html

## Overview

TYPO3 documentation is rendered using a Docker container that processes reStructuredText files into HTML. This enables local preview before committing changes.

## Container Image

```
ghcr.io/typo3-documentation/render-guides:latest
```

## Rendering Documentation

### Basic Render Command

Execute from the project root (where `composer.json` is located):

```bash
docker run --rm --pull always -v $(pwd):/project -it \
  ghcr.io/typo3-documentation/render-guides:latest \
  --config=Documentation
```

### Command Options Explained

| Option | Purpose |
|--------|---------|
| `--rm` | Remove container after execution |
| `--pull always` | Fetch latest container image |
| `-v $(pwd):/project` | Mount current directory as `/project` |
| `-it` | Enable interactive terminal |
| `--config=Documentation` | Specify documentation folder location |

### Output Location

Rendered documentation is generated at:

```
Documentation-GENERATED-temp/Index.html
```

Open this file in a browser to preview the documentation.

## Initializing New Documentation

When no `Documentation/` directory exists, **always use the init command** to scaffold the structure:

```bash
docker run --rm --pull always -v $(pwd):/project -it \
  ghcr.io/typo3-documentation/render-guides:latest init
```

### Prerequisites

- `composer.json` must exist in project root
- Docker must be installed and running

### Interactive Prompts

The init command asks for:

1. **Documentation format**:
   - `rst` (ReStructuredText) - **Recommended** for full TYPO3 theme features
   - `md` (Markdown) - Simpler, for single-page documentation only

2. **Site Set configuration** (if applicable):
   - Enter the Site set name and path if your extension defines one
   - Auto-generates configuration documentation
   - Skip if extension has no Site sets

### Generated Files

The command creates:
- `Documentation/guides.xml` - Configuration file (enhance with GitHub integration)
- `Documentation/Index.rst` - Entry point with basic structure
- Example documentation pages

### Post-Init Workflow

After running init:

1. **Enhance `guides.xml`** with GitHub integration, project links, inventories
2. **Expand `Index.rst`** with proper toctree and extension overview
3. **Create section directories** (`Configuration/`, `Usage/`, `Developer/`) with `Index.rst` files
4. **Add content** based on extension features
5. **Render and verify** the documentation

### Reference

- **Writing Documentation for Extensions:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Howto/WritingDocForExtension/Index.html

## Convenience Scripts

To simplify rendering, create wrapper scripts in your project:

### scripts/render_docs.sh

```bash
#!/bin/bash
# Render documentation locally using Docker
set -e

cd "$(dirname "$0")/.."

echo "Rendering documentation..."
docker run --rm --pull always -v "$(pwd)":/project -it \
  ghcr.io/typo3-documentation/render-guides:latest \
  --config=Documentation

echo ""
echo "Documentation rendered successfully!"
echo "Open: Documentation-GENERATED-temp/Index.html"
```

### scripts/validate_docs.sh

```bash
#!/bin/bash
# Validate documentation RST syntax
set -e

cd "$(dirname "$0")/.."

echo "Validating documentation..."
docker run --rm --pull always -v "$(pwd)":/project -it \
  ghcr.io/typo3-documentation/render-guides:latest \
  --config=Documentation \
  --no-progress \
  --fail-on-log

echo "Documentation validation passed!"
```

Make scripts executable:
```bash
chmod +x scripts/render_docs.sh scripts/validate_docs.sh
```

## Visual Verification

After rendering, always verify the output visually:

1. Open `Documentation-GENERATED-temp/Index.html` in a browser
2. Check that all pages render correctly
3. Verify code blocks have proper syntax highlighting
4. Confirm images and diagrams display
5. Test internal links work
6. Review table formatting

## Live View (Watch Mode)

For real-time preview while editing, use watch mode. The container monitors file changes and automatically re-renders, enabling WYSIWYG-style editing.

### Live View Command

```bash
docker run --rm -it --pull always \
  -v "./Documentation:/project/Documentation" \
  -v "./Documentation-GENERATED-temp:/project/Documentation-GENERATED-temp" \
  -p 1337:1337 \
  ghcr.io/typo3-documentation/render-guides:latest \
  --config="Documentation" --watch
```

Then open `http://localhost:1337/Index.html` in your browser.

### Command Differences from Basic Render

| Option | Purpose |
|--------|---------|
| `-p 1337:1337` | Expose built-in web server on port 1337 |
| `--watch` | Enable file watching and auto-rebuild |
| Separate volume mounts | Required for watch mode to detect changes |

### Custom Port

If port 1337 is in use, change the host port:

```bash
-p 8080:1337  # Access via http://localhost:8080/
```

### Convenience Script: scripts/watch_docs.sh

```bash
#!/bin/bash
# Live-render documentation with auto-reload
set -e

cd "$(dirname "$0")/.."

echo "Starting documentation live server..."
echo "Open: http://localhost:1337/Index.html"
echo "Press Ctrl+C to stop"
echo ""

docker run --rm -it --pull always \
  -v "./Documentation:/project/Documentation" \
  -v "./Documentation-GENERATED-temp:/project/Documentation-GENERATED-temp" \
  -p 1337:1337 \
  ghcr.io/typo3-documentation/render-guides:latest \
  --config="Documentation" --watch
```

### Shell Alias

Add to your shell config (`.bashrc`, `.zshrc`) for quick access:

```bash
alias typo3-docs-watch="docker run --rm -it --pull always \
  -v './Documentation:/project/Documentation' \
  -v './Documentation-GENERATED-temp:/project/Documentation-GENERATED-temp' \
  -p 1337:1337 ghcr.io/typo3-documentation/render-guides:latest --watch"
```

### DDEV Integration

For DDEV projects, use the official addon:

```bash
ddev get github.com/TYPO3-Documentation/ddev-renderer-guides
ddev restart
```

Access via `http://<yourproject>.ddev.site:1337/`

### Watch Mode Limitations

Auto-rebuild does **not** trigger for:

| Change Type | Action Required |
|-------------|-----------------|
| `guides.xml` changes | Restart watch container |
| Newly added files | Restart watch container |
| Menu structure changes | Restart watch container |
| File relocations | Restart watch container |

For these changes, stop the container (Ctrl+C) and restart it.

## Troubleshooting

### Container Not Starting

Ensure Docker Desktop is running:
```bash
docker info
```

### Permission Issues

On Linux, you may need to run with your user ID:
```bash
docker run --rm --pull always -v $(pwd):/project -u $(id -u):$(id -g) -it \
  ghcr.io/typo3-documentation/render-guides:latest \
  --config=Documentation
```

### Warnings During Rendering

Common warnings and fixes:

| Warning | Fix |
|---------|-----|
| `Unknown directive` | Check directive spelling and available directives |
| `Duplicate label` | Ensure unique `.. _label:` across all RST files |
| `Reference not found` | Verify `:ref:` targets exist |
| `Image not found` | Check image path is relative to RST file |

### Clearing Cache

If rendering produces unexpected results, clear the generated directory:
```bash
rm -rf Documentation-GENERATED-temp/
```

## CI/CD Integration

For GitHub Actions, add documentation rendering to your workflow:

```yaml
name: Documentation
on: [push, pull_request]

jobs:
  render:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Render documentation
        run: |
          docker run --rm -v ${{ github.workspace }}:/project \
            ghcr.io/typo3-documentation/render-guides:latest \
            --config=Documentation \
            --no-progress \
            --fail-on-log
```

## Requirements

- **Docker**: Must be installed and running
- **Project structure**: Valid `composer.json` in project root
- **Documentation**: `Documentation/` folder with RST files
- **Configuration**: `Documentation/guides.xml` (or use `init` command)

## Gitignore

Always exclude the generated directory from version control:

```gitignore
# Documentation rendering output
Documentation-GENERATED-temp/
```

## References

- **Rendering Container:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/RenderingContainer.html
- **Live View (Watch Mode):** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Howto/RenderingDocs/Watch.html
- **guides.xml Reference:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/GuidesXml.html
