# godot-agent-kit

**Your AI agent screenshots, taps and blind-playtests your Godot game.**
A Claude Code plugin. Give the game to an AI that was told nothing, and it reports where a first-time player gets lost.

![An AI that was told nothing plays a cat game: "I could not tell." After the fixes, a new one gets the rules right.](docs/demo/demo.gif)

*Real runs of the [example game](examples/sleepy-cat). [Longer video with the agent's play-by-play](docs/demo/demo.mp4).*

[日本語の README](README.ja.md)

## Why

Claude Code can write GDScript all day, but it never sees the game or presses anything. It says "done" and hands you a
screen nobody can use. And even when it can look, it knows how the game works, so it cannot tell whether a new player
would get it. Neither can you.

## What it does

1. **Screenshot**: `godot-kit shot out.png --after 3` launches the game and saves the screen 3 s in. The agent reads
   the image and catches broken layout, overflowing text, blank screens.
2. **Tap**: `--tap=360,800,2` (tap here at 2 s), plus holds, swipes, clicks, hover and keys, replayed into the running
   game. The agent checks for itself that a button really works. `godot-kit record` makes a video.
3. **Blind playtest** (the `playtest` skill), the main point: a fresh subagent that knows nothing about the game gets
   only 1 and 2, plays, and reports what it pressed, what it expected, and where it got lost.

Also included: a project template where all of this works from the first minute, a script-error check, image
generation for UI parts in one style, and about 80 lines of rules that each cost a rework. It is deliberately small:
six skills, one command, no role-play agents, no hooks, no process gates.

## What a blind playtest finds

[`examples/sleepy-cat`](examples/sleepy-cat) is a tiny game that is unclear on purpose. Two agents that were told
nothing about it played it from screenshots. The full reports are in
[`playtests/01.md`](examples/sleepy-cat/playtests/01.md) and [`02.md`](examples/sleepy-cat/playtests/02.md).

| | Round 1 (as first written) | Round 2 (after the fixes) |
|---|---|---|
| Goal and rules | "I could not tell." | Stated correctly in its own words |
| Pressable things found | "Nothing confirmed pressable." | Both controls, at once |
| Most lost | Right after tapping "fish": "I could not tell whether the tap missed" | "Never badly lost." Still found one: "how much margin I have when it is red" |

The part worth noticing is round 1. The "fish" control **did work**: fed three times, the cat still has its eyes open
at 15 s, unfed they are closed ([image](docs/demo/plain_fed_vs_unfed.png)). The agent saw no change after any
press and could not tell whether anything responded. The bug was that feeding changed a number nobody could see. The builder, who
knows the answers, would never have noticed that.

Try it on your own game: "Would a new player understand this?" loads the `playtest` skill.

## Install

Requires [Claude Code](https://code.claude.com), Godot 4 (`godot` on PATH), Python 3, and Perl. Pillow and ffmpeg are optional.

```bash
claude plugin marketplace add kotaroyamazaki/godot-agent-kit
claude plugin install godot-agent-kit@godot-agent-kit
```

Then, in any Claude Code session:

```
> run godot-kit doctor
```

`doctor` lists, feature by feature, what works on your machine and what is missing. Nothing needs configuring if `godot`
is on your PATH. Image generation needs `OPENAI_API_KEY` (see [Configuration](#configuration)).

## Use

Ask Claude in plain words; the skills load when they apply.

| You say | Skill | What happens |
|---|---|---|
| "Start a new Godot game called cat-patrol" | `godot-agent-kit:new` | Creates a project from the template and has you fill in the design first |
| "Check that the title screen still looks right" | `godot-agent-kit:check` | Script-error check, screenshots, Claude reads the images |
| "Press Start and see if the shop opens" | `godot-agent-kit:check` | Replays real input and shoots before/after |
| "Would a new player understand this?" | `godot-agent-kit:playtest` | A subagent that was told nothing plays it and reports |
| "Make an icon for the coin" | `godot-agent-kit:assets` | Generates the image, resizes it, checks transparency |
| "Design the core loop" / "this is confusing" | `godot-agent-kit:rules` | Loads the rulebook |
| "Are our Steam tags right?" | `godot-agent-kit:steam-tags` | Compares with similar games, picks and orders 20 tags, applies them in the Tag Wizard |

### The command

The plugin puts `godot-kit` on the PATH of Claude's shell. To use it in your own terminal too: `godot-kit setup --link`.

```bash
godot-kit new cat-patrol "Cat Patrol"          # --landscape for a 1280x720 desktop project
godot-kit check                                # the game's tools/check.sh, or the script-error check
godot-kit shot shots/title.png --after 2
godot-kit shot shots/play.png --after 1 --every 1 --count 8 -- --tap=360,1100,2 --key=Enter,4
godot-kit record 45                            # mp4 of 45 s of self-play
godot-kit image _src/coin.png "a gold coin, flat risograph style" --transparent --resize 128x128
godot-kit doctor
```

### Using it in an existing game

`check`, `parse` and `image` work in any Godot 4 project as is. Screenshots and input replay need one file: copy
`template/scripts/shot.gd` into the game and register it as an autoload named `Shot`. It does nothing unless the game is
launched with `--shot=...` or an input argument, so it is safe to leave in.

## Configuration

Everything is optional. `godot-kit setup` asks a few questions and writes `~/.config/godot-kit/config.env`
(see [`config.env.example`](config.env.example)).

API keys are never stored in this repository. They are read from, in order:

1. the environment (`OPENAI_API_KEY`, optionally `GEMINI_API_KEY` as a fallback provider)
2. `~/.config/godot-kit/secrets.env` (`KEY=value` lines; keep it `chmod 600`)
3. the file named by `GODOT_KIT_SECRETS_FILE` in `config.env`, if you already keep keys somewhere

Per-game settings go in an optional `kit.env` at the game's root: `GAME_ID`, `GAME_TITLE`, `GAME_DIR` (if the Godot
project is in a subfolder), `GODOT_CMD` (if the game needs a specific Godot binary).

## Always-on rules

The `rules` skill loads `RULES.md` on demand. To load it in every session, import it from a `CLAUDE.md` above your games:

```
@/path/printed/by/godot-kit-rules/RULES.md
```

`godot-kit rules` prints the path. If you installed from a marketplace the path changes on update, so for this use a
local clone is steadier: `git clone` the repository and `claude plugin marketplace add ./godot-agent-kit`.

## Platform support

Developed and tested on macOS with Godot 4.6 and 4.7. The scripts are plain bash and Python and should work on Linux with a
display (or xvfb), but that is not tested yet. Windows is not supported except through WSL.

## What it is not

It is not a studio simulator. There are no producer or designer agents, no approval gates and no hooks. If you want
that, look at larger templates such as Claude Code Game Studios. godot-kit only covers the part an agent cannot do
without help: looking at the game, pressing things, and not repeating known mistakes.

## Contributing

The bar for adding something is "a second game needed it too". Rules are one or two lines each, and each one should name
a mistake that actually happened. See [RULES.md](RULES.md).

## License

MIT
