import 'package:get/get.dart';
import 'package:music_app/model/track_ref.dart';

enum AppDestination {
  quickPicks('quick-picks'),
  songs('songs'),
  favourites('favourites'),
  artists('artists'),
  library('library'),
  downloads('downloads'),
  settings('settings');

  const AppDestination(this.stableId);
  final String stableId;
}

bool destinationAvailableForSource(
  TrackSource source,
  AppDestination destination,
) {
  if (source != TrackSource.local) return true;
  return destination != AppDestination.favourites &&
      destination != AppDestination.library;
}

/// Stable destination state, remembered independently for every music source.
class NavController extends GetxController {
  NavController({TrackSource initialSource = TrackSource.nyroServer})
      : _activeSource = initialSource,
        current = AppDestination.quickPicks.obs;

  final Rx<AppDestination> current;
  TrackSource _activeSource;
  final Map<TrackSource, AppDestination> _bySource = {
    for (final source in TrackSource.values) source: AppDestination.quickPicks,
  };

  /// `1` moving down the rail, `-1` moving up.
  double direction = 1;

  TrackSource get activeSource => _activeSource;

  void go(AppDestination next) {
    if (!destinationAvailableForSource(_activeSource, next)) return;
    final previous = current.value;
    if (next == previous) return;
    direction = next.index > previous.index ? 1 : -1;
    current.value = next;
    _bySource[_activeSource] = next;
  }

  void activateSource(TrackSource source) {
    if (source == _activeSource) return;
    _bySource[_activeSource] = current.value;
    final remembered = _bySource[source] ?? AppDestination.quickPicks;
    final next = destinationAvailableForSource(source, remembered)
        ? remembered
        : AppDestination.songs;
    direction = next.index >= current.value.index ? 1 : -1;
    _activeSource = source;
    current.value = next;
  }
}
