# Dependency Management Reference

Dependabot and Renovate configuration patterns.

## Dependabot

### Basic Configuration
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "06:00"
      timezone: "Europe/Berlin"
```

### Package Ecosystems

| Ecosystem | Languages/Tools |
|-----------|-----------------|
| gomod | Go modules |
| npm | JavaScript/Node.js |
| composer | PHP |
| pip | Python |
| cargo | Rust |
| maven | Java |
| gradle | Java/Kotlin |
| nuget | .NET |
| bundler | Ruby |
| docker | Dockerfiles |
| github-actions | GitHub Actions |
| terraform | Terraform |

### Grouping Dependencies
```yaml
updates:
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      all-dependencies:
        patterns:
          - "*"

      # Or group by type
      production:
        dependency-type: "production"
      development:
        dependency-type: "development"
```

### Commit Message Prefixes
```yaml
updates:
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "deps"
      prefix-development: "deps(dev)"
      include: "scope"
    labels:
      - "dependencies"
```

### Multiple Ecosystems
```yaml
version: 2
updates:
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      dependencies:
        patterns:
          - "*"
    commit-message:
      prefix: "deps"
    labels:
      - "dependencies"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      github-actions:
        patterns:
          - "*"
    commit-message:
      prefix: "ci"
    labels:
      - "dependencies"
      - "github-actions"

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "docker"
    labels:
      - "dependencies"
      - "docker"
```

### Ignoring Dependencies
```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    ignore:
      - dependency-name: "lodash"
        versions: [">=5.0.0"]
      - dependency-name: "react"
        update-types: ["version-update:semver-major"]
```

### Reviewers and Assignees
```yaml
updates:
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
    reviewers:
      - "username"
      - "org/team-name"
    assignees:
      - "username"
```

## Renovate

### Basic Configuration
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended"
  ]
}
```

### Extended Configuration
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended",
    ":semanticCommits",
    ":semanticCommitTypeAll(chore)",
    "group:allNonMajor"
  ],
  "labels": ["dependencies"],
  "prHourlyLimit": 2,
  "prConcurrentLimit": 5,
  "timezone": "Europe/Berlin",
  "schedule": ["before 7am on monday"]
}
```

### Auto-merge Configuration
```json
{
  "extends": ["config:recommended"],
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true
    },
    {
      "matchManagers": ["github-actions"],
      "groupName": "GitHub Actions",
      "automerge": true
    },
    {
      "matchDepTypes": ["devDependencies"],
      "automerge": true
    }
  ]
}
```

### Grouping Rules
```json
{
  "extends": ["config:recommended"],
  "packageRules": [
    {
      "matchPackagePatterns": ["^@types/"],
      "groupName": "TypeScript types"
    },
    {
      "matchPackagePatterns": ["eslint"],
      "groupName": "ESLint"
    },
    {
      "matchPackagePatterns": ["^react"],
      "groupName": "React"
    }
  ]
}
```

### Security Updates
```json
{
  "extends": [
    "config:recommended",
    ":enableVulnerabilityAlerts"
  ],
  "vulnerabilityAlerts": {
    "labels": ["security"],
    "automerge": true
  }
}
```

### PHP/Composer Configuration
```json
{
  "extends": ["config:recommended"],
  "composer": {
    "enabled": true
  },
  "packageRules": [
    {
      "matchPackagePatterns": ["^typo3/"],
      "groupName": "TYPO3"
    },
    {
      "matchPackagePatterns": ["^phpstan/", "^phpunit/"],
      "groupName": "PHP dev tools"
    }
  ]
}
```

### Go Configuration
```json
{
  "extends": ["config:recommended"],
  "gomod": {
    "enabled": true
  },
  "packageRules": [
    {
      "matchManagers": ["gomod"],
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true
    }
  ]
}
```

## Auto-merge Workflow

### Auto-merge Decision Matrix

| Repository Configuration | Workflow Pattern | Key Difference |
|--------------------------|------------------|----------------|
| Merge queue enabled | GraphQL `enqueuePullRequest` | Adds PR to queue, queue handles merge |
| Branch protection (no queue) | `gh pr merge --auto` | Enables auto-merge, GitHub merges when checks pass |
| No branch protection | `gh pr merge --rebase` | Direct merge, no waiting |

### GitHub Actions Auto-merge (Branch Protection)
```yaml
# .github/workflows/auto-merge.yml
# Use when: Branch protection enabled, no merge queue
name: Auto-merge dependency updates

on:
  pull_request_target:
    types: [opened, synchronize, reopened]

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]' || github.actor == 'renovate[bot]'
    steps:
      - name: Harden Runner
        uses: step-security/harden-runner@v2
        with:
          egress-policy: audit

      - name: Auto-approve PR
        run: gh pr review --approve "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Enable auto-merge
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### GitHub Actions Auto-merge (Merge Queue)
```yaml
# .github/workflows/auto-merge-deps.yml
# Use when: Repository has merge queue enabled
# IMPORTANT: mergeMethod is NOT a valid argument for enqueuePullRequest
name: Auto-merge dependency PRs

on:
  pull_request_target:
    types: [opened, synchronize, reopened]

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]' || github.actor == 'renovate[bot]'
    steps:
      - name: Auto-approve PR
        run: gh pr review --approve "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Add to merge queue
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_NODE_ID: ${{ github.event.pull_request.node_id }}
        run: |
          gh api graphql -f query='
            mutation($pullRequestId: ID!) {
              enqueuePullRequest(input: {pullRequestId: $pullRequestId}) {
                mergeQueueEntry { id }
              }
            }' -f pullRequestId="$PR_NODE_ID"
```

### GitHub Actions Auto-merge (No Branch Protection)
```yaml
# .github/workflows/auto-merge-deps.yml
# Use when: No branch protection rules configured
# Note: --auto flag requires branch protection, use direct merge instead
name: Auto-merge dependency PRs

on:
  pull_request_target:
    types: [opened, synchronize, reopened]

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]' || github.actor == 'renovate[bot]'
    steps:
      - name: Auto-approve PR
        run: gh pr review --approve "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Merge PR
        run: gh pr merge --rebase "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Dependabot Auto-merge Metadata
```yaml
# Check metadata for safer auto-merge
- name: Dependabot metadata
  id: metadata
  uses: dependabot/fetch-metadata@v2
  with:
    github-token: "${{ secrets.GITHUB_TOKEN }}"

- name: Auto-merge minor/patch
  if: steps.metadata.outputs.update-type != 'version-update:semver-major'
  run: gh pr merge --auto --squash "$PR_URL"
  env:
    PR_URL: ${{ github.event.pull_request.html_url }}
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Comparison: Dependabot vs Renovate

| Feature | Dependabot | Renovate |
|---------|------------|----------|
| Hosting | GitHub native | Self-hosted or app |
| Configuration | YAML | JSON/JSON5 |
| Grouping | Basic | Advanced |
| Auto-merge | Via workflow | Native support |
| Custom managers | Limited | Regex support |
| Dashboard | Basic | Dependency Dashboard |
| Presets | Limited | Extensive |
| Update types | All | Granular control |

### When to Use Dependabot
- GitHub-only projects
- Simple dependency management
- Native GitHub integration preferred
- Limited configuration needs

### When to Use Renovate
- Complex grouping requirements
- Multiple repositories
- Advanced auto-merge rules
- Custom package managers
- Dependency Dashboard needed
- Cross-platform support

## Best Practices

1. **Group related updates**: Reduce PR noise
2. **Use semantic commit prefixes**: Better changelogs
3. **Enable auto-merge for safe updates**: minor/patch
4. **Require CI checks**: Before auto-merge
5. **Review major updates manually**: Breaking changes
6. **Schedule updates**: Off-peak hours
7. **Label PRs**: Easy filtering
8. **Limit concurrent PRs**: Avoid CI overload
