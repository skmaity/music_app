import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:music_app/all_urls.dart';
import 'package:music_app/component/animated_gradient_widget.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/player_page_function.dart';
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
      Get.find<BackgroundController>();

  @override
  void initState() {
    controller = Get.find<SongController>();
    services = Get.find<FireStoreServices>();
    _backgroundController.updatePaletteGenerator(); 
    super.initState();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // Method to play the previous song
 

  final PlayerPageFunction _playerPageFunction = Get.find<PlayerPageFunction>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              _backgroundController.isFromSongLogo.value = true;
              Navigator.pop(context);
            },
            icon: const Hero(
              tag: 'music',
              child: Icon(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        blurRadius: 9.0,
                        color: Colors.white70,
                        offset: Offset(0, 0))
                  ],
                  Icons.music_note_outlined),
            )),
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(alignment: Alignment.center, children: <Widget>[
        // const AnimatedBackground(),
        // AnimateGradient(
        //   primaryColors: _backgroundController.primaryColorsList,
        //   secondaryColors: _backgroundController.secondaryColorsList,
        // ),
        Obx(() {
          return AnimatedGradient( 
            primaryColors:
                List<Color>.from(_backgroundController.primaryColorsList),
            secondaryColors:
                List<Color>.from(_backgroundController.secondaryColorsList),
          );
        }),
        Obx(
          ()=> AnimatedContainer(  
              duration: Duration(milliseconds: _backgroundController.isVisible.value ? 600 : 5000),
              color: Colors.black.withOpacity(_backgroundController.isVisible.value ? 1 : 0.0),
              child: const SizedBox.expand(),
            ),
        ),
        Obx(() {
          final currentPositionText =
              formatDuration(controller.currentPosition.value);
          final totalDurationText =
              formatDuration(controller.totalDuration.value);
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    height: 470,
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
                            borderRadius: BorderRadius.circular(4),
                            child: 
                                  CachedNetworkImage(
                                    imageUrl:   baseUrl + controller.currentPlaying.coverurl,
                                    fit: BoxFit.cover,
                                    height: 300,
                                    ),
                            
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              const SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                child: Text(
                                  overflow: TextOverflow.ellipsis,
                                  "${controller.currentPlaying.title} - ${controller.currentPlaying.artist}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              // FutureBuilder(
                              //     future: services.isSongInFavorites(
                              //         controller.currentPlaying.song),
                              //     builder: (context, snapshot) {
                              //       if (snapshot.hasData) {
                              //         return IconButton(
                              //           icon: Icon(
                              //             snapshot.data!
                              //                 ? FontAwesome.heart
                              //                 : FontAwesome.heart_o,
                              //             color: Colors.white,
                              //             shadows: [
                              //               Shadow(
                              //                 blurRadius:
                              //                     snapshot.data! ? 9.0 : 0,
                              //                 color: Colors.white,
                              //                 offset: const Offset(0, 0),
                              //               ),
                              //             ],
                              //           ),
                              //           onPressed: () async {
                              //             if (!snapshot.data!) {
                              //               await services
                              //                   .addSongToFavorites(
                              //                       controller.currentPlaying)
                              //                   .then(
                              //                 (value) {
                              //                   if (value) {
                              //                     _playerPageFunction
                              //                         .songAddedToFaviorateAlert(
                              //                       Get.context,
                              //                       controller
                              //                           .currentPlaying.title,
                              //                     );
                              //                   }
                              //                 },
                              //               );
                              //             } else {
                              //               await services
                              //                   .removeSongFromFavorites(
                              //                       controller.currentPlaying)
                              //                   .then(
                              //                 (value) {
                              //                   _playerPageFunction
                              //                       .songRemovedFromFaviorateAlert(
                              //                     Get.context,
                              //                     controller
                              //                         .currentPlaying.title,
                              //                   );
                              //                 },
                              //               );
                              //             }
                              //           },
                              //         );
                              //       } else {
                              //         return const SizedBox(
                              //           height: 25,
                              //           width: 25,
                              //           child: CircularProgressIndicator(
                              //             strokeWidth: 1,
                              //             color: Colors.white,
                              //           ),
                              //         );
                              //       }
                              //     }),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 1.5,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8), // Thumb size
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 15), // Thumb hover size
                            ),
                            child: Slider(
                              min: 0.0,
                              max: controller.totalDuration.value.inSeconds
                                  .toDouble(),
                              value: controller.currentPosition.value.inSeconds
                                  .toDouble()
                                  .clamp(
                                      0.0,
                                      controller.totalDuration.value.inSeconds
                                          .toDouble()),
                              activeColor: Colors.white,
                              allowedInteraction: SliderInteraction.slideOnly,
                              onChanged: (value) {
                                controller
                                    .seekTo(Duration(seconds: value.toInt()));
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    currentPositionText,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    totalDurationText,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                ],
                              ),
                            ],
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
                    onPressed: controller.playPreviousSong,
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
                      onPressed: controller.playNextSong,
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
                      )),
                ],
              ),
            ],
          );
        }),
      ]),
    );
  }
}
