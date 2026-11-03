#!/bin/bash
# Script-error check only: import the project, then run 120 headless frames and grep the output.
. "$(cd "$(dirname "$0")" && pwd -P)/../lib/kit.sh"
TMP=$(mktemp -d)
ERR_RE="SCRIPT ERROR|Parse Error|Failed to load script"
"$GODOT" --path "$GAME_PATH" --headless --import > "$TMP/import.log" 2>&1
"$GODOT" --path "$GAME_PATH" --headless --quit-after 120 > "$TMP/parse.log" 2>&1
if grep -E "$ERR_RE" -A3 "$TMP/import.log" "$TMP/parse.log"; then
	rm -rf "$TMP"; echo "FAIL: script errors"; exit 1
fi
rm -rf "$TMP"; echo "ok: no script errors (${GAME_ID})"
