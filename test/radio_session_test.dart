import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/radio_session.dart';

TrackRef _youtube(String id) => TrackRef(
      source: TrackSource.youtube,
      providerId: id,
      title: 'Track $id',
      artist: 'Artist',
    );

TrackRef _server(String id) => TrackRef(
      source: TrackSource.nyroServer,
      providerId: id,
      title: 'Server $id',
      artist: 'Artist',
    );

void main() {
  test('recent dedup history is bounded while pending tracks remain unique',
      () async {
    var page = 0;
    final session = RadioSession(
      targetBufferSize: 2,
      refillThreshold: 2,
      recentHistoryLimit: 2,
      fetchRelated: (_, continuation) async {
        page++;
        final id = switch (page) {
          1 => 'one',
          2 => 'two',
          3 => 'three',
          _ => 'one',
        };
        return RadioPage(
          tracks: [_youtube(id)],
          continuation: 'page-$page',
        );
      },
    );
    await session.start(_youtube('seed'));
    expect(session.takeNext()?.providerId, 'one');
    await session.refillIfNeeded();
    expect(session.takeNext()?.providerId, 'two');
    await session.refillIfNeeded();
    expect(session.takeNext()?.providerId, 'three');
    await session.refillIfNeeded();

    expect(session.recommendations.single.providerId, 'one',
        reason: 'An old consumed candidate can recur after the recent window.');
  });

  test('invalid buffer settings fail before any provider call', () {
    Future<RadioPage> fetch(_, __) => Future.value(RadioPage(tracks: []));
    expect(
      () => RadioSession(fetchRelated: fetch, targetBufferSize: 0),
      throwsArgumentError,
    );
    expect(
      () => RadioSession(fetchRelated: fetch, refillThreshold: 0),
      throwsArgumentError,
    );
    expect(
      () => RadioSession(
        fetchRelated: fetch,
        targetBufferSize: 2,
        refillThreshold: 3,
      ),
      throwsArgumentError,
    );
  });

  test('start keeps a bounded first-seen recommendation buffer', () async {
    final session = RadioSession(
      targetBufferSize: 3,
      refillThreshold: 1,
      fetchRelated: (_, __) async => RadioPage(
        tracks: [
          _youtube('seed'),
          _youtube('one'),
          _youtube('one'),
          _youtube('two'),
          _youtube('three'),
          _youtube('four'),
        ],
        continuation: 'next-page',
      ),
    );

    await session.start(_youtube('seed'));

    expect(
      session.recommendations.map((track) => track.providerId),
      ['one', 'two', 'three'],
    );
    expect(session.continuation, 'next-page');
    expect(session.seed?.stableKey, 'youtube:seed');
  });

  test('refill starts only after usable recommendations fall below threshold',
      () async {
    var calls = 0;
    final session = RadioSession(
      targetBufferSize: 5,
      refillThreshold: 3,
      fetchRelated: (_, continuation) async {
        calls++;
        if (continuation == null) {
          return RadioPage(
            tracks: [_youtube('one'), _youtube('two'), _youtube('three')],
            continuation: 'page-2',
          );
        }
        expect(continuation, 'page-2');
        return RadioPage(
          tracks: [_youtube('four'), _youtube('five')],
          continuation: null,
        );
      },
    );

    await session.start(_youtube('seed'));
    await session.refillIfNeeded();
    expect(calls, 1, reason: 'Exactly three usable items must not refill yet.');

    expect(session.takeNext()?.providerId, 'one');
    await session.refillIfNeeded();

    expect(calls, 2);
    expect(
      session.recommendations.map((track) => track.providerId),
      ['two', 'three', 'four', 'five'],
    );
  });

  test('refill deduplicates seed buffer and consumed history and keeps source',
      () async {
    var calls = 0;
    final session = RadioSession(
      targetBufferSize: 5,
      refillThreshold: 3,
      fetchRelated: (_, continuation) async {
        calls++;
        if (continuation == null) {
          return RadioPage(
            tracks: [_youtube('one'), _youtube('two')],
            continuation: 'page-2',
          );
        }
        return RadioPage(
          tracks: [
            _youtube('seed'),
            _youtube('one'),
            _youtube('two'),
            _server('99'),
            _youtube('fresh'),
          ],
        );
      },
    );

    await session.start(_youtube('seed'));
    expect(session.takeNext()?.providerId, 'one');
    expect(session.takeNext()?.providerId, 'two');
    await session.refillIfNeeded();

    expect(calls, 2);
    expect(
      session.recommendations.map((track) => track.stableKey),
      ['youtube:fresh'],
    );
  });

  test('concurrent low-buffer checks share one refill request', () async {
    var calls = 0;
    final refill = Completer<RadioPage>();
    final session = RadioSession(
      targetBufferSize: 5,
      refillThreshold: 3,
      fetchRelated: (_, continuation) {
        calls++;
        if (continuation == null) {
          return Future.value(
            RadioPage(
              tracks: [_youtube('one')],
              continuation: 'page-2',
            ),
          );
        }
        return refill.future;
      },
    );

    await session.start(_youtube('seed'));
    final first = session.refillIfNeeded();
    final second = session.refillIfNeeded();

    expect(calls, 2,
        reason: 'The two refill checks must share one provider call.');
    refill.complete(RadioPage(tracks: [_youtube('two')]));
    await Future.wait([first, second]);
    expect(
      session.recommendations.map((track) => track.providerId),
      ['one', 'two'],
    );
  });

  test('Stop invalidates an in-flight initial request and clears the buffer',
      () async {
    final pending = Completer<RadioPage>();
    final session = RadioSession(
      fetchRelated: (_, __) => pending.future,
    );

    final starting = session.start(_youtube('seed'));
    session.stop();
    pending.complete(RadioPage(tracks: [_youtube('late')]));
    await starting;

    expect(session.isStopped, isTrue);
    expect(session.recommendations, isEmpty);
    expect(session.takeNext(), isNull);
  });

  test('starting a new seed fences the previous seed callback', () async {
    final firstPage = Completer<RadioPage>();
    final secondPage = Completer<RadioPage>();
    final session = RadioSession(
      fetchRelated: (seed, __) => switch (seed.providerId) {
        'first-seed' => firstPage.future,
        'second-seed' => secondPage.future,
        _ => throw StateError('Unexpected seed'),
      },
    );

    final firstStart = session.start(_youtube('first-seed'));
    final secondStart = session.start(_youtube('second-seed'));
    firstPage.complete(RadioPage(tracks: [_youtube('stale')]));
    await firstStart;

    expect(session.recommendations, isEmpty);
    secondPage.complete(RadioPage(tracks: [_youtube('current')]));
    await secondStart;

    expect(session.seed?.providerId, 'second-seed');
    expect(
      session.recommendations.map((track) => track.providerId),
      ['current'],
    );
  });

  test('failed refill can be retried without losing buffered tracks', () async {
    var refillAttempts = 0;
    final session = RadioSession(
      targetBufferSize: 4,
      refillThreshold: 2,
      fetchRelated: (_, continuation) async {
        if (continuation == null) {
          return RadioPage(
            tracks: [_youtube('one')],
            continuation: 'retry-page',
          );
        }
        refillAttempts++;
        if (refillAttempts == 1) throw StateError('offline');
        return RadioPage(tracks: [_youtube('two')]);
      },
    );
    await session.start(_youtube('seed'));

    await expectLater(session.refillIfNeeded(), throwsStateError);
    expect(session.recommendations.single.providerId, 'one');
    await session.refillIfNeeded();
    expect(refillAttempts, 2);
    expect(
      session.recommendations.map((track) => track.providerId),
      ['one', 'two'],
    );
  });

  test('stale provider failure after Stop is ignored', () async {
    final pending = Completer<RadioPage>();
    final session = RadioSession(fetchRelated: (_, __) => pending.future);
    final starting = session.start(_youtube('seed'));
    session.stop();
    pending.completeError(StateError('late provider failure'));

    await starting;
    expect(session.isStopped, isTrue);
    expect(session.recommendations, isEmpty);
  });

  test('explicit Stop cannot be undone by a late refill callback', () async {
    final lateRefill = Completer<RadioPage>();
    final session = RadioSession(
      targetBufferSize: 5,
      refillThreshold: 3,
      fetchRelated: (_, continuation) {
        if (continuation == null) {
          return Future.value(
            RadioPage(
              tracks: [_youtube('one')],
              continuation: 'page-2',
            ),
          );
        }
        return lateRefill.future;
      },
    );

    await session.start(_youtube('seed'));
    final refilling = session.refillIfNeeded();
    session.stop();
    lateRefill.complete(RadioPage(tracks: [_youtube('late')]));
    await refilling;

    expect(session.isStopped, isTrue);
    expect(session.recommendations, isEmpty);
    expect(session.takeNext(), isNull);
  });
}
