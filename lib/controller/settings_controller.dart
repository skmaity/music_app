import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/recent_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/controller/userid_controller.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/controller/user_favourite_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's name, wherever the app has to say it: `GetMaterialApp.title`
/// (which is what the Android task switcher shows), Settings' About section,
/// and the licences page.
///
/// The Dart package is still `music_app` and the Android/iOS bundle ids still
/// say `music`, all of which are internal identifiers a rename cannot reach
/// without breaking every import or, in the stores' case, orphaning the
/// listing. This is the only name a user ever sees, alongside
/// `android:label` and iOS's `CFBundleDisplayName`.
const String kAppName = 'Nyro';

/// The app version shown on the About section.
///
/// `package_info_plus` is not in `pubspec.yaml`, and Hard rule 8 forbids
/// adding a dependency for this. Hand-kept in step with pubspec.yaml's
/// `version:` field instead — update this string whenever that line changes;
/// nothing checks that the two agree.
const String kAppVersion = '1.0.0+1';

/// Every user-facing setting the app has, persisted to `shared_preferences`
/// and exposed as observables so the rest of the app reacts through `Obx`.
///
/// Every value here is read by something — a toggle that changed nothing was
/// the one thing this task forbade. Where a setting's effect lives in another
/// controller (the veil, the skip interval, autoplay, remembered position),
/// that controller calls back in here through `Get.find<SettingsController>()`
/// rather than this controller reaching out, so none of them need to depend
/// on Settings existing at construction time — only whenever the behaviour
/// they gate actually runs.
class SettingsController extends GetxController {
  // ---------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------

  static const _kGradientEnabled = 'settings_gradient_enabled';
  static const _kVeilOpacity = 'settings_veil_opacity';
  static const _kReducedMotion = 'settings_reduced_motion';
  static const _kPlaybackSpeed = 'settings_default_playback_speed';
  static const _kSkipInterval = 'settings_skip_interval_seconds';
  static const _kAutoplay = 'settings_autoplay_enabled';
  static const _kRememberPosition = 'settings_remember_position_enabled';
  static const _kLastPositions = 'settings_last_positions';

  late SharedPreferences _prefs;

  /// True once the values below reflect disk rather than just their
  /// compiled-in defaults. Mirrors how `UseridController.id` resolves
  /// lazily — `Get.find<SettingsController>()` can return before
  /// `SharedPreferences.getInstance()` does, so every observable below
  /// starts at the value that also matches today's un-configurable
  /// behaviour, and this flips once the real, possibly-different value
  /// lands.
  RxBool isReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
    refreshImageCacheSize();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();

    gradientEnabled.value = _prefs.getBool(_kGradientEnabled) ?? true;
    veilOpacity.value =
        _clampVeil(_prefs.getDouble(_kVeilOpacity) ?? kVeilRest);
    reducedMotion.value = _prefs.getBool(_kReducedMotion) ?? false;

    final storedSpeed = _prefs.getDouble(_kPlaybackSpeed);
    defaultPlaybackSpeed.value = storedSpeed != null &&
            SongController.availableSpeeds.contains(storedSpeed)
        ? storedSpeed
        : 1.0;

    final storedInterval = _prefs.getInt(_kSkipInterval);
    skipIntervalSeconds.value = storedInterval != null &&
            availableSkipIntervals.contains(storedInterval)
        ? storedInterval
        : 10;

    autoplayEnabled.value = _prefs.getBool(_kAutoplay) ?? true;
    rememberPositionEnabled.value = _prefs.getBool(_kRememberPosition) ?? false;

    final storedPositions = _prefs.getString(_kLastPositions);
    if (storedPositions != null) {
      try {
        final decoded = jsonDecode(storedPositions) as Map<String, dynamic>;
        _lastPositions
          ..clear()
          ..addAll(decoded.map((key, value) => MapEntry(key, value as int)));
      } catch (e) {
        // A previous build's format, or a write that got cut off mid-way.
        // Starting clean beats throwing on every launch.
        debugPrint('Discarding unreadable remembered positions: $e');
      }
    }

    isReady.value = true;
  }

  // ---------------------------------------------------------------------
  // Appearance
  // ---------------------------------------------------------------------

  /// Whether the background derives its colour from the current cover at
  /// all. Consulted by `BackgroundController.updatePaletteGenerator`, which
  /// falls back to a fixed pair instead of running `PaletteGenerator` when
  /// this is off.
  RxBool gradientEnabled = true.obs;

  /// The veil's resting opacity — "gradient intensity" in the UI. Wired
  /// straight to what `BackgroundController.restingVeilOpacity` returns,
  /// which the dashboard and player screens should read instead of the
  /// `kVeilRest` literal.
  ///
  /// [minVeilOpacity] is `kVeilRest` itself: tokens.dart documents it as the
  /// contrast floor that keeps white text at 4.5:1 over a bright cover, so
  /// this can never be set — nor default, nor be loaded from a stale
  /// pre-floor value on disk — below it. The floor is the least-veiled end
  /// of the range on purpose: sliding "up" means more veil, never less than
  /// what legibility requires.
  RxDouble veilOpacity = kVeilRest.obs;

  /// The contrast floor. Never let a slider go under this.
  static const double minVeilOpacity = kVeilRest;

  /// The most veil Settings will ever apply. Not 1.0: a fully opaque veil
  /// would hide the cover entirely, and "the background is the music" is
  /// design.md's whole premise for this screen — even at maximum, the
  /// palette should still be visibly there underneath.
  static const double maxVeilOpacity = 0.6;

  /// Persisted only. `global_widgets/motion.dart`'s `noMotion()` is what
  /// actually honours this — it is UI, and out of this controller's scope —
  /// this just keeps the choice across restarts.
  RxBool reducedMotion = false.obs;

  // `num.clamp` (there's no `double`-specific override) returns `num`, not
  // `double` — the explicit `.toDouble()` is load-bearing, not decoration.
  double _clampVeil(double value) =>
      value.clamp(minVeilOpacity, maxVeilOpacity).toDouble();

  Future<void> setGradientEnabled(bool value) async {
    gradientEnabled.value = value;
    await _prefs.setBool(_kGradientEnabled, value);
    // Applies immediately rather than waiting for the next track change —
    // flipping the toggle should be visible right away. `Get.find`, not an
    // `isRegistered` guard: see `resetIdentity`'s doc for why a guard here
    // would risk silently doing nothing.
    Get.find<BackgroundController>().updatePaletteGenerator();
  }

  Future<void> setVeilOpacity(double value) async {
    final clamped = _clampVeil(value);
    veilOpacity.value = clamped;
    await _prefs.setDouble(_kVeilOpacity, clamped);
  }

  Future<void> setReducedMotion(bool value) async {
    reducedMotion.value = value;
    await _prefs.setBool(_kReducedMotion, value);
  }

  // ---------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------

  /// Applied when a queue is loaded — see `SongController.playQueue`. It used
  /// to be reapplied at the start of every track, which the player now handles
  /// itself: a speed set on a playlist survives a track change.
  ///
  /// Must be one of `SongController.availableSpeeds`; the player only ever
  /// offers those six, and a default outside that set couldn't be selected
  /// again from the player's own speed picker.
  RxDouble defaultPlaybackSpeed = 1.0.obs;

  /// Backs `SongController.skipInterval`, which used to be a
  /// `static const Duration`. `skipForward`/`skipBackward` keep their
  /// existing signatures; only how far they jump is settings-driven now.
  RxInt skipIntervalSeconds = 10.obs;

  static const List<int> availableSkipIntervals = [10, 15, 30];

  /// Gates the plain "move on to the next track" branch of
  /// `SongController`'s `processingStateStream` listener. Repeat-one still
  /// replays the track that just finished, and the sleep timer's
  /// end-of-track pause still fires, regardless of this — neither of those
  /// is "advancing to a new track", which is the only thing this toggle
  /// means.
  RxBool autoplayEnabled = true.obs;

  /// When on, `SongController` checkpoints and restores per-song playback
  /// position — see `getLastPosition`/`saveLastPosition` below.
  RxBool rememberPositionEnabled = false.obs;

  Future<void> setDefaultPlaybackSpeed(double speed) async {
    if (!SongController.availableSpeeds.contains(speed)) return;
    defaultPlaybackSpeed.value = speed;
    await _prefs.setDouble(_kPlaybackSpeed, speed);
  }

  Future<void> setSkipIntervalSeconds(int seconds) async {
    if (!availableSkipIntervals.contains(seconds)) return;
    skipIntervalSeconds.value = seconds;
    await _prefs.setInt(_kSkipInterval, seconds);
  }

  Future<void> setAutoplayEnabled(bool value) async {
    autoplayEnabled.value = value;
    await _prefs.setBool(_kAutoplay, value);
  }

  Future<void> setRememberPositionEnabled(bool value) async {
    rememberPositionEnabled.value = value;
    await _prefs.setBool(_kRememberPosition, value);
  }

  // -- last playback position ----------------------------------------------
  //
  // Keyed by songid (as a string — JSON object keys can't be ints) rather
  // than kept per-controller, so it survives the app restarting and doesn't
  // care which screen the song was opened from. Bounded to
  // [_maxRememberedPositions] entries, evicted oldest-first: without a cap
  // this is a file that only ever grows, one entry per song ever opened
  // with the setting on, for the life of the install.

  static const int _maxRememberedPositions = 50;

  /// In-memory mirror of what's on disk, kept in insertion order so the
  /// least-recently-touched entry is always `.keys.first`.
  final Map<String, int> _lastPositions = {};

  /// The saved position for [songId], or null if none is stored. Synchronous
  /// — it reads the in-memory mirror rather than disk — because
  /// `SongController.playQueue` and `jumpToQueueIndex` both need an answer
  /// before they can hand a start position to the player.
  Duration? getLastPosition(int songId) {
    final ms = _lastPositions[songId.toString()];
    return ms == null ? null : Duration(milliseconds: ms);
  }

  Future<void> saveLastPosition(int songId, Duration position) async {
    final key = songId.toString();
    // Remove-then-reinsert so this key becomes the most-recently-used one —
    // `Map` in Dart preserves insertion order, which is what makes
    // `.keys.first` below the least-recently-used entry to evict.
    _lastPositions.remove(key);
    _lastPositions[key] = position.inMilliseconds;
    while (_lastPositions.length > _maxRememberedPositions) {
      _lastPositions.remove(_lastPositions.keys.first);
    }
    await _prefs.setString(_kLastPositions, jsonEncode(_lastPositions));
  }

  /// Drops the remembered position for [songId] — called once a track plays
  /// through to the end, since there's nothing left to resume.
  Future<void> clearLastPosition(int songId) async {
    if (_lastPositions.remove(songId.toString()) != null) {
      await _prefs.setString(_kLastPositions, jsonEncode(_lastPositions));
    }
  }

  // ---------------------------------------------------------------------
  // Data and storage
  // ---------------------------------------------------------------------

  /// The on-disk size of `cached_network_image`'s cache, in bytes. Zero
  /// until the first [refreshImageCacheSize] resolves.
  RxInt imageCacheBytes = 0.obs;

  /// True while [clearImageCache] is running, so the UI can disable the
  /// button rather than let a second tap race the first.
  RxBool isClearingCache = false.obs;

  /// `cached_network_image` caches through `flutter_cache_manager`'s
  /// `DefaultCacheManager`, which is a transitive dependency (see
  /// `pubspec.lock`) rather than a direct one — importing it here adds no
  /// line to `pubspec.yaml`. It stores files under
  /// `<getTemporaryDirectory()>/libCachedImageData`
  /// (`DefaultCacheManager.key`); `path_provider` supplies the directory
  /// itself. Neither package exposes a "total size" API, so this walks the
  /// directory by hand.
  Future<void> refreshImageCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}${DefaultCacheManager.key}',
      );
      if (!await cacheDir.exists()) {
        imageCacheBytes.value = 0;
        return;
      }

      var total = 0;
      await for (final entity
          in cacheDir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        try {
          total += await entity.length();
        } catch (_) {
          // Evicted by the cache manager between the listing and the read —
          // skip it rather than fail the whole scan over one file.
        }
      }
      imageCacheBytes.value = total;
    } catch (e) {
      debugPrint('Could not read image cache size: $e');
    }
  }

  /// Empties the image cache through the cache manager's own API — not a
  /// raw directory delete, which would leave its cache-info database
  /// pointing at files that no longer exist.
  Future<void> clearImageCache() async {
    isClearingCache.value = true;
    try {
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      debugPrint('Could not clear image cache: $e');
    } finally {
      await refreshImageCacheSize();
      isClearingCache.value = false;
    }
  }

  // Stream quality / wifi-only streaming: investigated and left out.
  // `MySongs` carries exactly one `songurl` — the API has no quality
  // variants to switch between — and `internet_connection_checker` (already
  // a dependency) only ever reports connected / disconnected / slow, never
  // which kind of connection it is. Distinguishing wifi from cellular needs
  // `connectivity_plus`, which is not in `pubspec.yaml`, and Hard rule 8 /
  // this task's own last line forbid adding a dependency to build this.

  // ---------------------------------------------------------------------
  // Identity
  // ---------------------------------------------------------------------

  /// Clears the stored uuid, mints a new one, and clears every bit of state
  /// that hung off the old one so nothing keeps showing the previous
  /// identity's data. `UseridController.resetIdentity()` does the actual
  /// swap (see that file for why `id` had to change shape to allow it) —
  /// this also resets what depends on it, which `UseridController` itself
  /// has no reason to know about:
  ///
  /// - the favourites list, which is fetched under the old id and does not
  ///   refetch itself just because the id underneath it changed;
  /// - the currently playing track's heart, which the new id has never
  ///   favourited;
  /// - the recently-played strip, which is a record of what the *previous*
  ///   listener heard. It is stored locally rather than against the id, so
  ///   nothing else would ever clear it, and a reset that leaves your listening
  ///   history on the home screen has not reset much.
  ///
  /// Both are reached with `Get.find`, not a `Get.isRegistered` guard —
  /// `SongController.toggleFavourite` already learned that lesson:
  /// `isRegistered` reports false for a `lazyPut` controller nobody has
  /// resolved yet (say, a reset before Favourites was ever opened), and a
  /// guard here would silently skip clearing state that very much still
  /// exists.
  Future<void> resetIdentity() async {
    await Get.find<UseridController>().resetIdentity();

    Get.find<UserFavouriteController>().userFavoutitesList.clear();
    await Get.find<RecentController>().clear();

    final songs = Get.find<SongController>();
    if (songs.currentPlaying.value.songid != 0) {
      await songs
          .refreshFavouriteStatus(songs.currentPlaying.value.songid.toString());
    } else {
      songs.isFavourite.value = false;
    }
  }
}
