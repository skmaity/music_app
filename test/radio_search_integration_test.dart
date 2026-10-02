import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/settings_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/playback_resolver.dart';
import 'package:music_app/services/radio_session.dart';

class _RecordingPlayer extends SongController {
  _RecordingPlayer({required super.playbackResolver, super.radioFetch});
  List<MySongs>? received;
  @override
  Future<void> playQueue(List<MySongs> songs, int index) async {
    received = List.of(songs);
  }
}

TrackRef _ref(String id) => TrackRef(
      source: TrackSource.youtube,
      providerId: id,
      title: id,
      artist: 'Artist',
    );

class _RadioRecordingPlayer extends _RecordingPlayer {
  _RadioRecordingPlayer({
    required super.playbackResolver,
    required FetchRelatedTracks radioFetch,
    required this.appended,
  }) : super(radioFetch: radioFetch);

  final Completer<MySongs> appended;
  @override
  Future<void> appendRadioRecommendation(MySongs song) async {
    appended.complete(song);
  }
}

class _Settings extends SettingsController {
  @override
  // No plugin initialization in this controller test.
  // ignore: must_call_super
  void onInit() {}
}

class _BackgroundRecorder extends BackgroundController {
  @override
  Future<void> updatePaletteGenerator() async {}
}

class _NativeQueueRecorder extends AudioPlayer {
  final added = <AudioSource>[];
  final inserted = <(int, AudioSource)>[];
  final removed = <int>[];
  @override
  Future<Duration?> setAudioSources(List<AudioSource> audioSources,
          {bool preload = true,
          int? initialIndex,
          Duration? initialPosition,
          ShuffleOrder? shuffleOrder}) async =>
      null;
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> removeAudioSourceAt(int index) async {
    removed.add(index);
  }

  @override
  Future<void> addAudioSource(AudioSource audioSource) async {
    added.add(audioSource);
  }

  @override
  Future<void> insertAudioSource(int index, AudioSource audioSource) async {
    inserted.add((index, audioSource));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.put<SettingsController>(_Settings());
  });
  tearDown(Get.reset);
  test('disabling recommendations removes only upcoming suggested audio',
      () async {
    final controller = SongController();
    final native = _NativeQueueRecorder();
    controller.player = native;
    await controller.appendRadioRecommendation(
      _ref('playing').toSong().copyWith(streamHandle: _Handle()),
    );
    await controller.appendRadioRecommendation(
      _ref('suggested').toSong().copyWith(streamHandle: _Handle()),
    );
    final manual = MySongs(
      songid: 7,
      artist: 'Artist',
      coverurl: '',
      songurl: 'song.mp3',
      title: 'Manual',
      isquickpick: 0,
    );
    controller.currentIndex.value = 0;
    await controller.addToQueue(manual);
    await controller.stopRadioRecommendations();
    expect(native.removed, [2]);
    expect(controller.currentPlayingList.map((song) => song.title),
        ['playing', 'Manual']);
    expect(controller.recommendedStartIndex, 2);
  });

  test('manual Add to queue stays ahead of the native radio tail', () async {
    final controller = SongController();
    final native = _NativeQueueRecorder();
    controller.player = native;
    await controller.appendRadioRecommendation(
      _ref('playing').toSong().copyWith(streamHandle: _Handle()),
    );
    await controller.appendRadioRecommendation(
      _ref('suggested').toSong().copyWith(streamHandle: _Handle()),
    );
    controller.currentIndex.value = 0;
    final explicit = MySongs(
      songid: 7,
      artist: 'Artist',
      coverurl: '',
      songurl: 'song.mp3',
      title: 'Manual',
      isquickpick: 0,
    );
    await controller.addToQueue(explicit);
    expect(native.inserted.single.$1, 1);
    expect(controller.currentPlayingList.map((song) => song.title),
        ['playing', 'Manual', 'suggested']);
    expect(controller.recommendedStartIndex, 2);
  });

  test('native audio append carries a MediaItem for notification controls',
      () async {
    final controller = SongController();
    final native = _NativeQueueRecorder();
    controller.player = native;
    final song = _ref('music-next').toSong().copyWith(streamHandle: _Handle());
    await controller.appendRadioRecommendation(song);
    expect(native.added, hasLength(1));
    final source = native.added.single as IndexedAudioSource;
    expect(source.tag, isA<MediaItem>());
    expect((source.tag as MediaItem).id, song.identity);
    expect(controller.currentPlayingList.single, same(song));
  });

  test('real playQueue seed leaves a growable queue-kind mirror for radio',
      () async {
    final controller = SongController();
    final native = _NativeQueueRecorder();
    controller.player = native;
    Get.put<SongController>(controller);
    Get.put<BackgroundController>(_BackgroundRecorder());
    final seed = _ref('seed').toSong().copyWith(streamHandle: _Handle());
    await controller.playQueue([seed], 0);
    final next = _ref('next').toSong().copyWith(streamHandle: _Handle());
    await controller.appendRadioRecommendation(next);
    expect(native.added, hasLength(1));
    expect(controller.currentPlayingList.map((song) => song.identity),
        ['youtube:seed', 'youtube:next']);
  });

  test('unreadable recommended audio is skipped before native append',
      () async {
    final appended = Completer<MySongs>();
    final broken = _FailingHandle();
    final player = _RadioRecordingPlayer(
      playbackResolver: PlaybackResolver(
        resolveYoutube: (track) async => track.toSong().copyWith(
              streamHandle:
                  track.providerId == 'unreadable' ? broken : _Handle(),
            ),
      ),
      radioFetch: (_, __) async => RadioPage(
        tracks: [_ref('unreadable'), _ref('music-next')],
      ),
      appended: appended,
    );
    await player.playRadioSeed(_ref('seed'));
    final next = await appended.future.timeout(const Duration(seconds: 2));
    expect(next.identity, 'youtube:music-next');
    expect(broken.closed, isTrue);
  });

  test('radio continues past empty verified-music windows', () async {
    final appended = Completer<MySongs>();
    var pages = 0;
    final player = _RadioRecordingPlayer(
      playbackResolver: PlaybackResolver(
        resolveYoutube: (track) async =>
            track.toSong().copyWith(streamHandle: _Handle()),
      ),
      radioFetch: (_, __) async {
        pages++;
        return RadioPage(
          tracks: pages < 3 ? [] : [_ref('music-next')],
          continuation: pages < 3 ? 'window-$pages' : null,
        );
      },
      appended: appended,
    );
    await player.playRadioSeed(_ref('seed'));
    final next = await appended.future.timeout(const Duration(seconds: 2));
    expect(next.identity, 'youtube:music-next');
    expect(pages, 3);
  });

  test('buffered music survives a failed background refill', () async {
    final appended = Completer<MySongs>();
    final player = _RadioRecordingPlayer(
      playbackResolver: PlaybackResolver(
        resolveYoutube: (track) async =>
            track.toSong().copyWith(streamHandle: _Handle()),
      ),
      radioFetch: (seed, cursor) async {
        if (cursor != null) throw StateError('continuation unavailable');
        return RadioPage(
          tracks: [_ref('music-next')],
          continuation: 'next-page',
        );
      },
      appended: appended,
    );
    await player.playRadioSeed(_ref('seed'));
    final next = await appended.future.timeout(const Duration(seconds: 2));
    expect(next.identity, 'youtube:music-next');
  });

  test('searched music seed appends one audio recommendation to native queue',
      () async {
    final appended = Completer<MySongs>();
    final player = _RadioRecordingPlayer(
      playbackResolver: PlaybackResolver(
        resolveYoutube: (track) async =>
            track.toSong().copyWith(streamHandle: _Handle()),
      ),
      radioFetch: (seed, cursor) async {
        expect(seed.providerId, 'seed');
        expect(cursor, isNull);
        return RadioPage(tracks: [_ref('music-next')]);
      },
      appended: appended,
    );
    await player.playRadioSeed(_ref('seed'));
    final next = await appended.future.timeout(const Duration(seconds: 2));
    expect(player.received?.single.identity, 'youtube:seed');
    expect(next.identity, 'youtube:music-next');
    expect(next.streamHandle, isNotNull);
  });

  test('late previous seed cannot replace the newer player queue', () async {
    final oldRequest = Completer<MySongs>();
    final oldHandle = _Handle();
    final player = _RecordingPlayer(
      playbackResolver: PlaybackResolver(
        resolveYoutube: (track) => track.providerId == 'old'
            ? oldRequest.future
            : Future.value(track.toSong().copyWith(streamHandle: _Handle())),
      ),
    );
    TrackRef ref(String id) => TrackRef(
          source: TrackSource.youtube,
          providerId: id,
          title: id,
          artist: 'Artist',
        );
    final oldPlay = player.playRadioSeed(ref('old'));
    await player.playRadioSeed(ref('new'));
    oldRequest.complete(ref('old').toSong().copyWith(streamHandle: oldHandle));
    await oldPlay;
    expect(player.received?.single.identity, 'youtube:new');
    expect(oldHandle.closed, isTrue);
  });

  test(
      'a search seed resolves first and is handed directly to the native queue',
      () async {
    final player = _RecordingPlayer(
      playbackResolver: PlaybackResolver(
        resolveYoutube: (track) async => track.toSong().copyWith(
              streamHandle: _Handle(),
            ),
      ),
    );
    final seed = TrackRef(
      source: TrackSource.youtube,
      providerId: 'seed',
      title: 'Seed',
      artist: 'Artist',
    );
    await player.playRadioSeed(seed);
    expect(player.received?.single.identity, 'youtube:seed');
    expect(player.received?.single.streamHandle, isNotNull);
  });
}

class _FailingHandle extends _Handle {
  @override
  Stream<List<int>> open() => Stream.error(StateError('unreadable audio'));
}

class _Handle implements SongStreamHandle {
  bool closed = false;
  @override
  int get length => 1;
  @override
  String get mimeType => 'audio/mp4';
  @override
  Stream<List<int>> open() => Stream.value([1]);
  @override
  void close() => closed = true;
}
