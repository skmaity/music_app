import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/model/user_favourites_model.dart';
import 'package:music_app/model/song_model.dart';

class UserFavouriteController extends GetxController {
  Dio dio = Dio();

  RxList<MySongs> userFavoutitesList = <MySongs>[].obs;

  Future<void> getUserFavourites(String userId) async {
    Map<String, dynamic> payLoad = {"userid": userId};
    final response = await dio.get(getAllUserFavoiritesUrl, data: payLoad);
    if (response.statusCode == 200) {
      userFavoutitesList.value =
          userFavouritesModelFromJson(jsonEncode(response.data)).favorites;
    }
  }
}
