# guides.xml Configuration Reference

Complete reference for `Documentation/guides.xml` configuration.

Based on: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/GuidesXml.html

## Overview

The `guides.xml` file configures documentation rendering, project metadata, GitHub integration, and cross-references. It replaces the legacy `Settings.cfg`.

## Extracting Information for guides.xml

When creating or updating `guides.xml`, extract information from these sources:

### From composer.json

```json
{
  "name": "vendor/package-name",
  "description": "Package description",
  "license": "GPL-2.0-or-later",
  "authors": [
    {"name": "Company Name", "email": "info@example.com"}
  ],
  "support": {
    "issues": "https://github.com/vendor/repo/issues",
    "source": "https://github.com/vendor/repo"
  }
}
```

Extract:
- `name` → `interlink-shortcode` (e.g., `vendor/package-name`)
- `description` → Consider for `<project title="">`
- `authors[0].name` → `copyright`
- `support.issues` → `project-issues`
- `support.source` → `project-repository`

### From GitHub Repository

Use `gh` CLI to extract repository information:

```bash
# Get repository details
gh repo view --json name,owner,description,url

# Get default branch
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'

# Get homepage if set
gh repo view --json homepageUrl --jq '.homepageUrl'
```

Extract:
- `owner.login` + `name` → `edit-on-github` (format: `owner/repo`)
- `defaultBranchRef.name` → `edit-on-github-branch`
- `url` → `project-repository`
- `homepageUrl` → `project-home` (if set)

### From Git Remote

```bash
# Extract owner/repo from git remote
git remote get-url origin | sed -E 's/.*[:/]([^/]+)\/([^/.]+)(\.git)?$/\1\/\2/'
```

## Complete guides.xml Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<guides
    xmlns="https://www.phpdoc.org/guides"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="https://www.phpdoc.org/guides vendor/phpdocumentor/guides-cli/resources/schema/guides.xsd"
    theme="typo3docs"
    default-code-language="php"
    links-are-relative="true"
>
    <project
        title="Extension Name"
        version="1.0"
        release="1.0.0"
        copyright="since 2024 by Vendor Name"
    />

    <extension
        class="\T3Docs\Typo3DocsTheme\DependencyInjection\Typo3DocsThemeExtension"
        typo3-core-preferred="stable"
        interlink-shortcode="vendor/extension-name"
        project-home="https://extensions.typo3.org/extension/extension_key"
        project-contact="mailto:info@vendor.com"
        project-repository="https://github.com/vendor/extension"
        project-issues="https://github.com/vendor/extension/issues"
        project-discussions="https://github.com/vendor/extension/discussions"
        edit-on-github="vendor/extension"
        edit-on-github-branch="main"
        edit-on-github-directory="Documentation"
    />
    <!-- Note: Only include project-discussions if GitHub Discussions is enabled -->

    <!-- Intersphinx inventories for cross-references -->
    <inventory id="t3coreapi" url="https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/"/>
    <inventory id="t3tca" url="https://docs.typo3.org/m/typo3/reference-tca/main/en-us/"/>
    <inventory id="t3tsconfig" url="https://docs.typo3.org/m/typo3/reference-tsconfig/main/en-us/"/>
    <inventory id="t3tsref" url="https://docs.typo3.org/m/typo3/reference-typoscript/main/en-us/"/>
</guides>
```

## Element Reference

### Root Element: `<guides>`

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `theme` | string | - | **Must be `typo3docs`** for TYPO3 documentation |
| `default-code-language` | string | `php` | Default language for code blocks without explicit language |
| `links-are-relative` | boolean | `false` | Use relative links in output |
| `max-menu-depth` | integer | unlimited | Limit main menu nesting depth |
| `automatic-menu` | boolean | `false` | Auto-generate alphabetical menu (for Markdown docs) |

**Critical:** `theme` must be an **attribute**, not a child element.

### `<project>` Element

Project metadata displayed in rendered documentation.

| Attribute | Required | Description |
|-----------|----------|-------------|
| `title` | Yes | Extension/project name, displayed in sidebar and page title |
| `version` | No | Version number (auto-set during CI/CD, local only) |
| `release` | No | Release number, available via `\|release\|` substitution |
| `copyright` | Yes | Copyright statement for footer (e.g., "since 2024 by Company") |

**Extract from:**
- `title`: Extension name or `composer.json` description
- `copyright`: `composer.json` authors or company name

### `<extension>` Element

TYPO3-specific theme configuration. The `class` attribute loads the TYPO3 documentation theme which provides the official styling, "Edit on GitHub" buttons, version switcher, and intersphinx support.

| Attribute | Required | Description |
|-----------|----------|-------------|
| `class` | Yes | Always: `\T3Docs\Typo3DocsTheme\DependencyInjection\Typo3DocsThemeExtension` |

**Why `class` is required:** Without the theme extension class, documentation renders with default phpDocumentor styling instead of TYPO3's official theme. The class enables all TYPO3-specific features like the version switcher, intersphinx cross-references, and branded styling.

#### GitHub Integration Attributes

| Attribute | Default | Description |
|-----------|---------|-------------|
| `edit-on-github` | `""` | Format: `Organization/Repository` (enables "Edit on GitHub" button) |
| `edit-on-github-branch` | `main` | Branch for edit links |
| `edit-on-github-directory` | `Documentation` | Path to Documentation/ within repo |

**Extract from:** Git remote URL or `gh repo view`

#### Project Links Attributes

| Attribute | Description | Example |
|-----------|-------------|---------|
| `project-home` | Extension homepage | TER page or custom website |
| `project-contact` | Contact for questions | `mailto:info@example.com` or Slack channel |
| `project-repository` | Source code URL | `https://github.com/vendor/repo` |
| `project-issues` | Issue tracker URL | `https://github.com/vendor/repo/issues` |
| `project-discussions` | Discussions forum (optional) | GitHub Discussions URL |
| `report-issue` | Override issue link | `none`, internal path, or URL |

**Extract from:** `composer.json` support section or GitHub repository

**project-discussions:** Add this attribute only if GitHub Discussions is enabled on the repository. Check with:
```bash
gh repo view --json hasDiscussionsEnabled --jq '.hasDiscussionsEnabled'
# If true, add:
gh repo view --json url --jq '"\(.url)/discussions"'
```

**report-issue:** Controls the "Report Issue" button behavior:
- **Omit attribute**: Uses `project-issues` URL (default behavior)
- **`none`**: Hides the "Report Issue" button entirely (use for internal/private docs)
- **URL**: Custom URL for issue reporting (e.g., different tracker, form)
- **Internal path**: Link to a documentation page (e.g., `/Contribute/ReportIssue`)

#### Interlink Configuration

| Attribute | Description |
|-----------|-------------|
| `interlink-shortcode` | Identifier for "Reference this headline" dialog |
| `typo3-core-preferred` | Target TYPO3 version for cross-manual links |

**interlink-shortcode values:**
- Third-party extensions: Use Composer name (e.g., `georgringer/news`)
- System extensions: Use Composer name (e.g., `typo3/cms-adminpanel`)

**typo3-core-preferred values:**
- `main` - Development version
- `stable` - Latest LTS (default)
- `oldstable` - Previous LTS
- Explicit version: `12.4`, `11.5`, `8.7`

### `<inventory>` Elements

Define Intersphinx inventories for cross-references to other TYPO3 documentation.

```xml
<inventory id="identifier" url="https://docs.typo3.org/path/to/docs/"/>
```

| Attribute | Description |
|-----------|-------------|
| `id` | Identifier used in `:ref:` cross-references |
| `url` | Absolute URL to the documentation (must end with `/`) |

#### When to Add Inventories

Add an `<inventory>` element **only when your documentation uses cross-references to that manual**. Do not add unused inventories.

**Detection:** Search your RST files for `:ref:` patterns with prefixes:
```bash
grep -rE ':ref:`t3[a-z]+:' Documentation/
```

If you use `:ref:`t3coreapi:dependency-injection``, add the `t3coreapi` inventory.

#### Common Inventories

```xml
<!-- Core references -->
<inventory id="t3coreapi" url="https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/"/>
<inventory id="t3tca" url="https://docs.typo3.org/m/typo3/reference-tca/main/en-us/"/>
<inventory id="t3tsconfig" url="https://docs.typo3.org/m/typo3/reference-tsconfig/main/en-us/"/>
<inventory id="t3tsref" url="https://docs.typo3.org/m/typo3/reference-typoscript/main/en-us/"/>

<!-- Guides -->
<inventory id="t3start" url="https://docs.typo3.org/m/typo3/tutorial-getting-started/main/en-us/"/>
<inventory id="t3editors" url="https://docs.typo3.org/m/typo3/tutorial-editors/main/en-us/"/>

<!-- ViewHelper reference -->
<inventory id="t3viewhelper" url="https://docs.typo3.org/other/typo3/view-helper-reference/main/en-us/"/>

<!-- Extbase/Fluid -->
<inventory id="t3extbasebook" url="https://docs.typo3.org/m/typo3/book-extbasefluid/main/en-us/"/>
```

**Usage in RST:**
```rst
See :ref:`t3coreapi:dependency-injection` for details.
See :ref:`t3tca:columns-types` for TCA column types.
```

## Automated guides.xml Generation

When creating `guides.xml` for an extension, follow this workflow:

### Step 1: Extract from composer.json

```bash
# Read composer.json
cat composer.json | jq -r '.name' # → interlink-shortcode
cat composer.json | jq -r '.authors[0].name' # → copyright
cat composer.json | jq -r '.support.issues' # → project-issues
cat composer.json | jq -r '.support.source' # → project-repository
```

### Step 2: Extract from GitHub

```bash
# Get owner/repo for edit-on-github
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'

# Get default branch
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'

# Get issues URL
gh repo view --json url --jq '"\(.url)/issues"'

# Check if Discussions enabled (add project-discussions only if true)
gh repo view --json hasDiscussionsEnabled --jq '.hasDiscussionsEnabled'
# If true:
gh repo view --json url --jq '"\(.url)/discussions"'
```

### Step 3: Determine Extension Key

The extension key (for TER link) is typically:
- Composer name without vendor: `vendor/my-extension` → `my_extension`
- Or explicitly defined in `composer.json` extras

### Step 4: Generate guides.xml

Combine extracted values into the complete template above.

## Validation Checklist

Before committing `guides.xml`:

1. ✅ `theme="typo3docs"` is an attribute on `<guides>`, not a child element
2. ✅ `<extension class="...">` includes the required theme extension class
3. ✅ `<project title="">` is set with meaningful extension name
4. ✅ `<project copyright="">` includes year and author/company
5. ✅ `edit-on-github` matches GitHub `owner/repo` exactly
6. ✅ `edit-on-github-branch` matches your default branch
7. ✅ `project-repository` and `project-issues` are valid URLs
8. ✅ `project-discussions` added only if GitHub Discussions is enabled
9. ✅ `interlink-shortcode` uses Composer package name format
10. ✅ `typo3-core-preferred` set appropriately (stable, main, or specific version)
11. ✅ `<inventory>` elements added only for cross-references actually used
12. ✅ All inventory URLs end with `/`

## Common Mistakes

### Theme as Element

```xml
<!-- ❌ WRONG: theme as child element -->
<guides>
    <theme name="typo3docs"/>
</guides>

<!-- ✅ CORRECT: theme as attribute -->
<guides theme="typo3docs">
</guides>
```

### Missing Extension Class

```xml
<!-- ❌ WRONG: missing class attribute -->
<extension
    edit-on-github="vendor/repo"
/>

<!-- ✅ CORRECT: class is required -->
<extension
    class="\T3Docs\Typo3DocsTheme\DependencyInjection\Typo3DocsThemeExtension"
    edit-on-github="vendor/repo"
/>
```

### Wrong edit-on-github Format

```xml
<!-- ❌ WRONG: full URL -->
<extension edit-on-github="https://github.com/vendor/repo"/>

<!-- ❌ WRONG: missing owner -->
<extension edit-on-github="repo"/>

<!-- ✅ CORRECT: owner/repo format -->
<extension edit-on-github="vendor/repo"/>
```

### Inventory URL Missing Trailing Slash

```xml
<!-- ❌ WRONG: no trailing slash -->
<inventory id="t3coreapi" url="https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us"/>

<!-- ✅ CORRECT: with trailing slash -->
<inventory id="t3coreapi" url="https://docs.typo3.org/m/typo3/reference-coreapi/main/en-us/"/>
```

## Minimal Valid guides.xml

For quick setup, use this minimal valid configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<guides
    xmlns="https://www.phpdoc.org/guides"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="https://www.phpdoc.org/guides vendor/phpdocumentor/guides-cli/resources/schema/guides.xsd"
    theme="typo3docs"
>
    <project
        title="My Extension"
        copyright="since 2024 by My Company"
    />

    <extension
        class="\T3Docs\Typo3DocsTheme\DependencyInjection\Typo3DocsThemeExtension"
    />
</guides>
```

## References

- **guides.xml Reference:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/GuidesXml.html
- **Intersphinx:** https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Reference/Intersphinx.html
