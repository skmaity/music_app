import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
// import 'package:get/get_state_manager/src/simple/list_notifier.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/component/animated_gradient_widget.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/controller/userid_controller.dart';
// import 'package:music_app/player_page_function.dart';
import 'package:music_app/services/services.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  late SongController controller;
  late FireStoreServices services;

  final BackgroundController _backgroundController =
      Get.find<BackgroundController>();
  final UseridController _useridController = Get.find<UseridController>();

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    controller = Get.find<SongController>();
    services = Get.find<FireStoreServices>();
    _backgroundController.updatePaletteGenerator();
    isFAvourite();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: animationDurationMilliSeconds),
    );
    final curvedAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.ease, // 👈 Change this curve to whatever you want
    );
    sizeAnimation = Tween<double>(begin: 25, end: 50).animate(curvedAnimation);
    colourAnimation = ColorTween(begin: Colors.white, end: Colors.pinkAccent)
        .animate(curvedAnimation);
    super.initState();
  }

  isFAvourite() async {
    isFav.value = await controller.isFavouriteSong(
        _useridController.userId.value,
        controller.currentPlaying.songid.toString());
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  RxBool isFav = false.obs;

  late AnimationController animationController;
  late Animation sizeAnimation;
  late Animation colourAnimation;
  int animationDurationMilliSeconds = 300;

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
        Obx(() {
          return AnimatedGradient(
            primaryColors:
                List<Color>.from(_backgroundController.primaryColorsList),
            secondaryColors:
                List<Color>.from(_backgroundController.secondaryColorsList),
          );
        }),
        Obx(
          () => AnimatedContainer(
            duration: Duration(
                milliseconds:
                    _backgroundController.isVisible.value ? 600 : 5000),
            color: Colors.black
                .withOpacity(_backgroundController.isVisible.value ? 1 : 0.0),
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
                            child: CachedNetworkImage(
                              imageUrl:
                                  baseUrl + controller.currentPlaying.coverurl,
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
                              SizedBox(
                                height: 60,
                                width: 60,
                                child: IconButton(
                                  icon: Icon(
                                    isFav.value
                                        ? FontAwesome.heart
                                        : FontAwesome.heart_o,
                                    color: colourAnimation.value,
                                    size: sizeAnimation.value,
                                    shadows: [
                                      Shadow(
                                        blurRadius: true ? 9.0 : 0,
                                        color: colourAnimation.value,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  onPressed: () async {
                                    if (!isFav.value) {
                                      animationController.forward().then((v) {
                                        animationController.reverse();
                                      });
                                      controller.addFavourite(
                                          _useridController.userId.value,
                                          controller.currentPlaying.songid
                                              .toString());
                                    } else {
                                      controller.removeFromFavourite(
                                          _useridController.userId.value,
                                          controller.currentPlaying.songid
                                              .toString());
                                    }

                                    isFav.value = !isFav.value;
                                  },
                                ),
                              )
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
