import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:music_app/component/animated_background.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/services/services.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late SongController controller;
  late FireStoreServices services;

  final BackgroundController _backgroundController =
      Get.put(BackgroundController());

  @override
  void initState() {
    controller = Get.put(SongController());
    services = Get.put(FireStoreServices());
    _backgroundController.updatePaletteGenerator();
    super.initState();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // Method to play the next song
void playNextSong() {
  if (services.quickpicks.length > controller.currentIndex.value + 1) {
    // Play the next song
    controller.currentIndex.value = controller.currentIndex.value + 1;
    controller.startPlaying(services.quickpicks[controller.currentIndex.value]);
  } else {
    // If it's the last song, go back to the first song
    controller.currentIndex.value = 0;
    controller.startPlaying(services.quickpicks[0]);
  }
}

// Method to play the previous song
void playPreviousSong() {
  if (controller.currentIndex.value > 0) {
    // Play the previous song
    controller.currentIndex.value = controller.currentIndex.value - 1;
    controller.startPlaying(services.quickpicks[controller.currentIndex.value]);
  } else {
    // If it's the first song, go to the last song
    controller.currentIndex.value = services.quickpicks.length - 1;
    controller.startPlaying(services.quickpicks[controller.currentIndex.value]);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(alignment: Alignment.center, children: <Widget>[
        const AnimatedBackground(),
        Obx(
          () {
      final currentPositionText = formatDuration(controller.currentPosition.value);
    final totalDurationText = formatDuration(controller.totalDuration.value);
         return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    height: 450,
                    width: MediaQuery.of(context).size.width - 50,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100.withOpacity(0.2)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image(
                              height: 300,
                              fit: BoxFit.cover,
                              image:
                                  NetworkImage(controller.currentPlaying.cover),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            children: [
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                '$currentPositionText / $totalDurationText',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                          Slider(
                            min: 0.0,
                            max: controller.totalDuration.value.inSeconds.toDouble(),
                            value: controller.currentPosition.value.inSeconds
                                .toDouble()
                                .clamp(0.0, controller.totalDuration.value.inSeconds.toDouble()),
                            activeColor: Colors.white,
                            allowedInteraction: SliderInteraction.slideOnly,
                            onChanged: (value) {
                              controller
                                  .seekTo(Duration(seconds: value.toInt()));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton.large(
                      heroTag: 'btn-previous',
                      shape: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                              color: Colors.grey.shade100.withOpacity(0.15))),
                      backgroundColor: Colors.grey.shade100.withOpacity(0.1),
                      elevation: 0,
                      disabledElevation: 0,
                      hoverElevation: 0,
                      focusElevation: 0,
                      highlightElevation: 0,
                      child: const Icon(
                        shadows: [
                          Shadow(
                            blurRadius: 9.0,
                            color: Colors.white,
                            offset: Offset(0, 0),
                          ),
                        ],
                        Ionicons.md_play_skip_back_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: playPreviousSong,
                      ),
                  FloatingActionButton.large(
                    heroTag: 'btn-play',
                    shape: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                            color: Colors.grey.shade100.withOpacity(0.15))),
                    backgroundColor: Colors.grey.shade100.withOpacity(0.1),
                    elevation: 0,
                    disabledElevation: 0,
                    hoverElevation: 0,
                    focusElevation: 0,
                    highlightElevation: 0,
                    child: Icon(
                      shadows: const [
                        Shadow(
                          blurRadius: 9.0,
                          color: Colors.white,
                          offset: Offset(0, 0),
                        ),
                      ],
                      controller.isPlaying.value ? Feather.pause : Feather.play,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () async {
                      controller.isPlaying.value
                          ? controller.pausePlaying()
                          : controller.resumePlaying();
                    },
                  ),
                  FloatingActionButton.large(
                    heroTag: 'btn-next',
                    shape: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                            color: Colors.grey.shade100.withOpacity(0.15))),
                    backgroundColor: Colors.grey.shade100.withOpacity(0.1),
                    elevation: 0,
                    disabledElevation: 0,
                    hoverElevation: 0,
                    focusElevation: 0,
                    highlightElevation: 0,
                    child: const Icon(
                      shadows: [
                        Shadow(
                          blurRadius: 9.0,
                          color: Colors.white,
                          offset: Offset(0, 0),
                        ),
                      ],
                      Ionicons.md_play_skip_forward_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: playNextSong
                  ),
                ],
              )
            ],
          );}
        ),
      ]),
    );
  }
}
