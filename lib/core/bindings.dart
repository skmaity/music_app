import 'package:get/get.dart';
import 'package:music_app/data/library_database.dart';
import 'package:music_app/controller/artist_controller.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/internet_controller.dart';
import 'package:music_app/controller/music_source_controller.dart';
import 'package:music_app/controller/nav_controller.dart';
import 'package:music_app/controller/recent_controller.dart';
import 'package:music_app/controller/settings_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/main_nav_pages/page_controller/page_controller.dart';
import 'package:music_app/main_nav_pages/quick_picks/quick_picks_controller.dart';
import 'package:music_app/main_nav_pages/search_songs/controllers/search_song_controller.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/controller/user_favourite_controller.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/player_page/player_page_function.dart';
import 'package:music_app/repositories/library_repository.dart';
import 'package:music_app/services/backend_music_provider.dart';
import 'package:music_app/services/local_music_provider.dart';
import 'package:music_app/services/music_provider.dart';
import 'package:music_app/services/youtube_music_provider.dart';
// import 'package:music_app/services/services.dart';

class InitialScreenBindings implements Bindings {
  InitialScreenBindings();

  @override
  void dependencies() {
    Get.lazyPut(() => LibraryDatabase.open());
    Get.lazyPut(() => LibraryRepository(Get.find<LibraryDatabase>()));
    Get.lazyPut(() => NavController());
    Get.lazyPut<BackendMusicProvider>(() => BackendMusicProvider());
    Get.lazyPut<LocalMusicProvider>(() => LocalMusicProvider());
    Get.lazyPut<YoutubeMusicProvider>(() => YoutubeMusicProvider());
    Get.lazyPut(
      () => MusicSourceController(
        navigation: Get.find<NavController>(),
        providers: <TrackSource, MusicProvider>{
          TrackSource.local: Get.find<LocalMusicProvider>(),
          TrackSource.nyroServer: Get.find<BackendMusicProvider>(),
          TrackSource.youtube: Get.find<YoutubeMusicProvider>(),
        },
      ),
    );
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
      () => UserFavouriteController(
        library: Get.find<LibraryRepository>(),
      ),
    );

    Get.lazyPut(
      () => SearchSongController(),
    );
    Get.lazyPut(
      () => SettingsController(),
    );
    Get.lazyPut(
      () => RecentController(
        library: Get.find<LibraryRepository>(),
      ),
    );
  }
}
