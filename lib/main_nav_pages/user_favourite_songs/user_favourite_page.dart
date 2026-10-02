import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/music_source_controller.dart';
import 'package:music_app/controller/nav_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/global_widgets/empty_state.dart';
import 'package:music_app/global_widgets/motion.dart';
import 'package:music_app/global_widgets/page_header.dart';
import 'package:music_app/global_widgets/skeleton.dart';
import 'package:music_app/global_widgets/song_tile.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/controller/user_favourite_controller.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/player_page/player_page.dart';

typedef PreparedFavouritePlayer = Future<void> Function(MySongs song);

class UserFavouritePage extends StatefulWidget {
  const UserFavouritePage({
    super.key,
    this.sourceOverride,
    this.onPreparedPlay,
  });

  final TrackSource? sourceOverride;
  final PreparedFavouritePlayer? onPreparedPlay;

  @override
  State<UserFavouritePage> createState() => _UserFavouritePageState();
}

class _UserFavouritePageState extends State<UserFavouritePage> {
  late SongController controller;
  late UserFavouriteController favouriteController;
  Worker? _sourceWorker;

  TrackSource get _source =>
      widget.sourceOverride ??
      Get.find<MusicSourceController>().selectedSource.value;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SongController>();
    favouriteController = Get.find<UserFavouriteController>();
    final override = widget.sourceOverride;
    if (override == null) {
      final sourceController = Get.find<MusicSourceController>();
      _sourceWorker = ever<TrackSource>(
        sourceController.selectedSource,
        (source) => unawaited(favouriteController.loadFavourites(source)),
      );
    }
    unawaited(favouriteController.loadFavourites(_source));
  }

  @override
  void dispose() {
    _sourceWorker?.dispose();
    super.dispose();
  }

  Future<void> _reload() => favouriteController.loadFavourites(_source);

  Future<void> _playFavourite(BuildContext context, MySongs favourite) async {
    try {
      final prepared = await favouriteController.prepareForPlayback(favourite);
      if (!context.mounted) {
        prepared.streamHandle?.close();
        return;
      }
      final callback = widget.onPreparedPlay;
      if (callback != null) {
        await callback(prepared);
        return;
      }
      final queue = prepared.isYouTube
          ? <MySongs>[prepared].obs
          : favouriteController.userFavoutitesList;
      playSong(context, prepared, queue);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('This favourite could not be prepared for playback.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader('Favourites'),
        Expanded(
          // Crossfade, not a hard cut: the page used to swap its whole layout
          // for a spinner and then snap to content.
          child: Obx(() => AnimatedSwitcher(
                duration: Motion.normal,
                child: _body(context),
              )),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    if (favouriteController.isLoading.value) {
      return const SongListSkeleton(key: ValueKey('loading'));
    }

    if (favouriteController.hasError.value) {
      return ErrorState(
        key: const ValueKey('error'),
        message: 'Your favourites could not be loaded.',
        onRetry: _reload,
      );
    }

    if (favouriteController.userFavoutitesList.isEmpty) {
      return EmptyState(
        key: const ValueKey('empty'),
        icon: Icons.favorite_border_rounded,
        headline: 'No favourites yet',
        message: 'Tap the heart while a song is playing '
            'and it will show up here.',
        actionLabel: 'Browse songs',
        onAction: () => Get.find<NavController>().go(AppDestination.quickPicks),
      );
    }

    final playingIdentity = controller.currentPlaying.value.identity;

    return KeyedSubtree(
      key: const ValueKey('content'),
      child: RefreshIndicator(
        onRefresh: _reload,
        child: AnimationLimiter(
          child: ListView.builder(
            // Returning to a tab used to put you back at the top; the page is
            // destroyed on every switch, so the offset has to live in the bucket.
            key: const PageStorageKey('favourites'),
            itemCount: favouriteController.userFavoutitesList.length,
            itemBuilder: (context, index) {
              final favourite = favouriteController.userFavoutitesList[index];
              return staggeredEntrance(
                context,
                index,
                SongTile(
                  key: ValueKey(favourite.identity),
                  song: favourite,
                  isPlaying: playingIdentity == favourite.identity,
                  onTap: () => _playFavourite(context, favourite),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
