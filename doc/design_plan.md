# Design plan — music_app · Phase 2

Prioritisation of `design_audit.md` by **impact ÷ effort**, with the build order
Phase 3 will follow.

---

## Progress

Updated **2026-08-04**. One row per build item; ✅ done · ▶ in progress ·
☐ not started · ⏪ reverted. This table is the only place status is recorded —
update the row as the last step of every item (see *Phase 3 protocol*).

| # | Item | Status | Impact | Effort | Fixes |
|---|---|---|---|---|---|
| F1–F2 | Foundation — tokens + theme | ✅ | ●●●●● | ●● | A1 A2 A3 C5 |
| 1 | Player page | ✅ | ●●●●● | ●●● | C1 C2 + hierarchy |
| 2 | Motion retiming | ✅ | ●●●● | ● | §10 §11 §28 |
| 3 | Now-playing bar | ✅ | ●●●● | ●● | §3 §26 |
| 4 | Accessibility batch | ✅ | ●●● | ● | C3 C4 §13 |
| 5 | Home screen | ✅ | ●●●●● | ●●●● | §17 §23 |
| 6 | List states | ✅ | ●●● | ●● | §12 §14 §15 |
| 7 | SongTile | ✅ | ●●● | ● | §1 §19 §21 |
| 8 | Search | ✅ | ●●● | ●● | C7 §25 |
| 9 | Artists | ✅ | ●● | ●●● | C11 §24 |
| 10 | Background | ⏪ | ●● | ●● | §7 |
| 11 | Glass ladder | ✅ | ●● | ●● | §6 §8 |
| 12 | Polish | ✅ | ●●● | ●●● | Part D |

**12 of 13 built, 1 reverted.**

### Item 10 was reverted on device evidence

Two regressions, both reported from a real run:

1. **The gradient showed the same colour for every song.**
2. **Pressing next/previous stopped the animation, permanently.**

Cause of (2) is certain: the palette cache returned early *before*
`hideVisibility()`, and since `startPlaying()` raises the veil itself, stepping
back to an already-played song left an opaque black curtain up for good.

Cause of (1) was never found. The colour maths was simulated against the real
covers and preserves hue correctly; the covers load; the endpoint is fine. It
could not be isolated without running the app, so the whole rework went back
rather than shipping a screen that half-works.

**What this means for the rest of the plan:** every item here was verified by
`flutter analyze` and by reasoning from constraints, and item 10 proves that is
not sufficient for anything visual. The project total went 27 → 24 issues and
every touched file is clean — but a type checker is not a pair of eyes.
**Walk the app before trusting any of it.**

Two things from item 12's list were deliberately not built:

- **Marquee on truncated titles.** It re-introduces a dependency the cleanup in
  `progress.md` wants gone, it scrolls forever so it needs its own reduced-
  motion branch, and the player's title now runs to two lines at 24px, so
  truncation is much rarer than it was at one line of 18px.
- **A minimum display time on loading states.** The problem it solves — a flash
  of loading on a fast response — was real when every list cleared itself for a
  centred spinner. With skeletons that match the content's geometry and a
  crossfade between states, the remaining case was search, and that is fixed
  properly instead: results stay on screen rather than being swapped for a
  skeleton at all. Adding latency back after item 2 deleted a hardcoded 400ms
  wait would have been the wrong trade.

The one design item still open anywhere is `design_audit.md` §7's gradient
*form* — a radial bloom instead of two linear stops. See item 10's note.

> **Left open on purpose, item 10.** `design_audit.md` §7's first finding is
> that a two-stop linear gradient makes a band, not an atmosphere, and that the
> reference answer is a radial bloom behind the artwork. That changes the
> *form* of the background, and the background is on the "not being touched"
> list above — it needs a deliberate decision, not a drive-by. Everything else
> in §7 is done.

**Every defect in `design_audit.md` Part C — C1 through C11 — is closed.**

Item 9 also **wired the Artists screen to its backend**, which was the largest
open item in `progress.md`. Its header needs the bio and song count the API
returns, so the model, a real `ArtistController` and the two URLs were the
enabling work rather than scope creep. All six screens now have a backend.

> **Item 7 needs re-scoping.** Its plan bullet says `SongTile` becomes "the hero
> source for the player transition" — that is not possible as written. The
> now-playing bar and any list row live on the *same* route, and Flutter throws
> on two heroes sharing a tag in one subtree. The artwork hero belongs to the
> bar (item 3). Item 7 keeps its other three parts: tonal step between title and
> artist, a visible press state, larger artwork.

Picked up along the way, outside the items' own lists: the seek slider's
semantic value; the dashboard veil's resting alpha unified with the player's
under one `kVeilRest`; C4 and C9 because item 3 restructured the exact code they
live in; C10 and the offline page's nested `Scaffold` because item 4 rewrote
that widget anyway; and a real bug — the favourite pop was built inside an `Obx`
reading an `AnimationController`, which `Obx` does not listen to, so the
animation never played.

---

## Locked decisions

Answered before prioritising, because they change the list:

| Question | Decision | Effect on this plan |
|---|---|---|
| Pacifico nav labels | **Keep.** Fix legibility only | Typography work is contrast/tracking/state, not a family swap |
| 45px right-aligned header | **Keep fixed.** No collapse-on-scroll | Drops a Tier-1 item; still fix line-height, tracking, text-scaling truncation |
| Mini player | **Art + title + play/pause** | Promotes it to a real component; needs a new home (bottom-anchored, spanning the content column) |

## Not being touched

Stated once so it stays true through every later phase. These are the identity:

- The album-art-driven gradient background and the veil system
- The left vertical nav rail, and its five destinations
- The right-aligned 45px page title
- The white glow, and its "this is live" meaning
- `pinkAccent` as the only fixed accent, on the heart alone
- Glass as the panel material
- GetX, and every existing UX flow

---

## Build order

### Tier 0 — Foundation ✅ done

`const/theme/tokens.dart` · `const/theme/app_theme.dart` · `main.dart` ·
`const/theme/dash_board_options_colors.dart`. `flutter analyze` clean on all
four; project total unchanged at 27 pre-existing issues in files not touched.

Everything below depends on this. It is also the single highest-leverage change
in the whole audit: it closes root causes **A1, A2, A3** and defect **C5**, and
removes the *cause* of most Tier 1–3 inconsistencies rather than their symptoms.

**F1 · Token layer** — one file, `const/theme/tokens.dart`.
Spacing, radius, type, colour, glass, elevation, motion. Every literal in the
audit resolves to a name here. Scales get fixed as they are written:

- Spacing collapses from `4·5·8·10·20·50·60·70` to an 8pt-based set
- Radius collapses from eight values to four
- Type gets one ratio, and gains weight + tracking + line-height per step
- The six mid-whites collapse to a three-step opacity ladder
- Glass collapses from four unrelated recipes to three levels

**F2 · A real `ThemeData`** — `sliderTheme`, `listTileTheme`, `iconTheme`,
`inputDecorationTheme`, `appBarTheme`, `progressIndicatorTheme`,
`textSelectionTheme`, and an **explicit dark `ColorScheme`** replacing
`fromSeed(Colors.blue)`. Kills the blue ripples, the blue cursor and the blue
slider track everywhere at once, with no per-screen edits.

> Tier 0 changes no layout. It should be visually near-invisible except that the
> blue disappears — which is exactly what makes it safe to do first.

---

### Tier 1 — Highest impact, contained effort

**1 · Player page.** Highest-value screen in the app, and it holds the audit's
only P0 alongside its worst hierarchy failure.

- Fix **C1**: artwork is non-square and cropped on every phone under 390pt
- Fix **C2**: fixed `height: 470` overflows at ~103% text scale
- Split `"$title - $artist"` into two ranked lines
- Give the transport a primary: play dominant, prev/next secondary — not three
  identical 96dp buttons
- Replace `FloatingActionButton.large`-as-a-box with a real control
- Thicken the seek track; add a contrast floor to the resting veil
- Re-architect so the six controls planned in `claude_code_prompt.md` Task 3
  (shuffle, repeat, speed, volume, timer, queue) have somewhere to go

**2 · Motion retiming.** Roughly a dozen numbers. Nothing else in the audit
changes how the whole app *feels* for so little work.

- Tab transition 800ms → ~300ms, and direction-aware
- Stagger 100ms → ~40ms per item
- Delete the hardcoded `Future.delayed(400ms)` before search navigation
- Add duration + easing tokens so nothing drifts again

**3 · Mini player → now-playing bar.** Art, title, play/pause. Largest
functional gap in the UI, and self-contained. Needs a bottom-anchored home, and
the `Hero` moves from the note glyph to the artwork — which finally spends the
app's best transition on the app's own thesis.

**4 · Accessibility batch.** Small, individually cheap, collectively the
difference between shippable and not.

- **C3 (P0)**: gate the offline flicker animation on `noMotion`
- **C4**: bottom safe-area inset on every list
- `selected` semantics on nav items (active state is glow-only today)
- Semantic label + value on the seek slider
- A real label on the search field
- Text-scaling pass: `PageHeader` truncates to "Quick p…" at large Dynamic Type

---

### Tier 2 — High impact, real effort

**5 · Home / Quick picks.** The largest strategic gain in the audit. Today three
of five destinations render the same flat list, and the app's thesis — album art
— appears at its smallest size on the screen meant to sell it. Needs artwork-led
composition and more than one density.

**6 · List states.** Skeleton rows matching `SongTile`'s geometry instead of a
page-clearing spinner; a real **error state** distinct from empty (today a failed
request and an empty result are pixel-identical); crossfade instead of hard cut;
an action in every empty state.

**7 · `SongTile` refinement.** Tonal step between title and artist, a visible
press state, larger artwork, and the hero source for the player transition.

---

### Tier 3 — Medium

**8 · Search.** Debounce (stops the entire list re-staggering on every
keystroke — **C7**), a clear button where the decorative music note sits now, a
search icon that means search.

**9 · Artists.** One shape for one entity type (circles, not circles-then-
squares); a real grid instead of horizontally-scrolling rows with no affordance
(**C11**); an artist header using the bio and song count the API already
returns; an SVG divider instead of `album_line2.png`.

**10 · Background system.** Luminance clamp on `vibrantColor`; dark fallback
instead of `Colors.white` for missing swatches; hold luminance across the tween
so the screen stops changing hue behind the text; cache the palette by cover URL.

**11 · Glass + elevation ladder.** Three levels with a consistent recipe; a 1px
edge highlight so glass reads as a pane rather than fog; `RepaintBoundary` around
the gradient and the blurred rail.

---

### Tier 4 — Polish

Part D of the audit, in one pass at the end: haptics on play/favourite/tab,
artwork fade-in, seek thumb scale + scrub bubble, buffered-progress track, `0:42`
instead of `00:42`, marquee on truncated titles, scroll-position memory,
pull-to-refresh, spinner minimum-display-time.

---

## Phase 3 protocol

One item at a time, in the order above. For each:

1. Build it against the tokens — never a new literal
2. `flutter analyze` clean on every file touched
3. Report what changed and what to test by hand
4. **Phase 4** — critique it as a second designer would, and fix what that finds
5. Update **Progress** — tick the row, move the "Next" line, strike the closed
   `C` defects, re-date the heading
6. Only then move to the next item

`design.md` gets updated at the end of each item, so the spec stops drifting
from the build (root cause **A5**).
