#!/bin/bash
# Show, feature by feature, what works on this machine and what is missing. Never prints secret values.
KIT_NO_GAME=1
. "$(cd "$(dirname "$0")" && pwd -P)/../lib/kit.sh"
has() { command -v "$1" >/dev/null 2>&1; }
secret() { # is the key available anywhere godot-kit looks?
	python3 - "$1" <<PY 2>/dev/null
import sys; sys.path.insert(0, "$KIT/lib"); import kitconf
sys.exit(0 if kitconf.secret(sys.argv[1]) else 1)
PY
}
MISSING=0
row() { # status label detail
	printf "  %-8s %-22s %s\n" "$1" "$2" "$3"
	[ "$1" = "missing" ] && MISSING=1
	return 0
}

echo "godot-kit: $KIT"
if [ -f "$KIT_CONFIG/config.env" ]; then echo "config:    $KIT_CONFIG/config.env"; else echo "config:    none yet (optional; create with: godot-kit setup)"; fi
echo

echo "Core (check, shot, playtest, new)"
G=${GODOT_KIT_GODOT:-$(command -v godot || true)}
if [ -n "$G" ] && [ -x "$G" ]; then row ok "godot" "$("$G" --version 2>/dev/null | head -1) ($G)"
else row missing "godot" "install Godot 4 and put \`godot\` on PATH, or set GODOT_KIT_GODOT in config.env"; fi
if has python3; then row ok "python3" "$(python3 --version 2>&1)"; else row missing "python3" "needed by shot, sheet and image"; fi
if has perl; then row ok "perl" "used as a timeout for hung game windows"; else row missing "perl" "needed by shot and record"; fi
if python3 -c "import PIL" 2>/dev/null; then row ok "Pillow" "contact sheets, --resize, transparency"
else row optional "Pillow" "pip install pillow  (without it: no contact sheets, no --resize)"; fi
if has git; then row ok "git" ""; else row optional "git" "godot-kit new skips \`git init\` without it"; fi
echo

echo "Recording (record)"
if has ffmpeg; then row ok "ffmpeg" ""; else row optional "ffmpeg" "install ffmpeg to use godot-kit record"; fi
echo

echo "Image generation (image)"
if has curl; then row ok "curl" ""; else row missing "curl" "needed by image"; fi
if secret OPENAI_API_KEY; then row ok "OPENAI_API_KEY" "found"
else row optional "OPENAI_API_KEY" "not set: godot-kit image will not work (set it in the environment or $KIT_CONFIG/secrets.env)"; fi
if secret GEMINI_API_KEY; then row ok "GEMINI_API_KEY" "found (fallback when OpenAI has no credit)"
else row optional "GEMINI_API_KEY" "not set: no fallback provider"; fi
echo

case "$(uname -s)" in
	Darwin) echo "Platform: macOS (the platform godot-kit is developed and tested on)" ;;
	*) echo "Platform: $(uname -s) (not tested yet; screenshots need a display, so use a desktop session or xvfb)" ;;
esac
echo
if [ "$MISSING" = 0 ]; then echo "Core is ready."; else echo "Something required is missing (see 'missing' above)."; exit 1; fi
