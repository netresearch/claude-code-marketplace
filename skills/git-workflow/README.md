# Git Workflow Skill

Expert patterns for Git version control workflows including branching strategies, commit conventions, collaborative workflows, and CI/CD integration.

## 🔌 Compatibility

This is an **Agent Skill** following the [open standard](https://agentskills.io) originally developed by Anthropic and released for cross-platform use.

**Supported Platforms:**
- ✅ Claude Code (Anthropic)
- ✅ Cursor
- ✅ GitHub Copilot
- ✅ Other skills-compatible AI agents

> Skills are portable packages of procedural knowledge that work across any AI agent supporting the Agent Skills specification.


## Features

- **Branching Strategies**: Git Flow (feature/release/hotfix branches), GitHub Flow (simple feature branches), trunk-based development, release management patterns
- **Commit Conventions**: Conventional Commits standard, semantic versioning integration, commit message best practices, atomic commit patterns
- **Collaborative Workflows**: Pull request best practices, code review processes, merge strategies (merge, squash, rebase), conflict resolution patterns
- **CI/CD Integration**: GitHub Actions workflows, GitLab CI patterns, branch protection rules, automated versioning
- **Git Hooks**: Pre-commit hooks for linting and testing, commit message validation
- **Advanced Operations**: Interactive rebase, cherry-picking, stashing, reflog recovery

## Installation

### Option 1: Via Netresearch Marketplace (Recommended)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

### Option 2: Download Release

Download the [latest release](https://github.com/netresearch/git-workflow-skill/releases/latest) and extract to `~/.claude/skills/git-workflow-skill/`

### Option 3: Composer (PHP projects)

```bash
composer require netresearch/agent-git-workflow-skill
```

**Requires:** [netresearch/composer-agent-skill-plugin](https://github.com/netresearch/composer-agent-skill-plugin)

## Usage

This skill is automatically triggered when:

- Establishing branching strategies (Git Flow, GitHub Flow, Trunk-based)
- Implementing Conventional Commits for semantic versioning
- Configuring pull request workflows
- Integrating Git with CI/CD systems
- Setting up Git hooks for quality gates
- Resolving merge conflicts
- Configuring branch protection rules

Example queries:
- "Set up Git Flow workflow"
- "Configure conventional commits with semantic versioning"
- "Create GitHub Actions workflow for CI/CD"
- "Set up pre-commit hooks for linting"
- "Configure branch protection rules"
- "Implement pull request review process"

## Structure

```
git-workflow-skill/
├── SKILL.md                              # Skill metadata and core patterns
├── references/
│   ├── branching-strategies.md           # Branch management patterns
│   ├── commit-conventions.md             # Commit message standards
│   ├── pull-request-workflow.md          # PR and review processes
│   ├── ci-cd-integration.md              # Automation patterns
│   └── advanced-git.md                   # Advanced Git operations
└── scripts/
    └── verify-git-workflow.sh            # Verification script
```

## Expertise Areas

### Branching Strategies
- Git Flow (feature/release/hotfix branches)
- GitHub Flow (simple feature branches)
- Trunk-based development
- Release management patterns

### Commit Conventions
- Conventional Commits standard
- Semantic versioning integration
- Commit message best practices
- Atomic commit patterns

### Collaborative Workflows
- Pull request best practices
- Code review processes
- Merge strategies (merge, squash, rebase)
- Conflict resolution patterns

### CI/CD Integration
- GitHub Actions workflows
- GitLab CI patterns
- Branch protection rules
- Automated versioning

## Conventional Commits Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature (MINOR version bump)
- `fix`: Bug fix (PATCH version bump)
- `docs`: Documentation only
- `style`: Code style (formatting, no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding/updating tests
- `build`: Build system changes
- `ci`: CI configuration changes
- `chore`: Maintenance tasks
- `revert`: Reverting changes

**Breaking Changes:**
```
feat!: remove deprecated API endpoints

BREAKING CHANGE: The /api/v1/users endpoint has been removed.
Use /api/v2/users instead.
```

## Quick Reference

### Daily Workflow

```bash
# Start of day
git checkout main && git pull
git checkout -b feature/my-feature

# During development
git add -p                    # Stage hunks interactively
git commit -m "feat: ..."     # Commit with conventional message

# Ready for review
git push -u origin HEAD
gh pr create

# After merge
git checkout main && git pull
git branch -d feature/my-feature
```

### Emergency Fixes

```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Revert a specific commit
git revert <commit-hash>

# Fix last commit message
git commit --amend -m "new message"

# Fix last commit (add forgotten file)
git add forgotten-file.txt
git commit --amend --no-edit
```

## Related Skills

- **enterprise-readiness-skill**: Git workflow is part of CI/CD maturity
- **security-audit-skill**: Git hooks for security checks

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

Developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/).

---

**Made with ❤️ for Open Source by [Netresearch](https://www.netresearch.de/)**
