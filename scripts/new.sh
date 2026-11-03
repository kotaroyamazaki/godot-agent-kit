#!/bin/bash
# Create a new Godot game from the template.
#   godot-kit new <game_id> "<title shown in the game>" [--landscape] [--dir DEST] [--lang en|ja]
#   e.g. godot-kit new cat-patrol "Cat Patrol"
#        godot-kit new red-room "Red Room" --landscape
# DEST defaults to $GODOT_KIT_GAMES_DIR/<game_id> if that is set in the config, else ./<game_id>.
# Runs `git init` in the new folder. It does not commit.
set -eu
KIT_NO_GAME=1
. "$(cd "$(dirname "$0")" && pwd -P)/../lib/kit.sh"
[ $# -ge 2 ] || kit_die "usage: godot-kit new <game_id> \"<title>\" [--landscape] [--dir DEST] [--lang en|ja]"
ID=$1; TITLE=$2; shift 2
LAND=0; DEST=""; LANG_=${GODOT_KIT_LANG:-en}
while [ $# -gt 0 ]; do
	case "$1" in
		--landscape) LAND=1; shift ;;
		--dir) DEST=$2; shift 2 ;;
		--lang) LANG_=$2; shift 2 ;;
		*) kit_die "unknown option: $1" ;;
	esac
done
echo "$ID" | grep -Eq '^[a-z0-9][a-z0-9-]*$' || kit_die "game_id may only contain lowercase letters, digits and hyphens (e.g. cat-patrol)"
if [ -z "$DEST" ]; then
	BASE=${GODOT_KIT_GAMES_DIR:-$PWD}; BASE=${BASE/#\~/$HOME}
	DEST=$BASE/$ID
fi
[ ! -e "$DEST" ] || kit_die "already exists: $DEST"
mkdir -p "$(dirname "$DEST")"
cp -R "$KIT/template" "$DEST"
[ "$LANG_" = "en" ] || { [ -d "$KIT/template-$LANG_" ] && cp -R "$KIT/template-$LANG_/." "$DEST/"; }
find "$DEST" -name .gitkeep -delete
ID="$ID" TITLE="$TITLE" LAND="$LAND" python3 - "$DEST" <<'PY'
import os, pathlib, sys
root = pathlib.Path(sys.argv[1])
for p in root.rglob("*"):
    if p.is_file() and p.suffix in (".md", ".godot", ".env", ".sh", ".gd", ".tscn"):
        s = p.read_text()
        t = s.replace("__GAME_ID__", os.environ["ID"]).replace("__GAME_TITLE__", os.environ["TITLE"])
        if p.name == "project.godot" and os.environ["LAND"] == "1":  # landscape desktop project
            t = (t.replace("viewport_width=720", "viewport_width=1280").replace("viewport_height=1280", "viewport_height=720")
                  .replace("window/size/window_width_override=450\n", "").replace("window/size/window_height_override=800\n", "")
                  .replace("window/handheld/orientation=1\n", "")
                  .replace('"4.6", "Mobile"', '"4.6", "Forward Plus"').replace('renderer/rendering_method="mobile"\n', ""))
        if t != s:
            p.write_text(t)
PY
git -C "$DEST" init -q 2>/dev/null || true
echo "created: $DEST"
echo "next:    cd $DEST && tools/check.sh"
