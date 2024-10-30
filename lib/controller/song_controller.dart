import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/model/song_model.dart';

class SongController extends GetxController {

   late AudioPlayer player = AudioPlayer();
   RxBool isPlaying = false.obs;

  MySongs currentPlaying = MySongs(artist: 'artist', cover: 'cover', song: 'song', title: 'title');
  RxInt currentIndex = 0.obs;

 @override
  void onInit() {
    super.onInit();
     player = AudioPlayer();

    // Set the release mode to keep the source after playback has completed.
    player.setReleaseMode(ReleaseMode.stop);

    // Start the player as soon as the app is displayed.
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   await player.setSource(UrlSource('https://www2.cs.uic.edu/~i101/SoundFiles/BabyElephantWalk60.wav'));
    //   // await player.resume();
    // });
  }

    // Create the audio player.
  
  startPlaying(MySongs song)async{
    currentPlaying = song;

    isPlaying.value = true;

    await player.play(UrlSource(song.song));

  }
  resumePlaying(){
    player.resume();
    isPlaying.value = true;
  }
  pausePlaying()async{
    await player.pause();
    isPlaying.value = false;

  }
  disposePlayer  () async {
    await player.stop();

//  await player.dispose();

  }

}