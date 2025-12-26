# Context7 Documentation Lookup Skill

Fetch up-to-date library documentation via Context7 REST API. Lightweight alternative to Context7 MCP with no persistent context overhead.

## Features

- **No MCP Overhead** - Uses REST API directly, no tool schemas consuming context
- **Current Documentation** - Fetches live docs from Context7's curated database
- **Topic Filtering** - Focus on specific areas (hooks, routing, middleware, etc.)
- **50+ Libraries** - React, Next.js, Vue, Express, Prisma, and more

## Installation

### Option 1: Via Netresearch Marketplace (Recommended)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

Then browse skills with `/plugin`.

### Option 2: Download Release

Download the [latest release](https://github.com/netresearch/context7-skill/releases/latest) and extract to `~/.claude/skills/context7/`

### Option 3: Composer (PHP projects)

```bash
composer require netresearch/agent-context7
```

**Requires:** [netresearch/composer-agent-skill-plugin](https://github.com/netresearch/composer-agent-skill-plugin)

## Usage

The skill triggers on keywords like:
- "how do I use [library]"
- "what's the API for [library]"
- "[library] documentation"
- "show me [library] patterns"

### Example Prompts

```
"How do I use React hooks?"
"What's the Next.js App Router API?"
"Show me Prisma query patterns"
"Express middleware documentation"
```

### Manual Script Usage

```bash
# Search for a library ID
scripts/context7.sh search "prisma"

# Fetch documentation with topic
scripts/context7.sh docs "/prisma/prisma" "queries"
```

## Structure

```
context7/
├── SKILL.md              # AI instructions
├── README.md             # This file
├── LICENSE               # MIT license
├── scripts/              # Automation scripts
│   └── context7.sh       # REST API wrapper
└── .github/
    └── workflows/
        └── release.yml   # Release packaging
```

## Why Use This Over Context7 MCP?

| Aspect | MCP Server | This Skill |
|--------|------------|------------|
| Context cost | ~500-2000 tokens always | ~100 tokens on-demand |
| Tool schemas | Always in context | None |
| Invocation | Model decides | Model decides |
| API access | Via MCP protocol | Direct REST API |

Best for: Users who occasionally need library docs but don't want persistent context overhead.

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `CONTEXT7_API_KEY` | No | API key for higher rate limits |

## Contributing

Contributions welcome! Please submit PRs for:
- Adding common library IDs
- Improving script error handling
- Documentation updates

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

- Context7 API by [Upstash](https://upstash.com/)
- Skill developed by [Netresearch DTT GmbH](https://www.netresearch.de/)

---

**Made with love for Open Source by [Netresearch](https://www.netresearch.de/)**
