import 'dart:convert';

List<MySongs> mySongsFromJson(String str) => List<MySongs>.from(json.decode(str).map((x) => MySongs.fromJson(x)));

String mySongsToJson(List<MySongs> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class MySongs {
    String artist;
    String cover;
    String song;
    String title;

    MySongs({
        required this.artist,
        required this.cover,
        required this.song,
        required this.title,
    });

    factory MySongs.fromJson(Map<String, dynamic> json) => MySongs(
        artist: json["artist"],
        cover: json["cover"],
        song: json["song"],
        title: json["title"],
    );

    Map<String, dynamic> toJson() => {
        "artist": artist,
        "cover": cover,
        "song": song,
        "title": title,
    };
}
