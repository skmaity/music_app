import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/global_widgets/empty_state.dart';
import 'package:music_app/global_widgets/glass_panel.dart';
import 'package:music_app/global_widgets/remote_image.dart';
import 'package:music_app/global_widgets/sheet_handle.dart';
import 'package:music_app/global_widgets/song_tile.dart';
import 'package:music_app/model/song_model.dart';

/// Opens the up-next sheet: [SongController.currentPlayingList] with the
/// current track marked, tap to jump, drag to reorder, swipe to remove.
void showQueueSheet(BuildContext context, SongController controller) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QueueSheet(controller: controller),
  );
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet({required this.controller});

  final SongController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return GlassPanel(
      level: GlassLevel.high,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      child: SizedBox(
        // A fraction of the viewport, not the content's own height — the queue
        // can run to dozens of tracks, and a sheet that grows with it would
        // eventually cover the status bar. Same [kSheetMaxHeightFraction] the
        // options sheet caps itself at, so neither sheet can swallow the
        // scrim you tap to dismiss it.
        height: MediaQuery.sizeOf(context).height * kSheetMaxHeightFraction,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Already a sibling above the list rather than inside it, so a
              // drag here has always reached the sheet — it just had no tap
              // and nothing for a screen reader. Shared with the options
              // sheet now, so both close the same way.
              const SheetDragHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Space.xl, Space.md, Space.xl, Space.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Up next', style: text.bodyLarge),
                ),
              ),
              Expanded(
                child: Obx(() {
                  final queue = controller.currentPlayingList;
                  if (queue.isEmpty) {
                    // Defensive, not expected: this sheet only opens from a
                    // player that already has something loaded. Still, an
                    // empty list rendering nothing reads as a broken sheet.
                    return const EmptyState(
                      headline: 'Queue is empty',
                      message: 'Play a song to start one.',
                    );
                  }

                  final currentIndex = controller.currentIndex.value;

                  return ReorderableListView.builder(
                    // Default handles make the whole row draggable on a long
                    // press, which fights the swipe-to-remove gesture below.
                    // A dedicated handle keeps "drag" and "swipe" from
                    // competing for the same touch.
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.only(bottom: Space.lg),
                    itemCount: queue.length,
                    onReorder: controller.reorderQueue,
                    itemBuilder: (context, index) {
                      final song = queue[index];
                      return _QueueRow(
                        // Index folded into the key: the same song can sit in
                        // the queue twice, and every child here needs a key
                        // unique among its siblings.
                        key: ValueKey('queue-${song.songid}-$index'),
                        song: song,
                        index: index,
                        isCurrent: index == currentIndex,
                        onTap: () => controller.jumpToQueueIndex(index),
                        onRemove: () => controller.removeFromQueue(index),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One queue row — [SongTile]'s visual language (glass1 fill, [Radii.sm],
/// [Controls.thumbRow] artwork, the same title/artist tone split) plus what a
/// queue needs on top of a plain song list: a drag handle and a swipe to
/// remove. Not [SongTile] itself, which has neither.
class _QueueRow extends StatelessWidget {
  const _QueueRow({
    super.key,
    required this.song,
    required this.index,
    required this.isCurrent,
    required this.onTap,
    required this.onRemove,
  });

  final MySongs song;
  final int index;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Dismissible(
      // Reuses the widget's own key rather than inventing a second one —
      // Dismissible needs a key unique among its siblings, and this already
      // is one.
      key: key!,
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: Space.gutter, vertical: Space.xs),
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.black),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.gutter, vertical: Space.xs),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: onTap,
            tileColor: AppColors.glass1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: Space.md),
            minVerticalPadding: Space.sm,
            leading: RemoteImage(
              url: '$baseUrl${song.coverurl}',
              size: Controls.thumbRow,
              semanticLabel: 'Cover art for ${song.title}',
            ),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The one "this is playing" mark, same as every other song
                // list in the app — never a tinted row, which is exactly the
                // rule [SongTile] exists to enforce.
                if (isCurrent) const NowPlayingMarker(),
                ReorderableDragStartListener(
                  index: index,
                  child: const Tooltip(
                    message: 'Drag to reorder',
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.drag_handle_rounded,
                          color: AppColors.textTertiary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
