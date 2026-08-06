# MVP push — background playback and the last gaps

Started 2026-08-06. The work that stands between Nyro-as-it-is and Nyro-as-a-music-app.

Companion docs: `progress.md` (what exists), `release.md` (what blocks an upload),
`design.md` (the visual language).

---

## Why this exists

Every screen in the app is done and device-tested. What is missing is not a screen —
it is everything that happens **outside the app window**, plus two landmines that
have been sitting in live code.

1. **Audio dies when the screen locks.** No `audio_service`, no
   `just_audio_background`, no `FOREGROUND_SERVICE` in the manifest, no
   `UIBackgroundModes` in `Info.plist`. No media notification, no lock-screen
   control, no bluetooth or headset buttons. For a music app this is the one hard
   blocker.
2. **The player dies permanently on a network blip.** `internet_controller.dart`
   called `disposePlayer()` — and so `player.dispose()`, which is irreversible — on
   both `disconnected` **and** merely `slow`. `player` was built once and never
   rebuilt. One slow reading and every later call threw for the rest of the session.
   The bug was documented in-code at `song_controller.dart` and never fixed.
3. **Nothing bounded a hung request.** No Dio timeouts, and `MySongs.fromJson` threw
   on any missing key.

Plus two things every music app has and Nyro did not: **recently played**, and any
way to **add** a song to the queue rather than replacing it.

**Out of scope, deliberately** — playlists, downloads/offline, accounts, albums,
genres, lyrics, crash reporting. All are v1.1. The keystore, the privacy-policy URL,
the Data-safety form and deploying `migration_user_fav_uuid.sql` are the author's
own tasks; see `release.md`.

---

## Progress

| Phase | What | State |
|---|---|---|
| 1 | Background playback + full media notification | **Done — device-tested 2026-08-06** |
| 2 | Stop the network from killing the player | **Done — device-tested 2026-08-06** |
| 3 | Dio timeouts + tolerant `MySongs.fromJson` | **Done — device-tested 2026-08-06** |
| 4 | Recently played | **Done — device-tested 2026-08-06** |
| 5 | Play next / Add to queue | **Done — device-tested 2026-08-06** |

All five phases confirmed working on a device by the author on 2026-08-06, including
the regression sweep over the rewritten controller.

### Log

- **2026-08-06** — Plan approved. `flutter pub add just_audio_background
  flutter_cache_manager`. Resolved: `just_audio 0.10.5`,
  `just_audio_background 0.0.1-beta.17`, pulling in `audio_service 0.18.19` and
  `audio_session 0.2.3` transitively. `flutter_cache_manager 3.4.2` promoted from
  transitive to declared — `settings_controller.dart` had been importing it without
  declaring it (`progress.md`, "Known weak points").
- **2026-08-06** — Phases 1 and 2 written. They landed together because Phase 2's
  fix is the deletion of a method in the file Phase 1 rewrote. `flutter analyze`
  clean on every live file — the 8 remaining infos are all pre-existing and all in
  dead code (`test.dart`, `Albums.dart`, `player_page_function.dart`). The
  `depend_on_referenced_packages` info `progress.md` recorded is gone, since
  `flutter_cache_manager` is declared now.
- **2026-08-06** — `flutter build apk --debug` succeeds. The merged manifest was
  checked rather than assumed: it carries `WAKE_LOCK`, `FOREGROUND_SERVICE`,
  `FOREGROUND_SERVICE_MEDIA_PLAYBACK` and `POST_NOTIFICATIONS`, plus
  `com.ryanheise.audioservice.AudioService` with
  `foregroundServiceType="mediaPlayback"` and `MediaButtonReceiver`. No
  manifest-merger conflict, so the explicit declarations in the app manifest stay.
- **2026-08-06** — Phases 3, 4 and 5 written. `flutter analyze` still clean (same 8
  pre-existing infos in dead code), `flutter build apk --debug` still succeeds.
  Phase 4 and 5's UI was written against `const/theme/tokens.dart` and the existing
  `GlassPanel` / `SheetDragHandle` / `RemoteImage` / `NowPlayingMarker` widgets — no
  new colour, radius, spacing or duration was introduced.

- **2026-08-06** — **Device pass run by the author: everything works.** Background
  playback, the notification card with working skip buttons, the lock screen, the
  recent strip and the queue actions all confirmed on a real device, along with the
  regression sweep over the rewritten transport. This push is closed.

---

## The decisive constraint

`just_audio_background` builds the notification **from just_audio's own state**. It
does not accept a queue of its own. The skip buttons render only when
`player.hasNext` / `player.hasPrevious` are true, and those are derived from the
player's playlist.

`SongController` loaded **one track at a time** (`player.setUrl`) and did
next/prev/shuffle/repeat itself in Dart. With a single audio source `hasNext` is
always false, so the shortest possible integration would have produced a
notification with play/pause and a seek bar and **no skip buttons** — half a feature.

So the queue moves into just_audio. This is a rewrite of the transport half of
`SongController` that deletes more than it adds, and it makes gapless playback fall
out for free.

### Verified against the installed package, not the docs

Before writing any of it, every method below was checked against
`just_audio-0.10.5/lib/just_audio.dart` in the pub cache:

| Used | Line | Note |
|---|---|---|
| `setAudioSources(List, {initialIndex, initialPosition})` | 877 | replaces `ConcatenatingAudioSource`, removed in 0.10 |
| `addAudioSource` / `insertAudioSource` | 931 / 935 | Phase 5 |
| `removeAudioSourceAt` / `moveAudioSource` | 947 / 954 | queue sheet |
| `setLoopMode` / `setShuffleModeEnabled` / `shuffle` | 1231 / 1239 / 1251 | |
| `seek(position, {index})` | 1308 | queue-sheet jump |
| `currentIndex` / `currentIndexStream` | 560 / 563 | |
| `effectiveIndices` | 578 | shuffle-aware play order |

Two behaviours of just_audio that the plan had to bend around, both found by reading
`_getRelativeIndex` (line 599):

- **`currentIndex` is an index into the original sequence, not the shuffled one.**
  Shuffle is expressed through `effectiveIndices`. So `currentPlayingList[i]` stays
  correct while shuffled, and the queue sheet keeps showing the real order — which
  is exactly the invariant the old hand-rolled `_shuffleOrder` existed to protect.
- **`seekToNext()` / `seekToPrevious()` obey `loopMode`.** Under `LoopMode.one`,
  `nextIndex == currentIndex`, so a *tap* on Next would replay the track instead of
  moving on. Under `LoopMode.off` at index 0, `previousIndex` is null and Previous
  would do nothing. Both contradict this app's documented behaviour: repeat governs
  what happens when a track ends **on its own**, not what a button means. So manual
  next/previous do not use those helpers — see `_manualIndex` in
  `song_controller.dart`.

---

## Phase 1 — Background playback + media notification

| File | Change |
|---|---|
| `pubspec.yaml` | `just_audio_background`, and `flutter_cache_manager` promoted to a declared dependency |
| `lib/main.dart` | `JustAudioBackground.init(...)` before `runApp`, before any `AudioPlayer` exists |
| `lib/controller/song_controller.dart` | the transport half rewritten around the player's own playlist |
| `lib/player_page/player_page.dart` | `playSong()` makes one call, not two |
| `android/.../AndroidManifest.xml` | four permissions, `AudioService`, `MediaButtonReceiver` |
| `android/.../MainActivity.kt` | extends `AudioServiceActivity` |
| `android/.../res/drawable/ic_stat_nyro.xml` | new — the status-bar icon |
| `ios/Runner/Info.plist` | `UIBackgroundModes: audio` |

### `setQueue` + `startPlaying` became `playQueue`

Loading the queue into the player **is** starting playback now, so the two-call
sequence every screen went through collapses into one. `startPlaying` is gone; so is
its `_request` race counter, which existed because two quick taps could each be
mid-`setUrl` at once. `setAudioSources` serialises that itself and raises
`PlayerInterruptedException` for the loser, which is caught and ignored.

### The status-bar icon is not the launcher icon

`JustAudioBackground.init` defaults `androidNotificationIcon` to
`mipmap/ic_launcher`. Android treats a notification's small icon as an **alpha
mask** — it discards colour and keeps transparency — so an opaque launcher icon
renders as a solid grey square. `ic_stat_nyro.xml` is the N-note mark as a white
silhouette, with the stem flag dropped: at the ~18dp a status bar renders it at, the
flag is noise rather than a detail.

### Behaviour that changed, deliberately

Four things used to hang off `ProcessingState.completed`, which with a playlist now
fires once at the end of the whole sequence rather than between tracks. All four
moved to the track-change listener, and two of them are not quite what they were:

- **Sleep timer "end of current track"** and **autoplay off** now stop playback at
  the *head of the next track* rather than the foot of the one that ended — the
  player has already moved on by the time it says so. A fraction of a second of the
  next track is audible. The alternative is polling position against duration to
  predict the end of every track, which is a lot of machinery to save 200ms.
- **Sleep timer "end of current track" cannot fire while repeat-one is armed.** The
  player loops the same track without changing index, so there is no boundary to
  catch. The two settings contradict each other; reconciling them would be building
  for a combination nobody means to set.

### The track-change listener keys on the song, not the index

Removing or reordering a queue entry *above* the playing one shifts its index
without changing a note of what is playing. Watching the index would read every such
edit as a track change: refetch the favourite state, rebuild the palette, and — with
autoplay off — pause the music mid-song. So `_lastSongId`, not `_lastIndex`.
`currentIndex` is still updated on every emission, because next/previous walk from
it.

## Phase 2 — Stop the network from killing the player

`disposePlayer()` is deleted. `player.dispose()` now appears exactly once in the
codebase, in `SongController.onClose`.

`internet_controller.dart` no longer touches the player's lifetime:

- `disconnected` → `pausePlaying()`. just_audio picks the stream back up by itself.
- `slow` → **nothing**. "Slow" is not "offline"; just_audio buffers through it, and
  cutting the audio because a reachability probe was sluggish is worse than a moment
  of rebuffering. The flag still flips, so the offline page still swaps in — that
  part is unchanged and is arguably still too aggressive, but it is reversible and
  killing the player was not.

The doc comment on `_guardPlayerCall` documented this bug as unfixed and load-bearing
against it. Rewritten: the guard stays, for the ordinary reason that a seek against a
half-loaded source can fail and no transport control has anything useful to say when
it does.

## Phase 3 — Bound the network

**One Dio, in `apis/all_urls.dart`, with timeouts.** Five controllers each built a
bare `Dio()`, and a bare Dio has no timeouts at all — the defaults are null, meaning
wait forever. Every screen already had a loading state and an error state; nothing
bounded how long the first lasted before the second could appear, so a host that
accepted a connection and then went quiet left the app spinning with no way back but
a restart.

10s connect / 15s receive / 10s send. Deliberately generous: this streams from shared
hosting to phones on mobile data, and a timeout that fires on a merely slow
connection turns a slow screen into a broken one.

The five `Dio dio = Dio()` fields are gone; each controller calls `api` directly.
Four `package:dio` imports went with them — only `SearchSongController` still needs
one, for an explicit `Response` type.

**`MySongs.fromJson` is tolerant now.** It read every key straight out of the map and
cast it, so one row with a null column — or a `songid` the PHP layer handed back as
the string `"12"`, which it does depending on the driver — threw mid-parse and took
the whole screen to its error state. Same `int.tryParse('${...}') ?? 0` /
`as String? ?? ''` shape `Artist.fromJson` already used. One bad row now costs one
bad row.

## Phase 4 — Recently played

`lib/controller/recent_controller.dart` — an `RxList<MySongs>`, newest first,
deduplicated by id, capped at 20, mirrored into `shared_preferences` as a JSON list.
`MySongs` already round-trips through `toJson`/`fromJson`, so a row is stored whole
rather than as an id that would need re-fetching before the strip could render. The
unreadable-data path discards and starts clean, the same call `SettingsController`
makes for remembered positions.

**Recorded from the track-change listener, not from `playQueue`.** That is the whole
reason it works with the rest of this push: a tap, an auto-advance, the
notification's skip button and a bluetooth remote all pass through that listener, and
only the first passes through `playQueue`.

**`lib/main_nav_pages/quick_picks/recent_strip.dart`** — a "Jump back in" row of
112dp cards between the hero and "More picks". Same stack as the grid cell it sits
above (artwork, `Radii.md`, `kArtScrim` under the `NowPlayingMarker`) minus the
artist line, which at that width truncates to two words and buys nothing.

It renders `SizedBox.shrink()` when the history is empty — no empty state. This is
supplementary to Quick picks rather than a destination, and an empty state here would
be a permanent apology on the home screen of a new install.

Settings' identity reset clears it. It is stored locally rather than against the
listener id, so nothing else ever would, and a reset that leaves your listening
history on the home screen has not reset much.

## Phase 5 — Play next / Add to queue

`SongController.playNext` / `addToQueue`, on `insertAudioSource` / `addAudioSource`.
Both fall back to `playQueue([song], 0)` on an empty queue — a control that silently
does nothing is worse than one that does the obvious thing.

**`lib/global_widgets/song_actions_sheet.dart`** — the same `GlassPanel` +
`SheetDragHandle` + `kSheetMaxHeightFraction` shape as the queue and options sheets,
with a header naming the song, because a menu with no subject is one you have to
remember the context of.

Reached two ways, deliberately:

- a `⋯` button in `SongTile`'s trailing row, at `textTertiary` — it repeats on every
  row, and at full strength a list reads as a column of dots with songs behind them.
  When a row is also the now-playing row, `trailing` carries both the marker and the
  button: the marker says what the row *is*, the button offers what you can do to it.
- a long press, on the rows *and* on the artwork tiles in Quick picks and the recent
  strip. On a grid cell there is no room for a button, so there the long press is the
  only way in — but on a row it is never the only way, because a gesture with no
  visible affordance is a feature most people never find.

Confirmation uses the app's existing idiom rather than a new one: white on black,
floating, `clearSnackBars()` first, exactly as Settings' "Listener id copied" does.
`AppColors.danger` stays reserved for failures. The `ScaffoldMessenger` is resolved
*before* the sheet pops — looking one up through a defunct context is the standard
way to turn a confirmation into a crash.

---

## Verification

**Phases 1 and 2 cannot be verified by `flutter analyze`. Every item needs a
physical device.** Record results in the Log above as they are run.

**Background and the notification card**

1. Play a track, background the app — audio continues, card appears in the shade.
2. Card shows artwork, title, artist, a working seek bar, and **enabled `⏮ ⏯ ⏭`**.
   Greyed-out skip buttons mean the queue never reached just_audio.
3. Lock the screen — controls present, all four functional.
4. Bluetooth headset or wired remote: play/pause, double-tap next, triple-tap
   previous.
5. The status-bar icon is a clean white glyph, not a grey square.
6. Swipe the card while paused — dismisses. While playing — does not.
7. Tap the card body — returns to the running app, not a fresh launch.
8. Android 13+: if the card never appears at all, check `POST_NOTIFICATIONS`.
9. iOS: the same list, driven by `UIBackgroundModes`.

**Interruptions** — an incoming call pauses and resumes; another app taking audio
focus pauses Nyro; unplugging headphones pauses rather than blaring.

**Regression sweep on the rewritten controller.** This is the highest-risk part of
the whole push — four behaviours moved off `ProcessingState.completed`.

- shuffle on and off mid-queue (the playing track must not change); repeat off/all/one
- sleep timer, both "end of current track" and a fixed duration
- autoplay off — must stop at the end of the current track, not roll on
- remember-position restore, on a list tap and on a queue-sheet jump
- queue sheet reorder and swipe-to-remove, including removing the playing track
- default playback speed survives a track change
- gapless: back-to-back tracks with no silent gap (new, free)

**Phase 2** — play a track, drop wifi and restore it, then force a slow connection.
Playback must recover and every control must still respond. Before this phase the
player was dead for the rest of the session.

**Phase 3** — point `myWebHost` at an unroutable address; every screen must reach
its error state within ~15s instead of spinning forever.

**Phases 4-5** — play three tracks, kill the app, relaunch: the strip shows all
three, newest first, no duplicates. "Play next" lands the track directly after the
current one in the queue sheet; "Add to queue" lands it at the end.

`flutter analyze` clean throughout — `progress.md` records that as the standing bar.

**When this is all done, update `progress.md` and `release.md`.** Both currently
describe background playback as absent and the `disposePlayer` bug as open.
