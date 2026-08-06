import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/global_widgets/duration_format.dart';
import 'package:music_app/global_widgets/glass_panel.dart';
import 'package:music_app/global_widgets/select_pill.dart';
import 'package:music_app/global_widgets/sheet_handle.dart';
import 'package:music_app/player_page/queue_sheet.dart';

/// Opens the "more" sheet: everything that isn't reached for on every play —
/// speed, volume, the sleep timer, and the way into the up-next queue.
///
/// Grouped behind one affordance on purpose. The player already has one
/// primary action and a row of frequent, low-cost toggles (shuffle, 10-second
/// skip, repeat) that earned a permanent place on screen; these four are
/// configuration, reached for occasionally, and a screen whose whole thesis
/// is the artwork does not get to spend more of it on a volume slider.
void showPlayerOptionsSheet(BuildContext context, SongController controller) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Cap the height so there is always scrim left to tap. With
    // `isScrollControlled: true` and nothing else, this sheet grew to whatever
    // its content wanted — four sections, two of them wrapping to two rows of
    // pills — and on a shorter phone it covered nearly the whole player, which
    // is how it ended up feeling like a screen you could not back out of.
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * kSheetMaxHeightFraction,
    ),
    // Belt to the cap's braces: whatever the content does, the sheet stops
    // short of the status bar.
    useSafeArea: true,
    // The page's own context, not the one the sheet's builder hands back —
    // see [_UpNextRow] for why that distinction matters once this sheet
    // needs to hand off to another one.
    builder: (_) =>
        _PlayerOptionsSheet(pageContext: context, controller: controller),
  );
}

class _PlayerOptionsSheet extends StatelessWidget {
  const _PlayerOptionsSheet({
    required this.pageContext,
    required this.controller,
  });

  final BuildContext pageContext;
  final SongController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return GlassPanel(
      level: GlassLevel.high,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Above the scroll view, never inside it — see [SheetDragHandle]
            // for why that one line of layout is the difference between a
            // sheet you can drag away and one you cannot.
            const SheetDragHandle(),
            // Flexible, not Expanded: the sheet still shrink-wraps its content
            // when that content is short, and only fills the capped height
            // when it isn't.
            //
            // A landscape phone gives this sheet a fraction of the height it
            // gets in portrait. Four short sections still fit most of the
            // time, but this is what stops the rest overflowing instead of
            // clipping silently on the one viewport nobody tested against.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    Space.xl, Space.sm, Space.xl, Space.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Speed', style: text.bodyLarge),
                    const SizedBox(height: Space.sm),
                    _SpeedRow(controller: controller),
                    const SizedBox(height: Space.xl),
                    Text('Volume', style: text.bodyLarge),
                    const SizedBox(height: Space.sm),
                    _VolumeRow(controller: controller),
                    const SizedBox(height: Space.xl),
                    Text('Sleep timer', style: text.bodyLarge),
                    const SizedBox(height: Space.sm),
                    _SleepTimerSection(controller: controller),
                    const SizedBox(height: Space.xl),
                    _UpNextRow(
                        pageContext: pageContext, controller: controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedRow extends StatelessWidget {
  const _SpeedRow({required this.controller});

  final SongController controller;

  static String _label(double speed) {
    final trimmed = speed == speed.roundToDouble()
        ? speed.toInt().toString()
        : speed.toString();
    return '${trimmed}x';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.playbackSpeed.value;
      return Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final speed in SongController.availableSpeeds)
            SelectPill(
              label: _label(speed),
              selected: speed == active,
              semanticLabel: '${_label(speed)} speed',
              onTap: () => controller.setPlaybackSpeed(speed),
            ),
        ],
      );
    });
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({required this.controller});

  final SongController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final volume = controller.volume.value;
      final percent = (volume * 100).round();
      return Row(
        children: [
          const Icon(Icons.volume_down_rounded, color: AppColors.textSecondary),
          Expanded(
            child: Slider(
              value: volume,
              // Not awaited, same as the seek bar's own onChanged — a drag
              // fires this on every update and the slider has nothing to do
              // with the result besides move.
              onChanged: controller.setVolume,
              label: '$percent%',
              semanticFormatterCallback: (_) => '$percent percent',
            ),
          ),
          const Icon(Icons.volume_up_rounded, color: AppColors.textSecondary),
        ],
      );
    });
  }
}

class _SleepTimerSection extends StatelessWidget {
  const _SleepTimerSection({required this.controller});

  final SongController controller;

  static const List<int> _presetMinutes = [15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Obx(() {
      final remaining = controller.sleepTimeRemaining.value;
      final atEnd = controller.sleepAtTrackEnd.value;

      // Armed: show what it's waiting for and a way out, not the picker
      // that got it here.
      if (remaining != null || atEnd) {
        return Row(
          children: [
            const Icon(Icons.bedtime_rounded,
                color: AppColors.textPrimary, shadows: kGlow),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                remaining != null
                    ? 'Pausing in ${formatClock(remaining)}'
                    // No countdown for this one, by design — there is no
                    // clock to count down to, only "whenever this track
                    // ends".
                    : 'Pausing at the end of this track',
                style: text.bodyLarge,
              ),
            ),
            TextButton(
              onPressed: controller.cancelSleepTimer,
              child: const Text('Cancel'),
            ),
          ],
        );
      }

      return Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final minutes in _presetMinutes)
            SelectPill(
              label: '${minutes}m',
              selected: false,
              semanticLabel: 'Sleep in $minutes minutes',
              onTap: () =>
                  controller.startSleepTimer(Duration(minutes: minutes)),
            ),
          SelectPill(
            label: 'End of track',
            selected: false,
            onTap: controller.armSleepAtTrackEnd,
          ),
        ],
      );
    });
  }
}

/// The way into the queue from inside this sheet.
///
/// Takes [pageContext] — the player page's own, long-lived `BuildContext` —
/// rather than reading `context` from its own `build`. This sheet's context
/// stops being reliable the instant `Navigator.pop` starts tearing this
/// widget's subtree down, and opening the queue sheet is exactly the next
/// line after that pop. The page's context outlives both sheets.
class _UpNextRow extends StatelessWidget {
  const _UpNextRow({required this.pageContext, required this.controller});

  final BuildContext pageContext;
  final SongController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.sm),
        onTap: () {
          Navigator.of(pageContext).pop();
          showQueueSheet(pageContext, controller);
        },
        child: Semantics(
          button: true,
          label: 'Up next queue',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.md),
            child: Row(
              children: [
                const Icon(Icons.queue_music_rounded,
                    color: AppColors.textPrimary),
                const SizedBox(width: Space.md),
                Expanded(child: Text('Up next', style: text.bodyLarge)),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
