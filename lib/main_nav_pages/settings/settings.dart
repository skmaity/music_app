import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/settings_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/controller/userid_controller.dart';
import 'package:music_app/global_widgets/glass_panel.dart';
import 'package:music_app/global_widgets/page_header.dart';
import 'package:music_app/global_widgets/select_pill.dart';

/// Five sections, all of them backed by [SettingsController] — every control
/// here changes something the user can see or hear, which is the one thing
/// this screen was not allowed to fake.
///
/// Stateful only to refresh the image-cache size on entry: the controller
/// measures it once at construction, which is app launch, and by the time
/// anyone opens Settings a session's worth of covers have been downloaded
/// since.
class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final SettingsController settings;

  @override
  void initState() {
    super.initState();
    settings = Get.find<SettingsController>();
    settings.refreshImageCacheSize();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader('Settings'),
        Expanded(
          // The values below start at their compiled-in defaults and are
          // replaced a few milliseconds later by whatever is on disk, so the
          // screen is briefly showing numbers it cannot yet write to —
          // `SettingsController._prefs` is `late`, and a tap landing in that
          // window would throw. Absorbing pointers rather than swapping in a
          // skeleton, because the window is one or two frames: a placeholder
          // nobody can read is worse than a control nobody can hit.
          child: Obx(
            () => AbsorbPointer(
              absorbing: !settings.isReady.value,
              child: _sections(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sections(BuildContext context) {
    return ListView(
      // Returning to the tab used to put you back at the top; the page is
      // destroyed on every switch, so the offset has to live in the bucket.
      key: const PageStorageKey('settings'),
      padding: const EdgeInsets.fromLTRB(
          Space.gutter, Space.sm, Space.gutter, Space.xxl),
      children: [
        _Section(
          title: 'Appearance',
          children: [
            Obx(
              () => _SwitchRow(
                icon: Icons.palette_rounded,
                title: 'Album-art gradient',
                subtitle: 'Colour the whole app from the current cover.',
                value: settings.gradientEnabled.value,
                onChanged: settings.setGradientEnabled,
              ),
            ),
            const _RowDivider(),
            _GradientIntensityRow(settings: settings),
            const _RowDivider(),
            Obx(
              () => _SwitchRow(
                icon: Icons.slow_motion_video_rounded,
                title: 'Reduce motion',
                subtitle: 'Hold the gradient still and drop list animations.',
                value: settings.reducedMotion.value,
                onChanged: settings.setReducedMotion,
              ),
            ),
          ],
        ),
        _Section(
          title: 'Playback',
          children: [
            Obx(
              () => _PickerRow(
                icon: Icons.speed_rounded,
                title: 'Default speed',
                subtitle: 'Applied at the start of every track.',
                options: [
                  for (final speed in SongController.availableSpeeds)
                    SelectPill(
                      label: _speedLabel(speed),
                      selected: speed == settings.defaultPlaybackSpeed.value,
                      semanticLabel: '${_speedLabel(speed)} default speed',
                      onTap: () => settings.setDefaultPlaybackSpeed(speed),
                    ),
                ],
              ),
            ),
            const _RowDivider(),
            Obx(
              () => _PickerRow(
                icon: Icons.forward_10_rounded,
                title: 'Skip interval',
                subtitle: 'How far the skip buttons jump.',
                options: [
                  for (final seconds
                      in SettingsController.availableSkipIntervals)
                    SelectPill(
                      label: '${seconds}s',
                      selected: seconds == settings.skipIntervalSeconds.value,
                      semanticLabel: 'Skip $seconds seconds',
                      onTap: () => settings.setSkipIntervalSeconds(seconds),
                    ),
                ],
              ),
            ),
            const _RowDivider(),
            Obx(
              () => _SwitchRow(
                icon: Icons.playlist_play_rounded,
                title: 'Autoplay',
                subtitle: 'Move on to the next track when one finishes.',
                value: settings.autoplayEnabled.value,
                onChanged: settings.setAutoplayEnabled,
              ),
            ),
            const _RowDivider(),
            Obx(
              () => _SwitchRow(
                icon: Icons.history_rounded,
                title: 'Remember position',
                subtitle: 'Reopen a song where you left it.',
                value: settings.rememberPositionEnabled.value,
                onChanged: settings.setRememberPositionEnabled,
              ),
            ),
          ],
        ),
        _Section(
          title: 'Data and storage',
          children: [_ImageCacheRow(settings: settings)],
        ),
        _Section(
          title: 'Identity',
          children: [_IdentityBlock(settings: settings)],
        ),
        _Section(
          title: 'About',
          children: [
            const _InfoRow(
              icon: Icons.info_outline_rounded,
              title: kAppName,
              subtitle: 'Version $kAppVersion',
            ),
            const _RowDivider(),
            _ActionRow(
              icon: Icons.description_outlined,
              title: 'Open-source licences',
              onTap: () => showLicensePage(
                context: context,
                applicationName: kAppName,
                applicationVersion: kAppVersion,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _speedLabel(double speed) {
  final trimmed =
      speed == speed.roundToDouble() ? speed.toInt().toString() : '$speed';
  return '${trimmed}x';
}

// ---------------------------------------------------------------- structure

/// A titled group of rows: a label over a level-1 glass card.
///
/// [AppText.bodyLarge], not [AppText.headline] — design.md reserves the 30px
/// heading for a single in-page section like Quick picks' "More", and five of
/// them stacked down a settings list would outshout the page title. It has to
/// be merged in by hand because the theme spends its `bodyLarge` slot on
/// [AppText.body]; left at the slot's own value these labels would render at
/// exactly the size and weight of the row titles underneath them, which is no
/// hierarchy at all.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final label =
        Theme.of(context).textTheme.bodyLarge?.merge(AppText.bodyLarge);

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
            child: Text(title, style: label),
          ),
          GlassPanel(
            level: GlassLevel.low,
            borderRadius: BorderRadius.circular(Radii.lg),
            // The panel paints its own fill, so the rows need a Material of
            // their own above it or every ripple in this list would splash
            // *behind* the card and the taps would look like nothing
            // happened.
            child: Material(
              color: Colors.transparent,
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }
}

/// A hairline between rows, inset to the card's own padding so it separates
/// the rows without running edge to edge and cutting the card in half.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: Space.md,
      endIndent: Space.md,
      color: AppColors.glassEdge,
    );
  }
}

// --------------------------------------------------------------------- rows

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      // The whole row is the target, not just the switch — SwitchListTile
      // clears 48dp on its own and announces the toggled state for free.
      contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md, vertical: Space.xs),
      secondary: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: text.bodyMedium),
      subtitle: Text(
        subtitle,
        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// A row whose control is a set of [SelectPill]s — default speed, skip
/// interval. The pills wrap rather than scroll, so nothing is hidden off the
/// edge at large text sizes.
class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.options,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> options;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.textSecondary),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.bodyMedium),
                    Text(
                      subtitle,
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Wrap(spacing: Space.sm, runSpacing: Space.sm, children: options),
        ],
      ),
    );
  }
}

/// The veil slider, shown the way round a listener thinks about it.
///
/// The stored value is the veil's opacity, where *more* means a dimmer cover;
/// the control is labelled "gradient intensity", where more means a brighter
/// one. Inverting here rather than storing it inverted keeps
/// `BackgroundController` reading one number that means exactly what it says.
///
/// The [Obx] is inside this build rather than around the widget at the call
/// site: GetX only subscribes to observables read during the builder's own
/// call, so an `Obx(() => _GradientIntensityRow(...))` that reads nothing
/// itself subscribes to nothing and throws.
class _GradientIntensityRow extends StatelessWidget {
  const _GradientIntensityRow({required this.settings});

  final SettingsController settings;

  static const double _span =
      SettingsController.maxVeilOpacity - SettingsController.minVeilOpacity;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Tabular figures so the percentage does not twitch as it counts through
    // the drag. Lifted off [AppText.numeric] rather than merged from it: a
    // merge would bring its 16px size along with it.
    final readout =
        text.bodySmall?.copyWith(fontFeatures: AppText.numeric.fontFeatures);

    return Obx(() {
      final intensity =
          (SettingsController.maxVeilOpacity - settings.veilOpacity.value) /
              _span;
      final percent = (intensity * 100).round();

      // With the gradient off the background is a fixed dark pair, and there
      // is no palette left for this to turn up. Disabled rather than hidden —
      // a control that vanishes is a control the user has to rediscover.
      final enabled = settings.gradientEnabled.value;
      final labelColor =
          enabled ? AppColors.textPrimary : AppColors.textTertiary;
      final quietColor =
          enabled ? AppColors.textSecondary : AppColors.textTertiary;

      return Padding(
        padding:
            const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.opacity_rounded, color: quietColor),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Text(
                    'Gradient intensity',
                    style: text.bodyMedium?.copyWith(color: labelColor),
                  ),
                ),
                Text('$percent%', style: readout?.copyWith(color: quietColor)),
              ],
            ),
            Slider(
              value: intensity.clamp(0.0, 1.0),
              label: '$percent%',
              // Screen readers read "84%" as a fraction; this is the number in
              // words, which is what the rest of the app's sliders do too.
              semanticFormatterCallback: (_) => '$percent percent',
              onChanged: enabled
                  ? (value) => settings.setVeilOpacity(
                      SettingsController.maxVeilOpacity - value * _span)
                  : null,
            ),
          ],
        ),
      );
    });
  }
}

class _ImageCacheRow extends StatelessWidget {
  const _ImageCacheRow({required this.settings});

  final SettingsController settings;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB'];
    var value = bytes / 1024;
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(1)} ${units[unit]}';
  }

  /// [Obx] inside the build, not around this widget at the call site — see
  /// [_GradientIntensityRow] for why that distinction is load-bearing.
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Obx(
      () => ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
        leading: const Icon(Icons.photo_library_outlined,
            color: AppColors.textSecondary),
        title: Text('Cached artwork', style: text.bodyMedium),
        subtitle: Text(
          _formatBytes(settings.imageCacheBytes.value),
          style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        trailing: settings.isClearingCache.value
            // Same footprint as the button it replaces, so the row does not
            // twitch while the cache empties.
            ? const SizedBox(
                width: Controls.secondary,
                height: Controls.secondary,
                child: Center(
                  child: SizedBox(
                    width: Space.xl,
                    height: Space.xl,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : IconButton(
                tooltip: 'Clear cached artwork',
                constraints: const BoxConstraints.tightFor(
                  width: Controls.secondary,
                  height: Controls.secondary,
                ),
                onPressed: settings.clearImageCache,
                icon: const Icon(Icons.delete_sweep_rounded),
              ),
      ),
    );
  }
}

/// The anonymous id, and the one destructive action in the app.
///
/// It gets its own explanation because nothing else in the app tells the user
/// this exists: there is no login, so this uuid *is* the account, and the
/// consequence of losing it is invisible until the favourites are already
/// gone.
class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({required this.settings});

  final SettingsController settings;

  void _copy(BuildContext context, String id) {
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          // White on black, the same shape the player's error bar uses — the
          // app's feedback is made of white, and this one is not a failure.
          content: const Text('Listener id copied',
              style: TextStyle(color: AppColors.scrim)),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(Space.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
      );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset listener id?'),
        content: const Text(
          'Your favourites are saved against this id, and there is no account '
          'to sign back into. A new id starts empty and the old one cannot be '
          'recovered — every song you have hearted becomes unreachable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await settings.resetIdentity();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final userId = Get.find<UseridController>().userId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Space.md, Space.md, Space.md, Space.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.fingerprint_rounded,
                  color: AppColors.textSecondary),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Listener id', style: text.bodyMedium),
                    const SizedBox(height: Space.xs),
                    Obx(
                      () => SelectableText(
                        userId.value.isEmpty ? 'Not created yet' : userId.value,
                        // Metadata, so caption size is allowed here. Tabular
                        // figures are lifted off [AppText.numeric] rather than
                        // merged from it — a full merge would bring its 16px
                        // along and this is not body copy.
                        style: text.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontFeatures: AppText.numeric.fontFeatures,
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      'This app has no login. Favourites are stored against '
                      'this id, so keep a copy of it.',
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Obx(
                () => IconButton(
                  tooltip: 'Copy listener id',
                  constraints: const BoxConstraints.tightFor(
                    width: Controls.secondary,
                    height: Controls.secondary,
                  ),
                  onPressed: userId.value.isEmpty
                      ? null
                      : () => _copy(context, userId.value),
                  icon: const Icon(Icons.content_copy_rounded),
                ),
              ),
            ],
          ),
        ),
        const _RowDivider(),
        _ActionRow(
          icon: Icons.restart_alt_rounded,
          title: 'Reset listener id',
          // The app's second fixed colour, and the only place outside
          // ErrorState that earns it: this is the one action here that
          // destroys something.
          color: AppColors.danger,
          onTap: () => _confirmReset(context),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: text.bodyMedium),
      subtitle: Text(
        subtitle,
        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textSecondary),
    );
  }
}
