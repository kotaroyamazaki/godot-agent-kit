---
name: new
description: >-
  Create a new Godot 4 game from the godot-kit template, with script-error checks, screenshots and input replay working
  from the first minute. Use for "start a new Godot game", "scaffold a prototype", "make a new project from the
  template", and for adding godot-kit's Shot autoload to an existing Godot project.
  「新しいゲームを作って」「Godot で新作を始めたい」「プロトタイプを 1 本立てて」などで使う。
---

# Start a new Godot game

```bash
godot-kit new <game_id> "<title shown in the game>" [--landscape] [--dir DEST] [--lang en|ja]
```

- `game_id`: lowercase letters, digits, hyphens. It becomes the folder name and the id used in logs.
- Default is portrait mobile (720x1280). `--landscape` makes a 1280x720 desktop project.
- Destination: `--dir`, else `$GODOT_KIT_GAMES_DIR/<game_id>` from the user config, else `./<game_id>`.
- `--lang ja` writes the starter documents in Japanese. It runs `git init` and does not commit.

## After creating it

1. `cd <dest> && tools/check.sh` must pass.
2. **Fill in `docs/DESIGN.md` before writing gameplay code**: the one-sentence pitch, one play session, and what the
   player hesitates over every time. If the answer to the last one is "nothing", the design is not ready. Load the
   `rules` skill here. Where the direction could go two ways, offer the person two or three options with a recommendation.
3. Write the first two lines of the game's `CLAUDE.md`.
4. If the game shows non-Latin text, put a font in `assets/fonts/` and set `[gui] theme/custom_font` in `project.godot`.

## What the template contains

| File | Purpose |
|---|---|
| `kit.env` | Per-game values for godot-kit (`GAME_ID`, `GAME_TITLE`). Optional |
| `scripts/shot.gd` | The `Shot` autoload: screenshots, input replay (`--tap --hold --swipe --click --move --key`), the `--demo` flag |
| `tools/check.sh` | This game's checks. Grows with the game |
| `docs/DESIGN.md` | The spec |
| `assets/CREDITS.md` | Where sounds and fonts came from |

Self-play is the game's job: when `Shot.demo` is true, make the game play itself so screenshots and recordings can reach
the interesting moments. Keep game logic separate from drawing and make randomness reproducible from a `--seed`, so that
runs can be compared.

## Adding godot-kit to an existing game

The commands work without any setup (they find `project.godot` and use the folder name as the id). Only screenshots and
input replay need one thing:

1. Copy `${CLAUDE_SKILL_DIR}/../../template/scripts/shot.gd` into the game.
2. Add `Shot="*res://scripts/shot.gd"` (adjust the path) under `[autoload]` in `project.godot`.

Add a `kit.env` only if the Godot project is not at the repository root (`GAME_DIR=client`) or the game needs a specific
Godot binary (`GODOT_CMD=tools/godot`).
