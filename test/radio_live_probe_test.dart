import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/services/youtube_related_provider.dart';
import 'package:music_app/services/youtube_source.dart';

// Opt-in network acceptance probe: flutter test --dart-define=NYRO_LIVE_RADIO=true
// test/radio_live_probe_test.dart
void main() {
  test('first real search result has at least one music recommendation',
      () async {
    final search = YouTubeSource();
    final provider = YouTubeRelatedProvider();
    try {
      final hits = await search.search('Rick Astley');
      final seed = hits.first;
      final first = await provider.fetch(seed.externalId!, null);
      var page = first;
      var matched = page.entities
          .where((entity) =>
              entity.artist?.toLowerCase().contains('rick astley') == true)
          .length;
      for (var window = 0;
          window < 4 && matched == 0 && page.continuation != null;
          window++) {
        page = await provider.fetch(seed.externalId!, page.continuation);
        matched += page.entities
            .where((entity) =>
                entity.artist?.toLowerCase().contains('rick astley') == true)
            .length;
      }
      expect(matched, greaterThan(0),
          reason: 'Live radio must find music relevant to the seed.');
    } finally {
      search.close();
      provider.close();
    }
  }, skip: !const bool.fromEnvironment('NYRO_LIVE_RADIO'));

  test('public music seed yields at least one verified music recommendation',
      () async {
    final provider = YouTubeRelatedProvider();
    try {
      final first = await provider.fetch('dQw4w9WgXcQ', null);
      var musicCount = first.entities.length;
      var cursor = first.continuation;
      for (var page = 0;
          page < 2 && musicCount == 0 && cursor != null;
          page++) {
        final next = await provider.fetch('dQw4w9WgXcQ', cursor);
        musicCount += next.entities.length;
        cursor = next.continuation;
      }
      expect(musicCount, greaterThan(0),
          reason: 'Live provider must supply music for continuous radio.');
    } finally {
      provider.close();
    }
  }, skip: !const bool.fromEnvironment('NYRO_LIVE_RADIO'));
}
