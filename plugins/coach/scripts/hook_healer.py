#!/usr/bin/env python3
"""
Hook path self-healing module.

Automatically installs stable hook paths when scripts are run from versioned paths.
This ensures hooks survive plugin version updates without user intervention.
"""

import json
import re
import shutil
from pathlib import Path

COACH_DIR = Path.home() / ".claude-coach"
COACH_BIN_DIR = COACH_DIR / "bin"
LAUNCHER_PATH = COACH_BIN_DIR / "coach-run"
CLAUDE_SETTINGS = Path.home() / ".claude" / "settings.json"
INSTALLED_PLUGINS = Path.home() / ".claude" / "plugins" / "installed_plugins.json"

# Marker file to track if we've already healed this session
HEALED_MARKER = COACH_DIR / ".hooks_healed"


def get_plugin_root() -> Path | None:
    """Get the current coach plugin install path from installed_plugins.json."""
    if not INSTALLED_PLUGINS.exists():
        return None
    try:
        data = json.loads(INSTALLED_PLUGINS.read_text())
        plugins = data.get("plugins", {})
        coach_entry = plugins.get("coach@netresearch-claude-code-marketplace", [{}])[0]
        install_path = coach_entry.get("installPath")
        if install_path:
            return Path(install_path)
    except Exception:
        pass
    return None


def is_launcher_current() -> bool:
    """Check if the launcher exists and is from current plugin version."""
    if not LAUNCHER_PATH.exists():
        return False

    plugin_root = get_plugin_root()
    if not plugin_root:
        return True  # Can't verify, assume it's fine

    source_launcher = plugin_root / "bin" / "coach-run"
    if not source_launcher.exists():
        return True  # No source to compare, assume it's fine

    # Compare file contents
    try:
        return LAUNCHER_PATH.read_bytes() == source_launcher.read_bytes()
    except Exception:
        return False


def install_launcher() -> bool:
    """Install the coach-run launcher to stable path."""
    plugin_root = get_plugin_root()
    if not plugin_root:
        # Fallback: use script's location to find plugin root
        plugin_root = Path(__file__).parent.parent

    source_launcher = plugin_root / "bin" / "coach-run"
    if not source_launcher.exists():
        return False

    try:
        COACH_BIN_DIR.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_launcher, LAUNCHER_PATH)
        LAUNCHER_PATH.chmod(0o755)
        return True
    except Exception:
        return False


def update_settings_hooks() -> bool:
    """Update ~/.claude/settings.json hooks to use stable paths."""
    if not CLAUDE_SETTINGS.exists():
        return True

    try:
        settings = json.loads(CLAUDE_SETTINGS.read_text())
    except Exception:
        return False

    hooks = settings.get("hooks", {})
    if not hooks:
        return True

    stable_launcher = str(LAUNCHER_PATH)
    updated = False

    # Pattern to match versioned coach plugin paths
    version_pattern = re.compile(
        r"python3\s+[^\s]*plugins/cache/[^/]+/coach/[^/]+/scripts/(\w+\.py)"
    )

    def update_command(cmd: str) -> str:
        """Replace versioned path with stable launcher using async mode."""
        match = version_pattern.search(cmd)
        if match:
            script_name = match.group(1)
            # Extract args after the script path
            script_pos = cmd.find(script_name)
            args_part = cmd[script_pos + len(script_name):]
            # Use --async for non-blocking hook execution
            return f"{stable_launcher} --async {script_name}{args_part}"
        return cmd

    for hook_type, hook_list in hooks.items():
        if not isinstance(hook_list, list):
            continue
        for entry in hook_list:
            if not isinstance(entry, dict):
                continue
            inner_hooks = entry.get("hooks", [])
            for hook in inner_hooks:
                if hook.get("type") == "command" and "coach" in hook.get("command", ""):
                    old_cmd = hook["command"]
                    new_cmd = update_command(old_cmd)
                    if new_cmd != old_cmd:
                        hook["command"] = new_cmd
                        updated = True

    if updated:
        try:
            CLAUDE_SETTINGS.write_text(json.dumps(settings, indent=2))
            return True
        except Exception:
            return False

    return True


def ensure_stable_hooks() -> None:
    """
    Ensure hooks use stable paths. Call this at script startup.

    This function is idempotent and fast - it only does work once per session
    and when the launcher is missing or outdated.
    """
    # Quick check: if marker exists and is recent, skip
    try:
        if HEALED_MARKER.exists():
            # Check if marker is from this plugin version
            plugin_root = get_plugin_root()
            if plugin_root:
                marker_data = json.loads(HEALED_MARKER.read_text())
                if marker_data.get("plugin_path") == str(plugin_root):
                    return  # Already healed for this version
    except Exception:
        pass

    # Check if launcher needs updating
    if not is_launcher_current():
        if install_launcher():
            update_settings_hooks()

    # Update marker
    try:
        COACH_DIR.mkdir(parents=True, exist_ok=True)
        plugin_root = get_plugin_root()
        HEALED_MARKER.write_text(json.dumps({
            "plugin_path": str(plugin_root) if plugin_root else None,
            "launcher_path": str(LAUNCHER_PATH)
        }))
    except Exception:
        pass


# Auto-run on import for scripts that import this module
# This is intentionally commented out - scripts should call ensure_stable_hooks() explicitly
# ensure_stable_hooks()
