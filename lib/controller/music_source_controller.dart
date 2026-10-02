import 'dart:async';

import 'package:get/get.dart';
import 'package:music_app/controller/nav_controller.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/music_provider.dart';

typedef SavedSourceLoader = Future<TrackSource?> Function();
typedef SourceSaver = Future<void> Function(TrackSource source);

/// Owns browsing-source selection and the provider registry.
///
/// It deliberately does not own page result lists. Existing playable screens
/// keep request ownership in their page controllers, where late-result fencing
/// can guard the exact state being rendered. Later source-specific feature
/// slices can consume [providerFor] without creating a second competing list.
class MusicSourceController extends GetxController {
  MusicSourceController({
    required Map<TrackSource, MusicProvider> providers,
    this.navigation,
    this.loadSavedSource,
    this.saveSource,
    TrackSource initialSource = TrackSource.youtube,
  })  : _providers = Map.unmodifiable(providers),
        selectedSource = initialSource.obs {
    final missing = TrackSource.values
        .where((source) => !_providers.containsKey(source))
        .toList(growable: false);
    final mismatched = _providers.entries
        .where((entry) => entry.key != entry.value.source)
        .map((entry) => '${entry.key.name}:${entry.value.source.name}')
        .toList(growable: false);
    if (missing.isNotEmpty || mismatched.isNotEmpty) {
      throw ArgumentError.value(
        providers,
        'providers',
        'must contain exactly one correctly keyed provider per source; '
            'missing=$missing, mismatched=$mismatched',
      );
    }
    navigation?.activateSource(initialSource);
  }

  final Map<TrackSource, MusicProvider> _providers;
  final NavController? navigation;
  final SavedSourceLoader? loadSavedSource;
  final SourceSaver? saveSource;
  final Rx<TrackSource> selectedSource;
  int _selectionRevision = 0;
  bool _closed = false;

  MusicProvider get provider => _providers[selectedSource.value]!;

  MusicProvider providerFor(TrackSource source) => _providers[source]!;

  @override
  void onInit() {
    super.onInit();
    unawaited(restoreSelection());
  }

  void selectSource(TrackSource source) {
    if (source == selectedSource.value) return;
    _selectionRevision++;
    _applySource(source);
    unawaited(_persistSource(source));
  }

  Future<void> restoreSelection() async {
    final load = loadSavedSource;
    if (load == null) return;
    final revision = _selectionRevision;
    try {
      final source = await load();
      if (_closed || source == null || revision != _selectionRevision) return;
      _applySource(source);
    } catch (_) {
      // A corrupt or unavailable preference must not block the shell. The
      // explicit first-run default remains active.
    }
  }

  void _applySource(TrackSource source) {
    if (source == selectedSource.value) return;
    selectedSource.value = source;
    navigation?.activateSource(source);
  }

  Future<void> _persistSource(TrackSource source) async {
    final save = saveSource;
    if (save == null) return;
    try {
      await save(source);
    } catch (_) {
      // Browsing must remain usable when preference persistence is unavailable.
    }
  }

  @override
  void onClose() {
    _closed = true;
    _selectionRevision++;
    for (final provider in _providers.values.toSet()) {
      provider.close();
    }
    super.onClose();
  }
}
