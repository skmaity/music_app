import 'package:music_app/model/source_capabilities.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/music_provider.dart';

typedef LocalTrackLoader = Future<List<TrackRef>> Function();
typedef LocalTrackSearch = Future<List<TrackRef>> Function(String query);

/// Adapter boundary for Task 4's MediaStore index.
///
/// Until that index is wired, the defaults are an honest empty local library.
class LocalMusicProvider implements MusicProvider {
  LocalMusicProvider({
    LocalTrackLoader? loadSongs,
    LocalTrackSearch? searchSongs,
  })  : _loadSongs = loadSongs ?? _empty,
        _searchSongs = searchSongs;

  final LocalTrackLoader _loadSongs;
  final LocalTrackSearch? _searchSongs;

  @override
  TrackSource get source => TrackSource.local;

  @override
  bool get requiresInternet => false;

  @override
  SourceCapabilities get capabilities => SourceCapabilities(
        source: source,
        statuses: {
          MusicCapability.discovery: CapabilityStatus.unavailable(
            'Local discovery is available after media indexing.',
          ),
          MusicCapability.relatedTracks: CapabilityStatus.unavailable(
            'Related-track radio is not available for local music yet.',
          ),
          MusicCapability.albumBrowse: CapabilityStatus.unavailable(
            'Local albums are available after media indexing.',
          ),
          MusicCapability.artistBrowse: CapabilityStatus.unavailable(
            'Local artists are available after media indexing.',
          ),
          MusicCapability.downloads: CapabilityStatus.unavailable(
            'Local songs are already on this device.',
          ),
          MusicCapability.offlinePlayback: const CapabilityStatus.available(),
        },
      );

  @override
  Future<MusicProviderPage> loadSongs({String? continuation}) async {
    _rejectContinuation(continuation);
    return MusicProviderPage(items: _localOnly(await _loadSongs()));
  }

  @override
  Future<MusicProviderPage> quickPicks({String? continuation}) =>
      loadSongs(continuation: continuation);

  @override
  Future<MusicProviderPage> search(
    String query, {
    String? continuation,
  }) async {
    _rejectContinuation(continuation);
    final callback = _searchSongs;
    final tracks =
        callback == null ? await _loadSongs() : await callback(query);
    final normalized = query.trim().toLowerCase();
    final filtered = callback == null
        ? tracks.where((track) =>
            track.title.toLowerCase().contains(normalized) ||
            track.artist.toLowerCase().contains(normalized))
        : tracks;
    return MusicProviderPage(items: _localOnly(filtered));
  }

  @override
  void close() {}

  static Future<List<TrackRef>> _empty() async => const [];

  static List<TrackRef> _localOnly(Iterable<TrackRef> tracks) => tracks
      .where((track) => track.source == TrackSource.local)
      .toList(growable: false);

  static void _rejectContinuation(String? continuation) {
    if (continuation != null) {
      throw const MusicProviderException(
        'Local library pagination is not wired yet.',
      );
    }
  }
}
