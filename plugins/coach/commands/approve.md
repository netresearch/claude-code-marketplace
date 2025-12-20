---
description: "Approve and apply a learning proposal"
---

# Coach Approve

Approve a pending learning candidate and apply it to CLAUDE.md.

## Arguments

- `<id>` - The candidate ID to approve (e.g., "a1b2c3d4")

## Steps

1. Read `~/.claude-coach/candidates.json` and find the candidate by ID

2. Determine target location based on candidate scope:
   - Project scope → `<repo>/.claude/CLAUDE.md`
   - Global scope → `~/.claude/CLAUDE.md`

3. Apply the proposal using the apply script:
   ```bash
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/apply.py <id>
   ```

4. Update the candidate status to "approved" in candidates.json

5. Confirm to user:
   - What rule was added
   - Where it was added (project/global)
   - The trigger and action

If the candidate ID is not found, list available pending candidates.
