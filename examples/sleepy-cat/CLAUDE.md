# Sleepy Cat

A 30-second portrait game (720x1280, Godot 4.6+) that is unclear on purpose, used to demo the blind playtest. `--clear` launches the fixed build.

Shared rules live in godot-kit's RULES.md (the `godot-agent-kit:rules` skill). Write only what is specific to **this game** here.

- Spec (source of truth): `docs/DESIGN.md`. Update it in the same change as the code
- How to play, launch arguments, decisions: `README.md`
- Checks: `tools/check.sh`

## Rules for this game only

- Keep the plain build weak on purpose: it is the "before" of the demo. Fixes go behind `--clear` only.
- If the game changes, re-run both playtest rounds and replace `playtests/` and `docs/demo/` together.
