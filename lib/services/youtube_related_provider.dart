import 'package:music_app/services/youtube_music_discovery.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// A bounded verification window. The next cursor resumes at [offset + 3]
/// on the same provider page rather than discarding unexamined entries.
List<T> relatedCandidateWindow<T>(Iterable<T> page, int offset) =>
    page.skip(offset).take(3).toList();

/// Fail closed when YouTube's generic related feed crosses artists.
/// The source must separately confirm that the candidate is music.
bool isRelatedMusicArtist(
  String seedArtist, {
  required String candidateArtist,
  required String candidateTitle,
}) {
  String normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  final seed = normalize(seedArtist);
  if (seed.length < 4 ||
      seed == 'various artists' ||
      seed == 'unknown artist') {
    return false;
  }
  final artist = normalize(candidateArtist);
  final title = normalize(candidateTitle);
  return artist == seed ||
      artist.startsWith('$seed ') ||
      ' $title '.contains(' $seed ');
}

final class RelatedVideo {
  const RelatedVideo({
    required this.id,
    required this.title,
    required this.artist,
    required this.isMusic,
  });
  final String id;
  final String title;
  final String artist;
  final bool isMusic;
}

final class RelatedVideoPage {
  RelatedVideoPage({required this.videos, this.next});
  final List<RelatedVideo> videos;
  final Future<RelatedVideoPage?> Function()? next;
}

abstract interface class RelatedVideoGateway {
  Future<RelatedVideoPage?> initial(String videoId);
  void close();
}

/// Owns one discovery client. Stream playback uses separate handle-owned clients.
final class ExplodeRelatedGateway implements RelatedVideoGateway {
  final YoutubeExplode _client = YoutubeExplode();

  @override
  Future<RelatedVideoPage?> initial(String videoId) async {
    final video = await _client.videos.get(videoId);
    final seedArtist = video.musicData
            .map((music) => music.artist)
            .whereType<String>()
            .where((artist) => artist.trim().isNotEmpty)
            .firstOrNull ??
        video.author;
    final related = await _client.videos.getRelatedVideos(video);
    return related == null ? null : _map(related, seedArtist);
  }

  Future<RelatedVideoPage> _map(RelatedVideosList page, String seedArtist,
      [int offset = 0]) async {
    // A generic YouTube related feed includes non-music. Inspect only a
    // bounded window and require the watch page's music metadata.
    final candidates = relatedCandidateWindow(page, offset);
    final checked = await Future.wait(candidates.map((video) async {
      if (video.isLive) return null;
      try {
        final details = await _client.videos
            .get(video.id.value)
            .timeout(const Duration(seconds: 12));
        if (details.musicData.isEmpty) return null;
        final creditedArtists =
            details.musicData.map((music) => music.artist).whereType<String>();
        if (!creditedArtists.any((artist) => isRelatedMusicArtist(
              seedArtist,
              candidateArtist: artist,
              candidateTitle: video.title,
            ))) {
          return null;
        }
        return RelatedVideo(
          id: video.id.value,
          title: video.title,
          artist: creditedArtists.first,
          isMusic: true,
        );
      } catch (_) {
        return null;
      }
    }));
    return RelatedVideoPage(
      videos: checked.whereType<RelatedVideo>().toList(),
      next: () async {
        if (offset + candidates.length < page.length) {
          return _map(page, seedArtist, offset + candidates.length);
        }
        final following = await page.nextPage();
        return following == null ? null : _map(following, seedArtist);
      },
    );
  }

  @override
  void close() => _client.close();
}

/// Converts the package's stateful pages to one opaque, session-bound cursor.
/// A new seed replaces the old page; stale cursors never advance it.
final class YouTubeRelatedProvider {
  YouTubeRelatedProvider({RelatedVideoGateway? gateway})
      : _gateway = gateway ?? ExplodeRelatedGateway();

  final RelatedVideoGateway _gateway;
  String? _seed;
  RelatedVideoPage? _page;
  int _generation = 0;
  int _pageNumber = 0;
  bool _closed = false;

  Future<DiscoveryPage> fetch(String videoId, String? continuation) async {
    if (_closed) throw StateError('Related-video provider is closed.');
    late RelatedVideoPage? page;
    if (continuation == null) {
      final request = ++_generation;
      _pageNumber = 0;
      _seed = videoId;
      _page = null;
      page = await _gateway.initial(videoId);
      if (_closed || request != _generation) return DiscoveryPage(entities: []);
    } else {
      if (_seed != videoId ||
          continuation != 'page-$_generation-$_pageNumber' ||
          _page?.next == null) {
        throw StateError('Related-video cursor is no longer valid.');
      }
      final request = _generation;
      page = await _page!.next!();
      if (_closed || request != _generation) return DiscoveryPage(entities: []);
    }
    _page = page;
    _pageNumber++;
    return DiscoveryPage(
      entities: [
        for (final video in page?.videos ?? <RelatedVideo>[])
          if (video.isMusic && video.id.isNotEmpty)
            MusicEntity(
              type: MusicEntityType.track,
              providerId: video.id,
              videoId: video.id,
              title: video.title,
              artist: video.artist,
            ),
      ],
      continuation:
          page?.next == null ? null : 'page-$_generation-$_pageNumber',
    );
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _generation++;
    _page = null;
    _gateway.close();
  }
}
