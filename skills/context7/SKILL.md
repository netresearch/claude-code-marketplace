---
name: context7
description: "Fetch up-to-date library documentation via Context7 REST API. Use when needing current API docs, framework patterns, or code examples for any library. Lightweight alternative to Context7 MCP with no persistent context overhead. By Netresearch."
---

# Context7 Documentation Lookup Skill

Fetch current library documentation, API references, and code examples without MCP context overhead.

## When to Use

Activate when:
- User asks about library APIs or framework patterns
- Import statements suggest documentation needs: `import`, `require`, `from`
- Questions about specific library versions or migration
- Need for official documentation patterns vs generic solutions
- "How do I use X library?", "What's the API for Y?"

## Workflow

### Step 1: Search for Library ID

Always search first to get the correct library ID:
```bash
scripts/context7.sh search "library-name"
```

Example output shows library IDs you can use:
```
ID: /facebook/react
Name: React
Snippets: 2135 | Score: 79.4
```

### Step 2: Fetch Documentation

```bash
scripts/context7.sh docs "<library-id>" "[topic]" "[mode]"
```

**Parameters:**
- `library-id`: From search results (e.g., `/facebook/react`)
- `topic`: Optional focus area (e.g., `hooks`, `routing`)
- `mode`: `code` (default) for API/examples, `info` for guides

**Examples:**
```bash
# Get React hooks documentation
scripts/context7.sh docs "/facebook/react" "hooks"

# Get Next.js routing docs
scripts/context7.sh docs "/vercel/next.js" "routing"

# Get conceptual guide (info mode)
scripts/context7.sh docs "/vercel/next.js" "app router" info
```

### Step 3: Apply to User's Question

Use the returned documentation to:
1. Provide accurate, version-specific answers
2. Show official code patterns and examples
3. Reference correct API signatures
4. Include relevant caveats or deprecations

## Script Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `search` | Find library ID | `scripts/context7.sh search "prisma"` |
| `docs` | Fetch documentation | `scripts/context7.sh docs "/prisma/prisma" "queries"` |

## Documentation Modes

| Mode | Use For |
|------|---------|
| `code` | API references, code examples, function signatures (default) |
| `info` | Conceptual guides, tutorials, architecture docs |

## Example Workflow

```bash
# User asks: "How do I use React hooks?"

# Step 1: Search for React
scripts/context7.sh search "react"
# Output shows: ID: /facebook/react

# Step 2: Fetch hooks docs
scripts/context7.sh docs "/facebook/react" "hooks"

# Step 3: Use the returned documentation to answer
```

## Error Handling

If the script fails:
1. Verify `jq` and `curl` are installed
2. Check the library ID format (`/org/project`)
3. Try a broader topic or no topic filter
4. Try `info` mode if `code` returns nothing
5. Check network connectivity

## Notes

- **No MCP overhead**: Uses REST API directly, no tool schemas in context
- **API key optional**: Works without key, but rate-limited
- **Topic filtering**: Use specific topics for focused results
- **Search first**: Always search to find the correct library ID
- **Caching**: Results are not cached; each call fetches fresh data

---

> **Contributing:** Improvements to this skill should be submitted to the source repository:
> https://github.com/netresearch/context7-skill
