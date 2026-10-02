import 'dart:convert';

enum SongSource { local, backend, youtube }

/// Ephemeral playback state. Implementations may hold network clients and must
/// never be serialized.
abstract class SongStreamHandle {
  int get length;
  String get mimeType;
  Stream<List<int>> open();
  void close();
}

class MySongs {
  int songid;
  String title;
  String songurl;
  String coverurl;
  String artist;
  int isquickpick;
  SongSource source;
  String? externalId;
  // Ephemeral metadata for the resolved stream; never serialized.
  int? streamLength;
  String? streamMimeType;
  SongStreamHandle? streamHandle;

  MySongs({
    required this.songid,
    required this.title,
    required this.songurl,
    required this.coverurl,
    required this.artist,
    required this.isquickpick,
    this.source = SongSource.backend,
    this.externalId,
    this.streamLength,
    this.streamMimeType,
    this.streamHandle,
  });

  factory MySongs.youtube({
    required String videoId,
    required String title,
    required String artist,
    required String artworkUrl,
  }) =>
      MySongs(
        songid: 0,
        title: title,
        songurl: '',
        coverurl: artworkUrl,
        artist: artist,
        isquickpick: 0,
        source: SongSource.youtube,
        externalId: videoId,
      );

  bool get isBackend => source == SongSource.backend;
  bool get isLocal => source == SongSource.local;
  bool get isYouTube => source == SongSource.youtube;
  bool get isPlaceholder => isBackend && songid == 0;
  String get identity => switch (source) {
        SongSource.local => 'local:$externalId',
        SongSource.backend => 'backend:$songid',
        SongSource.youtube => 'youtube:$externalId',
      };

  Uri mediaUri(String backendBaseUrl) => _uri(songurl, backendBaseUrl);
  Uri artworkUri(String backendBaseUrl) => _uri(coverurl, backendBaseUrl);

  static Uri _uri(String value, String backendBaseUrl) {
    final uri = Uri.parse(value);
    if (uri.hasScheme) return uri;
    return Uri.parse(backendBaseUrl).resolve(value);
  }

  MySongs copyWith({
    int? songid,
    String? title,
    String? songurl,
    String? coverurl,
    String? artist,
    int? isquickpick,
    SongSource? source,
    String? externalId,
    int? streamLength,
    String? streamMimeType,
    SongStreamHandle? streamHandle,
  }) =>
      MySongs(
        songid: songid ?? this.songid,
        title: title ?? this.title,
        songurl: songurl ?? this.songurl,
        coverurl: coverurl ?? this.coverurl,
        artist: artist ?? this.artist,
        isquickpick: isquickpick ?? this.isquickpick,
        source: source ?? this.source,
        externalId: externalId ?? this.externalId,
        streamLength: streamLength ?? this.streamLength,
        streamMimeType: streamMimeType ?? this.streamMimeType,
        streamHandle: streamHandle ?? this.streamHandle,
      );

  void clear() {
    songid = 0;
    title = '';
    songurl = '';
    coverurl = '';
    artist = '';
    isquickpick = 0;
    source = SongSource.backend;
    externalId = null;
    try {
      streamHandle?.close();
    } finally {
      streamHandle = null;
      streamLength = null;
      streamMimeType = null;
    }
  }

  factory MySongs.fromRawJson(Map<String, dynamic> map) =>
      MySongs.fromJson(map);

  String toRawJson() => json.encode(toJson());

  /// Tolerant of a missing or oddly-typed field, the way `Artist.fromJson`
  /// already was.
  ///
  /// This used to read every key straight out of the map and cast it, so a
  /// single row with a null column — or an `songid` the PHP layer had handed
  /// back as the *string* `"12"`, which it does depending on the driver — threw
  /// while a whole list was being parsed, and took the entire screen to its
  /// error state. One bad row now costs one bad row.
  factory MySongs.fromJson(Map<String, dynamic> json) => MySongs(
        songid: int.tryParse('${json["songid"]}') ?? 0,
        title: json["title"] as String? ?? 'Unknown track',
        songurl: json["songurl"] as String? ?? '',
        coverurl: json["coverurl"] as String? ?? '',
        artist: json["artist"] as String? ?? 'Unknown artist',
        isquickpick: int.tryParse('${json["isquickpick"]}') ?? 0,
        source: SongSource.values.firstWhere(
          (source) => source.name == json['source'],
          orElse: () => SongSource.backend,
        ),
        externalId: json['externalId'] as String?,
      );

  String get _persistentBackendMediaPath {
    if (!isBackend || songurl.isEmpty) return '';
    final uri = Uri.tryParse(songurl);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      return '';
    }
    return songurl;
  }

  Map<String, dynamic> toJson() => {
        "songid": songid,
        "title": title,
        // Current hosted recents need their stable relative PHP media path.
        // Absolute, query-bearing and external stream URLs are runtime-only.
        "songurl": _persistentBackendMediaPath,
        "coverurl": coverurl,
        "artist": artist,
        "isquickpick": isquickpick,
        "source": source.name,
        if (externalId != null) "externalId": externalId,
      };
}
