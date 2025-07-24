import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/all_urls.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/services/services.dart';

class SongController extends GetxController {
  late AudioPlayer player = AudioPlayer();
  Dio dio = Dio();

  RxBool isPlaying = false.obs;

  MySongs currentPlaying = MySongs(
      songid: 0,
      artist: 'artist',
      coverurl: 'coverurl',
      songurl: 'songurl',
      title: 'title',
      isquickpick: 0);
  RxInt currentIndex = (-1).obs;
  RxList<MySongs> currentPlayingList = <MySongs>[].obs;

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
    // player.playbackStateStream.listen((event) {
    //   if (event.processingState == ProcessingState.completed) {
    //     isPlaying.value = false;
    //     currentPosition.value = Duration.zero;
    //     playNextSong();
    //   }
    // }
    // );
  }

  final FireStoreServices services = Get.find<FireStoreServices>();

  // Start playing a song
  startPlaying(MySongs song) async {
    BackgroundController backgroundController =
        Get.find<BackgroundController>();

    if (song == currentPlaying) {
      // If the song is already playing, just return
      return;
    }
    backgroundController.showVisibility();
    // Check if the player is currently playing
    if (player.playing) {
      await player.stop(); // Stop the current playback
    }

    currentPlaying = song;
    isPlaying.value = true;

    // Play the new song
    await player.setUrl(baseUrl + song.songurl);
    await player.play();
    backgroundController.updatePaletteGenerator();
  }

  void playNextSong() {
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
  resumePlaying() {
    player.play();
    isPlaying.value = true;
  }

  // Pause the current song
  pausePlaying() async {
    await player.pause();
    isPlaying.value = false;
  }

  // Stop and dispose the player
  disposePlayer() async {
    await player.stop();
    await player.dispose();
  }

  // Seek to a specific position in the song
  seekTo(Duration position) async {
    await player.seek(position);
  }

  double getProgress() {
    if (totalDuration.value.inMilliseconds == 0) return 0.0;
    return currentPosition.value.inMilliseconds /
        totalDuration.value.inMilliseconds;
  }

  Future<bool> addFavourite(String userid, String songId) async {
    String url = addToFavouriteUrl;

    Map<String, dynamic> payLoad = {"userid": userid, "songid": songId};
    Response res = await dio.post(url, data: payLoad);

    if (res.statusCode == 200) {
      if (res.data['success'] == true) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  Future<bool> removeFromFavourite(String userid, String songId) async {
    String url = removeFromFavouriteUrl;

    Map<String, dynamic> payLoad = {"userid": userid, "songid": songId};
    Response res = await dio.delete(url, data: payLoad);

    if (res.statusCode == 200) {
      if (res.data['success'] == true) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  Future<bool> isFavouriteSong(String userid, String songId) async {
    String url = checkIfFavouriteUrl;

    Map<String, dynamic> payLoad = {"userid": userid, "songid": songId};
    Response res = await dio.delete(url, data: payLoad);

    if (res.statusCode == 200 && res.data['success'] == true) {
      if (res.data['is_favorite'] == true) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
}
