// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_database.dart';

// ignore_for_file: type=lint
class $LibraryTracksTable extends LibraryTracks
    with TableInfo<$LibraryTracksTable, LibraryTrackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artworkRefMeta =
      const VerificationMeta('artworkRef');
  @override
  late final GeneratedColumn<String> artworkRef = GeneratedColumn<String>(
      'artwork_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
      'album_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        source,
        providerId,
        title,
        artist,
        artworkRef,
        albumId,
        durationMs,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(Insertable<LibraryTrackRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('artwork_ref')) {
      context.handle(
          _artworkRefMeta,
          artworkRef.isAcceptableOrUnknown(
              data['artwork_ref']!, _artworkRefMeta));
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source, providerId};
  @override
  LibraryTrackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryTrackRow(
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist'])!,
      artworkRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artwork_ref']),
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_id']),
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LibraryTracksTable createAlias(String alias) {
    return $LibraryTracksTable(attachedDatabase, alias);
  }
}

class LibraryTrackRow extends DataClass implements Insertable<LibraryTrackRow> {
  final String source;
  final String providerId;
  final String title;
  final String artist;
  final String? artworkRef;
  final String? albumId;
  final int? durationMs;
  final int createdAt;
  final int updatedAt;
  const LibraryTrackRow(
      {required this.source,
      required this.providerId,
      required this.title,
      required this.artist,
      this.artworkRef,
      this.albumId,
      this.durationMs,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['provider_id'] = Variable<String>(providerId);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    if (!nullToAbsent || artworkRef != null) {
      map['artwork_ref'] = Variable<String>(artworkRef);
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LibraryTracksCompanion toCompanion(bool nullToAbsent) {
    return LibraryTracksCompanion(
      source: Value(source),
      providerId: Value(providerId),
      title: Value(title),
      artist: Value(artist),
      artworkRef: artworkRef == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkRef),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LibraryTrackRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryTrackRow(
      source: serializer.fromJson<String>(json['source']),
      providerId: serializer.fromJson<String>(json['providerId']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      artworkRef: serializer.fromJson<String?>(json['artworkRef']),
      albumId: serializer.fromJson<String?>(json['albumId']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'providerId': serializer.toJson<String>(providerId),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'artworkRef': serializer.toJson<String?>(artworkRef),
      'albumId': serializer.toJson<String?>(albumId),
      'durationMs': serializer.toJson<int?>(durationMs),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LibraryTrackRow copyWith(
          {String? source,
          String? providerId,
          String? title,
          String? artist,
          Value<String?> artworkRef = const Value.absent(),
          Value<String?> albumId = const Value.absent(),
          Value<int?> durationMs = const Value.absent(),
          int? createdAt,
          int? updatedAt}) =>
      LibraryTrackRow(
        source: source ?? this.source,
        providerId: providerId ?? this.providerId,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        artworkRef: artworkRef.present ? artworkRef.value : this.artworkRef,
        albumId: albumId.present ? albumId.value : this.albumId,
        durationMs: durationMs.present ? durationMs.value : this.durationMs,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LibraryTrackRow copyWithCompanion(LibraryTracksCompanion data) {
    return LibraryTrackRow(
      source: data.source.present ? data.source.value : this.source,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      artworkRef:
          data.artworkRef.present ? data.artworkRef.value : this.artworkRef,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryTrackRow(')
          ..write('source: $source, ')
          ..write('providerId: $providerId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('artworkRef: $artworkRef, ')
          ..write('albumId: $albumId, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(source, providerId, title, artist, artworkRef,
      albumId, durationMs, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryTrackRow &&
          other.source == this.source &&
          other.providerId == this.providerId &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.artworkRef == this.artworkRef &&
          other.albumId == this.albumId &&
          other.durationMs == this.durationMs &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LibraryTracksCompanion extends UpdateCompanion<LibraryTrackRow> {
  final Value<String> source;
  final Value<String> providerId;
  final Value<String> title;
  final Value<String> artist;
  final Value<String?> artworkRef;
  final Value<String?> albumId;
  final Value<int?> durationMs;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const LibraryTracksCompanion({
    this.source = const Value.absent(),
    this.providerId = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.artworkRef = const Value.absent(),
    this.albumId = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryTracksCompanion.insert({
    required String source,
    required String providerId,
    required String title,
    required String artist,
    this.artworkRef = const Value.absent(),
    this.albumId = const Value.absent(),
    this.durationMs = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : source = Value(source),
        providerId = Value(providerId),
        title = Value(title),
        artist = Value(artist),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LibraryTrackRow> custom({
    Expression<String>? source,
    Expression<String>? providerId,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? artworkRef,
    Expression<String>? albumId,
    Expression<int>? durationMs,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (providerId != null) 'provider_id': providerId,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (artworkRef != null) 'artwork_ref': artworkRef,
      if (albumId != null) 'album_id': albumId,
      if (durationMs != null) 'duration_ms': durationMs,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryTracksCompanion copyWith(
      {Value<String>? source,
      Value<String>? providerId,
      Value<String>? title,
      Value<String>? artist,
      Value<String?>? artworkRef,
      Value<String?>? albumId,
      Value<int?>? durationMs,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return LibraryTracksCompanion(
      source: source ?? this.source,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artworkRef: artworkRef ?? this.artworkRef,
      albumId: albumId ?? this.albumId,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (artworkRef.present) {
      map['artwork_ref'] = Variable<String>(artworkRef.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryTracksCompanion(')
          ..write('source: $source, ')
          ..write('providerId: $providerId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('artworkRef: $artworkRef, ')
          ..write('albumId: $albumId, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavouritesTable extends Favourites
    with TableInfo<$FavouritesTable, FavouriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavouritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
      'origin', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('local'));
  @override
  List<GeneratedColumn> get $columns => [source, providerId, createdAt, origin];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favourites';
  @override
  VerificationContext validateIntegrity(Insertable<FavouriteRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(_originMeta,
          origin.isAcceptableOrUnknown(data['origin']!, _originMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source, providerId};
  @override
  FavouriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavouriteRow(
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      origin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}origin'])!,
    );
  }

  @override
  $FavouritesTable createAlias(String alias) {
    return $FavouritesTable(attachedDatabase, alias);
  }
}

class FavouriteRow extends DataClass implements Insertable<FavouriteRow> {
  final String source;
  final String providerId;
  final int createdAt;
  final String origin;
  const FavouriteRow(
      {required this.source,
      required this.providerId,
      required this.createdAt,
      required this.origin});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['provider_id'] = Variable<String>(providerId);
    map['created_at'] = Variable<int>(createdAt);
    map['origin'] = Variable<String>(origin);
    return map;
  }

  FavouritesCompanion toCompanion(bool nullToAbsent) {
    return FavouritesCompanion(
      source: Value(source),
      providerId: Value(providerId),
      createdAt: Value(createdAt),
      origin: Value(origin),
    );
  }

  factory FavouriteRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavouriteRow(
      source: serializer.fromJson<String>(json['source']),
      providerId: serializer.fromJson<String>(json['providerId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      origin: serializer.fromJson<String>(json['origin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'providerId': serializer.toJson<String>(providerId),
      'createdAt': serializer.toJson<int>(createdAt),
      'origin': serializer.toJson<String>(origin),
    };
  }

  FavouriteRow copyWith(
          {String? source,
          String? providerId,
          int? createdAt,
          String? origin}) =>
      FavouriteRow(
        source: source ?? this.source,
        providerId: providerId ?? this.providerId,
        createdAt: createdAt ?? this.createdAt,
        origin: origin ?? this.origin,
      );
  FavouriteRow copyWithCompanion(FavouritesCompanion data) {
    return FavouriteRow(
      source: data.source.present ? data.source.value : this.source,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      origin: data.origin.present ? data.origin.value : this.origin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavouriteRow(')
          ..write('source: $source, ')
          ..write('providerId: $providerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('origin: $origin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(source, providerId, createdAt, origin);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavouriteRow &&
          other.source == this.source &&
          other.providerId == this.providerId &&
          other.createdAt == this.createdAt &&
          other.origin == this.origin);
}

class FavouritesCompanion extends UpdateCompanion<FavouriteRow> {
  final Value<String> source;
  final Value<String> providerId;
  final Value<int> createdAt;
  final Value<String> origin;
  final Value<int> rowid;
  const FavouritesCompanion({
    this.source = const Value.absent(),
    this.providerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.origin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavouritesCompanion.insert({
    required String source,
    required String providerId,
    required int createdAt,
    this.origin = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : source = Value(source),
        providerId = Value(providerId),
        createdAt = Value(createdAt);
  static Insertable<FavouriteRow> custom({
    Expression<String>? source,
    Expression<String>? providerId,
    Expression<int>? createdAt,
    Expression<String>? origin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (providerId != null) 'provider_id': providerId,
      if (createdAt != null) 'created_at': createdAt,
      if (origin != null) 'origin': origin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavouritesCompanion copyWith(
      {Value<String>? source,
      Value<String>? providerId,
      Value<int>? createdAt,
      Value<String>? origin,
      Value<int>? rowid}) {
    return FavouritesCompanion(
      source: source ?? this.source,
      providerId: providerId ?? this.providerId,
      createdAt: createdAt ?? this.createdAt,
      origin: origin ?? this.origin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavouritesCompanion(')
          ..write('source: $source, ')
          ..write('providerId: $providerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('origin: $origin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibraryPlaylistsTable extends LibraryPlaylists
    with TableInfo<$LibraryPlaylistsTable, LibraryPlaylistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(Insertable<LibraryPlaylistRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryPlaylistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryPlaylistRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LibraryPlaylistsTable createAlias(String alias) {
    return $LibraryPlaylistsTable(attachedDatabase, alias);
  }
}

class LibraryPlaylistRow extends DataClass
    implements Insertable<LibraryPlaylistRow> {
  final String id;
  final String name;
  final int createdAt;
  final int updatedAt;
  const LibraryPlaylistRow(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LibraryPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return LibraryPlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LibraryPlaylistRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryPlaylistRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LibraryPlaylistRow copyWith(
          {String? id, String? name, int? createdAt, int? updatedAt}) =>
      LibraryPlaylistRow(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LibraryPlaylistRow copyWithCompanion(LibraryPlaylistsCompanion data) {
    return LibraryPlaylistRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryPlaylistRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryPlaylistRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LibraryPlaylistsCompanion extends UpdateCompanion<LibraryPlaylistRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const LibraryPlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryPlaylistsCompanion.insert({
    required String id,
    required String name,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LibraryPlaylistRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryPlaylistsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return LibraryPlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryPlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistEntriesTable extends PlaylistEntries
    with TableInfo<$PlaylistEntriesTable, PlaylistEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES playlists (id)'));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
      'added_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, playlistId, source, providerId, position, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_entries';
  @override
  VerificationContext validateIntegrity(Insertable<PlaylistEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}playlist_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $PlaylistEntriesTable createAlias(String alias) {
    return $PlaylistEntriesTable(attachedDatabase, alias);
  }
}

class PlaylistEntryRow extends DataClass
    implements Insertable<PlaylistEntryRow> {
  final String id;
  final String playlistId;
  final String source;
  final String providerId;
  final int position;
  final int addedAt;
  const PlaylistEntryRow(
      {required this.id,
      required this.playlistId,
      required this.source,
      required this.providerId,
      required this.position,
      required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['source'] = Variable<String>(source);
    map['provider_id'] = Variable<String>(providerId);
    map['position'] = Variable<int>(position);
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  PlaylistEntriesCompanion toCompanion(bool nullToAbsent) {
    return PlaylistEntriesCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      source: Value(source),
      providerId: Value(providerId),
      position: Value(position),
      addedAt: Value(addedAt),
    );
  }

  factory PlaylistEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistEntryRow(
      id: serializer.fromJson<String>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      source: serializer.fromJson<String>(json['source']),
      providerId: serializer.fromJson<String>(json['providerId']),
      position: serializer.fromJson<int>(json['position']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'source': serializer.toJson<String>(source),
      'providerId': serializer.toJson<String>(providerId),
      'position': serializer.toJson<int>(position),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  PlaylistEntryRow copyWith(
          {String? id,
          String? playlistId,
          String? source,
          String? providerId,
          int? position,
          int? addedAt}) =>
      PlaylistEntryRow(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        source: source ?? this.source,
        providerId: providerId ?? this.providerId,
        position: position ?? this.position,
        addedAt: addedAt ?? this.addedAt,
      );
  PlaylistEntryRow copyWithCompanion(PlaylistEntriesCompanion data) {
    return PlaylistEntryRow(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      source: data.source.present ? data.source.value : this.source,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      position: data.position.present ? data.position.value : this.position,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntryRow(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('source: $source, ')
          ..write('providerId: $providerId, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playlistId, source, providerId, position, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistEntryRow &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.source == this.source &&
          other.providerId == this.providerId &&
          other.position == this.position &&
          other.addedAt == this.addedAt);
}

class PlaylistEntriesCompanion extends UpdateCompanion<PlaylistEntryRow> {
  final Value<String> id;
  final Value<String> playlistId;
  final Value<String> source;
  final Value<String> providerId;
  final Value<int> position;
  final Value<int> addedAt;
  final Value<int> rowid;
  const PlaylistEntriesCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.source = const Value.absent(),
    this.providerId = const Value.absent(),
    this.position = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistEntriesCompanion.insert({
    required String id,
    required String playlistId,
    required String source,
    required String providerId,
    required int position,
    required int addedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        playlistId = Value(playlistId),
        source = Value(source),
        providerId = Value(providerId),
        position = Value(position),
        addedAt = Value(addedAt);
  static Insertable<PlaylistEntryRow> custom({
    Expression<String>? id,
    Expression<String>? playlistId,
    Expression<String>? source,
    Expression<String>? providerId,
    Expression<int>? position,
    Expression<int>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (source != null) 'source': source,
      if (providerId != null) 'provider_id': providerId,
      if (position != null) 'position': position,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? playlistId,
      Value<String>? source,
      Value<String>? providerId,
      Value<int>? position,
      Value<int>? addedAt,
      Value<int>? rowid}) {
    return PlaylistEntriesCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      source: source ?? this.source,
      providerId: providerId ?? this.providerId,
      position: position ?? this.position,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntriesCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('source: $source, ')
          ..write('providerId: $providerId, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListeningEventsTable extends ListeningEvents
    with TableInfo<$ListeningEventsTable, ListeningEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListeningEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _listenedAtMeta =
      const VerificationMeta('listenedAt');
  @override
  late final GeneratedColumn<int> listenedAt = GeneratedColumn<int>(
      'listened_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _listenedMsMeta =
      const VerificationMeta('listenedMs');
  @override
  late final GeneratedColumn<int> listenedMs = GeneratedColumn<int>(
      'listened_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _earlySkipMeta =
      const VerificationMeta('earlySkip');
  @override
  late final GeneratedColumn<bool> earlySkip = GeneratedColumn<bool>(
      'early_skip', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("early_skip" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _privateSessionMeta =
      const VerificationMeta('privateSession');
  @override
  late final GeneratedColumn<bool> privateSession = GeneratedColumn<bool>(
      'private_session', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("private_session" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        source,
        providerId,
        listenedAt,
        listenedMs,
        completed,
        earlySkip,
        privateSession
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listening_events';
  @override
  VerificationContext validateIntegrity(Insertable<ListeningEventRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('listened_at')) {
      context.handle(
          _listenedAtMeta,
          listenedAt.isAcceptableOrUnknown(
              data['listened_at']!, _listenedAtMeta));
    } else if (isInserting) {
      context.missing(_listenedAtMeta);
    }
    if (data.containsKey('listened_ms')) {
      context.handle(
          _listenedMsMeta,
          listenedMs.isAcceptableOrUnknown(
              data['listened_ms']!, _listenedMsMeta));
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('early_skip')) {
      context.handle(_earlySkipMeta,
          earlySkip.isAcceptableOrUnknown(data['early_skip']!, _earlySkipMeta));
    }
    if (data.containsKey('private_session')) {
      context.handle(
          _privateSessionMeta,
          privateSession.isAcceptableOrUnknown(
              data['private_session']!, _privateSessionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListeningEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListeningEventRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      listenedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}listened_at'])!,
      listenedMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}listened_ms'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      earlySkip: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}early_skip'])!,
      privateSession: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}private_session'])!,
    );
  }

  @override
  $ListeningEventsTable createAlias(String alias) {
    return $ListeningEventsTable(attachedDatabase, alias);
  }
}

class ListeningEventRow extends DataClass
    implements Insertable<ListeningEventRow> {
  final int id;
  final String source;
  final String providerId;
  final int listenedAt;
  final int listenedMs;
  final bool completed;
  final bool earlySkip;
  final bool privateSession;
  const ListeningEventRow(
      {required this.id,
      required this.source,
      required this.providerId,
      required this.listenedAt,
      required this.listenedMs,
      required this.completed,
      required this.earlySkip,
      required this.privateSession});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source'] = Variable<String>(source);
    map['provider_id'] = Variable<String>(providerId);
    map['listened_at'] = Variable<int>(listenedAt);
    map['listened_ms'] = Variable<int>(listenedMs);
    map['completed'] = Variable<bool>(completed);
    map['early_skip'] = Variable<bool>(earlySkip);
    map['private_session'] = Variable<bool>(privateSession);
    return map;
  }

  ListeningEventsCompanion toCompanion(bool nullToAbsent) {
    return ListeningEventsCompanion(
      id: Value(id),
      source: Value(source),
      providerId: Value(providerId),
      listenedAt: Value(listenedAt),
      listenedMs: Value(listenedMs),
      completed: Value(completed),
      earlySkip: Value(earlySkip),
      privateSession: Value(privateSession),
    );
  }

  factory ListeningEventRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListeningEventRow(
      id: serializer.fromJson<int>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      providerId: serializer.fromJson<String>(json['providerId']),
      listenedAt: serializer.fromJson<int>(json['listenedAt']),
      listenedMs: serializer.fromJson<int>(json['listenedMs']),
      completed: serializer.fromJson<bool>(json['completed']),
      earlySkip: serializer.fromJson<bool>(json['earlySkip']),
      privateSession: serializer.fromJson<bool>(json['privateSession']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'source': serializer.toJson<String>(source),
      'providerId': serializer.toJson<String>(providerId),
      'listenedAt': serializer.toJson<int>(listenedAt),
      'listenedMs': serializer.toJson<int>(listenedMs),
      'completed': serializer.toJson<bool>(completed),
      'earlySkip': serializer.toJson<bool>(earlySkip),
      'privateSession': serializer.toJson<bool>(privateSession),
    };
  }

  ListeningEventRow copyWith(
          {int? id,
          String? source,
          String? providerId,
          int? listenedAt,
          int? listenedMs,
          bool? completed,
          bool? earlySkip,
          bool? privateSession}) =>
      ListeningEventRow(
        id: id ?? this.id,
        source: source ?? this.source,
        providerId: providerId ?? this.providerId,
        listenedAt: listenedAt ?? this.listenedAt,
        listenedMs: listenedMs ?? this.listenedMs,
        completed: completed ?? this.completed,
        earlySkip: earlySkip ?? this.earlySkip,
        privateSession: privateSession ?? this.privateSession,
      );
  ListeningEventRow copyWithCompanion(ListeningEventsCompanion data) {
    return ListeningEventRow(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      listenedAt:
          data.listenedAt.present ? data.listenedAt.value : this.listenedAt,
      listenedMs:
          data.listenedMs.present ? data.listenedMs.value : this.listenedMs,
      completed: data.completed.present ? data.completed.value : this.completed,
      earlySkip: data.earlySkip.present ? data.earlySkip.value : this.earlySkip,
      privateSession: data.privateSession.present
          ? data.privateSession.value
          : this.privateSession,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListeningEventRow(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('providerId: $providerId, ')
          ..write('listenedAt: $listenedAt, ')
          ..write('listenedMs: $listenedMs, ')
          ..write('completed: $completed, ')
          ..write('earlySkip: $earlySkip, ')
          ..write('privateSession: $privateSession')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, source, providerId, listenedAt,
      listenedMs, completed, earlySkip, privateSession);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListeningEventRow &&
          other.id == this.id &&
          other.source == this.source &&
          other.providerId == this.providerId &&
          other.listenedAt == this.listenedAt &&
          other.listenedMs == this.listenedMs &&
          other.completed == this.completed &&
          other.earlySkip == this.earlySkip &&
          other.privateSession == this.privateSession);
}

class ListeningEventsCompanion extends UpdateCompanion<ListeningEventRow> {
  final Value<int> id;
  final Value<String> source;
  final Value<String> providerId;
  final Value<int> listenedAt;
  final Value<int> listenedMs;
  final Value<bool> completed;
  final Value<bool> earlySkip;
  final Value<bool> privateSession;
  const ListeningEventsCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.providerId = const Value.absent(),
    this.listenedAt = const Value.absent(),
    this.listenedMs = const Value.absent(),
    this.completed = const Value.absent(),
    this.earlySkip = const Value.absent(),
    this.privateSession = const Value.absent(),
  });
  ListeningEventsCompanion.insert({
    this.id = const Value.absent(),
    required String source,
    required String providerId,
    required int listenedAt,
    this.listenedMs = const Value.absent(),
    this.completed = const Value.absent(),
    this.earlySkip = const Value.absent(),
    this.privateSession = const Value.absent(),
  })  : source = Value(source),
        providerId = Value(providerId),
        listenedAt = Value(listenedAt);
  static Insertable<ListeningEventRow> custom({
    Expression<int>? id,
    Expression<String>? source,
    Expression<String>? providerId,
    Expression<int>? listenedAt,
    Expression<int>? listenedMs,
    Expression<bool>? completed,
    Expression<bool>? earlySkip,
    Expression<bool>? privateSession,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (providerId != null) 'provider_id': providerId,
      if (listenedAt != null) 'listened_at': listenedAt,
      if (listenedMs != null) 'listened_ms': listenedMs,
      if (completed != null) 'completed': completed,
      if (earlySkip != null) 'early_skip': earlySkip,
      if (privateSession != null) 'private_session': privateSession,
    });
  }

  ListeningEventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? source,
      Value<String>? providerId,
      Value<int>? listenedAt,
      Value<int>? listenedMs,
      Value<bool>? completed,
      Value<bool>? earlySkip,
      Value<bool>? privateSession}) {
    return ListeningEventsCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      providerId: providerId ?? this.providerId,
      listenedAt: listenedAt ?? this.listenedAt,
      listenedMs: listenedMs ?? this.listenedMs,
      completed: completed ?? this.completed,
      earlySkip: earlySkip ?? this.earlySkip,
      privateSession: privateSession ?? this.privateSession,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (listenedAt.present) {
      map['listened_at'] = Variable<int>(listenedAt.value);
    }
    if (listenedMs.present) {
      map['listened_ms'] = Variable<int>(listenedMs.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (earlySkip.present) {
      map['early_skip'] = Variable<bool>(earlySkip.value);
    }
    if (privateSession.present) {
      map['private_session'] = Variable<bool>(privateSession.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListeningEventsCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('providerId: $providerId, ')
          ..write('listenedAt: $listenedAt, ')
          ..write('listenedMs: $listenedMs, ')
          ..write('completed: $completed, ')
          ..write('earlySkip: $earlySkip, ')
          ..write('privateSession: $privateSession')
          ..write(')'))
        .toString();
  }
}

class $ResumePositionsTable extends ResumePositions
    with TableInfo<$ResumePositionsTable, ResumePositionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResumePositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMsMeta =
      const VerificationMeta('positionMs');
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
      'position_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [source, providerId, positionMs, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'resume_positions';
  @override
  VerificationContext validateIntegrity(Insertable<ResumePositionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
          _positionMsMeta,
          positionMs.isAcceptableOrUnknown(
              data['position_ms']!, _positionMsMeta));
    } else if (isInserting) {
      context.missing(_positionMsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source, providerId};
  @override
  ResumePositionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResumePositionRow(
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      positionMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position_ms'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ResumePositionsTable createAlias(String alias) {
    return $ResumePositionsTable(attachedDatabase, alias);
  }
}

class ResumePositionRow extends DataClass
    implements Insertable<ResumePositionRow> {
  final String source;
  final String providerId;
  final int positionMs;
  final int updatedAt;
  const ResumePositionRow(
      {required this.source,
      required this.providerId,
      required this.positionMs,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['provider_id'] = Variable<String>(providerId);
    map['position_ms'] = Variable<int>(positionMs);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ResumePositionsCompanion toCompanion(bool nullToAbsent) {
    return ResumePositionsCompanion(
      source: Value(source),
      providerId: Value(providerId),
      positionMs: Value(positionMs),
      updatedAt: Value(updatedAt),
    );
  }

  factory ResumePositionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResumePositionRow(
      source: serializer.fromJson<String>(json['source']),
      providerId: serializer.fromJson<String>(json['providerId']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'providerId': serializer.toJson<String>(providerId),
      'positionMs': serializer.toJson<int>(positionMs),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ResumePositionRow copyWith(
          {String? source,
          String? providerId,
          int? positionMs,
          int? updatedAt}) =>
      ResumePositionRow(
        source: source ?? this.source,
        providerId: providerId ?? this.providerId,
        positionMs: positionMs ?? this.positionMs,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ResumePositionRow copyWithCompanion(ResumePositionsCompanion data) {
    return ResumePositionRow(
      source: data.source.present ? data.source.value : this.source,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      positionMs:
          data.positionMs.present ? data.positionMs.value : this.positionMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResumePositionRow(')
          ..write('source: $source, ')
          ..write('providerId: $providerId, ')
          ..write('positionMs: $positionMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(source, providerId, positionMs, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResumePositionRow &&
          other.source == this.source &&
          other.providerId == this.providerId &&
          other.positionMs == this.positionMs &&
          other.updatedAt == this.updatedAt);
}

class ResumePositionsCompanion extends UpdateCompanion<ResumePositionRow> {
  final Value<String> source;
  final Value<String> providerId;
  final Value<int> positionMs;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ResumePositionsCompanion({
    this.source = const Value.absent(),
    this.providerId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResumePositionsCompanion.insert({
    required String source,
    required String providerId,
    required int positionMs,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : source = Value(source),
        providerId = Value(providerId),
        positionMs = Value(positionMs),
        updatedAt = Value(updatedAt);
  static Insertable<ResumePositionRow> custom({
    Expression<String>? source,
    Expression<String>? providerId,
    Expression<int>? positionMs,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (providerId != null) 'provider_id': providerId,
      if (positionMs != null) 'position_ms': positionMs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResumePositionsCompanion copyWith(
      {Value<String>? source,
      Value<String>? providerId,
      Value<int>? positionMs,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return ResumePositionsCompanion(
      source: source ?? this.source,
      providerId: providerId ?? this.providerId,
      positionMs: positionMs ?? this.positionMs,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResumePositionsCompanion(')
          ..write('source: $source, ')
          ..write('providerId: $providerId, ')
          ..write('positionMs: $positionMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, DownloadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bytesReceivedMeta =
      const VerificationMeta('bytesReceived');
  @override
  late final GeneratedColumn<int> bytesReceived = GeneratedColumn<int>(
      'bytes_received', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _expectedBytesMeta =
      const VerificationMeta('expectedBytes');
  @override
  late final GeneratedColumn<int> expectedBytes = GeneratedColumn<int>(
      'expected_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
      'error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        source,
        providerId,
        status,
        localPath,
        bytesReceived,
        expectedBytes,
        error,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(Insertable<DownloadRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('bytes_received')) {
      context.handle(
          _bytesReceivedMeta,
          bytesReceived.isAcceptableOrUnknown(
              data['bytes_received']!, _bytesReceivedMeta));
    }
    if (data.containsKey('expected_bytes')) {
      context.handle(
          _expectedBytesMeta,
          expectedBytes.isAcceptableOrUnknown(
              data['expected_bytes']!, _expectedBytesMeta));
    }
    if (data.containsKey('error')) {
      context.handle(
          _errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source, providerId};
  @override
  DownloadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadRow(
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      bytesReceived: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes_received'])!,
      expectedBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expected_bytes']),
      error: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class DownloadRow extends DataClass implements Insertable<DownloadRow> {
  final String source;
  final String providerId;
  final String status;
  final String? localPath;
  final int bytesReceived;
  final int? expectedBytes;
  final String? error;
  final int updatedAt;
  const DownloadRow(
      {required this.source,
      required this.providerId,
      required this.status,
      this.localPath,
      required this.bytesReceived,
      this.expectedBytes,
      this.error,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['provider_id'] = Variable<String>(providerId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['bytes_received'] = Variable<int>(bytesReceived);
    if (!nullToAbsent || expectedBytes != null) {
      map['expected_bytes'] = Variable<int>(expectedBytes);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      source: Value(source),
      providerId: Value(providerId),
      status: Value(status),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      bytesReceived: Value(bytesReceived),
      expectedBytes: expectedBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedBytes),
      error:
          error == null && nullToAbsent ? const Value.absent() : Value(error),
      updatedAt: Value(updatedAt),
    );
  }

  factory DownloadRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadRow(
      source: serializer.fromJson<String>(json['source']),
      providerId: serializer.fromJson<String>(json['providerId']),
      status: serializer.fromJson<String>(json['status']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      bytesReceived: serializer.fromJson<int>(json['bytesReceived']),
      expectedBytes: serializer.fromJson<int?>(json['expectedBytes']),
      error: serializer.fromJson<String?>(json['error']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'providerId': serializer.toJson<String>(providerId),
      'status': serializer.toJson<String>(status),
      'localPath': serializer.toJson<String?>(localPath),
      'bytesReceived': serializer.toJson<int>(bytesReceived),
      'expectedBytes': serializer.toJson<int?>(expectedBytes),
      'error': serializer.toJson<String?>(error),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  DownloadRow copyWith(
          {String? source,
          String? providerId,
          String? status,
          Value<String?> localPath = const Value.absent(),
          int? bytesReceived,
          Value<int?> expectedBytes = const Value.absent(),
          Value<String?> error = const Value.absent(),
          int? updatedAt}) =>
      DownloadRow(
        source: source ?? this.source,
        providerId: providerId ?? this.providerId,
        status: status ?? this.status,
        localPath: localPath.present ? localPath.value : this.localPath,
        bytesReceived: bytesReceived ?? this.bytesReceived,
        expectedBytes:
            expectedBytes.present ? expectedBytes.value : this.expectedBytes,
        error: error.present ? error.value : this.error,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DownloadRow copyWithCompanion(DownloadsCompanion data) {
    return DownloadRow(
      source: data.source.present ? data.source.value : this.source,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      status: data.status.present ? data.status.value : this.status,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      bytesReceived: data.bytesReceived.present
          ? data.bytesReceived.value
          : this.bytesReceived,
      expectedBytes: data.expectedBytes.present
          ? data.expectedBytes.value
          : this.expectedBytes,
      error: data.error.present ? data.error.value : this.error,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadRow(')
          ..write('source: $source, ')
          ..write('providerId: $providerId, ')
          ..write('status: $status, ')
          ..write('localPath: $localPath, ')
          ..write('bytesReceived: $bytesReceived, ')
          ..write('expectedBytes: $expectedBytes, ')
          ..write('error: $error, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(source, providerId, status, localPath,
      bytesReceived, expectedBytes, error, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadRow &&
          other.source == this.source &&
          other.providerId == this.providerId &&
          other.status == this.status &&
          other.localPath == this.localPath &&
          other.bytesReceived == this.bytesReceived &&
          other.expectedBytes == this.expectedBytes &&
          other.error == this.error &&
          other.updatedAt == this.updatedAt);
}

class DownloadsCompanion extends UpdateCompanion<DownloadRow> {
  final Value<String> source;
  final Value<String> providerId;
  final Value<String> status;
  final Value<String?> localPath;
  final Value<int> bytesReceived;
  final Value<int?> expectedBytes;
  final Value<String?> error;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.source = const Value.absent(),
    this.providerId = const Value.absent(),
    this.status = const Value.absent(),
    this.localPath = const Value.absent(),
    this.bytesReceived = const Value.absent(),
    this.expectedBytes = const Value.absent(),
    this.error = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String source,
    required String providerId,
    required String status,
    this.localPath = const Value.absent(),
    this.bytesReceived = const Value.absent(),
    this.expectedBytes = const Value.absent(),
    this.error = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : source = Value(source),
        providerId = Value(providerId),
        status = Value(status),
        updatedAt = Value(updatedAt);
  static Insertable<DownloadRow> custom({
    Expression<String>? source,
    Expression<String>? providerId,
    Expression<String>? status,
    Expression<String>? localPath,
    Expression<int>? bytesReceived,
    Expression<int>? expectedBytes,
    Expression<String>? error,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (providerId != null) 'provider_id': providerId,
      if (status != null) 'status': status,
      if (localPath != null) 'local_path': localPath,
      if (bytesReceived != null) 'bytes_received': bytesReceived,
      if (expectedBytes != null) 'expected_bytes': expectedBytes,
      if (error != null) 'error': error,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith(
      {Value<String>? source,
      Value<String>? providerId,
      Value<String>? status,
      Value<String?>? localPath,
      Value<int>? bytesReceived,
      Value<int?>? expectedBytes,
      Value<String?>? error,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return DownloadsCompanion(
      source: source ?? this.source,
      providerId: providerId ?? this.providerId,
      status: status ?? this.status,
      localPath: localPath ?? this.localPath,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      expectedBytes: expectedBytes ?? this.expectedBytes,
      error: error ?? this.error,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (bytesReceived.present) {
      map['bytes_received'] = Variable<int>(bytesReceived.value);
    }
    if (expectedBytes.present) {
      map['expected_bytes'] = Variable<int>(expectedBytes.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('source: $source, ')
          ..write('providerId: $providerId, ')
          ..write('status: $status, ')
          ..write('localPath: $localPath, ')
          ..write('bytesReceived: $bytesReceived, ')
          ..write('expectedBytes: $expectedBytes, ')
          ..write('error: $error, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourcePreferencesTable extends SourcePreferences
    with TableInfo<$SourcePreferencesTable, SourcePreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcePreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [source, key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_preferences';
  @override
  VerificationContext validateIntegrity(
      Insertable<SourcePreferenceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source, key};
  @override
  SourcePreferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourcePreferenceRow(
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SourcePreferencesTable createAlias(String alias) {
    return $SourcePreferencesTable(attachedDatabase, alias);
  }
}

class SourcePreferenceRow extends DataClass
    implements Insertable<SourcePreferenceRow> {
  final String source;
  final String key;
  final String value;
  final int updatedAt;
  const SourcePreferenceRow(
      {required this.source,
      required this.key,
      required this.value,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SourcePreferencesCompanion toCompanion(bool nullToAbsent) {
    return SourcePreferencesCompanion(
      source: Value(source),
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SourcePreferenceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourcePreferenceRow(
      source: serializer.fromJson<String>(json['source']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SourcePreferenceRow copyWith(
          {String? source, String? key, String? value, int? updatedAt}) =>
      SourcePreferenceRow(
        source: source ?? this.source,
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SourcePreferenceRow copyWithCompanion(SourcePreferencesCompanion data) {
    return SourcePreferenceRow(
      source: data.source.present ? data.source.value : this.source,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourcePreferenceRow(')
          ..write('source: $source, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(source, key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourcePreferenceRow &&
          other.source == this.source &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SourcePreferencesCompanion extends UpdateCompanion<SourcePreferenceRow> {
  final Value<String> source;
  final Value<String> key;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SourcePreferencesCompanion({
    this.source = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcePreferencesCompanion.insert({
    required String source,
    required String key,
    required String value,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : source = Value(source),
        key = Value(key),
        value = Value(value),
        updatedAt = Value(updatedAt);
  static Insertable<SourcePreferenceRow> custom({
    Expression<String>? source,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcePreferencesCompanion copyWith(
      {Value<String>? source,
      Value<String>? key,
      Value<String>? value,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return SourcePreferencesCompanion(
      source: source ?? this.source,
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcePreferencesCompanion(')
          ..write('source: $source, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LibraryDatabase extends GeneratedDatabase {
  _$LibraryDatabase(QueryExecutor e) : super(e);
  $LibraryDatabaseManager get managers => $LibraryDatabaseManager(this);
  late final $LibraryTracksTable libraryTracks = $LibraryTracksTable(this);
  late final $FavouritesTable favourites = $FavouritesTable(this);
  late final $LibraryPlaylistsTable libraryPlaylists =
      $LibraryPlaylistsTable(this);
  late final $PlaylistEntriesTable playlistEntries =
      $PlaylistEntriesTable(this);
  late final $ListeningEventsTable listeningEvents =
      $ListeningEventsTable(this);
  late final $ResumePositionsTable resumePositions =
      $ResumePositionsTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final $SourcePreferencesTable sourcePreferences =
      $SourcePreferencesTable(this);
  late final Index playlistEntriesOrder = Index('playlist_entries_order',
      'CREATE INDEX playlist_entries_order ON playlist_entries (playlist_id, position)');
  late final Index listeningEventsTrack = Index('listening_events_track',
      'CREATE INDEX listening_events_track ON listening_events (source, provider_id)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        libraryTracks,
        favourites,
        libraryPlaylists,
        playlistEntries,
        listeningEvents,
        resumePositions,
        downloads,
        sourcePreferences,
        playlistEntriesOrder,
        listeningEventsTrack
      ];
}

typedef $$LibraryTracksTableCreateCompanionBuilder = LibraryTracksCompanion
    Function({
  required String source,
  required String providerId,
  required String title,
  required String artist,
  Value<String?> artworkRef,
  Value<String?> albumId,
  Value<int?> durationMs,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$LibraryTracksTableUpdateCompanionBuilder = LibraryTracksCompanion
    Function({
  Value<String> source,
  Value<String> providerId,
  Value<String> title,
  Value<String> artist,
  Value<String?> artworkRef,
  Value<String?> albumId,
  Value<int?> durationMs,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$LibraryTracksTableFilterComposer
    extends Composer<_$LibraryDatabase, $LibraryTracksTable> {
  $$LibraryTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artworkRef => $composableBuilder(
      column: $table.artworkRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumId => $composableBuilder(
      column: $table.albumId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LibraryTracksTableOrderingComposer
    extends Composer<_$LibraryDatabase, $LibraryTracksTable> {
  $$LibraryTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artworkRef => $composableBuilder(
      column: $table.artworkRef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumId => $composableBuilder(
      column: $table.albumId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LibraryTracksTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $LibraryTracksTable> {
  $$LibraryTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get artworkRef => $composableBuilder(
      column: $table.artworkRef, builder: (column) => column);

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LibraryTracksTableTableManager extends RootTableManager<
    _$LibraryDatabase,
    $LibraryTracksTable,
    LibraryTrackRow,
    $$LibraryTracksTableFilterComposer,
    $$LibraryTracksTableOrderingComposer,
    $$LibraryTracksTableAnnotationComposer,
    $$LibraryTracksTableCreateCompanionBuilder,
    $$LibraryTracksTableUpdateCompanionBuilder,
    (
      LibraryTrackRow,
      BaseReferences<_$LibraryDatabase, $LibraryTracksTable, LibraryTrackRow>
    ),
    LibraryTrackRow,
    PrefetchHooks Function()> {
  $$LibraryTracksTableTableManager(
      _$LibraryDatabase db, $LibraryTracksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> source = const Value.absent(),
            Value<String> providerId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> artist = const Value.absent(),
            Value<String?> artworkRef = const Value.absent(),
            Value<String?> albumId = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LibraryTracksCompanion(
            source: source,
            providerId: providerId,
            title: title,
            artist: artist,
            artworkRef: artworkRef,
            albumId: albumId,
            durationMs: durationMs,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String source,
            required String providerId,
            required String title,
            required String artist,
            Value<String?> artworkRef = const Value.absent(),
            Value<String?> albumId = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LibraryTracksCompanion.insert(
            source: source,
            providerId: providerId,
            title: title,
            artist: artist,
            artworkRef: artworkRef,
            albumId: albumId,
            durationMs: durationMs,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LibraryTracksTableProcessedTableManager = ProcessedTableManager<
    _$LibraryDatabase,
    $LibraryTracksTable,
    LibraryTrackRow,
    $$LibraryTracksTableFilterComposer,
    $$LibraryTracksTableOrderingComposer,
    $$LibraryTracksTableAnnotationComposer,
    $$LibraryTracksTableCreateCompanionBuilder,
    $$LibraryTracksTableUpdateCompanionBuilder,
    (
      LibraryTrackRow,
      BaseReferences<_$LibraryDatabase, $LibraryTracksTable, LibraryTrackRow>
    ),
    LibraryTrackRow,
    PrefetchHooks Function()>;
typedef $$FavouritesTableCreateCompanionBuilder = FavouritesCompanion Function({
  required String source,
  required String providerId,
  required int createdAt,
  Value<String> origin,
  Value<int> rowid,
});
typedef $$FavouritesTableUpdateCompanionBuilder = FavouritesCompanion Function({
  Value<String> source,
  Value<String> providerId,
  Value<int> createdAt,
  Value<String> origin,
  Value<int> rowid,
});

class $$FavouritesTableFilterComposer
    extends Composer<_$LibraryDatabase, $FavouritesTable> {
  $$FavouritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnFilters(column));
}

class $$FavouritesTableOrderingComposer
    extends Composer<_$LibraryDatabase, $FavouritesTable> {
  $$FavouritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnOrderings(column));
}

class $$FavouritesTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $FavouritesTable> {
  $$FavouritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);
}

class $$FavouritesTableTableManager extends RootTableManager<
    _$LibraryDatabase,
    $FavouritesTable,
    FavouriteRow,
    $$FavouritesTableFilterComposer,
    $$FavouritesTableOrderingComposer,
    $$FavouritesTableAnnotationComposer,
    $$FavouritesTableCreateCompanionBuilder,
    $$FavouritesTableUpdateCompanionBuilder,
    (
      FavouriteRow,
      BaseReferences<_$LibraryDatabase, $FavouritesTable, FavouriteRow>
    ),
    FavouriteRow,
    PrefetchHooks Function()> {
  $$FavouritesTableTableManager(_$LibraryDatabase db, $FavouritesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavouritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavouritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavouritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> source = const Value.absent(),
            Value<String> providerId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<String> origin = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FavouritesCompanion(
            source: source,
            providerId: providerId,
            createdAt: createdAt,
            origin: origin,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String source,
            required String providerId,
            required int createdAt,
            Value<String> origin = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FavouritesCompanion.insert(
            source: source,
            providerId: providerId,
            createdAt: createdAt,
            origin: origin,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FavouritesTableProcessedTableManager = ProcessedTableManager<
    _$LibraryDatabase,
    $FavouritesTable,
    FavouriteRow,
    $$FavouritesTableFilterComposer,
    $$FavouritesTableOrderingComposer,
    $$FavouritesTableAnnotationComposer,
    $$FavouritesTableCreateCompanionBuilder,
    $$FavouritesTableUpdateCompanionBuilder,
    (
      FavouriteRow,
      BaseReferences<_$LibraryDatabase, $FavouritesTable, FavouriteRow>
    ),
    FavouriteRow,
    PrefetchHooks Function()>;
typedef $$LibraryPlaylistsTableCreateCompanionBuilder
    = LibraryPlaylistsCompanion Function({
  required String id,
  required String name,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$LibraryPlaylistsTableUpdateCompanionBuilder
    = LibraryPlaylistsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$LibraryPlaylistsTableReferences extends BaseReferences<
    _$LibraryDatabase, $LibraryPlaylistsTable, LibraryPlaylistRow> {
  $$LibraryPlaylistsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistEntriesTable, List<PlaylistEntryRow>>
      _playlistEntriesRefsTable(_$LibraryDatabase db) =>
          MultiTypedResultKey.fromTable(db.playlistEntries,
              aliasName: 'playlists__id__playlist_entries__playlist_id');

  $$PlaylistEntriesTableProcessedTableManager get playlistEntriesRefs {
    final manager = $$PlaylistEntriesTableTableManager(
            $_db, $_db.playlistEntries)
        .filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_playlistEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LibraryPlaylistsTableFilterComposer
    extends Composer<_$LibraryDatabase, $LibraryPlaylistsTable> {
  $$LibraryPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> playlistEntriesRefs(
      Expression<bool> Function($$PlaylistEntriesTableFilterComposer f) f) {
    final $$PlaylistEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playlistEntries,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistEntriesTableFilterComposer(
              $db: $db,
              $table: $db.playlistEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LibraryPlaylistsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $LibraryPlaylistsTable> {
  $$LibraryPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LibraryPlaylistsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $LibraryPlaylistsTable> {
  $$LibraryPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> playlistEntriesRefs<T extends Object>(
      Expression<T> Function($$PlaylistEntriesTableAnnotationComposer a) f) {
    final $$PlaylistEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playlistEntries,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.playlistEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LibraryPlaylistsTableTableManager extends RootTableManager<
    _$LibraryDatabase,
    $LibraryPlaylistsTable,
    LibraryPlaylistRow,
    $$LibraryPlaylistsTableFilterComposer,
    $$LibraryPlaylistsTableOrderingComposer,
    $$LibraryPlaylistsTableAnnotationComposer,
    $$LibraryPlaylistsTableCreateCompanionBuilder,
    $$LibraryPlaylistsTableUpdateCompanionBuilder,
    (LibraryPlaylistRow, $$LibraryPlaylistsTableReferences),
    LibraryPlaylistRow,
    PrefetchHooks Function({bool playlistEntriesRefs})> {
  $$LibraryPlaylistsTableTableManager(
      _$LibraryDatabase db, $LibraryPlaylistsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LibraryPlaylistsCompanion(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LibraryPlaylistsCompanion.insert(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LibraryPlaylistsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({playlistEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistEntriesRefs) db.playlistEntries
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistEntriesRefs)
                    await $_getPrefetchedData<LibraryPlaylistRow,
                            $LibraryPlaylistsTable, PlaylistEntryRow>(
                        currentTable: table,
                        referencedTable: $$LibraryPlaylistsTableReferences
                            ._playlistEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LibraryPlaylistsTableReferences(db, table, p0)
                                .playlistEntriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.playlistId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LibraryPlaylistsTableProcessedTableManager = ProcessedTableManager<
    _$LibraryDatabase,
    $LibraryPlaylistsTable,
    LibraryPlaylistRow,
    $$LibraryPlaylistsTableFilterComposer,
    $$LibraryPlaylistsTableOrderingComposer,
    $$LibraryPlaylistsTableAnnotationComposer,
    $$LibraryPlaylistsTableCreateCompanionBuilder,
    $$LibraryPlaylistsTableUpdateCompanionBuilder,
    (LibraryPlaylistRow, $$LibraryPlaylistsTableReferences),
    LibraryPlaylistRow,
    PrefetchHooks Function({bool playlistEntriesRefs})>;
typedef $$PlaylistEntriesTableCreateCompanionBuilder = PlaylistEntriesCompanion
    Function({
  required String id,
  required String playlistId,
  required String source,
  required String providerId,
  required int position,
  required int addedAt,
  Value<int> rowid,
});
typedef $$PlaylistEntriesTableUpdateCompanionBuilder = PlaylistEntriesCompanion
    Function({
  Value<String> id,
  Value<String> playlistId,
  Value<String> source,
  Value<String> providerId,
  Value<int> position,
  Value<int> addedAt,
  Value<int> rowid,
});

final class $$PlaylistEntriesTableReferences extends BaseReferences<
    _$LibraryDatabase, $PlaylistEntriesTable, PlaylistEntryRow> {
  $$PlaylistEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LibraryPlaylistsTable _playlistIdTable(_$LibraryDatabase db) =>
      db.libraryPlaylists
          .createAlias('playlist_entries__playlist_id__playlists__id');

  $$LibraryPlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager =
        $$LibraryPlaylistsTableTableManager($_db, $_db.libraryPlaylists)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PlaylistEntriesTableFilterComposer
    extends Composer<_$LibraryDatabase, $PlaylistEntriesTable> {
  $$PlaylistEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  $$LibraryPlaylistsTableFilterComposer get playlistId {
    final $$LibraryPlaylistsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.libraryPlaylists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LibraryPlaylistsTableFilterComposer(
              $db: $db,
              $table: $db.libraryPlaylists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaylistEntriesTableOrderingComposer
    extends Composer<_$LibraryDatabase, $PlaylistEntriesTable> {
  $$PlaylistEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  $$LibraryPlaylistsTableOrderingComposer get playlistId {
    final $$LibraryPlaylistsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.libraryPlaylists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LibraryPlaylistsTableOrderingComposer(
              $db: $db,
              $table: $db.libraryPlaylists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaylistEntriesTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $PlaylistEntriesTable> {
  $$PlaylistEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$LibraryPlaylistsTableAnnotationComposer get playlistId {
    final $$LibraryPlaylistsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.libraryPlaylists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LibraryPlaylistsTableAnnotationComposer(
              $db: $db,
              $table: $db.libraryPlaylists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaylistEntriesTableTableManager extends RootTableManager<
    _$LibraryDatabase,
    $PlaylistEntriesTable,
    PlaylistEntryRow,
    $$PlaylistEntriesTableFilterComposer,
    $$PlaylistEntriesTableOrderingComposer,
    $$PlaylistEntriesTableAnnotationComposer,
    $$PlaylistEntriesTableCreateCompanionBuilder,
    $$PlaylistEntriesTableUpdateCompanionBuilder,
    (PlaylistEntryRow, $$PlaylistEntriesTableReferences),
    PlaylistEntryRow,
    PrefetchHooks Function({bool playlistId})> {
  $$PlaylistEntriesTableTableManager(
      _$LibraryDatabase db, $PlaylistEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> playlistId = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> providerId = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> addedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistEntriesCompanion(
            id: id,
            playlistId: playlistId,
            source: source,
            providerId: providerId,
            position: position,
            addedAt: addedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String playlistId,
            required String source,
            required String providerId,
            required int position,
            required int addedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistEntriesCompanion.insert(
            id: id,
            playlistId: playlistId,
            source: source,
            providerId: providerId,
            position: position,
            addedAt: addedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlaylistEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (playlistId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.playlistId,
                    referencedTable:
                        $$PlaylistEntriesTableReferences._playlistIdTable(db),
                    referencedColumn: $$PlaylistEntriesTableReferences
                        ._playlistIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PlaylistEntriesTableProcessedTableManager = ProcessedTableManager<
    _$LibraryDatabase,
    $PlaylistEntriesTable,
    PlaylistEntryRow,
    $$PlaylistEntriesTableFilterComposer,
    $$PlaylistEntriesTableOrderingComposer,
    $$PlaylistEntriesTableAnnotationComposer,
    $$PlaylistEntriesTableCreateCompanionBuilder,
    $$PlaylistEntriesTableUpdateCompanionBuilder,
    (PlaylistEntryRow, $$PlaylistEntriesTableReferences),
    PlaylistEntryRow,
    PrefetchHooks Function({bool playlistId})>;
typedef $$ListeningEventsTableCreateCompanionBuilder = ListeningEventsCompanion
    Function({
  Value<int> id,
  required String source,
  required String providerId,
  required int listenedAt,
  Value<int> listenedMs,
  Value<bool> completed,
  Value<bool> earlySkip,
  Value<bool> privateSession,
});
typedef $$ListeningEventsTableUpdateCompanionBuilder = ListeningEventsCompanion
    Function({
  Value<int> id,
  Value<String> source,
  Value<String> providerId,
  Value<int> listenedAt,
  Value<int> listenedMs,
  Value<bool> completed,
  Value<bool> earlySkip,
  Value<bool> privateSession,
});

class $$ListeningEventsTableFilterComposer
    extends Composer<_$LibraryDatabase, $ListeningEventsTable> {
  $$ListeningEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get listenedAt => $composableBuilder(
      column: $table.listenedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get listenedMs => $composableBuilder(
      column: $table.listenedMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get earlySkip => $composableBuilder(
      column: $table.earlySkip, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get privateSession => $composableBuilder(
      column: $table.privateSession,
      builder: (column) => ColumnFilters(column));
}

class $$ListeningEventsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $ListeningEventsTable> {
  $$ListeningEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get listenedAt => $composableBuilder(
      column: $table.listenedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get listenedMs => $composableBuilder(
      column: $table.listenedMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get earlySkip => $composableBuilder(
      column: $table.earlySkip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get privateSession => $composableBuilder(
      column: $table.privateSession,
      builder: (column) => ColumnOrderings(column));
}

class $$ListeningEventsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $ListeningEventsTable> {
  $$ListeningEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<int> get listenedAt => $composableBuilder(
      column: $table.listenedAt, builder: (column) => column);

  GeneratedColumn<int> get listenedMs => $composableBuilder(
      column: $table.listenedMs, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<bool> get earlySkip =>
      $composableBuilder(column: $table.earlySkip, builder: (column) => column);

  GeneratedColumn<bool> get privateSession => $composableBuilder(
      column: $table.privateSession, builder: (column) => column);
}

class $$ListeningEventsTableTableManager extends RootTableManager<
    _$LibraryDatabase,
    $ListeningEventsTable,
    ListeningEventRow,
    $$ListeningEventsTableFilterComposer,
    $$ListeningEventsTableOrderingComposer,
    $$ListeningEventsTableAnnotationComposer,
    $$ListeningEventsTableCreateCompanionBuilder,
    $$ListeningEventsTableUpdateCompanionBuilder,
    (
      ListeningEventRow,
      BaseReferences<_$LibraryDatabase, $ListeningEventsTable,
          ListeningEventRow>
    ),
    ListeningEventRow,
    PrefetchHooks Function()> {
  $$ListeningEventsTableTableManager(
      _$LibraryDatabase db, $ListeningEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListeningEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListeningEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListeningEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> providerId = const Value.absent(),
            Value<int> listenedAt = const Value.absent(),
            Value<int> listenedMs = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<bool> earlySkip = const Value.absent(),
            Value<bool> privateSession = const Value.absent(),
          }) =>
              ListeningEventsCompanion(
            id: id,
            source: source,
            providerId: providerId,
            listenedAt: listenedAt,
            listenedMs: listenedMs,
            completed: completed,
            earlySkip: earlySkip,
            privateSession: privateSession,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String source,
            required String providerId,
            required int listenedAt,
            Value<int> listenedMs = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<bool> earlySkip = const Value.absent(),
            Value<bool> privateSession = const Value.absent(),
          }) =>
              ListeningEventsCompanion.insert(
            id: id,
            source: source,
            providerId: providerId,
            listenedAt: listenedAt,
            listenedMs: listenedMs,
            completed: completed,
            earlySkip: earlySkip,
            privateSession: privateSession,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ListeningEventsTableProcessedTableManager = ProcessedTableManager<
    _$LibraryDatabase,
    $ListeningEventsTable,
    ListeningEventRow,
    $$ListeningEventsTableFilterComposer,
    $$ListeningEventsTableOrderingComposer,
    $$ListeningEventsTableAnnotationComposer,
    $$ListeningEventsTableCreateCompanionBuilder,
    $$ListeningEventsTableUpdateCompanionBuilder,
    (
      ListeningEventRow,
      BaseReferences<_$LibraryDatabase, $ListeningEventsTable,
          ListeningEventRow>
    ),
    ListeningEventRow,
    PrefetchHooks Function()>;
typedef $$ResumePositionsTableCreateCompanionBuilder = ResumePositionsCompanion
    Function({
  required String source,
  required String providerId,
  required int positionMs,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$ResumePositionsTableUpdateCompanionBuilder = ResumePositionsCompanion
    Function({
  Value<String> source,
  Value<String> providerId,
  Value<int> positionMs,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$ResumePositionsTableFilterComposer
    extends Composer<_$LibraryDatabase, $ResumePositionsTable> {
  $$ResumePositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get positionMs => $composableBuilder(
      column: $table.positionMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ResumePositionsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $ResumePositionsTable> {
  $$ResumePositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get positionMs => $composableBuilder(
      column: $table.positionMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ResumePositionsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $ResumePositionsTable> {
  $$ResumePositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
      column: $table.positionMs, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ResumePositionsTableTableManager extends RootTableManager<
    _$LibraryDatabase,
    $ResumePositionsTable,
    ResumePositionRow,
    $$ResumePositionsTableFilterComposer,
    $$ResumePositionsTableOrderingComposer,
    $$ResumePositionsTableAnnotationComposer,
    $$ResumePositionsTableCreateCompanionBuilder,
    $$ResumePositionsTableUpdateCompanionBuilder,
    (
      ResumePositionRow,
      BaseReferences<_$LibraryDatabase, $ResumePositionsTable,
          ResumePositionRow>
    ),
    ResumePositionRow,
    PrefetchHooks Function()> {
  $$ResumePositionsTableTableManager(
      _$LibraryDatabase db, $ResumePositionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResumePositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResumePositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResumePositionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> source = const Value.absent(),
            Value<String> providerId = const Value.absent(),
            Value<int> positionMs = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ResumePositionsCompanion(
            source: source,
            providerId: providerId,
            positionMs: positionMs,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String source,
            required String providerId,
            required int positionMs,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ResumePositionsCompanion.insert(
            source: source,
            providerId: providerId,
            positionMs: positionMs,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ResumePositionsTableProcessedTableManager = ProcessedTableManager<
    _$LibraryDatabase,
    $ResumePositionsTable,
    ResumePositionRow,
    $$ResumePositionsTableFilterComposer,
    $$ResumePositionsTableOrderingComposer,
    $$ResumePositionsTableAnnotationComposer,
    $$ResumePositionsTableCreateCompanionBuilder,
    $$ResumePositionsTableUpdateCompanionBuilder,
    (
      ResumePositionRow,
      BaseReferences<_$LibraryDatabase, $ResumePositionsTable,
          ResumePositionRow>
    ),
    ResumePositionRow,
    PrefetchHooks Function()>;
typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  required String source,
  required String providerId,
  required String status,
  Value<String?> localPath,
  Value<int> bytesReceived,
  Value<int?> expectedBytes,
  Value<String?> error,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> source,
  Value<String> providerId,
  Value<String> status,
  Value<String?> localPath,
  Value<int> bytesReceived,
  Value<int?> expectedBytes,
  Value<String?> error,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$DownloadsTableFilterComposer
    extends Composer<_$LibraryDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bytesReceived => $composableBuilder(
      column: $table.bytesReceived, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expectedBytes => $composableBuilder(
      column: $table.expectedBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bytesReceived => $composableBuilder(
      column: $table.bytesReceived,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expectedBytes => $composableBuilder(
      column: $table.expectedBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get bytesReceived => $composableBuilder(
      column: $table.bytesReceived, builder: (column) => column);

  GeneratedColumn<int> get expectedBytes => $composableBuilder(
      column: $table.expectedBytes, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DownloadsTableTableManager extends RootTableManager<
    _$LibraryDatabase,
    $DownloadsTable,
    DownloadRow,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableAnnotationComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (
      DownloadRow,
      BaseReferences<_$LibraryDatabase, $DownloadsTable, DownloadRow>
    ),
    DownloadRow,
    PrefetchHooks Function()> {
  $$DownloadsTableTableManager(_$LibraryDatabase db, $DownloadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> source = const Value.absent(),
            Value<String> providerId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<int> bytesReceived = const Value.absent(),
            Value<int?> expectedBytes = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadsCompanion(
            source: source,
            providerId: providerId,
            status: status,
            localPath: localPath,
            bytesReceived: bytesReceived,
            expectedBytes: expectedBytes,
            error: error,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String source,
            required String providerId,
            required String status,
            Value<String?> localPath = const Value.absent(),
            Value<int> bytesReceived = const Value.absent(),
            Value<int?> expectedBytes = const Value.absent(),
            Value<String?> error = const Value.absent(),
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadsCompanion.insert(
            source: source,
            providerId: providerId,
            status: status,
            localPath: localPath,
            bytesReceived: bytesReceived,
            expectedBytes: expectedBytes,
            error: error,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DownloadsTableProcessedTableManager = ProcessedTableManager<
    _$LibraryDatabase,
    $DownloadsTable,
    DownloadRow,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableAnnotationComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (
      DownloadRow,
      BaseReferences<_$LibraryDatabase, $DownloadsTable, DownloadRow>
    ),
    DownloadRow,
    PrefetchHooks Function()>;
typedef $$SourcePreferencesTableCreateCompanionBuilder
    = SourcePreferencesCompanion Function({
  required String source,
  required String key,
  required String value,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$SourcePreferencesTableUpdateCompanionBuilder
    = SourcePreferencesCompanion Function({
  Value<String> source,
  Value<String> key,
  Value<String> value,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$SourcePreferencesTableFilterComposer
    extends Composer<_$LibraryDatabase, $SourcePreferencesTable> {
  $$SourcePreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SourcePreferencesTableOrderingComposer
    extends Composer<_$LibraryDatabase, $SourcePreferencesTable> {
  $$SourcePreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SourcePreferencesTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $SourcePreferencesTable> {
  $$SourcePreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SourcePreferencesTableTableManager extends RootTableManager<
    _$LibraryDatabase,
    $SourcePreferencesTable,
    SourcePreferenceRow,
    $$SourcePreferencesTableFilterComposer,
    $$SourcePreferencesTableOrderingComposer,
    $$SourcePreferencesTableAnnotationComposer,
    $$SourcePreferencesTableCreateCompanionBuilder,
    $$SourcePreferencesTableUpdateCompanionBuilder,
    (
      SourcePreferenceRow,
      BaseReferences<_$LibraryDatabase, $SourcePreferencesTable,
          SourcePreferenceRow>
    ),
    SourcePreferenceRow,
    PrefetchHooks Function()> {
  $$SourcePreferencesTableTableManager(
      _$LibraryDatabase db, $SourcePreferencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcePreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcePreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcePreferencesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> source = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SourcePreferencesCompanion(
            source: source,
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String source,
            required String key,
            required String value,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SourcePreferencesCompanion.insert(
            source: source,
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SourcePreferencesTableProcessedTableManager = ProcessedTableManager<
    _$LibraryDatabase,
    $SourcePreferencesTable,
    SourcePreferenceRow,
    $$SourcePreferencesTableFilterComposer,
    $$SourcePreferencesTableOrderingComposer,
    $$SourcePreferencesTableAnnotationComposer,
    $$SourcePreferencesTableCreateCompanionBuilder,
    $$SourcePreferencesTableUpdateCompanionBuilder,
    (
      SourcePreferenceRow,
      BaseReferences<_$LibraryDatabase, $SourcePreferencesTable,
          SourcePreferenceRow>
    ),
    SourcePreferenceRow,
    PrefetchHooks Function()>;

class $LibraryDatabaseManager {
  final _$LibraryDatabase _db;
  $LibraryDatabaseManager(this._db);
  $$LibraryTracksTableTableManager get libraryTracks =>
      $$LibraryTracksTableTableManager(_db, _db.libraryTracks);
  $$FavouritesTableTableManager get favourites =>
      $$FavouritesTableTableManager(_db, _db.favourites);
  $$LibraryPlaylistsTableTableManager get libraryPlaylists =>
      $$LibraryPlaylistsTableTableManager(_db, _db.libraryPlaylists);
  $$PlaylistEntriesTableTableManager get playlistEntries =>
      $$PlaylistEntriesTableTableManager(_db, _db.playlistEntries);
  $$ListeningEventsTableTableManager get listeningEvents =>
      $$ListeningEventsTableTableManager(_db, _db.listeningEvents);
  $$ResumePositionsTableTableManager get resumePositions =>
      $$ResumePositionsTableTableManager(_db, _db.resumePositions);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
  $$SourcePreferencesTableTableManager get sourcePreferences =>
      $$SourcePreferencesTableTableManager(_db, _db.sourcePreferences);
}
