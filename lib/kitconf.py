"""Shared helpers for godot-kit's Python scripts: user config, secrets, and "which game is this"."""
import os, pathlib, re

CONFIG_DIR = pathlib.Path(os.environ.get("GODOT_KIT_CONFIG_DIR")
                          or pathlib.Path(os.environ.get("XDG_CONFIG_HOME") or pathlib.Path.home() / ".config") / "godot-kit")
LOGS = CONFIG_DIR / "logs"
_LINE = re.compile(r'^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*["\']?(.*?)["\']?\s*$')


def _read(path):
    out = {}
    try:
        for line in pathlib.Path(path).expanduser().read_text().splitlines():
            m = _LINE.match(line)
            if m and not line.lstrip().startswith("#"):
                out[m.group(1)] = m.group(2)
    except OSError:
        pass
    return out


def config(name, default=None):
    """A non-secret setting: environment first, then config.env."""
    return os.environ.get(name) or _read(CONFIG_DIR / "config.env").get(name) or default


def secret(name):
    """An API key: environment, then secrets.env in the config dir, then the file named by GODOT_KIT_SECRETS_FILE."""
    if os.environ.get(name):
        return os.environ[name]
    files = [CONFIG_DIR / "secrets.env"]
    extra = config("GODOT_KIT_SECRETS_FILE")
    if extra:
        files.append(extra)
    for f in files:
        v = _read(f).get(name)
        if v:
            return v
    return None


def game_of(path):
    """Walk up from `path` to the game it belongs to: GAME_ID from kit.env, else the folder holding project.godot."""
    for d in pathlib.Path(path).resolve().parents:
        if (d / "kit.env").exists():
            return _read(d / "kit.env").get("GAME_ID") or d.name
        if (d / "project.godot").exists():
            return d.name
    return "-"
