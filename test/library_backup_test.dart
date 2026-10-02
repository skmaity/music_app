import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/data/library_database.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/repositories/library_repository.dart';

void main() {
  test('metadata backup excludes Local library records', () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(
      database,
      backupIdGenerator: () => 'remote-archive',
    );
    final local = TrackRef(
      source: TrackSource.local,
      providerId: 'content://media/external/audio/media/42',
      title: 'Device track',
      artist: 'Local artist',
    );
    final youtube = TrackRef(
      source: TrackSource.youtube,
      providerId: 'backup-video',
      title: 'Saved video',
      artist: 'Video artist',
      artworkRef: 'https://img.example/cover.jpg',
    );

    await repository.setFavourite(local, true);
    await repository.setFavourite(youtube, true);
    await repository.createPlaylist(id: 'mix', name: 'Remote mix');
    await repository.addPlaylistEntry(
      entryId: 'local-entry',
      playlistId: 'mix',
      track: local,
      position: 0,
    );
    await repository.addPlaylistEntry(
      entryId: 'youtube-entry',
      playlistId: 'mix',
      track: youtube,
      position: 1,
    );

    final encoded = await repository.exportMetadata();
    final backup = jsonDecode(encoded) as Map<String, dynamic>;
    final tracks = (backup['tracks'] as List).cast<Map<String, dynamic>>();
    final favourites =
        (backup['favourites'] as List).cast<Map<String, dynamic>>();
    final playlists =
        (backup['playlists'] as List).cast<Map<String, dynamic>>();
    final entries =
        (playlists.single['entries'] as List).cast<Map<String, dynamic>>();

    expect(encoded, isNot(contains('content://')));
    expect(tracks.map((record) => record['source']).toSet(), {'youtube'});
    expect(favourites.map((record) => record['source']).toSet(), {'youtube'});
    expect(entries.map((record) => record['source']).toSet(), {'youtube'});
  });

  test('remote metadata import is idempotent and preserves newer state',
      () async {
    final sourceDatabase = LibraryDatabase(NativeDatabase.memory());
    final source = LibraryRepository(
      sourceDatabase,
      backupIdGenerator: () => 'remote-idempotent',
    );
    final youtube = TrackRef(
      source: TrackSource.youtube,
      providerId: 'backup-video',
      title: 'Saved video',
      artist: 'Video artist',
    );
    await source.setFavourite(youtube, true);
    await source.createPlaylist(id: 'mix', name: 'Remote mix');
    await source.addPlaylistEntry(
      entryId: 'youtube-entry',
      playlistId: 'mix',
      track: youtube,
      position: 0,
    );
    final backup = await source.exportMetadata();
    await sourceDatabase.close();

    final targetDatabase = LibraryDatabase(NativeDatabase.memory());
    addTearDown(targetDatabase.close);
    var clock = DateTime.utc(2030);
    final target = LibraryRepository(targetDatabase, clock: () => clock);
    await target.importMetadata(backup);
    final playlistId = 'backup:remote-idempotent:mix';
    final firstPlaylist = (await target.listPlaylists()).single;

    clock = clock.add(const Duration(days: 1));
    await target.importMetadata(backup);
    final repeatedPlaylist = (await target.listPlaylists()).single;
    expect(repeatedPlaylist.createdAt, firstPlaylist.createdAt);
    expect(repeatedPlaylist.updatedAt, firstPlaylist.updatedAt);

    await target.upsertTrack(
      TrackRef(
        source: TrackSource.youtube,
        providerId: 'backup-video',
        title: 'Current metadata',
        artist: 'Current artist',
      ),
    );
    await target.renamePlaylist(playlistId, 'Current playlist');
    final currentPlaylist = (await target.listPlaylists()).single;
    clock = clock.add(const Duration(days: 1));
    await target.importMetadata(backup);

    final favourite = (await target.listFavourites()).single;
    final playlist = (await target.listPlaylists()).single;
    final entry = (await target.listPlaylistEntries(playlistId)).single;
    expect(favourite.title, 'Current metadata');
    expect(playlist.name, 'Current playlist');
    expect(playlist.createdAt, currentPlaylist.createdAt);
    expect(playlist.updatedAt, currentPlaylist.updatedAt);
    expect(entry.track.stableKey, 'youtube:backup-video');
  });

  test('unrelated backups namespace matching playlist IDs', () async {
    Future<String> createBackup(String backupId, String videoId) async {
      final database = LibraryDatabase(NativeDatabase.memory());
      final repository = LibraryRepository(
        database,
        backupIdGenerator: () => backupId,
      );
      final track = TrackRef(
        source: TrackSource.youtube,
        providerId: videoId,
        title: videoId,
        artist: 'Artist',
      );
      await repository.createPlaylist(id: 'shared', name: '$videoId mix');
      await repository.addPlaylistEntry(
        entryId: 'shared-entry',
        playlistId: 'shared',
        track: track,
        position: 0,
      );
      final result = await repository.exportMetadata();
      await database.close();
      return result;
    }

    final first = await createBackup('archive-a', 'video-a');
    final second = await createBackup('archive-b', 'video-b');
    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    await repository.importMetadata(first);
    await repository.importMetadata(second);

    expect(
      (await repository.listPlaylists()).map((playlist) => playlist.id).toSet(),
      {'backup:archive-a:shared', 'backup:archive-b:shared'},
    );
    expect(
      (await repository.listPlaylistEntries('backup:archive-a:shared'))
          .single
          .track
          .providerId,
      'video-a',
    );
    expect(
      (await repository.listPlaylistEntries('backup:archive-b:shared'))
          .single
          .track
          .providerId,
      'video-b',
    );
  });
}
