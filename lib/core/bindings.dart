import 'package:get/get.dart';
import 'package:music_app/controller/artist_controller.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/internet_controller.dart';
import 'package:music_app/controller/nav_controller.dart';
import 'package:music_app/controller/recent_controller.dart';
import 'package:music_app/controller/settings_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/main_nav_pages/page_controller/page_controller.dart';
import 'package:music_app/main_nav_pages/quick_picks/quick_picks_controller.dart';
import 'package:music_app/main_nav_pages/search_songs/controllers/search_song_controller.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/controller/user_favourite_controller.dart';
import 'package:music_app/player_page/player_page_function.dart';
// import 'package:music_app/services/services.dart';

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
    // Get.lazyPut(
    //   () => FireStoreServices(),
    // );
    Get.lazyPut(
      () => PlayerPageFunction(),
    );
    Get.lazyPut(
      () => ArtistController(),
    );
    Get.lazyPut(
      () => PageControllerNavPages(),
    );
    Get.lazyPut(
      () => UserFavouriteController(),
    );
    Get.lazyPut(
      () => NavController(),
    );
    Get.lazyPut(
      () => SearchSongController(),
    );
    Get.lazyPut(
      () => SettingsController(),
    );
    Get.lazyPut(
      () => RecentController(),
    );
  }
}
