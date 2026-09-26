import 'package:get/get.dart';
import 'package:music_app/controller/nav_controller.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/music_provider.dart';

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
    TrackSource initialSource = TrackSource.nyroServer,
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
  final Rx<TrackSource> selectedSource;

  MusicProvider get provider => _providers[selectedSource.value]!;

  MusicProvider providerFor(TrackSource source) => _providers[source]!;

  void selectSource(TrackSource source) {
    if (source == selectedSource.value) return;
    selectedSource.value = source;
    navigation?.activateSource(source);
  }

  @override
  void onClose() {
    for (final provider in _providers.values.toSet()) {
      provider.close();
    }
    super.onClose();
  }
}
