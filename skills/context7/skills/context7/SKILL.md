---
name: context7
description: "Fetch up-to-date library documentation via Context7 REST API. Use when needing current API docs, framework patterns, or code examples for any library. Lightweight alternative to Context7 MCP with no persistent context overhead. By Netresearch."
---

# Context7 Documentation Lookup Skill

Fetch current library documentation, API references, and code examples without MCP context overhead.

## When to Use

- User asks about library APIs or framework patterns
- Import statements: `import`, `require`, `from`
- Questions about specific library versions
- "How do I use X library?", "What's the API for Y?"

## Workflow

### Step 1: Search for Library ID

```bash
scripts/context7.sh search "library-name"
```

Output shows library IDs (e.g., `/facebook/react`).

### Step 2: Fetch Documentation

```bash
scripts/context7.sh docs "<library-id>" "[topic]" "[mode]"
```

- `library-id`: From search (e.g., `/facebook/react`)
- `topic`: Optional focus (e.g., `hooks`, `routing`)
- `mode`: `code` (default) or `info` for guides

### Step 3: Apply to User's Question

Use returned documentation for accurate, version-specific answers with official patterns.

## Script Reference

| Command | Purpose |
|---------|---------|
| `search` | Find library ID |
| `docs` | Fetch documentation |

## Documentation Modes

| Mode | Use For |
|------|---------|
| `code` | API references, examples (default) |
| `info` | Conceptual guides, tutorials |

---

> **Contributing:** https://github.com/netresearch/context7-skill
