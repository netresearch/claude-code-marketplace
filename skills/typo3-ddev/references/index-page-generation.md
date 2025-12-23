# Index Page Generation for TYPO3 DDEV Projects

## Purpose

Generate a professional overview page (`index.html`) that serves as the main entry point for the DDEV development environment, providing quick access to all TYPO3 versions and development tools.

## Automatic Branding Detection

**The index page MUST automatically detect and apply appropriate branding:**

### Step 1: Detect Available Branding Skills

Check for branding skills in this priority order:

1. **Company-specific branding** (e.g., `netresearch-branding`, `company-branding`)
2. **TYPO3 branding** (fallback - use TYPO3 orange #FF8700)
3. **Generic clean design** (last resort - neutral colors)

**Detection Method:**

For Claude Code / AI agents, check available skills:
```bash
# In Claude Code context
/sc:help | grep -i branding
# Or check skill directories
ls ~/.claude/plugins/cache/*/netresearch-branding/*/SKILL.md 2>/dev/null
```

For manual detection, check if the project is a Netresearch project:
```bash
# Check composer.json vendor
grep -q '"netresearch/' composer.json && echo "Netresearch project"
# Check git remote
git remote -v | grep -q 'netresearch' && echo "Netresearch repo"
```

### Branding Detection Troubleshooting

**Common Issue: Landing page generated without proper branding**

Symptoms:
- Generic colors instead of Netresearch turquoise (#2F99A4)
- Missing logo
- Wrong fonts (system fonts instead of Raleway/Open Sans)
- Extension name shows underscores (`nr_llm`) instead of hyphens (`nr-llm`)

**Root Causes and Fixes:**

1. **Branding skill not read** - The agent generated a page without consulting branding references
   - Fix: Explicitly invoke `netresearch-branding` skill before generating
   - Fix: Read the branding SKILL.md file for color/font values

2. **Logo not embedded** - The logo SVG wasn't included
   - Fix: Use the embedded SVG provided in this document (see below)
   - Fix: Do NOT rely on external logo URLs - embed inline

3. **Wrong extension name format** - Used internal key instead of display name
   - Fix: Read `composer.json` "name" field for authoritative name
   - Fix: Use hyphens (`nr-llm`) not underscores (`nr_llm`)

4. **Fallback to generic design** - Branding detection returned false negative
   - Fix: Check if repo URL or composer vendor contains "netresearch"
   - Fix: If Netresearch project, ALWAYS apply Netresearch branding

**Verification Checklist:**
- [ ] Header background is turquoise gradient (#2F99A4 → #247a82)
- [ ] Logo SVG is embedded (turquoise frame, grey "n")
- [ ] Headlines use Raleway font
- [ ] Body uses Open Sans font
- [ ] Extension name uses hyphens (from composer.json)
- [ ] Git branch and commit are displayed

### Step 2: Apply Branding Based on Detection

#### If Netresearch Branding Detected

**Invoke:** `netresearch-branding` skill

**Use Template:** `netresearch-branding/assets/landing-page-template.html`

This pre-built template includes:
- Professional gradient background
- Card-based layout for quick links
- Credentials display section
- Development commands reference
- GitHub repository link
- Netresearch footer branding

**Template Variables to Replace:**
| Variable | Source | Example |
|----------|--------|---------|
| `{{EXTENSION_TITLE}}` | Extension name from composer.json | "RTE CKEditor Image" |
| `{{EXTENSION_DESCRIPTION}}` | composer.json description | "Image support in CKEditor for TYPO3" |
| `{{DDEV_SITENAME}}` | .ddev/config.yaml name | "rte-ckeditor-image" |
| `{{GITHUB_URL}}` | composer.json homepage | "https://github.com/netresearch/..." |

**Colors:**
- Primary: #2F99A4 (Turquoise)
- Accent: #FF4D00 (Orange)
- Text: #585961 (Anthracite grey)
- Background: #FFFFFF (White)
- Light grey: #CCCDCC

**Typography:**
- Headlines: `font-family: 'Raleway', sans-serif;` (600/700 weight)
- Body: `font-family: 'Open Sans', sans-serif;` (400 weight)

**Layout:**
- Compact header: 20px padding
- High white space: 40px container padding
- Card shadows: subtle with turquoise glow on hover

**Official Netresearch Logo SVG:**

The logo MUST be included when Netresearch branding is detected. Embed this SVG directly:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="40" height="40">
  <!-- Turquoise frame -->
  <rect x="5" y="5" width="90" height="90" rx="8" ry="8"
        fill="none" stroke="#2999A4" stroke-width="6"/>
  <!-- Grey "n" letter -->
  <text x="50" y="72" text-anchor="middle"
        font-family="Arial, sans-serif" font-size="60" font-weight="bold"
        fill="#595A62">n</text>
</svg>
```

**CSS for logo in header:**
```css
.logo {
    display: flex;
    align-items: center;
    gap: 12px;
}
.logo svg {
    flex-shrink: 0;
}
.logo-text {
    font-family: 'Raleway', sans-serif;
    font-weight: 700;
    font-size: 1.5rem;
    color: #2F99A4;
}
```

**Complete header example:**
```html
<header style="background: linear-gradient(135deg, #2F99A4 0%, #247a82 100%); padding: 20px;">
    <div class="logo">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="40" height="40">
            <rect x="5" y="5" width="90" height="90" rx="8" ry="8"
                  fill="none" stroke="#ffffff" stroke-width="6"/>
            <text x="50" y="72" text-anchor="middle"
                  font-family="Arial, sans-serif" font-size="60" font-weight="bold"
                  fill="#ffffff">n</text>
        </svg>
        <span class="logo-text" style="color: #ffffff;">Extension Name</span>
    </div>
</header>
```

#### If TYPO3 Branding (Fallback)

**Colors:**
- Primary: #FF8700 (TYPO3 Orange)
- Secondary: #000000 (Black)
- Text: #333333 (Dark grey)
- Background: #F8F9FA (Light grey)
- Cards: #FFFFFF (White)

**Typography:**
- System fonts: `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`
- No external font imports

**Layout:**
- Standard header: 40px padding
- Moderate white space: 30px container padding
- Card shadows: standard grey shadows

#### If No Branding (Generic)

**Colors:**
- Primary: #0066CC (Professional blue)
- Text: #333333
- Background: #FFFFFF
- Cards: #F5F5F5

**Typography:**
- System fonts only
- Standard sizing

## HTML Template Structure

### Required Elements

1. **Header** - Compact bar with project title
2. **Info Box** - Backend credentials (username/password)
3. **Grid Layout** - 2-4 columns responsive
4. **Cards** - One per TYPO3 version + tools
5. **Links** - Frontend and Backend URLs

### Card Content Template

```html
<div class="card">
    <div class="card-icon">[EMOJI]</div>
    <h3>[VERSION NAME]</h3>
    <p>[DESCRIPTION]</p>
    <div class="card-links">
        <a href="[FRONTEND_URL]">→ Frontend</a>
        <a href="[BACKEND_URL]">→ Backend</a>
    </div>
</div>
```

### Cards to Include

**Always include:**
1. TYPO3 12.4 LTS (🎯 emoji)
2. TYPO3 13.x (⚡ emoji)
3. Documentation (📚 emoji)
4. Development Tools (📧 emoji - Mailpit)

**Optional cards** (if applicable):
5. TYPO3 11.5 LTS (📦 emoji)
6. Redis/Valkey (🔄 emoji)
7. Custom tools

## Generation Workflow

### Step 1: Detect Branding

```
1. Check for branding skills
2. If netresearch-branding exists → Use Netresearch colors/fonts
3. Else if project has branding config → Use project branding
4. Else → Use TYPO3 branding (fallback)
```

### Step 2: Extract Project Metadata

```
- Project name (from .ddev/config.yaml or composer.json)
- DDEV sitename
- Configured TYPO3 versions (from docker-compose or config)
```

### Step 3: Generate HTML

**File location:** `.ddev/web-build/index.html`

**Template variables to replace:**
- `{{PROJECT_NAME}}` - Extension display name
- `{{DDEV_SITENAME}}` - DDEV project name
- `{{PRIMARY_COLOR}}` - Brand primary color
- `{{ACCENT_COLOR}}` - Brand accent color
- `{{TEXT_COLOR}}` - Body text color
- `{{FONT_HEADLINE}}` - Headline font family
- `{{FONT_BODY}}` - Body font family

### Step 4: Copy to Web Root

```bash
# After generation
ddev exec cp /var/www/hello_world/.ddev/web-build/index.html /var/www/html/
```

## Example: Netresearch-Branded Index

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{PROJECT_NAME}} - Development Environment</title>
    <link href="https://fonts.googleapis.com/css2?family=Raleway:wght@600;700&family=Open+Sans:wght@400&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Open Sans', sans-serif;
            background: #FFFFFF;
            color: #585961;
        }
        .header {
            background: #2F99A4;
            padding: 20px;
        }
        .header h1 {
            font-family: 'Raleway', sans-serif;
            color: #FFFFFF;
            font-size: 24px;
        }
        .card-links a:hover {
            background: #2F99A4;
            color: #FFFFFF;
        }
    </style>
</head>
<body>
    <!-- Content here -->
</body>
</html>
```

## Example: TYPO3-Branded Index (Fallback)

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>{{PROJECT_NAME}} - Development Environment</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #F8F9FA;
            color: #333333;
        }
        .header {
            background: #FF8700;
            padding: 40px 20px;
        }
        .header h1 {
            color: #FFFFFF;
            font-size: 32px;
        }
        .card-links a {
            color: #FF8700;
        }
        .card-links a:hover {
            background: #FF8700;
            color: #FFFFFF;
        }
    </style>
</head>
<body>
    <!-- Content here -->
</body>
</html>
```

## Responsive Design Requirements

**Breakpoints:**
```css
/* Mobile: default (single column) */
.grid {
    grid-template-columns: 1fr;
}

/* Tablet: 768px+ (2 columns) */
@media (min-width: 768px) {
    .grid {
        grid-template-columns: repeat(2, 1fr);
    }
}

/* Desktop: 1024px+ (auto-fit) */
@media (min-width: 1024px) {
    .grid {
        grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    }
}
```

## Accessibility Requirements

**WCAG AA Compliance:**

1. **Color Contrast**
   - Text on background: minimum 4.5:1
   - Large text (18px+): minimum 3:1
   - Verify with: https://webaim.org/resources/contrastchecker/

2. **Keyboard Navigation**
   - All links must be keyboard accessible
   - Visible focus states
   - Logical tab order

3. **Semantic HTML**
   - Proper heading hierarchy (h1 → h2 → h3)
   - Descriptive link text (not just "click here")
   - Alt text for images (if any)

## Git Status Display

**The landing page SHOULD display git repository information:**

### Git Information to Show
- **Branch name**: Current git branch (e.g., `main`, `feature/xyz`)
- **Commit hash**: Short commit hash (7 characters)

### PHP Implementation (No shell_exec)

Read git info directly from files for security and compatibility:

```php
// Git info from files (no shell_exec needed)
$gitBranch = 'unknown';
$gitCommitShort = 'unknown';
$gitHeadFile = dirname(__DIR__) . '/.git/HEAD';

if (file_exists($gitHeadFile)) {
    $headContent = trim(file_get_contents($gitHeadFile));
    if (str_starts_with($headContent, 'ref: refs/heads/')) {
        $gitBranch = substr($headContent, 16);
        $refFile = dirname(__DIR__) . '/.git/refs/heads/' . $gitBranch;
        if (file_exists($refFile)) {
            $gitCommitShort = substr(trim(file_get_contents($refFile)), 0, 7);
        }
    }
}
```

### Display Format

```html
<div class="git-info">
    <span class="branch">📌 <?= htmlspecialchars($gitBranch) ?></span>
    <span class="commit">@<?= htmlspecialchars($gitCommitShort) ?></span>
</div>
```

**Why file-based instead of shell_exec?**
- Security: No command injection risk
- Compatibility: Works in restricted PHP environments
- Performance: Direct file read is faster than spawning shell

## Single-Extension Mode

**For projects with a single extension (not multi-version testing):**

When building a simple landing page for a single TYPO3 extension project:

### File Location

Place the landing page at `public/index.php` (not `.ddev/web-build/index.html`).

This approach:
- ✅ Works immediately without DDEV custom commands
- ✅ Can be served by the default DDEV web root
- ✅ Allows PHP for dynamic content (git info, extension metadata)

### Extension Naming Convention

**Use hyphenated names** in display, not underscored:
- ✅ `nr-llm` (composer package style)
- ✅ `t3x-nr-llm` (TYPO3 package prefix)
- ❌ `nr_llm` (internal extension key only)

The composer package name from `composer.json` (`name` field) is authoritative.

### Minimal Single-Extension Template

```php
<?php
declare(strict_types=1);

// Read extension info from composer.json
$composerJson = json_decode(file_get_contents(__DIR__ . '/../composer.json'), true);
$extensionName = $composerJson['name'] ?? 'extension';
$description = $composerJson['description'] ?? '';

// Git info (see implementation above)
// ... git file reading code ...
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><?= htmlspecialchars($extensionName) ?></title>
    <!-- Apply branding per detection logic -->
</head>
<body>
    <header>
        <h1><?= htmlspecialchars($extensionName) ?></h1>
        <p><?= htmlspecialchars($description) ?></p>
        <div class="git-info">Branch: <?= $gitBranch ?> @ <?= $gitCommitShort ?></div>
    </header>
    <!-- Links to TYPO3 backends, documentation, etc. -->
</body>
</html>
```

## Quality Checklist

Before finalizing the index page:

- [ ] Branding detection executed correctly
- [ ] Appropriate colors applied
- [ ] Proper fonts loaded (if external fonts used)
- [ ] All TYPO3 version links present
- [ ] Backend credentials displayed
- [ ] **Git branch and commit displayed**
- [ ] **Extension name uses correct format (hyphens, not underscores)**
- [ ] Responsive design works on mobile/tablet/desktop
- [ ] Color contrast passes WCAG AA
- [ ] No console errors
- [ ] File copied to /var/www/html/ (or public/index.php for single-extension)
- [ ] Accessible at https://{sitename}.ddev.site/

## Integration with SKILL.md

**In Step 8 of SKILL.md, replace the current text with:**

```markdown
### Step 8: Generate Project Overview Page

**Automatic branding detection:**

The overview page automatically detects and applies appropriate branding:

1. **Check for branding skills** (netresearch-branding, company-branding, etc.)
2. **Apply detected branding** (colors, fonts, layout)
3. **Fallback to TYPO3 branding** (orange #FF8700) if no branding detected
4. **Generate responsive HTML** with cards for each TYPO3 version

**Generation process:**

```bash
# Skill automatically:
# 1. Detects available branding (netresearch-branding skill if present)
# 2. Applies brand colors and fonts
# 3. Creates .ddev/web-build/index.html
# 4. Copies to /var/www/html/

# Manual copy if needed:
ddev exec cp /var/www/hello_world/.ddev/web-build/index.html /var/www/html/
```

**See:** `INDEX-PAGE-GENERATION.md` for complete branding detection logic
```

## Example Detection Logic (Pseudocode)

```python
def generate_index_page():
    # Step 1: Detect branding
    branding = detect_branding()
    
    if branding == "netresearch":
        colors = {
            "primary": "#2F99A4",
            "text": "#585961",
            "background": "#FFFFFF"
        }
        fonts = {
            "headline": "Raleway",
            "body": "Open Sans"
        }
        header_padding = "20px"
        
    elif branding == "company-specific":
        # Load company branding
        colors = load_company_colors()
        fonts = load_company_fonts()
        
    else:  # TYPO3 fallback
        colors = {
            "primary": "#FF8700",
            "text": "#333333",
            "background": "#F8F9FA"
        }
        fonts = {
            "headline": "system-ui",
            "body": "system-ui"
        }
        header_padding = "40px"
    
    # Step 2: Generate HTML
    html = generate_html_template(colors, fonts, header_padding)
    
    # Step 3: Write file
    write_file(".ddev/web-build/index.html", html)
    
    # Step 4: Copy to web root
    copy_to_web_root()
```

---

**This approach ensures:**
- ✅ Automatic branding application
- ✅ Consistent professional appearance
- ✅ Graceful fallback to TYPO3 branding
- ✅ Company branding when available
- ✅ No manual branding decisions needed
