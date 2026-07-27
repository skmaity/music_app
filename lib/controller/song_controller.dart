import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:just_audio/just_audio.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/userid_controller.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/controller/user_favourite_controller.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/services/services.dart';

class SongController extends GetxController {
  late AudioPlayer player = AudioPlayer();
  Dio dio = Dio();

  RxBool isPlaying = false.obs;

  Rx<MySongs> currentPlaying = MySongs(
          songid: 0,
          artist: 'artist',
          coverurl: 'coverurl',
          songurl: 'songurl',
          title: 'title',
          isquickpick: 0)
      .obs;
  RxInt currentIndex = (-1).obs;
  RxList<MySongs> currentPlayingList = <MySongs>[].obs;

  // Whether [currentPlaying] is in the user's favourites
  RxBool isFavourite = false.obs;

  // New variables for tracking song position and duration
  Rx<Duration> currentPosition = Duration.zero.obs;
  Rx<Duration> totalDuration = Duration.zero.obs;

  // Initialize the audio player
  @override
  void onInit() {
    super.onInit();

    // Listen to position changes
    player.positionStream.listen((position) {
      currentPosition.value = position;
    });

    // Listen to duration changes
    player.durationStream.listen((duration) {
      totalDuration.value = duration!;
    });

    // Listen to when the player finishes playing
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        currentPosition.value = Duration.zero;
        playNextSong();
      }
    });
  }

  final FireStoreServices services = Get.find<FireStoreServices>();

  // Start playing a song
  Future<void> startPlaying(MySongs song) async {
    try {
      BackgroundController backgroundController =
          Get.find<BackgroundController>();

      // Allow replaying the same song once it has finished
      if (song == currentPlaying.value &&
          player.processingState != ProcessingState.completed) {
        return;
      }

      backgroundController.showVisibility();

      if (player.playing) {
        await player.stop();
      }
      currentPlaying.value = song;
      currentPlaying.refresh();
      isPlaying.value = true;
      refreshFavouriteStatus(song.songid.toString());

      final url = baseUrl + song.songurl;

      await player.setUrl(url);
      await player.play();

      backgroundController.updatePaletteGenerator();
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  void playNextSong() {
    if (currentPlayingList.isEmpty) return;

    if (currentPlayingList.length > currentIndex.value + 1) {
      // Play the next song
      currentIndex.value = currentIndex.value + 1;
      startPlaying(currentPlayingList[currentIndex.value]);
    } else {
      // If it's the last song, go back to the first song
      currentIndex.value = 0;
      startPlaying(currentPlayingList[0]);
    }
  }

  void playPreviousSong() {
    // Check if there are any songs in the playlist
    if (currentPlayingList.isEmpty) return;

    // Move to previous song if not the first one, otherwise go to the last song
    if (currentIndex.value > 0) {
      currentIndex.value -= 1;
    } else {
      currentIndex.value = currentPlayingList.length - 1;
    }

    // Play the selected song
    startPlaying(currentPlayingList[currentIndex.value]);
  }

  // Resume playing the current song
  void resumePlaying() {
    player.play();
    isPlaying.value = true;
  }

  // Pause the current song
  Future<void> pausePlaying() async {
    await player.pause();
    isPlaying.value = false;
  }

  // Stop and dispose the player
  Future<void> disposePlayer() async {
    await player.stop();
    await player.dispose();
  }

  // Seek to a specific position in the song
  Future<void> seekTo(Duration position) async {
    await player.seek(position);
  }

  double getProgress() {
    if (totalDuration.value.inMilliseconds == 0) return 0.0;
    return currentPosition.value.inMilliseconds /
        totalDuration.value.inMilliseconds;
  }

  // The favourite endpoints only accept POST with a JSON body:
  // GET (even with a body) is rejected by the host with a 403.
  Future<Map<String, dynamic>?> _postFavourite(
      String url, String userid, String songId) async {
    try {
      final res =
          await dio.post(url, data: {"userid": userid, "songid": songId});
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
    } catch (e) {
      debugPrint('Favourite request failed ($url): $e');
    }
    return null;
  }

  Future<bool> addFavourite(String userid, String songId) async {
    final data = await _postFavourite(addToFavouriteUrl, userid, songId);
    return data?['success'] == true;
  }

  Future<bool> removeFromFavourite(String userid, String songId) async {
    final data = await _postFavourite(removeFromFavouriteUrl, userid, songId);
    return data?['success'] == true;
  }

  Future<bool> isFavouriteSong(String userid, String songId) async {
    final data = await _postFavourite(checkIfFavouriteUrl, userid, songId);
    return data?['success'] == true && data?['is_favorite'] == true;
  }

  // Re-check the favourite state of whatever is playing now. Called on every
  // song change, so next/previous/auto-advance all keep the heart in sync.
  Future<void> refreshFavouriteStatus(String songId) async {
    isFavourite.value = await isFavouriteSong(
      Get.find<UseridController>().userId.value,
      songId,
    );
  }

  // Add or remove the current song, keeping [isFavourite] and the favourites
  // list in step with what the server actually did.
  Future<void> toggleFavourite() async {
    final userid = Get.find<UseridController>().userId.value;
    final songId = currentPlaying.value.songid.toString();

    final ok = isFavourite.value
        ? await removeFromFavourite(userid, songId)
        : await addFavourite(userid, songId);

    if (!ok) return;

    isFavourite.value = !isFavourite.value;

    if (Get.isRegistered<UserFavouriteController>()) {
      Get.find<UserFavouriteController>().getUserFavourites(userid);
    }
  }
}
