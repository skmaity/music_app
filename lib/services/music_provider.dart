import 'package:music_app/model/source_capabilities.dart';
import 'package:music_app/model/track_ref.dart';

class MusicProviderPage {
  const MusicProviderPage({
    required this.items,
    this.continuation,
  });

  final List<TrackRef> items;
  final String? continuation;
}

class MusicProviderException implements Exception {
  const MusicProviderException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Capability-driven boundary shared by Local, Nyro Server and YouTube.
abstract interface class MusicProvider {
  TrackSource get source;
  SourceCapabilities get capabilities;
  bool get requiresInternet;

  Future<MusicProviderPage> quickPicks({String? continuation});
  Future<MusicProviderPage> loadSongs({String? continuation});
  Future<MusicProviderPage> search(
    String query, {
    String? continuation,
  });

  void close();
}
