# Sourced by every godot-kit script. Walks up from the current directory to locate the game
# and decides which Godot binary to run.
#
# Sets:
#   KIT         godot-kit install directory
#   KIT_CONFIG  user config directory (default ~/.config/godot-kit, override with GODOT_KIT_CONFIG_DIR)
#   GAME_ROOT   root of the game repository (where kit.env lives; otherwise where project.godot lives)
#   GAME_DIR    Godot project location relative to GAME_ROOT (default ".")
#   GAME_PATH   absolute path of the directory holding project.godot
#   GAME_ID     short name of the game (used in logs and file names)
#   GODOT       absolute path of the Godot binary
#
# kit.env is optional. Without it the nearest project.godot is used and the folder name becomes GAME_ID.
# Godot is picked in this order: GODOT_CMD in kit.env -> tools/godot in the game -> GODOT_KIT_GODOT
# in the user config -> `godot` on PATH.
# Set KIT_NO_GAME=1 before sourcing to skip the game lookup (config only).

KIT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
KIT_CONFIG=${GODOT_KIT_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/godot-kit}

kit_die() { echo "error: $*" >&2; exit 1; }

# User config (plain KEY=value shell file). Values already in the environment win.
if [ -f "$KIT_CONFIG/config.env" ]; then
	while IFS='=' read -r _k _v; do
		case "$_k" in ''|\#*) continue ;; esac
		_k=${_k#export }; _k=${_k// /}
		_v=${_v%\"}; _v=${_v#\"}; _v=${_v%\'}; _v=${_v#\'}
		[ -n "${!_k:-}" ] || export "$_k=$_v"
	done < "$KIT_CONFIG/config.env"
fi

_kit_up() { # print the nearest ancestor directory that contains file $1
	local d=$PWD
	while [ "$d" != "/" ]; do
		[ -f "$d/$1" ] && { echo "$d"; return 0; }
		d=$(dirname "$d")
	done
	return 1
}

if [ -z "${KIT_NO_GAME:-}" ]; then
	GAME_ID=""; GAME_DIR=""; GAME_TITLE=""; GODOT_CMD=""
	if GAME_ROOT=$(_kit_up kit.env); then
		# shellcheck disable=SC1091
		. "$GAME_ROOT/kit.env"
	elif GAME_ROOT=$(_kit_up project.godot); then
		:
	else
		kit_die "run this inside a Godot project (no kit.env or project.godot found above $PWD)"
	fi
	GAME_DIR=${GAME_DIR:-.}
	GAME_PATH=$(cd "$GAME_ROOT/$GAME_DIR" 2>/dev/null && pwd) || kit_die "GAME_DIR does not exist: $GAME_ROOT/$GAME_DIR"
	[ -f "$GAME_PATH/project.godot" ] || kit_die "no project.godot in $GAME_PATH"
	GAME_ID=${GAME_ID:-$(basename "$GAME_ROOT")}

	GODOT=""
	if [ -n "$GODOT_CMD" ]; then
		case "$GODOT_CMD" in /*) GODOT=$GODOT_CMD ;; */*) GODOT=$GAME_ROOT/$GODOT_CMD ;; *) GODOT=$(command -v "$GODOT_CMD" || true) ;; esac
	elif [ -x "$GAME_PATH/tools/godot" ]; then
		GODOT=$GAME_PATH/tools/godot
	elif [ -n "${GODOT_KIT_GODOT:-}" ]; then
		GODOT=$GODOT_KIT_GODOT
	else
		GODOT=$(command -v godot || true)
	fi
	[ -n "$GODOT" ] && [ -x "$GODOT" ] || kit_die "Godot not found. Put \`godot\` on PATH, or set GODOT_KIT_GODOT in $KIT_CONFIG/config.env (see: godot-kit doctor)"
fi
