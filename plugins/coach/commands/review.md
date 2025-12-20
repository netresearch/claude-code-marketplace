---
description: "Show pending learning proposals with diffs and rationale"
---

# Coach Review

Display all pending learning candidates from the coach system.

## Steps

1. Read the candidates file:
   ```bash
   cat ~/.claude-coach/candidates.json
   ```

2. For each candidate with status "pending", display:
   - ID and title
   - Type (rule/checklist/snippet/antipattern)
   - Confidence score
   - Evidence quotes that triggered it
   - The proposed trigger and action

3. Show available actions:
   - `/coach approve <id>` - Accept and apply this proposal
   - `/coach edit <id>` - Modify before approving
   - `/coach reject <id>` - Reject with reason

Format output as a clear, readable summary for each pending proposal.
