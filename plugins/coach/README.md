# Coach Plugin

Self-improving learning system for Claude Code that detects friction signals and proposes rule updates.

## 🔌 Compatibility

This is an **Agent Skill** following the [open standard](https://agentskills.io) originally developed by Anthropic and released for cross-platform use.

**Supported Platforms:**
- ✅ Claude Code (Anthropic)
- ✅ Cursor
- ✅ GitHub Copilot
- ✅ Other skills-compatible AI agents

> Skills are portable packages of procedural knowledge that work across any AI agent supporting the Agent Skills specification.


## Features

- **Signal Detection**: Automatically detects user corrections, tool failures, repeated instructions, and tone escalation
- **Skill Update Suggestions**: Detects when users supplement skills with additional guidance and proposes skill updates
- **Outdated Tool Detection**: Identifies deprecated tools and outdated dependencies from command output
- **LLM-Assisted Generation**: Uses Claude Haiku to generate specific, actionable learning candidates
- **Transcript Analysis**: Analyzes full session transcripts at session end for comprehensive learning
- **Cross-Repo Learning**: Tracks patterns across repositories and proposes promotion to global rules
- **Proactive Scanning**: `/coach scan` checks for outdated CLI tools and project dependencies
- **Approval Workflow**: All changes require explicit user approval

## Installation

Install via Claude Code plugin marketplace or manually:

```bash
claude plugins add netresearch/claude-coach-plugin
```

## Slash Commands

| Command | Description |
|---------|-------------|
| `/coach status` | Show system status and statistics |
| `/coach review` | Show pending learning proposals |
| `/coach approve <id>` | Approve and apply a proposal |
| `/coach reject <id>` | Reject a proposal with reason |
| `/coach edit <id>` | Edit a proposal before approving |
| `/coach promote <id>` | Promote project rule to global |
| `/coach scan` | Scan for outdated tools and dependencies |
| `/coach init` | Initialize the coach system |

## How It Works

1. **Hooks** detect friction signals as you work:
   - `UserPromptSubmit`: Detects corrections and repetition in user messages
   - `PostToolUse`: Captures command failures with exit codes
   - `Stop`: Runs full aggregation at session end

2. **Signals** are stored in `~/.claude-coach/events.sqlite`

3. **Candidates** are generated from patterns in signals

4. **Review** candidates with `/coach review` and approve/reject

5. **Rules** are added to your CLAUDE.md files

## Configuration

The plugin auto-configures hooks. For manual configuration or customization, see `hooks/hooks.json`.

## License

MIT
