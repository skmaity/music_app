import 'package:music_app/model/track_ref.dart';

enum MusicCapability {
  discovery,
  relatedTracks,
  albumBrowse,
  artistBrowse,
  downloads,
  offlinePlayback,
}

class CapabilityStatus {
  const CapabilityStatus.available()
      : isAvailable = true,
        unavailableReason = null;

  factory CapabilityStatus.unavailable(String reason) {
    final normalized = reason.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'must not be empty');
    }
    return CapabilityStatus._(false, normalized);
  }

  const CapabilityStatus._(this.isAvailable, this.unavailableReason);

  final bool isAvailable;
  final String? unavailableReason;
}

class SourceCapabilities {
  SourceCapabilities({
    required this.source,
    required Map<MusicCapability, CapabilityStatus> statuses,
  }) : _statuses = Map.unmodifiable(statuses) {
    final missing = MusicCapability.values
        .where((capability) => !_statuses.containsKey(capability))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw ArgumentError.value(
        statuses,
        'statuses',
        'must explicitly define every capability; missing: $missing',
      );
    }
  }

  final TrackSource source;
  final Map<MusicCapability, CapabilityStatus> _statuses;

  CapabilityStatus status(MusicCapability capability) => _statuses[capability]!;

  bool supports(MusicCapability capability) => status(capability).isAvailable;
}
