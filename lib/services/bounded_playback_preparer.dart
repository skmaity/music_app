import 'package:music_app/model/playback_context.dart';
import 'package:music_app/model/song_model.dart';

typedef ResolveQueueEntry = Future<MySongs> Function(QueueEntry entry);

/// A bounded, ephemeral preparation window; never a second playback queue.
/// The native player owns a song once [takePrepared] transfers it.
final class BoundedPlaybackPreparer {
  BoundedPlaybackPreparer({required ResolveQueueEntry resolve})
      : _resolve = resolve;

  final ResolveQueueEntry _resolve;
  final Map<String, MySongs> _prepared = {};
  final Set<String> _transferred = {};
  int _generation = 0;
  bool _disposed = false;

  List<String> get preparedIds => List.unmodifiable(_prepared.keys);

  Future<void> prepare({
    required List<QueueEntry> queue,
    required int currentIndex,
  }) async {
    if (_disposed) throw StateError('Playback preparer was disposed.');
    if (currentIndex < 0 || currentIndex >= queue.length) {
      throw RangeError.index(currentIndex, queue, 'currentIndex');
    }
    final generation = ++_generation;
    final window = queue.skip(currentIndex).take(2).toList();
    final wanted = window.map((entry) => entry.id).toSet();
    _transferred.removeWhere((id) => !wanted.contains(id));
    for (final id in _prepared.keys.toList()) {
      if (!wanted.contains(id)) _close(_prepared.remove(id)!);
    }
    for (final entry in window) {
      if (_disposed || generation != _generation) return;
      if (_prepared.containsKey(entry.id) || _transferred.contains(entry.id)) {
        continue;
      }
      late MySongs song;
      try {
        song = await _resolve(entry);
      } catch (_) {
        if (_disposed || generation != _generation) return;
        rethrow;
      }
      if (_disposed ||
          generation != _generation ||
          !wanted.contains(entry.id)) {
        _close(song);
        return;
      }
      _prepared[entry.id] = song;
    }
  }

  /// Ownership passes to the native player; later eviction must not close it.
  MySongs? takePrepared(String entryId) {
    final song = _prepared.remove(entryId);
    if (song != null) _transferred.add(entryId);
    return song;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    for (final song in _prepared.values) {
      _close(song);
    }
    _prepared.clear();
    _transferred.clear();
  }

  static void _close(MySongs song) {
    try {
      song.streamHandle?.close();
    } catch (_) {
      // Failed cleanup must not prevent the remaining handles being released.
    }
  }
}
