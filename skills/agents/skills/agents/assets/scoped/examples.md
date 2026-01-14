<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: {{TIMESTAMP}} -->

# AGENTS.md — {{SCOPE_NAME}}

## Overview
{{SCOPE_DESCRIPTION}}

Example applications, usage patterns, and sample code.

## Setup & environment
- Examples should be self-contained and runnable
- Each example may have its own dependencies (check local README)
- Examples should work with the current version of the main package

## Running examples
- Check each example's README for specific instructions
- Most examples: `cd example-name && follow README`
- Some examples may require environment setup

## Example organization
- One directory per example/use case
- Each example has its own README explaining what it demonstrates
- Keep examples focused on one concept or pattern
- Name examples descriptively: `basic-usage/`, `advanced-config/`, `integration-with-x/`

## Code style & conventions
- Examples should be educational and well-commented
- Use realistic but simplified scenarios
- Show best practices, not shortcuts
- Include error handling to demonstrate proper patterns
- Keep examples minimal - only what's needed to demonstrate the concept
- Avoid complex setups that distract from the main point

## Documentation requirements
- Each example needs a README with:
  - What this example demonstrates
  - Prerequisites and setup steps
  - How to run the example
  - Expected output or behavior
  - Links to relevant documentation

## Security & safety
- Never include real API keys or credentials
- Use environment variables for sensitive config: `export API_KEY=your-key`
- Use sandbox/test environments when interacting with external services
- Include warnings for examples that make real API calls

## PR/commit checklist
- [ ] Example runs successfully
- [ ] README is complete and accurate
- [ ] No hardcoded credentials
- [ ] Code demonstrates best practices
- [ ] Comments explain non-obvious parts
- [ ] Example works with current package version

## Good vs. bad examples
**Good**: Self-contained with clear purpose
```
examples/
├── basic-usage/
│   ├── README.md      # Explains purpose and how to run
│   ├── main.py        # Complete, runnable example
│   └── requirements.txt
└── advanced-config/
    ├── README.md
    └── main.py
```

**Bad**: Incomplete or unclear
```
examples/
├── example1.py        # No README, unclear purpose
├── test.py            # Naming doesn't explain what it shows
└── demo.py            # Requires undocumented setup
```

**Good**: Educational comments
```python
# This example shows how to configure retry behavior
# for handling transient network failures

from mypackage import Client

# Configure with exponential backoff (recommended for production)
client = Client(
    retries=3,           # Number of retry attempts
    backoff_factor=2.0,  # Exponential backoff multiplier
)
```

**Bad**: No context
```python
from mypackage import Client
client = Client(retries=3, backoff_factor=2.0)
```

## When stuck
- Check similar examples for patterns
- Ensure the example is self-contained
- Test the example from scratch (fresh environment)
- Check root AGENTS.md for project conventions

## House Rules (optional)
{{HOUSE_RULES}}
