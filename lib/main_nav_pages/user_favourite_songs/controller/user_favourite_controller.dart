import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/controller/userid_controller.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/model/user_favourites_model.dart';
import 'package:music_app/model/song_model.dart';

class UserFavouriteController extends GetxController {

  RxList<MySongs> userFavoutitesList = <MySongs>[].obs;

  /// Starts true so the first frame shows the skeleton, not the empty state.
  RxBool isLoading = true.obs;

  /// A failed request is not an empty list. "You have no favourites" and "the
  /// request failed" used to be pixel-identical.
  RxBool hasError = false.obs;

  /// The id is resolved here rather than passed in: it is loaded from disk, and
  /// every caller that read it off the observable risked sending an empty one
  /// and getting "Missing userid" back.
  Future<void> getUserFavourites() async {
    isLoading.value = true;
    hasError.value = false;
    final payLoad = {"userid": await Get.find<UseridController>().id};
    try {
      // Must be POST: the host returns 403 for a GET carrying a body.
      final response = await api.post(getAllUserFavoiritesUrl, data: payLoad);
      if (response.statusCode == 200) {
        userFavoutitesList.value =
            userFavouritesModelFromJson(jsonEncode(response.data)).favorites;
      } else {
        hasError.value = true;
      }
    } catch (e) {
      debugPrint('Failed to load favourites: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
