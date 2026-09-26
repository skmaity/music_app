import 'package:music_app/model/track_ref.dart';

class ArtistRef {
  const ArtistRef({
    required this.source,
    required this.providerId,
    required this.name,
    this.artworkRef,
  });

  final TrackSource source;
  final String providerId;
  final String name;
  final String? artworkRef;

  String get stableKey => '${source.storageName}:artist:$providerId';
}

class AlbumRef {
  const AlbumRef({
    required this.source,
    required this.providerId,
    required this.title,
    required this.artist,
    this.artworkRef,
    this.year,
  });

  final TrackSource source;
  final String providerId;
  final String title;
  final String artist;
  final String? artworkRef;
  final int? year;

  String get stableKey => '${source.storageName}:album:$providerId';
}

/// A Nyro-owned playlist can contain ordered tracks from different sources.
class PlaylistRef {
  const PlaylistRef({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
}
