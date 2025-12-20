---
description: "Edit a learning proposal before approving"
---

# Coach Edit

Modify a pending learning candidate before approval.

## Arguments

- `<id>` - The candidate ID to edit

## Steps

1. Read `~/.claude-coach/candidates.json` and find the candidate by ID

2. Display the current candidate:
   - Title
   - Trigger (when condition)
   - Action (what to do)
   - Type (rule/checklist/snippet)
   - Scope (project/global)

3. Ask user what they want to change:
   - Title?
   - Trigger condition?
   - Action description?
   - Scope?

4. Update the candidate with new values

5. Save to candidates.json

6. Show the updated candidate and ask if they want to `/coach approve <id>` now
