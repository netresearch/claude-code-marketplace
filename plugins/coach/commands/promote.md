---
description: "Promote a project rule to global scope"
---

# Coach Promote

Move an approved project-scope rule to global scope.

## Arguments

- `<id>` - The candidate ID to promote

## Steps

1. Read `~/.claude-coach/candidates.json` and find the candidate

2. Verify it's currently project-scoped and approved

3. Read the rule from `<repo>/.claude/CLAUDE.md`

4. Add the rule to `~/.claude/CLAUDE.md` under appropriate section

5. Optionally remove from project CLAUDE.md (ask user)

6. Update candidate scope to "global" in candidates.json

7. Confirm promotion to user

This is useful when a pattern learned in one project should apply everywhere.
