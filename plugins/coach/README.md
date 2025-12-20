# Coach Plugin

Self-improving learning system for Claude Code that detects friction signals and proposes rule updates.

## Features

- **Signal Detection**: Automatically detects user corrections, tool failures, repeated instructions, and tone escalation
- **LLM-Assisted Generation**: Uses Claude Haiku to generate specific, actionable learning candidates
- **Transcript Analysis**: Analyzes full session transcripts at session end for comprehensive learning
- **Cross-Repo Learning**: Tracks patterns across repositories and proposes promotion to global rules
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
