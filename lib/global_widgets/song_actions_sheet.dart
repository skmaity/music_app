import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/global_widgets/glass_panel.dart';
import 'package:music_app/global_widgets/remote_image.dart';
import 'package:music_app/global_widgets/sheet_handle.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/repositories/library_repository.dart';

/// What you can do with a song other than play it right now.
///
/// Opened from a [SongTile]'s "more" button and from a long press on any song
/// row or tile. Two actions today, both of which used to be impossible: the
/// queue could only ever be *replaced*, so hearing one more song meant throwing
/// away whatever was lined up behind it.
void showSongActionsSheet(BuildContext context, MySongs song) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Transparent so the GlassPanel inside supplies the surface — the same
    // arrangement the queue and options sheets use.
    backgroundColor: Colors.transparent,
    builder: (_) => _SongActionsSheet(song: song),
  );
}

class _SongActionsSheet extends StatelessWidget {
  const _SongActionsSheet({required this.song});

  final MySongs song;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return GlassPanel(
      level: GlassLevel.high,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      child: ConstrainedBox(
        // Two rows cannot reach this, and that is the point of a max rather
        // than a height: the sheet is as tall as it needs to be, and the cap is
        // there so a third action added later cannot quietly swallow the scrim
        // you tap to dismiss it.
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height * kSheetMaxHeightFraction,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sibling above the scrollable, never inside it — see
              // SheetDragHandle's doc for what happens otherwise.
              const SheetDragHandle(),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SheetHeader(song: song, text: text),
                      const Divider(
                        color: AppColors.glassEdge,
                        height: Space.lg,
                        indent: Space.xl,
                        endIndent: Space.xl,
                      ),
                      if (song.isYouTube)
                        const Padding(
                          padding: EdgeInsets.all(Space.md),
                          child: Text(
                            'Online queueing arrives with lazy playback. You can save this track now.',
                          ),
                        ),
                      if (!song.isLocal)
                        _ActionRow(
                          icon: Icons.playlist_add_check_rounded,
                          label: 'Add to playlist',
                          onTap: () => _addToPlaylist(context),
                        ),
                      if (song.isBackend)
                        _ActionRow(
                          icon: Icons.playlist_play_rounded,
                          label: 'Play next',
                          onTap: () => _run(
                            context,
                            () => Get.find<SongController>().playNext(song),
                            'Playing next',
                          ),
                        ),
                      if (song.isBackend)
                        _ActionRow(
                          icon: Icons.playlist_add_rounded,
                          label: 'Add to queue',
                          onTap: () => _run(
                            context,
                            () => Get.find<SongController>().addToQueue(song),
                            'Added to queue',
                          ),
                        ),
                      const SizedBox(height: Space.sm),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToPlaylist(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final repository = Get.find<LibraryRepository>();
    try {
      final playlists = await repository.listPlaylists();
      if (!context.mounted) return;
      if (playlists.isEmpty) {
        Navigator.of(context).pop();
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Create a playlist in Library first.'),
            ),
          );
        return;
      }

      final selected = await showDialog<LibraryPlaylist>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Add to playlist'),
          children: [
            for (final playlist in playlists)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, playlist),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.sm),
                  child: Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      );
      if (selected == null || !context.mounted) return;

      await repository.addPlaylistEntry(
        entryId:
            'entry-${DateTime.now().microsecondsSinceEpoch}-${song.identity.hashCode}',
        playlistId: selected.id,
        track: TrackRef.fromSong(song),
        position: selected.entryCount,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('Added to ${selected.name}')),
        );
    } catch (_) {
      if (!context.mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('That track could not be added.')),
        );
    }
  }

  /// Runs an action, closes the sheet, and says so.
  ///
  /// Both actions change something the user cannot see from here — the queue is
  /// behind the player — so without the confirmation the sheet would just close
  /// and the tap would read as having done nothing.
  void _run(BuildContext context, VoidCallback action, String confirmation) {
    // Resolved *before* the pop. Afterwards this context is defunct, and
    // looking a messenger up through it is the standard way to turn a
    // confirmation into a crash.
    final messenger = ScaffoldMessenger.of(context);

    action();
    Navigator.of(context).pop();
    HapticFeedback.selectionClick();

    messenger
      // Queueing three songs in a row must not stack three identical bars.
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          // White on black, the same shape Settings' "Listener id copied" uses
          // — the app's feedback is made of white, and [AppColors.danger] is
          // reserved for failures. This is not one.
          content: Text(confirmation,
              style: const TextStyle(color: AppColors.scrim)),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(Space.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

/// Which song this sheet is about. A menu with no subject is a menu you have to
/// remember the context of.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.song, required this.text});

  final MySongs song;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.sm, Space.xl, 0),
      child: Row(
        children: [
          RemoteImage(
            url: song.artworkUri(baseUrl).toString(),
            size: Controls.thumb,
            radius: Radii.sm,
            semanticLabel: 'Cover art for ${song.title}',
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.title,
                  style: text.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One action. A full-width row rather than a list of buttons — the whole width
/// is the target, which is what makes this comfortable one-handed.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          excludeSemantics: true,
          label: label,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.xl, vertical: Space.md),
            child: SizedBox(
              // Clears the 48dp minimum on its own rather than relying on the
              // text's line box to carry it there.
              height: kMinInteractiveDimension,
              child: Row(
                children: [
                  Icon(icon, size: Controls.iconInline),
                  const SizedBox(width: Space.lg),
                  Text(label, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
