---
description: "Reject a learning proposal with reason"
---

# Coach Reject

Reject a pending learning candidate with an optional reason.

## Arguments

- `<id>` - The candidate ID to reject
- `[reason]` - Optional reason for rejection

## Steps

1. Read `~/.claude-coach/candidates.json` and find the candidate by ID

2. Update the candidate:
   - Set status to "rejected"
   - Add rejection_reason if provided
   - Add rejected_at timestamp

3. Save the updated candidates.json

4. Confirm to user what was rejected and why

If no reason provided, ask the user for a brief rejection reason to help improve future candidate generation.
