#!/bin/bash
# Create the user config interactively. Everything here is optional: godot-kit works without a config
# as long as `godot` is on PATH. Safe to run again; existing values are offered as defaults.
#   godot-kit setup            ask questions
#   godot-kit setup --link     also link the `godot-kit` command into ~/.local/bin (for use outside Claude Code)
KIT_NO_GAME=1
. "$(cd "$(dirname "$0")" && pwd -P)/../lib/kit.sh"
LINK=0; [ "${1:-}" = "--link" ] && LINK=1
CONF=$KIT_CONFIG/config.env
ask() { # var question default
	local cur=${!1:-$3} ans
	read -r -p "$2 [${cur:-none}]: " ans
	printf -v "$1" '%s' "${ans:-$cur}"
}
echo "godot-kit setup. Press Enter to keep the value in [brackets]."
echo
GODOT_KIT_GODOT=${GODOT_KIT_GODOT:-}
if ! command -v godot >/dev/null 2>&1 || [ -n "$GODOT_KIT_GODOT" ]; then
	ask GODOT_KIT_GODOT "Path to the Godot 4 binary (not needed if \`godot\` is on PATH)" ""
fi
ask GODOT_KIT_GAMES_DIR "Folder where \`godot-kit new\` creates games (empty = the current folder)" ""
ask GODOT_KIT_LANG "Language of the files in a new game (en or ja)" "en"
ask GODOT_KIT_SECRETS_FILE "An existing file that holds OPENAI_API_KEY=... (empty = use the environment or $KIT_CONFIG/secrets.env)" ""

mkdir -p "$KIT_CONFIG"
{
	echo "# godot-kit user config. Plain KEY=value. No secrets here."
	[ -z "$GODOT_KIT_GODOT" ] || echo "GODOT_KIT_GODOT=$GODOT_KIT_GODOT"
	[ -z "$GODOT_KIT_GAMES_DIR" ] || echo "GODOT_KIT_GAMES_DIR=$GODOT_KIT_GAMES_DIR"
	echo "GODOT_KIT_LANG=${GODOT_KIT_LANG:-en}"
	[ -z "$GODOT_KIT_SECRETS_FILE" ] || echo "GODOT_KIT_SECRETS_FILE=$GODOT_KIT_SECRETS_FILE"
	# keep any other lines the user added by hand
	[ ! -f "$CONF" ] || grep -vE '^(#|$|GODOT_KIT_(GODOT|GAMES_DIR|LANG|SECRETS_FILE)=)' "$CONF"
} > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
echo
echo "wrote $CONF"
if [ "$LINK" = 1 ]; then
	mkdir -p "$HOME/.local/bin" && ln -sf "$KIT/bin/godot-kit" "$HOME/.local/bin/godot-kit"
	echo "linked ~/.local/bin/godot-kit (make sure ~/.local/bin is on your PATH)"
fi
echo
exec "$KIT/scripts/doctor.sh"
