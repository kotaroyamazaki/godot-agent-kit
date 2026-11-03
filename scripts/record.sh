#!/bin/bash
# Record the game with Godot's Movie Maker (with audio) and compress it to a small mp4 (about 9 MB, easy to share in chat).
#   godot-kit record [seconds=45] [out.mp4=shots/<game_id>_demo.mp4] [-- args passed to the game (default: --demo)]
. "$(cd "$(dirname "$0")" && pwd -P)/../lib/kit.sh"
command -v ffmpeg >/dev/null || kit_die "ffmpeg is required for recording"
SEC=45; OUT=""
case "${1:-}" in ""|--) ;; *) SEC=$1; shift ;; esac
case "${1:-}" in ""|--) ;; *) OUT=$1; shift ;; esac
[ "${1:-}" = "--" ] && shift
[ $# -gt 0 ] || set -- --demo
OUT=${OUT:-$GAME_PATH/shots/${GAME_ID}_demo.mp4}
case "$OUT" in /*) ;; *) OUT=$PWD/$OUT ;; esac
mkdir -p "$(dirname "$OUT")"
W=$(grep -m1 '^window/size/viewport_width=' "$GAME_PATH/project.godot" | cut -d= -f2); W=${W:-1152}
H=$(grep -m1 '^window/size/viewport_height=' "$GAME_PATH/project.godot" | cut -d= -f2); H=${H:-648}
AVI=$(mktemp -d)/rec.avi
perl -e "alarm $((SEC*4+60)); exec @ARGV" "$GODOT" --always-on-top --path "$GAME_PATH" --resolution "${W}x${H}" \
	--write-movie "$AVI" --fixed-fps 30 --quit-after $((SEC*30)) -- "$@" >/dev/null 2>&1 || true
[ -f "$AVI" ] || kit_die "recording failed (no movie file was written)"
# Target bitrate: 9 MB over the duration, minus 96 kbps of audio. Long side is scaled to 960.
VB=$(( 9*8*1024 / SEC - 96 ))
if [ "$H" -ge "$W" ]; then SC="-2:960"; else SC="960:-2"; fi
ffmpeg -y -loglevel error -i "$AVI" -vf "scale=$SC:flags=lanczos,format=yuv420p" -c:v libx264 -preset slow \
	-b:v ${VB}k -maxrate $((VB*2))k -bufsize $((VB*2))k -c:a aac -b:a 96k -movflags +faststart "$OUT"
rm -f "$AVI"
ls -la "$OUT" | awk '{printf "saved: %s (%.1f MB)\n", $9, $5/1024/1024}'
