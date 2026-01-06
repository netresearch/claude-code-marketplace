# Git Branching Strategies

## Git Flow

### Overview

Git Flow is a branching model designed for projects with scheduled releases.

```
main ─────●─────────────────●─────────────────●─────── (production)
          │                 │                 │
          │    release/1.0  │    release/1.1  │
          │    ┌───●───●────┤    ┌───●───●────┤
          │    │            │    │            │
develop ──●────●────●───●───●────●────●───●───●─────── (integration)
               │    │        │    │    │
               │    │        │    │    └── feature/C
               │    └────────┴────┴─────── feature/B
               └─────────────────────────── feature/A
```

### Branch Types

| Branch | Purpose | Created From | Merges To |
|--------|---------|--------------|-----------|
| `main` | Production code | - | - |
| `develop` | Integration | `main` | `release` |
| `feature/*` | New features | `develop` | `develop` |
| `release/*` | Release prep | `develop` | `main`, `develop` |
| `hotfix/*` | Emergency fixes | `main` | `main`, `develop` |

### Commands

```bash
# Initialize
git flow init

# Feature
git flow feature start user-auth
git flow feature publish user-auth    # Push to remote
git flow feature finish user-auth

# Release
git flow release start 1.2.0
git flow release publish 1.2.0
git flow release finish 1.2.0

# Hotfix
git flow hotfix start 1.2.1
git flow hotfix finish 1.2.1
```

### When to Use

**Good for:**
- Scheduled release cycles
- Long-lived feature branches
- Multiple versions in production
- Teams with dedicated release managers

**Avoid when:**
- Continuous deployment
- Small teams
- Rapid iteration needed

## GitHub Flow

### Overview

Simplified workflow ideal for continuous deployment.

```
main ───●───●───────────●───────●───●─── (always deployable)
        │   │           │       │   │
        │   └── PR #2 ──┘       │   └── PR #4
        │                       │
        └───── PR #1 ───────────┴─────── PR #3
```

### Rules

1. `main` is always deployable
2. Create descriptive feature branches from `main`
3. Push commits regularly
4. Open PR for discussion/review
5. Merge after review and CI passes
6. Deploy immediately after merge

### Workflow

```bash
# 1. Start feature
git checkout main
git pull origin main
git checkout -b add-user-notifications

# 2. Develop with regular commits
git add .
git commit -m "feat: add notification service"
git push -u origin add-user-notifications

# 3. Create PR
gh pr create --title "Add user notifications" \
  --body "Implements email and push notifications for users"

# 4. Address review feedback
git add .
git commit -m "fix: address review comments"
git push

# 5. Merge (after approval and CI)
gh pr merge --squash --delete-branch

# 6. Deploy (automatic via CI/CD)
```

### When to Use

**Good for:**
- Continuous deployment
- Web applications
- Small to medium teams
- Fast iteration cycles

**Avoid when:**
- Multiple versions in production
- Scheduled releases required

## Trunk-Based Development

### Overview

All developers work on a single branch with short-lived feature branches.

```
main ───●───●───●───●───●───●───●───●───●───●─── (trunk)
        │   │       │       │   │       │
        └─┬─┘       └───┬───┘   └───┬───┘
          │             │           │
        small         small       small
        feature       feature     feature
        (< 1 day)     (< 1 day)   (< 1 day)
```

### Principles

1. **Single branch**: All code goes to `main`/`trunk`
2. **Short-lived branches**: Max 1-2 days
3. **Feature flags**: Hide incomplete features
4. **Continuous integration**: Merge multiple times per day
5. **No long-running branches**: Avoid merge conflicts

### Workflow

```bash
# Start small feature (should complete today)
git checkout main
git pull
git checkout -b small-feature

# Work in small increments
git add .
git commit -m "feat: add basic structure"
git push

# Merge quickly (within hours/day)
gh pr create --title "Small feature"
gh pr merge --rebase

# Feature flags for incomplete work
if (featureFlags.isEnabled('new-checkout')) {
    // New checkout flow
} else {
    // Existing checkout flow
}
```

### Release Strategies

```bash
# Option 1: Release from trunk
git tag v1.2.0
git push origin v1.2.0

# Option 2: Release branches (for fixes)
git checkout -b release/1.2 main
# Cherry-pick fixes if needed
git cherry-pick <fix-commit>
git tag v1.2.1
```

### When to Use

**Good for:**
- Mature CI/CD pipelines
- High test coverage
- Experienced teams
- Microservices

**Avoid when:**
- Junior-heavy teams
- Low test coverage
- Multiple long-term versions

## GitLab Flow

### Overview

Combines feature branches with environment branches.

```
main ─────●─────●─────●─────●─────●───── (development)
          │     │     │     │     │
          ▼     ▼     ▼     ▼     ▼
staging ──●─────●─────●─────●─────●───── (staging env)
                │           │     │
                ▼           ▼     ▼
production ─────●───────────●─────●───── (production env)
```

### Environment Branches

```bash
# Feature development
git checkout -b feature/new-api main
# ... develop ...
git checkout main
git merge feature/new-api

# Promote to staging
git checkout staging
git merge main

# Promote to production (after staging verification)
git checkout production
git merge staging
git tag v1.2.0
```

### With Release Branches

```bash
# Support multiple versions
main
├── release/1.x
│   ├── 1.0.0
│   ├── 1.0.1
│   └── 1.1.0
└── release/2.x
    ├── 2.0.0
    └── 2.0.1
```

## Choosing a Strategy

### Decision Matrix

| Factor | Git Flow | GitHub Flow | Trunk-Based | GitLab Flow |
|--------|----------|-------------|-------------|-------------|
| Release frequency | Scheduled | Continuous | Continuous | Environment-based |
| Team size | Large | Small-Medium | Any | Any |
| Version support | Multiple | Single | Single | Multiple |
| Branch complexity | High | Low | Very Low | Medium |
| CI/CD maturity | Any | Medium | High | Medium |
| Merge conflicts | More | Less | Least | Medium |

### Quick Guide

```
Need scheduled releases?
├── Yes → Multiple versions in production?
│         ├── Yes → Git Flow
│         └── No  → GitLab Flow (with releases)
└── No  → Continuous deployment ready?
          ├── Yes → High test coverage?
          │         ├── Yes → Trunk-Based
          │         └── No  → GitHub Flow
          └── No  → GitHub Flow
```

## Branch Protection

### GitHub Branch Protection Rules

```yaml
# Settings > Branches > Branch protection rules
main:
  require_pull_request:
    required_approving_reviews: 2
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
  require_status_checks:
    strict: true
    contexts:
      - "ci/lint"
      - "ci/test"
      - "ci/build"
  require_conversation_resolution: true
  require_signed_commits: false
  include_administrators: true
  allow_force_pushes: false
  allow_deletions: false
```

### GitLab Protected Branches

```yaml
# Settings > Repository > Protected branches
main:
  allowed_to_push:
    - role: maintainer
  allowed_to_merge:
    - role: developer
  allowed_to_force_push: false
  code_owner_approval_required: true
```

## Migration Between Strategies

### Git Flow → GitHub Flow

```bash
# 1. Merge develop to main
git checkout main
git merge develop

# 2. Delete develop branch
git branch -d develop
git push origin --delete develop

# 3. Update CI/CD to deploy from main
# 4. Communicate new workflow to team
# 5. Update branch protection rules
```

### GitHub Flow → Trunk-Based

```bash
# 1. Implement feature flags
# 2. Increase test coverage
# 3. Set up continuous deployment
# 4. Shorten PR review cycle
# 5. Enforce small, frequent merges
```
