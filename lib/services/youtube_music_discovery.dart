import 'dart:async';

enum MusicEntityType { track, album, playlist, artist }

final class MusicEntity {
  const MusicEntity({
    required this.type,
    required this.providerId,
    required this.title,
    this.videoId,
  });

  final MusicEntityType type;
  final String providerId;
  final String title;
  final String? videoId;

  bool get isPlayable => videoId != null;
  String get identity => '${type.name}:$providerId';
}

final class DiscoveryPage {
  DiscoveryPage({required List<MusicEntity> entities, this.continuation})
      : entities = List.unmodifiable(entities);

  final List<MusicEntity> entities;
  final String? continuation;
}

final class DiscoveryException implements Exception {
  const DiscoveryException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef SearchMusic = Future<DiscoveryPage> Function(
  String query,
  String? continuation,
);
typedef RelatedMusic = Future<DiscoveryPage> Function(
  String videoId,
  String? continuation,
);

final class YouTubeMusicDiscovery {
  YouTubeMusicDiscovery({
    required SearchMusic search,
    required RelatedMusic relatedTracks,
    this.timeout = const Duration(seconds: 10),
  })  : _search = search,
        _relatedTracks = relatedTracks {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
    }
  }

  final SearchMusic _search;
  final RelatedMusic _relatedTracks;
  final Duration timeout;

  Future<DiscoveryPage> search(
    String query, {
    String? continuation,
  }) async {
    if (query.trim().isEmpty) {
      throw const DiscoveryException('Enter something to search for.');
    }
    return _run(() => _search(query, continuation));
  }

  Future<DiscoveryPage> relatedTracks(
    String videoId, {
    String? continuation,
  }) =>
      _run(() => _relatedTracks(videoId, continuation));

  Future<DiscoveryPage> _run(Future<DiscoveryPage> Function() request) async {
    try {
      final page = await request().timeout(timeout);
      final identities = <String>{};
      return DiscoveryPage(
        entities: [
          for (final entity in page.entities)
            if (identities.add(entity.identity)) entity,
        ],
        continuation: page.continuation,
      );
    } on TimeoutException {
      throw const DiscoveryException(
        'Music discovery took too long. Please try again.',
      );
    } on DiscoveryException {
      rethrow;
    } catch (_) {
      throw const DiscoveryException(
        'Music discovery is unavailable. Please try again.',
      );
    }
  }
}
