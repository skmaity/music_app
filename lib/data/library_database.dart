import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'library_database.g.dart';

@DataClassName('LibraryTrackRow')
class LibraryTracks extends Table {
  @override
  String get tableName => 'tracks';

  TextColumn get source => text()();
  TextColumn get providerId => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get artworkRef => text().nullable()();
  TextColumn get albumId => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {source, providerId};
}

@DataClassName('FavouriteRow')
class Favourites extends Table {
  TextColumn get source => text()();
  TextColumn get providerId => text()();
  IntColumn get createdAt => integer()();
  TextColumn get origin => text().withDefault(const Constant('local'))();

  @override
  Set<Column<Object>> get primaryKey => {source, providerId};
}

@DataClassName('LibraryPlaylistRow')
class LibraryPlaylists extends Table {
  @override
  String get tableName => 'playlists';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'playlist_entries_order', columns: {#playlistId, #position})
@DataClassName('PlaylistEntryRow')
class PlaylistEntries extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId => text().references(LibraryPlaylists, #id)();
  TextColumn get source => text()();
  TextColumn get providerId => text()();
  IntColumn get position => integer()();
  IntColumn get addedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'listening_events_track', columns: {#source, #providerId})
@DataClassName('ListeningEventRow')
class ListeningEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get source => text()();
  TextColumn get providerId => text()();
  IntColumn get listenedAt => integer()();
  IntColumn get listenedMs => integer().withDefault(const Constant(0))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  BoolColumn get earlySkip => boolean().withDefault(const Constant(false))();
  BoolColumn get privateSession =>
      boolean().withDefault(const Constant(false))();
}

@DataClassName('ResumePositionRow')
class ResumePositions extends Table {
  TextColumn get source => text()();
  TextColumn get providerId => text()();
  IntColumn get positionMs => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {source, providerId};
}

@DataClassName('DownloadRow')
class Downloads extends Table {
  TextColumn get source => text()();
  TextColumn get providerId => text()();
  TextColumn get status => text()();
  TextColumn get localPath => text().nullable()();
  IntColumn get bytesReceived => integer().withDefault(const Constant(0))();
  IntColumn get expectedBytes => integer().nullable()();
  TextColumn get error => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {source, providerId};
}

@DataClassName('SourcePreferenceRow')
class SourcePreferences extends Table {
  TextColumn get source => text()();
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {source, key};
}

@DriftDatabase(
  tables: [
    LibraryTracks,
    Favourites,
    LibraryPlaylists,
    PlaylistEntries,
    ListeningEvents,
    ResumePositions,
    Downloads,
    SourcePreferences,
  ],
)
class LibraryDatabase extends _$LibraryDatabase {
  LibraryDatabase(super.executor);

  factory LibraryDatabase.open() =>
      LibraryDatabase(driftDatabase(name: 'nyro_library'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(favourites, favourites.origin);
            await migrator.createTable(libraryPlaylists);
            await migrator.createTable(playlistEntries);
            await migrator.createTable(listeningEvents);
            await migrator.createTable(resumePositions);
            await migrator.createTable(downloads);
            await migrator.createTable(sourcePreferences);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
