// ignore_for_file: experimental_member_use

import 'dart:math' as math;

import 'package:just_audio/just_audio.dart';
import 'package:music_app/model/song_model.dart';

/// Pipes a provider-managed continuous stream through just_audio's local proxy.
/// The provider owns retries and signed-URL refreshes; seeking reopens the
/// stream and discards bytes up to the requested offset.
class YouTubeAudioSource extends StreamAudioSource {
  YouTubeAudioSource({required this.handle, super.tag});
  final SongStreamHandle handle;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final from = start ?? 0;
    final until = (end ?? handle.length).clamp(0, handle.length);
    if (handle.length <= 0 || from < 0 || from >= until) {
      throw RangeError('Invalid audio byte range');
    }
    return StreamAudioResponse(
      sourceLength: handle.length,
      contentLength: until - from,
      offset: from,
      contentType: handle.mimeType,
      stream: _slice(handle.open(), from, until - from),
    );
  }

  Stream<List<int>> _slice(Stream<List<int>> input, int skip, int take) async* {
    var toSkip = skip;
    var remaining = take;
    await for (final chunk in input) {
      if (toSkip >= chunk.length) {
        toSkip -= chunk.length;
        continue;
      }
      final begin = toSkip;
      toSkip = 0;
      final count = math.min(chunk.length - begin, remaining);
      if (count > 0) {
        yield chunk.sublist(begin, begin + count);
        remaining -= count;
      }
      if (remaining == 0) break;
    }
  }
}
