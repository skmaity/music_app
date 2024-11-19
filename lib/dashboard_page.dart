import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/Albums.dart';
import 'package:music_app/Artists.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/internet_controller.dart';
import 'package:music_app/nointernet_page.dart';
import 'package:music_app/playlists.dart';
import 'package:music_app/quick_picks.dart';
import 'package:music_app/songs.dart';

class Dashboard extends StatefulWidget  {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // bool isSelected = false;
  bool checkboxSelected = false;
  bool switchSelected = false;
  bool radioSelected = false;
  bool iconSelected = false;

  List<Widget> pages = [
    const QuickPicks(),
    const Songs(),
    const Playlists(),
    const Artists(),
    const Albums()
  ];

  RxInt pageIndex = 0.obs;

  late final InternetController internetController ;
  late BackgroundController backgroundcontroller;

  @override
  void initState() {
    backgroundcontroller = Get.put(BackgroundController());
    backgroundcontroller.updatePaletteGenerator();
   internetController = Get.put(InternetController());
    pageIndex.value = 0;
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        alignment: Alignment.center,
        children:[
              // const AnimatedBackground(),
          
        
      

          AnimatedContainer(
            duration: const Duration(milliseconds: 5000),
            color: Colors.black.withOpacity(0.1),
            child: const SizedBox.expand(),
          ),
          Row(
            children: [
              Obx(
                () => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(30),
                          bottomRight: Radius.circular(30)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          //  height: 400,

                          decoration: BoxDecoration(
                              color: Colors.grey.shade100.withOpacity(0.4)),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
  children: [
    RotatedBox(
      quarterTurns: 3,
      child: TextButton.icon(
        iconAlignment: IconAlignment.end,
        onPressed: () {
          pageIndex.value = 0;
        },
        icon: Icon(
          pageIndex.value == 0 ? Icons.hotel_class_rounded : Icons.hotel_class_outlined,
          color: pageIndex.value == 0 ? Colors.white : Colors.black54,
          shadows: pageIndex.value == 0
              ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
              : null,
          size: 20,
        ),
        label: Text(
          'Quick picks',
          style: TextStyle(
            shadows: pageIndex.value == 0
                ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
                : null,
            color: pageIndex.value == 0 ? Colors.white : Colors.black54,
          ),
        ),
      ),
    ),
    RotatedBox(
      quarterTurns: 3,
      child: TextButton.icon(
        iconAlignment: IconAlignment.end,
        onPressed: () {
          pageIndex.value = 1;
        },
        icon: Icon(
          pageIndex.value == 1 ? Icons.music_note : Icons.music_note_outlined,
          color: pageIndex.value == 1 ? Colors.white : Colors.black54,
          shadows: pageIndex.value == 1
              ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
              : null,
          size: 20,
        ),
        label: Text(
          'Songs',
          style: TextStyle(
            shadows: pageIndex.value == 1
                ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
                : null,
            color: pageIndex.value == 1 ? Colors.white : Colors.black54,
          ),
        ),
      ),
    ),
    RotatedBox(
      quarterTurns: 3,
      child: TextButton.icon(
        iconAlignment: IconAlignment.end,
        onPressed: () {
          pageIndex.value = 2;
        },
        icon: Icon(
          pageIndex.value == 2 ? Icons.playlist_play_rounded : Icons.playlist_play_outlined,
          color: pageIndex.value == 2 ? Colors.white : Colors.black54,
          shadows: pageIndex.value == 2
              ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
              : null,
          size: 20,
        ),
        label: Text(
          'Playlists',
          style: TextStyle(
            shadows: pageIndex.value == 2
                ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
                : null,
            color: pageIndex.value == 2 ? Colors.white : Colors.black54,
          ),
        ),
      ),
    ),
    RotatedBox(
      quarterTurns: 3,
      child: TextButton.icon(
        iconAlignment: IconAlignment.end,
        onPressed: () {
          pageIndex.value = 3;
        },
        icon: Icon(
          pageIndex.value == 3 ? Icons.person : Icons.person_2_outlined,
          color: pageIndex.value == 3 ? Colors.white : Colors.black54,
          shadows: pageIndex.value == 3
              ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
              : null,
          size: 20,
        ),
        label: Text(
          'Artists',
          style: TextStyle(
            shadows: pageIndex.value == 3
                ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
                : null,
            color: pageIndex.value == 3 ? Colors.white : Colors.black54,
          ),
        ),
      ),
    ),
    RotatedBox(
      quarterTurns: 3,
      child: TextButton.icon(
        iconAlignment: IconAlignment.end,
        onPressed: () {
          pageIndex.value = 4;
        },
        icon: Icon(
          pageIndex.value == 4 ? Icons.album : Icons.album_outlined,
          color: pageIndex.value == 4 ? Colors.white : Colors.black54,
          shadows: pageIndex.value == 4
              ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
              : null,
          size: 20,
        ),
        label: Text(
          'Albums',
          style: TextStyle(
            shadows: pageIndex.value == 4
                ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
                : null,
            color: pageIndex.value == 4 ? Colors.white : Colors.black54,
          ),
        ),
      ),
    ),
  ],
),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Obx(
                () => Expanded(
                  child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        final slideAnimation = Tween<Offset>(
                          begin: const Offset(1.0, 0.0), // Slide in from right
                          end: const Offset(0.0, 0.0),
                        ).animate(animation);

                        return SlideTransition(
                          position: slideAnimation,
                          child:
                              FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: internetController.internet.value
                          ? pages[pageIndex.value]
                          : const NointernetPage()

                          // child : const NointernetPage(),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
