import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/recent_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/global_widgets/remote_image.dart';
import 'package:music_app/global_widgets/song_actions_sheet.dart';
import 'package:music_app/global_widgets/song_tile.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/player_page/player_page.dart';

/// The artwork edge of one strip card. Smaller than a grid cell on purpose:
/// this row is a shortcut back to something you already know, not a place to
/// discover anything, so it should read as subordinate to the picks below it.
const double _cardSide = 112;

/// Card width, and the strip's own height, derived from it.
///
/// Both are fixed rather than measured. A horizontal `ListView` has unbounded
/// width, so its children cannot size themselves from the viewport, and its
/// parent has to be told a height — an intrinsic one would mean laying every
/// card out twice on every frame of a scroll.
const double _cardWidth = _cardSide;
const double _stripHeight = _cardSide + 46;

/// "Jump back in" — the last few tracks played, newest first.
///
/// Renders **nothing at all** when there is no history: this is supplementary
/// to Quick picks rather than a destination, so an empty state here would be a
/// permanent apology on the home screen of a brand-new install. Quick picks
/// keeps its own empty state for the case where the screen really is empty.
class RecentStrip extends StatelessWidget {
  const RecentStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final recentController = Get.find<RecentController>();
    final songs = Get.find<SongController>();
    final text = Theme.of(context).textTheme;

    return Obx(() {
      final recent = recentController.recent;
      if (recent.isEmpty) return const SizedBox.shrink();

      final playingId = songs.currentPlaying.value.songid;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            // Matches the "More picks" heading below it exactly, so the two
            // sections sit on one spine.
            padding: const EdgeInsets.fromLTRB(
                Space.gutter, Space.xl, Space.gutter, Space.md),
            child: Text('Jump back in', style: text.headlineMedium),
          ),
          SizedBox(
            height: _stripHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // The gutter is padding on the list, not a margin on each card:
              // the first card lines up with the headings, and the last one can
              // still scroll clear of the screen edge.
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: Space.md),
              itemBuilder: (context, index) {
                final song = recent[index];
                return _RecentCard(
                  key: ValueKey('recent-${song.songid}'),
                  song: song,
                  isPlaying: playingId == song.songid,
                  // The strip itself becomes the queue, so next/previous walks
                  // your history — the same rule every other list in the app
                  // follows.
                  onTap: () => playSong(context, song, recent),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

/// One strip card: square artwork with the title beneath it.
///
/// Deliberately the same stack as Quick picks' grid cell — artwork, title,
/// [Radii.md], the [kArtScrim] under the now-playing marker — minus the artist
/// line. At this width an artist would truncate to two words and buy nothing;
/// you already know what this track is, which is the entire premise of the row.
class _RecentCard extends StatelessWidget {
  const _RecentCard({
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

    return SizedBox(
      width: _cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          // Same sheet as everywhere else. No room for a "more" button on a
          // card this size, so the long press is the only way in here.
          onLongPress: () => showSongActionsSheet(context, song),
          borderRadius: BorderRadius.circular(Radii.md),
          child: Semantics(
            button: true,
            // One node, not three. Inside the InkWell rather than outside it:
            // excludeSemantics drops every descendant, and from outside it
            // would take the InkWell's own tap action with it.
            excludeSemantics: true,
            label: 'Recently played: ${song.title} by ${song.artist}'
                '${isPlaying ? '. Now playing' : ''}. Play',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    RemoteImage(
                      url: '$baseUrl${song.coverurl}',
                      size: _cardSide,
                      radius: Radii.md,
                    ),
                    // The marker needs ground for the same reason type over
                    // artwork does — a cover can be anything.
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
                ),
                const SizedBox(height: Space.sm),
                Text(
                  song.title,
                  style: text.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
