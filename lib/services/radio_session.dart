import 'dart:async';

import 'package:music_app/model/track_ref.dart';

/// One metadata-only page returned by source-specific related-track discovery.
final class RadioPage {
  RadioPage({required Iterable<TrackRef> tracks, this.continuation})
      : tracks = List<TrackRef>.unmodifiable(tracks);

  final List<TrackRef> tracks;
  final String? continuation;
}

typedef FetchRelatedTracks = Future<RadioPage> Function(
  TrackRef seed,
  String? continuation,
);

/// Metadata-only radio buffer. The player/controller owns the native queue;
/// this session never prepares audio or starts playback.
final class RadioSession {
  RadioSession({
    required FetchRelatedTracks fetchRelated,
    this.targetBufferSize = 10,
    this.refillThreshold = 3,
    this.recentHistoryLimit = 100,
  }) : _fetchRelated = fetchRelated {
    if (targetBufferSize <= 0 ||
        refillThreshold <= 0 ||
        refillThreshold > targetBufferSize ||
        recentHistoryLimit <= 0) {
      throw ArgumentError('Radio buffer size and threshold must be positive, '
          'and the threshold cannot exceed the buffer size.');
    }
  }

  final FetchRelatedTracks _fetchRelated;
  final int targetBufferSize;
  final int refillThreshold;
  final int recentHistoryLimit;
  final List<TrackRef> _buffer = [];
  final Set<String> _seen = {};
  final List<String> _recent = [];
  TrackRef? _seed;
  String? _continuation;
  bool _stopped = true;
  int _generation = 0;
  Future<void>? _pending;

  TrackRef? get seed => _seed;
  List<TrackRef> get recommendations => List.unmodifiable(_buffer);
  String? get continuation => _continuation;
  bool get isStopped => _stopped;

  Future<void> start(TrackRef seed) {
    _generation++;
    _seed = seed;
    _stopped = false;
    _buffer.clear();
    _recent.clear();
    _seen
      ..clear()
      ..add(seed.stableKey);
    _continuation = null;
    _pending = null;
    return _fetchPage(_generation, seed, null);
  }

  TrackRef? takeNext() {
    if (_stopped || _buffer.isEmpty) return null;
    final track = _buffer.removeAt(0);
    _recent.add(track.stableKey);
    if (_recent.length > recentHistoryLimit) {
      final expired = _recent.removeAt(0);
      if (expired != _seed?.stableKey &&
          !_buffer.any((candidate) => candidate.stableKey == expired)) {
        _seen.remove(expired);
      }
    }
    return track;
  }

  Future<void> refillIfNeeded() {
    if (_stopped || _seed == null) return Future<void>.value();
    if (_pending != null) return _pending!;
    if (_buffer.length >= refillThreshold || _continuation == null) {
      return Future<void>.value();
    }
    final request = _fetchPage(_generation, _seed!, _continuation);
    _pending = request;
    request.whenComplete(() {
      if (identical(_pending, request)) _pending = null;
    }).ignore();
    return request;
  }

  Future<void> _fetchPage(int generation, TrackRef seed, String? cursor) async {
    late RadioPage page;
    try {
      page = await _fetchRelated(seed, cursor);
    } catch (_) {
      if (_stopped || generation != _generation) return;
      rethrow;
    }
    if (_stopped || generation != _generation) return;
    _continuation = page.continuation;
    for (final track in page.tracks) {
      if (_buffer.length >= targetBufferSize) break;
      if (track.source == seed.source && _seen.add(track.stableKey)) {
        _buffer.add(track);
      }
    }
  }

  void stop() {
    _generation++;
    _stopped = true;
    _seed = null;
    _continuation = null;
    _pending = null;
    _buffer.clear();
    _seen.clear();
    _recent.clear();
  }
}
