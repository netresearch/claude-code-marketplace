# Scope Heuristics Reference

Rules for determining whether a learning candidate belongs at project or global scope.

## Decision Framework

### Priority Order
1. **Existing Rule Check**: Does similar rule exist?
2. **Cross-Repo Check**: Seen in multiple repos?
3. **Content Analysis**: Analyze text for indicators
4. **Default**: Project scope (safer)

## Project-Specific Indicators

### Path Patterns (+3 points each)
- `apps/` - Monorepo app directories
- `.platform.` - Platform.sh config
- `docker-compose.` - Docker composition
- `api.example.com` - Specific API URLs

### Path Patterns (+2 points each)
- `packages/` - Monorepo packages
- `src/components/` - Component directories
- `.env.` - Environment files
- `Makefile` - Project makefiles

### Domain Language (+2-3 points)
- Client/customer names
- Internal/proprietary references
- Business-specific terminology
- Project codenames

### Tooling Patterns (+2-3 points)
- `pnpm -C packages/` - Workspace-specific commands
- `nx ` - Nx monorepo tooling
- `turbo` - Turborepo commands
- Custom scripts in `scripts/`

## Global Indicators

### Universal Behaviors (+3 points each)
- `run tests` - Testing discipline
- `don't edit generated` - Generated code protection
- `never commit secrets` - Security practices
- `always backup` - Safety practices

### Universal Behaviors (+2 points each)
- `small pr` / `small commit` - PR discipline
- `commit message` - Git hygiene
- `code review` - Review practices
- `diff summary` - Diff practices
- `verify before` - Validation habits

### Cross-Repo Tooling (+1-2 points)
- `git` - Version control
- `docker` - Containerization
- `npm/pnpm/yarn` - JS package managers
- `python/pytest` - Python tooling
- `jest` - JS testing

## Scoring Algorithm

```python
def calculate_scope(candidate):
    project_score = sum(weight for pattern, weight in PROJECT_INDICATORS
                        if pattern in candidate_text)
    global_score = sum(weight for pattern, weight in GLOBAL_INDICATORS
                       if pattern in candidate_text)

    # Decision thresholds
    if global_score > project_score * 1.5:
        return "global"
    elif project_score > global_score * 1.5:
        return "project"
    else:
        return "project"  # Default
```

## Cross-Repo Promotion

### Promotion Threshold
- Default: 2 repos
- Configurable in config.json

### Promotion Criteria
1. Same fingerprint seen in N repos
2. Not already at global scope
3. Not previously rejected for promotion

### Fingerprint Matching
- Exact fingerprint match required
- Near-miss matching (Jaccard > 0.8) for suggestions

## Override Rules

### Force Project Scope
- Contains absolute paths specific to this machine
- References internal URLs or credentials
- Uses proprietary API endpoints

### Force Global Scope
- Exact match with existing global rule
- Cross-repo count >= 3
- User explicitly approves promotion

## Examples

### Example 1: Project Scope
```
Trigger: "when editing apps/storefront/generated/*"
Action: "regenerate from source"

Analysis:
- "apps/" → +3 project
- "storefront" → likely project-specific name
- Score: project=4, global=0
Result: PROJECT
```

### Example 2: Global Scope
```
Trigger: "when tests fail"
Action: "investigate before committing"

Analysis:
- "tests" → +2 global
- "committing" → +2 global
- Score: project=0, global=4
Result: GLOBAL
```

### Example 3: Ambiguous → Project Default
```
Trigger: "when using docker"
Action: "check container status first"

Analysis:
- "docker" → +2 global
- No project indicators
- Score: project=0, global=2
Result: PROJECT (not > 1.5x threshold)
```

## Configuration

```json
{
  "scope_indicators": {
    "project": [
      ["apps/", 3],
      ["packages/", 2]
    ],
    "global": [
      ["run tests", 3],
      ["git", 2]
    ]
  },
  "promotion_threshold_repos": 2,
  "force_project_patterns": [
    "/home/",
    "/Users/"
  ]
}
```
