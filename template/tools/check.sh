#!/bin/bash
# This game's checks. Run it after touching code, before reporting that something works.
# As the game grows, add its own steps here: logic tests, seeded self-play, screenshots of fixed scenes.
set -u
cd "$(dirname "$0")/.."
command -v godot-kit >/dev/null || { echo "godot-kit is not on PATH (inside Claude Code the plugin provides it; in a terminal run: godot-kit setup --link)"; exit 2; }
FAIL=0

echo "== script errors"
godot-kit parse || FAIL=1

if [ "${1:-}" != "--noshot" ]; then
	echo "== screenshot (window, muted)"
	godot-kit shot shots/title.png --after 2 || FAIL=1
fi

if [ "$FAIL" = 0 ]; then echo "== all passed"; else echo "== FAILED"; fi
exit $FAIL
