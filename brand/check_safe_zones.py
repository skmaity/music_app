"""Checks that masked icons keep their ink inside the mask.

    python brand/check_safe_zones.py

Run it after changing the mark's geometry or any mark fraction in
generate_icons.py. Exits non-zero if anything would be clipped.

This exists because the obvious way to size a masked icon -- fit the mark's
bounding box inside the mask -- is wrong for this mark. Its ink reaches the
opposite corners of its own box (the flag tip, the bar's foot), so the corners
stick out of any circular mask even when the box appears to fit. The overrun is
invisible until a launcher with a circle mask crops the logo.
"""
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generate_icons import FOREGROUND_FRAC, SPLASH_FRAC   # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (label, file, safe radius as a fraction of canvas, why)
TARGETS = [
    ("adaptive foreground",
     "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png",
     33.0 / 108.0,
     "108dp canvas; guaranteed-visible area is a 66dp circle"),
    ("web maskable 512",
     "web/icons/Icon-maskable-512.png",
     0.40,
     "safe zone is the middle 80%, masked to a circle"),
    ("web maskable 192",
     "web/icons/Icon-maskable-192.png",
     0.40,
     "safe zone is the middle 80%, masked to a circle"),
]

# The splash icon is a VectorDrawable, so there is no bitmap to measure. Its
# ink radius scales with the adaptive foreground's, both being the same path,
# so it is derived from that measurement and the two fractions.
SPLASH_SAFE = 96.0 / 288.0  # 192dp circle on a 288dp canvas


def max_ink_radius(path):
    """Farthest pixel carrying ink, as a fraction of canvas width."""
    im = Image.open(os.path.join(ROOT, path)).convert("RGBA")
    w, h = im.size
    cx, cy = w / 2.0, h / 2.0
    px = im.load()
    has_alpha = im.getchannel("A").getextrema()[0] < 255
    best = 0.0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            ink = a > 24 if has_alpha else max(r, g, b) > 40
            if ink:
                best = max(best, math.hypot(x - cx, y - cy))
    return best / w


def main():
    failures = 0
    ratio_per_frac = None
    for label, path, safe, why in TARGETS:
        got = max_ink_radius(path)
        ok = got <= safe
        failures += not ok
        print(f"{'ok  ' if ok else 'FAIL'}  {label:22} ink {got:.3f} "
              f"/ safe {safe:.3f}   ({why})")
        if "adaptive" in label:
            ratio_per_frac = got / FOREGROUND_FRAC

    if ratio_per_frac is not None:
        got = ratio_per_frac * SPLASH_FRAC
        ok = got <= SPLASH_SAFE
        failures += not ok
        print(f"{'ok  ' if ok else 'FAIL'}  {'splash_icon (vector)':22} "
              f"ink {got:.3f} / safe {SPLASH_SAFE:.3f}   "
              f"(192dp circle on a 288dp canvas; derived, not measured)")

    if failures:
        print(f"\n{failures} target(s) would be clipped. Lower the mark "
              f"fraction in brand/generate_icons.py and regenerate.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
