<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: {{TIMESTAMP}} -->

# AGENTS.md — {{SCOPE_NAME}}

## Overview
{{SCOPE_DESCRIPTION}}

Project documentation, guides, and reference materials.

## Setup & environment
- Documentation may use a static site generator (check for config files)
- Preview locally before committing major changes
- Check for broken links and formatting issues

## Building docs
- Preview: check for `npm run docs`, `make docs`, or similar
- Build: check for documentation build commands in root
- Serve locally to verify rendering

## Documentation structure
- `README.md` - Entry point, project overview
- `getting-started/` - Installation and quick start guides
- `guides/` - How-to guides and tutorials
- `reference/` - API documentation, configuration reference
- `architecture/` - Design documents, ADRs
- `contributing/` - Contribution guidelines

## Code style & conventions
- Use clear, concise language
- Include code examples for technical concepts
- Keep line length reasonable (~80-120 chars for readability)
- Use consistent heading hierarchy (H1 for page title, H2 for sections)
- Add alt text to images for accessibility
- Use relative links for internal references
- Keep code examples up-to-date with actual codebase

## Markdown best practices
- Use fenced code blocks with language hints: \`\`\`python
- Use tables for structured data comparison
- Use admonitions for warnings/notes (if supported)
- Keep paragraphs focused on one idea
- Use bullet points for lists, numbered lists for sequences

## Security & safety
- Never include secrets, API keys, or credentials in examples
- Use placeholder values: `your-api-key`, `example.com`
- Review screenshots for sensitive information
- Avoid documenting security vulnerabilities in detail

## PR/commit checklist
- [ ] Documentation matches current code behavior
- [ ] Code examples are tested and work
- [ ] Links are valid (no 404s)
- [ ] Images have alt text
- [ ] Spelling and grammar checked
- [ ] Formatting renders correctly

## Good vs. bad examples
**Good**: Clear code example
```python
# Install the package
pip install mypackage

# Basic usage
from mypackage import Client
client = Client(api_key="your-api-key")
result = client.process("input")
```

**Bad**: Incomplete example
```python
# Use the client
client.process()  # Missing context, imports, setup
```

**Good**: Structured reference
```markdown
## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `timeout` | int | 30 | Request timeout in seconds |
| `retries` | int | 3 | Number of retry attempts |
```

**Bad**: Unstructured reference
```markdown
Set timeout to change the timeout. Use retries for retries.
```

## When stuck
- Check existing documentation for patterns
- Review the style guide (if one exists)
- Preview changes locally before committing
- Check root AGENTS.md for project conventions

## House Rules (optional)
{{HOUSE_RULES}}
