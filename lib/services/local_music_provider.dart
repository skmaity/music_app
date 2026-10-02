import 'package:music_app/model/source_capabilities.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/music_provider.dart';

typedef LocalTrackLoader = Future<List<TrackRef>> Function();
typedef LocalTrackSearch = Future<List<TrackRef>> Function(String query);

/// Provider adapter over Nyro's MediaStore-backed local index.
class LocalMusicProvider implements MusicProvider {
  LocalMusicProvider({
    LocalTrackLoader? loadSongs,
    LocalTrackSearch? searchSongs,
    this.pageSize = 100,
  })  : _loadSongs = loadSongs ?? _empty,
        _searchSongs = searchSongs {
    if (pageSize <= 0) {
      throw ArgumentError.value(pageSize, 'pageSize', 'must be positive');
    }
  }

  final LocalTrackLoader _loadSongs;
  final LocalTrackSearch? _searchSongs;
  final int pageSize;

  @override
  TrackSource get source => TrackSource.local;

  @override
  bool get requiresInternet => false;

  @override
  SourceCapabilities get capabilities => SourceCapabilities(
        source: source,
        statuses: {
          MusicCapability.discovery: const CapabilityStatus.available(),
          MusicCapability.relatedTracks: CapabilityStatus.unavailable(
            'Related-track radio is not available for local music yet.',
          ),
          MusicCapability.albumBrowse: const CapabilityStatus.available(),
          MusicCapability.artistBrowse: const CapabilityStatus.available(),
          MusicCapability.downloads: CapabilityStatus.unavailable(
            'Local songs are already on this device.',
          ),
          MusicCapability.offlinePlayback: const CapabilityStatus.available(),
        },
      );

  @override
  Future<MusicProviderPage> loadSongs({String? continuation}) async {
    return _page(_localOnly(await _loadSongs()), continuation);
  }

  @override
  Future<MusicProviderPage> quickPicks({String? continuation}) =>
      loadSongs(continuation: continuation);

  @override
  Future<MusicProviderPage> search(
    String query, {
    String? continuation,
  }) async {
    final callback = _searchSongs;
    final tracks =
        callback == null ? await _loadSongs() : await callback(query);
    final normalized = query.trim().toLowerCase();
    final filtered = callback == null
        ? tracks.where((track) =>
            track.title.toLowerCase().contains(normalized) ||
            track.artist.toLowerCase().contains(normalized))
        : tracks;
    return _page(_localOnly(filtered), continuation);
  }

  @override
  void close() {}

  static Future<List<TrackRef>> _empty() async => const [];

  static List<TrackRef> _localOnly(Iterable<TrackRef> tracks) => tracks
      .where((track) => track.source == TrackSource.local)
      .toList(growable: false);

  MusicProviderPage _page(List<TrackRef> tracks, String? continuation) {
    final offset = continuation == null ? 0 : int.tryParse(continuation);
    if (offset == null || offset < 0 || offset > tracks.length) {
      throw const MusicProviderException('Invalid local library continuation.');
    }
    final end = (offset + pageSize).clamp(0, tracks.length);
    return MusicProviderPage(
      items: tracks.sublist(offset, end),
      continuation: end < tracks.length ? end.toString() : null,
    );
  }
}
