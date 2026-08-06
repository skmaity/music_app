# Design language — music_app (listener app)

Dark, immersive, **album-art driven**. The whole screen is tinted by the colours
of whatever is playing; glass panels and white glow text float on top of it.

Same family as the admin panel (`../../music_app_admin/doc/design.md`) — same
glass, same glow, same fonts — but the admin's background is a fixed photo,
while here **the background is the music**. That is the one idea everything else
serves.

Every value below is taken from the shipped code. When building a new screen,
pull from this file rather than inventing a variant.

Target is **mobile, portrait, dark only**. There is no light theme and there is
no desktop layout.

---

## 0. Tokens — read this first

Every value in this document now has a name in
**`const/theme/tokens.dart`**, and the component defaults live in
**`const/theme/app_theme.dart`**. Use the name, never the number.

| Group | Token | Holds |
|---|---|---|
| Spacing | `Space.xs … xxxl` | 4 · 8 · 12 · 16 · 24 · 32 · 48 |
| Radius | `Radii.sm … xl`, `Radii.full` | 8 · 12 · 20 · 28 · pill |
| Colour | `AppColors` | the three-step white ladder, glass levels, accent, danger |
| Type | `AppText` | display · headline · title · bodyLarge · body · label · caption · numeric |
| Motion | `Motion` | durations and curves |
| Glow | `kGlow` | the signature shadow |
| Elevation | `Elevation` | surface · raised · bar · overlay |

Two rules:

1. **A literal in a widget is a bug.** If the token you want does not exist,
   add it to `tokens.dart` first — that is what stops the same value drifting
   into five different files, which is how the old system decayed.
2. **Do not re-specify what the theme already sets.** `app_theme.dart` supplies
   slider, list-tile, icon, input, app-bar, progress and text-selection
   defaults. Override one only when there is a reason worth a comment.

The colour scheme is **explicit, not seeded**. It was
`ColorScheme.fromSeed(seedColor: Colors.blue)` in an app with no blue — which
M3 then spent on the slider's inactive track, the text cursor and every list-row
ripple. `primary` is white, because white is what this app's feedback is made
of; `secondary` is the pink accent.

---

## 1. The background system

Three layers, bottom to top, present on every screen:

```
AnimatedGradient   ← colours extracted from the current cover art
black veil         ← AnimatedContainer, hides the palette swap
content            ← transparent Scaffolds
```

> **Layers 1 and 2 are the author's own code and are not on the token system.**
> A rework replaced the colour tween with a fixed palette on a rotating axis,
> added a luminance clamp, a dark fallback and a palette cache. It analysed
> clean and the colour maths checked out against the real covers — and it still
> broke the screen on device. All of it has been reverted, at the author's
> request, to the implementation that works.
>
> `component/animated_gradient_widget.dart` and
> `controller/background_controller.dart` deliberately keep their own literals.
> **Do not "tidy" them into tokens, and change nothing here without running the
> app.** `design_audit.md` §7's findings on this layer stand unaddressed on
> purpose.

### Layer 1 — `AnimatedGradient`

`component/animated_gradient_widget.dart`. A two-stop `LinearGradient` that
tweens `primaryColors → secondaryColors` and simultaneously slides its
alignment, on a 4-second `repeat(reverse: true)` with `Curves.easeInOut`.

| Property | Value |
|---|---|
| duration | 4s, reversing |
| curve | `Curves.easeInOut` |
| begin → end | `topLeft → topRight` (primary), `bottomLeft → bottomRight` (secondary) |
| stops | exactly 2 (asserted: both lists equal length, ≥ 2) |

`didUpdateWidget` rebuilds the tweens when either colour list changes — the
palette changes on every track, and without it the gradient keeps painting the
previous song.

### Layer 2 — palette extraction

`BackgroundController.updatePaletteGenerator()` runs `PaletteGenerator` over
the current song's cover at `maximumColorCount: 20`:

| List | Slot 0 | Slot 1 |
|---|---|---|
| `primaryColorsList` | `vibrantColor` | `darkMutedColor` |
| `secondaryColorsList` | `dominantColor` | `mutedColor` |

Fallback when a swatch is missing: `Colors.white`.
Idle default before anything plays: black / `black38`.
No cover → `uploads/covers/alt_image_bg.png`.

Call it whenever the playing track changes or a screen that owns the background
mounts (`Dashboard.initState`, `PlayerPage.initState`).

**One fetch per cover.** `PaletteGenerator` sizes itself from the image, and the
`NetworkImage` resolves through Flutter's image cache — which the cover list has
usually already warmed, so opening the player normally costs no network at all.
On failure the previous palette stays put rather than flashing white.

**There is no palette cache, and adding one is a trap.** The attempt returned
early on a hit, before `hideVisibility()`. Because `startPlaying()` raises the
veil itself, stepping *back* to an already-played song left the screen under an
opaque black curtain permanently — the gradient still running, invisible. If a
cache ever returns, every path through this method must still reach
`hideVisibility()`.

### Layer 3 — the veil

A full-bleed `AnimatedContainer` of black over the gradient. It goes **opaque
while a new palette is being computed**, then fades back:

| Screen | Fade in (`isVisible = true`) | Fade out | Resting alpha |
|---|---|---|---|
| Dashboard | `Motion.veilIn` | `Motion.veilOut` | `kVeilRest` |
| Player | `Motion.veilIn` | `Motion.veilOut` | `kVeilRest` |

`hideVisibility()` waits 300 ms before releasing, so the gradient never pops.
`isFromSongLogo` suppresses the curtain when the user is only moving between the
dashboard and the player — same song, same palette, no need to hide anything.

**Rule:** never remove the veil, and never rest it at zero. Nothing bounds how
bright the extracted palette can get, so the veil is the only thing between a
vibrant cover and white text. The player used to rest at `0.0` — the least
protected text in the app on the brightest possible background — and the
dashboard at `0.1`; both now rest at the one `kVeilRest`. If a new screen puts
small text over the gradient, give it its own local scrim rather than lowering
this.

**Every path out of `updatePaletteGenerator()` must reach `hideVisibility()`.**
`startPlaying()` raises the veil before it calls this, so any early return
leaves the screen black — not dimmed, black, and it does not come back.

> Still open from `design_audit.md` §7, and all of it needs a device:
> the hue tween is a strobe behind the text; `vibrantColor` has no luminance
> clamp; and two linear stops make a band rather than an atmosphere, where the
> reference answer is a radial bloom behind the artwork. One attempt at the
> first two has already been reverted. The background is on `design_plan.md`'s
> "not being touched" list for a reason.

---

## 2. Glass

**One recipe, three levels — `GlassPanel` (`global_widgets/glass_panel.dart`).
Never hand-roll it.**

```dart
GlassPanel(
  level: GlassLevel.mid,
  borderRadius: BorderRadius.circular(Radii.lg),
  padding: const EdgeInsets.all(Space.lg),
  child: child,
)
```

| Level | Fill | Blur | Edge | Shadow | Used by |
|---|---|---|---|---|---|
| `low` | `glass1` | — | — | — | rows, chips |
| `mid` | `glass2` | `kGlassBlur` | `glassEdge` | `kPanelShadow` | player card, now-playing bar |
| `high` | `glass3` | `kGlassBlur` | `glassEdge` | `kPanelShadow` | nav rail |

There used to be **four unrelated recipes** hand-rolled at four call sites —
blurred at 0.4, blurred at 0.2, unblurred at 0.4, unblurred at 0.1, two of them
with borders and two without. That is a set of accidents, not a ladder, and
changing "the glass" meant editing every one of them.

### The order matters

**Shadow behind → clip → blur → fill → hairline in front.**

- The **shadow sits outside the clip**, or the clip cuts it off.
- The **hairline sits outside it too**, as a `DecorationPosition.foreground`.
  Drawn inside the clip, antialiasing eats most of the outer pixel and the edge
  comes back as a smudge — which is exactly how the app's previous border
  failed.
- Clip before blur before fill; any other order looks muddy.

### The hairline is not decoration

It is what makes a pane read as a pane instead of as fog. Every mature glass
system has one — Apple's materials, Vision OS. This app had none, and its one
border was 0.5px of a *second* grey at 40%, invisible over a moving gradient.

### Opacity is not elevation

`glass3` was **0.4**, which is not glass — it is a grey bar, and it made the
app's weakest contrast pair: white text on a ~40% white surface. It is 0.24 now.
A pane reads as raised through its hairline and its shadow, not by being opaque.

`kPanelShadow` is the app's depth language. There were **no shadows at all**
before it, so the rail, the player card and a list row floated at the same z.
The glow cannot do this job: light emitted outward reads as "on", never "above".

### Level 1 is a fill, not a pane

Rows get colour and nothing else — no blur, no edge, no shadow. A
`BackdropFilter` per row is expensive in a `ListView`, and a row is not a
surface floating over content.

### `RepaintBoundary` is part of the recipe

Every pane carries one, and so does `AnimatedGradient`. The gradient repaints
every frame, forever, behind the whole app; the blur re-samples it. Without the
boundaries that dirt propagates through the entire tree.

The transport controls are no longer glass — see §Player page.

Panels that sit **over content** (nav rail, player card) get the blur. Panels
that sit over the gradient only (rows, buttons) skip it — the gradient is
already soft, and a `BackdropFilter` per row is expensive in a `ListView`.

---

## 3. Colour

There is no brand colour. Hierarchy comes from **white at different opacities**,
plus glow. The gradient supplies all the hue.

Everything is a name in `AppColors` (`tokens.dart`). The app used to carry six
mid-whites doing one job — `white54`, `white70`, `withAlpha(150)` (59%),
`white30` — values not perceptibly different from one another, which is what
proves no scale existed. There is now a three-step ladder and nothing else.

| Token | Value | Use |
|---|---|---|
| `textPrimary` | white | titles, active nav, primary icons |
| `textSecondary` | white @ 72% | artists, hints, inactive nav — anything that must stay readable |
| `textTertiary` | white @ 50% | metadata and empty-state marks. The floor, never body copy |
| `glass1` | `grey.shade100 @ 10%` | rows, chips — no blur |
| `glass2` | `grey.shade100 @ 20%` | cards, the now-playing bar — blurred |
| `glass3` | `grey.shade100 @ 24%` | the nav rail — blurred |
| `glassEdge` | white @ 22% | the 1px hairline on a glass pane |
| `trackInactive` | white @ 24% | the unplayed part of any progress track |
| `overlay` | white @ 12% | the press state — theme `splashColor` and `highlightColor` |
| `scrim` | black | the veil, at `kVeilRest` when resting |
| `accent` | `pinkAccent` | the heart, and nothing else |
| `danger` | `#FF6B6B` | `ErrorState`, and any failure |

`accent` is the **only fixed accent in the app**. Keep it that way — it is what
makes the favourite action feel like the one emotional control.

`danger` is the app's second fixed colour and it earns its place: failure had no
visual language at all before `ErrorState`, which is why a broken request and an
empty list looked the same.

**Every tappable surface has a press state**, because `splashColor` and
`highlightColor` are set once on the theme. There was no pressed style defined
anywhere before — every `InkWell` inherited whatever M3 derived from the seed.
Anything sitting over its own opaque container still needs a local
`Material(color: Colors.transparent)` above it, or the ink paints behind the
widget and the tap looks like nothing happened.

There is **no seed colour**. `ColorScheme.fromSeed(seedColor: Colors.blue)` in
an app with no blue in it is what M3 spent on the slider's inactive track, the
text cursor and selection handles, and every list-row ripple — blue-violet
ripples over an orange album gradient. The scheme is explicit; `primary` is
white, because white is what this app's interactive feedback is made of.

Nav state lives in `DashBoardOptionsColors` (`const/theme/`), which re-exports
`kGlow`. Both nav states are white separated by opacity — do not introduce a
third white.

---

## 4. Glow

The signature. One shadow, reused everywhere:

```dart
const _glow = [Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))];
```

Applied to: page-title icons, the active nav item (icon **and** label), ghost
transport icons, the now-playing bar's play/pause, the player's dismiss control,
the offline text (blur 7).

Not on the player's primary play button — that one is a filled white disc, and
a solid white surface is already the loudest "this is live" the app can say.

**Never** on body text, list titles, subtitles or timestamps. Glow marks
"this is live / this is where you are" — glowing everything says nothing.

The favourite heart glows in its own animated colour, tracking the white →
pinkAccent tween, so the glow reads as the pop.

---

## 5. Type

Set globally in `main.dart` — do not restyle per widget:

- `GoogleFonts.josefinSansTextTheme()` — everything
- `GoogleFonts.pacifico()` via `textButtonTheme` — **all `TextButton` labels**

That second line is easy to miss: the nav rail is built from `TextButton.icon`,
so **the nav labels render in Pacifico** while the rest of the app is Josefin
Sans. That contrast is intentional; if you add a nav item, use `TextButton.icon`
so it inherits it, and if you add a non-nav button that should *not* be script,
override `textStyle` explicitly.

| px | Use |
|---|---|
| 45 | Page titles ("Quick picks", "Songs", "Artists", "Favourites", "Settings") |
| 35 | Page title fallback when the name may overflow |
| 30 | In-page section heading ("More") |
| 25 | Empty-state headline |
| 24 | Player track title (`AppText.title` / `textTheme.titleLarge`) |
| 16 | Body, artist labels, timestamps, nav labels |
| 14 | Empty-state subtitle |
| 12 | Row subtitle, metadata |

12 is a **metadata-only** size. Anything the user has to read as a sentence
stays at 16 or above.

---

## 6. Layout

### Page header

Titles are **right-aligned** at 45px, `EdgeInsets.only(right: 10, top: 40)`,
mirroring the rail on the left. This is the app's most recognisable layout move
— every main page repeats it. New pages must too.

### Nav rail — the app's structure

A vertical rail down the **left edge**, not a bottom bar. Five destinations
(Quick picks, Songs, Favourites, Artists, Settings), each a `TextButton.icon`
inside `RotatedBox(quarterTurns: 3)` so the label runs bottom-to-top. Rail
padding `all(4)`, right corners rounded 30.

| State | Icon | Colour | Glow |
|---|---|---|---|
| Active | filled rounded | `DashBoardOptionsColors.optionSelected` | yes |
| Inactive | outlined rounded | `DashBoardOptionsColors.optionUnselected` | no |

Icons 20. Each button carries `minimumSize: Size(48, 48)` — the `RotatedBox`
turns that 48 into the rail's width, which is what keeps the targets legal.

Destinations live in the `_navItems` list in `dashboard_page.dart`; add one
there rather than hand-building another button. Five is the cap — Material's
bottom-nav limit applies to the rail for the same reason (labels stop being
scannable past five).

### Now-playing bar

Reworked — `design_audit.md` §26 and `design_plan.md` Tier 1 item 3. It used to
be a music-note glyph in a progress ring beside the rail: **no artwork, no
title, no artist, no play/pause.** A navigation affordance wearing the name of
a component whose whole job is to make navigation unnecessary.

Bottom-anchored, **spanning the content column** — the last child of the column
right of the rail, not an overlay, so no page needs its own inset for it.

| Element | Spec |
|---|---|
| Surface | `Radii.lg`, `kGlassBlur`, `AppColors.glass2`, `Space.sm` margin |
| Artwork | `Controls.thumb`, `Radii.sm`, `Hero(tag: kNowPlayingHeroTag)` |
| Title | `textTheme.bodyLarge`, `maxLines: 1` |
| Artist | `textTheme.bodySmall` @ `AppColors.textSecondary`, `maxLines: 1` |
| Play/pause | ghost `IconButton`, `Controls.iconInline` in a `Controls.secondary` target |
| Progress | `LinearProgressIndicator`, `Controls.progressBar`, inset and capped |
| Entry | `.fadeIn().slideY()` at `Motion.normal`, gated on `noMotion` |

**It stays up while paused.** The old one was gated on `isPlaying`, so pausing
made the only route back to the player vanish. It is gated on *having a track*
(`songid != 0`) instead.

**The artwork is the `Hero`.** `kNowPlayingHeroTag` is declared in
`player_page.dart` and used in exactly two places — here and the player's
cover. It used to fly a music-note glyph between the mini player and the
player's back button, which spent the app's most valuable transition on the one
element that says nothing about the music. Do not reuse the tag.

**Everything but play/pause opens the player.** The tap target is a `Material` →
`InkWell`; the `Material` is what makes the splash visible at all — the old chip
had an `InkWell` above an opaque container with no local `Material` ancestor, so
the ink painted *behind* the widget and a tap looked like nothing had happened
(`design_audit.md` **C6**). Any new tappable surface over glass needs the same
`Material(color: Colors.transparent)` wrapper.

The progress line is inset by `Space.sm` and capped rather than run flush to the
bottom edge: a 2px line at the foot of a `Radii.lg` clip loses ~11px to each
corner, so low progress would not draw at all.

### Quick picks — the home screen

Reworked — `design_audit.md` §17 and `design_plan.md` Tier 2 item 5.

It was a flat list of 50×50 rows, **visually identical to Search and to
Favourites**: three of five destinations rendering the same screen with a
different word at the top. The app's premise is that the album art *is* the
experience, and this screen showed that art smaller than anywhere else in it.

`CustomScrollView` under the usual `PageHeader`, in two densities:

| Band | Spec |
|---|---|
| Hero | `picks.first`, square at `min(contentWidth, viewportHeight × 0.6)`, `Radii.lg`, `kArtShadow`, title + artist over `kArtScrim` |
| Heading | "More picks", `textTheme.headlineMedium` |
| Grid | `picks.skip(1)`, columns derived from width (2 on a phone, up to 5), `_tileRatio`, square art then title + artist beneath |

**The hero is capped by the viewport, not the content width.** Album art is
square, so a full-width hero would be 740pt tall in landscape. The cap also
guarantees the grid peeks below the fold, which is what says "keep scrolling".

**Grid columns are derived, never fixed.** `_columnsFor(width)` targets a ~180pt
cell, clamped 2–5.

**Artwork inside a grid cell is `Expanded`.** The type below claims its height
first and the art takes what is left, which is what makes a fixed
`childAspectRatio` safe at large text scales — the same rule as the player card.

**Type over artwork always gets `kArtScrim`.** A cover can be white, or busy, or
both; never trust it as a background. The now-playing grid cell gets the scrim
too, so the marker has ground.

**`Semantics(excludeSemantics: true)` goes *inside* the `InkWell`, never
outside** — from outside it drops the InkWell's own tap action, leaving a
control a screen reader can read but not activate.

The screen deliberately does **not** use `SongTile`; that row is what makes
Search and Favourites look alike, and this screen exists to not look like them.
It does share `NowPlayingMarker`, because there is one way to say "this is the
one playing".

### Song row

The single most repeated component — Quick picks, Search, Favourites and Artist
songs all render `SongTile` (`global_widgets/song_tile.dart`). Never rebuild it
inline; the row must look and behave identically everywhere.

```dart
SongTile(
  key: ValueKey(song.songid),
  song: song,
  isPlaying: controller.currentPlaying.value.songid == song.songid,
  onTap: () { /* start playing, then push PlayerPage */ },
)
```

Reworked — `design_audit.md` §1, §19, §23 and `design_plan.md` Tier 2 item 7.

| Part | Spec |
|---|---|
| Outer | `Padding(horizontal: Space.gutter, vertical: Space.xs)` → transparent `Material` |
| Row | `ListTile`, `Radii.sm`, `tileColor: AppColors.glass1`, `contentPadding` horizontal `Space.md`, `minVerticalPadding: Space.sm` |
| Artwork | `RemoteImage` at `Controls.thumbRow`, `Radii.md` |
| Title | `textTheme.bodyLarge` @ `textPrimary`, `maxLines: 1` |
| Artist | `textTheme.bodySmall` @ `textSecondary`, `maxLines: 1` |
| Trailing | `NowPlayingMarker` when `isPlaying`, nothing otherwise |

**No border.** It was 0.5px of `grey.shade200 @ 40%` — invisible over a moving
gradient, reading as a smudge on the row's edge rather than as an edge, and the
only reason the app had a second grey at all. The `glass1` fill defines the row.

**Title and artist differ in tone, not only size.** Both used to be full white
at 16 and 12: two different kinds of information with no step between them.
Hierarchy comes from the tonal drop first and the size second.

**The artwork is `Controls.thumbRow` (56), not 50.** This is the component the
app repeats most, and the app's whole thesis is the artwork.

`isPlaying` compares **songid, not list index** — the same song is row 3 in
Favourites and row 11 in Search, and an index comparison marks the wrong row.

`SongListSkeleton` mirrors these numbers exactly. If you change the row's
padding or thumbnail, change the skeleton in the same commit or the list will
jump when it loads.

The `trailing` Lottie is the now-playing marker — never a coloured row, never a
different background. One marker, one meaning. It falls back to a static
`Icons.graphic_eq_rounded` under reduced motion.

### Search field

Reworked — `design_audit.md` §25 and `design_plan.md` Tier 3 item 8.

| Part | Spec |
|---|---|
| Decoration | everything from `inputDecorationTheme` — do not restate borders, height or colours |
| Label | `labelText: 'Search songs'`, `hintText: 'Title or artist'` |
| Leading | `Icons.search_rounded` in `prefixIcon` |
| Trailing | a **clear** `IconButton` when there is text, nothing when there is not |
| Input | `controller.queryChanged`, never `searchSong` directly |

**Typing is debounced by `Motion.debounce`.** The request waits for 300ms of
quiet. Search used to fire per character, and because results are wrapped in
`staggeredEntrance` the entire list re-animated in on every letter typed — the
single most jarring moment in the app. Any field that drives a request goes
through a debounce; none of them call the network from `onChanged`.

**The search icon leads and the clear button trails.** The affordance used to be
a music note in the *trailing* slot: not tappable, saying nothing about search,
and sitting in the exact position every user reaches for to clear the field.

**An empty query is not a request.** `queryChanged('')` calls `clear()`, which
resets locally; asking the server for everything because a user pressed
backspace is not a search.

The clear button's visibility comes from a `ValueListenableBuilder` on the
`TextEditingController`, so a keystroke rebuilds the field and nothing else.

> Not built: recent searches, suggestions, a result count. The first two are
> feature work needing storage. A count was considered and left out — the audit
> also says this screen carries ~140pt of chrome above the first result, and
> adding a line to fix "no count" would make the bigger problem worse.

### Artists

Reworked — `design_audit.md` §24 and `design_plan.md` Tier 3 item 9. Master and
detail, both driven by `ArtistController`.

**One entity type, one shape.** Every artist is a circle at `Radii.full`, in a
single `GridView` with columns derived from width. The old screen gave the first
five 130px circles and everyone else 110px rounded squares — one kind of thing
wearing two shapes, when a circle is exactly how the whole industry encodes
"this is a person, not a record".

**A real grid.** Both bands used to be *horizontally-scrolling* `ListView`s, so
the "grid" under "More" scrolled sideways with no affordance, no peek and no
indicator, fighting the vertical scroll the page invites. Users would not have
found it.

Losing the featured/rest split also removes the "More" heading and with it
`album_line2.png` — a raster bitmap doing a divider's job, which could not
scale, tint or adapt. There is nothing left for a divider to divide.

| Part | Spec |
|---|---|
| Grid | columns from width (2–6, ~130pt target), `_tileRatio`, `Space.md` / `Space.lg` spacing |
| Tile | circle in an `Expanded` box, name `bodyLarge` centred beneath, one `Semantics` label |
| Detail header | `Controls.avatar` circle, song count, bio — all three come from the API |
| Detail list | `SongTile`, the same as everywhere else |

**The detail view has a header.** Tapping through used to give a bare
`PageHeader` with the name and nothing else — no image, no bio, no count —
while the API returned all three. The count is `songs.length` from the details
response, because that endpoint's `artist` object does not carry `total_songs`;
only the list endpoint does.

**Bio is nullable** and is null in practice today, so the block is conditional.

The tile carries **one** semantic label. It used to announce the artist twice,
once from the image's `semanticLabel` and once from the visible name below it.

### Player page

Reworked — `design_audit.md` §16 and `design_plan.md` Tier 1 item 1.

**Nothing on this screen has a fixed pixel height.** That is the rule, not an
implementation detail. The page is `Column[ Expanded(card), gap, transport ]`
inside `SafeArea` with `fromLTRB(Space.xl, kToolbarHeight, Space.xl, Space.xl)`;
the card is `Column[ Expanded(artwork), track, seek ]`. Both `Expanded`s mean
the artwork absorbs whatever is left after the type — so the layout holds on a
320pt phone and at 200% text scale without a scroll view.

**When the card is wider than it is tall** — landscape, split screen — the card
flips to `Row[ artwork, gap, Column[ track, seek ] ]`. Stacked, the type alone
needs ~150pt inside the card, which a landscape phone does not have; the old
fixed `height: 470` overflowed a landscape viewport by ~95pt unconditionally.
The transport stays below the card in both orientations. The branch keys off
the card's own box, not `MediaQuery.orientation`, so split screen and tablets
fall out correctly.

| Element | Spec |
|---|---|
| Card | `Radii.xl`, `kGlassBlur`, `AppColors.glass2`, `EdgeInsets.all(Space.lg)` |
| Artwork | square via `LayoutBuilder` + `min(maxWidth, maxHeight)`, `Radii.md`, `kArtShadow` — one widget, correct in both branches |
| Track title | `textTheme.titleLarge`, `maxLines: 2` |
| Artist | `textTheme.bodyLarge` @ `AppColors.textSecondary`, `maxLines: 1` |
| Heart | `Controls.iconInline` in a `Controls.secondary` target, right of the track |
| Seek | theme `sliderTheme` — no local override — plus `secondaryTrackValue`, `label` and `semanticFormatterCallback` |
| Timestamps | `AppText.numeric` @ `AppColors.textSecondary`, `spaceBetween` |
| Transport | `_GhostControl` · `_PrimaryControl` · `_GhostControl`, `Space.xl` apart |

**Radii are concentric.** Outer `Radii.xl` (28) minus `Space.lg` (16) of padding
is exactly `Radii.md` (12) on the artwork. Keep that relationship if either
value changes — an inner corner tighter than its outer one reads as a mistake.

**The artwork must be square.** Derive its side from the box it is given; never
pass `RemoteImage` a size the parent cannot honour. The old card requested 300
inside a `screenWidth - 90` content box, so every phone under 390pt rendered the
cover 285×300 and `BoxFit.cover` cropped it.

**The transport has one primary.** `_PrimaryControl` is a filled disc —
`colorScheme.primary` on `onPrimary`, `Controls.primary` (72), the **only solid
surface in the app**. `_GhostControl` is icon-and-glow only at
`Controls.secondary` (56). Three identical 96dp `FloatingActionButton.large`
with every elevation zeroed is what this replaced: a FAB used as a shaped box,
and a screen with no primary action. No `heroTag` juggling any more either.

**Title and artist are two ranked lines**, never `"$title - $artist"` in one —
a single ellipsis across both eats the artist first.

The heart animates **scale**, not `size`: animating a layout dimension shifted
the row on every tap and let the container clip the burst at its peak. It is
driven by an `AnimatedBuilder`, because an `Obx` listens to GetX observables and
not to an `AnimationController` — inside `Obx` the pop never actually played.

Two `Obx` rules this screen learned the hard way, and they apply everywhere:

1. **Scope each `Obx` to what changes.** The seek position ticks several times a
   second. One card-wide observer meant every tick rebuilt the artwork and the
   `BackdropFilter` too. The artwork, the track and the seek bar each own theirs.
2. **Read the observable in the `Obx`'s own build**, not inside a nested
   builder's callback. GetX only tracks reads that happen synchronously while
   the `Obx` builds; anything read later in an `AnimatedBuilder` or
   `LayoutBuilder` callback is invisible to it and will not trigger a rebuild.

Still true: the heart fires only after the server confirms, and the seek bar
stays `SliderInteraction.slideOnly`.

**The seek bar carries three tracks, not two.** Played, buffered
(`secondaryTrackValue` from `SongController.bufferedPosition`) and unplayed. It
showed played-vs-nothing before, so a stall looked identical to a track that had
buffered all the way through. The thumb grows on grab via `_GrabThumb`, and
`label` puts the time in a bubble above your finger — scrubbing without one is
blind, because your own thumb covers the timestamp.

**Timestamps are `0:42`, not `00:42`.** Minutes are not zero-padded; no clock,
player or stopwatch anywhere writes it the other way.

**The heart pulses on removal too**, in white rather than pink. It used to fire
on add and stay silent on remove, so half the interaction had no feedback.

> Not yet built: swipe-down-to-dismiss, a buffering state on play/pause, and the
> `Hero` from the tapped row's artwork — `design_plan.md` items 3 and 7. The
> back control is a plain `keyboard_arrow_down_rounded` with no `Hero` until
> then. Shuffle / repeat / speed / volume / timer / queue slot in as a row
> between the timestamps and the transport; the layout has room for them now.

### Radius and spacing

Both live in `const/theme/tokens.dart` — `Radii` and `Space`. Reach for a name,
never a number, and if the name you want does not exist, add it there first.

`Radii`: `sm` 8 rows · `md` 12 artwork and inputs · `lg` 20 panels · `xl` 28
full-height surfaces and the player card · `full` avatars. This replaced eight
values (`100 · 30 · 20 · 15 · 12 · 10 · 8 · 4`), including three different radii
for the same album art depending on where it appeared.

`Space`: 4 · 8 · 12 · 16 · 24 · 32 · 48. One 4pt grid. The old set mixed a 4/8
grid with a 5/10 grid, which fights Android everywhere.

**`Space.gutter` is the page gutter, and every screen uses it.** Headers used
`right: 10`, rows `horizontal: 10`, empty states `horizontal: 24` and the
artist list `left: 10`, so no two things shared a vertical edge and no page had
a spine. `PageHeader`, `SongTile` and Quick picks are on it; the remaining
screens convert as `design_plan.md` reaches them.

Screens not yet migrated still carry their old literals.

---

## 7. Motion

Every duration and curve in the app is a name in `Motion` (`tokens.dart`).
**Never type a millisecond value into a widget.** The app previously had none of
these, and drifted to a 800ms page switch and a 100ms-per-item stagger — 2.5x
and 2–5x over platform guidance on its two most repeated animations.

| Transition | Spec |
|---|---|
| Page switch (rail) | `AnimatedSwitcher` `Motion.page`, Material shared axis over `Motion.pageShift` + crossfade, **direction-aware** |
| List entrance | `AnimationLimiter` → `staggeredList(delay: Motion.stagger)` → `SlideAnimation(vertical 50, Motion.normal, Motion.enter)` → `FadeInAnimation` |
| Background gradient | 4 s, looping, reversing, colours tweening `primary → secondary` (its own literal — see §1) |
| Veil | `Motion.veilIn` in, 300 ms held, `Motion.veilOut` out |
| Favourite heart | `Motion.normal`, `Motion.enter`, **scale** 1.0 → 1.4, colour white → pinkAccent, forward-then-reverse |
| Now-playing bar entry | `.fadeIn().slideY(begin: 0.4)`, `Motion.normal`, `Motion.enter` |
| Bar → player | shared `Hero(tag: kNowPlayingHeroTag)` on the **artwork** |

**Exits are faster than entrances** — `Motion.exitOf(enter)`, 65%. A UI that
leaves at the same speed it arrives feels polite rather than responsive.

**Direction means something.** The rail's transition slides one way going down
the list of destinations and the other way coming back up, with the outgoing
page leaving toward where you came from. Every switch used to fly in from the
right whichever way you moved, and the outgoing page travelled the *same* path
at the *same* duration, so the two pages moved together instead of past each
other.

**List rows move vertically only.** They used to fly in from the right
(`horizontalOffset: 100`) while the page was itself sliding in from the right —
two competing right-to-left motions on the same frame.

Two speeds, deliberately: **content moves fast** (`fast`/`normal`/`page`,
150–300 ms) and **the background moves slowly** (`ambient`/`veilOut`, 3–4 s).
Never let the background animate at content speed — it turns the screen into a
strobe behind the text.

**No animation may stand in for latency.** Search's song rows carried a
hardcoded `await Future.delayed(400ms)` before navigating — 400ms of invented
wait on that screen's primary action. If something must wait, it waits on the
thing, not on a timer.

### Haptics

Three moments, and only three: **play/pause**, **favourite**, **tab change**.
They are the canonical ones on mobile and all three used to be silent.

| Moment | Feedback |
|---|---|
| Play / pause — player and bar | `HapticFeedback.lightImpact()` |
| Favourite, added *or* removed | `HapticFeedback.mediumImpact()` |
| Rail destination change | `HapticFeedback.selectionClick()` |

Tapping the destination you are already on fires nothing. Haptics confirm a
change; firing one for a no-op teaches the user to ignore them.

The favourite animation fires **only after the server confirms** the write
(`if (!wasFavourite && controller.isFavourite.value)`). Optimistic animation on a
failed write is a lie; keep this pattern for every new confirmation animation.

### Reduced motion

Everything above is gated on `noMotion(context)`, which reads
`MediaQuery.disableAnimations`. When it is set:

| Normally | Under reduced motion |
|---|---|
| `Motion.ambient` looping gradient | static gradient on the primary colours |
| Looping now-playing Lottie | static `Icons.graphic_eq_rounded` |
| Staggered list entrance | rows appear immediately |
| `Motion.page` rail switch | instant |
| Now-playing bar fade + slide | appears as-is |

Still ungated, and a known defect: the offline page's `FlickerAnimatedText`
loops forever regardless — `design_audit.md` **C3**, fixed by
`design_plan.md` item 4.

The veil still crossfades — it is a legibility device, not decoration, and
removing it would leave text over a raw bright cover.

Anything new that loops or moves needs its own branch here.

---

## 8. Content states

**Four states, in this order: `loading → error → empty → content`.** Every list
follows it, and they crossfade — the page used to swap its whole layout for one
centred spinner and then hard-cut to content.

```dart
Expanded(
  child: Obx(() => AnimatedSwitcher(
        duration: Motion.normal,
        child: _body(context),   // every branch returns a keyed widget
      )),
)
```

Each branch needs a `Key`, or `AnimatedSwitcher` cannot tell that the state
changed and will not fade.

| State | Treatment |
|---|---|
| Loading (list) | `SongListSkeleton` — rows matching `SongTile`'s geometry |
| Loading (Quick picks) | hero block + grid blocks on the *same* layout maths as the real screen |
| Loading (image) | `Skeleton` filling `RemoteImage`'s own box |
| **Error** | `ErrorState` — `cloud_off_rounded` in `AppColors.danger`, and a **Try again** |
| Empty / not built | `EmptyState` — `Space.xxxl` mark at `textTertiary`, `titleLarge` headline, `bodyMedium` explainer |
| Playback progress | `LinearProgressIndicator` at `Controls.progressBar` under the now-playing bar |
| Offline | `FlickerAnimatedText('No Connection')` at `titleLarge` + `kGlow`, gated on `noMotion`, `liveRegion` |

### Error is not empty

Every controller that fetches carries **`hasError`** alongside `isLoading`, set
in the `catch` *and* on a non-200. Before this, a failed request rendered the
empty state: "you have no favourites" and "the request failed" were
pixel-identical, and the user had no way to know whether retrying was worth it.
`ErrorState` always takes an `onRetry` — an error the user cannot act on is a
dead end.

### Empty states offer the next step

`EmptyState` takes `actionLabel` + `onAction`, rendered as a `FilledButton`.
Write the message as a next step ("Tap the heart while a song is playing"), not
a status report ("0 items") — and where there is a real next step, make it a
button:

| Screen | Action |
|---|---|
| Quick picks | **Reload** |
| Favourites | **Browse songs** → `NavController.go(NavDestination.quickPicks)` |
| Search, no matches | **Clear search** |
| Search, no query yet | *none* — the field is directly above it |
| Settings | *none* — it is a "coming soon", not an empty list |

Both parameters or neither. A button that does nothing useful is worse than no
button.

### Skeletons, not spinners

`Skeleton` (`global_widgets/skeleton.dart`) is a shimmering block; compose it to
match whatever the real layout will be, and derive its sizes from the *same*
maths the content uses. Quick picks computes `heroSide` and `columns` in a
`LayoutBuilder` above the state switch precisely so both branches share them —
a skeleton that lands somewhere other than the content is worse than none.

`noMotion` drops the shimmer and leaves the blocks static.

### Loading flags

Start **true** on controllers that fetch on open, so the first frame is a
skeleton rather than a flash of the empty state. Search is the exception — it
starts false, because "no query yet" is genuinely an empty state.

**Only show a skeleton when there is nothing to look at.** A refetch over
existing content keeps the content: search sets `isLoading` from
`searchSongResult.isEmpty`, and replaces the list in one assignment rather than
clearing then refilling. Clearing first is what made results blink empty
between keystrokes — swapping content for a skeleton and back on every
debounced stroke flickers worse than the re-stagger it replaced.

### Lists remember where they were, and can be pulled to refresh

Every scrollable that survives a tab switch carries a `PageStorageKey`, and
every list that fetches is wrapped in a `RefreshIndicator`. The pages are
destroyed on every rail switch, so a scroll offset has to live in the storage
bucket or it goes back to the top.

`NavController` (`controller/nav_controller.dart`) owns the rail index and the
transition direction. It exists so that anything on screen can move the user —
`pageIndex` used to be a `State` field on the Dashboard, which is why an empty
state could describe the next step but never offer it.

### Controllers come from bindings, always

Every controller is registered in `core/bindings.dart` and reached with
`Get.find`. **Never `Get.put` in a widget.** `Get.put(SongController())` on the
Search page constructed a whole controller — and so a whole `AudioPlayer` — on
every mount, only for GetX to keep the already-registered instance and drop the
new one. The page is remounted on every tab switch, so that leaked a player
each time. Constructing the argument is the cost; the registration check comes
too late to save you.

---

## 9. Icons

**Material rounded, one family, everywhere.** The transport row used to mix
Ionicons and Feather with a FontAwesome heart — three stroke weights in one row,
and the most obvious tell that the UI was assembled rather than designed.

Active/inactive is the **filled/outlined pair of the same icon**
(`favorite_rounded` / `favorite_border_rounded`), never a switch of family.

Sizes come from `Controls` in `tokens.dart`, not from literals at the call site.

| Context | Size |
|---|---|
| Player primary play/pause | `Controls.iconPrimary` |
| Player prev/next, page dismiss | `Controls.iconSecondary` |
| Favourite heart, bar play/pause | `Controls.iconInline` |
| Nav rail | 20 |
| Empty-state mark | 45 |

`flutter_vector_icons` is still in `pubspec.yaml` but no longer imported by any
live screen — drop it at the next dependency pass.

Never use emoji as an icon.

---

## 10. Images

Every remote image goes through `RemoteImage`
(`global_widgets/remote_image.dart`). Never call `CachedNetworkImage` — let
alone raw `NetworkImage` — directly.

```dart
RemoteImage(
  url: '$baseUrl${song.coverurl}',
  size: 50,
  radius: 12,
  semanticLabel: 'Cover art for ${song.title}',
)
```

It bakes in the three things that are easy to forget:

- **Fixed box first, image second**, so the list does not reflow as covers land.
- A `Skeleton` placeholder **and** an error widget on a 10% glass fill — enough
  rows have a missing cover that the fallback must look deliberate. The
  placeholder used to be a 16px ring at `strokeWidth: 0.5`: sub-pixel on a 1x
  device, and on any device it read as dirt on the screen rather than loading.
- A semantic label, since a cover with no label is announced as "image".
- A `Motion.normal` fade-in. Covers used to pop; nothing else in the app
  arrives that abruptly, and the artwork is the one thing being looked at.

URLs from the API are relative — always `'$baseUrl${song.coverurl}'`. Pass
`radius: 100` for the circular artist avatars and `fallbackIcon:
Icons.person_rounded` so the placeholder matches what is missing.

---

## 11. Applying this to a new screen

The shared widgets carry most of the language. Reach for them first — a screen
built from these is correct by construction.

| Widget | File | Gives you |
|---|---|---|
| `PageHeader` | `global_widgets/page_header.dart` | right-aligned 45px title that scales down rather than truncating, safe-area inset, optional glowing back arrow |
| `SongTile` | `global_widgets/song_tile.dart` | the song row, keys, now-playing marker |
| `RemoteImage` | `global_widgets/remote_image.dart` | fixed box, placeholder, error widget, semantics |
| `EmptyState` | `global_widgets/empty_state.dart` | the empty / not-built state, with an optional action |
| `ErrorState` | `global_widgets/empty_state.dart` | a failed request, with a retry |
| `Skeleton`, `SongListSkeleton` | `global_widgets/skeleton.dart` | loading placeholders |
| `GlassPanel` | `global_widgets/glass_panel.dart` | the glass recipe, all three levels |
| `staggeredEntrance` | `global_widgets/motion.dart` | list entrance, reduced-motion aware; pass `columnCount` for a grid |
| `NowPlayingMarker` | `global_widgets/song_tile.dart` | the one "this is playing" mark |
| `noMotion(context)` | `global_widgets/motion.dart` | the reduced-motion check |
| `kGlow` | `const/theme/tokens.dart` | the glow |

Then:

1. Return a bare `Column` — no `Scaffold`. The Dashboard owns the background and
   already renders each page inside one; a nested `Scaffold` only adds a layer.
2. `PageHeader('Title')` first, `Expanded` second.
3. Reach for an existing token before adding a value.
4. Glass comes from `GlassPanel`, never hand-rolled; rows use the flat `low`
   fill.
5. Glow on the active state and primary icons only.
6. Lists go `loading → error → empty → content` through one `AnimatedSwitcher`,
   every branch keyed; content wrapped in `AnimationLimiter`, one
   `staggeredEntrance` per row, `ValueKey` on every row.
7. Touch targets ≥ 48×48 dp; extend the hit area rather than growing the icon.
8. Anything that loops or moves gets a `noMotion(context)` branch.
9. Confirmation animations run **after** the server confirms.
10. Icon-only controls carry a `tooltip`; images carry a `semanticLabel`.

---

## 12. Assets

| File | Use |
|---|---|
| `assets/lottie_animations/musics_floating.json` | now-playing row marker |
| `assets/icons/megaphone.png` | empty / coming-soon state |
| `assets/vectors/album_line{,2,2x,2xx}.png` | unused — the "More" rule they drew went with the Artists rework |
| `assets/*.jpg`, `*.jfif` (Arijit, Billie, Bieber, Post Malone, The Weeknd, agartumsathho) | unused — leftovers from the mock data era |

`pubspec.yaml` globs all of `assets/`, so unused files still ship. Delete the
mock covers before release (~560 KB, all dead).

---

## 13. Accessibility

The rules the app already keeps, written down so they stay kept.

**Touch targets ≥ 48×48 dp.** Extend the hit area, never grow the icon: rail
buttons use `minimumSize: Size(48, 48)` (which the `RotatedBox` turns into the
rail's width), and icon buttons use
`BoxConstraints.tightFor(Controls.secondary)` around a smaller glyph.

**State is never carried by colour alone.** The active nav item is a filled
icon *and* a glow *and* `Semantics(selected: …)`. It used to be glow and colour
only — invisible to a screen reader, which had no way to say which destination
you were on. Wrap the whole control in `MergeSemantics` so the icon, the label
and the flag land on the one node a user swipes to.

**Fields carry a real `labelText`.** A `hintText` alone is announced as
nothing. The label should say what is being searched or entered, not be
conversational — "Search songs", with "Title or artist" as the hint.

**Anything that loops or moves gets a `noMotion(context)` branch**, including
decorative text effects. The offline page's flicker looped forever regardless
of the platform setting: a reduced-motion violation and a photosensitivity
concern in one widget.

**Type must survive Dynamic Type.** Never combine a large fixed size with
`maxLines: 1` and an ellipsis — that is how the 45px page title became
"Quick p…" at the first notch of the system text-size slider. Use
`FittedBox(fit: BoxFit.scaleDown)` where the size is part of the identity, and
let everything else grow.

**No fixed pixel heights on a screen that holds type.** See §Player page.

**Sliders announce a value, not a number.** `semanticFormatterCallback`, in
words — screen readers read `1:23` as "one colon twenty-three".

**State changes the user did not cause are `liveRegion`s** — the connection
dropping, for one.

**Images carry a `semanticLabel`; icon-only controls carry a `tooltip`.** Where
a composite row already has one label, use
`Semantics(label: …, excludeSemantics: true)` so it announces once instead of
once per child — and put that `Semantics` **inside** the `InkWell`, never
around it. From outside, `excludeSemantics` drops the InkWell's own tap action
and leaves a control a screen reader can read but not activate.

### Known gaps

| Gap | Owner |
|---|---|
| `RotatedBox` transforms semantics — rail traversal order needs a real VoiceOver / TalkBack pass | untested, needs a device |
| `_ArtistTile` announces the artist name twice (image label + visible label) | `design_plan.md` item 9 |
| Contrast of `AppColors.textSecondary` on the rail's 0.4 fill over a bright gradient is unmeasured | `design_plan.md` item 11 |
| A very long artist name in `PageHeader` now scales down instead of truncating, with no floor | acceptable, watch it |
