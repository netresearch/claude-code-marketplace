# Documentation Coverage Analysis

## Purpose

Provide context-aware documentation coverage assessment based on actual extension features rather than static file count thresholds.

## Problem with Static Thresholds

Traditional conformance scoring uses fixed RST file count thresholds:
- 50-99 files: +1 point
- 100-149 files: +2 points
- 150+ files: +3 points

**This approach is flawed** because:
1. Extension scope varies dramatically (focused vs. comprehensive)
2. File count doesn't reflect feature coverage quality
3. Penalizes well-scoped extensions with complete user documentation
4. Based on large CMS extensions (georgringer/news) as "excellence" reference

## Improved Methodology: Feature Coverage Analysis

### Step 1: Identify Extension Features

Categorize features into two groups:

**User-Facing Features:**
- Installation & configuration
- Backend modules & dashboards
- End-user workflows
- Integration guides
- Troubleshooting

**Developer Features:**
- CLI commands
- Scheduler tasks
- Reports/widgets
- Event listeners
- PHP API (public methods)
- Extension points

### Step 2: Assess Documentation Coverage

For each feature category, calculate coverage percentage:

```
User Coverage = Documented User Features / Total User Features
Developer Coverage = Documented Developer Features / Total Developer Features
Overall Coverage = (User + Developer) / (Total User + Total Developer)
```

### Step 3: Quality Assessment

Evaluate documentation quality beyond mere existence:

**Quality Indicators:**
- ✅ Uses TYPO3 directives (confval, versionadded, php:method)
- ✅ Includes code examples and integration patterns
- ✅ Modern tooling (guides.xml, card-grid navigation)
- ✅ Proper cross-references and interlinking
- ✅ Screenshots or visual aids where appropriate

### Step 4: Context-Aware Scoring

Score based on extension scope and feature coverage:

**Small/Focused Extensions (10-30 classes):**
- User coverage 100% + modern tooling = EXCELLENT (3-4 points)
- User coverage 80-99% = GOOD (2-3 points)
- User coverage 60-79% = ADEQUATE (1-2 points)
- User coverage <60% = INSUFFICIENT (0-1 points)

**Medium Extensions (31-100 classes):**
- User coverage 100% + developer coverage 80%+ = EXCELLENT (3-4 points)
- User coverage 100% + developer coverage 40-79% = GOOD (2-3 points)
- User coverage 80-99% = ADEQUATE (1-2 points)
- User coverage <80% = INSUFFICIENT (0-1 points)

**Large Extensions (100+ classes):**
- Comprehensive documentation (user + developer 90%+) = EXCELLENT (3-4 points)
- Good user docs + partial developer docs = GOOD (2-3 points)
- User docs 80%+ = ADEQUATE (1-2 points)
- User docs <80% = INSUFFICIENT (0-1 points)

## Analysis Workflow

### 1. Count Extension Features

```bash
# User-facing features
echo "User Features:"
echo "  - Installation: $(ls -1 Documentation/Installation/*.rst 2>/dev/null | wc -l)"
echo "  - Configuration: $(ls -1 Documentation/Configuration/*.rst 2>/dev/null | wc -l)"
echo "  - Backend Module: $(ls -1 Documentation/Backend/*.rst 2>/dev/null | wc -l)"
echo "  - Guides: $(ls -1 Documentation/Guides/*.rst 2>/dev/null | wc -l)"

# Developer features
echo "Developer Features:"
echo "  - CLI Commands: $(find Classes/Command -name "*.php" 2>/dev/null | wc -l)"
echo "  - Scheduler Tasks: $(find Classes/Task -name "*.php" 2>/dev/null | wc -l)"
echo "  - Reports: $(find Classes/Report -name "*.php" 2>/dev/null | wc -l)"
echo "  - Event Listeners: $(find Classes/EventListener -name "*.php" 2>/dev/null | wc -l)"
```

### 2. Map Documentation to Features

Create feature-to-documentation mapping:

```
User Features:
  ✓ Installation & Setup → Documentation/Installation/Index.rst
  ✓ Configuration → Documentation/Configuration/*.rst
  ✓ Backend Module → Documentation/Backend/*.rst
  ⚠️ Troubleshooting → Documentation/Troubleshooting/Index.rst (partial)

Developer Features:
  ⚠️ CLI: FlushCachesCommand → mentioned but no API reference
  ⚠️ CLI: ShowTransitionCommand → mentioned but no API reference
  ❌ Task: FlushExpiredCachesTask → not documented
  ❌ Report: CacheStatusReport → not documented
  ❌ EventListener: CacheLifetimeListener → not documented
```

### 3. Calculate Coverage Scores

```
User Coverage: 3/4 features = 75%
Developer Coverage: 0/5 features = 0%
Overall Coverage: 3/9 features = 33%
```

### 4. Assess Quality

```
Quality Indicators:
  ✅ Modern tooling (guides.xml)
  ✅ TYPO3 directives (confval)
  ✅ Card-grid navigation
  ✅ Code examples
  ⚠️ Screenshots mentioned but not included

Quality Score: 4/5 = 80%
```

### 5. Determine Final Rating

For a **focused extension** (30 classes):
- User coverage: 75% (3/4) → ADEQUATE
- Developer coverage: 0% (0/5) → gap acceptable for user-focused extensions
- Quality: 80% → HIGH
- Modern tooling: YES

**Final Rating: GOOD (2-3 points)**
- User documentation is COMPREHENSIVE for critical features
- Developer API documentation is a nice-to-have
- Quality is HIGH with modern TYPO3 13.x patterns

## Comparison: Static vs. Feature-Based Scoring

### Example Extension Analysis

**Extension:** Temporal Cache (focused, 30 classes)

**Static Threshold Scoring:**
```
RST Files: 22
Threshold: Need 50+ for points
Score: 1/4 (modern tooling bonus only)
Rating: INSUFFICIENT
```

**Feature-Based Scoring:**
```
User Features: 6/6 = 100% coverage ✅
Developer Features: 0/5 = 0% coverage (acceptable for scope)
Quality: 4/5 = 80% (modern tooling, directives, examples)
Extension Scope: Focused (30 classes)

Score: 3/4 points
Rating: EXCELLENT for scope
```

### Key Insight

**22 RST files can be EXCELLENT** for a focused extension with:
- 100% user feature coverage
- High-quality modern documentation
- Proper TYPO3 directives and examples
- Appropriate scope matching

**150+ RST files may be INSUFFICIENT** for a large CMS extension with:
- Incomplete feature coverage
- Missing integration guides
- No API reference
- Outdated patterns

## Recommendations for TYPO3 Conformance Skill

### Update Scoring Logic

Replace static thresholds with feature-based analysis:

```python
def calculate_documentation_score(extension):
    """
    Calculate documentation excellence score based on feature coverage.

    Returns: 0-4 points
    """
    # Determine extension scope
    class_count = count_php_classes(extension)
    scope = classify_scope(class_count)  # small/medium/large

    # Calculate feature coverage
    user_coverage = calculate_user_feature_coverage(extension)
    dev_coverage = calculate_developer_feature_coverage(extension)

    # Assess quality
    quality_score = assess_documentation_quality(extension)

    # Score based on scope
    if scope == "small":
        if user_coverage >= 0.90 and quality_score >= 0.80:
            return 3  # EXCELLENT
        elif user_coverage >= 0.75:
            return 2  # GOOD
        elif user_coverage >= 0.60:
            return 1  # ADEQUATE
        else:
            return 0  # INSUFFICIENT

    elif scope == "medium":
        if user_coverage >= 0.90 and dev_coverage >= 0.80:
            return 4  # OUTSTANDING
        elif user_coverage >= 0.90 and dev_coverage >= 0.40:
            return 3  # EXCELLENT
        elif user_coverage >= 0.80:
            return 2  # GOOD
        else:
            return 1 if user_coverage >= 0.60 else 0

    else:  # large
        total_coverage = (user_coverage + dev_coverage) / 2
        if total_coverage >= 0.90:
            return 4  # OUTSTANDING
        elif total_coverage >= 0.75:
            return 3  # EXCELLENT
        elif total_coverage >= 0.60:
            return 2  # GOOD
        else:
            return 1 if total_coverage >= 0.40 else 0
```

### Provide Clear Feedback

Documentation assessment should include:
1. Feature coverage breakdown (user vs. developer)
2. Quality assessment (directives, examples, tooling)
3. Scope-appropriate recommendations
4. Specific missing documentation items

### Example Output

```
## Documentation Excellence Assessment

**Extension Scope:** Small/Focused (30 classes)

**User Feature Coverage:** 6/6 (100%) ✅
  ✓ Installation & Setup
  ✓ Configuration (3 strategies)
  ✓ Backend Module
  ✓ Performance Guide
  ✓ Architecture
  ✓ Phases Roadmap

**Developer Feature Coverage:** 0/5 (0%) ⚠️
  ❌ CLI Commands API reference (2 commands)
  ❌ Scheduler Tasks reference (1 task)
  ❌ Reports reference (1 report)
  ❌ EventListener docs
  ❌ PHP API method-level docs

**Quality Assessment:** 4/5 (80%) ✅
  ✅ Modern tooling (guides.xml, card-grid)
  ✅ TYPO3 directives (confval throughout)
  ✅ Code examples extensive
  ✅ Cross-references proper
  ⚠️ Screenshots mentioned but not included

**Score:** 3/4 points (EXCELLENT for extension scope)

**Recommendation:**
Your user documentation is COMPREHENSIVE (100% coverage). Developer API
documentation is optional for this extension's scope. Consider adding
API reference if you expect other developers to extend your extension.

**Impact of Adding Developer Docs:**
- Current: 22 RST files (100% user coverage, 0% developer)
- With API reference: ~30 RST files (100% user + 100% developer)
- Score change: 3/4 → 4/4 (OUTSTANDING)
```

## Summary

**Key Principles:**
1. Documentation quality > file quantity
2. Feature coverage > arbitrary thresholds
3. Scope-appropriate expectations
4. User-facing docs prioritized over developer API docs
5. Context-aware scoring avoids penalizing focused extensions

**Benefits:**
- Accurate assessment of documentation completeness
- Fair scoring across extension scopes
- Actionable recommendations
- Recognizes excellent documentation regardless of file count
- Aligns with TYPO3 documentation best practices
