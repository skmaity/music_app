import 'package:music_app/model/track_ref.dart';

/// Why an item exists in the playback queue.
enum QueueEntryKind {
  /// Added by a direct user action: context start, Play next, or Add to queue.
  explicit,

  /// Added by radio/autoplay discovery.
  recommended,
}

/// One occurrence in the playback queue.
///
/// [id] identifies this occurrence, while [TrackRef.stableKey] identifies the
/// underlying track. Therefore intentional duplicate tracks remain separately
/// addressable.
final class QueueEntry {
  QueueEntry({
    required String id,
    required this.track,
    required this.kind,
  }) : id = _requiredId(id);

  final String id;
  final TrackRef track;
  final QueueEntryKind kind;

  bool get isExplicit => kind == QueueEntryKind.explicit;
  bool get isRecommended => kind == QueueEntryKind.recommended;

  static String _requiredId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'id', 'must not be empty');
    }
    return trimmed;
  }
}
