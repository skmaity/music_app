import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:music_app/all_urls.dart';
import 'package:music_app/main_nav_pages/quick_picks/models/quick_picks_model.dart';
import 'package:music_app/model/song_model.dart';

class QuickPicksController extends GetxController {

  Dio dio = Dio();

  RxList<MySongs> quickpicks = <MySongs>[].obs;


  getQuickPicks() async {
    final response = await dio.get(quickPicksUrl); 
if (response.statusCode == 200) {
   quickpicks.value = Quickpicksresponce.fromRawJson(response.data).data; 
}
  }
}
