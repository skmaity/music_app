import 'dart:async';
import 'package:music_app/model/song_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

typedef YouTubeSearch = Future<List<MySongs>> Function(String query);
typedef YouTubeResolve = Future<Uri?> Function(String videoId);

class LatestRequest {
  int _value = 0;
  int next() => ++_value;
  bool owns(int request) => request == _value;
}

class YouTubeSourceException implements Exception {
  const YouTubeSourceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class YouTubePlaybackHandle implements SongStreamHandle {
  YouTubePlaybackHandle(this._client, this._stream);
  final YoutubeExplode _client;
  final AudioOnlyStreamInfo _stream;
  bool _closed = false;

  @override
  int get length => _stream.size.totalBytes;
  @override
  String get mimeType => 'audio/${_stream.container.name}';
  @override
  Stream<List<int>> open() {
    if (_closed) throw StateError('YouTube stream handle is closed.');
    return _client.videos.streamsClient.get(_stream);
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }
}

/// Experimental, unofficial general YouTube source, not Music-only search.
class YouTubeSource {
  YouTubeSource(
      {YouTubeSearch? search,
      YouTubeResolve? resolve,
      this.timeout = const Duration(seconds: 20)})
      : _search = search,
        _resolve = resolve;

  final YouTubeSearch? _search;
  final YouTubeResolve? _resolve;
  final Duration timeout;
  final YoutubeExplode _client = YoutubeExplode();

  Future<List<MySongs>> search(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      if (_search != null) return await _search(query).timeout(timeout);
      final results = await _client.search.search(query).timeout(timeout);
      return [
        for (final video in results.take(20))
          MySongs.youtube(
              videoId: video.id.value,
              title: video.title,
              artist: video.author,
              artworkUrl: video.thumbnails.mediumResUrl),
      ];
    } on TimeoutException {
      throw const YouTubeSourceException(
          'YouTube search timed out. Try again.');
    } catch (_) {
      throw const YouTubeSourceException(
          'YouTube search is unavailable. Check your connection and try again.');
    }
  }

  /// Resolve for each explicit play; never persist the temporary stream URI.
  Future<MySongs> resolve(MySongs song) async {
    if (song.source != SongSource.youtube || song.externalId == null) {
      throw const YouTubeSourceException('This is not a YouTube track.');
    }
    try {
      if (_resolve == null) return await _resolveWithClient(song);
      final uri = await _resolve(song.externalId!).timeout(timeout);
      if (uri == null) {
        throw const YouTubeSourceException(
            'No playable audio stream is available for this video.');
      }
      return song.copyWith(songurl: uri.toString());
    } on YouTubeSourceException {
      rethrow;
    } on TimeoutException {
      throw const YouTubeSourceException(
          'YouTube audio resolution timed out. Try again.');
    } catch (_) {
      throw const YouTubeSourceException(
          'Audio is unavailable. The video may be restricted or the connection failed.');
    }
  }

  Future<MySongs> _resolveWithClient(MySongs song) async {
    final playbackClient = YoutubeExplode();
    try {
      final manifest = await playbackClient.videos.streamsClient.getManifest(
        song.externalId!,
        ytClients: [YoutubeApiClient.androidSdkless],
      ).timeout(timeout);
      if (manifest.audioOnly.isEmpty) {
        throw const YouTubeSourceException(
          'No playable audio stream is available for this video.',
        );
      }
      final stream = manifest.audioOnly.withHighestBitrate();
      final handle = YouTubePlaybackHandle(playbackClient, stream);
      return song.copyWith(
        songurl: stream.url.toString(),
        streamLength: handle.length,
        streamMimeType: handle.mimeType,
        streamHandle: handle,
      );
    } catch (_) {
      playbackClient.close();
      rethrow;
    }
  }

  void close() => _client.close();
}
