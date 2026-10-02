import 'package:music_app/controller/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/main_nav_pages/search_songs/controllers/search_song_controller.dart';
import 'package:music_app/main_nav_pages/search_songs/songs.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/youtube_source.dart';

class TestPlayer extends SongController {
  TrackRef? requestedSeed;
  @override
  Future<void> playRadioSeed(TrackRef seed) async {
    requestedSeed = seed;
  }

  @override
  // Test double deliberately skips plugin/persistence initialization.
  // ignore: must_call_super
  void onInit() {}
  @override
  void onClose() {}
}

class DeniedPlayer extends TestPlayer {
  @override
  Future<void> playRadioSeed(TrackRef seed) async {
    throw const YouTubeSourceException('Fixture denied');
  }
}

class TestSettings extends SettingsController {
  @override
  // Test double deliberately skips plugin/persistence initialization.
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  testWidgets('YouTube search tap passes stable seed to the player',
      (tester) async {
    Get.testMode = true;
    Get.put<SettingsController>(TestSettings()..reducedMotion.value = true);
    final search = SearchSongController(
      youtube: YouTubeSource(
        search: (_) async => [
          MySongs.youtube(
            videoId: 'seed',
            title: 'Seed song',
            artist: 'Artist',
            artworkUrl: '',
          ),
        ],
        resolve: (_) async => Uri.parse('https://example.com/audio'),
      ),
    )..selectSource(SearchSource.youtube);
    Get.put(search);
    final player = Get.put<SongController>(TestPlayer());
    await search.searchSong('seed');
    await tester
        .pumpWidget(const GetMaterialApp(home: Scaffold(body: SearchSongs())));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Seed song'));
    await tester.pump(const Duration(seconds: 1));
    expect((player as TestPlayer).requestedSeed?.stableKey, 'youtube:seed');
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
  });

  testWidgets(
      'YouTube entry explains preview and preserves queue on denied audio',
      (tester) async {
    Get.testMode = true;
    Get.put<SettingsController>(TestSettings()..reducedMotion.value = true);
    final source = YouTubeSource(
        search: (_) async => [
              MySongs.youtube(
                  videoId: 'aqz-KE-bpKQ',
                  title: 'Public fixture',
                  artist: 'Blender',
                  artworkUrl: '')
            ],
        resolve: (_) async =>
            throw const YouTubeSourceException('Fixture denied'));
    final search = SearchSongController(youtube: source)
      ..selectSource(SearchSource.youtube);
    Get.put(search);
    final player = Get.put<SongController>(DeniedPlayer());
    await search.searchSong('fixture');
    await tester
        .pumpWidget(const GetMaterialApp(home: Scaffold(body: SearchSongs())));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Experimental'), findsOneWidget);
    await tester.tap(find.text('Public fixture'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Fixture denied'), findsOneWidget);
    expect(player.currentPlayingList, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
  });
}
