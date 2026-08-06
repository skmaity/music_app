import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/artist_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/global_widgets/empty_state.dart';
import 'package:music_app/global_widgets/motion.dart';
import 'package:music_app/global_widgets/page_header.dart';
import 'package:music_app/global_widgets/remote_image.dart';
import 'package:music_app/global_widgets/skeleton.dart';
import 'package:music_app/global_widgets/song_tile.dart';
import 'package:music_app/model/artist_model.dart';
import 'package:music_app/player_page/player_page.dart';

/// Roughly how wide an artist tile wants to be.
const double _tileTarget = 130;

/// Cell width ÷ height. The circle is `Expanded`, so the name below claims its
/// height first and the circle takes the rest — a fixed ratio then holds at any
/// text scale.
const double _tileRatio = 0.78;

int _columnsFor(double width) => (width / _tileTarget).floor().clamp(2, 6);

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({super.key});

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  late final ArtistController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ArtistController>();
    controller.getArtists();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.selected.value == null
        ? _ArtistsList(controller: controller)
        : _ArtistDetail(controller: controller));
  }
}

/// Every artist, one shape, one grid.
///
/// The old screen gave the first five 130px circles and everyone else 110px
/// rounded squares — one entity type wearing two shapes, when a circle is
/// exactly how the whole industry encodes "this is a person". Worse, both bands
/// were **horizontally-scrolling `ListView`s**, so the "grid" under "More"
/// scrolled sideways with no affordance, no peek and no indicator, fighting the
/// vertical scroll the page invites (`design_audit.md` C11).
class _ArtistsList extends StatelessWidget {
  const _ArtistsList({required this.controller});

  final ArtistController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader('Artists'),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final columns = _columnsFor(box.maxWidth - Space.gutter * 2);
            return Obx(() => AnimatedSwitcher(
                  duration: Motion.normal,
                  child: _body(context, columns),
                ));
          }),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, int columns) {
    if (controller.isLoading.value) {
      return _ArtistsSkeleton(key: const ValueKey('loading'), columns: columns);
    }

    if (controller.hasError.value) {
      return ErrorState(
        key: const ValueKey('error'),
        message: 'The artist list could not be loaded.',
        onRetry: controller.getArtists,
      );
    }

    if (controller.artists.isEmpty) {
      return EmptyState(
        key: const ValueKey('empty'),
        icon: Icons.person_outline_rounded,
        headline: 'No artists yet',
        message: 'Artists appear here once they have songs to show.',
        actionLabel: 'Reload',
        onAction: controller.getArtists,
      );
    }

    return KeyedSubtree(
      key: const ValueKey('content'),
      child: RefreshIndicator(
        onRefresh: controller.getArtists,
        child: AnimationLimiter(
          child: GridView.builder(
            key: const PageStorageKey('artists'),
            padding: const EdgeInsets.fromLTRB(
                Space.gutter, Space.sm, Space.gutter, Space.xl),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: Space.md,
              mainAxisSpacing: Space.lg,
              childAspectRatio: _tileRatio,
            ),
            itemCount: controller.artists.length,
            itemBuilder: (context, index) {
              final artist = controller.artists[index];
              return staggeredEntrance(
                context,
                index,
                columnCount: columns,
                _ArtistTile(
                  key: ValueKey(artist.id),
                  artist: artist,
                  onTap: () => controller.open(artist),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ArtistTile extends StatelessWidget {
  const _ArtistTile({super.key, required this.artist, required this.onTap});

  final Artist artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        // One node. The tile used to announce the artist twice — once from the
        // image's own `semanticLabel` and once from the visible name below it.
        child: Semantics(
          button: true,
          excludeSemantics: true,
          label: artist.name,
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => RemoteImage(
                    url: '$baseUrl${artist.imageUrl}',
                    size: math.min(box.maxWidth, box.maxHeight),
                    radius: Radii.full,
                    fallbackIcon: Icons.person_rounded,
                  ),
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                artist.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One artist: who they are, then what they made.
class _ArtistDetail extends StatelessWidget {
  const _ArtistDetail({required this.controller});

  final ArtistController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final artist = controller.selected.value;
      if (artist == null) return const SizedBox.shrink();

      return Column(
        children: [
          PageHeader(artist.name, onBack: controller.back),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.normal,
              child: _body(context, artist),
            ),
          ),
        ],
      );
    });
  }

  Widget _body(BuildContext context, Artist artist) {
    if (controller.isLoadingSongs.value) {
      return const SongListSkeleton(key: ValueKey('loading'));
    }

    if (controller.hasSongsError.value) {
      return ErrorState(
        key: const ValueKey('error'),
        message: "${artist.name}'s songs could not be loaded.",
        onRetry: controller.retrySongs,
      );
    }

    final song = Get.find<SongController>();
    final playingId = song.currentPlaying.value.songid;

    return KeyedSubtree(
      key: const ValueKey('content'),
      child: AnimationLimiter(
        child: CustomScrollView(
          key: PageStorageKey('artist-${artist.id}'),
          slivers: [
            SliverToBoxAdapter(
              child: _ArtistHeader(
                artist: artist,
                songCount: controller.songs.length,
              ),
            ),
            if (controller.songs.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  headline: 'No songs yet',
                  message: 'Nothing has been published under this artist.',
                ),
              )
            else
              SliverList.builder(
                itemCount: controller.songs.length,
                itemBuilder: (context, index) {
                  final track = controller.songs[index];
                  return staggeredEntrance(
                    context,
                    index,
                    SongTile(
                      key: ValueKey(track.songid),
                      song: track,
                      isPlaying: playingId == track.songid,
                      onTap: () => playSong(context, track, controller.songs),
                    ),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
          ],
        ),
      ),
    );
  }
}

/// The artist's image, song count and bio.
///
/// Tapping through used to give a bare `PageHeader` with the name and nothing
/// else — no image, no bio, no count — while the API returned all three.
class _ArtistHeader extends StatelessWidget {
  const _ArtistHeader({required this.artist, required this.songCount});

  final Artist artist;
  final int songCount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bio = artist.bio;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Space.gutter, Space.sm, Space.gutter, Space.xl),
      child: Column(
        children: [
          RemoteImage(
            url: '$baseUrl${artist.imageUrl}',
            size: Controls.avatar,
            radius: Radii.full,
            fallbackIcon: Icons.person_rounded,
            semanticLabel: artist.name,
          ),
          const SizedBox(height: Space.md),
          Text(
            songCount == 1 ? '1 song' : '$songCount songs',
            style: text.labelLarge?.copyWith(color: AppColors.textSecondary),
          ),
          if (bio != null && bio.trim().isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Text(
              bio,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArtistsSkeleton extends StatelessWidget {
  const _ArtistsSkeleton({super.key, required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          Space.gutter, Space.sm, Space.gutter, Space.xl),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: Space.md,
        mainAxisSpacing: Space.lg,
        childAspectRatio: _tileRatio,
      ),
      itemCount: columns * 3,
      itemBuilder: (context, _) => Column(
        children: [
          const Expanded(child: Skeleton(radius: Radii.full)),
          const SizedBox(height: Space.sm),
          FractionallySizedBox(
            widthFactor: 0.7,
            child: const Skeleton(height: Space.md, radius: Radii.sm),
          ),
        ],
      ),
    );
  }
}
