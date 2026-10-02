import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/playback_resolver.dart';

class _FakeStreamHandle implements SongStreamHandle {
  _FakeStreamHandle(this.marker, {this.throwOnClose = false});

  final int marker;
  final bool throwOnClose;
  bool closed = false;

  @override
  int get length => 3;

  @override
  String get mimeType => 'audio/webm';

  @override
  Stream<List<int>> open() => Stream.value([marker, 1, 2]);

  @override
  void close() {
    closed = true;
    if (throwOnClose) throw StateError('close failed');
  }
}

void main() {
  test('local TrackRef resolves directly without a network resolver', () async {
    var serverCalls = 0;
    var youtubeCalls = 0;
    final resolver = PlaybackResolver(
      resolveNyroServer: (track) async {
        serverCalls += 1;
        return track.toSong();
      },
      resolveYoutube: (track) async {
        youtubeCalls += 1;
        return track.toSong();
      },
    );
    final track = TrackRef(
      source: TrackSource.local,
      providerId: 'content://media/external/audio/media/42',
      title: 'Local fixture',
      artist: 'Artist',
    );

    final resolved = await resolver.resolve(track);

    expect(resolved.source, SongSource.local);
    expect(resolved.externalId, track.providerId);
    expect(resolved.songurl, track.providerId);
    expect(serverCalls, 0);
    expect(youtubeCalls, 0);
  });

  test('invalid local network locator is rejected', () async {
    final resolver = PlaybackResolver();
    final track = TrackRef(
      source: TrackSource.local,
      providerId: 'https://example.test/not-local.mp3',
      title: 'Invalid local fixture',
      artist: 'Artist',
    );

    await expectLater(
      resolver.resolve(track),
      throwsA(isA<PlaybackResolutionException>()),
    );
  });

  test('local content URI without a provider authority is rejected', () async {
    final resolver = PlaybackResolver();
    final track = TrackRef(
      source: TrackSource.local,
      providerId: 'content:///audio/42',
      title: 'Missing provider fixture',
      artist: 'Artist',
    );

    await expectLater(
      resolver.resolve(track),
      throwsA(isA<PlaybackResolutionException>()),
    );
  });

  test('Nyro Server TrackRef is resolved lazily through its source adapter',
      () async {
    var calls = 0;
    final resolver = PlaybackResolver(
      resolveNyroServer: (track) async {
        calls += 1;
        return MySongs(
          songid: int.parse(track.providerId),
          title: track.title,
          songurl: 'songs/${track.providerId}.mp3',
          coverurl: track.artworkRef ?? '',
          artist: track.artist,
          isquickpick: 0,
        );
      },
    );
    final track = TrackRef(
      source: TrackSource.nyroServer,
      providerId: '17',
      title: 'Hosted fixture',
      artist: 'Artist',
    );

    expect(calls, 0);
    final resolved = await resolver.resolve(track);

    expect(calls, 1);
    expect(resolved.source, SongSource.backend);
    expect(resolved.songid, 17);
    expect(resolved.songurl, 'songs/17.mp3');
  });

  test('YouTube resolution is fresh per playback and remains memory-only',
      () async {
    var calls = 0;
    final handles = <_FakeStreamHandle>[];
    final resolver = PlaybackResolver(
      resolveYoutube: (track) async {
        final handle = _FakeStreamHandle(++calls);
        handles.add(handle);
        return track.toSong().copyWith(
              songurl: 'https://signed.example/$calls',
              streamLength: handle.length,
              streamMimeType: handle.mimeType,
              streamHandle: handle,
            );
      },
    );
    final track = TrackRef(
      source: TrackSource.youtube,
      providerId: 'video-id',
      title: 'YouTube fixture',
      artist: 'Artist',
    );

    final first = await resolver.resolve(track);
    final second = await resolver.resolve(track);

    expect(calls, 2);
    expect(first.streamHandle, same(handles[0]));
    expect(second.streamHandle, same(handles[1]));
    expect(first.streamHandle, isNot(same(second.streamHandle)));
    expect(track.toJson(), isNot(contains('songurl')));
    expect(track.toJson(), isNot(contains('streamHandle')));
  });

  test('mismatched resolver output is rejected and its handle is closed',
      () async {
    final handle = _FakeStreamHandle(1);
    final resolver = PlaybackResolver(
      resolveYoutube: (track) async => MySongs.youtube(
        videoId: 'different-video',
        title: track.title,
        artist: track.artist,
        artworkUrl: '',
      ).copyWith(
        songurl: 'https://signed.example/wrong',
        streamLength: handle.length,
        streamMimeType: handle.mimeType,
        streamHandle: handle,
      ),
    );
    final track = TrackRef(
      source: TrackSource.youtube,
      providerId: 'expected-video',
      title: 'YouTube fixture',
      artist: 'Artist',
    );

    await expectLater(
      resolver.resolve(track),
      throwsA(isA<PlaybackResolutionException>()),
    );
    expect(handle.closed, isTrue);
  });

  test('missing source resolver fails with a typed user-facing error',
      () async {
    final resolver = PlaybackResolver();
    final track = TrackRef(
      source: TrackSource.youtube,
      providerId: 'video-id',
      title: 'YouTube fixture',
      artist: 'Artist',
    );

    await expectLater(
      resolver.resolve(track),
      throwsA(
        isA<PlaybackResolutionException>().having(
          (error) => error.message,
          'message',
          contains('YouTube'),
        ),
      ),
    );
  });

  test('synchronous source adapter failure becomes a typed error', () async {
    final resolver = PlaybackResolver(
      resolveYoutube: (_) => throw StateError('synchronous failure'),
    );
    final track = TrackRef(
      source: TrackSource.youtube,
      providerId: 'video-id',
      title: 'YouTube fixture',
      artist: 'Artist',
    );

    await expectLater(
      resolver.resolve(track),
      throwsA(isA<PlaybackResolutionException>()),
    );
  });

  test('synchronous TimeoutException stays inside the typed boundary',
      () async {
    final resolver = PlaybackResolver(
      resolveYoutube: (_) => throw TimeoutException('synchronous timeout'),
    );
    final track = TrackRef(
      source: TrackSource.youtube,
      providerId: 'sync-timeout-video',
      title: 'YouTube fixture',
      artist: 'Artist',
    );

    await expectLater(
      resolver.resolve(track),
      throwsA(
        isA<PlaybackResolutionException>().having(
          (error) => error.message,
          'message',
          contains('took too long'),
        ),
      ),
    );
  });

  test('late result after timeout closes its abandoned stream handle',
      () async {
    final pending = Completer<MySongs>();
    final handle = _FakeStreamHandle(9);
    final resolver = PlaybackResolver(
      resolveYoutube: (_) => pending.future,
      timeout: const Duration(milliseconds: 10),
    );
    final track = TrackRef(
      source: TrackSource.youtube,
      providerId: 'late-video',
      title: 'Late fixture',
      artist: 'Artist',
    );

    await expectLater(
      resolver.resolve(track),
      throwsA(isA<PlaybackResolutionException>()),
    );
    pending.complete(
      track.toSong().copyWith(
            songurl: 'https://signed.example/late',
            streamLength: handle.length,
            streamMimeType: handle.mimeType,
            streamHandle: handle,
          ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(handle.closed, isTrue);
  });

  test('late timeout cleanup contains stream handle close failures', () async {
    final pending = Completer<MySongs>();
    final handle = _FakeStreamHandle(10, throwOnClose: true);
    final resolver = PlaybackResolver(
      resolveYoutube: (_) => pending.future,
      timeout: const Duration(milliseconds: 10),
    );
    final track = TrackRef(
      source: TrackSource.youtube,
      providerId: 'late-throwing-video',
      title: 'Late throwing fixture',
      artist: 'Artist',
    );

    await expectLater(
      resolver.resolve(track),
      throwsA(isA<PlaybackResolutionException>()),
    );
    pending.complete(
      track.toSong().copyWith(
            songurl: 'https://signed.example/late-throwing',
            streamLength: handle.length,
            streamMimeType: handle.mimeType,
            streamHandle: handle,
          ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(handle.closed, isTrue);
  });

  test('song clear removes ephemeral stream state when handle close throws',
      () {
    final handle = _FakeStreamHandle(11, throwOnClose: true);
    final song = MySongs(
      songid: 0,
      title: 'Cleanup fixture',
      songurl: 'https://signed.example/cleanup',
      coverurl: '',
      artist: 'Artist',
      isquickpick: 0,
      source: SongSource.youtube,
      externalId: 'cleanup-video',
      streamLength: handle.length,
      streamMimeType: handle.mimeType,
      streamHandle: handle,
    );

    expect(song.clear, throwsStateError);
    expect(song.streamHandle, isNull);
    expect(song.streamLength, isNull);
    expect(song.streamMimeType, isNull);
  });

  test('source resolution timeout becomes a typed failure', () async {
    final never = Completer<MySongs>();
    final resolver = PlaybackResolver(
      resolveYoutube: (_) => never.future,
      timeout: const Duration(milliseconds: 10),
    );
    final track = TrackRef(
      source: TrackSource.youtube,
      providerId: 'video-id',
      title: 'YouTube fixture',
      artist: 'Artist',
    );

    await expectLater(
      resolver.resolve(track),
      throwsA(
        isA<PlaybackResolutionException>().having(
          (error) => error.message,
          'message',
          contains('too long'),
        ),
      ),
    );
  });
}
