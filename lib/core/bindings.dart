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
import 'package:music_app/services/local_media_index.dart';
import 'package:music_app/services/local_music_provider.dart';
import 'package:music_app/services/music_provider.dart';
import 'package:music_app/services/playback_resolver.dart';
import 'package:music_app/services/radio_discovery_adapter.dart';
import 'package:music_app/services/youtube_music_discovery.dart';
import 'package:music_app/services/youtube_related_provider.dart';
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
    Get.lazyPut<LocalMediaIndex>(
      () => LocalMediaIndex(gateway: AndroidMediaStoreGateway()),
    );
    Get.lazyPut<LocalMusicProvider>(() {
      final index = Get.find<LocalMediaIndex>();
      return LocalMusicProvider(
        loadSongs: () async => (await index.refresh()).tracks,
        searchSongs: (query) async {
          if (index.tracks.isEmpty) await index.refresh();
          return index.search(query);
        },
      );
    });
    Get.lazyPut<YoutubeMusicProvider>(() => YoutubeMusicProvider());
    Get.lazyPut(
      () => MusicSourceController(
        navigation: Get.find<NavController>(),
        loadSavedSource: () =>
            _loadBrowsingSource(Get.find<LibraryRepository>()),
        saveSource: (source) =>
            Get.find<LibraryRepository>().setSourcePreference(
          TrackSource.nyroServer,
          _browsingSourcePreferenceKey,
          source.storageName,
        ),
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
      () => _buildSongController(),
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
        resolveYoutube: (song) =>
            Get.find<SearchSongController>().youtube.resolve(song),
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

SongController _buildSongController() {
  final related = YouTubeRelatedProvider();
  final discovery = YouTubeMusicDiscovery(
    timeout: const Duration(seconds: 18),
    search: (_, __) => Future.error(
      UnsupportedError('Radio discovery does not provide search.'),
    ),
    relatedTracks: related.fetch,
  );
  return SongController(
    history: Get.find<RecentController>(),
    library: Get.find<LibraryRepository>(),
    playbackResolver: PlaybackResolver(
      resolveYoutube: (track) =>
          Get.find<SearchSongController>().youtube.resolve(track.toSong()),
    ),
    radioFetch: radioDiscoveryAdapter(discovery),
    closeRadioDiscovery: related.close,
  );
}

const _browsingSourcePreferenceKey = 'selected_browsing_source';

Future<TrackSource?> _loadBrowsingSource(LibraryRepository repository) async {
  final saved = await repository.sourcePreference(
    TrackSource.nyroServer,
    _browsingSourcePreferenceKey,
  );
  if (saved == null) return null;
  try {
    return TrackSource.parse(saved);
  } on FormatException {
    return null;
  }
}
