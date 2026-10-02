import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:permission_handler/permission_handler.dart';

/// User-visible access state for the platform media library.
enum LocalMediaPermission {
  granted,
  denied,
  permanentlyDenied,
  unsupported,
}

/// Platform-neutral MediaStore row.
class LocalMediaRecord {
  const LocalMediaRecord({
    required this.contentUri,
    required this.title,
    this.artist,
    this.albumId,
    this.album,
    this.durationMs,
  });

  final String contentUri;
  final String title;
  final String? artist;
  final String? albumId;
  final String? album;
  final int? durationMs;
}

/// Native media boundary. Tests use a fake; production uses Android MediaStore.
abstract interface class LocalMediaGateway {
  Future<LocalMediaPermission> checkPermission();
  Future<LocalMediaPermission> requestPermission();
  Future<List<LocalMediaRecord>> queryAudio();
}

/// Audio-only MediaStore adapter owned by Nyro.
///
/// This deliberately does not request photo access. Some generic audio-query
/// plugins require READ_MEDIA_IMAGES merely to read embedded cover art; Nyro
/// reads artwork from each granted audio content URI instead.
class AndroidMediaStoreGateway implements LocalMediaGateway {
  AndroidMediaStoreGateway({MethodChannel? channel})
      : _channel = channel ?? LocalMediaPlatform.channel;

  final MethodChannel _channel;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<LocalMediaPermission> checkPermission() async {
    if (!_supported) return LocalMediaPermission.unsupported;
    return _mapPermission(await (await _mediaPermission()).status);
  }

  @override
  Future<LocalMediaPermission> requestPermission() async {
    if (!_supported) return LocalMediaPermission.unsupported;
    return _mapPermission(await (await _mediaPermission()).request());
  }

  Future<Permission> _mediaPermission() async {
    final sdk = await _channel.invokeMethod<int>('sdkVersion') ?? 33;
    return sdk >= 33 ? Permission.audio : Permission.storage;
  }

  @override
  Future<List<LocalMediaRecord>> queryAudio() async {
    if (!_supported) return const [];
    final rows =
        await _channel.invokeListMethod<dynamic>('queryAudio') ?? const [];
    return rows.map((raw) {
      final row = Map<Object?, Object?>.from(raw as Map);
      return LocalMediaRecord(
        contentUri: row['contentUri'] as String,
        title: row['title'] as String? ?? '',
        artist: row['artist'] as String?,
        albumId: row['albumId'] as String?,
        album: row['album'] as String?,
        durationMs: (row['durationMs'] as num?)?.toInt(),
      );
    }).toList(growable: false);
  }

  static LocalMediaPermission _mapPermission(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return LocalMediaPermission.granted;
    }
    if (status.isPermanentlyDenied) {
      return LocalMediaPermission.permanentlyDenied;
    }
    return LocalMediaPermission.denied;
  }
}

abstract final class LocalMediaPlatform {
  static const channel = MethodChannel('com.nyro.app/local_media');
  static const _artworkPrefix = 'media-artwork:';

  static String artworkRef(String contentUri) =>
      '$_artworkPrefix${Uri.encodeComponent(contentUri)}';

  static String? contentUriFromArtworkRef(String value) {
    if (!value.startsWith(_artworkPrefix)) return null;
    try {
      return Uri.decodeComponent(value.substring(_artworkPrefix.length));
    } on FormatException {
      return null;
    }
  }

  static Future<bool> openSettings() => openAppSettings();

  static Future<Uint8List?> loadArtwork(String artworkRef) async {
    final uri = contentUriFromArtworkRef(artworkRef);
    if (uri == null) return null;
    return channel.invokeMethod<Uint8List>('loadArtwork', {'uri': uri});
  }
}

class LocalMediaIndexResult {
  const LocalMediaIndexResult({
    required this.permission,
    required this.tracks,
  });

  final LocalMediaPermission permission;
  final List<TrackRef> tracks;
}

/// Permission-safe, platform-neutral local library index.
class LocalMediaIndex {
  LocalMediaIndex({required LocalMediaGateway gateway}) : _gateway = gateway;

  final LocalMediaGateway _gateway;
  List<TrackRef> _tracks = const [];
  Map<String, String> _albumTitles = const {};

  List<TrackRef> get tracks => List.unmodifiable(_tracks);

  String albumTitle(TrackRef track) =>
      _albumTitles[track.providerId] ?? 'Unknown album';

  List<TrackRef> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return tracks;
    return _tracks
        .where((track) =>
            track.title.toLowerCase().contains(normalized) ||
            track.artist.toLowerCase().contains(normalized) ||
            albumTitle(track).toLowerCase().contains(normalized))
        .toList(growable: false);
  }

  Future<LocalMediaIndexResult> refresh({bool requestPermission = true}) async {
    var permission = await _gateway.checkPermission();
    if (permission == LocalMediaPermission.denied && requestPermission) {
      permission = await _gateway.requestPermission();
    }
    if (permission != LocalMediaPermission.granted) {
      _tracks = const [];
      _albumTitles = const {};
      return LocalMediaIndexResult(permission: permission, tracks: _tracks);
    }

    final records = await _gateway.queryAudio();
    _tracks = records.map(_trackFromRecord).toList(growable: false);
    _albumTitles = {
      for (final record in records)
        record.contentUri: _metadataOr(record.album, 'Unknown album'),
    };
    return LocalMediaIndexResult(permission: permission, tracks: tracks);
  }

  static TrackRef _trackFromRecord(LocalMediaRecord record) {
    return TrackRef(
      source: TrackSource.local,
      providerId: record.contentUri,
      title: _metadataOr(record.title, 'Unknown track'),
      artist: _metadataOr(record.artist, 'Unknown artist'),
      albumId: record.albumId,
      artworkRef: LocalMediaPlatform.artworkRef(record.contentUri),
      duration: record.durationMs == null || record.durationMs! < 0
          ? null
          : Duration(milliseconds: record.durationMs!),
    );
  }

  static String _metadataOr(String? value, String fallback) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty || normalized.toLowerCase() == '<unknown>'
        ? fallback
        : normalized;
  }
}
