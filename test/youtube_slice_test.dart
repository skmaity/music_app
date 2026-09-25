import 'package:music_app/controller/recent_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/services/youtube_source.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/main_nav_pages/search_songs/controllers/search_song_controller.dart';

void main() {
  test('stream metadata survives in-memory copy but is not persisted', () {
    final song = MySongs.youtube(videoId: 'aqz-KE-bpKQ', title: 'Fixture',
        artist: 'Blender', artworkUrl: '')
      .copyWith(streamLength: 100, streamMimeType: 'audio/mp4');
    expect(song.copyWith(title: 'Renamed').streamLength, 100);
    expect(song.streamMimeType, 'audio/mp4');
    expect(song.toJson().containsKey('streamLength'), isFalse);
    expect(MySongs.fromJson(song.toJson()).streamLength, isNull);
  });

  test('provider search and resolution have bounded timeouts', () async {
    final source = YouTubeSource(
      timeout: const Duration(milliseconds: 5),
      search: (_) => Completer<List<MySongs>>().future,
      resolve: (_) => Completer<Uri?>().future,
    );
    addTearDown(source.close);
    await expectLater(source.search('fixture'), throwsA(isA<YouTubeSourceException>()));
    await expectLater(source.resolve(MySongs.youtube(videoId: 'aqz-KE-bpKQ',
        title: 'Fixture', artist: 'Blender', artworkUrl: '')),
        throwsA(isA<YouTubeSourceException>()));
  });

  test('experimental external tracks do not persist expired recents', () {
    final recent = RecentController();
    recent.record(MySongs.youtube(videoId: 'aqz-KE-bpKQ', title: 'Fixture',
        artist: 'Blender', artworkUrl: ''));
    expect(recent.recent, isEmpty);
  });

  test('unsupported external queue insertion fails before mutating queue', () async {
    final player = SongController();
    final song = MySongs.youtube(videoId: 'aqz-KE-bpKQ', title: 'Fixture',
        artist: 'Blender', artworkUrl: '');
    await expectLater(player.addToQueue(song), throwsA(isA<UnsupportedError>()));
    await expectLater(player.playNext(song), throwsA(isA<UnsupportedError>()));
    expect(player.currentPlayingList, isEmpty);
  });

  test('expiring stream URLs are never serialized', () {
    final song = MySongs.youtube(videoId: 'aqz-KE-bpKQ', title: 'Fixture',
        artist: 'Blender', artworkUrl: '')
        .copyWith(songurl: 'https://media.test/expiring');
    expect(song.toJson()['songurl'], isEmpty);
  });

  test('YouTube zero backend id is not an empty player', () {
    final song = MySongs.youtube(videoId: 'aqz-KE-bpKQ', title: 'Fixture',
        artist: 'Blender', artworkUrl: 'https://img.test/cover.jpg');
    expect(song.isPlaceholder, isFalse);
    expect(song.copyWith(source: SongSource.backend).isPlaceholder, isTrue);
  });

  test('stale results cannot arrive after controller closes', () async {
    final pending = Completer<List<MySongs>>();
    final source = YouTubeSource(search: (_) => pending.future);
    final controller = SearchSongController(youtube: source)
      ..selectSource(SearchSource.youtube);
    final request = controller.searchSong('old');
    controller.onClose();
    pending.complete([MySongs.youtube(videoId: 'aqz-KE-bpKQ', title: 'Late',
        artist: 'Fixture', artworkUrl: '')]);
    await request;
    expect(controller.searchSongResult, isEmpty);
  });

  test('source identity serializes without inventing a backend id', () {
    final song = MySongs.youtube(
      videoId: 'abc123',
      title: 'Fixture title',
      artist: 'Fixture artist',
      artworkUrl: 'https://example.test/cover.jpg',
    );

    final decoded = MySongs.fromJson(song.toJson());
    expect(decoded.songid, 0);
    expect(decoded.source, SongSource.youtube);
    expect(decoded.externalId, 'abc123');
    expect(decoded.identity, 'youtube:abc123');
  });

  test('backend and absolute media/artwork URIs resolve correctly', () {
    final backend = MySongs(
      songid: 7,
      title: 'Fixture',
      songurl: '/audio.mp3',
      coverurl: '/cover.jpg',
      artist: 'Artist',
      isquickpick: 0,
    );
    final external = MySongs.youtube(
      videoId: 'yt1',
      title: 'Fixture',
      artist: 'Artist',
      artworkUrl: 'https://img.test/cover.jpg',
    ).copyWith(songurl: 'https://media.test/audio');

    expect(backend.mediaUri('https://api.test').toString(),
        'https://api.test/audio.mp3');
    expect(backend.artworkUri('https://api.test').toString(),
        'https://api.test/cover.jpg');
    expect(external.mediaUri('https://api.test').toString(),
        'https://media.test/audio');
    expect(external.artworkUri('https://api.test').toString(),
        'https://img.test/cover.jpg');
  });

  test('resolve reports denied and empty audio without fake data', () async {
    final denied =
        YouTubeSource(resolve: (_) async => throw Exception('private'));
    final empty = YouTubeSource(resolve: (_) async => null);
    final song = MySongs.youtube(
      videoId: 'blocked',
      title: 'Fixture',
      artist: 'Artist',
      artworkUrl: 'https://img.test/x.jpg',
    );

    await expectLater(
        denied.resolve(song), throwsA(isA<YouTubeSourceException>()));
    await expectLater(
        empty.resolve(song), throwsA(isA<YouTubeSourceException>()));
  });

  test('each playback resolves a fresh expiring URL', () async {
    var calls = 0;
    final source = YouTubeSource(
      resolve: (_) async => Uri.parse('https://media.test/${++calls}'),
    );
    final song = MySongs.youtube(
      videoId: 'fresh',
      title: 'Fixture',
      artist: 'Artist',
      artworkUrl: 'https://img.test/x.jpg',
    );

    expect((await source.resolve(song)).songurl, 'https://media.test/1');
    expect((await source.resolve(song)).songurl, 'https://media.test/2');
  });

  test('only the latest search request owns results', () {
    final requests = LatestRequest();
    final oldRequest = requests.next();
    final newRequest = requests.next();
    expect(requests.owns(oldRequest), isFalse);
    expect(requests.owns(newRequest), isTrue);
  });
}
