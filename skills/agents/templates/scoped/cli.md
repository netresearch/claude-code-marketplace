<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: {{TIMESTAMP}} -->

# AGENTS.md — {{SCOPE_NAME}}

## Overview
{{SCOPE_DESCRIPTION}}

Command-line interface tools and entry points.

## Setup & environment
{{SETUP_INSTRUCTIONS}}
- CLI framework: {{CLI_FRAMEWORK}}
- Build output: {{BUILD_OUTPUT_PATH}}

## Build & tests (prefer file-scoped)
- Build CLI: {{BUILD_CMD}}
- Run CLI: {{RUN_CMD}}
- Test: {{TEST_CMD}}
- Lint: {{LINT_CMD}}

## Code style & conventions
- Use flag parsing library consistently ({{CLI_FRAMEWORK}})
- Provide `--help` for all commands and subcommands
- Use `--version` to display version information
- Exit codes: 0 = success, 1 = general error, 2 = usage error
- Output: structured (JSON) for scripts, human-readable for interactive
- Errors: write to stderr, not stdout
- Progress: show for long-running operations
- Interactive prompts: support non-interactive mode with flags

## Security & safety
- Validate all file paths and prevent directory traversal
- Never execute user-provided code without explicit confirmation
- Sensitive data: never log or display in plain text
- Config files: validate schema and permissions
- Network operations: timeout and retry with backoff

## PR/commit checklist
- [ ] `--help` text is clear and accurate
- [ ] `--version` displays correct version
- [ ] Exit codes are correct
- [ ] Errors go to stderr
- [ ] Long operations show progress
- [ ] Works in non-interactive mode
- [ ] Tests cover main workflows

## Good vs. bad examples
**Good**: Proper error handling
```{{LANGUAGE}}
if err := runCommand(); err != nil {
    fmt.Fprintf(os.Stderr, "Error: %v\n", err)
    os.Exit(1)
}
```

**Bad**: Errors to stdout
```{{LANGUAGE}}
if err := runCommand(); err != nil {
    fmt.Println("Error:", err)
}
```

**Good**: Clear help text
```
Usage: myapp <command> [options]

Commands:
  init     Initialize a new project
  build    Build the project
  deploy   Deploy to production

Options:
  --config string   Config file path (default: config.yaml)
  --verbose         Enable verbose output
```

## When stuck
- Review {{CLI_FRAMEWORK}} documentation
- Check existing commands for patterns
- Test with `--help` to ensure clarity
- Check root AGENTS.md for project conventions

## House Rules (optional)
{{HOUSE_RULES}}
