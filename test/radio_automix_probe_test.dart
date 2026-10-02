import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

// Opt-in, metadata-only endpoint capability test. No signed stream URLs logged.
void main() {
  test('music next response offers song queue or automix endpoint', () async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.https('music.youtube.com', '/youtubei/v1/next'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'context': {'client': {'clientName': 'WEB_REMIX',
            'clientVersion': '1.20220918', 'platform': 'DESKTOP', 'hl': 'en'}},
          'videoId': 'dQw4w9WgXcQ',
          'isAudioOnly': true,
          'tunerSettingValue': 'AUTOMIX_SETTING_NORMAL',
        }),
      ).timeout(const Duration(seconds: 18));
      final data = response.statusCode == 200
          ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{};
      final contents = data['contents'] as Map<String, dynamic>?;
      final one = contents?['singleColumnMusicWatchNextResultsRenderer'] as Map<String, dynamic>?;
      final tabbed = one?['tabbedRenderer'] as Map<String, dynamic>?;
      final next = tabbed?['watchNextTabbedResultsRenderer'] as Map<String, dynamic>?;
      final tabs = next?['tabs'] as List<dynamic>?;
      final firstTab = tabs?.firstOrNull as Map<String, dynamic>?;
      final renderer = firstTab?['tabRenderer'] as Map<String, dynamic>?;
      final content = renderer?['content'] as Map<String, dynamic>?;
      final queue = content?['musicQueueRenderer'] as Map<String, dynamic>?;
      final panelContent = queue?['content'] as Map<String, dynamic>?;
      final panel = panelContent?['playlistPanelRenderer'] as Map<String, dynamic>?;
      final entries = panel?['contents'] as List<dynamic>? ?? [];
      final songCount = entries.where((entry) => entry is Map && entry.containsKey('playlistPanelVideoRenderer')).length;
      final automixCount = entries.where((entry) => entry is Map && entry.containsKey('automixPreviewVideoRenderer')).length;
      print('Music next: status=${response.statusCode}, songs=$songCount, automix=$automixCount, bodyBytes=${response.bodyBytes.length}');
      expect(response.statusCode, 200);
      expect(automixCount, greaterThan(0));
      final preview = entries.whereType<Map<String, dynamic>>()
          .firstWhere((entry) => entry.containsKey('automixPreviewVideoRenderer'));
      final mix = preview['automixPreviewVideoRenderer']['content']
          ['automixPlaylistVideoRenderer']['navigationEndpoint']
          ['watchPlaylistEndpoint'] as Map<String, dynamic>;
      final playlistId = mix['playlistId'] as String?;
      expect(playlistId, isNotEmpty);
      final follow = await client.post(
        Uri.https('music.youtube.com', '/youtubei/v1/next'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'context': {'client': {'clientName': 'WEB_REMIX',
            'clientVersion': '1.20220918', 'platform': 'DESKTOP', 'hl': 'en'}},
          'videoId': 'dQw4w9WgXcQ',
          'playlistId': playlistId,
          if (mix['params'] != null) 'params': mix['params'],
          'isAudioOnly': true,
        }),
      ).timeout(const Duration(seconds: 18));
      final followData = jsonDecode(follow.body) as Map<String, dynamic>;
      final followTabs = followData['contents']
          ['singleColumnMusicWatchNextResultsRenderer']['tabbedRenderer']
          ['watchNextTabbedResultsRenderer']['tabs'] as List<dynamic>;
      final followEntries = followTabs.first['tabRenderer']['content']
          ['musicQueueRenderer']['content']['playlistPanelRenderer']['contents'] as List<dynamic>;
      final followSongs = followEntries.where((entry) => entry is Map && entry.containsKey('playlistPanelVideoRenderer')).length;
      print('Automix follow: status=${follow.statusCode}, songs=$followSongs');
      expect(follow.statusCode, 200);
      expect(followSongs, greaterThan(1));
    } finally {
      client.close();
    }
  }, skip: !const bool.fromEnvironment('NYRO_LIVE_AUTOMIX'));
}
