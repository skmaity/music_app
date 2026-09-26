import 'dart:convert';

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

class LibraryRepository {
  LibraryRepository(this.database, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final LibraryDatabase database;
  final DateTime Function() _clock;

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

  /// Replaces the server-owned cache only. Local and YouTube favourites are
  /// never accepted by this boundary or sent back to the PHP song-ID API.
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
