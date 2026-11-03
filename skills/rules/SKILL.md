---
name: rules
description: >-
  Shared rules for designing and building a Godot game with an AI agent: game feel and affordances, tutorials, what to
  verify before reporting, Godot pitfalls (mouse_filter, timers, viewports, iOS export), and git safety. Load this
  before designing a game's core loop or UI, before implementing or reviewing gameplay/UI code in a Godot project, and
  when a playtest says the game is confusing. Godot のゲームを設計・実装・レビューするとき、「分かりにくい」と言われたときに読む。
---

# Rules for Godot game work

Read `${CLAUDE_SKILL_DIR}/../../RULES.md` now and follow it for the rest of this task. It is short (about 80 lines).

- If the person works in Japanese, `${CLAUDE_SKILL_DIR}/../../RULES.ja.md` is the same content in Japanese.
- The game's own `CLAUDE.md` wins over these rules where they disagree.
- When the same lesson has now been learned in a second game, propose adding it to RULES.md in one or two lines.

To make the rules load in every session instead of on demand, the person can import the file from a `CLAUDE.md` that
sits above their games: add a line `@<path printed by: godot-kit rules>`.
