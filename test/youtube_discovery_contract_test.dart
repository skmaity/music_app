import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/services/youtube_music_discovery.dart';

void main() {
  const track = MusicEntity(
    type: MusicEntityType.track,
    providerId: 'provider-track-1',
    videoId: 'video-1',
    title: 'Track one',
  );

  test('search preserves IDs and continuation and removes duplicate identities',
      () async {
    String? receivedCursor;
    final discovery = YouTubeMusicDiscovery(
      search: (query, continuation) async {
        expect(query, 'lofi');
        receivedCursor = continuation;
        return DiscoveryPage(
          entities: const [track, track],
          continuation: 'next-search-page',
        );
      },
      relatedTracks: (_, __) async => DiscoveryPage(entities: const []),
    );

    final page = await discovery.search('lofi', continuation: 'search-cursor');

    expect(receivedCursor, 'search-cursor');
    expect(page.continuation, 'next-search-page');
    expect(page.entities, [track]);
    expect(page.entities.single.providerId, 'provider-track-1');
    expect(page.entities.single.videoId, 'video-1');
  });

  test('related lookup is paged and preserves first-seen order', () async {
    const second = MusicEntity(
      type: MusicEntityType.track,
      providerId: 'provider-track-2',
      videoId: 'video-2',
      title: 'Track two',
    );
    final discovery = YouTubeMusicDiscovery(
      search: (_, __) async => DiscoveryPage(entities: const []),
      relatedTracks: (videoId, continuation) async {
        expect(videoId, 'seed-video');
        expect(continuation, 'related-cursor');
        return DiscoveryPage(
          entities: const [second, track, second],
          continuation: 'next-related-page',
        );
      },
    );

    final page = await discovery.relatedTracks(
      'seed-video',
      continuation: 'related-cursor',
    );

    expect(page.entities, [second, track]);
    expect(page.continuation, 'next-related-page');
  });

  test('deduplication keeps different entity types with the same provider ID',
      () async {
    const album = MusicEntity(
      type: MusicEntityType.album,
      providerId: 'shared-id',
      title: 'Album',
    );
    const song = MusicEntity(
      type: MusicEntityType.track,
      providerId: 'shared-id',
      videoId: 'shared-id',
      title: 'Song',
    );
    final discovery = YouTubeMusicDiscovery(
      search: (_, __) async => DiscoveryPage(entities: const [album, song]),
      relatedTracks: (_, __) async => DiscoveryPage(entities: const []),
    );

    final page = await discovery.search('shared');

    expect(page.entities, [album, song]);
  });

  test('empty search is rejected before invoking the provider', () async {
    var calls = 0;
    final discovery = YouTubeMusicDiscovery(
      search: (_, __) async {
        calls++;
        return DiscoveryPage(entities: const []);
      },
      relatedTracks: (_, __) async => DiscoveryPage(entities: const []),
    );

    await expectLater(
      discovery.search('   '),
      throwsA(
        isA<DiscoveryException>().having(
          (error) => error.message,
          'message',
          'Enter something to search for.',
        ),
      ),
    );
    expect(calls, 0);
  });

  test('provider calls time out with a typed user-facing exception', () async {
    final never = Completer<DiscoveryPage>();
    final discovery = YouTubeMusicDiscovery(
      search: (_, __) => never.future,
      relatedTracks: (_, __) => never.future,
      timeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      discovery.search('slow'),
      throwsA(
        isA<DiscoveryException>().having(
          (error) => error.message,
          'message',
          'Music discovery took too long. Please try again.',
        ),
      ),
    );
  });

  test('non-positive timeout is rejected at runtime', () {
    expect(
      () => YouTubeMusicDiscovery(
        search: (_, __) async => DiscoveryPage(entities: const []),
        relatedTracks: (_, __) async => DiscoveryPage(entities: const []),
        timeout: Duration.zero,
      ),
      throwsArgumentError,
    );
  });

  test('provider failures become typed user-facing exceptions', () async {
    final discovery = YouTubeMusicDiscovery(
      search: (_, __) => Future<DiscoveryPage>.error(StateError('provider')),
      relatedTracks: (_, __) async => DiscoveryPage(entities: const []),
    );

    await expectLater(
      discovery.search('failure'),
      throwsA(
        isA<DiscoveryException>().having(
          (error) => error.message,
          'message',
          'Music discovery is unavailable. Please try again.',
        ),
      ),
    );
  });
}
