# Implementation status — Nyro (listener app)

> Named **Nyro** as of 2026-08-06. The Dart package is still `music_app` and
> always will be — it is the import prefix on every file in `lib/`. See
> `release.md` for every surface the name actually appears on, and for the two
> things still blocking the first upload.

What exists, what works, and what is left. Checked against the running code on
2026-08-06; the **live API** was last verified live on 2026-08-04 (see
"Endpoint coverage" — `get_all_songs.php` was re-verified live on 2026-08-06).

Companion docs: `design.md` (the visual language), **`mvp_push.md` (the background
playback / notification work, in flight as of 2026-08-06 — code complete, not yet
device-tested)**, `../../music_app_admin/doc/` (the admin side).

> Several entries below were written before `mvp_push.md` landed and are marked
> where they have been overtaken. Nothing in that push has run on a device yet, so
> this file still describes the last state that was actually verified.

---

## The short version

Five nav destinations plus a full-screen player. **All six screens are built.**

```
Quick picks   ████████████████████  done
Songs         ████████████████████  done — default list added 2026-08-06
Favourites    ████████████████████  done
Player        ████████████████████  done — full control set added 2026-08-06
Artists       ████████████████████  done — wired 2026-08-04
Settings      ████████████████████  done — built 2026-08-06
```

Nothing in the nav is a placeholder any more, and as of 2026-08-06 **every one
of them has been run on a device and confirmed working** — there is no
code in this app whose only evidence is `flutter analyze`. What is left is not
a screen: it is dead code, an undeployed backend fix, and two features that
start on the server (playlists, accounts).

---

## Screens

### Live — in the nav rail

| # | Screen | File | State | Backend |
|---|---|---|---|---|
| 0 | Quick picks | `main_nav_pages/quick_picks/quick_picks.dart` | **Done** | `get_quick_picks.php` ✓ |
| 1 | Songs (search) | `main_nav_pages/search_songs/songs.dart` | **Done** | `search_songs.php` ✓ `get_all_songs.php` ✓ |
| 2 | Favourites | `main_nav_pages/user_favourite_songs/user_favourite_page.dart` | **Done** | `get_user_favourites.php` ✓ |
| 3 | Artists | `main_nav_pages/artists/artists_page.dart` | **Done** | `get_all_artists.php` ✓ `get_artist_details.php` ✓ |
| 4 | Settings | `main_nav_pages/settings/settings.dart` | **Done** — appearance, playback, storage, identity, about. Added and tested on a device 2026-08-06 — see Task 4 in `claude_code_prompt.md` | none — every value is local, in `shared_preferences` |

### Live — full screen

| Screen | File | State |
|---|---|---|
| Player | `player_page/player_page.dart` | **Done** — art, title, seek, transport, favourite toggle, shuffle, repeat (off/all/one), settings-driven skip, playback speed, volume, sleep timer, queue sheet, buffering indicator, scrolling title. Tested on a device 2026-08-06 and re-tested the same day after the icon and sheet rework — see Task 3 in `claude_code_prompt.md` |
| Offline | `global_widgets/nointernet_page.dart` | **Done** — replaces the page body when `InternetController` reports no connection |

### Built but not in the nav

| Screen | File | Lines | Why it's out |
|---|---|---|---|
| Playlists | `main_nav_pages/playlists/playlists.dart` + `playlist_page_function.dart` | 432 | Commented out of `dashboard_page.dart`. **No backend exists** — there is no playlist table or endpoint of any kind. |
| Albums | `main_nav_pages/albums/Albums.dart` | 33 | Commented out. Stub only. |
| — | `lib/test.dart` | 235 | Scratch file, not reachable from `main.dart`. |

---

## What actually works today

- **Playback** — `just_audio`, streaming from the API. Play, pause, seek,
  next/previous, auto-advance on completion. Wrap-around at the end of the
  queue now follows repeat mode instead of being unconditional: off stops
  the queue, all wraps, one replays the track that just finished. Shuffle
  keeps `currentPlayingList` in its original order and walks a separate
  index permutation instead, so turning shuffle off hands next/previous
  straight back to the original sequence with whatever's playing untouched.
  Skip back/forward at the interval Settings is set to — 10, 15 or 30
  seconds, with the button's own glyph and tooltip following it rather than
  claiming a fixed 10 — six-step playback speed (0.5x–2x via
  `setSpeed`), a volume slider (`setVolume`), and a sleep timer (15/30/45/60
  minutes or "end of current track", cancellable, cancelled again on
  controller disposal so it can't fire into a dead player) live behind the
  player's "⋯" action. A queue / up-next bottom sheet lists
  `currentPlayingList` with the current track marked, tap to jump, drag to
  reorder, swipe to remove — reordering keeps the playing track playing. The
  play/pause button shows a spinner while `just_audio` reports buffering
  instead of sitting frozen. All of this landed 2026-08-06 and has not run on
  a device yet — see Task 3 in `claude_code_prompt.md`.
- **Now-playing context** — whichever list you tap from becomes the queue
  (`currentPlayingList`), so next/previous walks that list.
- **Favourites** — add, remove, and a per-song check on every track change, so
  the heart is always in sync. The heart animation fires only after the server
  confirms.
- **Album-art background** — `PaletteGenerator` recolours the whole app from the
  current cover; see `design.md` §1.
- **Songs screen never opens blank** — `main_nav_pages/search_songs/songs.dart`
  loads `get_all_songs.php` on first open and `SearchSongController` caches
  the result, so returning to the tab doesn't refetch. Clearing the search
  field, an empty submit, or a failed search all fall back to that cached
  list instead of an empty screen; pull-to-refresh bypasses the cache for a
  real refetch. Landed 2026-08-06 and **tested on a device the same day** —
  the author confirmed the whole screen, cache and fallbacks included.
- **Anonymous identity** — a UUID minted on first launch and kept in
  `shared_preferences` under `user_id`. Favourites hang off it. **There is no
  login, signup or account recovery** — clear the app data and the favourites
  are unreachable. Settings now surfaces this rather than leaving it invisible:
  the id is shown, copyable, and resettable behind a dialog that says plainly
  what a reset costs.
- **Settings** — nine controls across five sections, all of them local, all of
  them persisted to `shared_preferences` and read by something. Appearance:
  album-art gradient on/off (`BackgroundController` falls back to its idle
  black pair rather than running `PaletteGenerator`), gradient intensity
  (the veil's resting opacity, floored at `kVeilRest` so the contrast floor
  survives the slider, and shown inverted so "more" means a brighter cover),
  reduce motion (OR'd into `noMotion()` alongside the platform setting).
  Playback: default speed, skip interval, autoplay, remember-position — the
  first two feed `SongController` directly, the last two gate branches inside
  it. Storage: image-cache size and a clear action, through
  `DefaultCacheManager`. Identity and About as above, with licences via
  `showLicensePage`. Theme mode and stream quality were cut for cause — see
  Task 4's notes in `claude_code_prompt.md`. Landed and tested on a device
  2026-08-06.
- **Connectivity** — `internet_connection_checker` swaps in the offline page when the
  connection drops or goes slow. It used to *dispose the player* in both cases, which
  killed playback permanently for the rest of the session; `mvp_push.md` Phase 2
  removed that.
- **Accessibility / polish pass** — 48dp touch targets, `SafeArea`, reduced
  motion, empty states, image placeholders and error widgets, semantic labels.
  `flutter analyze` is clean on every live file.

---

## What is left

### 1. Playlists — needs a backend first

432 lines of UI exist behind a commented-out nav entry. There is **no server
side at all**: no table, no endpoint. Finishing this is a backend project
(create/rename/delete a playlist, add/remove songs, list a user's playlists)
before it is a Flutter one. The UI as written also predates the current design
language and would need a pass against `design.md`.

### 2. Albums — decide whether it exists

A 33-line stub. Songs have no album column in the schema, so "albums" is not a
concept the data currently supports. Either add it to the schema or delete the
file.

---

## Endpoint coverage

The app calls **9** endpoints. All verified returning `success: true` on
2026-08-04; `get_all_songs.php` re-verified live on 2026-08-06 (6 rows, same
row shape as `search_songs.php`).

| Endpoint | Method | Used by |
|---|---|---|
| `get_quick_picks.php` | GET | Quick picks |
| `search_songs.php` | GET `?query=` | Songs |
| `get_all_songs.php` | GET | Songs — default list, cached in `SearchSongController` |
| `get_user_favourites.php` | POST | Favourites |
| `add_to_fav.php` | POST | Player heart |
| `remove_from_fav.php` | POST | Player heart |
| `check_if_favourite.php` | POST | Every track change |
| `get_all_artists.php` | GET | Artists |
| `get_artist_details.php` | GET `?artist_id=` | Artist detail |

**Available but unused:**

| Endpoint | Note |
|---|---|
| `search_from_all_songs.php` | a second search endpoint; the app uses `search_songs.php` |

The remaining endpoints in `../music_apis/` are admin-only (`admin_*`,
`create_artist`, `update_artist`, `delete_artist`, `add_song_to_artist`,
`add_to_quick_picks`, `remove_from_quick_picks`, `create_new_admin`) and this
app should never call them.

The favourite endpoints only accept **POST with a JSON body** — the host answers
403 to a GET carrying a body. Do not "tidy" them into GETs.

---

## Architecture notes

**State management is GetX throughout** — `Get.find` / `Obx`, with every
controller registered in `core/bindings.dart`. This is worth flagging because
the **admin panel is mid-migration to BLoC**. The two apps have diverged; if the
listener app should follow, that is a decision to make deliberately rather than
drift into.

**Never `Get.put` in a widget.** `Get.put(SongController())` on the Search page
constructed a controller — and so an `AudioPlayer` — on every mount, only for
GetX to keep the registered instance and drop the new one. See `design.md` §8.

Controllers, and what each owns:

| Controller | Owns |
|---|---|
| `SongController` | the player, the queue (now a copy the up-next sheet can reorder/remove from without mutating whichever screen it came from), favourite state, shuffle order, repeat mode, playback speed, volume, sleep timer — the biggest one |
| `BackgroundController` | palette extraction and the veil |
| `InternetController` | connectivity, disposes the player when offline |
| `UseridController` | the anonymous UUID |
| `NavController` | the rail index and the page-transition direction |
| `QuickPicksController` | quick-picks list, `isLoading`, `hasError` |
| `UserFavouriteController` | favourites list, `isLoading`, `hasError` |
| `SearchSongController` | search results, the default list and its cache, `isLoading`, `hasError`, the debounce |
| `ArtistController` | artists, the selected artist and their songs, both load states |
| `SettingsController` | every user-facing setting, its `shared_preferences` mirror, the per-song remembered positions (capped at 50, evicted oldest-first), the image-cache measurement, and the identity reset. Other controllers call *into* it rather than the other way round, so none of them need it to exist at construction time |
| `PageControllerNavPages` | `goInsidePlayList` only — belongs to the dead Playlists screen |
| `FireStoreServices` | **dead Firebase shell** — nothing reads from it any more |

Shared widgets live in `global_widgets/` — `SongTile`, `RemoteImage`,
`EmptyState`, `ErrorState`, `Skeleton`, `PageHeader`, `GlassPanel`,
`SelectPill`, `SheetDragHandle`, `motion.dart`. New screens should be assembled
from these; see `design.md` §11.

**A bottom sheet needs `SheetDragHandle` above its scrollable, and a
`kSheetMaxHeightFraction` cap.** Both sheets in the player learned this the
hard way — read that widget's doc before building a third one.

---

## Known weak points

Not blockers, but they will bite eventually.

| Area | Issue |
|---|---|
| ~~`MySongs.fromJson`~~ | **Fixed** in `mvp_push.md` Phase 3 — tolerant now, same shape as `Artist.fromJson` |
| ~~Dio~~ | **Fixed** in `mvp_push.md` Phase 3 — one shared instance in `apis/all_urls.dart` with connect/receive/send timeouts |
| Identity | no account, no sync, no recovery — favourites die with the app data |
| `services.dart` | ~200 lines of commented-out Firebase, four unused `deviceId` locals, prints throughout. **Nothing in `lib/` references it** — the only trace is a commented-out `Get.find<FireStoreServices>()` in `song_controller.dart`. Deleting the file is a one-line follow-up, held back only by Hard rule 8's "no cleanup in this pass" |
| Dead code | `playlists/`, `albums/`, `test.dart`, `player_page_function.dart`, `services.dart`, `PageControllerNavPages` |
| `pubspec.yaml` | 6 dependencies no longer reachable from a live screen — `marquee`, `flutter_image_stack`, `url_launcher`, `device_info_plus` are imported nowhere at all; `flutter_vector_icons` and `font_awesome_flutter` only by the dead `player_page_function.dart`. Two came off this list 2026-08-06: `text_scroll` (`global_widgets/scrolling_text.dart` wraps it for the player's title/artist lines) and `path_provider` (`SettingsController` uses `getTemporaryDirectory()` to size the image cache) |
| ~~`flutter_cache_manager`~~ | **Fixed** in `mvp_push.md` Phase 1 — declared in `pubspec.yaml`. The original note follows. `settings_controller.dart` imports it to empty the image cache, but it was a **transitive** dependency via `cached_network_image`, not a declared one — `flutter analyze` says so (`depend_on_referenced_packages`, the one info-level lint on a live file). It works, and it kept a dependency off `pubspec.yaml`, but a future `cached_network_image` that drops or renames it breaks the build with no warning. Declaring it is a one-line fix whenever adding a dependency is on the table |
| `kAppVersion` | hand-kept in `settings_controller.dart` and shown in Settings' About section. Nothing checks it against `pubspec.yaml`'s `version:` line — edit both together |
| Assets | six unused mock covers (~560 KB) still ship, since `pubspec.yaml` globs all of `assets/` |

---

## Suggested order

Tasks 1–4 are all closed and device-tested as of 2026-08-06, so this list is
now the whole backlog rather than a queue behind a testing pass.

**Shipping today? `release.md` is the list that matters** — two things block
the first upload, and items 1 and 2 below are both of them.

1. **Create the release keystore.** Release builds were signed with the debug
   key, which the Play Console rejects. `build.gradle` now reads
   `android/key.properties` and fails loudly without it. Only you can run
   `keytool` — the password has to be yours. See `release.md`.
2. **Deploy the favourites fix.** `migration_user_fav_uuid.sql` and 5 PHP files
   are still sitting undeployed — see "Out-of-band fixes" in
   `claude_code_prompt.md`. This is the only thing on the list where the code
   is finished and the app is still wrong in production. Shipping without it
   means every user's favourites appear to save and come back empty.
3. **Clean out the dead code and unused dependencies.** Cheap, and it shrinks
   the bundle. `services.dart` can go now that Artists no longer needs it, and
   Hard rule 8's "no cleanup in this pass" has nothing left to protect — the
   packages it was holding back for (`text_scroll`, `path_provider`) both found
   a live caller.
4. **Dio timeouts.** The error states exist; nothing bounds how long a request
   hangs before one of them shows.
5. **Crash reporting.** Nothing is watching. Once the app is in real hands, a
   release-only failure is invisible without it.
6. **Playlists or accounts** — both are real projects that start on the backend.
   Pick one deliberately.

`design_plan.md` tracks the design work separately; items 10–12 are still open
there.
