import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/radio_discovery_adapter.dart';
import 'package:music_app/services/youtube_music_discovery.dart';

void main() {
  test('related discovery maps playable metadata and preserves pagination',
      () async {
    final requests = <String?>[];
    final discovery = YouTubeMusicDiscovery(
      search: (_, __) async => DiscoveryPage(entities: []),
      relatedTracks: (id, cursor) async {
        expect(id, 'seed');
        requests.add(cursor);
        return DiscoveryPage(
          entities: [
            const MusicEntity(
                type: MusicEntityType.track,
                providerId: 'video-a',
                title: 'Song A',
                videoId: 'video-a'),
            const MusicEntity(
                type: MusicEntityType.album,
                providerId: 'album-a',
                title: 'Album'),
          ],
          continuation: 'next-page',
        );
      },
    );
    final fetch = radioDiscoveryAdapter(discovery);
    final seed = TrackRef(
      source: TrackSource.youtube,
      providerId: 'seed',
      title: 'Seed',
      artist: 'Artist',
    );
    final page = await fetch(seed, 'before');
    expect(requests, ['before']);
    expect(page.continuation, 'next-page');
    expect(page.tracks.map((track) => track.providerId), ['video-a']);
    expect(page.tracks.single.source, TrackSource.youtube);
  });

  test('unplayable video entries are not fabricated into tracks', () async {
    final discovery = YouTubeMusicDiscovery(
      search: (_, __) async => DiscoveryPage(entities: []),
      relatedTracks: (_, __) async => DiscoveryPage(
        entities: [
          const MusicEntity(
              type: MusicEntityType.track,
              providerId: 'no-video',
              title: 'Unplayable'),
        ],
      ),
    );
    final fetch = radioDiscoveryAdapter(discovery);
    final seed = TrackRef(
      source: TrackSource.youtube,
      providerId: 'seed',
      title: 'Seed',
      artist: 'Artist',
    );
    expect((await fetch(seed, null)).tracks, isEmpty);
  });
}
