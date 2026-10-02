import 'package:music_app/model/song_model.dart';

/// Stable music sources used by Nyro's persistent library.
enum TrackSource {
  local,
  nyroServer,
  youtube;

  /// Existing hosted tracks keep their historical `backend:<id>` identity.
  String get storageName => switch (this) {
        TrackSource.local => 'local',
        TrackSource.nyroServer => 'backend',
        TrackSource.youtube => 'youtube',
      };

  String get label => switch (this) {
        TrackSource.local => 'Local',
        TrackSource.nyroServer => 'Nyro Server',
        TrackSource.youtube => 'YouTube',
      };

  static TrackSource parse(Object? value) {
    return switch (value) {
      'local' => TrackSource.local,
      'backend' || 'nyroServer' || 'server' => TrackSource.nyroServer,
      'youtube' => TrackSource.youtube,
      _ => throw FormatException('Unknown track source: $value'),
    };
  }
}

/// Immutable metadata and stable identity suitable for persistence.
///
/// Playback URLs and live stream handles intentionally have no place here.
class TrackRef {
  TrackRef({
    required this.source,
    required String providerId,
    required String title,
    required String artist,
    this.artworkRef,
    this.albumId,
    this.duration,
  })  : providerId = _required(providerId, 'providerId'),
        title = _required(title, 'title'),
        artist = artist.trim().isEmpty ? 'Unknown artist' : artist.trim();

  final TrackSource source;
  final String providerId;
  final String title;
  final String artist;
  final String? artworkRef;
  final String? albumId;
  final Duration? duration;

  String get stableKey => '${source.storageName}:$providerId';

  factory TrackRef.fromSong(MySongs song) {
    final source = switch (song.source) {
      SongSource.local => TrackSource.local,
      SongSource.backend => TrackSource.nyroServer,
      SongSource.youtube => TrackSource.youtube,
    };
    final providerId = switch (song.source) {
      SongSource.backend => song.songid.toString(),
      SongSource.local || SongSource.youtube => song.externalId ?? '',
    };

    return TrackRef(
      source: source,
      providerId: providerId,
      title: song.title,
      artist: song.artist,
      artworkRef: song.coverurl.isEmpty ? null : song.coverurl,
    );
  }

  factory TrackRef.fromJson(Map<String, dynamic> json) {
    final durationMs = json['durationMs'];
    if (durationMs != null && durationMs is! int) {
      throw const FormatException('durationMs must be an integer.');
    }
    if (durationMs is int && durationMs < 0) {
      throw const FormatException('durationMs cannot be negative.');
    }

    try {
      return TrackRef(
        source: TrackSource.parse(json['source']),
        providerId: json['providerId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        artist: json['artist'] as String? ?? 'Unknown artist',
        artworkRef: json['artworkRef'] as String?,
        albumId: json['albumId'] as String?,
        duration: durationMs == null
            ? null
            : Duration(milliseconds: durationMs as int),
      );
    } on TypeError catch (error) {
      throw FormatException('Invalid track metadata.', error);
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString(), error);
    }
  }

  Map<String, dynamic> toJson() => {
        'source': source.storageName,
        'providerId': providerId,
        'title': title,
        'artist': artist,
        if (artworkRef != null) 'artworkRef': artworkRef,
        if (albumId != null) 'albumId': albumId,
        if (duration != null) 'durationMs': duration!.inMilliseconds,
      };

  /// Compatibility adapter for existing screens and the current player.
  ///
  /// The resulting song contains stable metadata only. Playback must resolve a
  /// fresh source-specific URI later.
  MySongs toSong() => switch (source) {
        TrackSource.local => MySongs(
            songid: 0,
            title: title,
            // A persisted MediaStore/SAF content URI is the local track's stable
            // identity and playback locator. Unlike signed network URLs it does
            // not expire and is deliberately source-qualified by [TrackRef].
            songurl: providerId,
            coverurl: artworkRef ?? '',
            artist: artist,
            isquickpick: 0,
            source: SongSource.local,
            externalId: providerId,
          ),
        TrackSource.nyroServer => MySongs(
            songid: int.tryParse(providerId) ?? 0,
            title: title,
            songurl: '',
            coverurl: artworkRef ?? '',
            artist: artist,
            isquickpick: 0,
          ),
        TrackSource.youtube => MySongs.youtube(
            videoId: providerId,
            title: title,
            artist: artist,
            artworkUrl: artworkRef ?? '',
          ),
      };

  static String _required(String value, String name) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }
    return trimmed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackRef &&
          other.source == source &&
          other.providerId == providerId &&
          other.title == title &&
          other.artist == artist &&
          other.artworkRef == artworkRef &&
          other.albumId == albumId &&
          other.duration == duration;

  @override
  int get hashCode => Object.hash(
        source,
        providerId,
        title,
        artist,
        artworkRef,
        albumId,
        duration,
      );
}
