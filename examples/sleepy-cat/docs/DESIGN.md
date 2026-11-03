# Sleepy Cat: design

The single source of truth for the spec.

## In one sentence

Keep a hungry cat fed for 30 seconds.

## One play session

Hunger rises on its own. The player taps the fish to lower it. At full hunger the cat leaves; after 30 s it stays.

## What the player decides

When to feed. Too early wastes the 0.4 drop at a low value (hunger cannot go below 0); too late loses the cat.

## Screens and controls

One screen, one control (the fish). The plain build is the deliberately weak version; the `--clear` build applies the
fixes from the first blind playtest.

## Numbers

See README.md. All values are placeholders.

## What exists right now

Both builds, in `scripts/main.gd`.
