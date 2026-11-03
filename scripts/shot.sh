#!/bin/bash
# Open a window and take screenshots (audio muted). The game needs the Shot autoload (template/scripts/shot.gd).
#   godot-kit shot OUT.png [--after SEC] [--every SEC --count N] [--res 720x1560] [-- args passed to the game...]
#   e.g. godot-kit shot shots/title.png --after 2
#        godot-kit shot shots/play.png --after 3 --every 1 --count 8 -- --demo --seed=5
#        godot-kit shot shots/t.png --after 1 --every 1 --count 6 -- --tap=360,1100,2 --key=Enter,4
# With --every the files are OUT_1.png, OUT_2.png ... and a contact sheet OUT_sheet.jpg is written too.
HERE=$(cd "$(dirname "$0")" && pwd -P)
. "$HERE/../lib/kit.sh"
[ $# -ge 1 ] || kit_die "usage: godot-kit shot OUT.png [--after SEC] [--every SEC --count N] [--res WxH] [-- game args...]"
OUT=$1; shift
case "$OUT" in /*) ;; *) OUT=$PWD/$OUT ;; esac
AFTER=3; EVERY=""; COUNT=4; RES=""
while [ $# -gt 0 ]; do
	case "$1" in
		--after) AFTER=$2; shift 2 ;;
		--every) EVERY=$2; shift 2 ;;
		--count) COUNT=$2; shift 2 ;;
		--res) RES=$2; shift 2 ;;
		--) shift; break ;;
		*) kit_die "unknown option: $1 (arguments for the game go after --)" ;;
	esac
done
grep -q '^Shot=' "$GAME_PATH/project.godot" ||
	kit_die "this game has no Shot autoload. Copy $KIT/template/scripts/shot.gd into it and add Shot=\"*res://scripts/shot.gd\" under [autoload] in project.godot"
mkdir -p "$(dirname "$OUT")"
ENGINE=(--audio-driver Dummy --always-on-top --path "$GAME_PATH")
[ -z "$RES" ] || ENGINE+=(--resolution "$RES")
ARGS=("$@" "--shot=$OUT" "--shot-after=$AFTER")
[ -z "$EVERY" ] || ARGS+=("--shot-every=$EVERY" "--shot-count=$COUNT")
LOG=$(mktemp)
# Shot quits the game after the last frame. The alarm is a safety net in case it hangs.
LIMIT=$(python3 -c "print(int(float('$AFTER') + float('${EVERY:-0}') * $COUNT + 60))")
perl -e "alarm $LIMIT; exec @ARGV" "$GODOT" "${ENGINE[@]}" -- "${ARGS[@]}" > "$LOG" 2>&1
grep -E "SCRIPT ERROR|Parse Error|Failed to load script" -A3 "$LOG" | head -12
N=$(grep -c "^\[Shot\] saved" "$LOG"); rm -f "$LOG"
[ "$N" -gt 0 ] || kit_die "no screenshot was saved (did the game crash or quit before --after?)"
if [ -n "$EVERY" ]; then
	python3 "$HERE/sheet.py" "${OUT%.png}"_[0-9]*.png -o "${OUT%.png}_sheet.jpg"
else
	echo "saved: $OUT"
fi
