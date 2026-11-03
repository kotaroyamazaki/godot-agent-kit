#!/usr/bin/env python3
"""Generate a game image (UI parts, characters, backgrounds, icons, key art) with OpenAI's image model.

usage:
  godot-kit image OUT.png "prompt" [--size 1024x1024|1024x1536|1536x1024]
        [--transparent] [--quality low|medium|high] [--ref REF.png ...] [--resize WxH]

- --transparent: PNG with a transparent background (UI parts, characters, icons)
- --ref: reference images (key art or existing assets) to match the style; uses images/edits. Up to 4
- --resize: shrink to the size the game actually uses after generating (e.g. 256x256). Needs Pillow
- defaults: size=1024x1024, quality=medium
- Keys: OPENAI_API_KEY (and optionally GEMINI_API_KEY) from the environment, or from
  ~/.config/godot-kit/secrets.env, or from the file named by GODOT_KIT_SECRETS_FILE in config.env.
- If OpenAI reports no credit/quota and GEMINI_API_KEY is set, the image is made with Gemini instead and the call is
  recorded in ~/.config/godot-kit/logs/fallback_log.tsv. `godot-kit regen-images` redoes those later.
- Every call is recorded in ~/.config/godot-kit/logs/usage_log.tsv (time, game, provider, size, quality, refs, result).
- Models can be changed with GODOT_KIT_IMAGE_MODEL / GODOT_KIT_GEMINI_IMAGE_MODEL in config.env.
"""
import argparse, base64, json, os, pathlib, re, subprocess, sys, tempfile, datetime

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "lib"))
import kitconf

MODEL = kitconf.config("GODOT_KIT_IMAGE_MODEL", "gpt-image-2.5-flare")
GEMINI_MODEL = kitconf.config("GODOT_KIT_GEMINI_IMAGE_MODEL", "gemini-3.1-flash-image")
LOGS = kitconf.LOGS
FALLBACK_LOG = LOGS / "fallback_log.tsv"
USAGE_LOG = LOGS / "usage_log.tsv"


def log_usage(provider, a, ok):
    game = kitconf.game_of(a.out)
    LOGS.mkdir(parents=True, exist_ok=True)
    with open(USAGE_LOG, "a") as f:
        f.write("\t".join([datetime.datetime.now().isoformat(timespec="seconds"), game, provider, a.size, a.quality, str(len(a.ref)), "ok" if ok else "fail"]) + "\n")


def env_key(name):
    k = kitconf.secret(name)
    if not k:
        sys.exit(f"{name} is not set (environment, {kitconf.CONFIG_DIR}/secrets.env, or GODOT_KIT_SECRETS_FILE). See: godot-kit doctor")
    return k


def gemini(a, out):
    """Fallback when OpenAI has no credit. Transparency is made by keying out a green background."""
    w, h = (int(v) for v in a.size.split("x"))
    ratio = "2:3" if h > w else "3:2" if w > h else "1:1"
    prompt = a.prompt
    if a.transparent:
        prompt += (" Isolated single subject on a perfectly flat, uniform pure green (#00FF00) chroma-key background,"
                   " no shadow on the background, no green in the subject, crisp clean edges.")
    parts = [{"text": prompt}]
    for r in a.ref[:3]:
        parts.append({"inline_data": {"mime_type": "image/png", "data": base64.b64encode(pathlib.Path(r).read_bytes()).decode()}})
    body = {"contents": [{"parts": parts}],
            "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": ratio}}}
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
        json.dump(body, f)
        bodyfile = f.name
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={env_key('GEMINI_API_KEY')}"
    res = subprocess.run(["curl", "-s", url, "-H", "Content-Type: application/json", "-d", "@" + bodyfile],
                         capture_output=True, text=True, timeout=300).stdout
    os.unlink(bodyfile)
    try:
        d = json.loads(res)
        b64 = next(p["inlineData"]["data"] for p in d["candidates"][0]["content"]["parts"] if "inlineData" in p)
    except Exception:
        sys.exit(f"Gemini failed too: {res[:500]}")
    out.write_bytes(base64.b64decode(b64))
    from PIL import Image  # Gemini sometimes returns JPEG, so always re-save as PNG
    Image.open(out).convert("RGBA" if a.transparent else "RGB").save(out, "PNG")
    if a.transparent:
        chroma_key(out)
    with open(FALLBACK_LOG, "a") as f:
        f.write("\t".join([datetime.datetime.now().isoformat(timespec="seconds"), str(out.resolve()), json.dumps(sys.argv[2:], ensure_ascii=False)]) + "\n")


def chroma_key(path):
    from PIL import Image
    im = Image.open(path).convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, _ = px[x, y]
            if g > 140 and g > r * 1.35 and g > b * 1.35:
                px[x, y] = (0, 0, 0, 0)
            elif g > r * 1.15 and g > b * 1.15:  # tone down green spill on the edges
                px[x, y] = (r, max(r, b), b, 255)
    im.save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("prompt")
    ap.add_argument("--size", default="1024x1024")
    ap.add_argument("--transparent", action="store_true")
    ap.add_argument("--quality", default="medium")
    ap.add_argument("--ref", nargs="*", default=[])
    ap.add_argument("--resize")
    a = ap.parse_args()
    key = env_key("OPENAI_API_KEY")
    out = pathlib.Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    bg = "transparent" if a.transparent else "opaque"
    if a.ref:
        cmd = ["curl", "-s", "https://api.openai.com/v1/images/edits", "-H", f"Authorization: Bearer {key}",
               "-F", f"model={MODEL}", "-F", f"prompt={a.prompt}", "-F", f"size={a.size}",
               "-F", f"quality={a.quality}", "-F", f"background={bg}", "-F", "output_format=png"]
        for r in a.ref[:4]:
            cmd += ["-F", f"image[]=@{r}"]
    else:
        body = {"model": MODEL, "prompt": a.prompt, "size": a.size, "quality": a.quality,
                "background": bg, "output_format": "png"}
        cmd = ["curl", "-s", "https://api.openai.com/v1/images/generations", "-H", f"Authorization: Bearer {key}",
               "-H", "Content-Type: application/json", "-d", json.dumps(body)]
    import random, time
    for attempt in range(12):
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=300).stdout
        m = re.search(r"Rate limit.*?try again in ([0-9.]+)(ms|s)", res, re.S)
        if not m:
            break
        wait = float(m.group(1)) / (1000 if m.group(2) == "ms" else 1)
        time.sleep(wait + random.uniform(1, 8))
    try:
        d = json.loads(res)
        b64 = d["data"][0]["b64_json"]
        out.write_bytes(base64.b64decode(b64))
        log_usage(MODEL, a, True)
    except Exception:
        if re.search(r"credit|quota|billing|insufficient", res, re.I) and kitconf.secret("GEMINI_API_KEY"):
            print(f"OpenAI has no credit -> generated with Gemini instead (recorded in {FALLBACK_LOG})", file=sys.stderr)
            LOGS.mkdir(parents=True, exist_ok=True)
            gemini(a, out)
            log_usage(GEMINI_MODEL, a, True)
        else:
            log_usage(MODEL, a, False)
            sys.exit(f"image generation failed: {res[:500]}")
    if a.resize:
        from PIL import Image
        w, h = (int(v) for v in a.resize.split("x"))
        Image.open(out).resize((w, h), Image.LANCZOS).save(out, "PNG")
    print(f"saved {out}")


if __name__ == "__main__":
    main()
