import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// Opt-in catalogue probe; it does not fetch or play media streams.
void main() {
  test('a music playlist supplies identifiable, verified music entries', () async {
    final client = YoutubeExplode();
    try {
      final results = await client.search.searchContent(
        'Rick Astley official playlist',
        filter: TypeFilters.playlist,
      ).timeout(const Duration(seconds: 20));
      final playlists = results.whereType<SearchPlaylist>().take(3).toList();
      expect(playlists, isNotEmpty);
      var checked = 0;
      var verified = 0;
      for (final playlist in playlists) {
        print('Playlist candidate: ${playlist.title}; advertised=${playlist.videoCount}');
        final entries = await client.playlists.getVideos(playlist.id).take(3).toList()
            .timeout(const Duration(seconds: 20));
        for (final entry in entries) {
          checked++;
          try {
            final detail = await client.videos.get(entry.id)
                .timeout(const Duration(seconds: 12));
            if (detail.musicData.isNotEmpty) verified++;
          } catch (_) { /* unavailable entries are not confirmed music */ }
        }
      }
      print('Playlist catalogue: playlists=${playlists.length}, entries=$checked, music-confirmed=$verified');
      expect(verified, greaterThan(0));
    } finally {
      client.close();
    }
  }, skip: !const bool.fromEnvironment('NYRO_LIVE_PLAYLIST'));
}
