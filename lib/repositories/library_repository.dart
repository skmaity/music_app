import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:music_app/data/library_database.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';

enum FavouriteOrigin { local, serverCache }

class LegacyImportResult {
  const LegacyImportResult({
    this.imported = 0,
    this.skipped = 0,
    this.alreadyImported = false,
    this.failed = false,
  });

  final int imported;
  final int skipped;
  final bool alreadyImported;
  final bool failed;
}

class LibraryListeningEvent {
  const LibraryListeningEvent({
    required this.id,
    required this.track,
    required this.listenedAt,
    required this.listened,
    required this.completed,
    required this.earlySkip,
    required this.privateSession,
  });

  final int id;
  final TrackRef track;
  final DateTime listenedAt;
  final Duration listened;
  final bool completed;
  final bool earlySkip;
  final bool privateSession;
}

class LibraryPlaylist {
  const LibraryPlaylist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.entryCount,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int entryCount;
}

class LibraryPlaylistEntry {
  const LibraryPlaylistEntry({
    required this.id,
    required this.playlistId,
    required this.track,
    required this.position,
    required this.addedAt,
  });

  final String id;
  final String playlistId;
  final TrackRef track;
  final int position;
  final DateTime addedAt;
}

class LibraryRepository {
  LibraryRepository(
    this.database, {
    DateTime Function()? clock,
    String Function()? backupIdGenerator,
  })  : _clock = clock ?? DateTime.now,
        _backupIdGenerator = backupIdGenerator ?? _newBackupId;

  final LibraryDatabase database;
  final DateTime Function() _clock;
  final String Function() _backupIdGenerator;

  static final RegExp _portableBackupId = RegExp(r'^[A-Za-z0-9._-]{1,128}$');

  static String _newBackupId() {
    final random = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
        '${random.nextInt(0x100000000).toRadixString(36)}';
  }

  Future<void> upsertTrack(TrackRef track) async {
    final now = _clock().millisecondsSinceEpoch;
    await database.into(database.libraryTracks).insertOnConflictUpdate(
          LibraryTracksCompanion.insert(
            source: track.source.storageName,
            providerId: track.providerId,
            title: track.title,
            artist: track.artist,
            artworkRef: Value(track.artworkRef),
            albumId: Value(track.albumId),
            durationMs: Value(track.duration?.inMilliseconds),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> setFavourite(
    TrackRef track,
    bool value, {
    FavouriteOrigin origin = FavouriteOrigin.local,
  }) async {
    await database.transaction(() async {
      if (!value) {
        await (database.delete(database.favourites)
              ..where((row) =>
                  row.source.equals(track.source.storageName) &
                  row.providerId.equals(track.providerId)))
            .go();
        return;
      }
      await upsertTrack(track);
      await database.into(database.favourites).insertOnConflictUpdate(
            FavouritesCompanion.insert(
              source: track.source.storageName,
              providerId: track.providerId,
              createdAt: _clock().millisecondsSinceEpoch,
              origin: Value(origin.name),
            ),
          );
    });
  }

  Future<List<TrackRef>> listFavourites({TrackSource? source}) async {
    final query = database.select(database.libraryTracks).join([
      innerJoin(
        database.favourites,
        database.favourites.source.equalsExp(database.libraryTracks.source) &
            database.favourites.providerId
                .equalsExp(database.libraryTracks.providerId),
      ),
    ]);
    if (source != null) {
      query.where(database.libraryTracks.source.equals(source.storageName));
    }
    query.orderBy([OrderingTerm.desc(database.favourites.createdAt)]);
    final rows = await query.get();
    return rows
        .map((row) => _trackFromRow(row.readTable(database.libraryTracks)))
        .toList(growable: false);
  }

  Future<bool> isFavourite(TrackRef track) async {
    return await favouriteOrigin(track) != null;
  }

  Future<FavouriteOrigin?> favouriteOrigin(TrackRef track) async {
    final row = await (database.select(database.favourites)
          ..where((candidate) =>
              candidate.source.equals(track.source.storageName) &
              candidate.providerId.equals(track.providerId)))
        .getSingleOrNull();
    if (row == null) return null;
    return FavouriteOrigin.values.firstWhere(
      (origin) => origin.name == row.origin,
      orElse: () => FavouriteOrigin.local,
    );
  }

  /// Replaces the server-owned cache only. User-owned server favourites and
  /// YouTube favourites are never reclassified or sent through the wrong path.
  Future<int> cacheServerFavourites(Iterable<MySongs> songs) async {
    final refs = songs
        .where((song) => song.isBackend && !song.isPlaceholder)
        .map(TrackRef.fromSong)
        .toList(growable: false);

    await database.transaction(() async {
      await (database.delete(database.favourites)
            ..where((row) =>
                row.source.equals(TrackSource.nyroServer.storageName) &
                row.origin.equals(FavouriteOrigin.serverCache.name)))
          .go();
      for (final track in refs) {
        await upsertTrack(track);
        if (await favouriteOrigin(track) != FavouriteOrigin.local) {
          await setFavourite(
            track,
            true,
            origin: FavouriteOrigin.serverCache,
          );
        }
      }
    });
    return refs.length;
  }

  Future<int> recordListeningEvent(
    TrackRef track, {
    Duration listened = Duration.zero,
    bool completed = false,
    bool earlySkip = false,
    bool privateSession = false,
    DateTime? listenedAt,
  }) async {
    return database.transaction(() async {
      await upsertTrack(track);
      return database.into(database.listeningEvents).insert(
            ListeningEventsCompanion.insert(
              source: track.source.storageName,
              providerId: track.providerId,
              listenedAt: (listenedAt ?? _clock()).millisecondsSinceEpoch,
              listenedMs: Value(listened.inMilliseconds),
              completed: Value(completed),
              earlySkip: Value(earlySkip),
              privateSession: Value(privateSession),
            ),
          );
    });
  }

  Future<List<LibraryListeningEvent>> listListeningEvents() async {
    final query = database.select(database.listeningEvents).join([
      innerJoin(
        database.libraryTracks,
        database.libraryTracks.source
                .equalsExp(database.listeningEvents.source) &
            database.libraryTracks.providerId
                .equalsExp(database.listeningEvents.providerId),
      ),
    ])
      ..orderBy([OrderingTerm.desc(database.listeningEvents.listenedAt)]);
    final rows = await query.get();
    return rows.map((row) {
      final event = row.readTable(database.listeningEvents);
      return LibraryListeningEvent(
        id: event.id,
        track: _trackFromRow(row.readTable(database.libraryTracks)),
        listenedAt: DateTime.fromMillisecondsSinceEpoch(event.listenedAt),
        listened: Duration(milliseconds: event.listenedMs),
        completed: event.completed,
        earlySkip: event.earlySkip,
        privateSession: event.privateSession,
      );
    }).toList(growable: false);
  }

  Future<String> createPlaylist(
      {required String id, required String name}) async {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    final now = _clock().millisecondsSinceEpoch;
    await database.into(database.libraryPlaylists).insert(
          LibraryPlaylistsCompanion.insert(
            id: id,
            name: normalized,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<List<LibraryPlaylist>> listPlaylists() async {
    final entryCount = database.playlistEntries.id.count();
    final query = database.select(database.libraryPlaylists).join([
      leftOuterJoin(
        database.playlistEntries,
        database.playlistEntries.playlistId
            .equalsExp(database.libraryPlaylists.id),
      ),
    ])
      ..addColumns([entryCount])
      ..groupBy([database.libraryPlaylists.id])
      ..orderBy([OrderingTerm.desc(database.libraryPlaylists.updatedAt)]);
    final rows = await query.get();
    return rows.map((row) {
      final playlist = row.readTable(database.libraryPlaylists);
      return LibraryPlaylist(
        id: playlist.id,
        name: playlist.name,
        createdAt: DateTime.fromMillisecondsSinceEpoch(playlist.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(playlist.updatedAt),
        entryCount: row.read(entryCount) ?? 0,
      );
    }).toList(growable: false);
  }

  Future<void> renamePlaylist(String id, String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    await (database.update(database.libraryPlaylists)
          ..where((playlist) => playlist.id.equals(id)))
        .write(
      LibraryPlaylistsCompanion(
        name: Value(normalized),
        updatedAt: Value(_clock().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> deletePlaylist(String id) async {
    await database.transaction(() async {
      await (database.delete(database.playlistEntries)
            ..where((entry) => entry.playlistId.equals(id)))
          .go();
      await (database.delete(database.libraryPlaylists)
            ..where((playlist) => playlist.id.equals(id)))
          .go();
    });
  }

  Future<void> addPlaylistEntry({
    required String entryId,
    required String playlistId,
    required TrackRef track,
    required int position,
  }) async {
    if (position < 0) {
      throw ArgumentError.value(position, 'position', 'cannot be negative');
    }
    await database.transaction(() async {
      await upsertTrack(track);
      await database.into(database.playlistEntries).insert(
            PlaylistEntriesCompanion.insert(
              id: entryId,
              playlistId: playlistId,
              source: track.source.storageName,
              providerId: track.providerId,
              position: position,
              addedAt: _clock().millisecondsSinceEpoch,
            ),
          );
    });
  }

  Future<List<LibraryPlaylistEntry>> listPlaylistEntries(
    String playlistId,
  ) async {
    final query = database.select(database.playlistEntries).join([
      innerJoin(
        database.libraryTracks,
        database.libraryTracks.source
                .equalsExp(database.playlistEntries.source) &
            database.libraryTracks.providerId
                .equalsExp(database.playlistEntries.providerId),
      ),
    ])
      ..where(database.playlistEntries.playlistId.equals(playlistId))
      ..orderBy([
        OrderingTerm.asc(database.playlistEntries.position),
        OrderingTerm.asc(database.playlistEntries.addedAt),
      ]);
    final rows = await query.get();
    return rows.map((row) {
      final entry = row.readTable(database.playlistEntries);
      return LibraryPlaylistEntry(
        id: entry.id,
        playlistId: entry.playlistId,
        track: _trackFromRow(row.readTable(database.libraryTracks)),
        position: entry.position,
        addedAt: DateTime.fromMillisecondsSinceEpoch(entry.addedAt),
      );
    }).toList(growable: false);
  }

  Future<void> reorderPlaylistEntries(
    String playlistId,
    List<String> orderedEntryIds,
  ) async {
    final current = await listPlaylistEntries(playlistId);
    final currentIds = current.map((entry) => entry.id).toSet();
    if (current.length != orderedEntryIds.length ||
        currentIds.length != orderedEntryIds.toSet().length ||
        !currentIds.containsAll(orderedEntryIds)) {
      throw ArgumentError.value(
        orderedEntryIds,
        'orderedEntryIds',
        'must contain every playlist entry exactly once',
      );
    }

    await database.transaction(() async {
      for (var position = 0; position < orderedEntryIds.length; position++) {
        await (database.update(database.playlistEntries)
              ..where((entry) =>
                  entry.id.equals(orderedEntryIds[position]) &
                  entry.playlistId.equals(playlistId)))
            .write(PlaylistEntriesCompanion(position: Value(position)));
      }
      await _touchPlaylist(playlistId);
    });
  }

  Future<void> removePlaylistEntry(String entryId) async {
    final entry = await (database.select(database.playlistEntries)
          ..where((candidate) => candidate.id.equals(entryId)))
        .getSingleOrNull();
    if (entry == null) return;

    await database.transaction(() async {
      await (database.delete(database.playlistEntries)
            ..where((candidate) => candidate.id.equals(entryId)))
          .go();
      final remaining = await (database.select(database.playlistEntries)
            ..where(
                (candidate) => candidate.playlistId.equals(entry.playlistId))
            ..orderBy([
              (candidate) => OrderingTerm.asc(candidate.position),
              (candidate) => OrderingTerm.asc(candidate.addedAt),
            ]))
          .get();
      for (var position = 0; position < remaining.length; position++) {
        await (database.update(database.playlistEntries)
              ..where(
                  (candidate) => candidate.id.equals(remaining[position].id)))
            .write(PlaylistEntriesCompanion(position: Value(position)));
      }
      await _touchPlaylist(entry.playlistId);
    });
  }

  Future<void> _touchPlaylist(String playlistId) async {
    await (database.update(database.libraryPlaylists)
          ..where((playlist) => playlist.id.equals(playlistId)))
        .write(
      LibraryPlaylistsCompanion(
        updatedAt: Value(_clock().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> saveResumePosition(TrackRef track, Duration position) async {
    if (position.isNegative) {
      throw ArgumentError.value(position, 'position', 'cannot be negative');
    }
    await upsertTrack(track);
    await database.into(database.resumePositions).insertOnConflictUpdate(
          ResumePositionsCompanion.insert(
            source: track.source.storageName,
            providerId: track.providerId,
            positionMs: position.inMilliseconds,
            updatedAt: _clock().millisecondsSinceEpoch,
          ),
        );
  }

  Future<Duration?> resumePosition(TrackRef track) async {
    final row = await (database.select(database.resumePositions)
          ..where((candidate) =>
              candidate.source.equals(track.source.storageName) &
              candidate.providerId.equals(track.providerId)))
        .getSingleOrNull();
    return row == null ? null : Duration(milliseconds: row.positionMs);
  }

  Future<void> saveDownload({
    required TrackRef track,
    required String status,
    String? localPath,
    int bytesReceived = 0,
    int? expectedBytes,
    String? error,
  }) async {
    if (bytesReceived < 0 || (expectedBytes != null && expectedBytes < 0)) {
      throw ArgumentError('Download byte counts cannot be negative.');
    }
    await upsertTrack(track);
    await database.into(database.downloads).insertOnConflictUpdate(
          DownloadsCompanion.insert(
            source: track.source.storageName,
            providerId: track.providerId,
            status: status,
            localPath: Value(localPath),
            bytesReceived: Value(bytesReceived),
            expectedBytes: Value(expectedBytes),
            error: Value(error),
            updatedAt: _clock().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> setSourcePreference(
    TrackSource source,
    String key,
    String value,
  ) async {
    await database.into(database.sourcePreferences).insertOnConflictUpdate(
          SourcePreferencesCompanion.insert(
            source: source.storageName,
            key: key,
            value: value,
            updatedAt: _clock().millisecondsSinceEpoch,
          ),
        );
  }

  Future<String?> sourcePreference(TrackSource source, String key) async {
    final row = await (database.select(database.sourcePreferences)
          ..where((candidate) =>
              candidate.source.equals(source.storageName) &
              candidate.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<String> exportMetadata({TrackSource? source}) async {
    final backupId = _backupIdGenerator();
    if (!_portableBackupId.hasMatch(backupId)) {
      throw StateError('Backup ID generator returned an invalid ID.');
    }
    final trackQuery = database.select(database.libraryTracks);
    if (source != null) {
      trackQuery.where((track) => track.source.equals(source.storageName));
    }
    final tracks = (await trackQuery.get())
        .where((track) => TrackSource.parse(track.source) != TrackSource.local)
        .toList(growable: false);
    tracks.sort((left, right) {
      final sourceOrder = left.source.compareTo(right.source);
      return sourceOrder != 0
          ? sourceOrder
          : left.providerId.compareTo(right.providerId);
    });

    final favouriteQuery = database.select(database.favourites);
    if (source != null) {
      favouriteQuery.where((row) => row.source.equals(source.storageName));
    }
    final favouriteRows = (await favouriteQuery.get())
        .where(
          (row) => TrackSource.parse(row.source) != TrackSource.local,
        )
        .toList(growable: false);

    final playlists = await listPlaylists();
    final playlistRecords = <Map<String, Object?>>[];
    for (final playlist in playlists) {
      final entries = (await listPlaylistEntries(playlist.id))
          .where((entry) =>
              entry.track.source != TrackSource.local &&
              (source == null || entry.track.source == source))
          .toList(growable: false);
      if (source != null && entries.isEmpty) continue;
      playlistRecords.add({
        'id': playlist.id,
        'name': playlist.name,
        'createdAt': playlist.createdAt.millisecondsSinceEpoch,
        'updatedAt': playlist.updatedAt.millisecondsSinceEpoch,
        'entries': [
          for (final entry in entries)
            {
              'id': entry.id,
              'source': entry.track.source.storageName,
              'providerId': entry.track.providerId,
              'position': entry.position,
              'addedAt': entry.addedAt.millisecondsSinceEpoch,
            },
        ],
      });
    }

    return jsonEncode({
      'schemaVersion': 1,
      'backupId': backupId,
      'exportedAt': _clock().toUtc().toIso8601String(),
      'source': source?.storageName ?? 'all',
      'tracks': [
        for (final track in tracks)
          {
            'source': track.source,
            'providerId': track.providerId,
            'title': track.title,
            'artist': track.artist,
            if (track.artworkRef != null) 'artworkRef': track.artworkRef,
            if (track.albumId != null) 'albumId': track.albumId,
            if (track.durationMs != null) 'durationMs': track.durationMs,
            'createdAt': track.createdAt,
            'updatedAt': track.updatedAt,
          },
      ],
      'favourites': [
        for (final favourite in favouriteRows)
          {
            'source': favourite.source,
            'providerId': favourite.providerId,
            'createdAt': favourite.createdAt,
            'origin': favourite.origin,
          },
      ],
      'playlists': playlistRecords,
    });
  }

  Future<void> importMetadata(String encoded) async {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map || decoded['schemaVersion'] != 1) {
      throw const FormatException('Unsupported Nyro library backup.');
    }
    final root = Map<String, dynamic>.from(decoded);
    final trackRecords = (root['tracks'] as List? ?? const [])
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList(growable: false);
    final favouriteRecords = (root['favourites'] as List? ?? const [])
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList(growable: false);
    final playlistRecords = (root['playlists'] as List? ?? const [])
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList(growable: false);

    final exportedAt = DateTime.tryParse(root['exportedAt'] as String? ?? '');
    final fallbackTimestamp =
        exportedAt?.millisecondsSinceEpoch ?? _clock().millisecondsSinceEpoch;
    final backupId = root['backupId'] as String?;
    final importedTracks = <String, TrackRef>{};
    final importedTrackTimes = <String, (int, int)>{};

    String? referenceKey(Map<String, dynamic> record) {
      final source = TrackSource.parse(record['source'] as String);
      if (source == TrackSource.local) return null;
      final providerId = record['providerId'] as String?;
      if (providerId == null || providerId.isEmpty) return null;
      return '${source.storageName}:$providerId';
    }

    for (final record in trackRecords) {
      final key = referenceKey(record);
      if (key == null) continue;
      final source = TrackSource.parse(record['source'] as String);
      final providerId = record['providerId'] as String;
      final track = TrackRef(
        source: source,
        providerId: providerId,
        title: record['title'] as String? ?? 'Unknown title',
        artist: record['artist'] as String? ?? 'Unknown artist',
        artworkRef: record['artworkRef'] as String?,
        albumId: record['albumId'] as String?,
        duration: record['durationMs'] is int
            ? Duration(milliseconds: record['durationMs'] as int)
            : null,
      );
      importedTracks[key] = track;
      importedTrackTimes[key] = (
        record['createdAt'] as int? ?? fallbackTimestamp,
        record['updatedAt'] as int? ?? fallbackTimestamp,
      );
    }

    await database.transaction(() async {
      for (final entry in importedTracks.entries) {
        final track = entry.value;
        final times = importedTrackTimes[entry.key]!;
        final existing = await (database.select(database.libraryTracks)
              ..where((row) =>
                  row.source.equals(track.source.storageName) &
                  row.providerId.equals(track.providerId)))
            .getSingleOrNull();
        if (existing != null && existing.updatedAt > times.$2) continue;
        await database.into(database.libraryTracks).insertOnConflictUpdate(
              LibraryTracksCompanion.insert(
                source: track.source.storageName,
                providerId: track.providerId,
                title: track.title,
                artist: track.artist,
                artworkRef: Value(track.artworkRef),
                albumId: Value(track.albumId),
                durationMs: Value(track.duration?.inMilliseconds),
                createdAt: existing?.createdAt ?? times.$1,
                updatedAt: times.$2,
              ),
            );
      }
      for (final favourite in favouriteRecords) {
        final key = referenceKey(favourite);
        final track = key == null ? null : importedTracks[key];
        if (track == null) continue;
        final existingFavourite = await (database.select(database.favourites)
              ..where((row) =>
                  row.source.equals(track.source.storageName) &
                  row.providerId.equals(track.providerId)))
            .getSingleOrNull();
        if (existingFavourite != null) continue;
        final originName = favourite['origin'] as String?;
        final origin = FavouriteOrigin.values.any(
          (candidate) => candidate.name == originName,
        )
            ? originName!
            : FavouriteOrigin.local.name;
        await database.into(database.favourites).insertOnConflictUpdate(
              FavouritesCompanion.insert(
                source: track.source.storageName,
                providerId: track.providerId,
                createdAt: favourite['createdAt'] as int? ?? fallbackTimestamp,
                origin: Value(origin),
              ),
            );
      }
      for (final playlistRecord in playlistRecords) {
        final originalId = playlistRecord['id'] as String;
        final name = (playlistRecord['name'] as String).trim();
        if (backupId == null ||
            !_portableBackupId.hasMatch(backupId) ||
            originalId.isEmpty ||
            name.isEmpty) {
          continue;
        }
        final id = 'backup:$backupId:$originalId';
        final incomingCreatedAt =
            playlistRecord['createdAt'] as int? ?? fallbackTimestamp;
        final incomingUpdatedAt =
            playlistRecord['updatedAt'] as int? ?? fallbackTimestamp;
        final existingPlaylist =
            await (database.select(database.libraryPlaylists)
                  ..where((row) => row.id.equals(id)))
                .getSingleOrNull();
        if (existingPlaylist != null &&
            existingPlaylist.updatedAt > incomingUpdatedAt) {
          continue;
        }
        await database.into(database.libraryPlaylists).insertOnConflictUpdate(
              LibraryPlaylistsCompanion.insert(
                id: id,
                name: name,
                createdAt: existingPlaylist?.createdAt ?? incomingCreatedAt,
                updatedAt: incomingUpdatedAt,
              ),
            );
        final entries = (playlistRecord['entries'] as List? ?? const [])
            .map((value) => Map<String, dynamic>.from(value as Map));
        for (final entry in entries) {
          final key = referenceKey(entry);
          final track = key == null ? null : importedTracks[key];
          if (track == null) continue;
          await database.into(database.playlistEntries).insertOnConflictUpdate(
                PlaylistEntriesCompanion.insert(
                  id: 'backup:$backupId:${entry['id'] as String}',
                  playlistId: id,
                  source: track.source.storageName,
                  providerId: track.providerId,
                  position: entry['position'] as int,
                  addedAt: entry['addedAt'] as int? ?? fallbackTimestamp,
                ),
              );
        }
      }
    });
  }

  Future<LegacyImportResult> importLegacyRecents(String? encoded) async {
    const markerKey = 'legacy_recents_imported_v1';
    if (await sourcePreference(TrackSource.nyroServer, markerKey) == 'true') {
      return const LegacyImportResult(alreadyImported: true);
    }
    if (encoded == null || encoded.trim().isEmpty) {
      await setSourcePreference(TrackSource.nyroServer, markerKey, 'true');
      return const LegacyImportResult();
    }

    late final List<dynamic> decoded;
    try {
      decoded = jsonDecode(encoded) as List<dynamic>;
    } catch (_) {
      return const LegacyImportResult(failed: true);
    }

    var imported = 0;
    var skipped = 0;
    await database.transaction(() async {
      for (var index = 0; index < decoded.length; index++) {
        try {
          final value = decoded[index];
          final song = MySongs.fromJson(
            Map<String, dynamic>.from(value as Map),
          );
          if (!song.isBackend || song.isPlaceholder) {
            skipped++;
            continue;
          }
          await recordListeningEvent(
            TrackRef.fromSong(song),
            listenedAt: _clock().subtract(Duration(milliseconds: index)),
          );
          imported++;
        } catch (_) {
          skipped++;
        }
      }
      await setSourcePreference(TrackSource.nyroServer, markerKey, 'true');
    });
    return LegacyImportResult(imported: imported, skipped: skipped);
  }

  TrackRef _trackFromRow(LibraryTrackRow row) => TrackRef(
        source: TrackSource.parse(row.source),
        providerId: row.providerId,
        title: row.title,
        artist: row.artist,
        artworkRef: row.artworkRef,
        albumId: row.albumId,
        duration: row.durationMs == null
            ? null
            : Duration(milliseconds: row.durationMs!),
      );
}
