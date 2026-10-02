import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/services/youtube_related_provider.dart';

void main() {
  test('related music rejects a different credited artist', () {
    expect(
        isRelatedMusicArtist('Rick Astley',
            candidateArtist: 'Krishna Lofi Vibes',
            candidateTitle: 'Shri Krishna Govind Hare Murari'),
        isFalse);
    expect(
        isRelatedMusicArtist('Rick Astley',
            candidateArtist: 'Rick Astley', candidateTitle: 'Together Forever'),
        isTrue);
    expect(
        isRelatedMusicArtist('Rick Astley',
            candidateArtist: 'Archive Music',
            candidateTitle: 'Rick Astley - Together Forever'),
        isTrue);
    expect(
        isRelatedMusicArtist('Various Artists',
            candidateArtist: 'Archive Music',
            candidateTitle: 'Various Artists Mix'),
        isFalse);
  });

  test('candidate windows retain remaining entries from the same page', () {
    final page = List.generate(8, (index) => index);
    expect(relatedCandidateWindow(page, 0), [0, 1, 2]);
    expect(relatedCandidateWindow(page, 3), [3, 4, 5]);
    expect(relatedCandidateWindow(page, 6), [6, 7]);
    expect(relatedCandidateWindow(page, 9), isEmpty);
  });

  test('fetches a seed and advances the same paged session', () async {
    final gateway = _Gateway();
    final provider = YouTubeRelatedProvider(gateway: gateway);
    final first = await provider.fetch('seed', null);
    final next = await provider.fetch('seed', first.continuation);
    expect(gateway.initialCalls, ['seed']);
    expect(gateway.nextCalls, 1);
    expect(first.entities.single.videoId, 'one');
    expect(next.entities.single.videoId, 'two');
    expect(
        first.entities.every((entity) => entity.type.name == 'track'), isTrue);
    expect(next.continuation, isNull);
    provider.close();
    expect(gateway.closed, isTrue);
  });

  test('used cursor cannot be replayed after advancing', () async {
    final gateway = _Gateway();
    final provider = YouTubeRelatedProvider(gateway: gateway);
    final first = await provider.fetch('seed', null);
    await provider.fetch('seed', first.continuation);
    await expectLater(
      provider.fetch('seed', first.continuation),
      throwsA(isA<StateError>()),
    );
    expect(gateway.nextCalls, 1);
    provider.close();
  });

  test('stale cursor cannot advance a replacement seed', () async {
    final gateway = _Gateway();
    final provider = YouTubeRelatedProvider(gateway: gateway);
    final old = await provider.fetch('old', null);
    await provider.fetch('new', null);
    await expectLater(
      provider.fetch('old', old.continuation),
      throwsA(isA<StateError>()),
    );
    expect(gateway.nextCalls, 0);
    provider.close();
  });
}

class _Gateway implements RelatedVideoGateway {
  final initialCalls = <String>[];
  int nextCalls = 0;
  bool closed = false;

  @override
  Future<RelatedVideoPage?> initial(String videoId) async {
    initialCalls.add(videoId);
    return RelatedVideoPage(
      videos: [
        RelatedVideo(id: 'one', title: 'One', artist: 'Artist', isMusic: true),
        RelatedVideo(
            id: 'talk', title: 'Talk', artist: 'Speaker', isMusic: false),
      ],
      next: () async {
        nextCalls++;
        return RelatedVideoPage(
          videos: [
            RelatedVideo(
                id: 'two', title: 'Two', artist: 'Artist', isMusic: true)
          ],
        );
      },
    );
  }

  @override
  void close() => closed = true;
}
