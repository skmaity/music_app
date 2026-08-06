import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/global_widgets/empty_state.dart';
import 'package:music_app/global_widgets/motion.dart';
import 'package:music_app/global_widgets/page_header.dart';
import 'package:music_app/global_widgets/remote_image.dart';
import 'package:music_app/global_widgets/skeleton.dart';
import 'package:music_app/global_widgets/song_actions_sheet.dart';
import 'package:music_app/global_widgets/song_tile.dart';
import 'package:music_app/main_nav_pages/quick_picks/quick_picks_controller.dart';
import 'package:music_app/main_nav_pages/quick_picks/recent_strip.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/player_page/player_page.dart';

/// Cell width ÷ cell height in the grid.
///
/// The artwork inside a cell is [Expanded], so the type below it takes what it
/// needs first and the art absorbs the rest. That is what keeps a fixed ratio
/// safe at large text scales — the cell never has to grow.
const double _tileRatio = 0.74;

/// Roughly how wide a grid cell wants to be. Columns are derived from it, so
/// two on a phone becomes four in landscape rather than two enormous ones.
const double _tileTarget = 180;

int _columnsFor(double width) => (width / _tileTarget).floor().clamp(2, 5);

/// The most of the fold the hero may take. Album art is square, so left to the
/// content width alone the hero would be 740pt tall in landscape; this also
/// guarantees the grid always peeks, which is what says "keep scrolling".
const double _heroViewportShare = 0.6;

/// Quick picks — the home screen.
///
/// It used to be a flat list of 50×50 rows, **visually identical to Search and
/// to Favourites**: three of five destinations rendering the same screen with a
/// different word at the top. The app's entire premise is that the album art is
/// the experience, and this screen showed that art smaller than anywhere else
/// in it.
///
/// Now: one hero at full width, then a grid. Two densities, artwork first.
class QuickPicks extends StatefulWidget {
  const QuickPicks({super.key});

  @override
  State<QuickPicks> createState() => _QuickPicksState();
}

class _QuickPicksState extends State<QuickPicks> {
  late final SongController controller;
  late final QuickPicksController quickpicksController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SongController>();
    quickpicksController = Get.find<QuickPicksController>();
    quickpicksController.getQuickPicks();
  }

  void _play(MySongs song) =>
      playSong(context, song, quickpicksController.quickpicks);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader('Quick picks'),
        Expanded(
          // The layout maths is shared by every state, so the skeleton lands
          // exactly where the content will — which is the whole point of a
          // skeleton.
          child: LayoutBuilder(builder: (context, box) {
            final content = box.maxWidth - Space.gutter * 2;
            final columns = _columnsFor(content);
            final heroSide =
                math.min(content, box.maxHeight * _heroViewportShare);

            return Obx(() => AnimatedSwitcher(
                  duration: Motion.normal,
                  child: _body(context, heroSide, columns),
                ));
          }),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, double heroSide, int columns) {
    if (quickpicksController.isLoading.value) {
      return _PicksSkeleton(
        key: const ValueKey('loading'),
        heroSide: heroSide,
        columns: columns,
      );
    }

    if (quickpicksController.hasError.value) {
      return ErrorState(
        key: const ValueKey('error'),
        message: "Today's picks could not be loaded.",
        onRetry: quickpicksController.getQuickPicks,
      );
    }

    final picks = quickpicksController.quickpicks;
    if (picks.isEmpty) {
      return EmptyState(
        key: const ValueKey('empty'),
        headline: 'Nothing picked yet',
        message: "New picks land here as soon as they're chosen.",
        actionLabel: 'Reload',
        onAction: quickpicksController.getQuickPicks,
      );
    }

    final playingId = controller.currentPlaying.value.songid;
    final rest = picks.skip(1).toList();

    return KeyedSubtree(
      key: const ValueKey('content'),
      child: RefreshIndicator(
        onRefresh: quickpicksController.getQuickPicks,
        child: AnimationLimiter(
          child: CustomScrollView(
            // Returning to a tab used to put you back at the top; the
            // page is destroyed on every switch, so the offset has to
            // live in the storage bucket.
            key: const PageStorageKey('quick-picks'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                sliver: SliverToBoxAdapter(
                  child: staggeredEntrance(
                    context,
                    0,
                    Center(
                      child: _HeroPick(
                        side: heroSide,
                        song: picks.first,
                        isPlaying: playingId == picks.first.songid,
                        onTap: () => _play(picks.first),
                      ),
                    ),
                  ),
                ),
              ),
              // Between the hero and the grid: below the one thing this screen
              // is actually for, above the long tail you scroll. It hides
              // itself entirely until something has been played, so a fresh
              // install sees the screen exactly as it was.
              const SliverToBoxAdapter(child: RecentStrip()),
              if (rest.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Space.gutter, Space.xl, Space.gutter, Space.md),
                    child: Text(
                      'More picks',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      Space.gutter, 0, Space.gutter, Space.xl),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: Space.md,
                      mainAxisSpacing: Space.lg,
                      childAspectRatio: _tileRatio,
                    ),
                    itemCount: rest.length,
                    itemBuilder: (context, index) {
                      final song = rest[index];
                      return staggeredEntrance(
                        context,
                        index,
                        columnCount: columns,
                        _GridPick(
                          key: ValueKey(song.songid),
                          song: song,
                          isPlaying: playingId == song.songid,
                          onTap: () => _play(song),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The loading state, laid out on the same maths as the real screen so nothing
/// moves when the picks land.
class _PicksSkeleton extends StatelessWidget {
  const _PicksSkeleton({
    super.key,
    required this.heroSide,
    required this.columns,
  });

  final double heroSide;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      children: [
        Center(
          child: Skeleton(width: heroSide, height: heroSide, radius: Radii.lg),
        ),
        const SizedBox(height: Space.xl),
        const Skeleton(width: 140, height: Space.xl, radius: Radii.sm),
        const SizedBox(height: Space.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: Space.md,
            mainAxisSpacing: Space.lg,
            childAspectRatio: _tileRatio,
          ),
          itemCount: columns * 2,
          itemBuilder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: Skeleton(radius: Radii.md)),
              const SizedBox(height: Space.sm),
              const Skeleton(height: Space.md, radius: Radii.sm),
              const SizedBox(height: Space.xs),
              FractionallySizedBox(
                widthFactor: 0.55,
                child: const Skeleton(height: Space.sm, radius: Radii.sm),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The featured pick: artwork at full width with the track written across the
/// foot of it.
class _HeroPick extends StatelessWidget {
  const _HeroPick({
    required this.side,
    required this.song,
    required this.isPlaying,
    required this.onTap,
  });

  final double side;
  final MySongs song;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // A grid cell has no room for a "more" button beside the artwork the
        // way a list row does, so here the long press is the only way in. It is
        // the same sheet either way.
        onLongPress: () => showSongActionsSheet(context, song),
        borderRadius: BorderRadius.circular(Radii.lg),
        // Inside the InkWell, never outside it: excludeSemantics drops every
        // descendant node, and from out here that would take the InkWell's own
        // tap action with it — a control a screen reader can read but not
        // activate.
        child: Semantics(
          button: true,
          excludeSemantics: true,
          label: 'Top pick: ${song.title} by ${song.artist}. Play',
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.lg),
              boxShadow: kArtShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.lg),
              child: SizedBox.square(
                dimension: side,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RemoteImage(
                      url: '$baseUrl${song.coverurl}',
                      size: side,
                      radius: 0,
                    ),
                    // Type over artwork never trusts the artwork.
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: kArtScrim),
                      ),
                    ),
                    Positioned(
                      left: Space.lg,
                      right: Space.lg,
                      bottom: Space.lg,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  song.title,
                                  style: text.titleLarge,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  song.artist,
                                  style: text.bodyLarge?.copyWith(
                                      color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Space.md),
                          // The affordance, not a second target — the whole
                          // card is the button.
                          if (isPlaying)
                            const NowPlayingMarker()
                          else
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(Space.sm),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: scheme.onPrimary,
                                  size: Controls.iconInline,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A grid cell: square artwork, then the track beneath it.
class _GridPick extends StatelessWidget {
  const _GridPick({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onTap,
  });

  final MySongs song;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // A grid cell has no room for a "more" button beside the artwork the
        // way a list row does, so here the long press is the only way in. It is
        // the same sheet either way.
        onLongPress: () => showSongActionsSheet(context, song),
        borderRadius: BorderRadius.circular(Radii.md),
        child: Semantics(
          button: true,
          excludeSemantics: true,
          label: '${song.title} by ${song.artist}'
              '${isPlaying ? '. Now playing' : ''}. Play',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expanded, so the type below claims its height first and the
              // artwork takes what is left. A fixed cell ratio then holds at
              // any text scale.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final side = math.min(box.maxWidth, box.maxHeight);
                    return Stack(
                      children: [
                        RemoteImage(
                          url: '$baseUrl${song.coverurl}',
                          size: side,
                          radius: Radii.md,
                        ),
                        // The marker needs ground for the same reason the
                        // hero's title does — a cover can be anything.
                        if (isPlaying) ...[
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Radii.md),
                              child: const DecoratedBox(
                                decoration: BoxDecoration(gradient: kArtScrim),
                              ),
                            ),
                          ),
                          const Positioned(
                            right: Space.xs,
                            bottom: Space.xs,
                            child: NowPlayingMarker(),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                song.title,
                style: text.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                song.artist,
                style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
