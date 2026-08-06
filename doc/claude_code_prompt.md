# Claude Code prompt — music_app feature work

---

## Progress

Owned by the **tracker** agent. It is rewritten after every task from what is
actually in the code, not from what an agent reported doing.

Status values: `not started` · `in progress` · `blocked` · `needs testing` · `done`

| Task | Scope | API side | UI side | Status |
|---|---|---|---|---|
| 1 | Wire the Artists screen | done | done | **done** — 2026-08-04 |
| 2 | Songs page should not open blank | done | done | **done** — tested on device 2026-08-06 |
| 3 | Player page features (10 items) | done | done | **done** — tested on device 2026-08-06, re-tested after the icon and sheet rework the same day |
| 4 | Build the Settings screen | done | done | **done** — tested on device 2026-08-06 |

### Task 2 — decision notes

**2026-08-06 — default list is "All songs", not "Recently added."**
`get_all_songs.php` runs `SELECT * FROM songs ORDER BY songid DESC`, and the
`songs` table (`../music_apis/schema.sql`) has no date column at all — no
`created_at`, no `updated_at`, nothing. `songid DESC` reads newest-first only
because of auto-increment order, which is not a recency field a UI should
claim as one. Confirmed both against the schema and by calling the live
endpoint (6 rows, same shape as `search_songs.php`). Per Task 2 item 1's own
instruction, the screen calls this "All songs" rather than inventing a
"Recently added" label the data can't back up.

**2026-08-06 — `AlwaysScrollableScrollPhysics` on the songs list, added after
both agents finished.** The `ListView.builder` in `songs.dart` needs
`physics: const AlwaysScrollableScrollPhysics()`. Without it, a list shorter
than the viewport never overscrolls, so the `RefreshIndicator` added for
pull-to-refresh (item 2) can never be pulled — and the library currently
holds 6 songs, well short of a screen. Do not remove this as apparently
redundant; it stops being a no-op the moment the library grows past a
screenful, and is load-bearing before that.

### Task 3 — decision notes

**2026-08-06 — Share (item 10) is cancelled, not pending.** `../music_apis/`
has 25 PHP files and none of them serves a song page — only JSON endpoints
(`get_*`, `search_*`, `add_*`, `check_*`) and raw files under `uploads/`.
There is no URL a listener could open to see "this song" the way a Spotify or
YouTube link works; the only public artifact is the raw `.mp3`, and sharing a
direct link to an audio file the user's phone will just try to download is
not what "Share" means in a music app. Item 10's own instruction was to tell
me and skip rather than invent a link format, so that's what happened —
confirmed by listing `../music_apis/*.php` directly rather than trusting the
report. `url_launcher` stays in `pubspec.yaml` unused (it was already there
before this task, per Hard rule 8) and no share icon exists anywhere in
`lib/`. This is closed, not a gap to come back to — it reopens only if a
backend song page gets built.

**2026-08-06 — `SongController.setQueue` copies the list; do not "simplify"
that back to an assignment.** `playSong()` in `player_page.dart` used to do
`controller.currentPlayingList = queue`, handing the controller the exact
`RxList` a screen already owned — `quickpicksController.quickpicks`,
`favouriteController.userFavoutitesList`, an artist's `controller.songs`, or
`SearchSongController.searchSongResult`. That was harmless while the queue
was read-only. Task 3 item 7 added drag-to-reorder and swipe-to-remove on
that same list, so the moment those shipped, reordering the up-next sheet
would have reordered Quick picks (or Favourites, or whichever screen the
queue came from) right along with it, and removing a track from the queue
would have deleted it from that screen too. `setQueue` now does
`currentPlayingList.value = List<MySongs>.from(songs)` — a real copy, not an
alias — before pointing `currentIndex` at it. Verified by reading
`playSong()`'s four call sites (`quick_picks.dart`, `songs.dart`,
`user_favourite_page.dart`, `artists_page.dart`) — all four go through the
shared `playSong()` function, none construct the queue by hand.

**2026-08-06 — landscape gets its own control row, not the portrait one
squeezed down.** `player_page.dart`'s `LayoutBuilder` checks
`box.maxWidth > box.maxHeight` and, when true, renders `_CompactControls`
instead of stacking `_Transport` above `_SecondaryControls`. A landscape
phone (or a split screen) is short on height and long on width — the
opposite of portrait — and two control rows below the glass card were
pushing it below what the card's own `LayoutBuilder` branch needs for the
track and seek bar. `_CompactControls` folds shuffle / skip-back / previous /
play / next / skip-forward / repeat into one `Row`, spending width instead of
height. Same icons, same `SongController` calls as the portrait row — this
is a layout branch, not a second set of controls to keep in sync.

**2026-08-06 — the new transport controls fail silently against a disposed
player; that's a known pre-existing bug they route around, not one they
fix.** `InternetController` calls `SongController.disposePlayer()` — which
calls `player.dispose()`, permanent — on every disconnect *and* on a merely
slow connection, and `player` is built once in `onInit` and never rebuilt.
After the first such blip, every later call into `player` throws for the
rest of the session. `_guardPlayerCall` wraps skip, speed, volume, seek, and
the sleep timer's pause so each fails quietly (a debug log, nothing thrown)
instead of crashing the page — but the underlying player is still dead until
the app restarts. This was already broken before Task 3; the new controls
were built not to make it worse.

**2026-08-06 — `text_scroll` is now load-bearing; `marquee` still is not.**
Item 9 needed one of the two scrolling-text packages already sitting unused
in `pubspec.yaml` (Hard rule 8 forbids adding a new one).
`global_widgets/scrolling_text.dart` wraps `text_scroll`'s `TextScroll`
widget and is used by `player_page.dart` for the title and artist lines,
with a plain ellipsised `Text` fallback under `noMotion(context)`. `marquee`
was not touched and has no importer anywhere in `lib/` — it stays on the
unused list in `progress.md`, `text_scroll` comes off it.

### Task 3 — item checklist

Ten separate features; tracked individually so a partial task is legible.
**Closed 2026-08-06.** The author ran all ten on a device and reported the
behaviour correct throughout, then reported two UI problems: the control row's
icons and active states, and an options sheet that covered the player with no
obvious way out. Both were fixed and re-tested on a device the same day. No
behaviour changed in either fix — both were visual or gestural.

| # | Item | Status |
|---|---|---|
| 1 | Shuffle toggle (non-destructive order) | **done** — icon and active state reworked, re-tested |
| 2 | Repeat modes (off → all → one) | **done** — icon and active state reworked, re-tested |
| 3 | Elapsed/remaining labels + skip | **done** — skip icon follows the interval setting, re-tested |
| 4 | Playback speed (`setSpeed`) | **done** — re-tested after the sheet rework |
| 5 | Volume slider (`setVolume`) | **done** — re-tested after the sheet rework |
| 6 | Sleep timer | **done** — re-tested after the sheet rework |
| 7 | Queue / up-next bottom sheet | **done** — re-tested after the sheet rework |
| 8 | Buffering state on play/pause | **done** — tested on device |
| 9 | Scrolling title (`text_scroll`, not `marquee`) | **done** — tested on device |
| 10 | Share via `url_launcher` | cancelled — no song URL exists |

**2026-08-06 — the `_on` icon variants are boxed glyphs, and were the wrong
tool for an active state.** `Icons.shuffle_on_rounded`,
`repeat_on_rounded` and `repeat_one_on_rounded` are not their base glyphs in a
different colour — Material draws each of them **inside a filled rounded
square**. Turning shuffle on therefore dropped a solid box into a row of thin
line icons, which breaks design.md §9's one-icon-family rule, and it spent the
app's loudest signal — a filled white surface — on a toggle, when that surface
is what marks `_PrimaryControl` as the screen's single primary action. Shuffle
and repeat now keep one glyph across states (`repeat_one_rounded` still carries
all-vs-one, since the "1" *is* the difference) and `_SmallControl` marks the
armed state with **colour, glow and a 4pt dot under the glyph** — three
signals, because design.md §13's rule is that state is never carried by colour
alone, and white-vs-72%-white is the first distinction a bright cover eats. The
dot is `Positioned`, not stacked in a `Column`, so the glyph stays centred in
its target whether it is showing or not; in a Column the icons rode 4pt high
when active, which is visible in the landscape row where these sit beside the
larger transport icons.

**2026-08-06 — the options sheet had no working way out, and the cause was one
line of layout.** Reported from a device: the "⋯" sheet covered nearly the whole
player and felt impossible to dismiss without tapping something inside it. Two
faults, one of them subtle.

The subtle one: `_DragHandle` was rendered **inside** the sheet's
`SingleChildScrollView`. Flutter wraps a modal sheet in a single
`VerticalDragGestureRecognizer` (`_BottomSheetGestureDetector`, plain
`RawGestureDetector`, no scroll coordination), a scroll view installs its own,
and for a touch landing on the scrollable the deeper recognizer wins the
gesture arena. So the one affordance in the sheet that *looks* draggable was
the single place where a downward drag could only ever scroll. It is now
`global_widgets/sheet_handle.dart`'s `SheetDragHandle`, a sibling **above** the
scroll view, where the drag belongs to the sheet again — and it takes a tap and
carries `Semantics(button, label: 'Close')`, neither of which the decorative bar
had. **Do not move it back inside the scrollable.** Material's own
`showDragHandle: true` was considered and cannot be used here: it renders into
the sheet's own `Material`, which this app leaves transparent so a `GlassPanel`
can supply the surface, so the handle would sit in a transparent 48dp strip
above the glass instead of on it.

The blunt one: `isScrollControlled: true` with no `constraints` let the sheet
grow to whatever four sections wanted — two of them wrap to two rows of pills —
which on a shorter phone left barely any scrim, and tapping the scrim is the
other standard way out. Both sheets now cap at `kSheetMaxHeightFraction`
(`tokens.dart`, 0.75), which is the figure the queue sheet was already using as
a literal.

The queue sheet's handle was already a sibling above its list, so dragging it
always worked; it shares `SheetDragHandle` now so both sheets close the same
way and neither carries its own copy.

**2026-08-06 — the skip buttons were lying about how far they skip.** They
were hardcoded to `Icons.replay_10_rounded` / `Icons.forward_10_rounded` and
"Back 10 seconds", written when the interval was a `static const`. Task 4 made
it a setting, so at 15 or 30 seconds the button showed a "10" while jumping a
different distance. `_SkipControl` reads `SongController.skipInterval` inside
its own `Obx` — which subscribes through the getter to
`SettingsController.skipIntervalSeconds` — so both the glyph and the tooltip
follow the setting live. Material ships numbered glyphs for **5, 10 and 30
only** and Settings offers 15, so an interval it cannot draw falls back to the
unnumbered `Icons.replay_rounded`, mirrored for the forward direction, which is
exactly how Material's own `forward_N` relates to its `replay_N`. Do not
"simplify" this back to a fixed pair of numbered icons — the number is only
correct by coincidence at one of the three settings.

### Task 4 — decision notes

**2026-08-06 — two items in the spec were cut, both because the app cannot
back them.** Theme mode: `design.md`'s first paragraph says "Target is mobile,
portrait, **dark only**. There is no light theme", and the whole colour system
is white-at-three-opacities over an album gradient — a light mode is a redesign,
not a toggle, so the item is out per its own "check design.md first"
instruction. Stream quality / wifi-only: `MySongs` carries one `songurl` so
there are no quality variants to switch between, and
`internet_connection_checker` reports connected / disconnected / slow but never
*which kind* of connection — telling wifi from cellular needs
`connectivity_plus`, which is not in `pubspec.yaml`. Both decisions were taken
by the controller pass and are recorded in `settings_controller.dart` beside
the code that would have held them.

**2026-08-06 — the version string is a hand-kept constant, not
`package_info_plus`.** `kAppVersion` in `settings_controller.dart` is `'1.0.0+1'`
and must be edited whenever `pubspec.yaml`'s `version:` line changes; nothing
checks that the two agree. The spec offered "`package_info_plus` if you add it,
or a generated constant" and the last line of Task 4 requires asking before
adding a dependency, so the constant is what shipped.

**2026-08-06 — three settings did nothing until the *screen* landed, and the
wiring is easy to undo by accident.** The controller was written first and was
complete, but three of its values had no reader:

- `veilOpacity` — `dashboard_page.dart` and `player_page.dart` both painted the
  veil at the `kVeilRest` **literal**. They now read
  `BackgroundController.restingVeilOpacity`, from inside the `Obx` they already
  had, which is what makes the intensity slider repaint the background live.
  Putting the literal back silently disconnects the slider.
- `reducedMotion` — `global_widgets/motion.dart`'s `noMotion()` read only
  `MediaQuery.disableAnimations`. It now ORs the setting in. OR, not override:
  a phone-wide "reduce motion" is an accessibility need and an in-app toggle
  has no business turning it back off.
- The screen itself, which is every other setting's only reader.

**2026-08-06 — `_Pill` moved out of the player's options sheet to
`global_widgets/select_pill.dart` as `SelectPill`.** Settings' default-speed and
skip-interval pickers are the same "pick one of these" control the sheet's speed
row and sleep timer already were, and a second copy would have drifted from the
first. Same widget, same semantics; only the name and the file changed.

**2026-08-06 — small calls made rather than asked, per Hard rule 9.** The
"gradient intensity" slider is displayed **inverted** against the stored value:
`veilOpacity` going up means a dimmer cover, and a control labelled *intensity*
has to move the other way. The inversion is in the widget, so
`BackgroundController` keeps reading one number that means what it says. Section
labels use `AppText.bodyLarge` merged in by hand because the theme spends its
`bodyLarge` slot on `AppText.body` — left at the slot value, a group heading
would be pixel-identical to the row titles under it. The reset-identity dialog's
actions are bare `TextButton`s, so they render in Pacifico like the sleep
timer's existing Cancel; that is the shipped precedent rather than a new
override. `app_theme.dart` gained a `switchTheme` — M3 derives an unselected
switch track from `surfaceContainerHighest`, and this scheme's surface is
`0xFF07070A`, so every "off" toggle would have been a near-black shape on a
translucent white card.

### Out-of-band fixes

Real work that did not come from the task list above. Recorded here so the task
table stays an honest picture of the whole app.

| Date | What | Status |
|---|---|---|
| 2026-08-05 | Rapid song-switching races — `PlayerInterruptedException` spam, a load that showed its duration then sat silent at 0:00, and stacked `PlayerPage` routes tripping the navigator's `_userGesturesInProgress` assertion | **done** |
| 2026-08-06 | Favourites broken end to end — `user_fav.user_id` is `INT UNSIGNED` but the app sends a uuid, so MySQL coerced every write into a garbage bucket while the API answered `success: true` | **needs deploy** — code done; `migration_user_fav_uuid.sql` and 5 PHP files must go up |

### Agents

| Agent | Owns | Must not touch |
|---|---|---|
| **api** | `apis/all_urls.dart`, models, repos, the network half of controllers, and verifying endpoints against the live host | widgets, screens, anything under `global_widgets/` |
| **ui** | screens, widgets, and rewiring them onto whatever the api agent exposed | endpoint contracts, model field names |
| **tracker** | this section and `doc/progress.md`; verifies each claim against the code before recording it | source files — it reports, it does not implement |

They run in that order per task, not in parallel: the ui agent needs the
controller surface the api agent settled on, and both otherwise fight over the
same controller file.

---

You are working in the Flutter listener app `music_app`. Before writing any code, read
`doc/progress.md` (implementation status, endpoint list, architecture notes) and
`doc/design.md` (the visual language). Also open the files you are about to change and the
shared widgets in `global_widgets/` so new UI is assembled from existing pieces
(`SongTile`, `RemoteImage`, `EmptyState`, `PageHeader`, `motion.dart`).

## Hard rules

1. State management stays **GetX**. Do not introduce BLoC, Riverpod, or Provider. New
   controllers go in `core/bindings.dart` the same way the existing ones do.
2. Do not invent backend endpoints. Only these exist and are verified live:
   `get_quick_picks.php`, `search_songs.php`, `get_all_songs.php`,
   `search_from_all_songs.php`, `get_user_favourites.php`, `add_to_fav.php`,
   `remove_from_fav.php`, `check_if_favourite.php`, `get_all_artists.php`,
   `get_artist_details.php`. Everything else in `../music_apis/` is admin-only and this app
   must never call it.
3. The favourite endpoints accept **POST with a JSON body only** — the host returns 403 for a
   GET carrying a body. Do not convert them.
4. All new URLs go in `apis/all_urls.dart`. Relative image paths from the API need the
   `baseUrl` prefix, like every other image in the app.
5. Follow `design.md` for colours, spacing, motion, and typography. Keep 48dp touch targets,
   `SafeArea`, reduced-motion support, empty states, and semantic labels.
6. `flutter analyze` must be clean on every file you touch.
7. Work task by task in the order below. After each task, stop, summarise what changed, and
   let me test before you start the next one. One commit per task.
8. Do not delete dead code, unused assets, or unused dependencies in this pass — some of them
   (`marquee`, `text_scroll`, `url_launcher`) become useful again in the tasks below. Cleanup
   is a separate job.
9. If a design decision is genuinely ambiguous, ask me rather than guessing. If it is a small
   detail, pick the option most consistent with the existing screens and tell me what you
   picked.

---

## Task 1 — Wire the Artists screen

The UI in `main_nav_pages/artists/artists_page.dart` is finished and renders nothing because
`services/services.dart` is a leftover Firebase shell whose `getArtists()` and
`getSongsUnderArtists()` bodies are commented out.

Endpoints:

```
GET get_all_artists.php
-> {success, message, data: [{artist_id, name, bio, imageurl, created_at, total_songs}]}

GET get_artist_details.php?artist_id=<int>    (also accepts ?name=<string>)
-> {success, message, artist: {...}, songs: [ ...full song rows... ]}
```

What to do:

1. Add both URLs to `apis/all_urls.dart`.
2. Fix `model/artist_model.dart`. The API returns `artist_id` as an **int** and `imageurl`
   lowercase; the model currently expects `id` as a String and `imageUrl`. Add `bio`,
   `created_at`, and `total_songs`. Prefix `imageurl` with `baseUrl`.
3. Create a proper `ArtistRepo` (Dio) instead of extending the dead `FireStoreServices`
   shell. Leave the shell in place for now but stop depending on it.
4. Note that `get_artist_details.php` returns `artist` and `songs` at the **top level**, not
   wrapped in `data`, unlike every other endpoint. Parse it accordingly.
5. Song rows from `get_artist_details.php` are full `songs` rows, so `MySongs.fromJson`
   parses them as-is. Tapping a song must set that artist's song list as
   `currentPlayingList` so next/previous walks the artist's songs.
6. Rework `ArtistController` (currently holds only `selectedArtistIndex`) into a real
   controller: artists list, selected artist, that artist's songs, `isLoading`, and an error
   flag. Show the existing loading and empty states while it works.

## Task 2 — Songs page should not open blank

`main_nav_pages/search_songs/songs.dart` currently shows nothing until the user types.

1. On first open, load a default list so the screen is never empty. Use `get_all_songs.php`.
   If the response includes a date field such as `created_at`, sort descending and present it
   as "Recently added"; if it does not, present it as "All songs" and tell me — do not fake a
   recency ordering.
2. Cache the default list in `SearchSongController` so returning to the tab does not refetch
   every time. Support pull-to-refresh.
3. When the search field is cleared or the query is empty, fall back to the default list
   rather than an empty screen.
4. Add debouncing to the search — it currently fires on every keystroke. Use roughly 350ms,
   and cancel the in-flight request when a newer query arrives so stale results cannot
   overwrite fresh ones.
5. Add a clear ("x") button in the search field, and keep the keyboard behaviour sane on
   submit.
6. Distinguish the three states properly: loading, "no results for <query>", and "the request
   failed" with a retry button. Right now a failed fetch looks identical to an empty result.
7. If the list is long, use a lazy-building list so scrolling stays smooth.

## Task 3 — Player page features

`player_page/player_page.dart` currently has artwork, title, seek bar, transport, and the
favourite toggle. Add the standard set that other music apps have. Playback state belongs in
`SongController`; the page stays a view.

Build these:

1. **Shuffle toggle.** Shuffle the play order of `currentPlayingList` without destroying the
   original order — keep the original list and a separate shuffled index order, so toggling
   shuffle off returns to the original sequence with the current song still playing.
2. **Repeat modes**, cycling off -> repeat all -> repeat one. Repeat one replays the current
   track on completion; repeat all wraps the queue (wrap-around already exists — make it
   respect the mode instead of always wrapping).
3. **Elapsed and remaining time labels** on either side of the seek bar, and 10-second
   skip-back and skip-forward buttons.
4. **Playback speed** control (0.5x, 0.75x, 1x, 1.25x, 1.5x, 2x) using `just_audio`'s
   `setSpeed`. Show the active speed on the button.
5. **Volume slider** using `setVolume`.
6. **Sleep timer.** Options: 15, 30, 45, 60 minutes and "end of current track". Show a
   countdown somewhere unobtrusive while it is armed, allow cancelling, and pause playback
   when it fires. Make sure the timer is cancelled on dispose so it cannot fire after the
   player is gone.
7. **Queue / up next bottom sheet.** Lists `currentPlayingList` with the current track
   highlighted, tap to jump to a track, drag to reorder, swipe to remove. Reordering must
   keep the currently playing track playing.
8. **Buffering state.** The play/pause button should show a loading indicator while
   `just_audio` reports buffering, instead of looking frozen.
9. **Scrolling title** for long song and artist names. `marquee` and `text_scroll` are
   already in `pubspec.yaml` — use one of them rather than adding a dependency. Respect the
   reduced-motion setting.
10. **Share** the current song using `url_launcher`, which is already a dependency. If a
    shareable public URL for a song does not exist, tell me and skip this item rather than
    inventing a link format.

Also keep behaviour correct at the edges: track changes must still run the favourite check,
the palette/background recolour must still fire, and everything must survive the connection
dropping (`InternetController` disposes the player).

## Task 4 — Build the Settings screen

`main_nav_pages/settings/settings.dart` is a placeholder `EmptyState`. Build it for real.

Create a `SettingsController` registered in `core/bindings.dart`, persisting every value to
`shared_preferences` and exposing them as observables so the rest of the app reacts through
`Obx`. Every setting must actually take effect somewhere — do not add a toggle that changes
nothing. Group the screen into sections with `PageHeader`-consistent styling:

1. **Appearance**
   - Album-art gradient on/off. When off, fall back to a fixed accent from `design.md`
     instead of `PaletteGenerator` output.
   - Gradient intensity slider, wired to the veil opacity in `BackgroundController`.
   - Reduced motion toggle, honoured by `motion.dart` and the animated widgets (heart
     animation, scrolling title, transitions).
   - Theme mode, only if the app's design supports it. Check `design.md` first — if the app
     is dark-only by design, leave this out and tell me instead of half-building it.
2. **Playback**
   - Default playback speed, applied on player start.
   - Skip interval (10 / 15 / 30 seconds), used by the skip buttons from Task 3.
   - Autoplay next track on completion, on/off.
   - Remember and restore the last playback position when reopening a song, on/off.
3. **Data and storage**
   - Show the current image cache size and a "clear cache" action.
   - Stream quality or wifi-only streaming only if the API and `internet_connection_checker`
     actually support it. If they do not, leave it out and say so.
4. **Identity** — this matters because there is no login. Show the anonymous `user_id` from
   `UseridController`, let the user copy it, and offer a "reset identity" action behind a
   confirmation dialog that clearly warns that all favourites become unreachable.
5. **About** — app name, version, and a licences page via `showLicensePage`. Use
   `package_info_plus` for the version if you add it, or read it from a generated constant;
   tell me which you chose.

Ask me before adding any dependency that is not already in `pubspec.yaml`.

---

## When you finish each task

Report: files added, files changed, any dependency added, anything you could not do and why,
and what I should test by hand. Then stop and wait.
