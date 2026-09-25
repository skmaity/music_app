import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/services/youtube_audio_source.dart';
import 'package:music_app/services/youtube_source.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android reads bytes through the resolved continuous source',
      (_) async {
    final provider = YouTubeSource(timeout: const Duration(seconds: 30));
    SongStreamHandle? handle;
    try {
      final song = await provider.resolve(MySongs.youtube(
        videoId: 'aqz-KE-bpKQ',
        title: 'Big Buck Bunny',
        artist: 'Blender',
        artworkUrl: '',
      ));
      handle = song.streamHandle;
      final source = YouTubeAudioSource(handle: handle!);
      final response = await source.request(0, 1024);
      expect(response.offset, 0);
      expect(response.contentLength, 1024);
      expect(await response.stream.expand((chunk) => chunk).length, 1024);
    } finally {
      handle?.close();
      provider.close();
    }
  });

  testWidgets('Android playback remains active beyond the former 30s cutoff',
      (_) async {
    final provider = YouTubeSource(timeout: const Duration(seconds: 30));
    final player = AudioPlayer();
    SongStreamHandle? handle;
    try {
      final song = await provider.resolve(MySongs.youtube(
        videoId: '55148ftuI6o',
        title: 'Ghum Ghum Chand Jhikimiki Tara',
        artist: 'Bangla Children Song',
        artworkUrl: '',
      ));
      handle = song.streamHandle;
      await player.setAudioSource(YouTubeAudioSource(handle: handle!));
      unawaited(player.play());
      await Future<void>.delayed(const Duration(seconds: 42));
      expect(player.processingState, ProcessingState.ready);
      expect(player.playing, isTrue);
      expect(player.position, greaterThan(const Duration(seconds: 35)));
    } finally {
      await player.dispose();
      handle?.close();
      provider.close();
    }
  });
}
