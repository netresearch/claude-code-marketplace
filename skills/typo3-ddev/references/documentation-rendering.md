# Documentation Rendering

Render TYPO3 extension documentation locally using DDEV.

## The `ddev docs` Command

Create a host command that renders documentation using the official TYPO3 render-guides Docker image:

### Command File: `.ddev/commands/host/docs`

```bash
#!/bin/bash

## Description: Render extension documentation using TYPO3 render-guides
## Usage: docs
## Example: ddev docs

set -e

PROJECT_ROOT="${DDEV_APPROOT}"
DOCS_SOURCE="${PROJECT_ROOT}/Documentation"
DOCS_OUTPUT="${PROJECT_ROOT}/Documentation-GENERATED-temp"

echo "Rendering documentation..."
echo "Source: ${DOCS_SOURCE}"
echo "Output: ${DOCS_OUTPUT}"

# Clean output directory (needs sudo for Docker-created files)
sudo rm -rf "${DOCS_OUTPUT}"/* 2>/dev/null || rm -rf "${DOCS_OUTPUT}"/* 2>/dev/null || true

# Render using TYPO3 render-guides Docker image with current user
# NOTE: The 'run' subcommand is required as of 2024+
docker run --rm \
    --user "$(id -u):$(id -g)" \
    -v "${PROJECT_ROOT}:/project" \
    ghcr.io/typo3-documentation/render-guides:latest \
    run \
    --no-progress \
    --output=/project/Documentation-GENERATED-temp \
    /project/Documentation

echo ""
echo "Documentation rendered successfully!"
echo "View at: https://docs.${DDEV_SITENAME}.ddev.site/"
```

## Critical: Output Directory Convention

**ALWAYS use `Documentation-GENERATED-temp/`** - This is the TYPO3 standard convention.

```
❌ WRONG: docs/
❌ WRONG: Documentation-rendered/
❌ WRONG: public/docs/
✅ CORRECT: Documentation-GENERATED-temp/
```

This directory:
- Is automatically gitignored by TYPO3 conventions
- Matches what docs.typo3.org expects
- Is recognized by TYPO3 documentation tools
- Uses capital-I `Index.html` (TYPO3 convention)

## Apache VirtualHost Configuration

Configure Apache to serve the rendered documentation:

```apache
# Documentation
# NOTE: Use ${DDEV_SITENAME} (Apache env var), not {{DDEV_SITENAME}} (template placeholder)
<VirtualHost *:80>
    ServerName docs.${DDEV_SITENAME}.ddev.site
    DocumentRoot /var/www/html/Documentation-GENERATED-temp

    # CRITICAL: TYPO3 docs use capital-I Index.html
    DirectoryIndex Index.html index.html

    <Directory /var/www/html/Documentation-GENERATED-temp>
        AllowOverride All
        Require all granted
        Options Indexes FollowSymLinks
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/docs-error.log
    CustomLog ${APACHE_LOG_DIR}/docs-access.log combined
</VirtualHost>
```

### Key Configuration Points

1. **DirectoryIndex**: TYPO3 documentation uses `Index.html` with capital I
2. **Options Indexes**: Allow directory listing as fallback
3. **ServerName**: Use `docs.` subdomain prefix

## Volume Configuration

**Do NOT use Docker volumes for documentation** - they don't sync with the host filesystem.

```yaml
# docker-compose.web.yaml
# ❌ WRONG - Docker volume doesn't show host files
volumes:
  docs-data:
    name: "${DDEV_SITENAME}-docs-data"

# ✅ CORRECT - Use project bind mount (default)
# Documentation-GENERATED-temp is already in project root,
# which is bind-mounted to /var/www/html
```

## File Permission Issues

Docker render-guides may create root-owned files. Handle with sudo fallback:

```bash
# Clean with sudo fallback
sudo rm -rf "${DOCS_OUTPUT}"/* 2>/dev/null || rm -rf "${DOCS_OUTPUT}"/* 2>/dev/null || true
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Directory listing instead of docs | Apache not finding Index.html | Add `DirectoryIndex Index.html index.html` |
| Permission denied | Root-owned Docker files | Use `sudo rm -rf` or run Docker with `--user` |
| Empty output directory | Volume not syncing | Don't use Docker volumes, use bind mounts |
| 404 errors | Wrong DocumentRoot | Point to `Documentation-GENERATED-temp` |
| Docs not updating | Cache or old files | Delete output directory completely, re-render |

## DDEV Configuration Checklist

- [ ] `docs.{sitename}` in additional_hostnames or additional_fqdns
- [ ] Apache VirtualHost for docs subdomain
- [ ] `DirectoryIndex Index.html index.html` directive
- [ ] DocumentRoot pointing to `Documentation-GENERATED-temp`
- [ ] No Docker volume for docs (use bind mount)
- [ ] `docs` command in `.ddev/commands/host/`
- [ ] `--user "$(id -u):$(id -g)"` in Docker run command

## Integration with docs.typo3.org

The `Documentation-GENERATED-temp` directory is a local preview. For publishing:

1. Push `Documentation/` source files to repository
2. Register extension on extensions.typo3.org
3. Configure docs.typo3.org webhook
4. Documentation auto-renders on push

See [TYPO3 Documentation Rendering](https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/RenderingDocs/Index.html) for official deployment.
