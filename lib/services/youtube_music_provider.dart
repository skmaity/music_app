import 'package:music_app/model/source_capabilities.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/music_provider.dart';
import 'package:music_app/services/youtube_source.dart';

class YoutubeMusicProvider implements MusicProvider {
  YoutubeMusicProvider({YouTubeSource? sourceClient})
      : _sourceClient = sourceClient ?? YouTubeSource();

  final YouTubeSource _sourceClient;

  @override
  TrackSource get source => TrackSource.youtube;

  @override
  bool get requiresInternet => true;

  @override
  SourceCapabilities get capabilities => SourceCapabilities(
        source: source,
        statuses: {
          MusicCapability.discovery: const CapabilityStatus.available(),
          MusicCapability.relatedTracks: CapabilityStatus.unavailable(
            'YouTube radio is not connected to the app shell yet.',
          ),
          MusicCapability.albumBrowse: CapabilityStatus.unavailable(
            'YouTube album browsing is not connected yet.',
          ),
          MusicCapability.artistBrowse: CapabilityStatus.unavailable(
            'YouTube artist browsing is not connected yet.',
          ),
          MusicCapability.downloads: CapabilityStatus.unavailable(
            'YouTube downloads require a later eligibility check.',
          ),
          MusicCapability.offlinePlayback: CapabilityStatus.unavailable(
            'YouTube playback currently requires a fresh stream.',
          ),
        },
      );

  @override
  Future<MusicProviderPage> loadSongs({String? continuation}) {
    throw const MusicProviderException(
      'Search YouTube to find music. A browsable catalogue comes later.',
    );
  }

  @override
  Future<MusicProviderPage> quickPicks({String? continuation}) {
    throw const MusicProviderException(
      'YouTube Quick picks are not connected yet.',
    );
  }

  @override
  Future<MusicProviderPage> search(
    String query, {
    String? continuation,
  }) async {
    if (continuation != null) {
      throw const MusicProviderException(
        'YouTube search continuation is not available yet.',
      );
    }
    final songs = await _sourceClient.search(query);
    return MusicProviderPage(
      items: songs
          .where((song) => song.isYouTube)
          .map(TrackRef.fromSong)
          .toList(growable: false),
    );
  }

  @override
  void close() => _sourceClient.close();
}
