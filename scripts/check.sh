#!/bin/bash
# Run the game's own tools/check.sh (with any arguments) if it has one; otherwise just the script-error check.
HERE=$(cd "$(dirname "$0")" && pwd -P)
. "$HERE/../lib/kit.sh"
if [ -x "$GAME_PATH/tools/check.sh" ]; then
	exec "$GAME_PATH/tools/check.sh" "$@"
fi
echo "(no tools/check.sh in this game: running the script-error check only)"
exec "$HERE/parse.sh"
