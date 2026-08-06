import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/component/animated_gradient_widget.dart';
import 'package:music_app/const/theme/dash_board_options_colors.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/global_widgets/glass_panel.dart';
import 'package:music_app/global_widgets/motion.dart';
import 'package:music_app/global_widgets/remote_image.dart';
import 'package:music_app/main_nav_pages/artists/artists_page.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/internet_controller.dart';
import 'package:music_app/controller/nav_controller.dart';
import 'package:music_app/main_nav_pages/settings/settings.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/user_favourite_page.dart';
import 'package:music_app/global_widgets/nointernet_page.dart';
import 'package:music_app/main_nav_pages/quick_picks/quick_picks.dart';
import 'package:music_app/main_nav_pages/search_songs/songs.dart';
import 'package:music_app/player_page/player_page.dart';

/// One nav-rail destination. Filled icon when active, outlined when not —
/// one icon family, one stroke language.
class _NavItem {
  const _NavItem(this.label, this.active, this.inactive);

  final String label;
  final IconData active;
  final IconData inactive;
}

const List<_NavItem> _navItems = [
  _NavItem(
      'Quick picks', Icons.hotel_class_rounded, Icons.hotel_class_outlined),
  _NavItem('Songs', Icons.music_note_rounded, Icons.music_note_outlined),
  _NavItem('Favorites', Icons.favorite_rounded, Icons.favorite_border_rounded),
  _NavItem('Artists', Icons.person_rounded, Icons.person_outline_rounded),
  _NavItem('Settings', Icons.settings_rounded, Icons.settings_outlined),
];

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final List<Widget> pages = const [
    QuickPicks(),
    SearchSongs(),
    UserFavouritePage(),
    ArtistsPage(),
    Settings(),
  ];

  /// Which page is showing, and which way the next transition travels — both
  /// on [NavController] rather than in this State, so an empty state can send
  /// the user somewhere instead of only describing where to go.
  late final NavController nav;

  late final InternetController internetController;
  late BackgroundController backgroundcontroller;

  @override
  void initState() {
    backgroundcontroller = Get.find<BackgroundController>();
    backgroundcontroller.updatePaletteGenerator();
    internetController = Get.find<InternetController>();
    nav = Get.find<NavController>();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Obx(() {
            return AnimatedGradient(
              primaryColors:
                  List<Color>.from(backgroundcontroller.primaryColorsList),
              secondaryColors:
                  List<Color>.from(backgroundcontroller.secondaryColorsList),
            );
          }),
          // The veil. Opaque while a new palette is computed, then it fades
          // back to the resting opacity — which is what keeps white list text
          // legible over a bright cover.
          //
          // `restingVeilOpacity`, not the `kVeilRest` literal: that getter is
          // what Settings' gradient-intensity slider moves, and it reads the
          // observable from inside this Obx, so dragging the slider repaints
          // the background live. It never returns less than `kVeilRest` —
          // the contrast floor is still the floor.
          Obx(
            () => AnimatedContainer(
              duration: backgroundcontroller.isVisible.value
                  ? Motion.veilIn
                  : Motion.veilOut,
              color: AppColors.scrim.withValues(
                  alpha: backgroundcontroller.isVisible.value
                      ? 1.0
                      : backgroundcontroller.restingVeilOpacity),
              child: const SizedBox.expand(),
            ),
          ),
          Row(
            children: [
              SafeArea(
                right: false,
                // Centred for real. The old `mainAxisAlignment: center` sat
                // inside a SingleChildScrollView, whose cross axis is
                // unbounded, so it did nothing and the rail was top-aligned in
                // practice while the code claimed otherwise.
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: Center(child: _navRail()),
                    ),
                  ),
                ),
              ),
              Expanded(
                // One bottom inset for every page. No list adds its own, so
                // before this the last row of every list sat under the gesture
                // bar.
                child: SafeArea(
                  top: false,
                  left: false,
                  child: Column(
                    children: [
                      Obx(() => Expanded(child: _pageSwitcher(context))),
                      const _NowPlayingBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The rail's page transition — a Material shared axis, not a full-width fly.
  ///
  /// The outgoing page leaves the way you came from and the incoming page
  /// arrives from the way you are going, both over a short [Motion.pageShift].
  /// Before, both pages travelled the same path at the same duration, which
  /// read as muddy rather than spatial — and it ran for 800ms, roughly 2.5x
  /// the platform standard on the most repeated interaction in the app.
  Widget _pageSwitcher(BuildContext context) {
    final offline = !internetController.internet.value;
    final currentKey = ValueKey<int>(offline ? -1 : nav.index.value);
    final still = noMotion(context);

    return AnimatedSwitcher(
      duration: still ? Duration.zero : Motion.page,
      reverseDuration: still ? Duration.zero : Motion.exitOf(Motion.page),
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      transitionBuilder: (child, animation) {
        // AnimatedSwitcher runs the outgoing child's animation in reverse
        // through this same builder, so the direction has to be flipped for it
        // — otherwise both pages end up travelling to the same side.
        final inbound = child.key == currentKey;
        final dx =
            (inbound ? nav.direction : -nav.direction) * Motion.pageShift;

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(dx, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: currentKey,
        child: offline ? const NointernetPage() : pages[nav.index.value],
      ),
    );
  }

  Widget _navRail() {
    return GlassPanel(
      level: GlassLevel.high,
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(Radii.xl),
        bottomRight: Radius.circular(Radii.xl),
      ),
      padding: const EdgeInsets.all(Space.xs),
      child: Obx(
        () => Column(
          children: [
            for (int i = 0; i < _navItems.length; i++)
              _navButton(i, _navItems[i]),
          ],
        ),
      ),
    );
  }

  Widget _navButton(int index, _NavItem item) {
    final selected = nav.index.value == index;
    final color = selected
        ? DashBoardOptionsColors.optionSelected
        : DashBoardOptionsColors.optionUnselected;

    // The active tab was signalled by glow and colour alone — invisible to a
    // screen reader, which had no way to say which destination you were on.
    // MergeSemantics collapses the icon, the label and this flag into the one
    // node a user actually swipes to.
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        child: RotatedBox(
          quarterTurns: 3,
          child: TextButton.icon(
            // Rotated, so this 48 becomes the rail's width — the old buttons
            // were under the 48dp minimum touch target.
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            iconAlignment: IconAlignment.end,
            onPressed: () {
              if (nav.index.value == index) return;
              HapticFeedback.selectionClick();
              nav.go(index);
            },
            icon: Icon(
              selected ? item.active : item.inactive,
              color: color,
              shadows: selected ? kGlow : null,
              size: 20,
            ),
            label: Text(
              item.label,
              style: TextStyle(
                color: color,
                shadows: selected ? kGlow : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The now-playing bar, anchored to the bottom of the content column.
///
/// What this replaced was a music-note glyph in a progress ring beside the
/// rail: **no artwork, no title, no artist, no play/pause.** It was a
/// navigation affordance wearing the name of a component whose entire job is to
/// make navigation unnecessary — you could not tell what was playing, or pause
/// it, without opening the player.
///
/// It also stays up while paused. The old one was gated on `isPlaying`, so
/// pausing made the only route back to the player disappear.
class _NowPlayingBar extends StatelessWidget {
  const _NowPlayingBar();

  @override
  Widget build(BuildContext context) {
    final song = Get.find<SongController>();
    final text = Theme.of(context).textTheme;

    return Obx(() {
      final current = song.currentPlaying.value;
      // songid 0 is SongController's placeholder — nothing has played yet.
      if (current.songid == 0) return const SizedBox.shrink();

      final bar = Padding(
        padding: const EdgeInsets.fromLTRB(Space.sm, 0, Space.sm, Space.sm),
        child: GlassPanel(
          borderRadius: BorderRadius.circular(Radii.lg),
          // Stack, not Column. The progress hairline used to be the Column's
          // second child, which cost the bar a padded row — ~10px of height to
          // show 2px of information. Overlaid, it costs nothing, and the bar
          // came out shorter even after the artwork grew.
          child: Stack(
            children: [
              Row(
                children: [
                  // Material ancestor so the ink splash paints *above* the
                  // container rather than behind it — the old chip's tap
                  // looked like nothing had happened until the push landed.
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        // Through the same guarded push as every list row, so
                        // an impatient double-tap on the bar cannot stack two
                        // players either.
                        onTap: () => openPlayer(context),
                        child: Semantics(
                          button: true,
                          // One node, not four. Without this the row
                          // announces the title, the artist and a bare
                          // "image" separately.
                          excludeSemantics: true,
                          label: 'Now playing: ${current.title} by '
                              '${current.artist}. Open player',
                          child: Padding(
                            padding: const EdgeInsets.all(Space.sm),
                            child: Row(
                              children: [
                                // thumbRow, not thumb. This was the smallest
                                // artwork anywhere in the app — smaller than
                                // the list rows it sits under — in an app
                                // whose whole thesis is that the artwork is
                                // the experience. Matching the row size makes
                                // the bar read as the same object you tapped.
                                Hero(
                                  tag: kNowPlayingHeroTag,
                                  child: RemoteImage(
                                    url: baseUrl + current.coverurl,
                                    size: Controls.thumbRow,
                                    radius: Radii.sm,
                                  ),
                                ),
                                const SizedBox(width: Space.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        current.title,
                                        style: text.bodyLarge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        current.artist,
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
                          ),
                        ),
                      ),
                    ),
                  ),
                  _MiniPlayPause(song: song),
                  const SizedBox(width: Space.sm),
                ],
              ),
              // Riding the panel's bottom edge rather than sitting in a row of
              // its own — but *not* flush against it, which is what the old
              // padded row was avoiding. A 2px line at `bottom: 0` runs into
              // the Radii.lg corner clip and loses both ends, so progress near
              // zero would not draw at all.
              //
              // These two numbers are the geometry, not taste. The corner
              // circle has its centre at (20, h-20) with r = 20, so at
              // `bottom: Space.xs` the panel's own left edge has reached
              // x = 20 - sqrt(20² - 16²) = 8 — exactly `Space.sm`. The line
              // therefore spans the full straight run of the edge and touches
              // the curve at each end without ever being cut by it. Changing
              // Radii.lg means redoing this.
              //
              // Its own Obx — the position ticks several times a second and
              // has no business rebuilding the artwork or the blur.
              Positioned(
                left: Space.sm,
                right: Space.sm,
                bottom: Space.xs,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Controls.progressBar),
                  child: Obx(
                    () => LinearProgressIndicator(
                      value: song.getProgress().clamp(0.0, 1.0),
                      minHeight: Controls.progressBar,
                      backgroundColor: AppColors.trackInactive,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (noMotion(context)) return bar;
      return bar
          .animate()
          .fadeIn(duration: Motion.normal)
          .slideY(begin: 0.4, duration: Motion.normal, curve: Motion.enter);
    });
  }
}

/// Play/pause in the bar. A ghost, not a filled disc — the filled disc is the
/// player's primary action and there may only be one.
class _MiniPlayPause extends StatelessWidget {
  const _MiniPlayPause({required this.song});

  final SongController song;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final playing = song.isPlaying.value;
      return IconButton(
        tooltip: playing ? 'Pause' : 'Play',
        iconSize: Controls.iconInline,
        constraints: const BoxConstraints.tightFor(
          width: Controls.secondary,
          height: Controls.secondary,
        ),
        onPressed: () => playing ? song.pausePlaying() : song.resumePlaying(),
        icon: Icon(
          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          shadows: kGlow,
        ),
      );
    });
  }
}
