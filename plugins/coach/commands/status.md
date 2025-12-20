---
description: "Show coach system status and statistics"
---

# Coach Status

Display the current state of the coach learning system.

## Steps

1. Check if coach is initialized:
   ```bash
   ls ~/.claude-coach/events.sqlite 2>/dev/null
   ```

2. If not initialized, suggest running `/coach init`

3. If initialized, gather statistics:

   **Events Database:**
   ```bash
   sqlite3 ~/.claude-coach/events.sqlite "SELECT signal_type, COUNT(*) FROM events GROUP BY signal_type"
   ```

   **Candidates:**
   - Read `~/.claude-coach/candidates.json`
   - Count pending, approved, rejected

   **Recent Activity:**
   ```bash
   sqlite3 ~/.claude-coach/events.sqlite "SELECT * FROM events ORDER BY timestamp DESC LIMIT 5"
   ```

4. Display summary:
   - Total events by type (COMMAND_FAILURE, USER_CORRECTION, etc.)
   - Pending proposals count
   - Approved rules count
   - Recently detected signals
   - Last proposal timestamp
