---
name: playtest
description: >-
  Find out where a first-time player gets lost in a Godot game, by having a subagent that knows nothing about the game
  play it from screenshots and report what it pressed and why. Use for "is this understandable on first play", "does
  the tutorial work", "playtest it", "are the controls confusing", and after building or changing UI, onboarding or a
  tutorial. 「初見で分かるか見て」「遊び方が伝わるか確かめて」「プレイテストして」などで使う。
---

# Blind playtest

Whoever built the game knows the answers, so they cannot judge whether it explains itself. Hand it to **a subagent that
has been told nothing about the game**.

## Steps

1. **Fix the entry point**: the launch arguments (a fresh save, if the game has such a flag) and the viewport size from
   `project.godot`. Check that `godot-kit shot` works in the game.
   **Give the agent a clean copy.** The folder name, `CLAUDE.md`, `README.md` and `docs/` all tell it what the game is.
   Copy the project somewhere with a neutral name (`/tmp/playtest/g1`) without those files, and point the brief there.
2. **Spawn exactly one subagent** (a small, cheap model is enough). Give it only the brief below. Do not give it the
   game's name, genre, rules, README or source, and tell it not to read them.
3. **Compare its report with what you intended.** Candidates to fix: things it never noticed were pressable, things it
   misread, places it stopped.
4. After fixing, run it again with **a new subagent**. The previous one is no longer a first-time player.
5. **Keep every round.** Save the report as `docs/playtests/NN.md` with the date and what you changed afterwards, so you
   can see whether round 2 lost fewer places than round 1. `examples/sleepy-cat/playtests/` has two real rounds.

## Brief (use as is; fill in the `<...>` parts and delete the input line that does not apply)

```
You are playing a game for the first time. There is no manual. Do not read source code, README files or docs.
Your job: look at the screen, press what looks pressable, and work out what this game is.

Tool (run it inside <absolute path of the game folder>):
  godot-kit shot <out>.png --after <sec> [--every 1 --count N] -- <launch args> <inputs...>
- The screen is <width>x<height>. Input coordinates use that size; times are seconds since launch.
- Touch game:           --tap=x,y,sec   --hold=x,y,sec,length   --swipe=x1,y1,x2,y2,sec
- Mouse/keyboard game:  --click=x,y,sec  --move=x,y,sec (hover)  --key=Name,sec  (Enter, Space, Escape, Left, Right, Up, Down, A...)
- Every launch starts from the beginning. So each time, repeat ALL inputs you have made so far and add one new input
  at the end (one launch replays the whole session).
- Read the saved images to see the result.

Procedure:
1. Launch with no input and capture 2 s and 6 s after start. Write what you see, what looks pressable, and what you
   think the game is about.
2. Choose one thing, act on it, capture 1 s later. Write what you expected and what actually happened.
3. Repeat for up to 12 actions. If you do not know what to do, say so, and say what you pressed at random.

Report (facts only; no praise, no suggestions):
- Per action: the input / why you chose it / expected / actual
- Things you thought were pressable that did not react
- Things you only later realized were pressable
- The goal and rules of the game in your own words (or "I could not tell")
- The moment you were most lost
```

## What to look at in the report

- **Byte-identical screenshots mean the agent saw nothing.** Run `cmp before.png after.png`. If the agent says "nothing
  reacted" but the game did change state (a counter went down, a timer reset), the finding is that the change was
  invisible. That is a feedback bug, not an agent mistake. Confirm by replaying the same input yourself and comparing.

- Did it hesitate before the first action? Then pressable things do not look pressable before interaction.
- Could it state the goal and the rules? If not, the game is missing a place that teaches them in words.
- Actions where "expected" and "actual" differ usually lack motion, sound or a clear beat.

## Limits

- It sees still frames, so it cannot judge sound or how good movement feels. Ask the person to play on a real device for that.
- Games that need fast or precisely timed input are better checked with a fixed script of inputs (the `check` skill).
