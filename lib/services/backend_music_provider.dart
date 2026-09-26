import 'dart:convert';

import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/source_capabilities.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/music_provider.dart';

typedef ServerSongLoader = Future<List<MySongs>> Function();
typedef ServerSongSearch = Future<List<MySongs>> Function(String query);

class BackendMusicProvider implements MusicProvider {
  BackendMusicProvider({
    ServerSongLoader? loadSongs,
    ServerSongLoader? loadQuickPicks,
    ServerSongSearch? searchSongs,
  })  : _loadSongs = loadSongs ?? _fetchAllSongs,
        _loadQuickPicks = loadQuickPicks ?? _fetchQuickPicks,
        _searchSongs = searchSongs ?? _search;

  final ServerSongLoader _loadSongs;
  final ServerSongLoader _loadQuickPicks;
  final ServerSongSearch _searchSongs;

  @override
  TrackSource get source => TrackSource.nyroServer;

  @override
  bool get requiresInternet => true;

  @override
  SourceCapabilities get capabilities => SourceCapabilities(
        source: source,
        statuses: {
          MusicCapability.discovery: const CapabilityStatus.available(),
          MusicCapability.relatedTracks: CapabilityStatus.unavailable(
            'Nyro Server does not expose related-track radio yet.',
          ),
          MusicCapability.albumBrowse: CapabilityStatus.unavailable(
            'Album browsing still uses the legacy Nyro Server controller.',
          ),
          MusicCapability.artistBrowse: CapabilityStatus.unavailable(
            'Artist browsing still uses the legacy Nyro Server controller.',
          ),
          MusicCapability.downloads: CapabilityStatus.unavailable(
            'Hosted downloads are not enabled yet.',
          ),
          MusicCapability.offlinePlayback: CapabilityStatus.unavailable(
            'This track must be downloaded before offline playback.',
          ),
        },
      );

  @override
  Future<MusicProviderPage> loadSongs({String? continuation}) async {
    _rejectContinuation(continuation);
    return MusicProviderPage(items: _refs(await _loadSongs()));
  }

  @override
  Future<MusicProviderPage> quickPicks({String? continuation}) async {
    _rejectContinuation(continuation);
    return MusicProviderPage(items: _refs(await _loadQuickPicks()));
  }

  @override
  Future<MusicProviderPage> search(
    String query, {
    String? continuation,
  }) async {
    _rejectContinuation(continuation);
    return MusicProviderPage(items: _refs(await _searchSongs(query)));
  }

  @override
  void close() {}

  static List<TrackRef> _refs(Iterable<MySongs> songs) => songs
      .where((song) => song.isBackend && !song.isPlaceholder)
      .map(TrackRef.fromSong)
      .toList(growable: false);

  static void _rejectContinuation(String? continuation) {
    if (continuation != null) {
      throw const MusicProviderException(
        'Nyro Server does not support paged continuations.',
      );
    }
  }

  static Future<List<MySongs>> _fetchAllSongs() async {
    final response = await api.get(allSongsUrl);
    if (response.statusCode != 200) {
      throw const MusicProviderException('Nyro Server songs are unavailable.');
    }
    return _decodeSongs(response.data);
  }

  static Future<List<MySongs>> _fetchQuickPicks() async {
    final response = await api.get(quickPicksUrl);
    if (response.statusCode != 200) {
      throw const MusicProviderException('Quick picks are unavailable.');
    }
    return _decodeSongs(response.data);
  }

  static Future<List<MySongs>> _search(String query) async {
    final response = await api.get(
      searchSongsUrl,
      queryParameters: {'query': query},
    );
    if (response.statusCode != 200) {
      throw const MusicProviderException('Nyro Server search is unavailable.');
    }
    return _decodeSongs(response.data);
  }

  static List<MySongs> _decodeSongs(dynamic payload) {
    var decoded = payload;
    if (decoded is String) decoded = jsonDecode(decoded);
    if (decoded is Map) decoded = decoded['data'];
    if (decoded is! List) {
      throw const MusicProviderException(
          'Nyro Server returned invalid music data.');
    }
    return [
      for (final value in decoded)
        MySongs.fromJson(Map<String, dynamic>.from(value as Map)),
    ];
  }
}
