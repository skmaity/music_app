import 'package:music_app/model/playback_context.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:uuid/uuid.dart';

typedef QueueEntryIdFactory = String Function();

final class QueueCoordinationException implements Exception {
  const QueueCoordinationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Stateless playback-order policy used by the player-owning controller.
///
/// This service does not own a playback cursor or a native audio queue.
/// SongController remains responsible for applying returned queue snapshots to
/// just_audio and for supplying the currently playing entry identity.
final class QueueCoordinator {
  QueueCoordinator({QueueEntryIdFactory? idFactory})
      : _idFactory = idFactory ?? const Uuid().v4;

  final QueueEntryIdFactory _idFactory;

  List<QueueEntry> replaceWithExplicit(Iterable<TrackRef> tracks) {
    final occupiedIds = <String>{};
    return List<QueueEntry>.unmodifiable(
      tracks.map(
        (track) => _createEntry(
          track,
          kind: QueueEntryKind.explicit,
          occupiedIds: occupiedIds,
        ),
      ),
    );
  }

  List<QueueEntry> playNext({
    required List<QueueEntry> queue,
    required String currentEntryId,
    required TrackRef track,
  }) {
    _validateUniqueIds(queue);
    final currentIndex = queue.indexWhere(
      (entry) => entry.id == currentEntryId,
    );
    if (currentIndex < 0) {
      throw const QueueCoordinationException(
        'The current queue entry is no longer present.',
      );
    }

    final updated = List<QueueEntry>.of(queue);
    updated.insert(
      currentIndex + 1,
      _createEntry(
        track,
        kind: QueueEntryKind.explicit,
        occupiedIds: queue.map((entry) => entry.id).toSet(),
      ),
    );
    return List<QueueEntry>.unmodifiable(updated);
  }

  List<QueueEntry> addToQueue({
    required List<QueueEntry> queue,
    required String currentEntryId,
    required TrackRef track,
  }) {
    _validateUniqueIds(queue);
    final currentIndex = queue.indexWhere(
      (entry) => entry.id == currentEntryId,
    );
    if (currentIndex < 0) {
      throw const QueueCoordinationException(
        'The current queue entry is no longer present.',
      );
    }

    final future = queue.skip(currentIndex + 1);
    final updated = <QueueEntry>[
      ...queue.take(currentIndex + 1),
      ...future.where((entry) => entry.isExplicit),
      _createEntry(
        track,
        kind: QueueEntryKind.explicit,
        occupiedIds: queue.map((entry) => entry.id).toSet(),
      ),
      ...future.where((entry) => entry.isRecommended),
    ];
    return List<QueueEntry>.unmodifiable(updated);
  }

  List<QueueEntry> removeById({
    required List<QueueEntry> queue,
    required String entryId,
  }) {
    _validateUniqueIds(queue);
    final index = queue.indexWhere((entry) => entry.id == entryId);
    if (index < 0) {
      throw const QueueCoordinationException(
        'The queue entry to remove is no longer present.',
      );
    }

    final updated = List<QueueEntry>.of(queue)..removeAt(index);
    return List<QueueEntry>.unmodifiable(updated);
  }

  void _validateUniqueIds(List<QueueEntry> queue) {
    final ids = <String>{};
    for (final entry in queue) {
      if (!ids.add(entry.id)) {
        throw const QueueCoordinationException(
          'Queue entry identities must be unique.',
        );
      }
    }
  }

  QueueEntry _createEntry(
    TrackRef track, {
    required QueueEntryKind kind,
    required Set<String> occupiedIds,
  }) {
    return QueueEntry(
      id: _nextId(occupiedIds),
      track: track,
      kind: kind,
    );
  }

  String _nextId(Set<String> occupiedIds) {
    for (var attempt = 0; attempt < 100; attempt++) {
      final candidate = _idFactory().trim();
      if (candidate.isNotEmpty && occupiedIds.add(candidate)) return candidate;
    }
    throw const QueueCoordinationException(
      'Unable to allocate a unique queue-entry identity.',
    );
  }
}
