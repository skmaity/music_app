import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/model/playback_context.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/queue_coordinator.dart';

TrackRef _track(String id) => TrackRef(
      source: TrackSource.youtube,
      providerId: id,
      title: 'Track $id',
      artist: 'Artist',
    );

void main() {
  test('duplicate tracks receive distinct queue-entry identities', () {
    var nextId = 0;
    final coordinator = QueueCoordinator(
      idFactory: () => 'entry-${nextId++}',
    );
    final track = _track('duplicate');

    final entries = coordinator.replaceWithExplicit([track, track]);
    final first = entries.first;
    final second = entries.last;

    expect(first.id, isNot(second.id));
    expect(first.track.stableKey, second.track.stableKey);
    expect(first.kind, QueueEntryKind.explicit);
    expect(second.kind, QueueEntryKind.explicit);
  });

  test(
      'Play next inserts directly after current before explicit and radio tail',
      () {
    var nextId = 0;
    final coordinator = QueueCoordinator(
      idFactory: () => 'entry-${nextId++}',
    );
    final current = QueueEntry(
      id: 'current-entry',
      track: _track('current'),
      kind: QueueEntryKind.explicit,
    );
    final explicitTail = QueueEntry(
      id: 'explicit-tail-entry',
      track: _track('explicit-tail'),
      kind: QueueEntryKind.explicit,
    );
    final recommended = QueueEntry(
      id: 'recommended-entry',
      track: _track('recommended'),
      kind: QueueEntryKind.recommended,
    );
    final original = [current, explicitTail, recommended];

    final updated = coordinator.playNext(
      queue: original,
      currentEntryId: current.id,
      track: _track('play-next'),
    );

    expect(
      updated.map((entry) => entry.track.providerId),
      ['current', 'play-next', 'explicit-tail', 'recommended'],
    );
    expect(updated[1].kind, QueueEntryKind.explicit);
    expect(original, [current, explicitTail, recommended],
        reason: 'The native-queue owner applies the returned snapshot.');
  });

  test('Add to queue stays behind explicit tail and ahead of recommendations',
      () {
    var nextId = 0;
    final coordinator = QueueCoordinator(
      idFactory: () => 'entry-${nextId++}',
    );
    final current = QueueEntry(
      id: 'current-entry',
      track: _track('current'),
      kind: QueueEntryKind.explicit,
    );
    final explicitTail = QueueEntry(
      id: 'explicit-tail-entry',
      track: _track('explicit-tail'),
      kind: QueueEntryKind.explicit,
    );
    final firstRecommendation = QueueEntry(
      id: 'radio-1-entry',
      track: _track('radio-1'),
      kind: QueueEntryKind.recommended,
    );
    final secondRecommendation = QueueEntry(
      id: 'radio-2-entry',
      track: _track('radio-2'),
      kind: QueueEntryKind.recommended,
    );

    final updated = coordinator.addToQueue(
      queue: [
        current,
        explicitTail,
        firstRecommendation,
        secondRecommendation,
      ],
      currentEntryId: current.id,
      track: _track('added'),
    );

    expect(
      updated.map((entry) => entry.track.providerId),
      ['current', 'explicit-tail', 'added', 'radio-1', 'radio-2'],
    );
    expect(updated[2].kind, QueueEntryKind.explicit);
  });

  test('Add to queue canonicalizes interleaved future entries', () {
    var nextId = 0;
    final coordinator = QueueCoordinator(
      idFactory: () => 'new-entry-${nextId++}',
    );
    final current = QueueEntry(
      id: 'current-entry',
      track: _track('current-radio'),
      kind: QueueEntryKind.recommended,
    );
    final futureRecommendation = QueueEntry(
      id: 'future-radio-entry',
      track: _track('future-radio'),
      kind: QueueEntryKind.recommended,
    );
    final futureExplicit = QueueEntry(
      id: 'future-explicit-entry',
      track: _track('future-explicit'),
      kind: QueueEntryKind.explicit,
    );

    final updated = coordinator.addToQueue(
      queue: [current, futureRecommendation, futureExplicit],
      currentEntryId: current.id,
      track: _track('added'),
    );

    expect(
      updated.map((entry) => entry.track.providerId),
      ['current-radio', 'future-explicit', 'added', 'future-radio'],
    );
  });

  test(
      'new explicit context preserves order and creates one entry per occurrence',
      () {
    var nextId = 0;
    final coordinator = QueueCoordinator(
      idFactory: () => 'entry-${nextId++}',
    );
    final duplicate = _track('duplicate');

    final queue = coordinator.replaceWithExplicit([
      _track('first'),
      duplicate,
      duplicate,
    ]);

    expect(
      queue.map((entry) => entry.track.providerId),
      ['first', 'duplicate', 'duplicate'],
    );
    expect(queue.map((entry) => entry.id).toSet(), hasLength(3));
    expect(queue.every((entry) => entry.isExplicit), isTrue);
  });

  test('removing by entry id removes only one duplicate occurrence', () {
    var nextId = 0;
    final coordinator = QueueCoordinator(
      idFactory: () => 'entry-${nextId++}',
    );
    final duplicate = _track('duplicate');
    final queue = coordinator.replaceWithExplicit([
      duplicate,
      _track('middle'),
      duplicate,
    ]);

    final updated = coordinator.removeById(
      queue: queue,
      entryId: queue.last.id,
    );

    expect(
      updated.map((entry) => entry.track.providerId),
      ['duplicate', 'middle'],
    );
    expect(updated.first.id, queue.first.id);
  });

  test('entry-id collisions are retried before exposing a queue entry', () {
    final generated = ['collision', 'collision', 'unique'];
    var index = 0;
    final coordinator = QueueCoordinator(
      idFactory: () => generated[index++],
    );

    final queue = coordinator.replaceWithExplicit([
      _track('first'),
      _track('second'),
    ]);

    expect(queue.first.id, 'collision');
    expect(queue.last.id, 'unique');
  });

  test('exhausted entry-id allocation fails with a typed error', () {
    final coordinator = QueueCoordinator(idFactory: () => 'same-id');

    expect(
      () => coordinator.replaceWithExplicit([
        _track('first'),
        _track('second'),
      ]),
      throwsA(isA<QueueCoordinationException>()),
    );
  });

  test('stale current entry is rejected before Play next changes the queue',
      () {
    var nextId = 0;
    final coordinator = QueueCoordinator(
      idFactory: () => 'entry-${nextId++}',
    );
    final queue = coordinator.replaceWithExplicit([_track('current')]);

    expect(
      () => coordinator.playNext(
        queue: queue,
        currentEntryId: 'stale-entry',
        track: _track('next'),
      ),
      throwsA(isA<QueueCoordinationException>()),
    );
    expect(queue.single.track.providerId, 'current');
    expect(nextId, 1, reason: 'A rejected edit must not consume an entry id.');
  });

  test('stale current entry is rejected before Add to queue changes order', () {
    var nextId = 0;
    final coordinator = QueueCoordinator(
      idFactory: () => 'entry-${nextId++}',
    );
    final queue = coordinator.replaceWithExplicit([_track('current')]);

    expect(
      () => coordinator.addToQueue(
        queue: queue,
        currentEntryId: 'stale-entry',
        track: _track('added'),
      ),
      throwsA(isA<QueueCoordinationException>()),
    );
    expect(queue.single.track.providerId, 'current');
    expect(nextId, 1);
  });

  test('ambiguous duplicate entry ids are rejected before queue mutation', () {
    final coordinator = QueueCoordinator(idFactory: () => 'unused');
    final first = QueueEntry(
      id: 'duplicate-id',
      track: _track('first'),
      kind: QueueEntryKind.explicit,
    );
    final second = QueueEntry(
      id: 'duplicate-id',
      track: _track('second'),
      kind: QueueEntryKind.explicit,
    );

    expect(
      () => coordinator.playNext(
        queue: [first, second],
        currentEntryId: first.id,
        track: _track('next'),
      ),
      throwsA(isA<QueueCoordinationException>()),
    );
  });

  test('Add to queue also rejects ambiguous duplicate entry ids', () {
    final coordinator = QueueCoordinator(idFactory: () => 'new-entry');
    final queue = [
      QueueEntry(
        id: 'duplicate-id',
        track: _track('first'),
        kind: QueueEntryKind.explicit,
      ),
      QueueEntry(
        id: 'duplicate-id',
        track: _track('second'),
        kind: QueueEntryKind.explicit,
      ),
    ];

    expect(
      () => coordinator.addToQueue(
        queue: queue,
        currentEntryId: 'duplicate-id',
        track: _track('added'),
      ),
      throwsA(isA<QueueCoordinationException>()),
    );
  });

  test('stale removal fails before changing the queue', () {
    var nextId = 0;
    final coordinator = QueueCoordinator(
      idFactory: () => 'entry-${nextId++}',
    );
    final queue = coordinator.replaceWithExplicit([
      _track('first'),
      _track('second'),
    ]);

    expect(
      () => coordinator.removeById(
        queue: queue,
        entryId: 'stale-entry',
      ),
      throwsA(isA<QueueCoordinationException>()),
    );
    expect(
      queue.map((entry) => entry.track.providerId),
      ['first', 'second'],
    );
  });

  test('remove by id rejects ambiguous duplicate entry ids', () {
    final coordinator = QueueCoordinator();
    final queue = [
      QueueEntry(
        id: 'duplicate-id',
        track: _track('first'),
        kind: QueueEntryKind.explicit,
      ),
      QueueEntry(
        id: 'duplicate-id',
        track: _track('second'),
        kind: QueueEntryKind.explicit,
      ),
    ];

    expect(
      () => coordinator.removeById(
        queue: queue,
        entryId: 'duplicate-id',
      ),
      throwsA(isA<QueueCoordinationException>()),
    );
  });

  test('returned snapshots are immutable and independent from caller lists',
      () {
    var nextId = 0;
    final coordinator = QueueCoordinator(
      idFactory: () => 'entry-${nextId++}',
    );
    final initial = coordinator.replaceWithExplicit([
      _track('current'),
      _track('tail'),
    ]);
    final callerQueue = List<QueueEntry>.of(initial);
    final playedNext = coordinator.playNext(
      queue: callerQueue,
      currentEntryId: callerQueue.first.id,
      track: _track('next'),
    );
    final added = coordinator.addToQueue(
      queue: playedNext,
      currentEntryId: playedNext.first.id,
      track: _track('added'),
    );
    final removed = coordinator.removeById(
      queue: added,
      entryId: added.last.id,
    );
    callerQueue.clear();

    expect(playedNext, hasLength(3));
    final marker = QueueEntry(
      id: 'marker',
      track: _track('marker'),
      kind: QueueEntryKind.explicit,
    );
    for (final snapshot in [initial, playedNext, added, removed]) {
      expect(() => snapshot.add(marker), throwsUnsupportedError);
    }
  });
}
