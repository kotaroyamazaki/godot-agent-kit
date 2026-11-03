---
name: check
description: >-
  Verify a Godot game yourself before reporting: script errors, screenshots you actually look at, real input replayed
  into the running game (touch, mouse, keys), other aspect ratios, and video recording. Use after changing code,
  scenes or UI in a Godot project, and for "check it", "take a screenshot", "does it still work", "record a demo",
  "does it break on a tall phone". For "would a new player understand this" use the playtest skill.
  「確認して」「スクショ撮って」「動くか見て」「録画して」などで使う。
---

# Verify a Godot game

Run these inside the game's folder.

```bash
godot-kit check                 # the game's tools/check.sh if it has one, else the script-error check
godot-kit parse                 # script errors only
godot-kit shot shots/title.png --after 2                               # one screenshot
godot-kit shot shots/play.png --after 3 --every 1 --count 8 -- --demo  # numbered frames + a contact sheet (play_sheet.jpg)
godot-kit shot shots/tall.png --after 2 --res 720x1560                 # another aspect ratio
godot-kit shot shots/t.png --after 1 --every 1 --count 6 -- --tap=360,1100,2 --key=Enter,4   # replay input
godot-kit record 45             # 45 s of --demo as a small mp4
```

`shot` opens a real window (muted, always on top) and quits after the last frame. Everything after `--` goes to the game.
It needs the `Shot` autoload; if the game lacks it, the command says how to add it (see the `new` skill).

Input replay arguments (viewport coordinates, seconds since launch; repeat as needed):
`--tap=x,y,sec` `--hold=x,y,sec[,length]` `--swipe=x1,y1,x2,y2,sec` `--click=x,y,sec` `--move=x,y,sec` `--key=Name,sec[,length]`

## Procedure

1. **Run `godot-kit check`.** Fix failures before going further.
2. **Screenshot what you changed and read the image.** Look for: broken layout, overlapping or unreadable text,
   blown-out highlights, blank areas, and whether pressable things look pressable. For motion, take numbered frames and
   read the contact sheet. Reach specific moments with the game's own arguments (`--demo`, `--seed`, ...; see its README).
3. **If layout changed, shoot other ratios.** Portrait mobile: `--res 720x1280`, `720x1440`, `720x1560`, `720x1600`.
4. **If controls changed, press them for real** and shoot before and after, so the reaction is visible in the frames.
   Use `--move` to check hover states. Self-play does not catch input bugs.
5. **For a change that should not alter behavior**, compare seeded self-play logs from before and after, if the game has
   that mechanism.
6. Report what the images showed, with their paths. Do not write "verified" for anything you did not look at.

## Good to know

- `--headless` does not draw. It is only for script errors and logic tests.
- Each launch starts the game clock at zero. For a time-driven game, verify a sequence inside one launch.
- Godot is chosen in this order: `GODOT_CMD` in `kit.env`, the game's `tools/godot`, `GODOT_KIT_GODOT` in the user
  config, `godot` on PATH. `godot-kit doctor` shows what is missing.
- On Linux a display is required (a desktop session or xvfb). Only macOS has been tested so far.
