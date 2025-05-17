import 'package:get/get.dart';
import 'package:music_app/controller/artist_controller.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/internet_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/main_nav_pages/page_controller/page_controller.dart';
import 'package:music_app/main_nav_pages/quick_picks/quick_picks_controller.dart';
import 'package:music_app/player_page_function.dart';
import 'package:music_app/services/services.dart';

class InitialScreenBindings implements Bindings {
  InitialScreenBindings();

  @override
  void dependencies() {
    Get.lazyPut(
      () => QuickPicksController(),
    );
    Get.lazyPut(
      () => BackgroundController(),
    );
    Get.lazyPut(
      () => InternetController(),
    );
    Get.lazyPut(
      () => SongController(),
    );
    Get.lazyPut(
      () => FireStoreServices(),
    );
    Get.lazyPut(
      () => PlayerPageFunction(),
    );
    Get.lazyPut(
      () => ArtistController(),
    );
    Get.lazyPut(
      () => PageControllerNavPages(),
    );
  }
}
