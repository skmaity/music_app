import 'dart:async';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/global_widgets/empty_state.dart';
import 'package:music_app/global_widgets/motion.dart';
import 'package:music_app/global_widgets/page_header.dart';
import 'package:music_app/global_widgets/skeleton.dart';
import 'package:music_app/global_widgets/song_tile.dart';
import 'package:music_app/main_nav_pages/search_songs/controllers/search_song_controller.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/player_page/player_page.dart';
import 'package:music_app/services/playback_resolver.dart';
import 'package:music_app/services/youtube_source.dart';

class SearchSongs extends StatefulWidget {
  const SearchSongs({super.key, this.lockedSource});

  /// When set by the global source-aware shell, the page cannot drift to a
  /// different provider through its legacy two-source control.
  final SearchSource? lockedSource;

  @override
  State<SearchSongs> createState() => _SearchSongsState();
}

class _SearchSongsState extends State<SearchSongs> {
  final TextEditingController songQuery = TextEditingController();
  // `Get.put` here built a whole new SongController — and so a whole new
  // AudioPlayer — every time this page mounted, only for GetX to keep the
  // already-registered one and drop the new instance on the floor. The page is
  // remounted on every tab switch, so that leaked a player each time.
  final SearchSongController controller = Get.find<SearchSongController>();
  final SongController songController = Get.find<SongController>();
  final FocusNode focus = FocusNode();
  final LatestRequest _playbackRequests = LatestRequest();
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    final locked = widget.lockedSource;
    if (locked != null) controller.selectSource(locked);
    // Nothing fetched the default list before this — the screen opened blank
    // until the user typed a query. Safe to call on every mount: it is a
    // no-op once the cache from a previous visit is warm, which is what makes
    // returning to this tab free.
    controller.loadDefaultSongs();
  }

  @override
  void didUpdateWidget(covariant SearchSongs oldWidget) {
    super.didUpdateWidget(oldWidget);
    final locked = widget.lockedSource;
    if (locked != null && locked != oldWidget.lockedSource) {
      _playbackRequests.next();
      songQuery.clear();
      controller.selectSource(locked);
    }
  }

  @override
  void dispose() {
    _playbackRequests.next();
    songQuery.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader('Songs'),
        if (widget.lockedSource == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Obx(() => SegmentedButton<SearchSource>(
                  segments: const [
                    ButtonSegment(
                      value: SearchSource.catalogue,
                      label: Text('Catalogue'),
                    ),
                    ButtonSegment(
                      value: SearchSource.youtube,
                      label: Text('YouTube'),
                    ),
                  ],
                  selected: {controller.selectedSource.value},
                  onSelectionChanged: (value) {
                    _playbackRequests.next();
                    setState(() => _resolving = false);
                    songQuery.clear();
                    controller.selectSource(value.single);
                  },
                )),
          ),
        const SizedBox(height: Space.md),
        Obx(() => controller.selectedSource.value == SearchSource.youtube
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: Space.gutter),
                child: Text(
                    'Experimental YouTube search · one track at a time. '
                    'Saved tracks and YouTube queues are not available yet.'),
              )
            : const SizedBox.shrink()),
        if (_resolving) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          // Rebuilds only the field, and only so the clear button can appear
          // and disappear with the text.
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: songQuery,
            builder: (context, value, _) => TextField(
              focusNode: focus,
              controller: songQuery,
              onChanged: controller.queryChanged,
              textInputAction: TextInputAction.search,
              // Submitting used to do nothing at all — no handler here meant
              // the keyboard's search key just sat there. Treat it as "I'm
              // done": drop the keyboard and run the query immediately rather
              // than making the user wait out the rest of the debounce.
              onSubmitted: _submit,
              // Borders, hint style, height and colours all come from
              // `inputDecorationTheme`; there is nothing left to say here.
              decoration: InputDecoration(
                alignLabelWithHint: true,
                // A real label, not a placeholder pretending to be one. The
                // old field had `hintText` alone — announced as nothing, and
                // "What's on your mind" never said what was being searched.
                labelText: 'Search songs',
                hintText: 'Title or artist',
                // Leading, and it means search. The affordance used to be a
                // music note in the *trailing* slot: not tappable, saying
                // nothing about search, and sitting in the exact position
                // every user reaches for to clear the field.
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _clear,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.lg),
        Expanded(
          child: Obx(() => AnimatedSwitcher(
                duration: Motion.normal,
                child: _body(context),
              )),
        ),
      ],
    );
  }

  void _clear() {
    songQuery.clear();
    controller.clear();
  }

  void _submit(String value) {
    focus.unfocus();
    final query = value.trim();
    // An empty submit is the same as clearing the field by hand — back to
    // the default list, not a round trip for "".
    if (query.isEmpty) {
      controller.clear();
    } else {
      controller.searchSong(query);
    }
  }

  // Pull-to-refresh means something different depending on what is on
  // screen: the default list bypasses its cache, a search re-runs itself.
  // Always calling `searchSong(lastQuery)` here — the old single-purpose
  // retry this replaces — would silently ask the server for an empty string
  // whenever the default list was what needed refreshing.
  Future<void> _refresh() {
    if (controller.isShowingDefault) {
      return controller.loadDefaultSongs(forceRefresh: true);
    }
    return controller.searchSong(controller.lastQuery);
  }

  Widget _body(BuildContext context) {
    if (controller.isLoading.value) {
      return const SongListSkeleton(key: ValueKey('loading'));
    }

    if (controller.hasError.value) {
      final isDefault = controller.isShowingDefault;
      return ErrorState(
        key: const ValueKey('error'),
        message: controller.errorMessage.value.isNotEmpty
            ? controller.errorMessage.value
            : isDefault
                ? 'Your songs could not be loaded.'
                : 'The search could not be completed.',
        // Branches for the same reason `_refresh` does: retrying a failed
        // default-list load by calling `searchSong('')` — what this used to
        // do unconditionally — asks the server for an empty query instead of
        // the songs list, which is not what a "Try again" tap means here.
        onRetry: isDefault
            ? () => controller.loadDefaultSongs(forceRefresh: true)
            : () => controller.searchSong(controller.lastQuery),
      );
    }

    if (controller.searchSongResult.isEmpty) {
      final isDefault = controller.isShowingDefault;
      if (isDefault &&
          controller.selectedSource.value == SearchSource.youtube) {
        return const EmptyState(
            icon: Icons.search_rounded,
            headline: 'Search YouTube',
            message:
                'Enter a title or artist to find public videos and music.');
      }
      return EmptyState(
        key: ValueKey(isDefault ? 'empty-default' : 'empty-search'),
        icon: isDefault ? Icons.music_off_rounded : Icons.search_off_rounded,
        headline: isDefault ? 'No songs yet' : 'Nothing found',
        message: isDefault
            ? 'Nothing has been added to the library yet.'
            : 'No songs match "${controller.lastQuery}". '
                'Try another spelling.',
        actionLabel: isDefault ? 'Reload' : 'Clear search',
        onAction: isDefault
            ? () => controller.loadDefaultSongs(forceRefresh: true)
            : _clear,
      );
    }

    final playingIdentity = songController.currentPlaying.value.identity;

    return KeyedSubtree(
      key: const ValueKey('content'),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: AnimationLimiter(
          child: ListView.builder(
            key: const PageStorageKey('search'),
            padding: EdgeInsets.zero,
            // Without this a list shorter than the viewport does not overscroll,
            // so the RefreshIndicator above it can never be pulled — and the
            // library is currently six songs, which is exactly that case.
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.searchSongResult.length,
            itemBuilder: (context, index) {
              final searchSong = controller.searchSongResult[index];
              return staggeredEntrance(
                context,
                index,
                SongTile(
                  key: ValueKey(searchSong.identity),
                  song: searchSong,
                  isPlaying: playingIdentity == searchSong.identity,
                  onTap: () async {
                    // There was a hardcoded 400ms delay here, waiting on
                    // nothing: 400ms of unexplained latency on this
                    // screen's primary action. Dismissing the keyboard
                    // does not need to be awaited.
                    focus.unfocus();
                    final request = _playbackRequests.next();
                    if (searchSong.source == SongSource.youtube) {
                      setState(() => _resolving = true);
                      try {
                        await songController.playRadioSeed(
                          TrackRef.fromSong(searchSong),
                        );
                        if (!context.mounted ||
                            !_playbackRequests.owns(request)) {
                          return;
                        }
                      } on PlaybackResolutionException catch (e) {
                        if (context.mounted &&
                            _playbackRequests.owns(request)) {
                          _showPlaybackError(context, e.message);
                        }
                      } on TimeoutException {
                        if (context.mounted &&
                            _playbackRequests.owns(request)) {
                          _showPlaybackError(
                            context,
                            'YouTube took too long to provide this audio.',
                          );
                        }
                      } on YouTubeSourceException catch (e) {
                        if (context.mounted &&
                            _playbackRequests.owns(request)) {
                          _showPlaybackError(context, e.message);
                        }
                      } finally {
                        if (mounted && _playbackRequests.owns(request)) {
                          setState(() => _resolving = false);
                        }
                      }
                    } else {
                      playSong(
                        context,
                        searchSong,
                        controller.searchSongResult,
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPlaybackError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
