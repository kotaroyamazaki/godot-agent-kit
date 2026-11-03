# Sleepy Cat

A 30-second game that is **unclear on purpose**. It exists to show what a blind playtest finds, and to give
`godot-kit:playtest` something real to chew on.

Keep the cat fed. That is the whole game. The cat gets hungry on its own, a fish feeds it, and if it gets too hungry it
leaves.

Two builds of the same project:

| Launch | What it is |
|---|---|
| `godot --path .` | **Plain.** The cat, a faint word "fish" in the corner. No goal, no bar, no feedback. |
| `godot --path . -- --clear` | **Clear.** What the playtest report asked for: a how-to-play card, a hunger bar, a pressable-looking button that pulses when it matters, a pop when you feed. |

The two real playtest reports are in [`playtests/`](playtests/). The screenshots the agents saw are in
[`../../docs/demo/`](../../docs/demo/).

## Try it yourself

```bash
godot-kit shot shots/plain.png --after 2
godot-kit shot shots/clear.png --after 2 -- --clear
godot-kit shot shots/fed.png --after 15 -- --tap=83,1213,5 --tap=83,1213,10 --tap=83,1213,13   # plain build, fed three times
```

## Numbers (placeholders; not tuned)

- Hunger rises 0.05 per second from 0.1, the cat leaves at 1.0 (about 18 s with no feeding).
- A feed lowers hunger by 0.4.
- Goal: 30 s.
