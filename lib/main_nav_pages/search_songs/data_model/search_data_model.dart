// To parse this JSON data, do
//
//     final searchDataModel = searchDataModelFromJson(jsonString);

import 'dart:convert';

import 'package:music_app/model/song_model.dart';

SearchDataModel searchDataModelFromJson(String str) =>
    SearchDataModel.fromJson(json.decode(str));

String searchDataModelToJson(SearchDataModel data) =>
    json.encode(data.toJson());

class SearchDataModel {
  final bool success;
  final List<MySongs> data;

  SearchDataModel({
    required this.success,
    required this.data,
  });

  SearchDataModel copyWith({
    bool? success,
    List<MySongs>? data,
  }) =>
      SearchDataModel(
        success: success ?? this.success,
        data: data ?? this.data,
      );

  factory SearchDataModel.fromJson(Map<String, dynamic> json) =>
      SearchDataModel(
        success: json["success"],
        data: List<MySongs>.from(json["data"].map((x) => MySongs.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}
