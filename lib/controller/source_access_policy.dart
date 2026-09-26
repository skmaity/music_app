import 'package:music_app/controller/nav_controller.dart';
import 'package:music_app/model/track_ref.dart';

abstract final class SourceAccessPolicy {
  static bool canOpen({
    required TrackSource source,
    required AppDestination destination,
    required bool online,
  }) {
    if (online || source == TrackSource.local) return true;
    return destination == AppDestination.library ||
        destination == AppDestination.downloads ||
        destination == AppDestination.settings;
  }
}
