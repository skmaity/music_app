# Design audit — music_app · Phase 1

Audited against the **shipped code**, not `design.md`. Where the two disagree,
that disagreement is itself a finding.

Read: all 6 live screens, 5 shared widgets, `main.dart`, `AnimatedGradient`,
`BackgroundController`, `SongController`, the theme file.


Severity: **P0** broken · **P1** high impact · **P2** medium · **P3** polish.
Items marked ⚠ need on-device confirmation.

---

## Verdict

The app has something most apps this size do not: **one strong idea, executed
consistently.** The background *is* the music. Album art drives a live palette,
glass floats on it, glow marks what is live. That idea is worth protecting, and
nothing in this audit proposes replacing it.

What separates it from a shipped product is not the idea. It is that **the idea
was implemented as a set of literals rather than a system.** There are no tokens
in code. `Colors.grey.shade100.withValues(alpha: 0.1)` is typed out in five
files. Eight radii, nine spacing values, six mid-greys, seven font sizes with no
ratio between them. Every screen re-specifies what should be inherited, and each
one drifted slightly. Almost every finding below is a symptom of that one cause.

Second: **the app's own thesis is not on screen where it matters most.** The
identity is album art. The home screen shows album art at 50×50. The player
shows it squashed non-square on any phone narrower than 390pt. The most valuable
shared-element transition in a music app — art growing from row into player — is
spent on a music-note glyph instead.

Third: **hierarchy is done almost entirely with size.** No font weights are used
anywhere in the app. Everything is w400. Three transport buttons at identical
96dp. Row title and row subtitle in identical white. Professional interfaces
build hierarchy from weight, opacity and spacing *before* reaching for size —
which is why they hold up at 12px and at 45px.

Grade: a strong art-directed prototype at roughly **6/10** against the reference
tier. The gap is closeable — most of it is one token layer and one theme file.

---

## Part A — Five root causes

Fix these and roughly 60% of Part B disappears.

**A1 · No token layer (P1).** `const/theme/dash_board_options_colors.dart` holds
two colours and one shadow. Everything else is a magic number at its use site.
Consequence: changing the glass recipe means editing five files, and nobody
does, so they drift.

**A2 · `ThemeData` is nearly empty (P1).** `main.dart` sets `textTheme`,
`textButtonTheme`, `colorScheme` — and nothing else. No `sliderTheme`,
`listTileTheme`, `iconTheme`, `inputDecorationTheme`, `progressIndicatorTheme`,
`appBarTheme`. So every component styles itself inline, and every screen is a
fresh chance to be inconsistent.

**A3 · `ColorScheme.fromSeed(seedColor: Colors.blue)` (P1).** The app is
white-on-gradient with one pink accent. But M3 derives from that blue seed: the
slider's **inactive track and thumb**, the text-field **cursor and selection
handles**, **every ListTile ripple**, and default progress-indicator colour. So
blue-violet ripples fire on song rows sitting over an orange album gradient.
This is a visible, on-screen inconsistency, not a theoretical one.

**A4 · Hierarchy has only one tool (P1).** No `fontWeight` appears in any UI
file. No letter-spacing. No line-height. Size and the glow carry everything.

**A5 · `design.md` has already drifted from the build (P2).** Transport icons:
§Player says 22, §Icons says 28, code says 28 — *the spec contradicts itself.*
Artist name width: spec says 100, code says `size` (110/130). Spec says the row
subtitle is metadata; code paints it the same full white as the title. A spec
that no longer matches the build stops being used, which is how the drift
accelerates.

---

## Part B — Section by section

### 1. Typography — P1

**Works.** One family, set globally. Tabular figures on the player timestamps —
a genuinely professional touch most apps miss. Josefin Sans is a good, slightly
unusual choice that reads as deliberate.

**Fails.**

- **The scale is not a scale.** 12 · 14 · 16 · 18 · 25 · 30 · 45. Step ratios:
  1.17, 1.14, 1.13, **1.39**, 1.20, **1.50**. Those two outliers are where
  values were picked by eye. A real scale has one ratio.
- **Nav labels are Pacifico** — a script face — for functional navigation,
  rotated 90°, at 16px, over moving glass. `design.md` calls the contrast
  intentional. It is the single loudest "assembled, not designed" signal in the
  app: script display faces are for one word at large size, never for repeated
  UI labels, and never rotated. Pacifico also has one weight, so those labels
  can never participate in the weight hierarchy.
- **No weights.** Everything is regular. `Text` styles across all six screens
  never set `fontWeight`.
- **45px display type at default line-height and zero tracking.** Josefin Sans
  at 45px needs roughly `height: 1.0–1.1` and `letterSpacing: -0.5 to -1.5`.
  Left at defaults it looks like body text that was enlarged.
- **The player's most important text is 18px** — smaller than the 45px word
  "Favourites" on a list screen. The single most-looked-at string in the app is
  ranked below a tab label.
- **Title and artist are concatenated:** `"$title - $artist"` in one 18px line
  with one ellipsis. Two different information levels welded with a hyphen. When
  it truncates, it eats the artist first. This is the most amateur single line
  of UI in the codebase.
- **Row title and row subtitle are the same colour.** `SongTile` title is white,
  subtitle is `Colors.white` at 12px. Hierarchy by size alone; no tonal step.
- `NointernetPage` calls `GoogleFonts.josefinSans()` directly rather than reading
  the theme.

### 2. Spacing — P2

**Works.** Consistent 10/5 padding on the song row; the right-aligned header
inset is applied uniformly.

**Fails.**

- **Two competing rhythms.** 4 · 5 · 8 · 10 · 20 · 50 · 60 · 70 mixes a 4/8 grid
  with a 5/10 grid. Android is an 8dp platform; 5 and 10 fight it everywhere.
- **`SizedBox(height: 2)`** between the empty-state headline and its message.
  2px is not a spacing value; it is an accident, and it makes the two lines
  collide.
- **Gutters disagree.** `PageHeader` insets `LTRB(4,10,10,10)`; `SongTile`
  `horizontal: 10` plus a further `contentPadding: 10`; `EmptyState`
  `horizontal: 24`; artist list `left: 10`. Nothing shares a vertical edge, so
  no page has a spine.
- **`SizedBox(height: 70)`** at the bottom of Settings only. A magic number that
  exists on exactly one screen, pushing its empty state visibly off-centre.
- **Fixed pixel dimensions on the player** (`height: 470`, `width - 50`) — see
  §16. Fixed heights are the classic non-responsive tell.

### 3. Layout hierarchy — P1

**Works.** The right-aligned title mirroring the left rail is a genuinely
distinctive, ownable layout move. Keep it.

**Fails.**

- **The 45px title is the largest element on every screen and carries the least
  information.** The user already knows which tab they are on — the rail says so
  with a filled icon and a glow. On a 375×812 phone that header consumes ~110pt
  (≈14% of the viewport) to restate the nav. Apple Music and Spotify both solve
  this by letting a large title *collapse to inline on scroll*, which keeps the
  identity and returns the space to content.
- **The mini player shows nothing about the music.** It is a note glyph in a
  progress ring. No artwork, no title, no play/pause. The user cannot tell what
  is playing, or pause it, without a full navigation. Every reference app puts
  art + title + a play/pause control there. This is the largest functional gap
  in the UI.
- **`mainAxisAlignment: MainAxisAlignment.center` inside a
  `SingleChildScrollView`** (`dashboard_page.dart:105`) does nothing — the
  cross-axis is unbounded, so the rail is top-aligned in practice while the code
  claims it is centred. Also means rail + mini player scroll on short screens.
- **No bottom safe-area inset on any list.** `PageHeader` is `SafeArea(bottom:
  false)` and no list adds a bottom pad, so the final row sits under the gesture
  bar on every modern phone. **P0-adjacent.**

### 4. Visual rhythm — P2

**Fails.**

- **Eight radii** for a six-screen app: 100 · 30 · 20 · 15 · 12 · 10 · 8 · 4.
- **Album art has three different radii** depending on where it appears: 12 in a
  row, 4 in the player, 100 as an artist. Same content, three shapes.
- **Nested radii are not concentric.** Player card r10 containing art at r4 with
  20 padding. The rule is *inner = outer − padding*; here the inner corner is
  tighter than the outer, which reads as a mistake even to people who cannot
  name it.
- **Two greys with no reason.** Fills use `grey.shade100`, borders use
  `grey.shade200`. That difference is invisible and therefore pure noise.

### 5. Colour system — P1

**Works.** The discipline of *no brand colour, hierarchy from white opacity* is
a real and defensible position. Reserving `pinkAccent` for the heart alone is
excellent — one emotional control, one colour.

**Fails.**

- **A3 above:** blue-seeded ripples, cursor, selection handles and slider
  inactive track leak into a palette that has no blue.
- **The `Slider` sets only `activeColor`.** Inactive track and thumb are
  theme-derived → blue. On the app's single most important control.
- **Six mid-whites doing one job:** `white54`, `white70`, `withAlpha(150)`
  (=59%), `white30`, plus the glass fills at 0.1/0.2/0.4. 54% vs 59% vs 70% are
  not perceptibly different — they are proof that no scale exists.
- **The player's resting veil is `0.0`.** Nothing between a bright vibrant
  gradient and 18px white text except a 0.2 glass fill. `design.md` §1 itself
  warns this can drop below 4.5:1. On a white or yellow cover it will. ⚠
- **Missing swatches fall back to `Colors.white`.** One missing swatch on a dark
  app produces a full-screen white gradient stop.
- **There is no error/danger colour.** Failure has no visual language at all.

### 6. Glassmorphism — P2

**Works.** Clip → blur → fill, in that order, is correct and consistently
applied. Restricting blur to panels over content while rows use a flat fill is a
sound, performance-aware rule.

**Fails.**

- **"Glass" means three different things:** blurred + 0.4 fill (rail), blurred +
  0.2 (player card), unblurred + 0.4 (mini chip), unblurred + 0.1 (rows,
  transport). Two of those have borders, two do not. There is no elevation
  ladder — just four unrelated recipes.
- **The rail at 0.4 white fill is not glass, it is a grey bar.** And it produces
  the app's weakest contrast pair: white text on a ~40% white surface.
- **No edge highlight.** Every mature glass system (Apple's materials, Vision
  OS) defines the surface with a 1px light hairline on the leading edge. Without
  it, glass reads as fog rather than a pane.
- **The rail's `BackdropFilter` re-blurs every frame** while the gradient
  animates continuously behind it, with no `RepaintBoundary`. Continuous
  full-height blur is the most expensive thing on screen. ⚠

### 7. Background gradients — P1

**Works.** The concept. Palette caching through Flutter's image cache. Keeping
the previous palette on failure instead of flashing. The veil-during-swap
mechanism is thoughtfully built.

**Fails.**

- **A two-stop linear gradient is the least sophisticated gradient form.** It
  produces a diagonal band, not an atmosphere. Reference apps anchor a radial
  bloom behind the art and keep a dark base at the bottom so bottom-anchored UI
  always has ground to sit on.
- **The tween swaps hue, not just position.** `vibrant → dominant` across 4s
  means the whole screen changes colour continuously. `design.md` warns against
  exactly this ("it turns the screen into a strobe behind the text") and then
  does it — the fix is to hold luminance and hue roughly constant and animate
  only the alignment.
- **`vibrantColor` can be near-neon**, and it is applied full-bleed. There is no
  luminance clamp between the palette and the screen.
- **No cache keyed on cover URL** — replaying the same song re-runs
  `PaletteGenerator` and re-triggers the veil.

### 8. Shadows, borders, elevation — P2

**Fails.**

- **There are no shadows in the app.** None. So there is no depth language: the
  rail, the player card and a list row all float at the same z. Glass alone does
  not establish order — it establishes *material*.
- **The glow is doing a shadow's job.** Light emitted outward cannot read as
  "above"; it reads as "on".
- **0.5px borders at 40% opacity over a moving gradient are invisible.** They
  read as a smudge on the edge of the row. Either commit (1px, higher opacity)
  or remove.
- **`FloatingActionButton.large` with all five elevations zeroed** is a FAB used
  as a shaped box. Wrong widget, and it is why the code needs three distinct
  `heroTag`s to avoid a runtime throw.

### 9. Iconography — P1

**Works.** One family (Material rounded), and the filled/outlined pair used for
active/inactive state is exactly right. `design.md` §9 correctly identifies the
old mixed-family transport row as the previous worst offender.

**Fails.**

- **Six icon sizes:** 20, 24 (default back arrow), 28, 45, plus a heart
  animating 25→50.
- **The filled/outlined rule is broken in the two places it matters most.** The
  mini player and the player's back button both use
  `Icons.music_note_outlined` — the *outlined* variant to represent *active
  playback*.
- **The search field's affordance icon is a music note.** It occupies the exact
  position users reach for the clear "×", it is not tappable, and it does not
  say "search".
- **The player's back control is a music note.** A glyph with no learned meaning
  as "back". Users expect a chevron-down on a full-screen player.
- **The heart animates its `size`, 25 → 50, inside a fixed 60×60 box.** Animating
  a layout dimension is the layout-shifting-feedback anti-pattern; it also means
  the burst is clipped by its own container at peak.

### 10. Motion — P1

**Works.** The two-speed principle (content fast, background slow) is correct
and rare. Reduced motion is genuinely wired through `noMotion()` — most apps at
this stage have nothing. `slideOnly` on the seek bar is a real usability call.
Animating the heart **only after the server confirms** is a discipline most
production apps get wrong.

**Fails.**

- **800ms tab transition.** Material specifies ~300ms for a full-screen change;
  iOS ~350. At 800ms the most-repeated interaction in the app feels sluggish,
  and it is 2.5× over budget.
- **Direction has no meaning.** Every page slides in from the right whether you
  moved forward or back through the rail. And `AnimatedSwitcher` runs the
  outgoing page along the *same* path at the *same* duration, so both pages
  travel together — muddy rather than spatial.
- **100ms stagger** against Material's 20–50ms. A 20-row list takes two full
  seconds to finish appearing. And the rows fly in *from the right* (`horizontal
  Offset: 100`) while the page itself is sliding in from the right — two
  competing right-to-left motions on the same frame.
- **A hardcoded `await Future.delayed(400ms)`** before navigating from a search
  result (`songs.dart:105`). 400ms of unexplained latency on that screen's
  primary action.
- **Exit is not faster than enter** anywhere; there is no easing token, no
  duration token, and no spring anywhere in the app.
- **The favourite animation is asymmetric** — it fires on add, never on remove.

### 11. Page transitions — P1

**Fails.**

- Covered above (800ms, no direction logic).
- **`Hero(tag: 'music')` flies an icon.** The most valuable shared element in a
  music app is the artwork growing from the tapped row into the player. It is
  already the app's thesis — and the hero is spent on a note glyph instead.
- **No swipe-down-to-dismiss on the full-screen player.** Standard on every
  reference app; its absence is felt immediately.

### 12. Component consistency — P1

**Works.** `SongTile` genuinely is one component used in four places, with
`isPlaying` correctly compared on **songid, not index** — a subtle bug most
codebases ship. `RemoteImage` centralising fixed-box + placeholder + error +
semantics is exactly the right call.

**Fails.**

- **The same user action behaves four different ways.** Tapping a song: Quick
  picks fires and navigates immediately; Search unfocuses, waits 400ms, then
  navigates; Artists chains `.then()`; Favourites navigates without a
  `context.mounted` guard. Four implementations of one interaction.
- **`NointernetPage` returns its own `Scaffold`** inside the dashboard's
  Scaffold — a direct violation of `design.md` §11 rule 1, in the app's own
  code.
- **No error-state component exists.** Every failure renders the *empty* state,
  so "you have no favourites" and "the request failed" are pixel-identical. The
  user has no way to know whether to retry.
- **No skeletons.** Every list swaps its whole layout for one centred spinner,
  then hard-cuts to content. No crossfade.
- `NointernetPage` contains a `print()`, a commented-out `Text`, an `onTap` that
  does nothing, and no retry action.

### 13. Accessibility — P1

**Works.** 48dp minimum targets on the rail (with the `RotatedBox` trick
correctly reasoned). `semanticLabel` on every remote image. Tooltips on
icon-only controls. `Semantics(label: 'Now playing')` on the marker. A real
reduced-motion path. This is well above average for the stage.

**Fails.**

- **Nav items carry no `selected` semantic state.** The active tab is signalled
  by glow only — colour/visual alone, invisible to a screen reader.
- **The offline page is a `FlickerAnimatedText` looping forever, not gated by
  `noMotion`.** A flickering element is both a reduced-motion violation and a
  photosensitivity concern. **P0 for accessibility.**
- **The seek `Slider` has no semantic label or value formatter** — announced as
  a bare number with no unit or meaning.
- **The search field is placeholder-only labelled.** No `labelText`; the hint
  "What's on your mind" does not state what is searched.
- **Text scaling is unsupported.** Every size is hardcoded; `PageHeader` is
  `maxLines: 1` + ellipsis at 45px, so "Quick picks" truncates to "Quick p…" at
  large Dynamic Type, and the fixed-470 player card overflows. ⚠
- **`white54` nav-inactive on a 0.4-white rail over a bright gradient** is very
  likely under 3:1. ⚠
- `_ArtistTile` announces the artist name twice (image `semanticLabel` + the
  visible label below it).
- `RotatedBox` transforms semantics; rail traversal order needs a VoiceOver /
  TalkBack pass. ⚠

### 14. Empty states — P2

**Works.** One component, used everywhere. The copy rule in `design.md` — write
the next step, not the status — is right, and Favourites follows it ("Tap the
heart while a song is playing").

**Fails.** The 2px headline/message gap. A 45px icon at `white70` above a 25px
headline is top-heavy — the mark outweighs the message. No empty state offers an
**action**; they are all read-only. Reference apps put a button there ("Browse
songs").

### 15. Loading states — P1

**Fails.**

- **One centred spinner replaces the entire page**, destroying the layout and
  causing a full flash on every load. Skeleton rows matching `SongTile`'s
  geometry would keep the page stable and read as faster.
- **`RemoteImage`'s placeholder is a 16px ring at `strokeWidth: 0.5`.**
  Sub-pixel on a 1x device and near-invisible on any device — it reads as dirt
  on the screen, not as loading.
- **Hard cut from loading to content**, no crossfade.
- **The play/pause button has no buffering state** — it looks frozen while
  `just_audio` buffers.

### 16. Player page — P0 / P1

**Works.** Composition is sound: art, title, seek, transport, top to bottom.
Tabular figures. `slideOnly`. Distinct hero tags. Zeroed elevations.

**Fails.**

- **P0 — the artwork is not square on most phones.** Card width is `screenWidth
  − 50`, inner padding is 20 per side, so the content box is `screenWidth − 90`.
  The art is `RemoteImage(size: 300)`. On a 375pt phone that is a 285-wide
  constraint against a 300 request → the "square" cover renders **285 × 300**
  and `BoxFit.cover` crops it. Same on 360pt Androids and the iPhone mini. It is
  only correct at ≥390pt. **The app's central visual element is geometrically
  wrong on a large share of devices.**
- **P1 — the fixed `height: 470` card has ~10pt of slack and no more.** Measured
  against the SDK: 20 + 300 (art) + 5 + 60 (the heart's `SizedBox`) + 20 + 30
  (Slider = overlay radius 15 ×2) + ~24 (timestamps) ≈ **459**. It fits at 100%
  text scale and **overflows at roughly 103%** — i.e. at the first notch of
  Dynamic Type / Android font scaling, which a large share of users run.
- **P1 — three identical 96dp transport buttons.** `FloatingActionButton.large`
  is 96×96. Previous, play and next carry exactly equal visual weight, so the
  screen has no primary action. Every reference player makes play dominant
  (filled, larger) and prev/next secondary (ghost, smaller). This is the single
  clearest hierarchy failure in the app.
- **P1 — title and artist concatenated with a hyphen** (see §1).
- **P1 — 1.5px seek track.** Thinner than any mainstream player (~4px). It reads
  as a hairline rule, not as a control you can grab.
- **P1 — the resting veil is 0.0** (see §5) — the least protected text in the
  app sits on the brightest possible background.
- **P2 — the card has no room to grow.** Shuffle, repeat, volume, speed, queue
  and a sleep timer are all planned (`claude_code_prompt.md` Task 3). Six more
  controls cannot go into a fixed 470pt box. The layout must be re-architected
  *before* those land, or they will be bolted on.

### 17. Home / Quick picks — P1

**Fails.** The home screen is a flat vertical list of 50×50 rows — **visually
identical to Search and to Favourites.** Three of five destinations render the
same screen with a different word at the top.

The app's entire premise is that album art is the experience. The home screen
shows album art smaller than anywhere else in the app. There is no hero, no
artwork-forward moment, no sectioning, one density, one content type. This is
the largest strategic miss: the screen that should sell the idea is the screen
that hides it.

### 18. Navigation — P1

**Works.** A left vertical rail is genuinely distinctive and is half the app's
identity. Five destinations is the correct cap. Filled/outlined state is right.

**Fails.**

- **Rotated script labels.** Bottom-to-top text costs a head tilt on every read;
  in Pacifico, over glass, at 54% white when inactive, it is the least legible
  text in the app.
- **Left-edge placement is the hardest zone for one-handed reach** on a phone.
  Primary navigation sits where the thumb reaches last. This is the one genuine
  usability argument for change — and it can be answered *without* abandoning
  the rail (anchor it lower, grow the targets) rather than by replacing it with
  a bottom bar, which would cost the identity.
- **No active-state semantics** (see §13).

### 19. Lists — P2

**Fails.** No separators, no section headers, no sticky context, no
scroll-position restoration between tabs. Every list is `ListView.builder` with
zero bottom inset (see §3). Rows have a 60px+ height with a 0.5px border and a
10/5 pad — dense enough to feel like a table, not curated.

### 20. Cards — P2

The only card in the app is the player card, and it is fixed-size (§16). There
is no card component, no card token, no card elevation.

### 21. Buttons — P1

**Fails.** There is no button system. The app contains: `TextButton.icon`
(rail, script font), `IconButton` (heart, back), `FloatingActionButton.large`
(transport, elevation-stripped), bare `InkWell` (mini player, artist tile). Four
mechanisms, no shared shape, no shared state layer, no disabled style, no
pressed style defined anywhere.

**Two of them have no visible press feedback at all:** the mini-player `InkWell`
and `_ArtistTile`'s `InkWell` both sit above their own opaque containers with no
local `Material` ancestor, so the ink splash paints *behind* the widget. Tapping
them looks like nothing happened until the navigation lands. ⚠

### 22. Sliders — P1

Covered in §5 (blue inactive track) and §16 (1.5px track). Add: no semantics, no
buffered-progress indication, and the thumb is a plain 8pt circle with a 15pt
overlay — no scale-on-drag, no time bubble.

### 23. Album artwork presentation — P1

The app's thesis, and its weakest execution.

- 50×50 in every list — the smallest artwork of any music app of this type.
- Non-square in the player on most phones (§16).
- Three different corner radii for the same asset (§4).
- Never used as a hero transition (§11).
- No shadow, glow, or reflection under the player artwork — it sits flat on
  glass with a 4px radius and nothing separating it from the card.

### 24. Artist pages — P2

**Fails.**

- **Circles for the top five, rounded squares for everyone else.** One entity
  type, two shapes. Artists are circles everywhere in the industry precisely
  because shape encodes *kind*.
- **The "rows of five" are horizontally-scrolling `ListView`s.** So the grid
  below "More" scrolls sideways with no affordance, no peek, no indicator.
  Users will not discover it, and it conflicts with vertical scroll intent.
  It should be a `GridView`/`Wrap`.
- The `album_line2.png` raster rule next to the "More" heading is a bitmap doing
  a divider's job — it will not scale, tint or adapt.
- No artist header on the songs view: tapping through gives a bare `PageHeader`
  with the name, no image, no bio, no song count — while the API returns all
  three.

### 25. Search — P1

**Fails.**

- **No debounce.** Fires per keystroke — and because the results are wrapped in
  `staggeredEntrance`, the entire list *re-animates in from the right on every
  character typed.* Visually chaotic and the single most jarring moment in the
  app.
- Opens blank into an empty state.
- Placeholder-only label; music-note suffix instead of a clear button (§9).
- 400ms artificial delay before navigating (§10).
- The 45px "Songs" header plus the field puts ~140pt of chrome above the first
  result.
- No recent searches, no suggestions, no result count.

### 26. Mini player — P1

Covered in §3. To restate its severity: it displays **no information about the
music.** No art, no title, no artist, no play/pause, no dismiss. It is a
navigation affordance wearing the name of a component that exists to make
navigation unnecessary.

### 27. Micro-interactions — P2

**Fails.** No haptics anywhere — play/pause, favourite and tab change are the
three canonical haptic moments on mobile and all three are silent. No press
states (§21). No scale-on-press. Ripples are blue (§5). The heart's burst is
clipped by its own 60pt box (§9).

### 28. Animations — P1

Timing summary against platform guidance:

| Animation | App | Standard | Verdict |
|---|---|---|---|
| Tab transition | 800ms | 300–350ms | 2.5× too slow |
| List stagger | 100ms/item | 20–50ms | 2–5× too slow |
| List item slide | 300ms | 200–300ms | OK |
| Heart | 300ms | 150–300ms | OK |
| Veil out | 3000/5000ms | — | intentional, keep |
| Gradient | 4000ms loop | — | intentional, keep |

No easing tokens, no spring curves, no `exit < enter` rule, and no
`Curves` beyond `easeInOut` / `ease`.

---

## Part C — Confirmed defects (broken, not taste)

| # | Defect | File | Sev |
|---|---|---|---|
| C1 | Player artwork renders 285×300 (non-square, cropped) on <390pt phones | `player_page.dart:126,136` | P0 |
| C2 | Fixed `height: 470` card overflows at ~103% text scale | `player_page.dart:125` | P1 |
| C3 | Offline flicker animation is not gated by `noMotion` | `nointernet_page.dart:37` | P0 |
| C4 | No bottom safe-area inset — last row under the gesture bar | all list pages | P1 |
| C5 | Blue-seeded ripple / cursor / slider-inactive across the app | `main.dart:30` | P1 |
| C6 | Ink splash invisible on mini player and artist tiles ⚠ | `dashboard_page.dart:217`, `artists_page.dart:160` | P1 |
| C7 | Search re-staggers the whole list on every keystroke | `songs.dart:42` | P1 |
| C8 | `totalDuration.value = duration!` force-unwraps a null between tracks | `song_controller.dart:48` | P1 |
| C9 | `mainAxisAlignment: center` is a no-op inside the scroll view | `dashboard_page.dart:105` | P2 |
| C10 | `print()` and a dead `onTap` shipping in the offline page | `nointernet_page.dart:43` | P2 |
| C11 | Artist "grid" rows scroll horizontally with no affordance | `artists_page.dart:113` | P2 |

**Checked and dismissed:** `Slider(min: 0, max: 0)` before the duration resolves
is *safe* — `_unlerp` guards with `max > min ? … : 0.0` (`slider.dart:802`). Not
a defect.

---

## Part D — The details that separate this from a billion-dollar product

Small individually. Collectively they *are* the difference.

1. Album art never animates in — no fade-up from placeholder, so every cover
   pops.
2. No shadow or bloom beneath the player artwork; it has no weight.
3. Seek thumb does not scale on grab, and there is no time bubble while
   scrubbing.
4. No buffered-progress track behind the played progress.
5. Timestamps are `00:00` even for tracks under a minute — should be `0:42`.
6. Track title does not marquee when it truncates.
7. No haptic on play, favourite, or tab change.
8. Tapping the currently-playing row re-navigates instead of just opening the
   player.
9. No scroll-position memory when returning to a tab.
10. No pull-to-refresh on any list.
11. Nothing indicates *which list* is the queue once you are in the player.
12. The favourite heart animates on add but not on remove.
13. No confirmation or undo on removing a favourite.
14. The empty states offer no action.
15. Loading spinners have no minimum display time, so fast responses cause a
    flash of spinner.
16. No `RepaintBoundary` around the animated gradient or the blurred rail.
17. The offline page offers no retry.
18. `album_line2.png` is a raster divider.
19. Icon sizes are literals at every call site.
20. No app icon / splash treatment reflecting the design language (worth a
    separate pass).

---

## Phase 2 preview

Phase 2 will rank everything above by **impact ÷ effort** and produce a build
order. The shape it will take:

1. **The token layer + theme** — one file, kills most of Part A and much of
   Part B. Highest leverage change in the audit.
2. **The player page** — three P0 defects and the app's worst hierarchy problem
   in one screen.
3. **The mini player** — largest functional gap, self-contained.
4. **Motion retiming** — a one-line-per-value change that makes the whole app
   feel twice as fast.
5. **The home screen** — the largest strategic gain, and the largest effort.

Nothing in this plan changes the background system, the rail, the right-aligned
header, the glow, the pink heart, or the glass. Those are the identity. The work
is making the rest of the app as considered as they are.
