import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:music_app/controller/settings_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/data/library_database.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/controller/user_favourite_controller.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/user_favourite_page.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/repositories/library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets(
      'YouTube favourites page loads Nyro library without server user id',
      (tester) async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    await repository.setFavourite(
      TrackRef(
        source: TrackSource.youtube,
        providerId: 'widget-video-id',
        title: 'Saved in Nyro',
        artist: 'Video artist',
      ),
      true,
    );
    Get.put(UserFavouriteController(
      library: repository,
      resolveYoutube: (song) async => song.copyWith(
        songurl: 'https://signed.example/widget-fresh',
      ),
    ));
    Get.put(SongController());
    Get.put<SettingsController>(_TestSettingsController());

    MySongs? preparedForPlayback;
    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: UserFavouritePage(
            sourceOverride: TrackSource.youtube,
            onPreparedPlay: (song) async {
              preparedForPlayback = song;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    for (var frame = 0; frame < 8; frame += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Saved in Nyro'), findsOneWidget);
    expect(find.text('Video artist'), findsOneWidget);
    await tester.tap(find.text('Saved in Nyro'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(preparedForPlayback?.songurl, 'https://signed.example/widget-fresh');
    expect(tester.takeException(), isNull);
  });
}

class _TestSettingsController extends SettingsController {
  @override
  // ignore: must_call_super
  void onInit() {}
}
