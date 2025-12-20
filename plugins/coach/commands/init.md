---
description: "Initialize the coach learning system"
---

# Coach Init

Initialize the coach system for the current environment.

## Steps

1. Run the initialization script:
   ```bash
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/init_coach.py
   ```

2. This creates:
   - `~/.claude-coach/` directory
   - `events.sqlite` database for friction signals
   - `ledger.sqlite` database for cross-repo fingerprints
   - `candidates.json` for pending proposals
   - `config.json` for settings

3. Verify the hooks are active (should be auto-configured by plugin)

4. Confirm initialization to user with:
   - Created file locations
   - How signals will be detected
   - Next steps (just use Claude normally, coach will learn)

If already initialized, report current status instead.
