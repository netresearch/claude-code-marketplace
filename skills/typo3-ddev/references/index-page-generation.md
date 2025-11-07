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
```bash
# Check if branding skill exists
list-skills | grep -i branding
```

### Step 2: Apply Branding Based on Detection

#### If Netresearch Branding Detected

**Invoke:** `netresearch-branding` skill

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

## Quality Checklist

Before finalizing the index page:

- [ ] Branding detection executed correctly
- [ ] Appropriate colors applied
- [ ] Proper fonts loaded (if external fonts used)
- [ ] All TYPO3 version links present
- [ ] Backend credentials displayed
- [ ] Responsive design works on mobile/tablet/desktop
- [ ] Color contrast passes WCAG AA
- [ ] No console errors
- [ ] File copied to /var/www/html/
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
