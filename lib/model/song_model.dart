
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

    factory MySongs.fromRawJson(Map<String, dynamic> map) => MySongs.fromJson(map);

    String toRawJson() => json.encode(toJson());

    factory MySongs.fromJson(Map<String, dynamic> json) => MySongs(
        songid: json["songid"],
        title: json["title"],
        songurl: json["songurl"],
        coverurl: json["coverurl"],
        artist: json["artist"],
        isquickpick: json["isquickpick"],
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