import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/services/youtube_audio_source.dart';

class FakeStreamHandle implements SongStreamHandle {
  FakeStreamHandle(this.bytes);
  final List<int> bytes;
  int opens = 0;
  bool closed = false;

  @override
  int get length => bytes.length;
  @override
  String get mimeType => 'audio/webm';
  @override
  Stream<List<int>> open() {
    opens++;
    return Stream.fromIterable([
      bytes.sublist(0, bytes.length ~/ 2),
      bytes.sublist(bytes.length ~/ 2),
    ]);
  }

  @override
  void close() => closed = true;
}

void main() {
  test('continuous request streams the whole resolved source once', () async {
    final handle = FakeStreamHandle(List.generate(10, (index) => index));
    final source = YouTubeAudioSource(handle: handle);

    final response = await source.request();

    expect(response.sourceLength, 10);
    expect(response.offset, 0);
    expect(response.contentLength, 10);
    expect(await response.stream.expand((chunk) => chunk).toList(),
        List.generate(10, (index) => index));
    expect(handle.opens, 1);
  });

  test('seek request skips bytes and stops at exclusive end', () async {
    final handle = FakeStreamHandle(List.generate(10, (index) => index));
    final source = YouTubeAudioSource(handle: handle);

    final response = await source.request(3, 7);

    expect(response.offset, 3);
    expect(response.contentLength, 4);
    expect(
        await response.stream.expand((chunk) => chunk).toList(), [3, 4, 5, 6]);
    expect(handle.opens, 1);
  });

  test('invalid ranges fail before opening provider stream', () async {
    final handle = FakeStreamHandle([1, 2, 3]);
    final source = YouTubeAudioSource(handle: handle);

    await expectLater(source.request(3), throwsRangeError);
    expect(handle.opens, 0);
  });

  test('handle remains open for retries and is explicitly closeable', () async {
    final handle = FakeStreamHandle([1, 2, 3]);
    final source = YouTubeAudioSource(handle: handle);

    await (await source.request()).stream.drain<void>();
    await (await source.request()).stream.drain<void>();
    expect(handle.opens, 2);
    expect(handle.closed, isFalse);

    handle.close();
    expect(handle.closed, isTrue);
  });
}
