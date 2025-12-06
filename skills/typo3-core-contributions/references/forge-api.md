# Forge REST API Documentation

Complete guide to using the TYPO3 Forge (Redmine) REST API for programmatic issue management.

## Overview

TYPO3 Forge (https://forge.typo3.org) is built on Redmine and exposes a REST API for:
- Creating issues
- Updating issues
- Querying project metadata
- Managing issue relationships

## Authentication

### Get API Key

1. Log in to https://forge.typo3.org
2. Go to https://forge.typo3.org/my/account
3. Find "API access key" on the right side
4. Click "Show" to reveal your key
5. Store securely (treat like a password!)

### Using API Key

**IMPORTANT**: Different operations require different authentication methods!

#### For GET Requests (Reading)

Pass via HTTP header:
```bash
-H "X-Redmine-API-Key: your-api-key-here"
```

#### For POST Requests (Creating Issues)

**Header authentication does NOT work for creating issues!** Use HTTP Basic Auth with API key as username:
```bash
curl -u "your-api-key-here:x" \
  -H "Content-Type: application/json" \
  -X POST \
  -d '{"issue": {...}}' \
  https://forge.typo3.org/issues.json
```

Note: The password can be anything (we use "x") - only the API key as username matters.

#### For PUT Requests (Updating Issues)

**Warning**: PUT requests may return 403 Forbidden depending on your account permissions. Some accounts can create issues but not update them via API. If you get 403 on PUT, you'll need to update issues manually through the web interface.

```bash
# This may return 403 depending on permissions
curl -u "your-api-key-here:x" \
  -H "Content-Type: application/json" \
  -X PUT \
  -d '{"issue": {"description": "..."}}' \
  https://forge.typo3.org/issues/12345.json
```

**Security**: Never commit API keys to repositories. Use environment variables:
```bash
export FORGE_API_KEY="your-api-key-here"
```

## Base URL

All API endpoints use:
```
https://forge.typo3.org
```

## Common Endpoints

### Create Issue

**Endpoint**: `POST /issues.json`

**Request**:
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: $FORGE_API_KEY" \
  -d '{
    "issue": {
      "project_id": "typo3cms-core",
      "subject": "Issue title here",
      "description": "Detailed description",
      "tracker_id": 1,
      "category_id": 975,
      "priority_id": 4,
      "custom_fields": [
        {"id": 4, "value": "13"}
      ]
    }
  }' \
  https://forge.typo3.org/issues.json
```

**Response**:
```json
{
  "issue": {
    "id": 107881,
    "project": {"id": 27, "name": "TYPO3 Core"},
    "tracker": {"id": 1, "name": "Bug"},
    "status": {"id": 1, "name": "New"},
    "priority": {"id": 4, "name": "Should have"},
    "subject": "Issue title here",
    "description": "Detailed description",
    "created_on": "2024-12-15T10:30:00Z",
    "updated_on": "2024-12-15T10:30:00Z"
  }
}
```

**Extract Issue Number**:
```bash
# Parse with jq
curl ... | jq -r '.issue.id'

# Parse with grep
curl ... | grep -oP '"id":\K[0-9]+' | head -1
```

### Get Project Metadata

**Endpoint**: `GET /projects/typo3cms-core.json`

**Request**:
```bash
curl -H "X-Redmine-API-Key: $FORGE_API_KEY" \
  https://forge.typo3.org/projects/typo3cms-core.json
```

**Response includes**:
- Available trackers (Bug, Feature, Task, etc.)
- Issue categories (Backend, Frontend, etc.)
- Custom field definitions

### Get Issue Details

**Endpoint**: `GET /issues/{id}.json`

**Request**:
```bash
curl -H "X-Redmine-API-Key: $FORGE_API_KEY" \
  https://forge.typo3.org/issues/105737.json
```

**Response includes**:
- Full issue details
- Custom fields
- Status and assignments
- Related issues

## Field IDs

### Trackers

| ID | Name |
|----|------|
| 1  | Bug |
| 2  | Feature |
| 4  | Task |
| 6  | Story |
| 10 | Epic |

### Priorities

| ID | Name |
|----|------|
| 2  | Nice to have |
| 3  | Must have |
| 4  | Should have |
| 5  | Could have |

### Common Categories

| ID   | Name |
|------|------|
| 971  | Backend API |
| 972  | Backend User Interface |
| 973  | Caching |
| 974  | Database API (Doctrine DBAL) |
| 975  | Miscellaneous |
| 976  | Extension Manager |
| 977  | Frontend |
| 1000 | Indexed Search |
| 1003 | Content Rendering |
| 1004 | Documentation |

**Get full list**: Use `scripts/query-forge-metadata.sh`

### Custom Fields

| ID | Name | Purpose |
|----|------|---------|
| 3  | Tags | Comma-separated keywords |
| 4  | TYPO3 Version | Version affected (e.g., "13", "12") |
| 5  | PHP Version | PHP version (e.g., "8.2", "8.3") |
| 8  | Complexity | Complexity estimate |
| 15 | Is Regression | Whether it's a regression |
| 18 | Sprint Focus | Sprint assignment |

## Complete Examples

### Example 1: Create Bug Report

```bash
export FORGE_API_KEY="your-api-key-here"

curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: $FORGE_API_KEY" \
  -d '{
    "issue": {
      "project_id": "typo3cms-core",
      "subject": "Indexed search causes crash on malformed UTF-8",
      "description": "When processing content with malformed UTF-8, the indexed search indexer crashes with TypeError in PHP 8.2+.\n\nSteps to reproduce:\n1. Create page with malformed UTF-8 content\n2. Run indexer\n3. Observe crash\n\nExpected: Graceful handling\nActual: TypeError exception",
      "tracker_id": 1,
      "category_id": 1000,
      "priority_id": 4,
      "custom_fields": [
        {"id": 4, "value": "13"},
        {"id": 5, "value": "8.2"},
        {"id": 3, "value": "indexed search, UTF-8, crash"}
      ]
    }
  }' \
  https://forge.typo3.org/issues.json
```

### Example 2: Create Feature Request

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: $FORGE_API_KEY" \
  -d '{
    "issue": {
      "project_id": "typo3cms-core",
      "subject": "Add WebP image format support",
      "description": "Add native WebP support to TYPO3 image processing:\n\n- WebP MIME type detection\n- Image manipulation support\n- Configuration options\n\nBenefit: 25-30% better compression than JPEG",
      "tracker_id": 2,
      "category_id": 977,
      "priority_id": 5,
      "custom_fields": [
        {"id": 4, "value": "14"},
        {"id": 3, "value": "WebP, images, performance"}
      ]
    }
  }' \
  https://forge.typo3.org/issues.json
```

### Example 3: Create Task

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: $FORGE_API_KEY" \
  -d '{
    "issue": {
      "project_id": "typo3cms-core",
      "subject": "Standardize commit-msg hook error message",
      "description": "Update Build/git-hooks/commit-msg error message to mention only '\''Resolves:'\'' tag instead of '\''Resolves|Fixes:'\'' to align with TYPO3 community standard.\n\nWhile validation regex accepts both for backward compatibility, error message should guide toward single standard keyword.",
      "tracker_id": 4,
      "category_id": 975,
      "priority_id": 4,
      "custom_fields": [
        {"id": 4, "value": "14"}
      ]
    }
  }' \
  https://forge.typo3.org/issues.json
```

## Error Handling

### Common Errors

**422 Unprocessable Entity**:
```json
{
  "errors": ["Category is not included in the list"]
}
```

**Solution**: Check field IDs are valid for the project

**422 - Required Field Missing**:
```json
{
  "errors": ["Typo3 version cannot be blank"]
}
```

**Solution**: Add required custom field (id: 4 for TYPO3 version)

**401 Unauthorized**:
```
{"errors": ["You are not authorized to access this page."]}
```

**Solution**: Check API key is correct and has permissions

### Validation

Before creating issue, validate:
- [ ] API key is set and valid
- [ ] project_id is "typo3cms-core"
- [ ] subject is descriptive (not too generic)
- [ ] tracker_id is valid (1, 2, or 4 most common)
- [ ] category_id matches project categories
- [ ] TYPO3 version custom field included (id: 4)

## Best Practices

### Subject Lines

✅ **Good**:
- "Indexed search crashes on malformed UTF-8"
- "Add WebP image format support"
- "Standardize commit-msg hook error message"

❌ **Bad**:
- "Fix bug"
- "Improvement needed"
- "Question about feature"

### Descriptions

**Structure**:
1. Brief summary (what is the issue)
2. Steps to reproduce (for bugs)
3. Expected behavior
4. Actual behavior
5. Additional context

**Include**:
- Error messages
- Stack traces
- Version information
- Configuration details

**Avoid**:
- Asking questions (use Slack instead)
- Multiple unrelated issues in one ticket
- Vague descriptions without details

### Categories

Choose most specific category:
- Not "Miscellaneous" if more specific exists
- "Backend API" for backend PHP code
- "Backend User Interface" for backend UI/UX
- "Frontend" for frontend rendering
- Component-specific for extensions (e.g., "Indexed Search")

### Priority

**Guidelines**:
- **Must have (3)**: Blocking issues, critical bugs, security
- **Should have (4)**: Normal bugs, important features (most common)
- **Could have (5)**: Nice-to-have features, minor improvements
- **Nice to have (2)**: Low priority, future considerations

## Automation Tips

### Store Issue Template

```bash
cat > /tmp/issue-template.json <<'EOF'
{
  "issue": {
    "project_id": "typo3cms-core",
    "subject": "",
    "description": "",
    "tracker_id": 1,
    "category_id": 975,
    "priority_id": 4,
    "custom_fields": [
      {"id": 4, "value": "13"}
    ]
  }
}
EOF
```

### Parse Response

```bash
# Extract issue number
ISSUE_ID=$(curl ... | jq -r '.issue.id')

# Build URL
ISSUE_URL="https://forge.typo3.org/issues/${ISSUE_ID}"

# Use in commit message
echo "Resolves: #${ISSUE_ID}"
```

### Batch Operations

Query multiple issues:
```bash
for id in 105737 107881 108000; do
  curl -H "X-Redmine-API-Key: $FORGE_API_KEY" \
    "https://forge.typo3.org/issues/${id}.json"
done
```

## Integration with Git

### Create Issue and Commit

```bash
#!/bin/bash
# Create issue
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: $FORGE_API_KEY" \
  -d @issue.json \
  https://forge.typo3.org/issues.json)

# Extract issue number
ISSUE_ID=$(echo "$RESPONSE" | jq -r '.issue.id')

# Use in commit
git commit -m "[BUGFIX] Fix the problem

Resolves: #${ISSUE_ID}
Releases: main"
```

### Link Gerrit Patch to Issue

After submitting to Gerrit:
```bash
GERRIT_URL="https://review.typo3.org/c/Packages/TYPO3.CMS/+/91302"
# Add comment to Forge issue with patch link
# (requires additional API call - see Redmine API docs)
```

## Resources

- **Redmine API Docs**: https://www.redmine.org/projects/redmine/wiki/Rest_api
- **TYPO3 Forge**: https://forge.typo3.org
- **API Access Key**: https://forge.typo3.org/my/account
- **Project Info**: https://forge.typo3.org/projects/typo3cms-core

## Quick Reference

| Task | Endpoint | Method |
|------|----------|--------|
| Create issue | `/issues.json` | POST |
| Get issue | `/issues/{id}.json` | GET |
| Update issue | `/issues/{id}.json` | PUT |
| Get project | `/projects/{id}.json` | GET |
| List issues | `/issues.json?project_id=typo3cms-core` | GET |

## See Also

- `scripts/create-forge-issue.sh` - Interactive issue creation
- `scripts/query-forge-metadata.sh` - Query project metadata
- `references/commit-message-format.md` - For using issue numbers in commits
