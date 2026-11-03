# Rules for making Godot games with an AI agent

Short rules that apply to any game. Each one is here because breaking it cost a rework. Game-specific rules belong in
that game's `CLAUDE.md`, not here. (Japanese translation: `RULES.ja.md`. This file is the source of truth.)

## How to work

- **One source of truth for the spec** (`docs/DESIGN.md` or `README.md`; the game's `CLAUDE.md` says which). When a
  number, rule or effect changes, update it in the same change. Numbers that were not measured are marked as placeholders.
- **Talk to the person in plain words.** No studio jargon (vertical slice, GDD, ADR, epic, gate) in reports, and never in
  the game's own text.
- **When a decision could go either way, offer two or three options with a recommendation** instead of an open question.
- **Shipping, store submission and publishing happen only when asked.** "Implement it" does not mean "release it".

## The game itself

- **Do not build "read text, press one of two buttons".** Give the player something to do from the first design: choosing
  where to look, choosing what to say, time pressure, an opponent that reacts.
- **Put the information needed for a decision on screen.** A game that looks monotonous usually hides what each choice is for and how
  far the player is from the goal.
- **Keep the danger of losing visible at all times**, in the picture itself, not only at the moment of impact.
- **If the theme has real-world conventions, follow the real thing** (a shop's actual order sheet, a sport's actual
  rules). Do not invent them from memory.

## Feel (the things playtests kept rejecting)

- **Things you can press must look pressable before you hover them.** Signal it with something separate from the
  object: a halo, an outline, motion, a cursor change. Merely brightening the object reads as "a pale object".
- **Do not announce state in words during play.** No permanent "you can act now" / "cutscene playing" labels. Show it
  with light, the cursor, the state of objects, the camera.
- **But teach the rules in words.** A tutorial starts with a short how-to-play card, then says for every step what to do
  and why, in one short sentence. Keep a reference card the player can reopen. Glowing arrows alone do not teach a game.
- **Open one or two verbs on the first play.** Never hand over four or more at once.
- **Every state change gets motion, a sound and a beat** (a fade or a cut). Never move on with the same screen unchanged.
- **Every scene shows what to do next.** Use concrete objects, not abstract effects.
- **Music and the basic sounds (confirm, text tick, success, failure) go in from the first playable build.**

## Art, sound, text

- **Decide one reference image for the art style first** and match everything to it. Keep originals separate from the
  resized files the game loads.
- **Never bake text into images.** Draw it with Label and a bundled font. If the game shows Japanese (or any non-Latin
  script), bundle a font that covers it; mobile builds cannot rely on system fonts.
- **Record where every sound and font came from** in `assets/CREDITS.md`, in the same change that adds it, and check the
  license before using it.
- **Do not over-glow.** Cap HDR emission around 1.3 to 1.6 and never make the center of a flash pure white.
- **Floating text must not overlap.** Stack it vertically; identical messages replace each other.
- **Portrait mobile games must not hard-code coordinates.** Lay out from the viewport size and the safe area, and check
  720x1280, 720x1440, 720x1560 and 720x1600.

## Verify before reporting (the `check` skill)

1. Run `tools/check.sh` (or `godot-kit parse` if the game has none).
2. **Screenshot the screens you touched and look at them**: broken layout, overlap, unreadable text, blown-out
   highlights, blank areas. Headless mode does not draw, so it cannot check appearance.
3. **Mute audio when opening a window** (`--audio-driver Dummy`; `godot-kit shot` does it already).
4. **If controls changed, do not stop at self-play.** Press with real input (`--tap`, `--click`, `--key`). Self-play never
   catches "an invisible Control is eating the touches".
5. **Whether a first-time player understands it** is checked with the `playtest` skill, by an agent that was told nothing.
6. **For changes that should not alter behavior, compare seeded self-play logs before and after.** That requires game
   logic that is separate from drawing and randomness that is reproducible from a seed. Build it that way from the start.
7. Report only what was actually looked at, with the image paths.

## Godot pitfalls (each one was hit for real)

- **A click reaches only the topmost Control.** A full-screen layer must be `MOUSE_FILTER_IGNORE`. Plain Control,
  TextureRect and ColorRect default to STOP, so decorations inside a button need IGNORE too.
- A root with `mouse_filter = STOP` cannot receive clicks in `_unhandled_input`. Use `_gui_input` and `accept_event()`.
- A Control added at runtime may not follow its anchors. Fix its size after all children are added.
- **`get_tree().create_timer()` keeps running after its owner is freed.** Use a child Timer node for effect timers.
- `--headless` gives no SubViewport image.
- Do not let a ViewportTexture be minified on a 3D surface (it shimmers). Match the SubViewport to the on-screen size.
- iOS export fails without a reason unless `project.godot` has `textures/vram_compression/import_etc2_astc=true`.
- In GUT tests, `var x := autofree(...)` makes the whole test file silently skip. Write the type explicitly.
- In shell scripts, a multibyte character right after `$var` corrupts the output. Write `${var}`.

## Git

- Commit `*.import` and `*.uid`. Do not commit `.godot/`, `shots/` or export output.
- **Never reset the whole working tree.** Several sessions may be working in the same folder. No `git checkout -- .`,
  `git restore .`, `git reset --hard`, `git stash`, `git clean` or `git add -A`: name the files you touched. Changes you do
  not recognize belong to another session; do not touch, delete or commit them.
- No API keys or tokens in files or commits.
