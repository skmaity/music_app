import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:music_app/controller/music_source_controller.dart';
import 'package:music_app/controller/nav_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/dashboard_page.dart';
import 'package:music_app/global_widgets/music_source_selector.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/user_favourite_page.dart';
import 'package:music_app/main_nav_pages/search_songs/controllers/search_song_controller.dart';
import 'package:music_app/model/source_capabilities.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/backend_music_provider.dart';
import 'package:music_app/services/local_music_provider.dart';
import 'package:music_app/services/music_provider.dart';
import 'package:music_app/services/youtube_music_provider.dart';
import 'package:music_app/services/youtube_source.dart';

void main() {
  tearDown(Get.reset);

  test('stable destination state is remembered independently per source', () {
    final navigation = NavController();

    navigation.go(AppDestination.artists);
    navigation.activateSource(TrackSource.youtube);
    expect(navigation.current.value, AppDestination.quickPicks);

    navigation.go(AppDestination.songs);
    navigation.activateSource(TrackSource.local);
    navigation.go(AppDestination.library);

    navigation.activateSource(TrackSource.nyroServer);
    expect(navigation.current.value, AppDestination.artists);
    navigation.activateSource(TrackSource.youtube);
    expect(navigation.current.value, AppDestination.songs);
    navigation.activateSource(TrackSource.local);
    expect(navigation.current.value, AppDestination.quickPicks);

    expect(AppDestination.library.stableId, 'library');
    expect(AppDestination.downloads.stableId, 'downloads');
  });

  test('favourites destination routes only remote sources', () {
    for (final source in [TrackSource.nyroServer, TrackSource.youtube]) {
      final page = dashboardPageFor(source, AppDestination.favourites);

      expect(page, isA<UserFavouritePage>());
      expect((page as UserFavouritePage).sourceOverride, source);
    }
    expect(
      () => dashboardPageFor(TrackSource.local, AppDestination.favourites),
      throwsUnsupportedError,
    );
  });

  test('source switching does not own or mutate active playback', () {
    final navigation = NavController();
    final controller = MusicSourceController(
      providers: _providers(),
      navigation: navigation,
    );
    final player = SongController();
    player.currentPlaying.value = MySongs.youtube(
      videoId: 'still-playing',
      title: 'Playing',
      artist: 'Artist',
      artworkUrl: '',
    );

    controller.selectSource(TrackSource.local);

    expect(controller.selectedSource.value, TrackSource.local);
    expect(player.currentPlaying.value.identity, 'youtube:still-playing');
  });

  test('late search results cannot cross a real browsing-source switch',
      () async {
    final delayedYouTube = Completer<List<MySongs>>();
    final controller = SearchSongController(
      youtube: YouTubeSource(search: (_) => delayedYouTube.future),
      loadCatalogue: () async => [_serverSong(31)],
    )..selectSource(SearchSource.youtube);

    final staleRequest = controller.searchSong('old source');
    controller.selectSource(SearchSource.catalogue);
    await controller.loadDefaultSongs();

    delayedYouTube.complete([
      MySongs.youtube(
        videoId: 'stale',
        title: 'Stale result',
        artist: 'Artist',
        artworkUrl: '',
      ),
    ]);
    await staleRequest;

    expect(controller.selectedSource.value, SearchSource.catalogue);
    expect(controller.searchSongResult.single.identity, 'backend:31');
    controller.onClose();
  });

  test('controller rejects a provider registry missing any source', () {
    final providers = _providers()..remove(TrackSource.local);

    expect(
      () => MusicSourceController(providers: providers),
      throwsArgumentError,
    );
  });

  test('non-default initial source synchronizes navigation ownership', () {
    final navigation = NavController()..go(AppDestination.artists);
    final controller = MusicSourceController(
      providers: _providers(),
      navigation: navigation,
      initialSource: TrackSource.local,
    );

    expect(controller.selectedSource.value, TrackSource.local);
    expect(navigation.current.value, AppDestination.quickPicks);
    navigation.go(AppDestination.library);
    expect(navigation.current.value, AppDestination.quickPicks);

    controller.selectSource(TrackSource.nyroServer);
    expect(navigation.current.value, AppDestination.artists);
    controller.selectSource(TrackSource.local);
    expect(navigation.current.value, AppDestination.quickPicks);
  });

  test('first-time browsing defaults to YouTube', () {
    final controller = MusicSourceController(providers: _providers());

    expect(controller.selectedSource.value, TrackSource.youtube);
  });

  test('saved source restores but cannot override a newer user selection',
      () async {
    final savedSource = Completer<TrackSource?>();
    final persisted = <TrackSource>[];
    final controller = MusicSourceController(
      providers: _providers(),
      loadSavedSource: () => savedSource.future,
      saveSource: (source) async => persisted.add(source),
    );

    final restore = controller.restoreSelection();
    controller.selectSource(TrackSource.local);
    savedSource.complete(TrackSource.nyroServer);
    await restore;

    expect(controller.selectedSource.value, TrackSource.local);
    expect(persisted, [TrackSource.local]);
  });

  testWidgets('selector exposes all sources and changes browsing source',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = MusicSourceController(providers: _providers());
    Get.put(controller);

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: MusicSourceSelector())),
    );

    expect(find.text('Local'), findsOneWidget);
    expect(find.text('Nyro Server'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Local'));
    await tester.pump();

    expect(controller.selectedSource.value, TrackSource.local);
    expect(tester.takeException(), isNull);
  });

  test('provider adapters preserve source identity and honest capabilities',
      () async {
    final server = BackendMusicProvider(
      loadSongs: () async => [_serverSong(21)],
      loadQuickPicks: () async => [_serverSong(22)],
      searchSongs: (_) async => [_serverSong(23)],
    );
    final local = LocalMusicProvider(
      loadSongs: () async => [
        TrackRef(
          source: TrackSource.local,
          providerId: 'external:media:1',
          title: 'Local',
          artist: 'Artist',
        ),
      ],
    );
    final youtubeSource = YouTubeSource(
      search: (_) async => [
        MySongs.youtube(
          videoId: 'yt-1',
          title: 'YouTube',
          artist: 'Artist',
          artworkUrl: '',
        ),
      ],
    );
    final youtube = YoutubeMusicProvider(sourceClient: youtubeSource);
    addTearDown(youtube.close);

    expect((await server.loadSongs()).items.single.stableKey, 'backend:21');
    expect((await local.loadSongs()).items.single.stableKey,
        'local:external:media:1');
    expect((await youtube.search('fixture')).items.single.stableKey,
        'youtube:yt-1');
    expect(server.requiresInternet, isTrue);
    expect(local.requiresInternet, isFalse);
    expect(
      server.capabilities.supports(MusicCapability.albumBrowse),
      isFalse,
    );
    expect(
      youtube.capabilities.supports(MusicCapability.relatedTracks),
      isFalse,
    );
    expect(
      youtube.capabilities
          .status(MusicCapability.relatedTracks)
          .unavailableReason,
      isNotEmpty,
    );
  });
}

MySongs _serverSong(int id) => MySongs(
      songid: id,
      title: 'Server $id',
      songurl: '/$id.mp3',
      coverurl: '',
      artist: 'Artist',
      isquickpick: 0,
    );

Map<TrackSource, MusicProvider> _providers() {
  return {
    TrackSource.local: _FakeProvider(TrackSource.local),
    TrackSource.nyroServer: _FakeProvider(TrackSource.nyroServer),
    TrackSource.youtube: _FakeProvider(TrackSource.youtube),
  };
}

class _FakeProvider implements MusicProvider {
  _FakeProvider(this.source);

  @override
  final TrackSource source;

  @override
  SourceCapabilities get capabilities => SourceCapabilities(
        source: source,
        statuses: {
          for (final capability in MusicCapability.values)
            capability: const CapabilityStatus.available(),
        },
      );

  @override
  bool get requiresInternet => source != TrackSource.local;

  @override
  Future<MusicProviderPage> loadSongs({String? continuation}) =>
      Future.value(const MusicProviderPage(items: []));

  @override
  Future<MusicProviderPage> quickPicks({String? continuation}) =>
      loadSongs(continuation: continuation);

  @override
  Future<MusicProviderPage> search(
    String query, {
    String? continuation,
  }) =>
      loadSongs(continuation: continuation);

  @override
  void close() {}
}
