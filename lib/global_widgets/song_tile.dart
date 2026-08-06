import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/global_widgets/motion.dart';
import 'package:music_app/global_widgets/remote_image.dart';
import 'package:music_app/global_widgets/song_actions_sheet.dart';
import 'package:music_app/model/song_model.dart';

/// The one song row. Quick picks, search, favourites and artist songs all use
/// this — the row must look and behave identically everywhere.
///
/// Callers pass `key: ValueKey(song.songid)` so rows keep their state as the
/// list reorders.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    this.showActions = true,
  });

  final MySongs song;

  /// Whether this row is the song currently loaded in the player.
  final bool isPlaying;

  final VoidCallback onTap;

  /// Whether the row offers "Play next" / "Add to queue".
  ///
  /// On by default because every plain song list in the app wants it. The
  /// queue sheet builds its own row rather than using this widget, so nothing
  /// currently turns it off — but a list of things *already* in the queue is
  /// the obvious case for doing so, and a caller should be able to say no.
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter, vertical: Space.xs),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: Space.md),
          minVerticalPadding: Space.sm,
          onTap: onTap,
          // The same sheet the "more" button opens. A long press is the
          // gesture people already try on a song row, and it costs one line —
          // but it is never the *only* way in, because a gesture with no
          // visible affordance is a feature most users never find.
          onLongPress:
              showActions ? () => showSongActionsSheet(context, song) : null,
          tileColor: AppColors.glass1,
          // No border. It was 0.5px of `grey.shade200 @ 40%` — invisible over
          // a moving gradient, reading as a smudge on the row's edge rather
          // than an edge, and the only reason the app had a second grey.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          leading: RemoteImage(
            url: '$baseUrl${song.coverurl}',
            size: Controls.thumbRow,
            semanticLabel: 'Cover art for ${song.title}',
          ),
          // Title and artist were the same full white at 16 and 12 — hierarchy
          // by size alone, with no tonal step between two different kinds of
          // information.
          title: Text(
            song.title,
            style: text.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song.artist,
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Both, when both apply — the marker says what this row *is*, the
          // button offers what you can do to it, and neither can stand in for
          // the other. `mainAxisSize: min` so the pair claims only the width it
          // needs and the title keeps the rest.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPlaying) const NowPlayingMarker(),
              if (showActions) _MoreButton(song: song),
            ],
          ),
        ),
      ),
    );
  }
}

/// The row's "more" affordance.
///
/// [AppColors.textTertiary] rather than full white: this is the quietest
/// control on the row and it repeats on every single one, so at full strength a
/// list would read as a column of dots with songs behind them.
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.song});

  final MySongs song;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showSongActionsSheet(context, song),
      tooltip: 'More options',
      // Icon-only, so it needs this — without it a screen reader announces an
      // unlabelled button.
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textTertiary),
      iconSize: Controls.iconInline,
      constraints: const BoxConstraints.tightFor(
        width: kMinInteractiveDimension,
        height: kMinInteractiveDimension,
      ),
    );
  }
}

/// Now-playing marker. One marker, one meaning — never a tinted row.
///
/// Public because Quick picks marks its hero and grid tiles with the same
/// thing; a second way of saying "this is the one playing" would say less.
class NowPlayingMarker extends StatelessWidget {
  const NowPlayingMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Now playing',
      child: noMotion(context)
          // The Lottie loops forever, so reduced motion gets a static mark.
          ? const Icon(Icons.graphic_eq_rounded,
              color: Colors.white, shadows: kGlow)
          : Lottie.asset(
              'assets/lottie_animations/musics_floating.json',
              width: 40,
              height: 40,
            ),
    );
  }
}
