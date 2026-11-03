#!/usr/bin/env python3
"""Tile numbered screenshots into one contact sheet, for looking at many frames at once.
usage: godot-kit sheet a_1.png a_2.png ... -o sheet.jpg [--cols 8] [--width 225] [--per 16]
More than --per images are split into sheet_1.jpg, sheet_2.jpg ... (too many on one sheet is unreadable)."""
import argparse, re, sys

ap = argparse.ArgumentParser()
ap.add_argument("files", nargs="+")
ap.add_argument("-o", "--out", required=True)
ap.add_argument("--cols", type=int, default=8)
ap.add_argument("--width", type=int, default=225)
ap.add_argument("--per", type=int, default=16)
a = ap.parse_args()
try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is not installed, so no contact sheet was made (look at the images directly, or: pip install pillow)")
fs = sorted(a.files, key=lambda f: [int(n) for n in re.findall(r"\d+", f)])
w0, h0 = Image.open(fs[0]).size
w, h = a.width, round(a.width * h0 / w0)
parts = [fs[i:i + a.per] for i in range(0, len(fs), a.per)]
for k, part in enumerate(parts):
    cols = min(a.cols, len(part))
    rows = -(-len(part) // cols)
    sheet = Image.new("RGB", (w * cols, h * rows))
    for i, f in enumerate(part):
        sheet.paste(Image.open(f).convert("RGB").resize((w, h)), ((i % cols) * w, (i // cols) * h))
    out = a.out if len(parts) == 1 else re.sub(r"(\.\w+)$", r"_%d\1" % (k + 1), a.out)
    sheet.save(out, quality=82)
    print("sheet: %s (%d frames, left to right, top to bottom)" % (out, len(part)))
