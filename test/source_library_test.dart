import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/controller/recent_controller.dart';
import 'package:music_app/data/library_database.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/controller/user_favourite_controller.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/repositories/library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  test('YouTube favourite action stores stable metadata without stream URL',
      () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    Get.put(repository);
    final controller = SongController();
    addTearDown(controller.player.dispose);
    controller.currentPlaying.value = MySongs.youtube(
      videoId: 'durable-video-id',
      title: 'Saved YouTube track',
      artist: 'Artist',
      artworkUrl: 'https://img.example/cover.jpg',
    ).copyWith(songurl: 'https://signed.example/expiring-audio');

    final error = await controller.toggleFavourite();
    final saved = await repository.listFavourites(
      source: TrackSource.youtube,
    );

    expect(error, isNull);
    expect(controller.isFavourite.value, isTrue);
    expect(saved.single.providerId, 'durable-video-id');
    expect(saved.single.toSong().songurl, isEmpty);
  });

  test('Local songs cannot be added to favourites', () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    final controller = SongController(library: repository);
    addTearDown(controller.player.dispose);
    controller.currentPlaying.value = MySongs(
      songid: 0,
      songurl: 'content://media/external/audio/media/7',
      coverurl: '',
      title: 'Device song',
      artist: 'Device artist',
      isquickpick: 0,
      source: SongSource.local,
      externalId: 'content://media/external/audio/media/7',
    );

    final error = await controller.toggleFavourite();

    expect(error, 'Local favourites are not available yet.');
    expect(await repository.listFavourites(), isEmpty);
  });

  test('Local playback does not enter Library history', () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    final recent = RecentController(library: repository);
    final song = MySongs(
      songid: 0,
      songurl: 'content://media/external/audio/media/8',
      coverurl: '',
      title: 'Device song',
      artist: 'Device artist',
      isquickpick: 0,
      source: SongSource.local,
      externalId: 'content://media/external/audio/media/8',
    );

    recent.trackChanged(
      song,
      previousCompleted: false,
      previousEarlySkip: false,
    );
    recent.playbackStarted(song);
    recent.positionChanged(song, const Duration(seconds: 12));
    recent.playbackCompleted(song);
    await recent.historyIdle;

    expect(await repository.listListeningEvents(), isEmpty);
  });

  test('YouTube favourites reload through controller after database restart',
      () async {
    final directory = await Directory.systemTemp.createTemp('nyro-source-lib-');
    final file = File('${directory.path}/library.sqlite');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final firstDatabase = LibraryDatabase(NativeDatabase(file));
    await LibraryRepository(firstDatabase).setFavourite(
      TrackRef(
        source: TrackSource.youtube,
        providerId: 'restart-video-id',
        title: 'Restart favourite',
        artist: 'Artist',
      ),
      true,
    );
    await firstDatabase.close();

    final reopenedDatabase = LibraryDatabase(NativeDatabase(file));
    addTearDown(reopenedDatabase.close);
    final controller = UserFavouriteController(
      library: LibraryRepository(reopenedDatabase),
    );

    await controller.loadFavourites(TrackSource.youtube);

    expect(controller.hasError.value, isFalse);
    expect(controller.userFavoutitesList.single.identity,
        'youtube:restart-video-id');
    expect(controller.userFavoutitesList.single.songurl, isEmpty);
  });

  test('duplicate queue entries are separate playback occurrences', () {
    final controller = SongController();
    addTearDown(controller.player.dispose);
    final firstOccurrence = Object();
    final secondOccurrence = Object();

    expect(controller.registerPlaybackOccurrence(firstOccurrence), isTrue);
    expect(controller.registerPlaybackOccurrence(firstOccurrence), isFalse);
    expect(controller.registerPlaybackOccurrence(secondOccurrence), isTrue);
  });

  test('listening history waits for actual playback and stores progress',
      () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    final recent = RecentController(library: repository);
    final song = MySongs.youtube(
      videoId: 'history-video-id',
      title: 'Actually played',
      artist: 'History artist',
      artworkUrl: '',
    );

    recent.trackChanged(
      song,
      previousCompleted: false,
      previousEarlySkip: false,
    );
    await recent.historyIdle;
    expect(await repository.listListeningEvents(), isEmpty);

    recent.playbackStarted(song);
    recent.positionChanged(song, const Duration(seconds: 17));
    recent.playbackCompleted(song);
    await recent.historyIdle;

    final events = await repository.listListeningEvents();
    expect(events, hasLength(1));
    expect(events.single.track.stableKey, 'youtube:history-video-id');
    expect(events.single.listened, const Duration(seconds: 17));
    expect(events.single.completed, isTrue);
    expect(events.single.earlySkip, isFalse);
  });

  test('late favourite write cannot change the next track heart', () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = _DelayedFavouriteWriteRepository(database);
    final controller = SongController(library: repository);
    addTearDown(controller.player.dispose);
    final first = MySongs.youtube(
      videoId: 'first-toggle',
      title: 'First',
      artist: 'Artist',
      artworkUrl: '',
    );
    final second = MySongs.youtube(
      videoId: 'second-toggle',
      title: 'Second',
      artist: 'Artist',
      artworkUrl: '',
    );
    controller.currentPlaying.value = first;
    controller.isFavourite.value = true;

    final toggle = controller.toggleFavourite();
    controller.currentPlaying.value = second;
    controller.isFavourite.value = true;
    repository.write.complete();
    await toggle;

    expect(controller.currentPlaying.value.identity, second.identity);
    expect(controller.isFavourite.value, isTrue);
  });

  test('different tracks can toggle favourites concurrently', () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = _ControlledFavouriteWriteRepository(database);
    final controller = SongController(library: repository);
    addTearDown(controller.player.dispose);
    final first = MySongs.youtube(
      videoId: 'concurrent-first',
      title: 'First',
      artist: 'Artist',
      artworkUrl: '',
    );
    final second = MySongs.youtube(
      videoId: 'concurrent-second',
      title: 'Second',
      artist: 'Artist',
      artworkUrl: '',
    );

    controller.currentPlaying.value = first;
    controller.isFavourite.value = false;
    final firstToggle = controller.toggleFavourite();
    controller.currentPlaying.value = second;
    controller.isFavourite.value = false;
    final secondToggle = controller.toggleFavourite();

    expect(repository.requests, [first.identity, second.identity]);
    repository.writes[first.identity]!.complete();
    repository.writes[second.identity]!.complete();
    await Future.wait([firstToggle, secondToggle]);

    expect(controller.currentPlaying.value.identity, second.identity);
    expect(controller.isFavourite.value, isTrue);
  });

  test('pre-toggle status refresh cannot undo a successful toggle', () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = _DelayedFavouriteStatusRepository(database);
    final controller = SongController(library: repository);
    addTearDown(controller.player.dispose);
    final song = MySongs.youtube(
      videoId: 'refresh-race',
      title: 'Refresh race',
      artist: 'Artist',
      artworkUrl: '',
    );
    controller.currentPlaying.value = song;
    controller.isFavourite.value = false;

    final staleRefresh = controller.refreshFavouriteStatusForSong(song);
    expect(await controller.toggleFavourite(), isNull);
    expect(controller.isFavourite.value, isTrue);
    repository.status.complete(false);
    await staleRefresh;

    expect(controller.isFavourite.value, isTrue);
  });

  test('player heart reflects a persisted YouTube favourite', () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    final song = MySongs.youtube(
      videoId: 'hearted-video',
      title: 'Hearted',
      artist: 'Artist',
      artworkUrl: '',
    );
    await repository.setFavourite(TrackRef.fromSong(song), true);
    final player = SongController(library: repository);
    addTearDown(player.player.dispose);
    player.currentPlaying.value = song;

    await player.refreshFavouriteStatusForSong(song);

    expect(player.isFavourite.value, isTrue);
  });

  test('buffering intent does not create listening history', () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    final recent = RecentController(library: repository);
    final player = SongController(history: recent);
    addTearDown(player.player.dispose);
    final song = MySongs.youtube(
      videoId: 'buffering-video',
      title: 'Buffering',
      artist: 'Artist',
      artworkUrl: '',
    );
    recent.trackChanged(
      song,
      previousCompleted: false,
      previousEarlySkip: false,
    );

    player.recordPlaybackProgressForHistory(
      song,
      const Duration(seconds: 4),
      playing: true,
      ready: false,
    );
    recent.playbackCompleted(song);
    await recent.historyIdle;
    expect(await repository.listListeningEvents(), isEmpty);

    player.recordPlaybackProgressForHistory(
      song,
      const Duration(seconds: 1),
      playing: true,
      ready: true,
    );
    recent.playbackCompleted(song);
    await recent.historyIdle;
    expect(await repository.listListeningEvents(), hasLength(1));
  });

  test('playlist CRUD preserves remote-source order and duplicate entries',
      () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    final server = TrackRef(
      source: TrackSource.nyroServer,
      providerId: '4',
      title: 'Server track',
      artist: 'Server artist',
    );
    final youtube = TrackRef(
      source: TrackSource.youtube,
      providerId: 'playlist-video',
      title: 'YouTube track',
      artist: 'Video artist',
    );

    await repository.createPlaylist(id: 'mix', name: ' Road mix ');
    await repository.addPlaylistEntry(
      entryId: 'server-1',
      playlistId: 'mix',
      track: server,
      position: 0,
    );
    await repository.addPlaylistEntry(
      entryId: 'youtube-1',
      playlistId: 'mix',
      track: youtube,
      position: 1,
    );
    await repository.addPlaylistEntry(
      entryId: 'youtube-2',
      playlistId: 'mix',
      track: youtube,
      position: 2,
    );

    expect((await repository.listPlaylists()).single.name, 'Road mix');
    expect(
      (await repository.listPlaylistEntries('mix'))
          .map((entry) => entry.track.stableKey),
      [
        'backend:4',
        'youtube:playlist-video',
        'youtube:playlist-video',
      ],
    );

    await repository.renamePlaylist('mix', ' Evening mix ');
    await repository.reorderPlaylistEntries(
      'mix',
      ['youtube-2', 'server-1', 'youtube-1'],
    );
    await repository.removePlaylistEntry('youtube-1');

    final playlist = (await repository.listPlaylists()).single;
    final reordered = await repository.listPlaylistEntries('mix');
    expect(playlist.name, 'Evening mix');
    expect(reordered.map((entry) => entry.id), ['youtube-2', 'server-1']);
    expect(reordered.map((entry) => entry.position), [0, 1]);

    await repository.deletePlaylist('mix');
    expect(await repository.listPlaylists(), isEmpty);
    expect(await repository.listPlaylistEntries('mix'), isEmpty);
  });

  test('restored YouTube favourite resolves a fresh stream before playback',
      () async {
    var resolutions = 0;
    final controller = UserFavouriteController(
      resolveYoutube: (song) async {
        resolutions += 1;
        return song.copyWith(
          songurl: 'https://signed.example/fresh-$resolutions',
        );
      },
    );
    final restored = TrackRef(
      source: TrackSource.youtube,
      providerId: 'fresh-video-id',
      title: 'Fresh favourite',
      artist: 'Artist',
    ).toSong();

    final first = await controller.prepareForPlayback(restored);
    final second = await controller.prepareForPlayback(restored);

    expect(restored.songurl, isEmpty);
    expect(first.songurl, 'https://signed.example/fresh-1');
    expect(second.songurl, 'https://signed.example/fresh-2');
    expect(resolutions, 2);
  });
}

class _DelayedFavouriteStatusRepository extends LibraryRepository {
  _DelayedFavouriteStatusRepository(super.database);

  final status = Completer<bool>();

  @override
  Future<bool> isFavourite(TrackRef track) => status.future;
}

class _DelayedFavouriteWriteRepository extends LibraryRepository {
  _DelayedFavouriteWriteRepository(super.database);

  final write = Completer<void>();

  @override
  Future<void> setFavourite(
    TrackRef track,
    bool value, {
    FavouriteOrigin origin = FavouriteOrigin.local,
  }) =>
      write.future;
}

class _ControlledFavouriteWriteRepository extends LibraryRepository {
  _ControlledFavouriteWriteRepository(super.database);

  final requests = <String>[];
  final writes = <String, Completer<void>>{};

  @override
  Future<void> setFavourite(
    TrackRef track,
    bool value, {
    FavouriteOrigin origin = FavouriteOrigin.local,
  }) {
    requests.add(track.stableKey);
    final write = Completer<void>();
    writes[track.stableKey] = write;
    return write.future;
  }
}
