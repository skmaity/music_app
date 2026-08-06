import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/controller/settings_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:get/get.dart';

class BackgroundController extends GetxController {
  RxBool isVisible = false.obs;
  SongController controller = Get.find<SongController>();

  RxList<Color> primaryColorsList = [
    Colors.black,
    Colors.black38,
  ].obs;
  RxList<Color> secondaryColorsList = [
    Colors.black38,
    Colors.black,
  ].obs;

  PaletteGenerator? paletteGenerator;
  String altImage = "uploads/covers/alt_image_bg.png";

  /// The cover whose colours are currently on screen.
  ///
  /// Only ever set once a palette has actually been applied, so a failed fetch
  /// leaves it alone and the next call retries instead of the app sitting on
  /// the black defaults for the rest of the session.
  String? _paintedCover;

  /// True once the Settings gradient-off fallback (below) is what's actually
  /// painted, so repeated calls while the toggle stays off — one per track
  /// change — don't re-flicker the veil over a colour pair that's already on
  /// screen.
  bool _paintedFlat = false;

  /// Which fetch owns the screen. Bumped on entry, checked before painting.
  int _request = 0;

  /// The veil's resting opacity. Settings' "gradient intensity" slider is
  /// the only thing that changes this — see
  /// `SettingsController.veilOpacity` — and it never returns less than
  /// `kVeilRest`, the contrast floor `SettingsController` itself won't go
  /// under. The dashboard and player screens should read this instead of
  /// the `kVeilRest` literal, or the slider changes nothing on screen.
  double get restingVeilOpacity =>
      Get.find<SettingsController>().veilOpacity.value;

  /// Repaints the background from the current cover art.
  Future<void> updatePaletteGenerator() async {
    final gradientEnabled =
        Get.find<SettingsController>().gradientEnabled.value;

    // Settings' gradient toggle, off: stop deriving colour from the cover at
    // all, rather than merely skipping the fetch below, so a vibrant
    // palette painted before the toggle was flipped doesn't linger. Falls
    // back to this controller's own idle-default pair — black / black38,
    // the same values it starts on above before anything has ever played,
    // and the pair design.md §1 documents as the "idle default" — not
    // `AppColors.accent`, which design.md and design_plan.md's "Not being
    // touched" list both reserve for the favourite heart alone.
    if (!gradientEnabled) {
      if (_paintedFlat) return;
      _paintedFlat = true;
      _paintedCover = null; // re-enabling later must repaint for real
      isVisible.value = true;
      primaryColorsList.value = [Colors.black, Colors.black38];
      secondaryColorsList.value = [Colors.black38, Colors.black];
      isVisible.value = false;
      return;
    }
    _paintedFlat = false;

    final cover = controller.currentPlaying.value.coverurl == "coverurl"
        ? altImage
        : controller.currentPlaying.value.coverurl;

    // Opening and closing the player re-runs this for a song whose palette is
    // already up. Nothing to fetch, and nothing to veil — this is what the
    // `isFromSongLogo` flag was standing in for, except that flag was a
    // one-shot the player-close path set and no one consumed, so the *next*
    // real song change was the one that silently lost its veil.
    if (cover == _paintedCover) return;

    final request = ++_request;
    isVisible.value = true;

    try {
      // Through `cached_network_image`'s cache, which is where every cover in
      // the app already lives. `NetworkImage` reads Flutter's separate cache,
      // so this re-downloaded the artwork on every song change — seconds of
      // in-flight time on a slow connection, which is the whole reason two of
      // these could overlap.
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(baseUrl + cover),
        maximumColorCount: 20,
      );

      // A newer song started while this was in flight. Drop the result: it is
      // the *previous* song's palette, and whichever fetch happened to finish
      // last used to win the screen.
      if (request != _request) return;

      paletteGenerator = palette;
      _paintedCover = cover;

      primaryColorsList.value = [
        palette.vibrantColor?.color ?? Colors.white,
        palette.darkMutedColor?.color ?? Colors.white,
      ];
      secondaryColorsList.value = [
        palette.dominantColor?.color ?? Colors.white,
        palette.mutedColor?.color ?? Colors.white,
      ];
    } catch (e) {
      // Keep whatever palette is already on screen rather than flashing white.
      debugPrint('Error generating palette: $e');
    } finally {
      // Always lift the veil — but only for the fetch that still owns it. A
      // superseded request bowing out must not uncover the gradient its
      // successor is still loading.
      if (request == _request) isVisible.value = false;
    }
  }
}
