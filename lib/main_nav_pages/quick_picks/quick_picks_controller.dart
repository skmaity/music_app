import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/main_nav_pages/quick_picks/models/quick_picks_model.dart';
import 'package:music_app/model/song_model.dart';

class QuickPicksController extends GetxController {

  RxList<MySongs> quickpicks = <MySongs>[].obs;

  /// Starts true so the first frame shows the skeleton, not the empty state.
  RxBool isLoading = true.obs;

  /// A failed request is not an empty list. Without this the two rendered
  /// identically and the user could not tell whether retrying was worth it.
  RxBool hasError = false.obs;

  Future<void> getQuickPicks() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final response = await api.get(quickPicksUrl);
      if (response.statusCode == 200) {
        quickpicks.value = Quickpicksresponce.fromRawJson(response.data).data;
      } else {
        hasError.value = true;
      }
    } catch (e) {
      debugPrint('Failed to load quick picks: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
