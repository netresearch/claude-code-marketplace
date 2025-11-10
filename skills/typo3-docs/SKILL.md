---
name: typo3-docs
version: 1.1.0
description: >
  Create and maintain TYPO3 extension documentation following official TYPO3 13.x standards.

  Trigger when: creating/editing Documentation/**/*.rst files or README.md (keep in sync!), using TYPO3 directives
  (confval, versionadded, versionchanged, php:method, card-grid), rendering documentation locally (ddev docs,
  render_docs.sh), extracting documentation data (extract-all.sh, analyze-docs.sh), deploying to docs.typo3.org
  (webhook setup, publish documentation), or working with TYPO3 documentation guidelines.

  Covers: RST syntax, TYPO3-specific directives, documentation extraction/analysis, local Docker rendering,
  validation procedures, webhook setup (gh CLI + manual), and TYPO3 Intercept deployment. Ensures documentation
  meets modern TYPO3 13.x quality standards with card-grid navigation and renders correctly on docs.typo3.org.
license: Complete terms in LICENSE.txt
---

# TYPO3 Documentation

## When to Use This Skill

Invoke this skill when working with TYPO3 extension documentation:

**File Patterns:**
- Editing `Documentation/**/*.rst` files
- Creating new RST files in Documentation/ directory
- Updating `Documentation/Settings.cfg`
- Editing `README.md` (requires syncing with Documentation/)

**Keywords/Commands:**
- Creating: "create Documentation/", "generate documentation", "new docs"
- Using TYPO3 directives: `confval`, `versionadded`, `versionchanged`, `php:method`, `card-grid`
- Running: `ddev docs`, `scripts/validate_docs.sh`, `scripts/render_docs.sh`
- Extraction: `scripts/extract-all.sh`, `scripts/analyze-docs.sh`
- Deployment: "setup webhook", "deploy docs", "publish to docs.typo3.org", "docs.typo3.org"
- Mentions of: "TYPO3 documentation standards", "card-grid navigation", "confval directive"

**Tasks:**
- Creating new TYPO3 extension documentation
- Extracting documentation data from code and configs
- Analyzing documentation coverage and identifying gaps
- Adding configuration documentation with confval directives
- Documenting version-specific changes (new features, behavior changes, deprecations)
- Creating visual navigation with card-grid layouts
- Documenting PHP APIs with php:method directives
- Validating RST syntax and cross-references
- Rendering documentation locally for verification
- Troubleshooting broken cross-references or rendering warnings
- Following TYPO3 documentation best practices

## Workflow

**Before editing Documentation/*.rst files or README.md:**
1. Invoke this skill if not already active
2. Optional: Run `scripts/extract-all.sh` and `scripts/analyze-docs.sh` for gap analysis (see `references/typo3-extension-architecture.md` for extraction priorities)
3. Review the workflow decision tree below
4. Use appropriate TYPO3 directives (not plain text equivalents)
5. Validate: `scripts/validate_docs.sh` or `ddev docs`
6. Check rendered output for warnings
7. **Verify synchronization:** If editing README.md, update Documentation/ accordingly (and vice versa)
8. Commit both README.md and Documentation/ together in atomic commits

**Common Mistakes to Avoid:**
- ❌ Writing "Since v13.0.0" instead of `.. versionadded:: 13.0.0`
- ❌ Using card-grid without `stretched-link` class
- ❌ Skipping local rendering before committing
- ❌ Creating markdown files in Documentation/ (RST only)
- ❌ Missing `:type:`, `:Default:`, or `:Path:` in confval directives
- ❌ Using external links for internal documentation (use `:ref:` instead)
- ❌ **Updating README.md without updating Documentation/** (or vice versa)

## Documentation Synchronization

**Critical Rule:** README.md and Documentation/ must stay synchronized.

**When to sync:**
- Installation instructions changed → Update both README.md and Documentation/Introduction/Index.rst
- Feature descriptions changed → Update both README.md and Documentation/Index.rst
- Configuration examples changed → Update both README.md and Documentation/Integration/
- Button names or UI elements mentioned → Verify consistency across all docs

**Synchronization checklist:**
1. ✅ Installation steps match between README.md and Documentation/Introduction/
2. ✅ Feature descriptions consistent between README.md and Documentation/Index.rst
3. ✅ Code examples identical (button names, configuration, TypoScript)
4. ✅ Version numbers consistent (README.md badges match Documentation/Settings.cfg)
5. ✅ Links to external resources point to same destinations

**Example from real bug:**
```markdown
# README.md (WRONG)
toolbar: [typo3image]  # Wrong button name

# Documentation/Integration/RTE-Setup.rst (WRONG)
toolbar: [typo3image]  # Wrong button name

# Actual JavaScript code (CORRECT)
editor.ui.componentFactory.add('insertimage', ...)  # Correct button name
```

**Fix approach:**
1. Find source of truth (usually the actual code)
2. Update README.md with correct information
3. Update all Documentation/*.rst files with same information
4. Commit both in same atomic commit

## Overview

This skill enables creation and maintenance of TYPO3 extension documentation following official TYPO3 documentation standards. It covers RST syntax, TYPO3-specific directives (confval, versionadded, php:method, card-grid), documentation extraction and analysis tools, local rendering with Docker, validation procedures, and automated deployment through TYPO3 Intercept.

## Documentation Structure

### Three-Tier Documentation System

TYPO3 extensions use a three-tier documentation structure:

**1. Documentation/ (RST Format - Official Published)**
- Official TYPO3 documentation in reStructuredText format
- Published at docs.typo3.org
- Built automatically by TYPO3 Intercept
- Versioned and searchable across all TYPO3 docs
- **This is where to work when using this skill**

**2. claudedocs/ (Markdown - AI Session Context)**
- Temporary session documentation (gitignored)
- Comprehensive project knowledge for AI agents
- Never committed to version control
- **Not relevant for this skill**

**3. Root Documentation (Project Essentials)**
- README.md, CONTRIBUTING.md, SECURITY.md
- Project overview and guidelines
- **Not relevant for this skill**

### Standard Documentation/ Structure

```
Documentation/
├── Index.rst           # Main entry point (required)
├── Settings.cfg        # Documentation metadata (required)
├── Introduction/       # Getting started content
├── Integration/        # Configuration guides
├── CKEditor/          # Feature-specific docs
├── Troubleshooting/   # Problem solving
├── Security/          # Security documentation
└── API/               # PHP API reference
```

## Documentation Extraction and Analysis

### When to Use Extraction

Use extraction tools when:

- **Starting documentation for existing extension** - Extract data from code and configs
- **Auditing documentation coverage** - Identify undocumented APIs and configurations
- **Updating after code changes** - Find documentation gaps for new features
- **Ensuring consistency** - Verify docs match current code/config defaults

### Extraction Workflow

```
1. Extract → 2. Analyze → 3. Generate (optional) → 4. Complete → 5. Validate
```

**1. Extract Data from All Sources**

Run extraction to gather documentation data:

```bash
scripts/extract-all.sh                    # Core extraction only
scripts/extract-all.sh --build            # Include build configs
scripts/extract-all.sh --repo             # Include GitHub/GitLab data
scripts/extract-all.sh --all              # Extract everything
```

Extracted data saved to: `.claude/docs-extraction/data/*.json`

**Sources:**
- PHP code (Classes/**/*.php) → php_apis.json
- Extension configs (ext_emconf.php, ext_conf_template.txt) → extension_meta.json, config_options.json
- Composer dependencies → dependencies.json
- Project files (README.md, CHANGELOG.md) → project_files.json
- Build configs (optional: .github/workflows, phpunit.xml) → build_configs.json
- Repository metadata (optional: GitHub/GitLab API) → repo_metadata.json

**2. Analyze Documentation Coverage**

Compare extracted data with existing Documentation/:

```bash
scripts/analyze-docs.sh
```

Generates: `Documentation/ANALYSIS.md` with:
- **Summary**: Coverage statistics (X/Y classes documented, etc.)
- **Missing Documentation**: Undocumented classes, configs, methods
- **Outdated Documentation**: Config defaults that don't match code
- **Recommendations**: Prioritized action items

**3. Review Analysis Report**

Open and review `Documentation/ANALYSIS.md`:

- Identify Priority 1 items (missing core documentation)
- Check Priority 2 items (outdated content)
- Plan documentation updates

**4. Create Missing Documentation**

For each missing item in ANALYSIS.md:

**Classes/APIs:**
```bash
# Manually create based on php_apis.json data
# Location: Documentation/API/ClassName.rst
# Use php:class and php:method directives
```

**Configuration Options:**
```bash
# Add to existing or new configuration RST
# Location: Documentation/Integration/Configuration.rst
# Use confval directive with extracted data
```

**Extension Metadata:**
```bash
# Update Documentation/Index.rst
# Update Documentation/Settings.cfg
# Verify version numbers match ext_emconf.php
```

**5. Validate and Re-analyze**

After updates:

```bash
scripts/validate_docs.sh                  # Check RST syntax
scripts/render_docs.sh                    # Verify rendering
scripts/analyze-docs.sh                   # Re-check coverage
```

### Extraction Best Practices

**DO:**
- Run extraction before starting documentation work
- Review ANALYSIS.md for systematic gap identification
- Use extracted data as templates (copy descriptions, defaults)
- Keep extraction data in .claude/ directory (gitignored)
- Re-run analyze-docs.sh after updates to track progress

**DON'T:**
- Commit extraction data to version control
- Blindly copy extracted data without adding examples
- Skip the analysis step - it provides valuable insights
- Ignore security warnings in extracted config options
- Auto-generate docs without human review

### Example: Documenting Undocumented Config Option

**ANALYSIS.md reports:**
```markdown
### fetchExternalImages (ext_conf_template.txt)
- Type: boolean
- Default: true
- Security Warning: Enabling this setting fetches arbitrary URLs from the internet.
- Suggested Location: Integration/Configuration.rst
```

**Action:**

1. Open `Documentation/Integration/Configuration.rst`
2. Add confval directive using extracted data:

```rst
.. confval:: fetchExternalImages

   :type: boolean
   :Default: true
   :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['rte_ckeditor_image']['fetchExternalImages']

   Controls whether external image URLs are automatically fetched and uploaded
   to the current backend user's upload folder.

   .. warning::
      Enabling this setting fetches arbitrary URLs from the internet.

   Example
   -------

   Disable for security-sensitive installations:

   .. code-block:: php
      :caption: ext_localconf.php

      $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['rte_ckeditor_image']['fetchExternalImages'] = false;
```

3. Re-run `scripts/analyze-docs.sh` to verify

For complete extraction patterns and examples, see: `references/extraction-patterns.md`

## Workflow Decision Tree

**1. New Documentation?**
- Yes → Create Index.rst with card-grid navigation
- No → Go to step 2

**2. Adding Configuration?**
- Yes → Use confval directive (see "Configuration Documentation")
- No → Go to step 3

**3. Version-Specific Feature?**
- Yes → Use versionadded/versionchanged (see "Version Documentation")
- No → Go to step 4

**4. PHP API Documentation?**
- Yes → Use php:method directive (see "PHP API Documentation")
- No → Go to step 5

**5. Visual Navigation?**
- Yes → Use card-grid with stretched-link (see "Card Grid Navigation")
- No → Go to step 6

**6. Cross-References?**
- Yes → Use :ref: labels (see "Cross-References")
- No → Write standard RST content (see references/rst-syntax.md)

**7. Setup Documentation Context (First Time)**
- Add AGENTS.md to Documentation/ folder
- Run scripts/add-agents-md.sh (creates context for AI assistants)

**8. Always: Validate and Render**
- Run scripts/validate_docs.sh
- Run scripts/render_docs.sh
- Check for warnings and broken references

## Modern TYPO3 13.x Standards

### Default Patterns for New Documentation

When creating new TYPO3 extension documentation, use these MODERN defaults:

**1. Card-Grid Navigation (DEFAULT for Index.rst)**

Always use card-grid instead of plain toctree lists:

```rst
.. toctree::
   :hidden:
   :maxdepth: 2

   Introduction/Index
   Installation/Index
   Configuration/Index

.. card-grid::
   :columns: 1
   :columns-md: 2
   :gap: 4
   :card-height: 100

   .. card:: 📘 Introduction

      Learn what the extension does and key features.

      .. card-footer:: :ref:`Read more <introduction>`
         :button-style: btn btn-primary stretched-link
```

**2. confval Directives (MANDATORY for Configuration)**

Always use confval directive, never plain text:

```rst
✅ Correct:
.. confval:: settingName
   :type: boolean
   :Default: true
   :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['ext_key']['settingName']

❌ Wrong:
settingName
~~~~~~~~~~~
Type: boolean
Default: true
```

**3. guides.xml (AVOID - Usually Not Needed)**

**Do NOT create guides.xml unless specifically needed!**

- guides.xml is OPTIONAL and often causes rendering problems
- Modern TYPO3 docs use `Settings.cfg` + RST files (sufficient for 99% of cases)
- Only create guides.xml for advanced use cases (custom themes, special rendering)
- If rendering fails with guides.xml errors, delete it and try again

**4. Missing Images Handling**

When documentation references non-existent images:

**Best Practice:** Remove figure directives, add descriptive content:

```rst
❌ Wrong (causes rendering errors):
.. figure:: /Images/screenshot.png
   :alt: Screenshot description

✅ Correct:
..  note::
    Screenshots will be added in a future update.

The backend module provides:
- Feature 1: Description
- Feature 2: Description

..  todo::
    Add screenshot showing the backend module interface
```

**Alternative:** Create `.gitkeep` in `Documentation/Images/` for future additions

### Common Pitfalls and Fixes

**Pitfall 1: Plain Toctree Instead of Card-Grid**
- ❌ Creates plain bulleted list (outdated)
- ✅ Use card-grid with emoji icons (modern standard)

**Pitfall 2: Plain Text Configuration**
- ❌ Uses "Type:", "Default:" format
- ✅ Use confval directive with `:type:`, `:Default:`, `:Path:`

**Pitfall 3: Creating guides.xml By Default**
- ❌ Adds guides.xml → often causes rendering errors
- ✅ Omit guides.xml unless specifically needed

**Pitfall 4: Image References Without Images**
- ❌ Leaves broken figure directives
- ✅ Remove directives, add descriptive content + todo notes

**Pitfall 5: Missing stretched-link in Card Footer**
- ❌ Only button text is clickable
- ✅ Add `stretched-link` class for full card clickability

## Configuration Documentation

To document configuration values, use the `confval` directive:

```rst
.. confval:: settingName

   :type: boolean
   :Default: true
   :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['ext_key']['setting']

   Description of the configuration value. Explain what it does,
   when to use it, and any important considerations.
```

**Required Fields:**
- `:type:` - Data type (boolean, string, integer, array, object)
- `:Default:` - Default value (capitalize 'Default')
- `:Path:` - Full path in TYPO3 configuration

**Example:**
```rst
.. confval:: fetchExternalImages

   :type: boolean
   :Default: true
   :Path: $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['rte_ckeditor_image']['fetchExternalImages']

   Controls whether external image URLs are automatically fetched and uploaded
   to the current backend user's upload folder. When enabled, pasting image
   URLs will trigger automatic download and FAL integration.
```

For detailed confval syntax and more examples, see: `references/typo3-directives.md`

## Version Documentation

To document version-specific changes, use version directives:

**New Feature:**
```rst
.. versionadded:: 13.0.0
   The CKEditor plugin now requires ``StyleUtils`` and ``GeneralHtmlSupport``
   dependencies for style functionality.
```

**Changed Behavior:**
```rst
.. versionchanged:: 13.1.0
   Image processing now uses TYPO3's native image processing service.
```

**Deprecated Feature:**
```rst
.. deprecated:: 13.2.0
   The ``oldSetting`` configuration option is deprecated. Use ``newSetting`` instead.
   This option will be removed in version 14.0.0.
```

**Placement:** Place version directives immediately before or after the content they describe.

## PHP API Documentation

To document PHP classes and methods, use the PHP domain directives:

**Method:**
```rst
.. php:method:: infoAction(ServerRequestInterface $request): ResponseInterface

   Retrieves image information and processed file details.

   :param \\Psr\\Http\\Message\\ServerRequestInterface $request: PSR-7 server request
   :returns: JSON response with image data
   :returntype: \\Psr\\Http\\Message\\ResponseInterface
   :throws \\RuntimeException: When file is not found
```

**Return Type Annotations:**

Include return type annotations in method signatures (after closing parenthesis) to improve documentation clarity and follow Sphinx best practices:

```rst
✅ Correct:   .. php:method:: getImage(int $fileUid): File|null
❌ Incorrect: .. php:method:: getImage(int $fileUid)
```

**Return Type Format:**
- Use short class names when unambiguous: `File|null`, `ProcessedFile|null`
- Use fully qualified names when needed: `\\TYPO3\\CMS\\Core\\Resource\\File|null`
- Use union types for nullable returns: `string|null` or `?string`
- Match the style used in parameter type hints for consistency

**Class:**
```rst
.. php:class:: SelectImageController

   Main controller for image selection wizard.

   Extends: ``TYPO3\\CMS\\Backend\\Controller\\ElementBrowserController``
```

For complete PHP domain reference, see: `references/typo3-directives.md`

## Card Grid Navigation

To create visual navigation, use card-grid layouts with stretched links:

```rst
.. card-grid::
    :columns: 1
    :columns-md: 2
    :gap: 4
    :card-height: 100

    ..  card:: 📘 Introduction

        The RTE CKEditor Image extension provides comprehensive image handling
        capabilities for CKEditor in TYPO3.

        ..  card-footer:: :ref:`Read more <introduction>`
            :button-style: btn btn-primary stretched-link

    ..  card:: 🔧 Configuration

        Learn how to configure the extension with TSConfig, YAML, and TypoScript
        settings for your specific needs.

        ..  card-footer:: :ref:`Read more <configuration>`
            :button-style: btn btn-secondary stretched-link
```

**Critical Elements:**
- UTF-8 emoji icons in card titles (📘, 🔧, 🎨, 🔍, ⚡, 🛡️, etc.)
- `stretched-link` class in card-footer for full card clickability
- `:ref:` cross-references in card-footer

For complete card-grid reference, see: `references/typo3-directives.md`

## Cross-References

To create internal links, use labels and `:ref:`:

**Create Label:**
```rst
.. _my-section-label:

Section Title
=============
```

**Reference Label:**
```rst
Link to :ref:`my-section-label`
Link with custom text: :ref:`Custom Text <my-section-label>`
```

**TYPO3 Core Documentation:**
```rst
:ref:`t3tsref:start` - TypoScript Reference
:ref:`t3coreapi:fal` - File Abstraction Layer
:ref:`t3tsconfig:pagetsconfig` - Page TSConfig
```

## Validation and Rendering

### Validate Documentation

Use the validation script to check RST syntax and common issues:

```bash
scripts/validate_docs.sh /path/to/project
```

**Checks:**
- RST file existence and count
- Settings.cfg presence
- Index.rst presence
- RST syntax validation
- UTF-8 encoding
- Trailing whitespace
- Common reference issues

### Render Documentation Locally

Use the rendering script to generate HTML output:

```bash
scripts/render_docs.sh /path/to/project
```

**Output:** `Documentation-GENERATED-temp/Index.html`

**View:**
```bash
open Documentation-GENERATED-temp/Index.html
# or
xdg-open Documentation-GENERATED-temp/Index.html
```

**Always render locally before committing to verify:**
- No rendering warnings
- No broken cross-references
- Proper formatting
- Card grids display correctly
- Code blocks render properly

## Common Tasks

### Add New Page

1. Create `Documentation/Section/NewPage.rst`
2. Add to parent `Index.rst` toctree:
   ```rst
   .. toctree::
      :maxdepth: 2

      Introduction/Index
      Section/NewPage
   ```
3. Add label at top: `.. _section-newpage:`
4. Validate: `scripts/validate_docs.sh`
5. Render: `scripts/render_docs.sh`
6. Commit changes

### Update Configuration

1. Find relevant RST file in `Integration/`
2. Add or update `.. confval::` directive
3. Include `:type:`, `:Default:`, `:Path:`
4. Provide clear description
5. Validate and render

### Document Version Changes

1. Add `.. versionadded::` or `.. versionchanged::`
2. Include version number
3. Describe what changed and why
4. Place near relevant content
5. Validate and render

### Fix Cross-References

1. Find broken reference in render warnings
2. Check if target label exists
3. Update reference or create missing label
4. Re-render to verify fix

## Quality Standards

**Before Committing:**
- ✅ No rendering warnings
- ✅ No broken cross-references
- ✅ All confval directives complete
- ✅ Version information for new features
- ✅ Card grids use stretched-link
- ✅ UTF-8 emoji icons in card titles
- ✅ Code blocks specify language
- ✅ Proper heading hierarchy
- ✅ No trailing whitespace
- ✅ PHP method signatures include return types

**Documentation Coverage:**
- All public APIs documented
- All configuration options explained
- All features have usage examples
- Troubleshooting for common issues
- Security considerations documented

## TYPO3 Intercept Deployment

TYPO3 Intercept provides automatic documentation rendering and publishing. Properly configured repositories automatically build and publish documentation to docs.typo3.org.

### Prerequisites

Before enabling automatic deployment:

1. **Extension in TER**: Extension must be registered in TYPO3 Extension Repository with same key as `composer.json`
2. **Git Repository Referenced**: Repository URL must be listed on TER detail page
3. **Documentation Structure**: Must include `Index.rst`, `Settings.cfg`, and valid RST files

### Webhook Registration

**GitHub Setup:**
1. Repository Settings → Webhooks → Add webhook
2. Payload URL: `https://docs-hook.typo3.org`
3. Content type: `application/json`
4. Enable SSL verification
5. Events: "Just the push event"
6. Mark as Active

**GitLab Setup:**
1. Project Settings → Webhooks
2. URL: `https://docs-hook.typo3.org`
3. Triggers: Push events + Tag push events
4. Enable SSL verification

### Automated Webhook Setup (GitHub CLI)

**Faster alternative for GitHub repositories:**

If you have `gh` CLI installed, automate webhook creation:

```bash
# Create webhook
gh api repos/{owner}/{repo}/hooks \
  --method POST \
  --field name=web \
  --field "config[url]=https://docs-hook.typo3.org" \
  --field "config[content_type]=json" \
  --field "config[insecure_ssl]=0" \
  --raw-field "events[]=push" \
  --field active=true

# Trigger test delivery
gh api repos/{owner}/{repo}/hooks/{hook_id}/tests --method POST

# Verify delivery status
gh api repos/{owner}/{repo}/hooks/{hook_id}/deliveries \
  --jq '.[] | {id: .id, status: .status, status_code: .status_code, delivered_at: .delivered_at}'
```

**Expected response:** Status 200 or 204 indicates successful webhook delivery.

**Check webhook ID:**
```bash
gh api repos/{owner}/{repo}/hooks --jq '.[] | {id: .id, url: .config.url, events: .events}'
```

### First-Time Approval

First webhook trigger requires manual approval by TYPO3 Documentation Team:
- Automatic hold on first build
- Team verifies TER registration and repository reference
- Typical approval time: 1-3 business days
- Future builds are automatic after approval

### Verification

**Check Webhook Delivery:**
- GitHub: Settings → Webhooks → Recent Deliveries (expect `200` response)
- GitLab: Settings → Webhooks → Recent events (verify success)

**Check Build Status:**
- Dashboard: https://intercept.typo3.com/admin/docs/deployments
- Filter by extension package name
- Monitor build progress and success status

**Published Documentation:**
```
https://docs.typo3.org/p/{vendor}/{extension}/main/en-us/
https://docs.typo3.org/p/{vendor}/{extension}/{version}/en-us/
```

### Automatic Triggers

Builds triggered by:
- Git push to main/master
- Version tags (e.g., `2.1.0`)
- Branch pushes (for multi-version docs)

### Manual Rebuild

If needed:
1. Visit https://intercept.typo3.com/admin/docs/deployments
2. Find your extension
3. Click Redeploy button

### Build Process

1. Webhook received from Git host
2. Build job queued
3. Repository cloned at specific commit/tag
4. Documentation rendered using `render-guides`
5. HTML published to docs.typo3.org
6. Content indexed for search

**Typical build time:** 2-5 minutes

### Troubleshooting

**Build Failing:**
- Validate RST syntax locally: `scripts/validate_docs.sh`
- Render locally: `scripts/render_docs.sh`
- Check for broken cross-references
- Verify UTF-8 encoding

**Common Rendering Errors:**

1. **guides.xml Extension Class Path Error**
   ```
   Extension "\T3Docs\GuidesExtension\..." does not exist
   ```
   **Fix:** Delete `guides.xml` - it's usually not needed for TYPO3 extensions

2. **Missing Image Errors**
   ```
   WARNING: image file not found: Images/screenshot.png
   ```
   **Fix:** Remove figure directives, add descriptive content + todo notes (see "Missing Images Handling" above)

3. **confval Directive Missing Required Fields**
   ```
   WARNING: confval directive missing :type: field
   ```
   **Fix:** Add all required fields: `:type:`, `:Default:`, `:Path:`

4. **Broken Cross-References**
   ```
   WARNING: undefined label: my-section
   ```
   **Fix:** Verify label exists with `.. _my-section:` syntax, check spelling

5. **stretched-link Class Missing**
   ```
   Card footer buttons not making full card clickable
   ```
   **Fix:** Add `stretched-link` class to card-footer button-style

**Webhook Not Triggering:**
- Verify webhook URL: `https://docs-hook.typo3.org`
- Check SSL verification enabled
- Verify webhook marked as Active
- Check Recent Deliveries for errors (use `gh api` commands above)

**First Build On Hold:**
- Expected for new repositories
- Wait for Documentation Team approval (1-3 business days)
- Post in TYPO3 Slack #typo3-documentation to expedite

For comprehensive webhook setup, troubleshooting, and best practices, see: `references/intercept-deployment.md`

## Best Practices

**DO:**
- ✅ Use card-grid navigation for Index.rst (modern default)
- ✅ Use confval directive for ALL configuration options (mandatory)
- ✅ Include UTF-8 emoji icons in card titles (📘 📦 ⚙️ 👤 etc.)
- ✅ Add stretched-link class to card footers (full card clickability)
- ✅ Omit guides.xml unless specifically needed (avoid rendering issues)
- ✅ Use TYPO3-specific directives (confval, versionadded, php:method)
- ✅ Cross-reference using `:ref:` labels (internal links)
- ✅ Render locally before committing (catch issues early)
- ✅ Follow modern TYPO3 13.x standards

**DON'T:**
- ❌ Create plain toctree lists (use card-grid instead)
- ❌ Use plain text for configuration (must use confval directive)
- ❌ Create guides.xml by default (causes rendering errors)
- ❌ Leave broken image references (remove or add descriptive content)
- ❌ Skip stretched-link in card footers (poor UX)
- ❌ Create markdown files in Documentation/ (RST only)
- ❌ Commit claudedocs/ to version control (gitignored)
- ❌ Use external links for internal docs (use :ref:)
- ❌ Skip local rendering (blind commits = broken docs)

## Resources

This skill includes comprehensive reference materials and automation scripts:

### references/

**rst-syntax.md:**
Complete RST syntax reference including headings, code blocks, lists, links, tables, admonitions, images, and whitespace rules. Load this when working with basic RST syntax or encountering RST-specific formatting questions.

**typo3-directives.md:**
TYPO3-specific directive reference including confval, version directives, PHP domain, card-grid, intersphinx, and quality checklists. Load this when using TYPO3-specific features or creating specialized documentation elements.

### scripts/

**validate_docs.sh:**
Validates RST syntax, checks for Settings.cfg and Index.rst, detects encoding issues, identifies trailing whitespace, and provides comprehensive validation reporting. Execute this before committing documentation changes.

**render_docs.sh:**
Renders documentation locally using Docker with the official TYPO3 render-guides image. Execute this to verify documentation renders correctly before pushing to version control.

## Additional Resources

**Official Documentation:**
- TYPO3 Documentation Guide: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/
- RST Reference: https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html
- Rendering with Docker: https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Howto/RenderingDocs/Index.html

**Example Projects:**
- TYPO3 Best Practice Extension: https://github.com/TYPO3BestPractices/tea
- RTE CKEditor Image: https://docs.typo3.org/p/netresearch/rte-ckeditor-image/main/en-us/
