import 'dart:async';

import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';

typedef ResolveTrackForPlayback = Future<MySongs> Function(TrackRef track);

/// A user-facing failure while converting stable metadata into playable media.
final class PlaybackResolutionException implements Exception {
  const PlaybackResolutionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Resolves a stable [TrackRef] only when playback needs a concrete source.
///
/// Persistent callers keep [TrackRef] values. Temporary network URLs and
/// [SongStreamHandle] instances exist only on the returned [MySongs] object and
/// are owned by the playback session that requested them.
final class PlaybackResolver {
  PlaybackResolver({
    ResolveTrackForPlayback? resolveNyroServer,
    ResolveTrackForPlayback? resolveYoutube,
    this.timeout = const Duration(seconds: 20),
  })  : _resolveNyroServer = resolveNyroServer,
        _resolveYoutube = resolveYoutube {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
  }

  final ResolveTrackForPlayback? _resolveNyroServer;
  final ResolveTrackForPlayback? _resolveYoutube;
  final Duration timeout;

  Future<MySongs> resolve(TrackRef track) async {
    if (track.source == TrackSource.local) {
      return _validate(track, track.toSong());
    }

    final sourceResolver = switch (track.source) {
      TrackSource.local => null,
      TrackSource.nyroServer => _resolveNyroServer,
      TrackSource.youtube => _resolveYoutube,
    };
    if (sourceResolver == null) {
      throw PlaybackResolutionException(
        '${track.source.label} playback resolver is unavailable.',
      );
    }

    Future<MySongs>? pending;
    try {
      pending = sourceResolver(track);
      final resolved = await pending.timeout(timeout);
      return _validate(track, resolved);
    } on TimeoutException {
      // Dart futures cannot be cancelled. If the provider finishes after the
      // timeout, close any handle it created instead of leaking it into a dead
      // playback request.
      final timedOutRequest = pending;
      if (timedOutRequest != null) {
        unawaited(
          timedOutRequest.then<void>(
            _closeQuietly,
            onError: (_) {},
          ),
        );
      }
      throw PlaybackResolutionException(
        '${track.source.label} playback resolution took too long.',
      );
    } on PlaybackResolutionException {
      rethrow;
    } catch (_) {
      throw PlaybackResolutionException(
        '${track.source.label} track could not be prepared for playback.',
      );
    }
  }

  MySongs _validate(TrackRef requested, MySongs resolved) {
    try {
      final resolvedRef = TrackRef.fromSong(resolved);
      if (resolvedRef.stableKey != requested.stableKey) {
        throw const PlaybackResolutionException(
          'The playback provider returned a different track.',
        );
      }

      switch (requested.source) {
        case TrackSource.local:
          final localUri = Uri.tryParse(requested.providerId);
          if (localUri == null ||
              localUri.scheme != 'content' ||
              !localUri.hasAuthority ||
              localUri.host.trim().isEmpty ||
              resolved.songurl != requested.providerId) {
            throw const PlaybackResolutionException(
              'The local playback location is not a valid content URI.',
            );
          }
        case TrackSource.nyroServer:
          if (resolved.songurl.trim().isEmpty) {
            throw const PlaybackResolutionException(
              'Nyro Server returned no playable media location.',
            );
          }
        case TrackSource.youtube:
          if (resolved.streamHandle == null) {
            throw const PlaybackResolutionException(
              'YouTube returned no playable audio stream.',
            );
          }
      }
      return resolved;
    } on PlaybackResolutionException {
      _closeQuietly(resolved);
      rethrow;
    } catch (_) {
      _closeQuietly(resolved);
      throw const PlaybackResolutionException(
        'The playback provider returned invalid track data.',
      );
    }
  }

  static void _closeQuietly(MySongs song) {
    try {
      song.streamHandle?.close();
    } catch (_) {
      // Cleanup must not replace the playback failure that triggered it.
    }
  }
}
