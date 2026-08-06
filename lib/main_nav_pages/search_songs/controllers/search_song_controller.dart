import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/model/song_model.dart';

class SearchSongController extends GetxController {
  /// Whatever is currently on screen: the default list when there is no
  /// active query, or the results of [lastQuery] otherwise. One list because
  /// the screen only ever shows one of the two at a time.
  RxList<MySongs> searchSongResult = <MySongs>[].obs;

  /// The default list ("All songs" — see [allSongsUrl]), cached apart from
  /// [searchSongResult] so clearing a search restores it without a round
  /// trip, and so a search failure can never lose the list a returning user
  /// expects to still be there.
  final List<MySongs> _defaultSongs = [];

  /// Whether [_defaultSongs] has been fetched at least once. Lets
  /// [loadDefaultSongs] skip the network on every tab return — the whole
  /// point of caching it.
  bool _defaultLoaded = false;

  /// Starts false, unlike the other lists: "no query yet" is genuinely an
  /// empty state, not a load in progress. Flips true for both the default
  /// fetch and a search — whichever is currently filling [searchSongResult].
  RxBool isLoading = false.obs;

  /// A failed request is not an empty result, for the default list or search.
  RxBool hasError = false.obs;

  /// The query the current results belong to, so the screen can offer to
  /// clear it and can retry the right thing. Empty means [searchSongResult]
  /// is the default list, not search results — see [isShowingDefault].
  String lastQuery = '';

  /// True when [searchSongResult] holds the default list rather than results
  /// for [lastQuery]. The empty and error states read differently for each:
  /// "no songs match X" only makes sense once there is an X.
  bool get isShowingDefault => lastQuery.isEmpty;


  Timer? _debounce;

  /// Which fetch owns [searchSongResult] — the default load or a search, only
  /// one of `SearchSongController`'s network calls is ever allowed to win the
  /// shared list. Bumped on entry, checked before every write, same pattern as
  /// `BackgroundController._request` and `SongController._request`.
  int _request = 0;

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  /// Fetches the default list once and caches it. Safe to call from
  /// `initState` on every tab mount — a second call with [forceRefresh]
  /// false is a no-op once the first has landed, which is what makes
  /// returning to the tab free. Pull-to-refresh calls this with
  /// [forceRefresh] true to bypass the cache.
  Future<void> loadDefaultSongs({bool forceRefresh = false}) async {
    if (_defaultLoaded && !forceRefresh) return;

    final request = ++_request;
    hasError.value = false;

    // Skeleton only when the screen has nothing to show yet. A
    // pull-to-refresh on an already-populated list must not blank it out
    // from under the gesture — `RefreshIndicator`'s own spinner covers that
    // case, the same restraint [searchSong] already uses for re-searches.
    isLoading.value = searchSongResult.isEmpty;

    try {
      final res = await api.get(allSongsUrl);

      // A search started (or another refresh began) while this was in
      // flight. Its answer belongs to a screen state that no longer exists.
      if (request != _request) return;

      if (res.statusCode == 200) {
        _defaultSongs
          ..clear()
          ..addAll([
            for (final song in res.data['data'] as List) MySongs.fromJson(song),
          ]);
        _defaultLoaded = true;

        // Only paint over the visible list if nothing else has since claimed
        // it — a background refresh must not stomp on an active search.
        if (lastQuery.isEmpty) {
          searchSongResult.value = List<MySongs>.from(_defaultSongs);
        }
      } else {
        hasError.value = true;
      }
    } catch (e) {
      if (request != _request) return;
      debugPrint('Failed to load songs: $e');
      hasError.value = true;
    }

    if (request == _request) isLoading.value = false;
  }

  /// What the field calls on every keystroke.
  ///
  /// The request waits for [Motion.debounce] of quiet. Search used to fire per
  /// character, and because the results are wrapped in `staggeredEntrance` the
  /// entire list re-animated in on every letter typed — the single most jarring
  /// moment in the app (`design_audit.md` C7).
  void queryChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      clear();
      return;
    }

    _debounce = Timer(Motion.debounce, () => searchSong(query));
  }

  /// Back to the default list, not a round trip and not a blank screen — an
  /// empty query is not a search worth asking the server about, and the
  /// screen must never go empty just because the field did.
  ///
  /// This used to empty [searchSongResult] outright; that is the behaviour
  /// this replaces.
  void clear() {
    _debounce?.cancel();

    // Invalidate anything in flight (a search, or a default-list fetch) so a
    // late answer for the query being abandoned cannot land after this and
    // overwrite the default list that is about to show.
    ++_request;

    lastQuery = '';
    hasError.value = false;

    if (_defaultLoaded) {
      isLoading.value = false;
      searchSongResult.value = List<MySongs>.from(_defaultSongs);
    } else {
      // Cleared before the very first default fetch landed — fetch rather
      // than leave the screen blank until some later trigger tries again.
      loadDefaultSongs();
    }
  }

  Future<void> searchSong(String query) async {
    // Supersedes both an older in-flight search and any default-list fetch —
    // whichever was still running loses the shared list to this one.
    final request = ++_request;

    lastQuery = query;
    hasError.value = false;

    // Only show the skeleton when there is nothing to look at. Swapping
    // results for a skeleton and back on every debounced keystroke flickers
    // worse than the re-stagger it replaced — and unlike a first load, there
    // is no doubt about what the screen is doing.
    isLoading.value = searchSongResult.isEmpty;

    try {
      // Query parameters, not string interpolation into the URL: the old
      // `"$searchSongsUrl?query=$query"` sent spaces and punctuation raw,
      // which is exactly what a title-or-artist search is full of.
      Response res = await api.get(
        searchSongsUrl,
        queryParameters: {'query': query},
      );

      // A newer query (or a clear) arrived while this was in flight. Its
      // answer describes a search the user has already moved on from.
      if (request != _request) return;

      if (res.statusCode == 200) {
        // Replaced in one go, not cleared then refilled — clearing first is
        // what made the list blink empty between every keystroke.
        searchSongResult.value = [
          for (final song in res.data['data'] as List) MySongs.fromJson(song),
        ];
      } else {
        hasError.value = true;
      }
    } catch (e) {
      if (request != _request) return;
      debugPrint('Search failed: $e');
      hasError.value = true;
    }

    if (request == _request) isLoading.value = false;
  }
}
