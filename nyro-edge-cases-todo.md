# Nyro Edge Case Todo
```yaml
title: Edge Cases & Failure Mode Notes
created: 2026-09-27
last-updated: 2026-09-27
```

Trackable TODO list. Each item specifies: category, a description of the edge
case or failure mode, its potential impact, current status, and notes.

Categories: Networking, State Management, Auth, UI/UX, Data Sync, Persistence,
Permissions, Concurrency, and others.

## Networking

- [ ] **Empty error field in POST /favourite endpoint**
    - The hosted server endpoint returns `{ "message": "" }` on failure,
      yielding no visible error to the user.
    - Impact: silent failure that looks identical to success.
    - Proposed fix: the handler reads `statusCode` (4xx) and `data["success"]
      == false` before inspecting the message; if both agree on a failure but
      the message is empty, display a canned message like "That could not be
      saved on this device."

- [ ] **Connection failures are swallowed**
    - `toggleFavourite` calls `_postFavourite` with a trailing `?`. Both
      network request failures and JSON-parsing errors are caught and logged
      to stderr.
    - Impact: a network blip leaves the user thinking the favourite was
      recorded.
    - Proposed fix: call `?` only in long-press handling. The tap handler
      must return a message on any error, so `isFavourite` can branch:
      `null` → retry, `"Could not reach the server."` → show tomo error, other
      strings → show a short message from the host.

## State Management

- [ ] **RecentController records from a failed track-change listener**
    - The listener fires on any transport event before calling the player's
      `onError` callback. For YouTube, the track never starts playing and the
      next track is queued immediately.
    - Impact: a failed track change may still be recorded as history.
    - Proposed fix: check the player state inside the listener; do not record
      an event if the player is not in `ready` state.

- [ ] **YouTube request hangs on 204 No Content responses**
    - Nyro Server sometimes responds to a playlist request with a `204 No
      Content` body and a `Location` header containing a direct audio URL.
      If that redirects to the host's catalogue listing page instead of an
      empty `application/json` body, the request hangs past `wait_for_load`.
    - Impact: search and defaults are stuck, the player shows only a spinner,
      and a new search (debounced) can race to replace it.
    - Proposed fix: handle `204` in `ApiException` so `loadSongs` reports
      `hasError.value` and `errorMessage.value` instead of a hanging response.

- [ ] **YouTube streams die without player notification**
    - YouTube terminates streams. `just_audio`'s `onError` callback fires
      without a `just_audio` `error` event. `onPlaybackError` also does not
      fire.
    - Impact: the track changes abruptly, the history recorder fires, and the
      new track never starts playing.
    - Proposed fix: poll `player.processingState` as a fallback; listen to
      `progress`. Listen to YouTube's `onStreamEnd`.

## Data Sync

- [ ] **Playlist entries list does not clear on mount/dispose**
    - `LibraryPlaylistController` does not clear its cached entries list on
      mount or dispose.
    - Impact: stale entries remain visible, or when swapping between sources
      a playlist from one source is visible while playing from another.
    - Proposed fix: clear `playlistEntries` on mount and dispose, and clear
      the cache when `selectedPlaylistId` changes.

- [ ] **Playlist entries cache is not invalidated on data reload**
    - The cache lives in `_entriesCache` and is populated on request. Nothing
      invalidates it between `loadPlaylistEntries` and `getQueue` calls.
    - Impact: stale entries may be used on the next request.
    - Proposed fix: clear the cache in the same transaction that populates the
      request result, and invalidate whenever the cache misses on every
      request instead of lazily on dispose.

- [ ] **Track list clears on every mount regardless of source**
    - The `playlistEntries` page controller clears `playlistEntries` on
      dispose, and on mount it calls `loadPlaylistEntries` which uses the
      global source selection from the parent page.
    - Impact: switching to a different source and returning to this page
      clears the entries list.
    - Proposed fix: only clear the cache when the playlist ID changes, and
      only call `loadPlaylistEntries` when the cache no longer has valid
      data for the current source.

- [ ] **Track list re-runs `loadPlaylistEntries` on every `onMount`**
    - The `PlaylistEntriesPage` controller calls `loadPlaylistEntries` on
      mount every time, which queries the database again rather than using
      the cache.
    - Impact: a fresh query per mount is unnecessary and duplicates work.
    - Proposed fix: use the cached value directly in `_body` and only
      repopulate when the cache is stale.

- [ ] **Playlist entries list does not clear on mount/dispose**
    - `LibraryPlaylistController` does not clear its cached entries list on
      mount or dispose.
    - Impact: stale entries remain visible, or when swapping between sources
      a playlist from one source is visible while playing from another.
    - Proposed fix: clear `playlistEntries` on mount and dispose, and clear
      the cache when `selectedPlaylistId` changes.

- [ ] **Track list does not refresh when song changes**
    - The track list in Favourites does not re-run `loadSongs` when the song
      changes.
    - Impact: the track list may show stale data.
    - Proposed fix: in the `SongController` track-change listener, re-run
      `loadSongs` when a song changes, or add a reactive trigger.

- [ ] **Track list clears on every mount regardless of source**
    - The track list page clears its state on mount regardless of the current
      source selection.
    - Impact: switching to a different source and returning to this page
      clears the list.
    - Proposed fix: only clear the list when the source changes, not on every
      mount.

- [ ] **Track list re-runs `loadSongs` on every mount**
    - The track list page re-runs `loadSongs` on mount every time, which
      queries the database again rather than using the cache.
    - Impact: a fresh query per mount is unnecessary and duplicates work.
    - Proposed fix: use the cached value directly in `_body` and only
      repopulate when the cache is stale.

## Persistence

- [ ] **Database transaction deadlocks on import**
    - `importLegacyRecents` wraps every row in a transaction and acquires a
      write lock for each row.
    - Impact: importing many rows locks the database longer than necessary,
      leaving the page stuck in a loading state.
    - Proposed fix: bulk-insert all imported tracks in a single transaction.
      The import routine should collect all rows and call a single transaction
      that inserts them all at once.

## UI / UX

- [ ] **Favourites page opens empty**
    - For tracks added via long-press on search results, the "Add to
      Favourites" long-press adds a heart icon but does not trigger the
      "Add to Favourites" page.
    - Impact: the user performs an action that looks like it succeeded but has
      no visible effect.
    - Proposed fix: the "Add to Favourites" page should be routed to the new
      `favourites.page` route so the user can see their favourites.

- [ ] **"Add to Favourites" page does not navigate to favourites**
    - The "Add to Favourites" page currently routes to `Search.page` with the
      "Favourites" segment selected, which shows a filtered list instead of
      the actual Favourites page.
    - Impact: the user ends up on a filtered search results page instead of
      their favourite songs.
    - Proposed fix: the "Add to Favourites" page should navigate directly to
      the `favourites.page` route.

- [ ] **Add to Favourites page lacks a header**
    - Unlike the track list and other navigation pages, the "Add to
      Favourites" page does not include a page header.
    - Impact: the page lacks branding and context, especially when the tab bar
      is at the bottom of the screen.
    - Proposed fix: add a header consistent with the other pages.

- [ ] **Recent strip shows placeholder songs**
    - The "Recent" strip currently lists all recently-played songs, including
      placeholder songs that have never actually played.
    - Impact: the strip is misleading and shows entries for tracks that the user
      never listened to.
    - Proposed fix: add a filter in `RecentController.record()` to skip
      placeholder songs.

- [ ] **Recent strip does not clear on reset**
    - The `ResetSettingsPageController` does not clear the recently-played list.
    - Impact: after a reset, the strip still shows previous songs.
    - Proposed fix: call `recentController.clear()` in the reset handler.

- [ ] **Track list does not handle empty state**
    - The "Track list" page does not handle the case when there are no songs
      in the library.
    - Impact: the page looks broken or confusing when the library is empty.
    - Proposed fix: add an empty state message when no tracks are available.

- [ ] **Search results page does not handle empty state**
    - The "Search results" page does not handle the case when no songs match
      the query.
    - Impact: the page shows a blank list or an unhelpful message.
    - Proposed fix: add an appropriate empty state message for YouTube and
      Nyro Server sources.

- [ ] **Search page error state can be left in a bad state**
    - When an error occurs during loading or search, the error state may not
      be cleared properly on successful subsequent attempts.
    - Impact: the error message may persist incorrectly or new errors may not
      show up.
    - Proposed fix: ensure error state is cleared when a successful response
      is received or on page dispose.

## Concurrency

- [ ] **Playlist entry reordering can be interrupted by a new song request**
    - `reorderPlaylistEntries` is a long-running file I/O operation. During
      execution, a new `loadSongs` call (e.g. from a tap) can overwrite the
      cached `playlistEntriesList`.
    - Impact: the reordering may fail silently with no indication to the user.
    - Proposed fix: guard `loadSongs` against running while a reordering
      operation is in progress, use a mutex or a revision number to detect
      conflicts, or provide a progress indicator during reorder.

- [ ] **SongController.trackChanged calls `_maybeSaveLastPosition` which fires I/O**
    - `trackChanged` fires on every transport event (next/previous tap,
      auto-advance, notification skip). Each call chains to `_maybeSaveLastPosition`, which
    - writes to disk.
    - Impact: every song change triggers a write to shared_preferences, which
      is expensive (`onWrite` can block the UI).
    - Proposed fix: already implemented a 500ms throttle on `_maybeSaveLastPosition`.
      Consider batching updates or using a write-behind queue.

- [ ] **SettingsController.saveLastPosition is called from multiple places**
    - `saveLastPosition` is called from `trackChanged`, from the completion
      event listener, and also from sleep timer activation.
    - Impact: race conditions where multiple callers write concurrently could
      lead to lost updates or inconsistent state.
    - Proposed fix: use a single-threaded approach (e.g. a mutex around the
      write) or make the write idempotent by checking the song ID before
      writing.

## Permissions

- [ ] **Network access not requested for Nyro Server source**
    - The app does not request the required network permission for connecting
      to the Nyro hosted server, nor does it check or handle `http://` URL
      schemes.
    - Impact: the app will crash or throw a security warning when trying to
      load songs from the Nyro Server source.
    - Proposed fix: add a dedicated permission check for `network` and handle
      `http://` URLs appropriately.

## Other

- [ ] **`recentlyPlayed: []` in `shared_preferences`**
    - The `RecentController` writes `recentlyPlayed: []` to persistent
      storage on every record.
    - Impact: `shared_preferences` is written to even when a song changes but
      the list is unchanged. This is unnecessary `on_write` work and clutters
      the storage key.
    - Proposed fix: write only if the list changed.

- [ ] **`TrackRef` fromSong does not check artwork ref stability**
    - `TrackRef.fromSong` uses
      `song.coverurl.isEmpty ? null : song.coverurl`, but the cover URL may
      be unstable or may change over time.
    - Impact: a changed cover URL breaks the `TrackRef` identity and
      dededuplication logic.
    - Proposed fix: ensure the cover URL is stable and only changes when the
      track itself changes.

- [ ] **`RecentController.record` does not check `mounted` before persisting**
    - `RecentController.record` calls `_persist` unconditionally after modifying
      the list.
    - Impact: the app writes to persistent storage even when the page is no
      longer mounted or needs to be disposed.
    - Proposed fix: check `mounted` before calling `_persist`, or use `Future
    .andThen` with a `mounted` check.
