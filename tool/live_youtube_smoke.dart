// Opt-in network smoke check; no audio file is saved or URL logged.
import 'dart:io';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/services/youtube_source.dart';

Future<void> main() async {
  final source = YouTubeSource();
  final http = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final results = await source.search('Blender Big Buck Bunny official')
        .timeout(const Duration(seconds: 30));
    stdout.writeln('SEARCH results=${results.length}');
    if (results.isEmpty) throw StateError('Search returned no results');
    final sample = MySongs.youtube(videoId: 'aqz-KE-bpKQ',
        title: 'Big Buck Bunny', artist: 'Blender', artworkUrl: '');
    final resolved = await source.resolve(sample)
        .timeout(const Duration(seconds: 40));
    stdout.writeln('RESOLVE audio URL obtained (redacted)');
    final request = await http.getUrl(Uri.parse(resolved.songurl));
    request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-1023');
    final response = await request.close().timeout(const Duration(seconds: 15));
    stdout.writeln('MEDIA status=${response.statusCode} type=${response.headers.contentType}');
    if (response.statusCode != 200 && response.statusCode != 206) {
      throw StateError('Media request rejected');
    }
    final chunk = await response.first.timeout(const Duration(seconds: 15));
    if (chunk.isEmpty) throw StateError('Media response was empty');
    stdout.writeln('MEDIA received=${chunk.length} bytes; no file saved');
  } catch (error) {
    stdout.writeln('FAIL ${error is YouTubeSourceException ? error.message : error.runtimeType}');
    exitCode = 1;
  } finally {
    source.close();
    http.close(force: true);
  }
}
