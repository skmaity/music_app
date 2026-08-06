import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/nav_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/global_widgets/empty_state.dart';
import 'package:music_app/global_widgets/motion.dart';
import 'package:music_app/global_widgets/page_header.dart';
import 'package:music_app/global_widgets/skeleton.dart';
import 'package:music_app/global_widgets/song_tile.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/controller/user_favourite_controller.dart';
import 'package:music_app/player_page/player_page.dart';

class UserFavouritePage extends StatefulWidget {
  const UserFavouritePage({super.key});

  @override
  State<UserFavouritePage> createState() => _UserFavouritePageState();
}

class _UserFavouritePageState extends State<UserFavouritePage> {
  late SongController controller;
  late UserFavouriteController favouriteController;

  @override
  void initState() {
    controller = Get.find<SongController>();
    favouriteController = Get.find<UserFavouriteController>();
    favouriteController.getUserFavourites();
    super.initState();
  }

  Future<void> _reload() => favouriteController.getUserFavourites();

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
        onAction: () => Get.find<NavController>().go(NavDestination.quickPicks),
      );
    }

    final playingId = controller.currentPlaying.value.songid;

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
                  key: ValueKey(favourite.songid),
                  song: favourite,
                  isPlaying: playingId == favourite.songid,
                  onTap: () => playSong(context, favourite,
                      favouriteController.userFavoutitesList),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
