---
description: Scan project for outdated tools and dependencies
---

# /coach scan

Proactively scan the project for outdated tools and dependencies.

## Steps

1. Run the skill analyzer scan:
   ```bash
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/skill_analyzer.py --scan --verbose
   ```

2. Review the findings:
   - **Outdated CLI tools**: Core tools (node, npm, python, go, docker, gh) below recommended versions
   - **Outdated npm packages**: Dependencies that have newer versions available
   - **Outdated pip packages**: Python dependencies that need updating
   - **Installed skills**: List of skills available for potential updates

3. For each finding, generate a learning candidate if appropriate:
   - Tool updates → snippet candidates
   - Deprecated tools → rule candidates

4. Report summary to user:
   - Number of outdated tools/packages found
   - Specific upgrade recommendations
   - Any generated candidates for `/coach review`

## Example Output

```
Scanning project dependencies...
Checking installed skills...

Findings:
  Outdated tools/packages: 3
  Installed skills: 5
  Generated candidates: 2

  Tool/Package Issues:
    - node: 16.0 → 18+ (recommended)
    - lodash: 4.17.20 → 4.17.21
    - axios: 0.21.4 → 1.6.2

Run /coach review to see generated update candidates.
```
