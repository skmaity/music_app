# Brand

The Nyro mark, and the script that turns it into every icon the app ships.

```
python brand/generate_icons.py
```

That rewrites 45 files across `android/`, `ios/`, `macos/`, `web/` and
`windows/`. Nothing in here is referenced at runtime — `pubspec.yaml` does not
bundle `brand/`, and the app has no in-app logo widget. It is build-time source
material only.

## Why the mark is geometry and not a PNG

Every icon used to be a downscale of a 1024px raster from an image model. That
put a ceiling on quality everywhere at once: the mark itself was only a few
hundred pixels of real data, so anything that drew it larger than that — most
visibly the Android 12 splash — had nothing left to draw with.

`generate_icons.py` holds the mark as a path and rasterises it fresh at each
target size. `nyro_mark.svg` is emitted from the same path, so it is a build
artifact, not a second source of truth. Edit the constants at the top of the
script; never edit the SVG or `drawable/splash_icon.xml` by hand.

Rasterising goes through headless Chrome. It is the one SVG renderer reliably
present on a Flutter dev machine — `cairosvg` needs a native cairo DLL that
Windows does not ship.

## Relationship to the reference

`reference/app_logo.png` is the artwork the mark was traced from. The trace is
faithful except in three places, all deliberate:

- **The silhouette is one closed path.** The reference outlines the diagonal,
  the stem and the note head as separate shapes, which leaves a stray line
  visible across the note head.
- **The construction is regularised.** The reference was drawn freehand, so its
  two swept corners had different radii, the diagonal's two edges were not
  parallel, and the note head was not a true circle. All three are exact here.
- **The stem is widened, 19u to 34u.** This is the one change to the design's
  proportions. Against a 60u bar, a 19u stem outlined at launcher sizes has its
  two sides merge into a single blob.

## Optical sizing

`stroke_for()` varies the stroke weight with the mark's rendered height, from
21u at the small end to 9u at the large. This is not an inconsistency. The
reference's stroke is roughly 2u on a 1024px canvas — about 0.2% of its width —
and at a 48px launcher icon that is well under one pixel, so it greys out into
an unreadable smudge. A weight heavy enough for 48px, scaled up to 1024px,
reads as a fat cartoon outline instead of neon. The path and the treatment are
identical at every size; only the weight is corrected, the way any optical-size
type family works.

The bloom is dropped below ~85px of mark height for the same reason: at that
size it stops reading as glow and just eats the stroke's contrast.

## Colours

`BLACK` is `#06060A`, and it is repeated in four places that must agree —
`android/.../values/colors.xml`, `web/manifest.json`, this script, and the
Flutter theme's `scaffoldBackgroundColor`. Change all four together.

The blue field the reference sits on is presentation only; it is not a brand
colour and nothing in the app uses it.
