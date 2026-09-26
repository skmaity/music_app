# Nyro Three-Source Music Experience Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.
> Planning only. Implementation requires the user's next instruction. If the named orchestration skill is unavailable, use available coding-agent-orchestration/safe-feature-delivery procedures; do not invent a tool or workflow.

**Goal:** Make Nyro an Android-first, privately distributed music app with Local, Nyro Server, and YouTube modes, source-aware discovery/navigation, a persistent library, downloads where permitted and technically available, and continuous contextual playback.

**Architecture:** One shared playback engine and persistent library sit above three provider adapters. Browsing source is independent of the active playback session. Persist stable track references and metadata; resolve temporary network streams just before playback, never store signed media URLs or resolver handles.

**Tech Stack:** Existing Flutter/GetX, just_audio, just_audio_background, youtube_explode_dart, PHP catalogue. Proposed SQLite persistence through a migration-capable Flutter library (prefer Drift after compatibility review), Android MediaStore/Storage Access Framework for local media, and a native-capable download worker chosen after a physical-device spike.

---

## 1. Confirmed scope and inspected baseline

Project: `E:/my_work_projects/music_folders/music_app`.

- Distribution is direct/private APK only. Play Store/App Store work is excluded.
- Current YouTube source is general YouTube search plus a proven continuous-stream resolver, not a full YouTube Music catalogue integration.
- `lib/services/youtube_source.dart` returns up to 20 search items; no homepage, artist/album discovery or recommendation pagination exists there.
- `lib/model/song_model.dart` supports backend and youtube only. `!isBackend` is currently treated as YouTube; this must become exhaustive source dispatch before local files are introduced.
- `lib/controller/song_controller.dart` owns one native playlist. Preserve it as playback authority; do not build a second competing queue cursor.
- `lib/dashboard_page.dart` has Quick picks, Songs, Favorites, Artists and Settings. Its global offline replacement currently hides every page, including Settings.
- `RecentController` filters out external songs. Favourites use backend song IDs and PHP endpoints. Neither is ready for source-independent library features.
- The working tree contains existing unrelated modifications. Preserve them; no reset, wholesale staging or automatic pull.
- User reports current playback works well. Prior automated evidence covered the original cutoff, not hours-long sessions, gapless transitions, downloads or recommendation quality.

## 2. Product decisions and defaults

### Global source selector

Use a three-segment control: **Local | Nyro Server | YouTube**. "Nyro Server" is clearer than "author streamed" and means the owner's hosted catalogue. Place it above page content beside/below the page heading, not solely inside Songs. Keep the navigation rail.

- Remember the last selected source.
- Start first-time users in YouTube, with a short explanation of all sources.
- Source switching preserves the selected destination, independent scroll/search state, and the active audio session.
- Show a source badge on the mini-player so browsing Local while YouTube plays is not confusing.
- Explicitly playing a different item starts/replaces its playback context. Adding Play next/Add to queue does not replace it.
- Keep default radio recommendations in the session's original source. Allow deliberate mixed-source playlists/queue additions with badges; never mix providers silently.
- Use Montserrat consistently, existing Nyro styling, accessible touch targets, scalable text and reduced-motion support.

### Source-aware navigation matrix

| Destination | Local | Nyro Server | YouTube |
|---|---|---|---|
| Quick picks | Recent, most played, recently added, shuffle library | Existing curated picks, latest additions where metadata exists, favourites-based selections | For you, listen again, artist/track radio, language/mood mixes, related discoveries |
| Songs | Indexed on-device songs, folders/sort/filter, local search | Hosted songs and server search | Discovery/search entry, suggestions, song/video filters, paginated search |
| Favorites | Saved local tracks | Hosted favourites, preserving existing server behavior | YouTube tracks saved in Nyro, independent of Google account |
| Artists | Parsed local tags, Unknown artist fallback | Existing server artists | Real provider artist entities when supported; uploader shown as uploader, not falsely as artist |
| Library (new) | Playlists, albums, folders, history | Playlists, albums when supported, history | Saved playlists/albums, history, followed artists where supported |
| Downloads (new) | Existing files/storage shortcuts, no duplicate download | Hosted downloads | Permitted/available YouTube downloads and statuses |
| Settings | Global settings plus source-specific sections | Same | Same |

Use source-filtered defaults. Library and Downloads may expose an explicit All sources filter. Downloads are an availability state, NOT a fourth source: a downloaded YouTube track remains a YouTube track.

## 3. Discovery and recommendation design

### Separate metadata discovery from playback

Keep the working youtube_explode_dart audio path initially. Add a `YouTubeMusicDiscovery` boundary for music-oriented search, home sections, artist/album/playlist browse, related tracks/radio and continuation cursors. Validate which capabilities an available maintained provider actually exposes before committing to a library or endpoint contract.

A discovery spike must prove search -> stable video ID -> existing playback resolver, related-track pagination, music entity IDs, and unavailable/region-restricted handling on the phone. Do not present generic video search as verified music-only discovery. Do not copy GPL reference code into the project without reviewing license implications.

Fallback if a music-specific capability is unavailable: clearly labelled Nyro mixes generated from known track/artist/language signals and related/search candidates. Hide unsupported album/artist browse actions rather than fabricate entities or counts. No brittle hardcoded IDs masquerading as recommendations.

### Nyro personalization, without Google login

- Optional onboarding: preferred languages, genres and a few artists; Skip is available.
- Cold start: source-backed editorial/discovery sections if available, otherwise transparent preference-based mixes.
- Gather local play history, meaningful listening duration, completions, early skips, favourites and Don't recommend actions.
- Rank candidates by seed relevance, preferences and positive history, with recent-repeat penalties, artist diversity and exclusions.
- Cache metadata, cap cache size and refresh deliberately. Preserve valid cached sections when refresh fails.
- Include clear history/reset recommendations and private-listening controls.
- YouTube Music account recommendations, subscriptions, official Liked Music synchronization and algorithm parity are NOT promised. Initial favourites/recommendations belong to Nyro.

## 4. Continuous listening and queue rules

A tap on a search result must play that song and seed a radio session, not a permanent one-song queue. A playlist/album tap starts the chosen ordered context; recommendations extend it after its explicit items.

- Default **Autoplay recommendations ON** for YouTube; expose a visible toggle in queue/player.
- Distinguish normal queue continuation from recommendation refill. Autoplay OFF finishes explicitly queued items and then stops; it must not pause after each track (existing setting behavior must be migrated deliberately).
- Keep explicit user-added songs before the generated recommendation tail. Preserve their order and show an "Up next / Recommended" boundary.
- Keep a rolling metadata buffer, initially about 10 candidates. Refill once fewer than 3 usable recommendations remain; tune after measurement.
- Prepare only a bounded next-track window (initially 1-2), keeping resolver clients alive as needed. Do not resolve every saved playlist item or open unbounded clients.
- Validate just_audio lazy preparation on physical devices. Choose a lazy source or bounded append strategy based on evidence, maintaining the native queue as authority and functional notification skip buttons.
- Resolve expired streams again by stable track ID; use the existing continuous provider reader, not the failed manual 512 KiB CDN range approach.
- Deduplicate generated candidates against recent session history; explicit user repeats are allowed. Distinguish stable track identity from unique queue-entry identity.
- Fence asynchronous search/refill/resolve work with session IDs. Stop, new playback, queue removal and source disposal invalidate obsolete jobs and close abandoned handles.
- Failed tracks get bounded retries, then skip with a visible reason. After a configurable consecutive-failure threshold (initially 3), stop with Retry rather than looping forever.
- Preserve pending queue during connectivity loss, show waiting/retry state, and do not count an offline burst as a series of unavailable tracks.
- Pause/Stop/sleep timer/audio-focus loss must win over late background tasks. No automatic restart after explicit Stop or app relaunch.
- Repeat one repeats the current track without radio refill. Repeat all loops the explicit queue without growing it. Default repeat off allows radio extension. Local finite libraries may cycle only with a clear repeat/continuous-library setting.
- Save queue references and position for user-initiated resume; never auto-play sound on relaunch.

Continuous playback is an intention, not an absolute guarantee during outages, provider failure, depleted local libraries or OS process termination.

## 5. Shared data and library model

Introduce immutable persistent `TrackRef`/metadata and separate ephemeral playback sessions. Use migration adapters rather than abruptly replacing legacy server JSON.

- Track key: source plus provider ID. Local identity includes MediaStore volume + media ID or granted document URI; account for removed/reindexed files.
- Additional entities: ArtistRef, AlbumRef, PlaylistRef, QueueEntry, PlaybackContext, HomeSection, paged results and SourceCapabilities.
- Capabilities include discovery, related tracks, album/artist browse, download eligibility and offline play. A disabled capability has an explicit reason.
- Tables: tracks, favourites, playlists, playlist_entries, listening_events, resume_positions, downloads, source_preferences and schema migrations.
- Store title/artist/artwork references/duration/provenance and stable IDs. Stream URLs and client handles remain memory-only.
- SQLite indexes use source+ID and unique queue/playlist entry IDs. Preserve user ordering and intentional duplicate playlist entries.
- Migrate existing local recents/preferences idempotently. Preserve server favourites via a dedicated adapter and cache; never send YouTube/local IDs to PHP song-ID endpoints.
- Offline server favourite changes use a bounded idempotent pending-operation queue with conflict/error state; audit server support before promising sync.
- YouTube/local favourites are local-first; survives restart and normal in-place APK updates. Cross-device synchronization is a separate future backend feature.
- Add export/import of library metadata for backup; exclude secrets, signed URLs, file bytes and unusable device-specific local URIs (mark local relinking required).

## 6. Local music and offline downloads

### Local source

Use Android MediaStore with version-appropriate audio permission requests, plus optional user-selected folders through SAF/persisted grants. Do not demand broad all-files access. Query off the UI thread, paginate large libraries, cache artwork, refresh on media changes, support denied/revoked permissions and deleted files. Group tracks by actual tags with honest fallbacks; avoid assuming a filename equals an artist.

### Downloads

Provide Download in player, track action sheet and eligible playlist actions. "Any song" is the desired UX, but the system must check rights/source eligibility and stream availability; restricted/DRM/unavailable content must not be bypassed. Existing local files are Already on device.

- Explicit user-triggered persistent downloads, separate from bounded transient playback buffering.
- State machine: queued -> resolving -> downloading -> verifying -> complete, with paused/cancelled/failed branches.
- Progress, Wi-Fi-only, quality choice based on actual available formats, low-space checks, retry and cancel; initial concurrency limit 2.
- Keep partial data in app-private `.part` files. Validate expected length/container/integrity before atomic final rename and database completion.
- Never declare a partial file available offline. Startup reconciles orphaned/partial/missing records and files.
- Downloads resolve fresh streams in memory. Resume only when format, byte identity, validator/range support and provider behavior permit; otherwise restart safely and explain it. Do not reuse saved signed URLs or the known-broken manual range algorithm.
- Android-native background execution/notification integration must be proven across screen-off and process recreation; do not promise survival of user Force stop.
- Download workers own their resolver sessions independently from playback; cancelling one must not kill the other.
- Prefer verified local downloads for playback and retain original source identity/favourite state.
- Deleting an in-app download preserves favourites/playlists, and never deletes a user's original local song. No file export by default; user-selected export can be added later for permitted content.
- Do not reindex app-private downloads as duplicate Local tracks.
- Offline dashboard remains available: Local, Downloads, library, Settings and cached metadata; unavailable actions show inline errors instead of replacing the entire app.

## 7. Ordered implementation work packages

Every code task follows: add focused test -> run and confirm expected failure -> minimal change -> focused pass -> relevant regression suite -> scope review. Commits must include explicit task paths only and respect existing uncommitted work. Commands below are future validation steps, not results from this planning turn.

### Task 1: Baseline and capability spike
**Objective:** Protect current behavior and establish real music-discovery/download capabilities.
**Files:** inspect `lib/services/youtube_source.dart`, `lib/services/youtube_audio_source.dart`, `pubspec.yaml`, `pubspec.lock`; create `tool/youtube_music_discovery_probe.dart`, `test/youtube_discovery_contract_test.dart`, `integration_test/youtube_discovery_test.dart`.
**Steps:** inventory dirty worktree; run existing tests; add discovery contract tests with injected results; inspect candidate implementations/licenses; live-test stable music IDs, pagination, related results and existing resolution; record unsupported capabilities; verify download feasibility with permitted test media. Preserve the working player during the spike.
**Gate:** Written capability report and deterministic adapter contract; no fake claim of official recommendation parity.

### Task 2: Source model and persistent library
**Files:** modify `lib/model/song_model.dart`; create `lib/model/track_ref.dart`, `lib/model/music_entities.dart`, `lib/model/source_capabilities.dart`, `lib/data/library_database.dart`, `lib/repositories/library_repository.dart`, `test/library_migration_test.dart`, `test/track_ref_test.dart`.
**Steps:** test legacy round-trip and source-key collisions; add exhaustive three-source model; split runtime handles from persistence; implement migrations; import recents and cache server favourites without rewriting server IDs; test corrupt/missing data and restart durability.
**Gate:** Existing hosted catalogue still plays; all sources can store stable references without serializing signed URLs.

### Task 3: Provider adapters and source-aware shell
**Files:** create `lib/services/music_provider.dart`, `lib/services/backend_music_provider.dart`, `lib/services/local_music_provider.dart`, `lib/services/youtube_music_provider.dart`, `lib/controller/music_source_controller.dart`, `lib/global_widgets/music_source_selector.dart`; modify `lib/dashboard_page.dart`, `lib/controller/nav_controller.dart`, `lib/main.dart`; test `test/source_navigation_test.dart`, `test/offline_navigation_test.dart`.
**Steps:** test source switching and stale requests; add capability-driven interface; wire existing server and YouTube adapters; add segmented selector with per-source state; replace global offline gate; add Library/Downloads routes using stable destination IDs.
**Gate:** Every rail destination uses selected source; source switching never stops or replaces active playback; offline Settings/Local/Downloads accessible.

### Task 4: Local-library slice
**Files:** create `lib/services/local_media_index.dart`, `lib/main_nav_pages/library/library_page.dart`, `test/local_media_index_test.dart`, `integration_test/local_music_test.dart`; modify `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml`, `lib/global_widgets/remote_image.dart`, `lib/services/local_music_provider.dart`, player source dispatch.
**Steps:** test fake media index/permission refusal; select compatible MediaStore implementation; implement permission and folder flows; add refresh/search/grouping; handle content-URI art/audio; test real offline playback and deleted files.
**Gate:** Airplane-mode local playback works; denying media access does not break Server/YouTube.

### Task 5: Favourites, history and playlists
**Files:** modify `lib/controller/recent_controller.dart`, `lib/main_nav_pages/user_favourite_songs/controller/user_favourite_controller.dart`, `lib/main_nav_pages/user_favourite_songs/user_favourite_page.dart`, `lib/main_nav_pages/playlists/playlists.dart`, `lib/global_widgets/song_actions_sheet.dart`, `lib/controller/song_controller.dart`; create `test/source_library_test.dart`, `test/server_favourite_compatibility_test.dart`.
**Steps:** test YouTube favourite persistence without stream URL; route library actions by source; persist listened events only after actual playback; support create/rename/reorder/remove playlists; add source-filtered library and backup metadata; test old server favourites unchanged.
**Gate:** Favourite a YouTube result, restart app, open favourite and resolve it afresh successfully.

### Task 6: Shared lazy queue and continuous radio (highest-value listening slice)
**Files:** create `lib/services/playback_resolver.dart`, `lib/services/queue_coordinator.dart`, `lib/services/radio_session.dart`, `lib/model/playback_context.dart`; modify `lib/controller/song_controller.dart`, `lib/controller/settings_controller.dart`, `lib/player_page/queue_sheet.dart`, `lib/player_page/player_page.dart`, `lib/main_nav_pages/search_songs/songs.dart`; test `test/radio_session_test.dart`, `test/queue_coordinator_test.dart`, `integration_test/youtube_radio_test.dart`.
**Steps:** test queue order/refill/cancellation with fakes; wire source-specific lazy resolution; preserve native queue authority; implement explicit/generated boundary and bounded prefetch; migrate autoplay setting; handle failures/repeat/shuffle; add stop/session invalidation and handle cleanup; physical background transition testing.
**Gate:** Search -> play -> multiple automatic related tracks without taps; adding Play next wins over recommendations; explicit Stop cannot be undone by late network callbacks; notification next/previous stay correct.

### Task 7: Music discovery, Quick picks and entity browsing
**Files:** create `lib/services/youtube_music_discovery.dart`, `lib/services/recommendation_service.dart`, `lib/controller/discovery_controller.dart`, `lib/main_nav_pages/library/entity_detail_page.dart`; modify `lib/main_nav_pages/quick_picks/quick_picks.dart`, `lib/main_nav_pages/quick_picks/quick_picks_controller.dart`, `lib/main_nav_pages/search_songs/controllers/search_song_controller.dart`, `lib/main_nav_pages/search_songs/songs.dart`, `lib/main_nav_pages/artists/artists_page.dart`, `lib/main_nav_pages/albums/albums.dart`; test `test/recommendation_service_test.dart`, `test/discovery_sections_test.dart`, `test/youtube_search_widget_test.dart`.
**Steps:** test cold-start/ranking/dedup/blocked candidates; implement optional preference selection; wire validated discovery capabilities; render cached/paginated source-aware sections; implement artist/album/playlist details where supported; support Start radio from song/artist/playlist.
**Gate:** YouTube Quick picks offers useful playable sections without typing; likes/listens change future local ranking; empty/unavailable providers show honest fallbacks.

### Task 8: Reliable offline downloads
**Files:** create `lib/services/download_manager.dart`, `lib/services/download_storage.dart`, `lib/model/download_record.dart`, `lib/main_nav_pages/downloads/downloads_page.dart`, `test/download_manager_test.dart`, `test/download_recovery_test.dart`, `integration_test/offline_download_test.dart`; modify `pubspec.yaml`, Android worker/notification integration after spike, `lib/global_widgets/song_actions_sheet.dart`, `lib/services/playback_resolver.dart`.
**Steps:** prove compatible background worker with permitted fixture; test state transitions/storage limits; implement durable jobs and ownership isolation; integrate verified-file preference; expose progress/retry/cancel/delete; test airplane-mode playback, expired links, interruption/restart and file deletion.
**Gate:** Completed download plays a whole song without network; interrupted file never marked complete; library membership survives download deletion.

### Task 9: Hardening and direct-release acceptance
**Files:** `integration_test/three_source_journey_test.dart`, existing `integration_test/youtube_android_test.dart`, new focused tests above, `android/app/build.gradle`, `lib/main_nav_pages/settings/settings.dart`, project release docs when implementation is authorized.
**Steps:** run full regression/release-mode checks; memory/battery/data-use sessions; signed direct APK and in-place upgrade rehearsal; verify backup before any signing transition; privacy-safe diagnostics and provider disable control; dependency/license/secret review; remove probes from shipping entry points.
**Gate:** Verified direct-install release, no store tasks. Never promise rollback to a lower versionCode without a forward-fix package/data compatibility plan.

## 8. Validation commands and acceptance journeys

From project root, implementation-time checks:

```text
flutter test test/track_ref_test.dart test/library_migration_test.dart
flutter test test/source_navigation_test.dart test/offline_navigation_test.dart
flutter test test/radio_session_test.dart test/queue_coordinator_test.dart
flutter test test/recommendation_service_test.dart test/source_library_test.dart
flutter test test/download_manager_test.dart test/download_recovery_test.dart
flutter test
flutter analyze --no-pub
flutter devices
flutter test integration_test/youtube_android_test.dart -d <discovered-device-id>
flutter test integration_test/youtube_radio_test.dart -d <discovered-device-id>
flutter test integration_test/offline_download_test.dart -d <discovered-device-id>
flutter test integration_test/three_source_journey_test.dart -d <discovered-device-id>
flutter build apk --release
git diff --check
```

Tests should initially fail for missing behavior, then pass after implementation. Existing analyzer infos must be recorded separately; no new errors/warnings accepted. Signing configuration requires explicit review rather than silently changing the installed app's identity.

Release journeys:
1. Select YouTube + Quick picks -> play -> lock screen -> several recommended transitions -> Stop remains stopped.
2. Search one song -> play -> Play next another -> related tail resumes -> favourite -> restart -> replay favourite.
3. Browse Local while YouTube plays -> source switch leaves player unchanged -> explicitly play Local -> correct source badge/queue.
4. Deny permissions -> Local explains request, other sources work -> grant -> index -> airplane-mode play.
5. Download permitted track -> complete verification -> airplane-mode whole-track playback -> delete download, favourite remains.
6. Change source during search, stop during resolve, rapid next/previous, delete queued item while prefetching -> no stale takeover or leaked clients.
7. Internet loss/recovery, missing track, unavailable recommendation endpoint, expired URL -> bounded honest recovery.
8. Long run of at least 60 minutes and multiple automatic transitions on physical devices; compare memory before/after, audio continuity, background controls and battery/data use. Not a substitute for full-song offline testing.
9. Old server favourites/recents survive migration; backed-up metadata imports safely; no signed URLs in DB/logs/export.
10. Upgrade signed APK in place -> library/download records/settings remain; no unexpected sound on launch.

## 9. Priorities, deferred features and decisions

Recommended delivery: foundation (1-3) -> Local (4) -> persistent favourites (5) -> search-to-radio (6) -> Quick picks/discovery (7) -> downloads (8) -> full acceptance (9). Tasks 5-7 deliver the core YouTube Music-like experience; do not postpone them for a large visual redesign.

Defaults requiring no clarification to draft: Android first, local-first personal library, no Google login, source switching does not interrupt audio, recommendation autoplay on, downloads in app-private storage, mixed-source playlists only by explicit user action.

Defer: Google-account sync, cloud library accounts, lyrics sourcing, casting, Android Auto, social sharing/follow systems, collaborative playlists, offline recommendation models, iOS distribution and algorithm parity. These can be separate phases, not hidden promises in this release.

Before implementation starts, approve this product scope and priority order. Discovery capability and background download feasibility remain technical spike gates; exact dependency choices/endpoints and time estimates follow those results. No app implementation, installs, production changes or migrations were performed for this plan.
