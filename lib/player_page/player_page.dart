import 'dart:math' as math;

// `RepeatMode` also exists in Flutter's own widgets library (for
// `RepeatingAnimationBuilder`), so the app's own enum of the same name has to
// be imported without it.
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/component/animated_gradient_widget.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/global_widgets/duration_format.dart';
import 'package:music_app/global_widgets/glass_panel.dart';
import 'package:music_app/global_widgets/remote_image.dart';
import 'package:music_app/global_widgets/scrolling_text.dart';
import 'package:music_app/model/repeat_mode.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/player_page/player_options_sheet.dart';

/// The shared element between the now-playing bar and this page.
///
/// The app's whole thesis is that the album art *is* the experience, and the
/// most valuable transition in a music app is that art growing from the bar
/// into the player. This tag used to be spent flying a music-note glyph.
const String kNowPlayingHeroTag = 'now-playing-art';

/// Whether a [PlayerPage] route is on the stack.
///
/// Set synchronously by [openPlayer] rather than from [PlayerPage]'s
/// `initState`, which does not run until the route builds a frame later — two
/// taps inside that window would both find it `false`. Cleared when the pop
/// transition finishes, so a tap during the closing animation does not race it
/// either.
bool _playerIsOpen = false;

/// Play [song] and open the player. The list you tapped it from becomes the
/// queue, so next/previous walks it.
///
/// Every song row in the app goes through here; each screen used to inline the
/// same four lines.
void playSong(BuildContext context, MySongs song, RxList<MySongs> queue) {
  final controller = Get.find<SongController>();
  // `playQueue` copies rather than adopting `queue` itself. This used to be
  // `controller.currentPlayingList = queue`, which aliased whichever screen's
  // own RxList produced it — Quick picks, Favourites, an artist's songs,
  // Search results — so dragging a reorder or swiping a remove in the
  // player's up-next sheet silently mutated that source screen's list too.
  // Found in the queue rather than taken from the row's build index: the
  // favourites list can lose an entry between a row being built and your tap
  // landing on it, and next/previous would then walk on from whatever song had
  // slid into that slot.
  //
  // One call, not two. `setQueue` + `startPlaying` were separate while this
  // controller loaded tracks one at a time; loading the queue into the player
  // *is* starting playback now.
  controller.playQueue(queue, queue.indexOf(song));
  openPlayer(context);
}

/// Open the player over whatever is on screen, without changing what plays.
///
/// The push is guarded because every screen pushed its own route per tap, so
/// tapping three songs in a row stacked three identical players — and unwinding
/// that stack with quick back-swipes is what tripped the navigator's
/// `_userGesturesInProgress` assertion: Flutter replays a predictive-back
/// commit onto a route that is already mid-pop, and the second
/// `didStopUserGesture` has nothing left to decrement. One player, one route,
/// no stack to unwind.
void openPlayer(BuildContext context) {
  if (_playerIsOpen) return;
  _playerIsOpen = true;
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const PlayerPage()))
      .whenComplete(() => _playerIsOpen = false);
}

/// The full-screen player.
///
/// Nothing here is a fixed pixel height. The card takes the space the screen
/// gives it and the artwork takes what the card has left, so the layout holds
/// on a 320pt phone and at 200% text scale alike — the previous `height: 470`
/// overflowed at the first notch of Dynamic Type, and the artwork rendered
/// 285x300 (cropped, non-square) on anything narrower than 390pt.
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  late final SongController controller;

  final BackgroundController _background = Get.find<BackgroundController>();

  late final AnimationController _heart;
  late final Animation<double> _heartScale;
  late final Animation<Color?> _heartColour;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SongController>();
    _background.updatePaletteGenerator();

    _heart = AnimationController(
      vsync: this,
      duration: Motion.normal,
      reverseDuration: Motion.exitOf(Motion.normal),
    );
    final curve = CurvedAnimation(parent: _heart, curve: Motion.enter);

    // Scale, not size. Animating the icon's `size` animated a layout dimension:
    // it shifted the row on every tap and the 60x60 box clipped the burst at
    // its peak. A transform paints outside its bounds and moves nothing.
    _heartScale = Tween<double>(begin: 1.0, end: 1.4).animate(curve);
    _heartColour = ColorTween(
      begin: AppColors.textPrimary,
      end: AppColors.accent,
    ).animate(curve);
  }

  @override
  void dispose() {
    _heart.dispose();
    super.dispose();
  }

  /// Failure only. Success needs no toast — the heart fills and pops, which is
  /// the whole point of having built that animation.
  void _showFavouriteError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      // Tapping the heart repeatedly must not stack a queue of identical bars.
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          // Dark on [AppColors.danger]: white over it lands around 2.4:1.
          content:
              Text(message, style: const TextStyle(color: AppColors.scrim)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(Space.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Close player',
          iconSize: Controls.iconSecondary,
          onPressed: () => Navigator.pop(context),
          // Was `Icons.music_note_outlined` inside a Hero — a glyph with no
          // learned meaning as "back", and the *outlined* variant of the icon
          // this app uses to mark active playback. A full-screen player
          // dismisses downward everywhere else, so it says so.
          icon: const Icon(Icons.keyboard_arrow_down_rounded, shadows: kGlow),
        ),
        // Everything that isn't reached for on every play — speed, volume,
        // the sleep timer, the way into the queue — lives behind this one
        // icon. Nine controls on a screen whose whole thesis is the artwork
        // does not stay a player; this is what keeps eight of them one tap
        // away instead of permanently on screen.
        actions: [
          Obx(() {
            final remaining = controller.sleepTimeRemaining.value;
            final atEnd = controller.sleepAtTrackEnd.value;
            final armed = remaining != null || atEnd;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The countdown lives out here, not only inside the sheet —
                // a timer nobody can see while it's running might as well
                // not show one at all.
                if (remaining != null)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.xs),
                    child: Text(
                      formatClock(remaining),
                      style: AppText.numeric.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                else if (atEnd)
                  const Padding(
                    padding: EdgeInsets.only(right: Space.xs),
                    child: Icon(Icons.bedtime_rounded,
                        size: 14, color: AppColors.textSecondary),
                  ),
                IconButton(
                  tooltip: armed
                      ? 'Playback options — sleep timer armed'
                      : 'Playback options',
                  iconSize: Controls.iconSecondary,
                  onPressed: () => showPlayerOptionsSheet(context, controller),
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    shadows: armed ? kGlow : null,
                    color:
                        armed ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          Obx(
            () => AnimatedGradient(
              primaryColors: List<Color>.from(_background.primaryColorsList),
              secondaryColors:
                  List<Color>.from(_background.secondaryColorsList),
            ),
          ),

          // The contrast floor. This rested at 0.0, which put white text
          // straight onto a full-bleed vibrant gradient.
          //
          // Reads `restingVeilOpacity` for the same reason the dashboard does:
          // it is what Settings' gradient-intensity slider moves, and it never
          // returns less than `kVeilRest`.
          Obx(
            () => AnimatedContainer(
              duration:
                  _background.isVisible.value ? Motion.veilIn : Motion.veilOut,
              color: AppColors.scrim.withValues(
                alpha: _background.isVisible.value
                    ? 1.0
                    : _background.restingVeilOpacity,
              ),
              child: const SizedBox.expand(),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                kToolbarHeight,
                Space.xl,
                Space.xl,
              ),
              // Same signal the card already uses one level down: wider than
              // tall means a landscape phone or a split screen, where height
              // is the scarce axis. Two control rows below the card fit
              // portrait's spare height comfortably; on a short landscape
              // viewport they were pushing the card below the room its own
              // LayoutBuilder branch needs for the (now single-line) track
              // and seek bar. Folding shuffle/skip/repeat into one row with
              // the transport — rather than a second row beneath it — gives
              // the card back that height, spending width instead, which is
              // the axis a landscape screen has to spare.
              child: LayoutBuilder(
                builder: (context, box) {
                  final isWide = box.maxWidth > box.maxHeight;
                  return Column(
                    children: [
                      Expanded(child: _card(context)),
                      const SizedBox(height: Space.xl),
                      if (isWide)
                        _CompactControls(controller: controller)
                      else ...[
                        _Transport(controller: controller),
                        // Tighter than the gap above the transport —
                        // proximity is what tells the eye this row is a step
                        // down from the one above it rather than a second row
                        // of equal weight.
                        const SizedBox(height: Space.md),
                        _SecondaryControls(controller: controller),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Glass card: artwork, then the track, then the seek bar.
  ///
  /// Radii are concentric — outer [Radii.xl] minus [Space.lg] of padding is
  /// exactly [Radii.md] on the artwork inside it. The cover previously sat at
  /// radius 4 inside a radius 10 card with 20 of padding, an inner corner
  /// tighter than its outer one.
  Widget _card(BuildContext context) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(Radii.xl),
      padding: const EdgeInsets.all(Space.lg),
      child: LayoutBuilder(
        builder: (context, box) {
          // Landscape, split screen, and anything else that leaves the card
          // wider than it is tall: the artwork moves beside the controls
          // instead of above them. Stacked, this card needs roughly 150pt
          // for the type alone, which a landscape phone does not have.
          if (box.maxWidth > box.maxHeight) {
            return Row(
              children: [
                _artwork(),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _track(context),
                      const SizedBox(height: Space.sm),
                      _seek(context),
                    ],
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The artwork absorbs whatever height the type does not use,
              // rather than the card growing to fit a fixed cover.
              Expanded(child: Center(child: _artwork())),
              const SizedBox(height: Space.lg),
              _track(context),
              const SizedBox(height: Space.sm),
              _seek(context),
            ],
          );
        },
      ),
    );
  }

  /// Square by construction: the side is the smaller of the two dimensions the
  /// parent offers, so it is right in a bounded box (stacked) and in an
  /// unbounded-width one (beside the controls) alike.
  Widget _artwork() {
    return LayoutBuilder(
      builder: (context, box) {
        final side = math.min(box.maxWidth, box.maxHeight);
        return Obx(() {
          final song = controller.currentPlaying.value;
          return SizedBox.square(
            dimension: side,
            child: Hero(
              tag: kNowPlayingHeroTag,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.md),
                  boxShadow: kArtShadow,
                ),
                child: RemoteImage(
                  url: baseUrl + song.coverurl,
                  size: side,
                  radius: Radii.md,
                  semanticLabel: 'Cover art for ${song.title}',
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// Title, artist, heart. Two ranked lines — these were welded into one 18px
  /// string, `"$title - $artist"`, sharing a single ellipsis, so a long title
  /// ate the artist first.
  Widget _track(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Obx(() {
            final song = controller.currentPlaying.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Single line, scrolling rather than wrapping. The old
                // two-line wrap-then-ellipsis still truncated the longest
                // titles mid-word; scrolling shows the whole string instead,
                // and — same as the Text it replaced — just sits still for
                // anything that already fits.
                ScrollingText(song.title, style: text.titleLarge),
                const SizedBox(height: Space.xs),
                ScrollingText(
                  song.artist,
                  style:
                      text.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            );
          }),
        ),
        const SizedBox(width: Space.sm),
        _favourite(),
      ],
    );
  }

  /// Seek bar and timestamps.
  ///
  /// Its own [Obx]: the position ticks several times a second, and the old
  /// single card-wide observer rebuilt the artwork and the blur along with it.
  Widget _seek(BuildContext context) {
    final timestamp = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.merge(AppText.numeric)
        .copyWith(color: AppColors.textSecondary);

    return Obx(() {
      final position = controller.currentPosition.value;
      final total = controller.totalDuration.value;
      final seconds = total.inSeconds.toDouble();
      final remainingRaw = total - position;
      final remaining =
          remainingRaw < Duration.zero ? Duration.zero : remainingRaw;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            min: 0.0,
            max: seconds,
            value: position.inSeconds.toDouble().clamp(0.0, seconds),
            // How much has downloaded. The bar showed played-vs-nothing, so a
            // stall looked identical to a fully buffered track.
            secondaryTrackValue: controller.bufferedPosition.value.inSeconds
                .toDouble()
                .clamp(0.0, seconds),
            // The scrub bubble — without it you drag blind, because your own
            // thumb is over the timestamp.
            label: formatClock(position),
            // A tap on the old 1.5px track was a mis-tap waiting to happen;
            // the theme's 4px track keeps the rule anyway, because a stray tap
            // mid-song is expensive to undo.
            allowedInteraction: SliderInteraction.slideOnly,
            semanticFormatterCallback: (value) =>
                '${formatSpoken(Duration(seconds: value.toInt()))} '
                'of ${formatSpoken(total)}',
            onChanged: (value) =>
                controller.seekTo(Duration(seconds: value.toInt())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Elapsed ${formatSpoken(position)}',
                excludeSemantics: true,
                child: Text(formatClock(position), style: timestamp),
              ),
              // Remaining, not total — once you're any distance into a
              // track, "3:42 left" tells you something a fixed length no
              // longer does.
              Semantics(
                label: '${formatSpoken(remaining)} remaining',
                excludeSemantics: true,
                child: Text('-${formatClock(remaining)}', style: timestamp),
              ),
            ],
          ),
        ],
      );
    });
  }

  /// The favourite heart. Still the only [AppColors.accent] in the app.
  ///
  /// [AnimatedBuilder] is the fix for a real bug: the icon read
  /// `colourAnimation.value` from inside an `Obx`, which listens to GetX
  /// observables and not to an [AnimationController] — so the pop never
  /// actually played, it snapped.
  Widget _favourite() {
    // The Obx has to read the observable synchronously in its own build —
    // reading it inside the AnimatedBuilder's builder instead would leave the
    // heart repainting only while the pop plays, so un-favouriting (which
    // deliberately does not animate) would never redraw the icon.
    return Obx(() {
      final isFavourite = controller.isFavourite.value;

      return AnimatedBuilder(
        animation: _heart,
        builder: (context, _) {
          final colour = _heartColour.value ?? AppColors.textPrimary;
          return IconButton(
            tooltip:
                isFavourite ? 'Remove from favourites' : 'Add to favourites',
            iconSize: Controls.iconInline,
            constraints: const BoxConstraints.tightFor(
              width: Controls.secondary,
              height: Controls.secondary,
            ),
            onPressed: () async {
              final error = await controller.toggleFavourite();
              // Say so. A refused write used to be indistinguishable from a tap
              // that never registered — which is exactly how favourites stayed
              // broken without anyone being told why.
              if (error != null) {
                _showFavouriteError(error);
                return;
              }
              // Pop the heart on add *and* on remove. The animation used to
              // fire on add and stay silent on remove, so half the interaction
              // had no feedback at all.
              HapticFeedback.mediumImpact();
              await _heart.forward();
              if (mounted) _heart.reverse();
            },
            icon: Transform.scale(
              scale: _heartScale.value,
              child: Icon(
                isFavourite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                // The colour tween only means something on the way in; a
                // removal pulses white, which is what removal looks like.
                color: isFavourite ? colour : AppColors.textPrimary,
                shadows: [
                  Shadow(
                    blurRadius: kGlow.first.blurRadius,
                    color: isFavourite ? colour : AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

/// Previous · play/pause · next.
///
/// One filled control and two ghosts. All three used to be
/// `FloatingActionButton.large` at 96dp with every elevation zeroed — a FAB
/// used as a shaped box, three of them carrying identical visual weight, so
/// the screen had no primary action at all.
class _Transport extends StatelessWidget {
  const _Transport({required this.controller});

  final SongController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GhostControl(
          icon: Icons.skip_previous_rounded,
          tooltip: 'Previous',
          onPressed: controller.playPreviousSong,
        ),
        const SizedBox(width: Space.xl),
        Obx(
          () => _PrimaryControl(
            isPlaying: controller.isPlaying.value,
            isBuffering: controller.isBuffering.value,
            onPressed: () => controller.isPlaying.value
                ? controller.pausePlaying()
                : controller.resumePlaying(),
          ),
        ),
        const SizedBox(width: Space.xl),
        _GhostControl(
          icon: Icons.skip_next_rounded,
          tooltip: 'Next',
          onPressed: controller.playNextSong,
        ),
      ],
    );
  }
}

/// The screen's one primary action: a filled disc, the only solid surface in
/// the app. White on the gradient is the same language the glow speaks — this
/// is what is live.
class _PrimaryControl extends StatelessWidget {
  const _PrimaryControl({
    required this.isPlaying,
    required this.isBuffering,
    required this.onPressed,
  });

  final bool isPlaying;

  /// True while `just_audio` reports loading or buffering. The button used
  /// to show a static play/pause icon through both — a track that hadn't
  /// started streaming yet looked identical to one that was genuinely stuck.
  final bool isBuffering;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: isBuffering ? 'Loading' : (isPlaying ? 'Pause' : 'Play'),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      iconSize: Controls.iconPrimary,
      style: IconButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        fixedSize: const Size.square(Controls.primary),
        shape: const CircleBorder(),
      ),
      // Still tappable while it spins — the tap is what pauses a buffering
      // stream, and a disabled button here would take that away.
      icon: isBuffering
          ? SizedBox.square(
              dimension: Controls.iconPrimary * 0.7,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.onPrimary,
              ),
            )
          : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }
}

/// Shuffle, 10-second skip, repeat — frequent, low-cost toggles that earned a
/// place on the screen but not equal billing with [_Transport]. Each one uses
/// the "inline icon in a secondary-sized target" recipe the favourite heart
/// already established, so the row reads as a step down from the transport
/// above it rather than a second row of the same weight.
///
/// Portrait only — see [_CompactControls] for the landscape row that folds
/// these into the transport instead of stacking them beneath it.
class _SecondaryControls extends StatelessWidget {
  const _SecondaryControls({required this.controller});

  final SongController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ShuffleToggle(controller: controller),
        _SkipControl(controller: controller, backward: true),
        _SkipControl(controller: controller, backward: false),
        _RepeatToggle(controller: controller),
      ],
    );
  }
}

/// Landscape's equivalent of [_Transport] plus [_SecondaryControls]: one row
/// instead of two.
///
/// A short, wide viewport is the opposite of a tall, narrow one — width to
/// spare, height scarce — and two control rows below the card were pushing
/// it below the room its own `LayoutBuilder` branch needs for the track and
/// seek bar. This spends the axis landscape actually has room on, the same
/// move the card itself already makes by putting the artwork beside the
/// controls instead of above them.
class _CompactControls extends StatelessWidget {
  const _CompactControls({required this.controller});

  final SongController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ShuffleToggle(controller: controller),
        _SkipControl(controller: controller, backward: true),
        _GhostControl(
          icon: Icons.skip_previous_rounded,
          tooltip: 'Previous',
          onPressed: controller.playPreviousSong,
        ),
        Obx(
          () => _PrimaryControl(
            isPlaying: controller.isPlaying.value,
            isBuffering: controller.isBuffering.value,
            onPressed: () => controller.isPlaying.value
                ? controller.pausePlaying()
                : controller.resumePlaying(),
          ),
        ),
        _GhostControl(
          icon: Icons.skip_next_rounded,
          tooltip: 'Next',
          onPressed: controller.playNextSong,
        ),
        _SkipControl(controller: controller, backward: false),
        _RepeatToggle(controller: controller),
      ],
    );
  }
}

/// The shuffle toggle, shared by [_SecondaryControls] and [_CompactControls]
/// so the icon logic exists in exactly one place.
///
/// One glyph in both states, with [_SmallControl]'s dot carrying the on/off.
/// This used to swap in `Icons.shuffle_on_rounded`, which is not the shuffle
/// glyph in a different colour — Material draws the `_on` variants **inside a
/// filled rounded square**. Turning shuffle on therefore dropped a solid box
/// into a row of thin line icons, breaking design.md's one-stroke-language
/// rule, and it spent the app's loudest signal — a filled white surface — on
/// a toggle, when that is what marks the play button as the screen's single
/// primary action.
class _ShuffleToggle extends StatelessWidget {
  const _ShuffleToggle({required this.controller});

  final SongController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => _SmallControl(
        icon: Icons.shuffle_rounded,
        tooltip: controller.isShuffled.value ? 'Shuffle on' : 'Shuffle off',
        active: controller.isShuffled.value,
        onPressed: controller.toggleShuffle,
      ),
    );
  }
}

/// The repeat toggle, shared by [_SecondaryControls] and [_CompactControls].
///
/// The glyph carries all-vs-one — `repeat_one_rounded`'s "1" is the whole
/// difference — and the dot carries on-vs-off, so no state here rests on
/// colour alone. Same fix as [_ShuffleToggle]: the `_on` variants this used
/// to reach for are boxed glyphs, and two different silhouettes for "all" and
/// "one" made a three-state cycle read as three unrelated buttons.
class _RepeatToggle extends StatelessWidget {
  const _RepeatToggle({required this.controller});

  final SongController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mode = controller.repeatMode.value;
      final (icon, tooltip) = switch (mode) {
        RepeatMode.off => (Icons.repeat_rounded, 'Repeat off'),
        RepeatMode.all => (Icons.repeat_rounded, 'Repeat all'),
        RepeatMode.one => (Icons.repeat_one_rounded, 'Repeat one'),
      };
      return _SmallControl(
        icon: icon,
        tooltip: tooltip,
        active: mode != RepeatMode.off,
        onPressed: controller.cycleRepeatMode,
      );
    });
  }
}

/// Skip back / skip forward, labelled with the interval Settings is actually
/// set to.
///
/// These were hardcoded to `Icons.replay_10_rounded` and "Back 10 seconds".
/// Task 4 made the interval a setting, so at 15 or 30 seconds the button was
/// showing a "10" while jumping a different distance — the icon was simply
/// lying about what the tap does.
///
/// Material ships numbered glyphs for 5, 10 and 30 seconds only, and Settings
/// also offers 15. An interval Material cannot draw falls back to the
/// unnumbered arrow, mirrored for the forward direction — which is exactly
/// how Material's own `forward_N` relates to its `replay_N` — rather than
/// showing a number that is wrong. The tooltip carries the real figure in
/// every case.
class _SkipControl extends StatelessWidget {
  const _SkipControl({required this.controller, required this.backward});

  final SongController controller;
  final bool backward;

  static const Map<int, (IconData, IconData)> _numbered = {
    5: (Icons.replay_5_rounded, Icons.forward_5_rounded),
    10: (Icons.replay_10_rounded, Icons.forward_10_rounded),
    30: (Icons.replay_30_rounded, Icons.forward_30_rounded),
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // `skipInterval` reads `SettingsController.skipIntervalSeconds` through
      // its getter, and reading it here — inside the Obx's own builder —
      // subscribes to it, so changing the interval in Settings relabels these
      // buttons without a restart.
      final seconds = controller.skipInterval.inSeconds;
      final numbered = _numbered[seconds];

      return _SmallControl(
        icon: numbered == null
            ? Icons.replay_rounded
            : (backward ? numbered.$1 : numbered.$2),
        mirrored: numbered == null && !backward,
        tooltip:
            backward ? 'Back $seconds seconds' : 'Forward $seconds seconds',
        onPressed: backward ? controller.skipBackward : controller.skipForward,
      );
    });
  }
}

/// One quiet toggle or action inside [_SecondaryControls] —
/// [Controls.iconInline] inside a [Controls.secondary] target, the same
/// recipe the favourite heart uses to stay a legal touch target without
/// reading as loud as a [_GhostControl].
class _SmallControl extends StatelessWidget {
  const _SmallControl({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
    this.mirrored = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// Skip-back and skip-forward have no on/off state and stay at this
  /// default; shuffle and repeat pass their armed state through.
  final bool active;

  /// Flips the glyph horizontally — only [_SkipControl] uses it, to build a
  /// forward arrow out of `Icons.replay_rounded` for an interval Material has
  /// no numbered glyph for.
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    Widget glyph = Icon(
      icon,
      color: active ? AppColors.textPrimary : AppColors.textSecondary,
      shadows: active ? kGlow : null,
    );

    if (mirrored) glyph = Transform.scale(scaleX: -1, child: glyph);

    // Icon, tooltip and toggle state land on one semantics node, the same
    // fix the nav rail's active/inactive state already needed — split across
    // nodes, a screen reader has no single thing to announce "on" about.
    return MergeSemantics(
      child: Semantics(
        toggled: active,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          iconSize: Controls.iconInline,
          constraints: const BoxConstraints.tightFor(
            width: Controls.secondary,
            height: Controls.secondary,
          ),
          // Colour, glow *and* a dot: three signals, because design.md's own
          // rule is that state is never carried by colour alone, and over an
          // album gradient a white-vs-72%-white difference is the first thing
          // a bright cover eats.
          icon: Stack(
            alignment: Alignment.center,
            // The dot hangs past the glyph's box on purpose.
            clipBehavior: Clip.none,
            children: [
              glyph,
              // Positioned rather than stacked in a Column so the glyph stays
              // dead-centre in its 48dp+ target whether the dot is showing or
              // not — in a Column it would ride 4pt high when active, and the
              // landscape row interleaves these with the larger transport
              // icons, where that misalignment is visible.
              Positioned(
                bottom: -Space.xs,
                child: SizedBox.square(
                  dimension: Space.xs,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          active ? AppColors.textPrimary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary transport. No fill and no border — the glow is the whole control,
/// which is what keeps [_PrimaryControl] reading as primary.
class _GhostControl extends StatelessWidget {
  const _GhostControl({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: Controls.iconSecondary,
      constraints: const BoxConstraints.tightFor(
        width: Controls.secondary,
        height: Controls.secondary,
      ),
      icon: Icon(icon, shadows: kGlow),
    );
  }
}
