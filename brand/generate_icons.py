"""Regenerates every app icon in this repo from one vector master.

Run it from anywhere:  python brand/generate_icons.py

WHY THIS EXISTS
---------------
Every icon in the project used to be a downscale of a 1024px raster produced by
an image model. That capped quality everywhere: the mark's own detail was only
a few hundred pixels of real data, so the launcher icon and the Android 12
splash (which redraws the adaptive foreground at 2.2x its authored size) were
visibly soft. The fix is to hold the mark as geometry and rasterise it fresh at
each target size, which is what this script does.

The geometry below was traced off brand/reference/app_logo.png and then
regularised -- the reference was drawn freehand, so its two swept corners had
different radii, its diagonal's edges were not parallel, and its note head was
not a true circle. Those are all exact here.

Rasterising uses headless Chrome because it is the one SVG renderer that is
always present on a Flutter dev machine; cairosvg needs a native cairo DLL that
Windows does not ship.
"""
import math
import os
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRAND = os.path.join(ROOT, "brand")

CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
]

# Brand colours. BLACK is the same #06060A that colors.xml, manifest.json and
# the Flutter scaffold all use -- if you change it, change it in all four.
BLACK = "#06060A"
CORE = "#EAF3FF"     # the neon filament itself
GLOW = "#5B9BF5"     # the blue bloom around it

# ---------------------------------------------------------------------------
# geometry, in a 1024x1024 authoring box
# ---------------------------------------------------------------------------
BAR_L, BAR_R = 326.0, 386.0      # left bar, 60u wide
CORNER_R = 60.0                  # radius of both swept corners
BAR_TOP_Y = 367.0                # apex of the bar, at x=BAR_R
BAR_BOT_Y = 710.0                # low point of the bar, at x=BAR_L

STEM_R_EDGE = 629.0              # stem's right edge, tangent to the note head
# The reference's stem is 19u against a 60u bar. Outlined at launcher sizes the
# two sides of a 19u stem merge into one blob, so the redraw widens it. This is
# the only intentional departure from the reference's proportions.
STEM_W = 34.0

HEAD_CX, HEAD_CY, HEAD_R = 561.0, 640.0, 70.0

DIAG_M = 0.915                   # slope of the diagonal, dy/dx
DIAG_DY = 70.0                   # vertical offset between its two edges

FLAG_TOP_Y = 317.0
FLAG_TIP_X = 698.0

MARK_BOX = (BAR_L, FLAG_TOP_Y, FLAG_TIP_X, BAR_BOT_Y)   # l, t, r, b


def _line_circle(x0, y0, m, cx, cy, r):
    """Leftmost crossing of y = y0 + m(x - x0) with the circle."""
    c = y0 - m * x0 - cy
    a_ = 1 + m * m
    b_ = -2 * cx + 2 * m * c
    c_ = cx * cx + c * c - r * r
    root = math.sqrt(b_ * b_ - 4 * a_ * c_)
    x = min((-b_ - root) / (2 * a_), (-b_ + root) / (2 * a_))
    return x, y0 + m * (x - x0)


def path_d():
    """The mark's silhouette as one closed path, traced clockwise.

    One closed path, not a union of parts: the reference outlines the diagonal,
    the stem and the note head separately, which leaves a stray line visible
    across the note head. Tracing the true silhouette removes it.
    """
    stem_l, stem_r = STEM_R_EDGE - STEM_W, STEM_R_EDGE
    up_end_y = BAR_TOP_Y + DIAG_M * (stem_l - BAR_R)      # diagonal meets stem
    lo_y0 = BAR_TOP_Y + DIAG_DY

    dx = stem_r - HEAD_CX                                  # stem enters the head
    stem_head_y = HEAD_CY - math.sqrt(HEAD_R ** 2 - dx * dx)
    dl_x, dl_y = _line_circle(BAR_R, lo_y0, DIAG_M, HEAD_CX, HEAD_CY, HEAD_R)

    return " ".join([
        f"M {BAR_R:.2f},{BAR_TOP_Y:.2f}",
        f"L {stem_l:.2f},{up_end_y:.2f}",                  # diagonal, upper edge
        f"L {stem_l:.2f},358.00",                          # up the stem
        f"C {stem_l:.2f},335.00 628.00,{FLAG_TOP_Y:.2f} 655.00,{FLAG_TOP_Y:.2f}",
        f"L {FLAG_TIP_X:.2f},318.00",                      # flag, over to the tip
        f"C 692.00,352.00 663.00,368.00 {stem_r:.2f},378.00",   # flag underside
        f"L {stem_r:.2f},{stem_head_y:.2f}",               # down into the head
        f"A {HEAD_R:.2f},{HEAD_R:.2f} 0 1 1 {dl_x:.2f},{dl_y:.2f}",
        f"L {BAR_R:.2f},{lo_y0:.2f}",                      # diagonal, lower edge
        f"L {BAR_R:.2f},{BAR_BOT_Y - CORNER_R:.2f}",
        f"A {CORNER_R:.2f},{CORNER_R:.2f} 0 0 1 {BAR_L:.2f},{BAR_BOT_Y:.2f}",
        f"L {BAR_L:.2f},{BAR_TOP_Y + CORNER_R:.2f}",
        f"A {CORNER_R:.2f},{CORNER_R:.2f} 0 0 1 {BAR_R:.2f},{BAR_TOP_Y:.2f}",
        "Z",
    ])


def stroke_for(mark_px):
    """Stroke weight, in authoring units, for a mark drawn `mark_px` tall.

    Optical sizing, not a bug: one constant weight cannot serve both ends of
    the range. Scaled down to 48px a filament-thin stroke greys out into an
    unreadable smudge, and scaled up to 1024px a stroke heavy enough for 48px
    reads as a fat cartoon outline. The mark and its treatment stay identical;
    only the weight is corrected per size, the way any optical-size type family
    works. Keyed to the mark's own rendered height rather than the canvas, so
    targets that frame the mark tighter (the splash, the favicon) land on the
    same optical weight. See brand/README.md.
    """
    return max(9.0, min(21.0, 759.0 / mark_px))


def svg(px, mark_frac, opaque, glow=None):
    """Markup for the mark rendered at `px`, occupying `mark_frac` of the box."""
    l, t, r, b = MARK_BOX
    mw, mh = r - l, b - t
    mark_px = px * mark_frac
    s = mark_px / max(mw, mh)
    tx = (px - mw * s) / 2 - l * s
    ty = (px - mh * s) / 2 - t * s
    w = stroke_for(mark_px)
    d = path_d()

    # Bloom is only worth drawing when it has pixels to live in; on a mark
    # smaller than ~85px it degrades into a grey haze that eats the stroke's
    # contrast instead of adding to it.
    if glow is None:
        glow = mark_px >= 85
    bloom = ""
    if glow:
        bloom = (
            f'<filter id="b" x="-40%" y="-40%" width="180%" height="180%">'
            f'<feGaussianBlur stdDeviation="16"/></filter>'
            f'<path d="{d}" fill="none" stroke="{GLOW}" stroke-width="{w * 1.6:.2f}" '
            f'stroke-linejoin="round" filter="url(#b)" opacity="0.85"/>'
        )
    bg = f'<rect width="{px}" height="{px}" fill="{BLACK}"/>' if opaque else ""
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{px}" height="{px}" '
        f'viewBox="0 0 {px} {px}">{bg}'
        f'<g transform="translate({tx:.4f},{ty:.4f}) scale({s:.6f})">{bloom}'
        f'<path d="{d}" fill="none" stroke="{CORE}" stroke-width="{w:.2f}" '
        f'stroke-linejoin="round"/></g></svg>'
    )


# ---------------------------------------------------------------------------
# rasterising
# ---------------------------------------------------------------------------
def find_chrome():
    for p in CHROME_CANDIDATES:
        if os.path.exists(p):
            return p
    sys.exit("Chrome not found -- edit CHROME_CANDIDATES.")


def render(chrome, profile, markup, px):
    with tempfile.TemporaryDirectory() as tmp:
        src = os.path.join(tmp, "m.svg")
        out = os.path.join(tmp, "m.png")
        with open(src, "w", encoding="utf-8") as f:
            f.write(markup)
        subprocess.run(
            [chrome, "--headless", "--disable-gpu", "--hide-scrollbars",
             "--force-device-scale-factor=1",
             "--default-background-color=00000000",
             f"--user-data-dir={profile}",
             f"--window-size={px},{px}", f"--screenshot={out}", src],
            capture_output=True, check=False)
        if not os.path.exists(out):
            sys.exit(f"Chrome produced nothing at {px}px")
        return Image.open(out).convert("RGBA")


def write(img, rel, opaque):
    """Save under the repo root, flattening onto black when alpha is not wanted."""
    dest = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    if opaque:
        flat = Image.new("RGB", img.size, tuple(
            int(BLACK[i:i + 2], 16) for i in (1, 3, 5)))
        flat.paste(img, mask=img.getchannel("A"))
        flat.save(dest)
    else:
        img.save(dest)
    return dest


# (relative path, pixel size, mark fraction of canvas, opaque)
#
# Mark fractions. 0.66 on plain square icons, which nothing masks.
#
# The masked targets are set by measurement, not by eye. This mark reaches the
# opposite corners of its own bounding box -- the flag tip at top right, the
# bar's foot at bottom left -- so its farthest ink sits at 0.73 of the box
# diagonal, not at the edge midpoints. Fitting the *box* inside a mask
# therefore still clips the corners. Each fraction below is chosen so measured
# ink radius lands inside the mask's circle:
#
#   FOREGROUND_FRAC  108dp canvas, guaranteed-visible circle is 66dp
#   0.55             maskable web icons, safe zone is the middle 80%
#   SPLASH_FRAC      288dp canvas, must fit a 192dp circle
#
# brand/check_safe_zones.py re-measures these; run it after changing the mark.
# It imports the two constants below, so they are stated once.
FOREGROUND_FRAC = 0.415
SPLASH_FRAC = 0.44
DENSITIES = [("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2), ("xxhdpi", 3),
             ("xxxhdpi", 4)]

TARGETS = []
for name, mult in DENSITIES:
    a = "android/app/src/main/res/mipmap-" + name
    TARGETS += [
        (f"{a}/ic_launcher.png", int(48 * mult), 0.66, True),
        (f"{a}/ic_launcher_foreground.png", int(108 * mult), FOREGROUND_FRAC, False),
        # pre-API-31 splash; the layer-list paints brand_black underneath.
        # Framed loose enough that the bloom fades out inside the bitmap --
        # the layer-list centres this over a flat field, so a glow running off
        # the PNG's edge would show as a hard square seam.
        (f"{a}/launch_image.png", int(128 * mult), 0.78, False),
    ]

TARGETS += [
    ("android/play_store_icon_512.png", 512, 0.66, True),
    ("web/icons/Icon-192.png", 192, 0.66, True),
    ("web/icons/Icon-512.png", 512, 0.66, True),
    ("web/icons/Icon-maskable-192.png", 192, 0.55, True),
    ("web/icons/Icon-maskable-512.png", 512, 0.55, True),
    ("web/favicon.png", 32, 0.78, True),
]

IOS = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
for label, px in [("20x20@1x", 20), ("20x20@2x", 40), ("20x20@3x", 60),
                  ("29x29@1x", 29), ("29x29@2x", 58), ("29x29@3x", 87),
                  ("40x40@1x", 40), ("40x40@2x", 80), ("40x40@3x", 120),
                  ("60x60@2x", 120), ("60x60@3x", 180),
                  ("76x76@1x", 76), ("76x76@2x", 152),
                  ("83.5x83.5@2x", 167), ("1024x1024@1x", 1024)]:
    # iOS rejects an alpha channel on app icons, so these are always flattened.
    TARGETS.append((f"{IOS}/Icon-App-{label}.png", px, 0.66, True))

MACOS = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
for px in (16, 32, 64, 128, 256, 512, 1024):
    TARGETS.append((f"{MACOS}/app_icon_{px}.png", px, 0.66, True))


def vector_drawable():
    """The Android 12+ splash icon, as a VectorDrawable.

    Deliberately vector and not a PNG. The system splash draws this into a
    288dp box -- far larger than any density bucket a mipmap would supply --
    which is exactly what made the old raster splash look soft. A VectorDrawable
    has no resolution to run out of.

    288dp canvas with the artwork inside a 192dp circle is the size Android
    specifies for a splash icon that brings no icon background of its own; the
    fraction below is what keeps this mark's corner-reaching ink inside that
    circle. VectorDrawable has no filter support, so the bloom is faked with two
    wider translucent strokes under the core rather than a real blur.
    """
    canvas, frac, base = 288.0, SPLASH_FRAC, 9.0
    l, t, r, b = MARK_BOX
    mw, mh = r - l, b - t
    s = (canvas * frac) / max(mw, mh)
    tx = (canvas - mw * s) / 2 - l * s
    ty = (canvas - mh * s) / 2 - t * s
    d = path_d()

    def layer(color, width, alpha):
        return (f'\n        <path android:pathData="{d}"\n'
                f'            android:strokeColor="{color}"\n'
                f'            android:strokeWidth="{width:.2f}"\n'
                f'            android:strokeAlpha="{alpha}"\n'
                f'            android:strokeLineJoin="round"/>')

    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!--\n'
        '  Generated by brand/generate_icons.py. Edit the geometry there, not\n'
        '  here; this file is overwritten on every run.\n'
        '\n'
        '  Referenced by values-v31/styles.xml as windowSplashScreenAnimatedIcon.\n'
        '-->\n'
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        f'    android:width="{canvas:.0f}dp"\n'
        f'    android:height="{canvas:.0f}dp"\n'
        f'    android:viewportWidth="{canvas:.0f}"\n'
        f'    android:viewportHeight="{canvas:.0f}">\n'
        f'    <group android:translateX="{tx:.4f}"\n'
        f'        android:translateY="{ty:.4f}"\n'
        f'        android:scaleX="{s:.6f}"\n'
        f'        android:scaleY="{s:.6f}">'
        + layer(GLOW, base * 3.2, 0.16)
        + layer(GLOW, base * 1.9, 0.28)
        + layer(CORE, base, 1.0)
        + '\n    </group>\n</vector>\n'
    )


def main():
    chrome = find_chrome()
    with tempfile.TemporaryDirectory() as profile:
        # the SVG master, checked in beside this script
        with open(os.path.join(BRAND, "nyro_mark.svg"), "w",
                  encoding="utf-8") as f:
            f.write(svg(1024, 0.82, False, glow=True))

        vd = os.path.join(ROOT, "android/app/src/main/res/drawable/splash_icon.xml")
        with open(vd, "w", encoding="utf-8") as f:
            f.write(vector_drawable())
        print("  vector  android/app/src/main/res/drawable/splash_icon.xml")

        cache = {}
        for rel, px, frac, opaque in TARGETS:
            key = (px, frac, opaque)
            if key not in cache:
                cache[key] = render(chrome, profile, svg(px, frac, opaque), px)
            write(cache[key], rel, opaque)
            print(f"  {px:>5}px  {rel}")

        # Windows wants every size inside one .ico
        ico = [render(chrome, profile, svg(p, 0.66, True), p).convert("RGB")
               for p in (16, 32, 48, 64, 128, 256)]
        dest = os.path.join(ROOT, "windows/runner/resources/app_icon.ico")
        ico[-1].save(dest, sizes=[(i.width, i.height) for i in ico])
        print(f"  multi   windows/runner/resources/app_icon.ico")

    print(f"\n{len(TARGETS) + 2} files written from brand/generate_icons.py")


if __name__ == "__main__":
    main()
