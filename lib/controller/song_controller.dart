import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/recent_controller.dart';
import 'package:music_app/controller/settings_controller.dart';
import 'package:music_app/controller/userid_controller.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/controller/user_favourite_controller.dart';
import 'package:music_app/model/repeat_mode.dart';
import 'package:music_app/model/playback_context.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/radio_session.dart';
import 'package:music_app/repositories/library_repository.dart';
import 'package:music_app/services/playback_resolver.dart';
import 'package:music_app/services/youtube_audio_source.dart';

/// The player, the queue, and everything hanging off "what is playing".
///
/// **The queue lives inside `just_audio`, not here.** This controller used to
/// load one track at a time with `setUrl` and walk the queue itself in Dart —
/// its own shuffle permutation, its own next/previous index maths, its own
/// race guard against a slow load. All of that is gone, because
/// `just_audio_background` builds the notification card out of the *player's*
/// state: skip buttons render only when `player.hasNext`/`hasPrevious` are
/// true, and with a single audio source they never are. A one-track-at-a-time
/// player can be backgrounded, but its notification is a play/pause button and
/// nothing else.
///
/// So [currentPlayingList] is now a mirror, kept in step for the UI's benefit,
/// and the player is the authority. Every transport control below delegates.
MySongs _placeholderSong() => MySongs(
      songid: 0,
      artist: 'artist',
      coverurl: 'coverurl',
      songurl: 'songurl',
      title: 'title',
      isquickpick: 0,
    );

class SongController extends GetxController {
  SongController({
    RecentController? history,
    LibraryRepository? library,
    PlaybackResolver? playbackResolver,
    FetchRelatedTracks? radioFetch,
    void Function()? closeRadioDiscovery,
  })  : _history = history,
        _library = library,
        _playbackResolver = playbackResolver,
        _radioFetch = radioFetch,
        _closeRadioDiscovery = closeRadioDiscovery;

  final RecentController? _history;
  final LibraryRepository? _library;
  final PlaybackResolver? _playbackResolver;
  final FetchRelatedTracks? _radioFetch;
  final void Function()? _closeRadioDiscovery;
  RadioSession? _radioSession;
  Worker? _recommendationToggleWorker;
  int? _radioAppendingGeneration;
  int _radioSeedGeneration = 0;
  late AudioPlayer player = AudioPlayer();

  RxBool isPlaying = false.obs;

  Rx<MySongs> currentPlaying = _placeholderSong().obs;
  RxInt currentIndex = (-1).obs;
  RxList<MySongs> currentPlayingList = <MySongs>[].obs;
  final RxList<QueueEntryKind> _queueKinds = <QueueEntryKind>[].obs;
  List<QueueEntryKind> get queueKinds => List.unmodifiable(_queueKinds);

  /// First upcoming recommended occurrence, or the queue length when absent.
  int get recommendedStartIndex {
    for (var i = currentIndex.value + 1; i < _queueKinds.length; i++) {
      if (_queueKinds[i] == QueueEntryKind.recommended) return i;
    }
    return currentPlayingList.length;
  }

  // Whether [currentPlaying] is in the user's favourites
  RxBool isFavourite = false.obs;

  // New variables for tracking song position and duration
  Rx<Duration> currentPosition = Duration.zero.obs;
  Rx<Duration> totalDuration = Duration.zero.obs;

  /// How much of the track has downloaded. Drives the seek bar's secondary
  /// track — the bar used to show played-vs-nothing, so a stall looked
  /// identical to a track that had buffered the whole way through.
  Rx<Duration> bufferedPosition = Duration.zero.obs;

  /// True while `just_audio` reports `loading` or `buffering`. Drives the
  /// play/pause button's spinner — without it, a track that hadn't started
  /// streaming yet looked identical to a frozen button.
  RxBool isBuffering = false.obs;

  /// Whether the index change now arriving was asked for by the user (a tap on
  /// next/previous, a queue-sheet jump, a new queue) rather than the player
  /// moving on by itself at the end of a track.
  ///
  /// Two settings need to tell those apart and there is no other way to: the
  /// player reports *that* the index changed, never *why*. Set immediately
  /// before any deliberate seek, and cleared by the listener that consumes it.
  bool _userSkip = false;

  /// The song identity and concrete audio-source occurrence most recently
  /// handled by the index listener.
  ///
  /// The occurrence is load-bearing: duplicate queue entries can have the same
  /// source-qualified song identity, while a reorder keeps the same AudioSource
  /// object and must not be misread as a new play.
  String? _lastSongIdentity;
  Object? _lastPlaybackOccurrence;
  int? _lastBackendSongId;
  StreamSubscription<PlaybackEvent>? _playbackErrorSubscription;

  // ---------------------------------------------------------------------
  // Audio sources
  // ---------------------------------------------------------------------

  /// Wraps a song as something the player — and therefore the notification,
  /// the lock screen and any connected bluetooth device — can describe.
  ///
  /// The [MediaItem] tag is the whole point. `just_audio` only needs the uri;
  /// everything the card shows (title, artist, artwork) reaches it through
  /// this tag and nowhere else.
  AudioSource buildAudioSource(MySongs song) {
    final tag = MediaItem(
        id: song.identity,
        title: song.title,
        artist: song.artist,
        artUri: song.artworkUri(baseUrl));
    return switch (song.source) {
      SongSource.backend => AudioSource.uri(song.mediaUri(baseUrl), tag: tag),
      SongSource.youtube => _youtubeSource(song, tag),
      SongSource.local => AudioSource.uri(song.mediaUri(baseUrl), tag: tag),
    };
  }

  AudioSource _youtubeSource(MySongs song, MediaItem tag) {
    final handle = song.streamHandle;
    if (handle == null) {
      throw StateError('YouTube track has no resolved stream handle.');
    }
    return YouTubeAudioSource(handle: handle, tag: tag);
  }

  // ---------------------------------------------------------------------
  // Shuffle
  // ---------------------------------------------------------------------

  /// Whether next/previous currently walk the player's shuffled order rather
  /// than the queue in sequence. Mirrors `player.shuffleModeEnabled` for the
  /// UI; the player holds the real flag and the real permutation.
  RxBool isShuffled = false.obs;

  /// Turns shuffle on or off. Never changes what's currently playing:
  /// `player.shuffle()` passes the current index into the shuffle order, which
  /// swaps that track to the head of the permutation — so arming shuffle only
  /// changes what "next" means from here.
  ///
  /// [currentPlayingList] is never reordered, so turning shuffle back off needs
  /// no data to restore, and the queue sheet keeps showing the real order.
  Future<void> toggleShuffle() async {
    final enabling = !isShuffled.value;

    if (enabling) {
      await _guardPlayerCall(() => player.shuffle(), 'Build shuffle order');
    }

    final applied = await _guardPlayerCall(
      () => player.setShuffleModeEnabled(enabling),
      'Shuffle',
    );
    if (applied) isShuffled.value = enabling;
  }

  // ---------------------------------------------------------------------
  // Repeat
  // ---------------------------------------------------------------------

  Rx<RepeatMode> repeatMode = RepeatMode.off.obs;

  LoopMode _loopModeFor(RepeatMode mode) => switch (mode) {
        RepeatMode.off => LoopMode.off,
        RepeatMode.all => LoopMode.all,
        RepeatMode.one => LoopMode.one,
      };

  /// off -> all -> one -> off.
  ///
  /// The mode is handed straight to the player, which is what makes it govern
  /// auto-advance *and* the notification's skip buttons at once — `hasNext` is
  /// derived from `loopMode`, so with repeat off at the end of a queue the
  /// card greys its own skip button without being told to.
  Future<void> cycleRepeatMode() async {
    final next = switch (repeatMode.value) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };

    final applied = await _guardPlayerCall(
      () => player.setLoopMode(_loopModeFor(next)),
      'Repeat',
    );
    if (applied) repeatMode.value = next;
  }

  // Initialize the audio player
  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<SettingsController>()) {
      _recommendationToggleWorker = ever<bool>(
        Get.find<SettingsController>().recommendationAutoplayEnabled,
        (enabled) {
          if (!enabled) unawaited(stopRadioRecommendations());
        },
      );
    }

    // Listen to position changes
    player.positionStream.listen((position) {
      currentPosition.value = position;
      recordPlaybackProgressForHistory(
        currentPlaying.value,
        position,
        playing: player.playing,
        ready: player.processingState == ProcessingState.ready,
      );
      _maybeSaveLastPosition(position);
    });

    // Listen to duration changes.
    //
    // `duration` is null whenever just_audio has no duration yet — which it
    // genuinely is between tracks, and for a stream it never resolves at all.
    // This used to force-unwrap, so the gap between one song ending and the
    // next resolving threw.
    player.durationStream.listen((duration) {
      totalDuration.value = duration ?? Duration.zero;
    });

    player.bufferedPositionStream.listen((buffered) {
      bufferedPosition.value = buffered;
    });

    // The player is the authority on whether anything is playing, not the tap
    // that asked for it. This was set to `true` optimistically before the load
    // and never corrected, so a tap whose load lost a race left the bar and the
    // player showing a pause button over silence.
    player.playingStream.listen((playing) {
      isPlaying.value = playing;
    });

    player.processingStateStream.listen((state) {
      isBuffering.value = state == ProcessingState.loading ||
          state == ProcessingState.buffering;

      // With a playlist this fires once, when the *sequence* runs out — not
      // between tracks. Everything that used to hang off it and needed to
      // happen per track now lives in the currentIndexStream listener below.
      if (state == ProcessingState.completed) {
        _history?.playbackCompleted(currentPlaying.value);
        currentPosition.value = Duration.zero;

        final settings = Get.find<SettingsController>();
        if (settings.rememberPositionEnabled.value &&
            currentPlaying.value.isBackend &&
            currentPlaying.value.songid != 0) {
          settings.clearLastPosition(currentPlaying.value.songid);
        }

        if (sleepAtTrackEnd.value) {
          cancelSleepTimer();
          _guardPlayerCall(() => player.pause(), 'Sleep timer');
        }
      }
    });

    _watchTrackChanges();
    _watchPlaybackErrors();
  }

  @visibleForTesting
  void recordPlaybackProgressForHistory(
    MySongs song,
    Duration position, {
    required bool playing,
    required bool ready,
  }) {
    if (playing && ready && position > Duration.zero) {
      _history?.playbackStarted(song);
    }
    _history?.positionChanged(song, position);
  }

  void _watchPlaybackErrors() {
    _playbackErrorSubscription = player.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        if (error is! PlayerException) return;
        final failedSong = localSongForPlaybackError(error);
        if (failedSong == null) return;
        unawaited(_removeUnavailableQueuedLocal(failedSong, error.index!));
      },
    );
  }

  @visibleForTesting
  MySongs? localSongForPlaybackError(PlayerException error) {
    final index = error.index;
    if (index == null || index < 0 || index >= currentPlayingList.length) {
      return null;
    }
    final failedSong = currentPlayingList[index];
    return failedSong.isLocal ? failedSong : null;
  }

  Future<void> _removeUnavailableQueuedLocal(
    MySongs failedSong,
    int failedIndex,
  ) async {
    await _guardPlayerCall(() => player.stop(), 'Stop unavailable local file');
    if (failedIndex >= 0 && failedIndex < player.sequence.length) {
      await _guardPlayerCall(
        () => player.removeAudioSourceAt(failedIndex),
        'Remove unavailable local file',
      );
    }
    handleUnavailableLocalSong(failedSong, queueIndex: failedIndex);
  }

  /// The centre of gravity of this controller since the queue moved into the
  /// player.
  ///
  /// Anything that used to happen inside `startPlaying` because that method was
  /// the only way a track could change now happens here instead, because the
  /// player can change track without asking: auto-advance, a notification's
  /// skip button, a bluetooth remote, a headset click.
  @visibleForTesting
  bool registerPlaybackOccurrence(Object occurrence) {
    if (identical(occurrence, _lastPlaybackOccurrence)) return false;
    _lastPlaybackOccurrence = occurrence;
    return true;
  }

  void _watchTrackChanges() {
    player.currentIndexStream.listen((index) {
      // Null between queues, and briefly out of range while a shorter queue is
      // still settling — the player's sequence and [currentPlayingList] are
      // updated a beat apart.
      if (index == null ||
          index < 0 ||
          index >= currentPlayingList.length ||
          index >= player.sequence.length) {
        return;
      }

      final song = currentPlayingList[index];
      final occurrence = player.sequence[index];

      // Kept in step even when the occurrence did not change — a queue edit
      // above the playing track shifts its index, and next/previous walk from it.
      currentIndex.value = index;

      if (!registerPlaybackOccurrence(occurrence)) return;
      final previousIdentity = _lastSongIdentity;
      final previousBackendId = _lastBackendSongId;

      final autoAdvanced = !_userSkip;
      _userSkip = false;
      _lastSongIdentity = song.identity;
      _lastBackendSongId = song.isBackend ? song.songid : null;

      final settings = Get.find<SettingsController>();

      // The track we just left finished on its own, so it has nothing left to
      // resume — leaving its saved position on disk would seek an already
      // finished song back into itself the next time it is opened. A manual
      // skip is different: that position is worth keeping.
      if (previousIdentity != null &&
          autoAdvanced &&
          settings.rememberPositionEnabled.value &&
          previousBackendId != null) {
        settings.clearLastPosition(previousBackendId);
      }

      currentPlaying.value = song;
      currentPlaying.refresh();

      final recents = _history;
      recents?.trackChanged(
        song,
        previousCompleted: autoAdvanced,
        previousEarlySkip: !autoAdvanced,
      );

      unawaited(refreshFavouriteStatusForSong(song));
      Get.find<BackgroundController>().updatePaletteGenerator();

      // History is staged here, but persisted only after playingStream confirms
      // audio actually started. This catches taps, auto-advance, notification
      // skips and bluetooth controls without counting failed loads.

      // Both of these stop playback *at the head of the next track* rather
      // than at the foot of the one that just ended — the player has already
      // moved on by the time it tells us it has. A fraction of a second of the
      // next track will be audible. Accepted rather than worked around: the
      // alternative is polling position against duration to predict the end of
      // every track, which is a lot of machinery to save 200ms.
      if (autoAdvanced && sleepAtTrackEnd.value) {
        cancelSleepTimer();
        _guardPlayerCall(() => player.pause(), 'Sleep timer');
        return;
      }

      final radio = _radioSession;
      if (radio != null &&
          !radio.isStopped &&
          index == currentPlayingList.length - 1) {
        unawaited(_appendNextRadio(radio, _radioSeedGeneration));
      }
      // Explicit queue entries continue regardless of recommendation autoplay.
      // The preference gates generation in _appendNextRadio, not native advance.
    });
  }

  // ---------------------------------------------------------------------
  // Loading a queue
  // ---------------------------------------------------------------------

  /// Replaces the queue with a *copy* of [songs], starting at [index], and
  /// plays.
  ///
  /// The copy matters and predates this rewrite: `playSong()` used to hand the
  /// screen's own `RxList` straight in, which made the queue an alias of
  /// `quickpicksController.quickpicks`, the favourites list, an artist's songs
  /// or the search results. Reordering the up-next sheet then silently
  /// reordered that screen too.
  /// Resolve a searched seed before replacing the native playlist. A failed
  /// resolution leaves the outgoing playback intact.
  Future<void> playRadioSeed(TrackRef seed) async {
    final resolver = _playbackResolver;
    if (resolver == null) {
      throw const PlaybackResolutionException(
          'Playback resolver is unavailable.');
    }
    _radioSession?.stop();
    _radioSession = null;
    final generation = ++_radioSeedGeneration;
    final resolved = await resolver.resolve(seed);
    if (generation != _radioSeedGeneration || isClosed) {
      resolved.streamHandle?.close();
      return;
    }
    await playQueue([resolved], 0);
    final fetch = _radioFetch;
    if (fetch != null && !isClosed && generation == _radioSeedGeneration) {
      final session = RadioSession(fetchRelated: fetch);
      _radioSession?.stop();
      _radioSession = session;
      unawaited(_startRadio(session, seed, generation));
    }
  }

  Future<void> _startRadio(
      RadioSession session, TrackRef seed, int generation) async {
    try {
      await session.start(seed);
      await _appendNextRadio(session, generation);
    } catch (error) {
      debugPrint('Radio discovery unavailable: $error');
    }
  }

  Future<void> _appendNextRadio(RadioSession session, int generation) async {
    if (_radioAppendingGeneration == generation ||
        isClosed ||
        generation != _radioSeedGeneration ||
        !identical(session, _radioSession) ||
        session.isStopped) {
      return;
    }
    if (!Get.find<SettingsController>().recommendationAutoplayEnabled.value) {
      return;
    }
    _radioAppendingGeneration = generation;
    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        final candidate = await _nextRadioCandidate(session, generation);
        if (candidate == null) return;
        MySongs? song;
        try {
          song = await _playbackResolver!.resolve(candidate);
          if (isClosed ||
              generation != _radioSeedGeneration ||
              !identical(session, _radioSession) ||
              session.isStopped) {
            song.streamHandle?.close();
            return;
          }
          // A manifest alone does not prove its stream can deliver audio.
          // Preflight only the immediate upcoming item; do not prepare the
          // whole radio buffer or store signed URLs.
          final firstBytes = await song.streamHandle!
              .open()
              .first
              .timeout(const Duration(seconds: 12));
          if (firstBytes.isEmpty) throw StateError('Empty radio audio');
          if (isClosed ||
              generation != _radioSeedGeneration ||
              !identical(session, _radioSession) ||
              session.isStopped) {
            song.streamHandle?.close();
            return;
          }
          await appendRadioRecommendation(song);
          unawaited(session.refillIfNeeded().catchError((Object error) {
            debugPrint('Radio refill unavailable: $error');
          }));
          return;
        } catch (error) {
          song?.streamHandle?.close();
          debugPrint('Radio audio candidate unavailable: ${error.runtimeType}');
        }
      }
    } catch (error) {
      debugPrint('Radio recommendation unavailable: $error');
    } finally {
      if (_radioAppendingGeneration == generation) {
        _radioAppendingGeneration = null;
      }
    }
  }

  Future<TrackRef?> _nextRadioCandidate(
      RadioSession session, int generation) async {
    // Consume buffered music before risking a network refill. A strict
    // music/artist filter can leave some related windows empty.
    var candidate = session.takeNext();
    for (var window = 0;
        window < 4 && candidate == null && session.continuation != null;
        window++) {
      await session.refillIfNeeded();
      if (isClosed ||
          generation != _radioSeedGeneration ||
          session.isStopped ||
          !identical(session, _radioSession)) {
        return null;
      }
      candidate = session.takeNext();
    }
    return candidate;
  }

  /// Appends through just_audio, which remains the transport and notification
  /// authority. A failed append must not leave a phantom UI queue entry.
  @visibleForTesting
  Future<void> stopRadioRecommendations() async {
    _radioSeedGeneration++;
    _radioSession?.stop();
    _radioSession = null;
    // Only remove upcoming recommendations. An already playing track and
    // every explicitly queued occurrence stay in the native playlist.
    for (var i = currentPlayingList.length - 1; i > currentIndex.value; i--) {
      if (i < _queueKinds.length &&
          _queueKinds[i] == QueueEntryKind.recommended) {
        await removeFromQueue(i);
      }
    }
  }

  Future<void> appendRadioRecommendation(MySongs song) async {
    final index = currentPlayingList.length;
    currentPlayingList.add(song);
    _queueKinds.add(QueueEntryKind.recommended);
    try {
      await player.addAudioSource(buildAudioSource(song));
    } catch (_) {
      if (index < currentPlayingList.length &&
          identical(currentPlayingList[index], song)) {
        currentPlayingList.removeAt(index);
        _queueKinds.removeAt(index);
      }
      song.streamHandle?.close();
      rethrow;
    }
  }

  Future<void> playQueue(List<MySongs> songs, int index) async {
    if (songs.isEmpty) return;
    if (_radioSession != null) {
      _radioSession!.stop();
      _radioSession = null;
      _radioSeedGeneration++;
    }
    final start = index < 0 || index >= songs.length ? 0 : index;

    final settings = Get.find<SettingsController>();

    // Checkpoint the outgoing track before [currentPlaying] is replaced below.
    // The periodic save in the positionStream listener is throttled, so it may
    // not have run recently — this is the last moment [currentPosition] still
    // describes the song that was playing rather than the one about to start.
    if (settings.rememberPositionEnabled.value &&
        currentPlaying.value.isBackend &&
        currentPlaying.value.songid != 0) {
      await settings.saveLastPosition(
          currentPlaying.value.songid, currentPosition.value);
    }

    final song = songs[start];
    final outgoingHandles = <SongStreamHandle>{
      for (final queued in currentPlayingList)
        if (queued.streamHandle != null) queued.streamHandle!,
      if (currentPlaying.value.streamHandle != null)
        currentPlaying.value.streamHandle!,
    };
    final incomingHandles = <SongStreamHandle>{
      for (final queued in songs)
        if (queued.streamHandle != null) queued.streamHandle!,
    };

    // Set synchronously as well as in the stream listener. The listener is the
    // authority, but `setAudioSources` has to load before it fires, and the
    // now-playing bar showing the *previous* track for that beat reads as a tap
    // that did not register.
    currentPlayingList.value = List<MySongs>.from(songs);
    _queueKinds.value = List<QueueEntryKind>.filled(
      songs.length,
      QueueEntryKind.explicit,
      growable: true,
    );
    currentIndex.value = start;
    currentPlaying.value = song;
    currentPlaying.refresh();

    // Before the player is asked for audio, not after. This ran below the load,
    // so a track the host would not serve threw straight past it — and since
    // this call is the only thing that ever lowers the veil, the scrim stayed
    // at full opacity: a black screen that no later song change could clear.
    Get.find<BackgroundController>().updatePaletteGenerator();

    final resume = settings.rememberPositionEnabled.value && song.isBackend
        ? settings.getLastPosition(song.songid)
        : null;

    _userSkip = true;

    try {
      await player.setAudioSources(
        [for (final s in songs) buildAudioSource(s)],
        initialIndex: start,
        initialPosition: resume ?? Duration.zero,
      );

      // Android's player may recover from an unreadable content URI by silently
      // advancing to the next source while the queue is loading. That is useful
      // for radio, but wrong for a direct tap: a deleted local file must not
      // unexpectedly start a different song.
      final loadedIndex = player.currentIndex;
      if (song.isLocal && loadedIndex != null && loadedIndex != start) {
        await _removeUnavailableQueuedLocal(song, start);
        return;
      }

      for (final handle in outgoingHandles.difference(incomingHandles)) {
        handle.close();
      }

      // Applied once per queue rather than once per track. With a playlist the
      // speed survives a track change by itself, so the old per-track reapply
      // in `startPlaying` has nothing left to correct.
      final defaultSpeed = settings.defaultPlaybackSpeed.value;
      final speedApplied = await _guardPlayerCall(
        () => player.setSpeed(defaultSpeed),
        'Set speed',
      );
      if (speedApplied) playbackSpeed.value = defaultSpeed;

      // Not awaited: `play()`'s future completes when the *queue* does.
      player.play();
    } on PlayerInterruptedException {
      // A newer queue took the player mid-load. That is this method working as
      // intended, not a failure.
    } catch (e) {
      debugPrint('Error playing song: $e');
      if (song.isLocal) {
        await _removeUnavailableQueuedLocal(song, start);
      }
    }
  }

  @visibleForTesting
  void handleUnavailableLocalSong(
    MySongs song, {
    int? queueIndex,
    bool notify = true,
  }) {
    if (queueIndex != null &&
        queueIndex >= 0 &&
        queueIndex < currentPlayingList.length &&
        currentPlayingList[queueIndex].identity == song.identity) {
      currentPlayingList.removeAt(queueIndex);
      if (queueIndex < _queueKinds.length) _queueKinds.removeAt(queueIndex);
    } else {
      final matchingIndex = currentPlayingList.indexWhere(
        (queued) => queued.identity == song.identity,
      );
      if (matchingIndex >= 0) {
        currentPlayingList.removeAt(matchingIndex);
        if (matchingIndex < _queueKinds.length) {
          _queueKinds.removeAt(matchingIndex);
        }
      }
    }
    currentIndex.value = -1;
    currentPlaying.value = _placeholderSong();
    currentPlaying.refresh();
    _lastSongIdentity = null;
    _lastPlaybackOccurrence = null;
    if (notify && Get.context != null) {
      Get.snackbar(
        'Local file unavailable',
        'This song may have been moved or deleted. Scan your library again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ---------------------------------------------------------------------
  // Transport
  // ---------------------------------------------------------------------

  /// The queue index a *tap* on next or previous should move to, or null when
  /// the tap should do nothing.
  ///
  /// Deliberately not `player.seekToNext()` / `seekToPrevious()`. Those obey
  /// `loopMode`, and under `LoopMode.one` the player's own `nextIndex` is the
  /// *current* index — so Next would replay the track instead of moving on, and
  /// Previous at the head of a queue with repeat off would do nothing at all.
  /// Repeat governs what happens when a track ends on its own; it was never
  /// meant to govern what a button means, and the hand-rolled index maths this
  /// replaced was careful about exactly that.
  ///
  /// Walks `player.effectiveIndices` — the shuffled play order when shuffle is
  /// on, the plain order when it is not — so this stays shuffle-aware without
  /// the controller keeping a permutation of its own.
  int? _manualIndex(int offset, {required bool wrap}) {
    final order = player.effectiveIndices;
    if (order.isEmpty) return null;

    final current = player.currentIndex ?? currentIndex.value;
    final position = order.indexOf(current);
    if (position < 0) return null;

    final target = position + offset;
    if (target < 0 || target >= order.length) {
      // Dart's % is never negative for a positive divisor, so this wraps in
      // both directions.
      return wrap ? order[target % order.length] : null;
    }
    return order[target];
  }

  /// Advances to the next track. Stops at the end of the queue unless repeat
  /// is `all` — which is what repeat off has meant here since the wrap-around
  /// stopped being unconditional.
  void playNextSong() {
    if (currentPlayingList.isEmpty) return;
    final target = _manualIndex(1, wrap: repeatMode.value == RepeatMode.all);
    if (target == null) return;

    _userSkip = true;
    _guardPlayerCall(
      () => player.seek(Duration.zero, index: target),
      'Next',
    );
  }

  /// Steps back a track. Always wraps to the end of the queue regardless of
  /// [repeatMode], which is the behaviour this had before the rewrite.
  void playPreviousSong() {
    if (currentPlayingList.isEmpty) return;
    final target = _manualIndex(-1, wrap: true);
    if (target == null) return;

    _userSkip = true;
    _guardPlayerCall(
      () => player.seek(Duration.zero, index: target),
      'Previous',
    );
  }

  // Resume playing the current song. [isPlaying] follows from playingStream.
  void resumePlaying() {
    player.play();
  }

  // Pause the current song
  Future<void> pausePlaying() async {
    await _guardPlayerCall(() => player.pause(), 'Pause');
    // A deliberate pause is as good a checkpoint as any for remember-position
    // — don't wait for the next throttled tick in positionStream below.
    final settings = Get.find<SettingsController>();
    if (settings.rememberPositionEnabled.value &&
        currentPlaying.value.isBackend &&
        currentPlaying.value.songid != 0) {
      await settings.saveLastPosition(
          currentPlaying.value.songid, currentPosition.value);
    }
  }

  // ---------------------------------------------------------------------
  // Remember position — the periodic half of it. `playQueue` checkpoints the
  // outgoing track and `pausePlaying` checkpoints on pause; this covers
  // everything in between, in case neither of those fires for a while (a long
  // track played straight through with the app never paused).
  // ---------------------------------------------------------------------

  DateTime? _lastPositionSaveAt;

  /// Throttled write-behind: `positionStream` fires many times a second, and
  /// without a floor on how often this writes, remember-position would mean
  /// a `shared_preferences` write on every tick.
  void _maybeSaveLastPosition(Duration position) {
    final settings = Get.find<SettingsController>();
    if (!settings.rememberPositionEnabled.value) return;

    final songId = currentPlaying.value.songid;
    if (songId == 0) return;

    final now = DateTime.now();
    if (_lastPositionSaveAt != null &&
        now.difference(_lastPositionSaveAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastPositionSaveAt = now;
    settings.saveLastPosition(songId, position);
  }

  // Seek to a specific position in the song
  Future<void> seekTo(Duration position) async {
    await _guardPlayerCall(() => player.seek(position), 'Seek');
  }

  double getProgress() {
    if (totalDuration.value.inMilliseconds == 0) return 0.0;
    return currentPosition.value.inMilliseconds /
        totalDuration.value.inMilliseconds;
  }

  // ---------------------------------------------------------------------
  // Skip interval
  // ---------------------------------------------------------------------

  /// Settings-driven — was a fixed `Duration(seconds: 10)`.
  Duration get skipInterval => Duration(
      seconds: Get.find<SettingsController>().skipIntervalSeconds.value);

  /// Skips ahead, clamped to the track's end so this can't seek past a duration
  /// `just_audio` hasn't even reported yet (see [totalDuration]'s doc for when
  /// that's null-turned-zero).
  Future<void> skipForward() async {
    final target = currentPosition.value + skipInterval;
    final total = totalDuration.value;
    await seekTo(
      total > Duration.zero && target > total ? total : target,
    );
  }

  /// Skips back, clamped to zero.
  Future<void> skipBackward() async {
    final target = currentPosition.value - skipInterval;
    await seekTo(target < Duration.zero ? Duration.zero : target);
  }

  // ---------------------------------------------------------------------
  // Playback speed
  // ---------------------------------------------------------------------

  /// The speeds `just_audio`'s `setSpeed` is offered at. A fixed set, not a
  /// slider — every other transport control in the app is a tap, not a drag.
  static const List<double> availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  RxDouble playbackSpeed = 1.0.obs;

  /// Sets playback speed. Silently ignores anything outside [availableSpeeds]
  /// rather than passing an arbitrary value on to `just_audio` — the UI is
  /// expected to only ever offer these six.
  Future<void> setPlaybackSpeed(double speed) async {
    if (!availableSpeeds.contains(speed)) return;
    final applied = await _guardPlayerCall(
      () => player.setSpeed(speed),
      'Set speed',
    );
    if (applied) playbackSpeed.value = speed;
  }

  // ---------------------------------------------------------------------
  // Volume
  // ---------------------------------------------------------------------

  RxDouble volume = 1.0.obs;

  /// Sets playback volume, clamped to `just_audio`'s own 0.0–1.0 range.
  Future<void> setVolume(double value) async {
    final clamped = value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value);
    final applied = await _guardPlayerCall(
      () => player.setVolume(clamped),
      'Set volume',
    );
    if (applied) volume.value = clamped;
  }

  // ---------------------------------------------------------------------
  // Sleep timer
  // ---------------------------------------------------------------------

  Timer? _sleepTicker;

  /// Counts down while a fixed-duration sleep timer is armed; null when no
  /// timer is running. Deliberately stays null for [sleepAtTrackEnd] too —
  /// there's no clock to show for "whenever this track ends."
  Rx<Duration?> sleepTimeRemaining = Rx<Duration?>(null);

  /// True while "end of current track" is armed. Consumed by the track-change
  /// listener in [_watchTrackChanges], since this has no fixed duration to
  /// count down.
  ///
  /// Note that this cannot fire while repeat-one is armed: the player loops the
  /// same track without ever changing index, so there is no track boundary to
  /// catch. The two settings contradict each other — "play this forever" and
  /// "stop when this ends" — and building machinery to reconcile them would be
  /// building it for a combination nobody means to set.
  RxBool sleepAtTrackEnd = false.obs;

  /// Arms a sleep timer for [duration] from now. Ticks [sleepTimeRemaining]
  /// once a second so the UI can show a countdown without polling.
  void startSleepTimer(Duration duration) {
    cancelSleepTimer();
    final endAt = DateTime.now().add(duration);
    sleepTimeRemaining.value = duration;

    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = endAt.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        sleepTimeRemaining.value = Duration.zero;
        cancelSleepTimer();
        _guardPlayerCall(() => player.pause(), 'Sleep timer');
        return;
      }
      sleepTimeRemaining.value = remaining;
    });
  }

  /// Arms "pause when the current track ends" instead of a fixed duration.
  void armSleepAtTrackEnd() {
    cancelSleepTimer();
    sleepAtTrackEnd.value = true;
  }

  /// Disarms whichever sleep timer is active, if any. Safe to call when
  /// nothing is armed.
  void cancelSleepTimer() {
    _sleepTicker?.cancel();
    _sleepTicker = null;
    sleepTimeRemaining.value = null;
    sleepAtTrackEnd.value = false;
  }

  // ---------------------------------------------------------------------
  // Queue mutation (up-next sheet)
  // ---------------------------------------------------------------------

  /// Jumps to the queue entry at [index] — the up-next sheet's tap-to-play.
  ///
  /// Restores that song's remembered position if there is one, which is the
  /// half of remember-position that `playQueue`'s `initialPosition` cannot
  /// reach once a queue is already loaded.
  void jumpToQueueIndex(int index) {
    if (index < 0 || index >= currentPlayingList.length) return;

    final settings = Get.find<SettingsController>();
    final resume = settings.rememberPositionEnabled.value
        ? settings.getLastPosition(currentPlayingList[index].songid)
        : null;

    _userSkip = true;
    _guardPlayerCall(
      () => player.seek(resume ?? Duration.zero, index: index),
      'Jump to queue entry',
    );
  }

  // ---------------------------------------------------------------------
  // Adding to the queue
  //
  // Until these existed there was exactly one way into the queue — replace it
  // wholesale — so the only way to hear a song was to abandon whatever was
  // already lined up.
  // ---------------------------------------------------------------------

  /// Queues [song] to play directly after whatever is playing now.
  ///
  /// With nothing playing there is no "after", so this starts a queue of one
  /// instead. Both entry points below do; a control that silently does nothing
  /// on an empty queue is worse than one that does the obvious thing.
  Future<void> playNext(MySongs song) async {
    if (!song.isBackend) {
      throw UnsupportedError(
          'YouTube queueing is not available in this preview.');
    }
    if (currentPlayingList.isEmpty) return playQueue([song], 0);

    final at = (currentIndex.value + 1).clamp(0, currentPlayingList.length);
    currentPlayingList.insert(at, song);
    _queueKinds.insert(at, QueueEntryKind.explicit);
    await _guardPlayerCall(
      () => player.insertAudioSource(at, buildAudioSource(song)),
      'Play next',
    );
  }

  /// Adds behind explicit upcoming entries and before radio recommendations.
  Future<void> addToQueue(MySongs song) async {
    if (!song.isBackend) {
      throw UnsupportedError(
          'YouTube queueing is not available in this preview.');
    }
    if (currentPlayingList.isEmpty) return playQueue([song], 0);

    final at = recommendedStartIndex;
    currentPlayingList.insert(at, song);
    _queueKinds.insert(at, QueueEntryKind.explicit);
    await _guardPlayerCall(
      () => player.insertAudioSource(at, buildAudioSource(song)),
      'Add to queue',
    );
  }

  /// Reorders the queue for the up-next sheet's drag-to-reorder.
  ///
  /// Takes [oldIndex]/[newIndex] exactly as Flutter's
  /// `ReorderableListView.onReorder` supplies them — `newIndex` is the target
  /// position *before* `oldIndex` is removed, one higher than where the item
  /// actually lands when dragged downward.
  ///
  /// The mirror list is moved first and the player second, so that when the
  /// player's index event arrives [currentPlayingList] already agrees with it.
  /// The playing track keeps playing: `moveAudioSource` moves entries around
  /// it, it does not reload anything.
  void reorderQueue(int oldIndex, int newIndex) {
    final length = currentPlayingList.length;
    if (oldIndex < 0 ||
        oldIndex >= length ||
        newIndex < 0 ||
        newIndex > length) {
      return;
    }
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex == oldIndex) return;

    final item = currentPlayingList.removeAt(oldIndex);
    final kind = _queueKinds.removeAt(oldIndex);
    currentPlayingList.insert(newIndex, item);
    _queueKinds.insert(newIndex, kind);

    _guardPlayerCall(
      () => player.moveAudioSource(oldIndex, newIndex),
      'Reorder queue',
    );
  }

  /// Removes the queue entry at [index] for the up-next sheet's
  /// swipe-to-remove.
  ///
  /// Removing any *other* entry leaves playback completely alone: the track
  /// change listener keys on the song, so an index that merely shifted is not
  /// mistaken for a new track.
  ///
  /// Removing the track that *is* playing hands the player on to whatever now
  /// sits at that position — `just_audio`'s own behaviour rather than something
  /// arranged here. That reads to the listener as an advance the user did not
  /// ask for, so with autoplay off it lands paused on the next track. Left as
  /// it is: swiping away what you are listening to is not obviously a request
  /// to keep listening.
  Future<void> removeFromQueue(int index) async {
    final length = currentPlayingList.length;
    if (index < 0 || index >= length) return;

    final removed = currentPlayingList.removeAt(index);
    _queueKinds.removeAt(index);

    if (currentPlayingList.isEmpty) {
      currentIndex.value = -1;
      _lastSongIdentity = null;
      _lastPlaybackOccurrence = null;
      _lastBackendSongId = null;
    }

    await _guardPlayerCall(
      () => player.removeAudioSourceAt(index),
      'Remove from queue',
    );
    if (index > currentIndex.value) removed.streamHandle?.close();
  }

  // The favourite endpoints only accept POST with a JSON body:
  // GET (even with a body) is rejected by the host with a 403.
  //
  // Returns the decoded body, or null if the request never got an answer.
  Future<Map<String, dynamic>?> _postFavourite(
      String url, String songId) async {
    try {
      final res = await api.post(url, data: {
        // Awaited, not read straight off the observable. The id is loaded from
        // disk, so a tap early in a session used to send an empty one.
        "userid": await Get.find<UseridController>().id,
        "songid": songId,
      });
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      debugPrint('Favourite request failed ($url): HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('Favourite request failed ($url): $e');
    }
    return null;
  }

  Future<bool> isFavouriteSong(String songId) async {
    final data = await _postFavourite(checkIfFavouriteUrl, songId);
    return data?['is_favorite'] == true;
  }

  Future<void> refreshFavouriteStatusForSong(MySongs song) async {
    final generation = ++_favouriteStateGeneration;
    final result = song.isBackend
        ? await isFavouriteSong(song.songid.toString())
        : await _library?.isFavourite(TrackRef.fromSong(song)) ?? false;
    if (generation != _favouriteStateGeneration ||
        song.identity != currentPlaying.value.identity) {
      return;
    }
    isFavourite.value = result;
  }

  // Re-check the favourite state of whatever is playing now. Called on every
  // song change, so next/previous/auto-advance all keep the heart in sync.
  Future<void> refreshFavouriteStatus(String songId) async {
    final generation = ++_favouriteStateGeneration;
    final result = await isFavouriteSong(songId);
    // The song moved on while this was in flight. This answer describes the
    // previous track, and applying it would put the wrong heart on screen.
    if (generation != _favouriteStateGeneration ||
        songId != currentPlaying.value.songid.toString()) {
      return;
    }
    isFavourite.value = result;
  }

  /// Guards against re-entry. The heart is one control: firing an add and a
  /// remove for the same song at once leaves the two disagreeing about which
  /// end state won.
  int _favouriteStateGeneration = 0;
  final Set<String> _favouriteTogglesInFlight = <String>{};

  /// Add or remove the current song, keeping [isFavourite] and the favourites
  /// list in step with what the server actually did.
  ///
  /// Returns null on success, or a message describing what went wrong — this
  /// used to return void and swallow every failure, so a rejected write looked
  /// exactly like a tap that had not registered.
  Future<String?> toggleFavourite() async {
    final song = currentPlaying.value;
    if (song.isLocal) return 'Local favourites are not available yet.';
    if (!_favouriteTogglesInFlight.add(song.identity)) return null;
    try {
      final adding = !isFavourite.value;
      _favouriteStateGeneration++;
      if (!song.isBackend) {
        try {
          await (_library ?? Get.find<LibraryRepository>()).setFavourite(
            TrackRef.fromSong(song),
            adding,
          );
        } catch (error) {
          debugPrint('YouTube favourite write failed: $error');
          return 'That could not be saved on this device.';
        }
        _favouriteStateGeneration++;
        if (currentPlaying.value.identity == song.identity) {
          isFavourite.value = adding;
        }
        return null;
      }

      final data = await _postFavourite(
        adding ? addToFavouriteUrl : removeFromFavouriteUrl,
        song.songid.toString(),
      );

      if (data == null) return 'Could not reach the server.';
      if (data['success'] != true) {
        return data['message'] as String? ?? 'That could not be saved.';
      }

      _favouriteStateGeneration++;
      if (currentPlaying.value.identity == song.identity) {
        isFavourite.value = adding;
      }

      // Refresh the server list only when that source is the visible favourites
      // page. Local and YouTube lists must not be replaced by a server response.
      unawaited(
        Get.find<UserFavouriteController>().refreshServerFavouritesIfVisible(),
      );
      return null;
    } finally {
      _favouriteTogglesInFlight.remove(song.identity);
    }
  }

  /// Runs a call against [player], reporting whether it actually completed.
  ///
  /// Player calls can legitimately fail — a seek against a source that has not
  /// finished loading, a queue mutation racing a queue replacement — and none
  /// of the transport controls has anything useful to say to the user when one
  /// does. They fail silently, the same way a favourite POST that never got an
  /// answer does.
  ///
  /// This used to be load-bearing for a much worse reason: `InternetController`
  /// called `disposePlayer()` on every disconnect *and* on a merely slow
  /// connection, and `player.dispose()` is permanent, so after the first blip
  /// every call into the player threw for the rest of the session. That bug is
  /// fixed — the player is disposed in [onClose] and nowhere else.
  Future<bool> _guardPlayerCall(
    Future<void> Function() action,
    String label,
  ) async {
    try {
      await action();
      return true;
    } catch (e) {
      debugPrint('$label failed: $e');
      return false;
    }
  }

  @override
  void onClose() {
    // Otherwise a timer armed on this page outlives the controller and fires
    // into a disposed player once GetX tears this down.
    _sleepTicker?.cancel();
    _radioSeedGeneration++;
    _radioSession?.stop();
    _recommendationToggleWorker?.dispose();
    _closeRadioDiscovery?.call();
    _playbackErrorSubscription?.cancel();
    for (final handle in <SongStreamHandle>{
      for (final song in currentPlayingList)
        if (song.streamHandle != null) song.streamHandle!,
      if (currentPlaying.value.streamHandle != null)
        currentPlaying.value.streamHandle!,
    }) {
      handle.close();
    }
    // The only place the player is ever disposed. See _guardPlayerCall.
    player.dispose();
    super.onClose();
  }
}
