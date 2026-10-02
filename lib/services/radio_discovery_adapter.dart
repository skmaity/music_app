import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/radio_session.dart';
import 'package:music_app/services/youtube_music_discovery.dart';

/// Adapts paged, source-qualified discovery metadata to a radio session.
/// Does not resolve audio or create playback sources.
FetchRelatedTracks radioDiscoveryAdapter(YouTubeMusicDiscovery discovery) =>
    (seed, cursor) async {
      if (seed.source != TrackSource.youtube) {
        throw ArgumentError.value(seed.source, 'seed', 'YouTube only');
      }
      final page = await discovery.relatedTracks(
        seed.providerId,
        continuation: cursor,
      );
      return RadioPage(
        tracks: [
          for (final entity in page.entities)
            if (entity.type == MusicEntityType.track &&
                entity.videoId != null &&
                entity.videoId!.isNotEmpty)
              TrackRef(
                source: TrackSource.youtube,
                providerId: entity.videoId!,
                title: entity.title,
                artist: entity.artist ?? 'Unknown artist',
              ),
        ],
        continuation: page.continuation,
      );
    };
