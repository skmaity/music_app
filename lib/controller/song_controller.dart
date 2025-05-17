import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:music_app/all_urls.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/services/services.dart';

class SongController extends GetxController {
  late AudioPlayer player = AudioPlayer();

  RxBool isPlaying = false.obs;

  MySongs currentPlaying = 
      MySongs(songid: 0, artist: 'artist', coverurl: 'coverurl', songurl: 'songurl', title: 'title', isquickpick: 0);
  RxInt currentIndex = (-1).obs;

  // New variables for tracking song position and duration
  Rx<Duration> currentPosition = Duration.zero.obs;
  Rx<Duration> totalDuration = Duration.zero.obs;

  // Initialize the audio player
  @override
  void onInit() {
    super.onInit();

    // Listen to position changes
    player.onPositionChanged.listen((position) {
      currentPosition.value = position;
    });

    // Listen to duration changes
    player.onDurationChanged.listen((duration) {
      totalDuration.value = duration;
    });

    // Listen to when the player finishes playing
    player.onPlayerComplete.listen((event) {
      isPlaying.value = false;
      currentPosition.value = Duration.zero;
      playNextSong();
    });
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
    if (player.state == PlayerState.playing) {
      await player.stop(); // Stop the current playback
    }

    currentPlaying = song;
    isPlaying.value = true;

    // Play the new song
    await player.play(UrlSource(baseUrl + song.songurl));
    backgroundController.updatePaletteGenerator();
  }

  void playNextSong() {
    if (services.currentPlayingList.length > currentIndex.value + 1) {
      // Play the next song
      currentIndex.value = currentIndex.value + 1;
      startPlaying(services.currentPlayingList[currentIndex.value]);
    } else {
      // If it's the last song, go back to the first song
      currentIndex.value = 0;
      startPlaying(services.currentPlayingList[0]);
    }
  }

  void playPreviousSong() {
    // Check if there are any songs in the playlist
    if (services.currentPlayingList.isEmpty) return;

    // Move to previous song if not the first one, otherwise go to the last song
    if (currentIndex.value > 0) {
      currentIndex.value -= 1;
    } else {
      currentIndex.value = services.currentPlayingList.length - 1;
    }

    // Play the selected song
    startPlaying(services.currentPlayingList[currentIndex.value]);
  }

  // Resume playing the current song
  resumePlaying() {
    player.resume();
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
}
