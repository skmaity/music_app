import 'dart:convert';

class MySongs {
  int songid;
  String title;
  String songurl;
  String coverurl;
  String artist;
  int isquickpick;

  MySongs({
    required this.songid,
    required this.title,
    required this.songurl,
    required this.coverurl,
    required this.artist,
    required this.isquickpick,
  });

  MySongs copyWith({
    int? songid,
    String? title,
    String? songurl,
    String? coverurl,
    String? artist,
    int? isquickpick,
  }) =>
      MySongs(
        songid: songid ?? this.songid,
        title: title ?? this.title,
        songurl: songurl ?? this.songurl,
        coverurl: coverurl ?? this.coverurl,
        artist: artist ?? this.artist,
        isquickpick: isquickpick ?? this.isquickpick,
      );

  void clear() {
    songid = 0;
    title = '';
    songurl = '';
    coverurl = '';
    artist = '';
    isquickpick = 0;
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
      );

  Map<String, dynamic> toJson() => {
        "songid": songid,
        "title": title,
        "songurl": songurl,
        "coverurl": coverurl,
        "artist": artist,
        "isquickpick": isquickpick,
      };
}
