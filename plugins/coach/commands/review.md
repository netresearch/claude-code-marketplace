---
description: "Show pending learning proposals with diffs and rationale"
---

# Coach Review

Analyze and display pending learning candidates from the coach system.

## Steps

1. Read the candidates file:
   ```bash
   cat ~/.claude-coach/candidates.json 2>/dev/null || echo '{"pending":[]}'
   ```

2. **For candidates with `needs_llm_analysis: true` or `candidate_type: "raw_correction"`:**

   These contain raw friction data that needs YOUR analysis. Look at:
   - The `raw_data.message` - what the user said
   - The `raw_data.context_before` - what happened before
   - The `raw_data.patterns_matched` - what patterns were detected

   Analyze and generate a proper proposal:
   - Understand what Claude did wrong
   - Determine the correct behavior
   - Create a specific, actionable rule
   - Set an appropriate confidence score (0.7-0.95)

3. **For other candidates:**
   Display as-is with:
   - ID and title
   - Type (rule/checklist/snippet/skill)
   - Confidence score
   - Evidence that triggered it
   - The proposed trigger and action

4. **Your recommendation for each:**
   Based on your analysis, indicate:
   - ✅ **Recommend approve** - clear pattern, actionable rule
   - ⚠️ **Needs refinement** - good signal but vague proposal
   - ❌ **Recommend reject** - false positive or too specific

5. Show available actions:
   - `/coach:approve <id>` - Accept and apply this proposal
   - `/coach:edit <id>` - Modify before approving
   - `/coach:reject <id> <reason>` - Reject with reason

Format output as a clear, readable summary. Group by recommendation.
