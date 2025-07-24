import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:music_app/all_urls.dart';
import 'package:music_app/model/song_model.dart';

class SearchSongController extends GetxController {
  RxList<MySongs> searchSongResult = <MySongs>[].obs;
  RxBool isLoading = false.obs;
  Dio dio = Dio();

  Future searchSong(String query) async {
    isLoading.value = true;

    try {
      searchSongResult.clear();
      String url = "$searchSongsUrl?query=$query";
      Response res = await dio.get(url);
      if (res.statusCode == 200) {
        for (var song in res.data['data']) {
          searchSongResult.add(MySongs.fromJson(song));
        }
      }
    } catch (e) {
      print(e.toString());
    }

    isLoading.value = false;
  }
}
