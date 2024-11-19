import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:music_app/model/song_model.dart';

class SongController extends GetxController {
  late AudioPlayer player = AudioPlayer();
  RxBool isPlaying = false.obs;

  MySongs currentPlaying = MySongs(artist: 'artist', cover: 'cover', song: 'song', title: 'title');
  RxInt currentIndex = 0.obs;

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
    });
  }

  // Start playing a song
  startPlaying(MySongs song) async {
    currentPlaying = song;
    isPlaying.value = true;

    await player.play(UrlSource(song.song));
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
}
