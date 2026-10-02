import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:music_app/data/library_database.dart';
import 'package:music_app/controller/settings_controller.dart';
import 'package:music_app/global_widgets/song_actions_sheet.dart';
import 'package:music_app/main_nav_pages/playlists/playlists.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/repositories/library_repository.dart';

void main() {
  testWidgets('YouTube song actions offer Add to playlist', (tester) async {
    Get.testMode = true;
    addTearDown(Get.reset);
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    Get.put<LibraryRepository>(repository);
    Get.put(SettingsController());
    await repository.createPlaylist(id: 'actions-mix', name: 'Road mix');
    final song = MySongs.youtube(
      videoId: 'action-video',
      title: 'Action track',
      artist: 'Action artist',
      artworkUrl: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSongActionsSheet(context, song),
              child: const Text('Open actions'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open actions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Add to playlist'), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pump();
    await tester.tap(find.text('Add to playlist'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Road mix'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final entries = await repository.listPlaylistEntries('actions-mix');
    expect(entries, hasLength(1));
    expect(entries.single.track.stableKey, 'youtube:action-video');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Local song actions omit Library controls', (tester) async {
    Get.testMode = true;
    addTearDown(Get.reset);
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    Get.put<LibraryRepository>(LibraryRepository(database));
    Get.put(SettingsController());
    final song = MySongs(
      songid: 0,
      title: 'Device track',
      songurl: 'content://media/external/audio/media/4',
      coverurl: '',
      artist: 'Device artist',
      isquickpick: 0,
      source: SongSource.local,
      externalId: 'content://media/external/audio/media/4',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSongActionsSheet(context, song),
              child: const Text('Open actions'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open actions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Add to playlist'), findsNothing);
    expect(find.textContaining('save this track'), findsNothing);
  });

  testWidgets('Library shows remote-source playlist at 320px', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    await repository.createPlaylist(id: 'road-mix', name: 'Road mix');
    await repository.addPlaylistEntry(
      entryId: 'server-entry',
      playlistId: 'road-mix',
      track: TrackRef(
        source: TrackSource.nyroServer,
        providerId: '4',
        title: 'Server track',
        artist: 'Server artist',
      ),
      position: 0,
    );
    await repository.addPlaylistEntry(
      entryId: 'youtube-entry',
      playlistId: 'road-mix',
      track: TrackRef(
        source: TrackSource.youtube,
        providerId: 'video-id',
        title: 'YouTube track',
        artist: 'Video artist',
      ),
      position: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: Playlists(repository: repository)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Road mix'), findsOneWidget);
    expect(find.text('2 songs'), findsOneWidget);

    await tester.tap(find.text('Road mix'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Server track'), findsOneWidget);
    expect(find.text('YouTube track'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Nyro Server'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'YouTube'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-400, 0),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, 'YouTube'));
    await tester.pump();
    expect(find.text('Local track'), findsNothing);
    expect(find.text('YouTube track'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
