import 'dart:convert';

import 'package:music_app/model/song_model.dart';

UserFavouritesModel userFavouritesModelFromJson(String str) =>
    UserFavouritesModel.fromJson(json.decode(str));

String userFavouritesModelToJson(UserFavouritesModel data) =>
    json.encode(data.toJson());

class UserFavouritesModel {
  final bool success;
  final List<MySongs> favorites;

  UserFavouritesModel({
    required this.success,
    required this.favorites,
  });

  UserFavouritesModel copyWith({
    bool? success,
    List<MySongs>? favorites,
  }) =>
      UserFavouritesModel(
        success: success ?? this.success,
        favorites: favorites ?? this.favorites,
      );

  factory UserFavouritesModel.fromJson(Map<String, dynamic> json) =>
      UserFavouritesModel(
        success: json["success"],
        favorites: List<MySongs>.from(
            json["favorites"].map((x) => MySongs.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "favorites": List<dynamic>.from(favorites.map((x) => x.toJson())),
      };
}
