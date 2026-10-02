import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/local_media_index.dart';
import 'package:music_app/services/local_music_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Android channel maps MediaStore rows without photo permission data',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LocalMediaPlatform.channel, (call) async {
      expect(call.method, 'queryAudio');
      return [
        {
          'contentUri': 'content://media/external/audio/media/5',
          'title': 'Channel song',
          'artist': 'Channel artist',
          'albumId': '3',
          'album': 'Channel album',
          'durationMs': 1200,
        },
      ];
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LocalMediaPlatform.channel, null));

    final rows = await AndroidMediaStoreGateway().queryAudio();

    expect(rows.single.title, 'Channel song');
    expect(rows.single.album, 'Channel album');
    expect(rows.single.durationMs, 1200);
  });

  test('permission refusal returns denied without querying MediaStore',
      () async {
    final gateway = _FakeLocalMediaGateway(
      permission: LocalMediaPermission.denied,
    );
    final index = LocalMediaIndex(gateway: gateway);

    final result = await index.refresh(requestPermission: false);

    expect(result.permission, LocalMediaPermission.denied);
    expect(result.tracks, isEmpty);
    expect(gateway.queryCount, 0);
  });

  test('granted rows keep content identity and normalize unknown metadata',
      () async {
    final gateway = _FakeLocalMediaGateway(
      permission: LocalMediaPermission.granted,
      records: const [
        LocalMediaRecord(
          contentUri: 'content://media/external/audio/media/42',
          title: '   ',
          artist: '<unknown>',
          albumId: '7',
          durationMs: 123000,
        ),
      ],
    );
    final index = LocalMediaIndex(gateway: gateway);

    final result = await index.refresh();
    final track = result.tracks.single;

    expect(
      track.stableKey,
      'local:content://media/external/audio/media/42',
    );
    expect(track.title, 'Unknown track');
    expect(track.artist, 'Unknown artist');
    expect(track.albumId, '7');
    expect(track.duration, const Duration(seconds: 123));
    expect(
      LocalMediaPlatform.contentUriFromArtworkRef(track.artworkRef!),
      track.providerId,
    );
  });

  test('search is case insensitive and refresh removes deleted media',
      () async {
    final gateway = _FakeLocalMediaGateway(
      permission: LocalMediaPermission.granted,
      records: const [
        LocalMediaRecord(
          contentUri: 'content://media/external/audio/media/1',
          title: 'Midnight Drive',
          artist: 'Nyro Artist',
          album: 'Night Routes',
        ),
        LocalMediaRecord(
          contentUri: 'content://media/external/audio/media/2',
          title: 'Morning Light',
          artist: 'Second Artist',
        ),
      ],
    );
    final index = LocalMediaIndex(gateway: gateway);
    await index.refresh();

    expect(index.search('NYRO').single.title, 'Midnight Drive');
    expect(index.search('routes').single.title, 'Midnight Drive');
    expect(index.search('light').single.providerId,
        'content://media/external/audio/media/2');

    gateway.records = const [];
    await index.refresh();
    expect(index.tracks, isEmpty);
  });

  test('local provider paginates a large media index', () async {
    final tracks = [
      for (var id = 1; id <= 3; id += 1)
        TrackRef(
          source: TrackSource.local,
          providerId: 'content://media/external/audio/media/$id',
          title: 'Track $id',
          artist: 'Artist',
        ),
    ];
    final provider = LocalMusicProvider(
      loadSongs: () async => tracks,
      pageSize: 2,
    );

    final first = await provider.loadSongs();
    final second = await provider.loadSongs(continuation: first.continuation);

    expect(first.items.map((track) => track.title), ['Track 1', 'Track 2']);
    expect(first.continuation, '2');
    expect(second.items.single.title, 'Track 3');
    expect(second.continuation, isNull);
  });

  test('local TrackRef restores its content URI for playback', () {
    final track = TrackRef(
      source: TrackSource.local,
      providerId: 'content://media/external/audio/media/42',
      title: 'Local track',
      artist: 'Artist',
    );

    final song = track.toSong();

    expect(song.isLocal, isTrue);
    expect(song.songurl, track.providerId);
    expect(
      song.mediaUri('https://unused.invalid'),
      Uri.parse(track.providerId),
    );
  });

  test('player dispatches a local song to its content URI', () {
    final song = TrackRef(
      source: TrackSource.local,
      providerId: 'content://media/external/audio/media/42',
      title: 'Local track',
      artist: 'Artist',
    ).toSong();
    final controller = SongController();
    addTearDown(controller.player.dispose);

    final source = controller.buildAudioSource(song);

    expect(source, isA<UriAudioSource>());
    expect((source as UriAudioSource).uri, Uri.parse(song.songurl));
  });

  test('unavailable local track is removed from now playing state', () {
    final song = TrackRef(
      source: TrackSource.local,
      providerId: 'content://media/external/audio/media/99',
      title: 'Deleted track',
      artist: 'Artist',
    ).toSong();
    final controller = SongController();
    addTearDown(controller.player.dispose);
    controller.currentPlayingList.add(song);
    controller.currentPlaying.value = song;
    controller.currentIndex.value = 0;

    controller.handleUnavailableLocalSong(song, notify: false);

    expect(controller.currentPlayingList, isEmpty);
    expect(controller.currentIndex.value, -1);
    expect(controller.currentPlaying.value.isPlaceholder, isTrue);
  });

  test('unavailable duplicate removes only its failed queue occurrence', () {
    final local = TrackRef(
      source: TrackSource.local,
      providerId: 'content://media/external/audio/media/8',
      title: 'Duplicate local',
      artist: 'Artist',
    ).toSong();
    final other = TrackRef(
      source: TrackSource.nyroServer,
      providerId: '9',
      title: 'Other',
      artist: 'Artist',
    ).toSong();
    final controller = SongController();
    addTearDown(controller.player.dispose);
    controller.currentPlayingList.addAll([local, other, local]);

    controller.handleUnavailableLocalSong(
      local,
      queueIndex: 2,
      notify: false,
    );

    expect(controller.currentPlayingList, [local, other]);
  });

  test('player error index identifies only the failed queued local track', () {
    final server = TrackRef(
      source: TrackSource.nyroServer,
      providerId: '7',
      title: 'Server track',
      artist: 'Artist',
    ).toSong();
    final local = TrackRef(
      source: TrackSource.local,
      providerId: 'content://media/external/audio/media/8',
      title: 'Queued local',
      artist: 'Artist',
    ).toSong();
    final controller = SongController();
    addTearDown(controller.player.dispose);
    controller.currentPlayingList.addAll([server, local]);

    expect(
      controller.localSongForPlaybackError(PlayerException(0, 'missing', 1)),
      same(local),
    );
    expect(
      controller.localSongForPlaybackError(PlayerException(0, 'server', 0)),
      isNull,
    );
  });
}

class _FakeLocalMediaGateway implements LocalMediaGateway {
  _FakeLocalMediaGateway({
    required this.permission,
    this.records = const [],
  });

  LocalMediaPermission permission;
  List<LocalMediaRecord> records;
  int queryCount = 0;

  @override
  Future<LocalMediaPermission> checkPermission() async => permission;

  @override
  Future<LocalMediaPermission> requestPermission() async => permission;

  @override
  Future<List<LocalMediaRecord>> queryAudio() async {
    queryCount += 1;
    return records;
  }
}
