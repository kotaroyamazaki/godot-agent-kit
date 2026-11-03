---
name: assets
description: >-
  Make images for a Godot game with an image model (UI parts, characters, backgrounds, icons, key art) and add sound
  effects and music with their sources recorded. Use for "make an image", "make an icon", "I need a background",
  "generate sprites", "add sound effects", "find music". 「画像を作って」「アイコン作って」「背景がほしい」「効果音を入れて」などで使う。
---

# Images and sound

## Images

```bash
godot-kit image _src/hero.png "prompt" --transparent --resize 256x256
godot-kit image _src/bg.png "prompt" --size 1024x1536 --quality high
godot-kit image _src/item.png "prompt" --transparent --ref docs/art/keyart.png
```

`--size 1024x1024|1024x1536|1536x1024`, `--transparent` (UI parts, characters, icons), `--quality low|medium|high`
(default medium), `--ref` (up to 4 images to match the style), `--resize WxH` (shrink to the size the game uses).

It needs `OPENAI_API_KEY`. If it is missing the command says where to put it; `godot-kit doctor` shows the status.
Each call costs money, so do not generate more variants than the task needs.

- **Settle the art style with one reference image first** (key art). Write the palette, shapes, materials and "never
  do this" in a few lines under `docs/art/`, and match everything to it.
- **Keep originals in `_src/` and the resized files in `assets/img/`.** Exclude `_src/` from exports.
- **No text in images.** Numbers and labels are drawn with Label.
- Passing key art as `--ref` can copy its whole composition or break transparency. For parts, use an already-generated
  part as the ref, or no ref with `--transparent`.
- Use medium quality by default; high only for key art and backgrounds.
- **Read every generated image**: is the background really transparent, is there color fringing, does the style match.
- If OpenAI is out of credit and `GEMINI_API_KEY` is set, Gemini is used instead and the call is logged;
  `godot-kit regen-images [--game <game_id>] [--dry-run]` redoes those later.

## Sound

1. Look in the person's own sound library first if they have one (ask, or check the project's `CLAUDE.md`), before
   searching free-asset sites.
2. **Check the license of each source before using it**: commercial use, redistribution, attribution, and any limit on
   content where the sound is the main subject.
3. Copy the file into `assets/audio/` and **add a row to `assets/CREDITS.md` in the same change** (file, source, license).
4. If any sound forbids redistribution, the game's repository must stay private.

Put in from the first playable build: music, a confirm sound, a text tick, success and failure. Raising the pitch on
consecutive successes (`pitch_scale`) makes streaks feel good. Play everything through one entry point in the game
(an `Sfx` autoload or similar) so volume settings apply.
