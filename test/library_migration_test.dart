import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/data/library_database.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/repositories/library_repository.dart';

void main() {
  test('migrates v1 data without rewriting hosted track identity', () async {
    final database = LibraryDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE tracks (
              source TEXT NOT NULL,
              provider_id TEXT NOT NULL,
              title TEXT NOT NULL,
              artist TEXT NOT NULL,
              artwork_ref TEXT,
              album_id TEXT,
              duration_ms INTEGER,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              PRIMARY KEY (source, provider_id)
            )
          ''');
          raw.execute('''
            CREATE TABLE favourites (
              source TEXT NOT NULL,
              provider_id TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              PRIMARY KEY (source, provider_id)
            )
          ''');
          raw.execute(
            "INSERT INTO tracks VALUES "
            "('backend', '42', 'Hosted fixture', 'Artist', NULL, NULL, "
            'NULL, 1000, 1000)',
          );
          raw.execute(
            "INSERT INTO favourites VALUES ('backend', '42', 1000)",
          );
          raw.userVersion = 1;
        },
      ),
    );
    addTearDown(database.close);

    final repository = LibraryRepository(database);
    final favourites = await repository.listFavourites();

    expect(database.schemaVersion, 2);
    expect(favourites, hasLength(1));
    expect(favourites.single.stableKey, 'backend:42');
    expect(favourites.single.title, 'Hosted fixture');
    expect(
      await database.customSelect('PRAGMA user_version').getSingle().then(
            (row) => row.read<int>('user_version'),
          ),
      2,
    );
    expect(
      await database
          .customSelect(
            "SELECT origin FROM favourites WHERE provider_id = '42'",
          )
          .getSingle()
          .then((row) => row.read<String>('origin')),
      FavouriteOrigin.local.name,
    );
    final migratedTables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        )
        .get();
    expect(
      migratedTables.map((row) => row.read<String>('name')).toSet(),
      containsAll({
        'playlists',
        'playlist_entries',
        'listening_events',
        'resume_positions',
        'downloads',
        'source_preferences',
      }),
    );
  });

  test('favourites from colliding sources survive a real restart', () async {
    final directory = await Directory.systemTemp.createTemp('nyro-library-');
    final file = File('${directory.path}/library.sqlite');
    addTearDown(() async {
      if (directory.existsSync()) await directory.delete(recursive: true);
    });

    final first = LibraryDatabase(NativeDatabase(file));
    final firstRepository = LibraryRepository(first);
    for (final source in TrackSource.values) {
      await firstRepository.setFavourite(
        TrackRef(
          source: source,
          providerId: 'shared-id',
          title: '${source.name} fixture',
          artist: 'Artist',
        ),
        true,
      );
    }
    await first.close();

    final second = LibraryDatabase(NativeDatabase(file));
    addTearDown(second.close);
    final restored = await LibraryRepository(second).listFavourites();

    expect(restored.map((track) => track.stableKey).toSet(), {
      'local:shared-id',
      'backend:shared-id',
      'youtube:shared-id',
    });
  });

  test('legacy recents import is idempotent and stores no playback URL',
      () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    final legacy = jsonEncode([
      MySongs(
        songid: 7,
        title: 'Legacy recent',
        songurl: 'https://server.example/audio/7.mp3',
        coverurl: '/cover/7.jpg',
        artist: 'Artist',
        isquickpick: 0,
      ).toJson(),
    ]);

    final first = await repository.importLegacyRecents(legacy);
    final second = await repository.importLegacyRecents(legacy);
    final events = await repository.listListeningEvents();

    expect(first.imported, 1);
    expect(second.imported, 0);
    expect(second.alreadyImported, isTrue);
    expect(events, hasLength(1));
    expect(events.single.track.stableKey, 'backend:7');
    final columns =
        await database.customSelect('PRAGMA table_info(tracks)').get();
    expect(columns.map((row) => row.read<String>('name')),
        isNot(contains('songurl')));
    expect(columns.map((row) => row.read<String>('name')),
        isNot(contains('stream_url')));
  });

  test('corrupt legacy recents are contained and can be retried', () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);

    final corrupt = await repository.importLegacyRecents('{not-json');
    final recovered = await repository.importLegacyRecents(jsonEncode([
      MySongs(
        songid: 9,
        title: 'Recovered',
        songurl: '/9.mp3',
        coverurl: '',
        artist: 'Artist',
        isquickpick: 0,
      ).toJson(),
    ]));

    expect(corrupt.failed, isTrue);
    expect(recovered.imported, 1);
  });

  test('server favourite cache preserves IDs and ignores foreign sources',
      () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);

    final cached = await repository.cacheServerFavourites([
      MySongs(
        songid: 17,
        title: 'Server favourite',
        songurl: '/17.mp3',
        coverurl: '/17.jpg',
        artist: 'Artist',
        isquickpick: 0,
      ),
      MySongs.youtube(
        videoId: 'must-not-cross-boundary',
        title: 'Foreign',
        artist: 'Artist',
        artworkUrl: '',
      ),
    ]);
    final favourites = await repository.listFavourites();

    expect(cached, 1);
    expect(favourites, hasLength(1));
    expect(favourites.single.stableKey, 'backend:17');
    expect(
      await repository.favouriteOrigin(favourites.single),
      FavouriteOrigin.serverCache,
    );
  });

  test('server cache refresh never reclassifies or deletes a local favourite',
      () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    final localBackendFavourite = TrackRef(
      source: TrackSource.nyroServer,
      providerId: '88',
      title: 'Locally retained',
      artist: 'Artist',
    );
    final serverSong = MySongs(
      songid: 88,
      title: 'Server copy',
      songurl: '/88.mp3',
      coverurl: '',
      artist: 'Artist',
      isquickpick: 0,
    );

    await repository.setFavourite(localBackendFavourite, true);
    await repository.cacheServerFavourites([serverSong]);
    expect(
      await repository.favouriteOrigin(localBackendFavourite),
      FavouriteOrigin.local,
    );

    await repository.cacheServerFavourites(const []);
    final remaining = await repository.listFavourites();
    expect(remaining.map((track) => track.stableKey), contains('backend:88'));
    expect(
      await repository.favouriteOrigin(localBackendFavourite),
      FavouriteOrigin.local,
    );
  });

  test('fresh schema supports ordered duplicate playlist entries and state',
      () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    final track = TrackRef(
      source: TrackSource.youtube,
      providerId: 'durable-id',
      title: 'Fixture',
      artist: 'Artist',
    );

    await repository.createPlaylist(id: 'playlist-1', name: 'My playlist');
    await repository.addPlaylistEntry(
      entryId: 'entry-1',
      playlistId: 'playlist-1',
      track: track,
      position: 0,
    );
    await repository.addPlaylistEntry(
      entryId: 'entry-2',
      playlistId: 'playlist-1',
      track: track,
      position: 1,
    );
    await repository.saveResumePosition(track, const Duration(seconds: 37));
    await repository.saveDownload(
      track: track,
      status: 'queued',
      bytesReceived: 0,
    );
    await repository.setSourcePreference(
      TrackSource.youtube,
      'autoplay',
      'true',
    );

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        )
        .get();
    expect(
      tables.map((row) => row.read<String>('name')).toSet(),
      containsAll({
        'tracks',
        'favourites',
        'playlists',
        'playlist_entries',
        'listening_events',
        'resume_positions',
        'downloads',
        'source_preferences',
      }),
    );
    expect(
      await database
          .customSelect('SELECT COUNT(*) AS count FROM playlist_entries')
          .getSingle()
          .then((row) => row.read<int>('count')),
      2,
      reason: 'Intentional duplicate tracks use unique playlist-entry IDs.',
    );
    expect(await repository.resumePosition(track), const Duration(seconds: 37));
    expect(
      await repository.sourcePreference(TrackSource.youtube, 'autoplay'),
      'true',
    );
  });
}
