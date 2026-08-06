import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:music_app/model/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How many tracks "recently played" remembers.
///
/// Twenty, not fifty: this is a strip you scan, not a history you browse. Past
/// a screenful or two of covers nobody scrolls, and every entry is a row
/// serialised into `shared_preferences` on every track change.
const int _kRecentLimit = 20;

/// The tracks you have played, newest first.
///
/// Entirely local — there is no backend for this and none is needed. `MySongs`
/// already round-trips through `toJson`/`fromJson`, so a row is stored whole
/// rather than as an id that would need re-fetching before the strip could
/// render.
///
/// Written from `SongController`'s track-change listener, which is the one
/// place that knows a track actually started — a tap, an auto-advance, a
/// notification skip and a bluetooth button all pass through it.
class RecentController extends GetxController {
  static const _kRecentlyPlayed = 'recently_played';

  /// Newest first. Empty until [_load] finishes, and empty is a legitimate
  /// resting state — the strip renders nothing at all rather than an empty
  /// state, because it is supplementary to the screen it sits on.
  final RxList<MySongs> recent = <MySongs>[].obs;

  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getString(_kRecentlyPlayed);
    if (stored == null) return;

    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      recent.value = decoded
          .map((e) => MySongs.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      // A previous build's format, or a write that got cut off mid-way.
      // Starting clean beats throwing on every launch — the same call this
      // makes as `SettingsController` does for remembered positions.
      debugPrint('Discarding unreadable recently-played list: $e');
    }
  }

  /// Records [song] as the most recently played.
  ///
  /// Deduplicated by id, not by object: the same track is a different [MySongs]
  /// instance in search than it is in favourites, so identity would let one
  /// song fill the whole strip. Re-playing something already in the list moves
  /// it to the front rather than adding a second copy.
  void record(MySongs song) {
    // The placeholder SongController starts life with. Never a real track.
    if (song.songid == 0) return;

    recent
      ..removeWhere((s) => s.songid == song.songid)
      ..insert(0, song);

    if (recent.length > _kRecentLimit) {
      recent.removeRange(_kRecentLimit, recent.length);
    }

    _persist();
  }

  /// Fire-and-forget. Nothing waits on this, and a failed write costs the strip
  /// one entry on the next launch — not worth surfacing, and not worth holding
  /// up a track change for.
  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(
      _kRecentlyPlayed,
      jsonEncode([for (final s in recent) s.toJson()]),
    );
  }

  /// Empties the list, on disk as well as in memory. Reached from Settings'
  /// identity reset, which already promises to forget everything local.
  Future<void> clear() async {
    recent.clear();
    await _prefs?.remove(_kRecentlyPlayed);
  }
}
