import 'dart:convert';

import 'package:music_app/model/song_model.dart';

class Quickpicksresponce {
    final bool success;
    final List<MySongs> data;

    Quickpicksresponce({
        required this.success,
        required this.data,
    });

    Quickpicksresponce copyWith({
        bool? success,
        List<MySongs>? data,
    }) =>  
        Quickpicksresponce(
            success: success ?? this.success,
            data: data ?? this.data,
        );

    factory Quickpicksresponce.fromRawJson(Map<String, dynamic> map) => Quickpicksresponce.fromJson(map);

    String toRawJson() => json.encode(toJson());

    factory Quickpicksresponce.fromJson(Map<String, dynamic> json) => Quickpicksresponce(
        success: json["success"],
        data: List<MySongs>.from(json["data"].map((x) => MySongs.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

