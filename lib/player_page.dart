import 'dart:ui';
import 'package:animate_gradient/animate_gradient.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_glow/flutter_glow.dart';
// import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/services/services.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key,});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late SongController controller;
  late FireStoreServices services;
  @override
  void initState() {
    controller = Get.put(SongController());
    services = Get.put(FireStoreServices());


    super.initState();
  }

  double _currentValue = 0;

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
        AnimateGradient(
          primaryColors: const [
            Colors.pink,
            Colors.pinkAccent,
            Colors.redAccent,
          ],
          secondaryColors: const [
            Colors.blue,
            Colors.blueAccent,
            Colors.deepPurple,
          ],
          child: const SizedBox.expand(),
        ),
        Column(
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
                          child:  Image(
                            height: 300,
                            fit: BoxFit.cover,
                            image: NetworkImage(controller.currentPlaying.cover),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Row(
                          children: [
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              '10:20',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            )
                          ],
                        ),
                        Slider(
                            activeColor: Colors.white,
                            max: 1,
                            allowedInteraction: SliderInteraction.slideOnly,
                            value: _currentValue,
                            onChanged: (v) {
                              _currentValue = v;
                              setState(() {});
                            })
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
                    // child: const GlowIcon(
                    //   Ionicons.md_play_skip_back_outline,
                    //   color: Colors.white,
                    //   size: 22,
                    // ),
                    onPressed: () {}),
                Obx(
                  ()=> FloatingActionButton.large( 
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
                    // child: GlowIcon(
                    //   controller.isPlaying.value ? Feather.pause : Feather.play,
                    //   color: Colors.white,
                    //   size: 22,
                    // ),
                    onPressed: () async {
                      controller.isPlaying.value
                          ? controller.pausePlaying() 
                          :controller.resumePlaying();
                    },
                  ),
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
                  // child:  const GlowIcon(
                  //   Ionicons.md_play_skip_forward_outline,
                  //   color: Colors.white,
                  //   size: 22,
                  // ),
                  onPressed: () async {
                    if(services.quickpicks.length > controller.currentIndex.value+1){
                    controller.startPlaying(services.quickpicks[controller.currentIndex.value+1]);

                     controller. currentIndex.value = controller.currentIndex.value+1;

                    }
                    else{
                    controller.startPlaying(services.quickpicks[0]);
                    controller. currentIndex.value = 0;

                    }
                  },
                ),
              ],
            )
          ],
        ),
      ]),
    );
  }
}
