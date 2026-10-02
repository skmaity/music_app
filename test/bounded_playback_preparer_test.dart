import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/model/playback_context.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/bounded_playback_preparer.dart';

TrackRef _track(String id) => TrackRef(
      source: TrackSource.youtube,
      providerId: id,
      title: id,
      artist: 'Artist',
    );

QueueEntry _entry(String id) => QueueEntry(
      id: id,
      track: _track(id),
      kind: QueueEntryKind.explicit,
    );

class _Handle implements SongStreamHandle {
  bool closed = false;
  @override
  int get length => 1;
  @override
  String get mimeType => 'audio/mp4';
  @override
  Stream<List<int>> open() => Stream.value([1]);
  @override
  void close() => closed = true;
}

MySongs _resolved(QueueEntry entry, _Handle handle) =>
    entry.track.toSong().copyWith(streamHandle: handle);

void main() {
  test('only the current and one upcoming entry are resolved', () async {
    final calls = <String>[];
    final preparer = BoundedPlaybackPreparer(
      resolve: (entry) async {
        calls.add(entry.id);
        return _resolved(entry, _Handle());
      },
    );
    final queue = [_entry('a'), _entry('b'), _entry('c'), _entry('d')];

    await preparer.prepare(queue: queue, currentIndex: 0);
    expect(calls, ['a', 'b']);
    expect(preparer.preparedIds, ['a', 'b']);
  });

  test(
      'eviction closes a handle but transfer leaves the player-owned handle open',
      () async {
    final handles = <String, _Handle>{};
    final preparer = BoundedPlaybackPreparer(
      resolve: (entry) async {
        final handle = _Handle();
        handles[entry.id] = handle;
        return _resolved(entry, handle);
      },
    );
    final queue = [_entry('a'), _entry('b'), _entry('c')];
    await preparer.prepare(queue: queue, currentIndex: 0);
    final ownedByPlayer = preparer.takePrepared('a');
    expect(ownedByPlayer, isNotNull);
    await preparer.prepare(queue: queue, currentIndex: 0);
    expect(handles['a']!.closed, isFalse);
    expect(preparer.preparedIds, ['b'],
        reason: 'A transferred active entry must not be resolved twice.');
    await preparer.prepare(queue: queue, currentIndex: 2);

    expect(handles['a']!.closed, isFalse);
    expect(handles['b']!.closed, isTrue);
    expect(preparer.preparedIds, ['c']);
    preparer.dispose();
    expect(handles['c']!.closed, isTrue);
    expect(handles['a']!.closed, isFalse);
    ownedByPlayer!.streamHandle!.close();
  });

  test('obsolete asynchronous result is closed after a queue replacement',
      () async {
    final old = Completer<MySongs>();
    final obsoleteHandle = _Handle();
    final preparer = BoundedPlaybackPreparer(
      resolve: (entry) => entry.id == 'old'
          ? old.future
          : Future.value(_resolved(entry, _Handle())),
    );
    final first = preparer.prepare(queue: [_entry('old')], currentIndex: 0);
    await preparer.prepare(queue: [_entry('new')], currentIndex: 0);
    old.complete(_resolved(_entry('old'), obsoleteHandle));
    await first;

    expect(obsoleteHandle.closed, isTrue);
    expect(preparer.preparedIds, ['new']);
  });

  test('stale resolver failure after dispose does not override cancellation',
      () async {
    final pending = Completer<MySongs>();
    final preparer = BoundedPlaybackPreparer(resolve: (_) => pending.future);
    final work = preparer.prepare(queue: [_entry('old')], currentIndex: 0);
    preparer.dispose();
    pending.completeError(StateError('obsolete resolver failed'));
    await work;
    expect(preparer.preparedIds, isEmpty);
  });

  test('dispose invalidates late results and does not resolve another entry',
      () async {
    final pending = Completer<MySongs>();
    final handle = _Handle();
    var calls = 0;
    final preparer = BoundedPlaybackPreparer(
      resolve: (entry) {
        calls++;
        return pending.future;
      },
    );
    final work = preparer.prepare(
      queue: [_entry('first'), _entry('second')],
      currentIndex: 0,
    );
    preparer.dispose();
    pending.complete(_resolved(_entry('first'), handle));
    await work;

    expect(handle.closed, isTrue);
    expect(calls, 1);
    expect(preparer.preparedIds, isEmpty);
  });
}
