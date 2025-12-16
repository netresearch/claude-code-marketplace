# Sub-Issues Reference

GitHub's sub-issues feature enables parent-child relationships between issues, supporting up to 8 levels of hierarchy and 100 sub-issues per parent. This replaced the deprecated tasklists feature (sunset April 2025).

**Important:** The `gh` CLI does not support sub-issues directly. You must use the GraphQL API.

## Creating Sub-Issues

**Step 1: Create the issues normally**
```bash
# Create parent issue
gh issue create --title "Parent feature request" --body "Main tracking issue"
# Returns: https://github.com/owner/repo/issues/100

# Create child issues
gh issue create --title "Sub-task 1" --body "First sub-task"
# Returns: https://github.com/owner/repo/issues/101

gh issue create --title "Sub-task 2" --body "Second sub-task"
# Returns: https://github.com/owner/repo/issues/102
```

**Step 2: Get issue node IDs (required for GraphQL)**
```bash
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    parent: issue(number: 100) { id }
    child1: issue(number: 101) { id }
    child2: issue(number: 102) { id }
  }
}'
```

Output:
```json
{
  "data": {
    "repository": {
      "parent": { "id": "I_kwDOXXXXXX" },
      "child1": { "id": "I_kwDOYYYYYY" },
      "child2": { "id": "I_kwDOZZZZZZ" }
    }
  }
}
```

**Step 3: Link sub-issues to parent**
```bash
# Add first sub-issue
gh api graphql -f query='
mutation {
  addSubIssue(input: {
    issueId: "I_kwDOXXXXXX",
    subIssueId: "I_kwDOYYYYYY"
  }) {
    issue { number title }
    subIssue { number title }
  }
}'

# Add second sub-issue
gh api graphql -f query='
mutation {
  addSubIssue(input: {
    issueId: "I_kwDOXXXXXX",
    subIssueId: "I_kwDOZZZZZZ"
  }) {
    issue { number title }
    subIssue { number title }
  }
}'
```

## Querying Sub-Issues

**List all sub-issues of a parent:**
```bash
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    issue(number: 100) {
      number
      title
      subIssues(first: 50) {
        nodes {
          number
          title
          state
        }
        totalCount
      }
    }
  }
}'
```

**Get parent of a sub-issue:**
```bash
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    issue(number: 101) {
      number
      title
      parent {
        number
        title
      }
    }
  }
}'
```

## Removing Sub-Issues

```bash
gh api graphql -f query='
mutation {
  removeSubIssue(input: {
    issueId: "I_kwDOXXXXXX",
    subIssueId: "I_kwDOYYYYYY"
  }) {
    issue { number }
    subIssue { number }
  }
}'
```

## Best Practices

| Practice | Rationale |
|----------|-----------|
| Use parent as tracking/meta issue | Provides overview and progress tracking |
| Add "tracking" label to parent | Identifies meta-issues in issue lists |
| Keep hierarchy ≤3 levels | Deeper hierarchies become hard to manage |
| Reference upstream PRs in body | Link to external sources for context |
| One sub-issue per distinct feature | Enables independent progress and assignment |

## Sub-Issues Behavior

- **Inheritance**: Sub-issues inherit Project and Milestone from parent by default
- **Cross-org support**: Sub-issues can belong to different organizations than parent
- **Progress tracking**: Parent issue shows completion percentage in GitHub UI
- **Limits**: Maximum 100 sub-issues per parent, 8 levels of nesting

## Migration from Tasklists

Tasklists were sunset April 30, 2025. To convert old tasklist items:

1. Identify issues with tasklist markdown (`- [ ] #123`)
2. Create sub-issue relationships using GraphQL API above
3. Remove tasklist markdown from issue body (or leave as reference)

## Quick Reference

```bash
# Get issue node ID
gh api graphql -f query='{repository(owner:"OWNER",name:"REPO"){issue(number:123){id}}}'

# Add sub-issue (requires node IDs)
gh api graphql -f query='mutation{addSubIssue(input:{issueId:"PARENT_ID",subIssueId:"CHILD_ID"}){issue{number}subIssue{number}}}'

# List sub-issues
gh api graphql -f query='{repository(owner:"OWNER",name:"REPO"){issue(number:123){subIssues(first:50){nodes{number title state}}}}}'

# Remove sub-issue
gh api graphql -f query='mutation{removeSubIssue(input:{issueId:"PARENT_ID",subIssueId:"CHILD_ID"}){issue{number}}}'
```
